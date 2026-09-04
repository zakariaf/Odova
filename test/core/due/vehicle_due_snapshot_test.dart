// The one function every §4.2.1 trigger calls.
//
// SPEC.md §4.2.1: "Reprojection is a pure function over the local database, and
// five vehicles x 16 reminders is 80 rows of arithmetic. Recompute everything,
// always; there is no incremental-invalidation cleverness to get wrong."
//
// The timing test below is what keeps that decision honest. If 80 rows are not
// comfortably fast, "recompute everything" is not affordable and that is a
// finding — not a licence to build a cache.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/vehicle_due_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
CivilDate day(String text) => CivilDate.tryParse(text)!;

final CivilDate _build = day('2026-01-01');

/// A distinct ULID suffix per index, so sixteen items are sixteen items.
String _suffix(int i) => '${_alphabet[i ~/ 32 % 32]}${_alphabet[i % 32]}';

ServiceItem item(
  int i, {
  bool isTracked = true,
  bool isActive = true,
}) => ServiceItem(
  id: ServiceItemId.tryParse('rem_${_id.substring(0, 24)}${_suffix(i)}')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  kind: ServiceKind.oilAndFilter,
  intervalDistance: Distance.fromKm(10000 + i * 100),
  intervalMonths: 12,
  isTracked: isTracked,
  isActive: isActive,
  baselineDate: '2026-01-01',
  baselineOdometer: const Distance.fromKm(100000),
  priority: ServicePriority.normal,
  rollover: ServiceRollover.fromActual,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

OdometerReading reading(int i, String occurredOn, int km) => OdometerReading(
  id: OdometerReadingId.tryParse('odo_${_id.substring(0, 24)}${_suffix(i)}')!,
  vehicleId: VehicleId.tryParse('veh_$_id')!,
  occurredOn: occurredOn,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  source: OdometerSource.manual,
  createdAtUtcMs: 1000 + i,
  updatedAtUtcMs: 1000 + i,
);

final _vehicle = Vehicle(
  id: VehicleId.tryParse('veh_$_id')!,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

final _settings = AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

final _series = ReadingSeries.from([
  reading(0, '2026-01-01', 100000),
  reading(1, '2026-06-01', 108000),
], const []);

VehicleDueSnapshot snapshot(
  List<ServiceItem> items, {
  String today = '2026-06-01',
  CivilDate? buildDate,
}) => recomputeVehicle(
  _vehicle,
  items,
  const [],
  _series,
  _settings,
  today: day(today),
  buildDate: buildDate ?? _build,
);

void main() {
  test('one assessment per eligible item, and none for the others', () {
    final result = snapshot([
      item(0),
      item(1, isActive: false),
      item(2, isTracked: false),
      item(3),
    ]);

    expect(result.assessments, hasLength(2));
    expect(
      result.assessments.map((a) => a.$1.id),
      [item(0).id, item(3).id],
      reason: 'in the order given, with the ineligible ones absent',
    );
  });

  test('is pure: the same inputs give the same output, twice', () {
    final items = [item(0), item(1), item(2)];
    expect(snapshot(items), snapshot(items));
    expect(snapshot(items).summary, snapshot(items).summary);
    expect(snapshot(items).nextDueOn, snapshot(items).nextDueOn);
  });

  test('the rate and the estimate are computed once for the vehicle', () {
    // Not asserted by counting calls — there is nothing to count in a pure
    // function — but by the shape: both live on the snapshot rather than on
    // each assessment, so sixteen items cannot produce sixteen slopes.
    final result = snapshot([item(0), item(1)]);
    expect(result.rate.confidence, RateConfidence.measured);
    expect(result.estimate, isNotNull);
    expect(result.estimate!.staleDays, 0);
  });

  group('clock-suspect mode', () {
    test('every item reports unknown, whatever its intervals', () {
      // §3's consequence, applied uniformly. The arithmetic is fine; the date
      // it starts from is not.
      final result = snapshot(
        [item(0), item(1), item(2)],
        today: '1970-01-01',
      );

      expect(result.clock.isSuspect, isTrue);
      expect(result.assessments, hasLength(3));
      for (final (_, assessment) in result.assessments) {
        expect(assessment.state, DueState.unknown);
        expect(assessment.driver, DueDriver.none);
      }
    });

    test('no projected_due_date is produced, so nothing can be scheduled', () {
      final result = snapshot([item(0)], today: '1970-01-01');

      expect(result.nextDueOn, isNull);
      for (final (_, assessment) in result.assessments) {
        expect(assessment.projectedDueDate, isNull);
      }
    });

    test('no estimate is published from a date the app does not believe', () {
      // The rate and the estimate were computed BEFORE the suspect branch, so
      // a phone reset to 1970 got `staleDays` clamped to 0 and an estimate of
      // `projection: entered` — the odometer strip would render the last
      // reading as though it had been typed today, while every assessment
      // beside it said `unknown`. A clock set to 2050 gives `expired` with a
      // nonsense staleness.
      //
      // §3's consequence is that the app stops answering. An odometer figure
      // IS an answer.
      final past = snapshot([item(0)], today: '1970-01-01');
      expect(past.clock.isSuspect, isTrue);
      expect(past.estimate, isNull);
      expect(past.nextDueOn, isNull);

      final future = snapshot([item(0)], today: '2050-01-01');
      expect(future.clock.isSuspect, isTrue);
      expect(future.estimate, isNull);
    });

    test('a trusted clock produces real states again', () {
      final result = snapshot([item(0)]);
      expect(result.clock.isSuspect, isFalse);
      expect(result.assessments.single.$2.state, isNot(DueState.unknown));
    });
  });

  test('a decade of history recomputes in well under 50 ms', () {
    // The version below runs with an empty record list and two readings, so it
    // exercises NEITHER term that scales: not `items x records` in
    // `resolveAnchor`, and not the sort in `ReadingSeries`. It could not have
    // produced the finding its own comment promises.
    //
    // Ten years: 1,000 odometer readings, 200 service records, 16 reminders,
    // five vehicles. If THIS is fast, "recompute everything, always" is
    // affordable for the user the app is designed for.
    final items = [for (var i = 0; i < 16; i++) item(i)];
    final manyReadings = ReadingSeries.from([
      for (var i = 0; i < 1000; i++)
        reading(
          // NOT `i % 900`. `_suffix` is unique to 1,023, and the modulo made
          // readings 900-999 reuse the ids of 0-99 — `cumulativeBySorted` keys
          // by id, so those hundred entries overwrote each other and the
          // benchmark measured a series whose values were not what it claimed.
          i,
          CivilDate.tryParse('2016-01-01')!.addDays(i * 4).toString(),
          100000 + i * 40,
        ),
    ], const []);
    final manyRecords = [
      for (var i = 0; i < 200; i++)
        ServiceRecord(
          id: ServiceRecordId.tryParse(
            'srv_${_id.substring(0, 24)}${_suffix(i)}',
          )!,
          vehicleId: VehicleId.tryParse('veh_$_id')!,
          occurredOn: CivilDate.tryParse(
            '2016-01-01',
          )!.addDays(i * 18).toString(),
          odometer: Distance.fromKm(100000 + i * 200),
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
          lines: [
            ServiceLine(
              id: ServiceLineId.tryParse(
                'lin_${_id.substring(0, 24)}${_suffix(i)}',
              )!,
              serviceRecordId: ServiceRecordId.tryParse(
                'srv_${_id.substring(0, 24)}${_suffix(i)}',
              )!,
              serviceItemId: items[i % 16].id,
              label: 'Service',
              amount: Money(8900, Currency.tryParse('EUR')!),
            ),
          ],
        ),
    ];

    VehicleDueSnapshot heavy() => recomputeVehicle(
      _vehicle,
      items,
      manyRecords,
      manyReadings,
      _settings,
      today: day('2026-06-01'),
      buildDate: _build,
    );

    for (var i = 0; i < 3; i++) {
      heavy();
    }

    final stopwatch = Stopwatch()..start();
    for (var vehicle = 0; vehicle < 5; vehicle++) {
      heavy();
    }
    stopwatch.stop();

    // The measurement IS the report — the assertion below is the affordability
    // claim and this is the number a reviewer reads.
    // ignore: avoid_print
    print(
      '5 vehicles x 16 items x 200 records x 1000 readings: '
      '${stopwatch.elapsedMilliseconds} ms',
    );
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(50),
      reason:
          'if this is slow, "recompute everything, always" is not affordable '
          'for a ten-year history — and that is a finding, not a licence to '
          'build a cache',
    );
  });

  test('SPEC §4.2.1s 80 rows recompute in well under 50 ms', () {
    // Five vehicles x sixteen reminders. The number in the spec, so the
    // "recompute everything, always" decision is measured rather than assumed.
    final items = [for (var i = 0; i < 16; i++) item(i)];

    // Warm up, so the measurement is of the arithmetic and not of the JIT.
    for (var i = 0; i < 5; i++) {
      snapshot(items);
    }

    final stopwatch = Stopwatch()..start();
    for (var vehicle = 0; vehicle < 5; vehicle++) {
      snapshot(items);
    }
    stopwatch.stop();

    // The number is printed, not asserted, because a machine-dependent
    // timing IS the thing being reported — the assertion below is the
    // affordability claim, and the print is what a reviewer reads.
    // ignore: avoid_print
    print('80-row recompute: ${stopwatch.elapsedMicroseconds} us');
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(50),
      reason:
          'if this is slow, "recompute everything, always" is not affordable '
          'and that is a finding — not a licence to build a cache',
    );
  });
  test('two snapshots differing only in the NUMBERS are not equal', () {
    // `props` encoded each assessment through `DueAssessment.toString()`, which
    // prints only `state` and `driver`. So two snapshots whose remaining
    // metres, remaining days, due date, projection, confidence and progress all
    // differed compared EQUAL — and `valuesEqual` is the `distinct` predicate
    // on the repositories' watch streams, so the home screen would not rebuild
    // when the only thing that changed was the numbers it renders.
    //
    // Built DIRECTLY rather than through `recomputeVehicle`, and that is the
    // point: a first version drove two recomputes four days apart and passed
    // under the bug, because `estimate` differs between them and carried the
    // inequality on its own. Isolating the assessment encoding means holding
    // every other field identical, which only direct construction can do.
    DueAssessment withRemaining(int days) => DueAssessment(
      state: DueState.dueSoon,
      driver: DueDriver.time,
      confidence: RateConfidence.measured,
      progress: 0.5,
      remainingDays: days,
    );

    VehicleDueSnapshot snapshotOf(DueAssessment assessment) =>
        VehicleDueSnapshot(
          assessments: [(item(0), assessment)],
          summary: const DueSummary(counts: {DueState.dueSoon: 1}),
          rate: const DailyDistance(
            metresPerDay: 41000,
            confidence: RateConfidence.measured,
          ),
          clock: ClockSuspicion(
            isSuspect: false,
            observedToday: day('2026-06-01'),
          ),
        );

    final a = snapshotOf(withRemaining(10));
    final b = snapshotOf(withRemaining(20));

    expect(a.assessments.single.$2.state, b.assessments.single.$2.state);
    expect(a.assessments.single.$2.driver, b.assessments.single.$2.driver);
    expect(
      a.assessments.single.$2.toString(),
      b.assessments.single.$2.toString(),
      reason: 'the debug string is identical — that is what made this a bug',
    );
    expect(a, isNot(b));
  });
}
