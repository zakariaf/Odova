// One comparable sort key across two axes that measure different things.
//
// SPEC.md §3 (`projected_due_date`) and §4.1.3 *From a rate to a projected
// date*. §3: "it makes 10,000 km and 12 months comparable on one axis, which is
// the whole point of the app."
//
// The §4.1.3 worked example in here is this epic's anchor. Every task from 7.1
// to 7.6 feeds it, so if its five published numbers move, something upstream
// moved and this is where it shows.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/project_due_date.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
CivilDate day(String text) => CivilDate.tryParse(text)!;

OdometerReading reading(String suffix, String occurredOn, int km) =>
    OdometerReading(
      id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}$suffix')!,
      vehicleId: VehicleId.tryParse('veh_$_id')!,
      occurredOn: occurredOn,
      odometer: Distance.fromKm(km),
      odometerUnit: DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

const _rate = DailyDistance(
  metresPerDay: 41000,
  confidence: RateConfidence.measured,
);

void main() {
  group('the SPEC.md §4.1.3 worked example, end to end', () {
    // Passat, oil every 10,000 km / 12 months, last done 2026-02-10 at
    // 108,200 km. Last reading 2026-08-20 at 116,050 km. Today 2026-09-02.
    //
    //   readings give rate = 41 km/day, measured
    //   odo_now       = 116,050 + 41 x 13   = 116,583
    //   threshold     = 108,200 + 10,000    = 118,200
    //   remaining     = 1,617 km -> 40 days -> projected_due = 2026-10-12
    //   time axis     = 2027-02-10          -> distance wins
    final today = day('2026-09-02');

    final series = ReadingSeries.from([
      reading('A', '2026-02-10', 108200),
      reading('B', '2026-08-20', 116050),
    ], const []);

    final oil = ServiceItem(
      id: ServiceItemId.tryParse('rem_$_id')!,
      vehicleId: VehicleId.tryParse('veh_$_id')!,
      kind: ServiceKind.oilAndFilter,
      intervalDistance: const Distance.fromKm(10000),
      intervalMonths: 12,
      priority: ServicePriority.normal,
      rollover: ServiceRollover.fromActual,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    final recordId = ServiceRecordId.tryParse('srv_$_id')!;
    final done = ServiceRecord(
      id: recordId,
      vehicleId: VehicleId.tryParse('veh_$_id')!,
      occurredOn: '2026-02-10',
      odometer: const Distance.fromKm(108200),
      odometerUnit: DistanceUnit.km,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
      lines: [
        ServiceLine(
          id: ServiceLineId.tryParse('lin_$_id')!,
          serviceRecordId: recordId,
          serviceItemId: oil.id,
          label: 'Oil and filter',
          amount: Money(8900, Currency.tryParse('EUR')!),
        ),
      ],
    );

    final car = Vehicle(
      id: VehicleId.tryParse('veh_$_id')!,
      name: 'Passat',
      vehicleType: VehicleType.car,
      fuelKindDefault: FuelKind.diesel,
      status: VehicleStatus.active,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    test('the rate is 41 km/day, measured', () {
      final rate = dailyDistance(
        series,
        expectedAnnualMetres: null,
        today: today,
      );
      expect(rate.confidence, RateConfidence.measured);
      expect(rate.metresPerDay ~/ 1000, 41);
    });

    test('odo_now is 116,583 km', () {
      final estimate = estimateOdometer(series, _rate, today: today)!;
      expect(estimate.metres ~/ 1000, 116583);
      expect(estimate.staleDays, 13);
    });

    test('the threshold is 118,200 km and the time axis is 2027-02-10', () {
      final anchor = resolveAnchor(oil, [done], car, series);
      final assessment = computeDueState(
        oil,
        anchor,
        estimateOdometer(series, _rate, today: today),
        noticeWindow(item: oil, vehicle: car, settings: _settings),
        today: today,
      );

      expect(assessment.dueAtOdometerMetres! ~/ 1000, 118200);
      expect(assessment.dueOn, day('2027-02-10'));
    });

    test('projected_due_date is 2026-10-12, and distance wins', () {
      final anchor = resolveAnchor(oil, [done], car, series);
      final estimate = estimateOdometer(series, _rate, today: today);
      final assessment = computeDueState(
        oil,
        anchor,
        estimate,
        noticeWindow(item: oil, vehicle: car, settings: _settings),
        today: today,
      );

      final projected = projectDueDate(
        assessment,
        series,
        _rate,
        today: today,
      );

      expect(projected, day('2026-10-12'));

      // "distance wins" in SPEC's example is about which axis sets the DATE —
      // 2026-10-12 from distance against 2027-02-10 from time — and not about
      // the due-state driver, which answers a different question (which axis
      // is worse). Both axes are `ok` here, so both produced the worst state
      // and the driver is `both`. Two different senses of "wins", and this
      // test asserted the wrong one first.
      expect(projected!.compareTo(assessment.dueOn!), lessThan(0));
      expect(assessment.state, DueState.ok);
      expect(assessment.driver, DueDriver.both);
    });
  });

  group('min over the axes that exist', () {
    test('takes the earlier of the two when both are present', () {
      final projected = projectDueDate(
        _assessment(dueOn: day('2027-02-10'), dueAtKm: 118200),
        _seriesAt('2026-08-20', 116050),
        _rate,
        today: day('2026-09-02'),
      );
      expect(projected, day('2026-10-12'), reason: 'distance is earlier');
    });

    test('a null due_on must not win the comparison', () {
      // The bug a naive `min` produces: `null` sorts before every date, so a
      // distance-only item would project as "no date" and sort to the top of
      // the home screen forever.
      final projected = projectDueDate(
        _assessment(dueAtKm: 118200),
        _seriesAt('2026-08-20', 116050),
        _rate,
        today: day('2026-09-02'),
      );
      expect(projected, day('2026-10-12'));
    });

    test('is the time date for a time-only item', () {
      final projected = projectDueDate(
        _assessment(dueOn: day('2027-02-10')),
        _seriesAt('2026-08-20', 116050),
        _rate,
        today: day('2026-09-02'),
      );
      expect(projected, day('2027-02-10'));
    });

    test('is null when neither axis can be projected', () {
      expect(
        projectDueDate(
          _assessment(),
          _seriesAt('2026-08-20', 116050),
          _rate,
          today: day('2026-09-02'),
        ),
        isNull,
      );
    });
  });

  test('rounds the day count UP, never down', () {
    // 52.4 days is 53. A projection that lands the user at the garage AFTER
    // the threshold is the failure mode; arriving a day early is not.
    final projected = projectDueDate(
      _assessment(dueAtKm: 118200),
      _seriesAt('2026-09-02', 116050),
      // 2,150 km remaining at 41 km/day is 52.44 days.
      const DailyDistance(
        metresPerDay: 41000,
        confidence: RateConfidence.measured,
      ),
      today: day('2026-09-02'),
    );

    expect(projected, day('2026-09-02').addDays(53));
  });

  test('returns a date in the PAST for an already-overdue axis', () {
    // It is a sort key, not a promise. An item 2,000 km past due sorts above
    // one due next week, which is the whole reason the key exists.
    final projected = projectDueDate(
      _assessment(dueAtKm: 110000),
      _seriesAt('2026-09-02', 112000),
      _rate,
      today: day('2026-09-02'),
    );

    expect(projected!.compareTo(day('2026-09-02')), lessThan(0));
  });

  test('still produces a sort key at confidence default', () {
    // §4.1.4 forbids SHOWING the date at `default`, not computing it. The
    // hedging is the UI's job; the list still has to be in an order.
    final projected = projectDueDate(
      _assessment(dueAtKm: 118200),
      _seriesAt('2026-08-20', 116050),
      const DailyDistance(
        metresPerDay: 32876,
        confidence: RateConfidence.defaulted,
      ),
      today: day('2026-09-02'),
    );

    expect(projected, isNotNull);
  });

  test('a zero or negative rate cannot project, and returns the time axis', () {
    // The rate is clamped to 5 km/day so this is unreachable through
    // `dailyDistance` — and a caller can hand any rate in, and dividing by
    // zero here would produce an Infinity that becomes a date.
    final projected = projectDueDate(
      _assessment(dueOn: day('2027-02-10'), dueAtKm: 118200),
      _seriesAt('2026-08-20', 116050),
      const DailyDistance(
        metresPerDay: 0,
        confidence: RateConfidence.defaulted,
      ),
      today: day('2026-09-02'),
    );

    expect(projected, day('2027-02-10'));
  });
}

/// Default settings — no notice overrides.
final _settings = AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// An assessment carrying only the fields `projectDueDate` reads.
DueAssessment _assessment({CivilDate? dueOn, int? dueAtKm}) => DueAssessment(
  state: DueState.ok,
  driver: DueDriver.none,
  confidence: RateConfidence.measured,
  progress: 0,
  dueOn: dueOn,
  dueAtOdometerMetres: dueAtKm == null ? null : Distance.fromKm(dueAtKm).metres,
);

ReadingSeries _seriesAt(String date, int km) =>
    ReadingSeries.from([reading('A', date, km)], const []);
