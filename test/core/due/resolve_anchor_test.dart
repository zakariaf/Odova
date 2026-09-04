// Where a reminder's next cycle is measured from.
//
// SPEC.md §3 *Due state per item* — the `resolveAnchor` ladder and the
// `from_due` paragraph — and §14 *Second-hand car with a service book*.
//
// Two things here are easy to get wrong and expensive when they are.
//
// The ladder resolves the two axes INDEPENDENTLY. A rung that supplies a date
// and no odometer must not collapse the whole item to `unknown`: an inspection
// with a baseline date and no baseline odometer still knows when it is due by
// time, and §14 is explicit that a used car with a service book must never read
// `overdue` for want of a number nobody wrote down.
//
// And `from_due` anchors on the date the job WAS due, not the date it was done
// — "registration falls in June whenever you paid".
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

const _id = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
VehicleId get _vehicleId => VehicleId.tryParse('veh_$_id')!;
ServiceItemId get _itemId => ServiceItemId.tryParse('rem_$_id')!;
ServiceItemId get _otherItemId =>
    ServiceItemId.tryParse('rem_${_id.substring(0, 25)}Z')!;

CivilDate? day(String? text) => text == null ? null : CivilDate.tryParse(text);

Vehicle vehicle({String? purchaseDate, int? purchaseKm}) => Vehicle(
  id: _vehicleId,
  name: 'The Golf',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  purchaseDate: purchaseDate,
  purchaseOdometer: purchaseKm == null ? null : Distance.fromKm(purchaseKm),
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

ServiceItem item({
  ServiceRollover rollover = ServiceRollover.fromActual,
  int? intervalMonths,
  String? baselineDate,
  int? baselineKm,
}) => ServiceItem(
  id: _itemId,
  vehicleId: _vehicleId,
  kind: ServiceKind.inspection,
  intervalMonths: intervalMonths,
  baselineDate: baselineDate,
  baselineOdometer: baselineKm == null ? null : Distance.fromKm(baselineKm),
  rollover: rollover,
  priority: ServicePriority.normal,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

ServiceRecord record(
  String suffix,
  String occurredOn,
  int km, {
  ServiceItemId? forItem,
}) {
  final recordId = ServiceRecordId.tryParse(
    'srv_${_id.substring(0, 25)}$suffix',
  )!;
  return ServiceRecord(
    id: recordId,
    vehicleId: _vehicleId,
    occurredOn: occurredOn,
    odometer: Distance.fromKm(km),
    odometerUnit: DistanceUnit.km,
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
    lines: [
      ServiceLine(
        id: ServiceLineId.tryParse('lin_${_id.substring(0, 25)}$suffix')!,
        serviceRecordId: recordId,
        serviceItemId: forItem ?? _itemId,
        label: 'Inspection',
        amount: Money(8900, Currency.tryParse('EUR')!),
      ),
    ],
  );
}

OdometerReading reading(String suffix, String occurredOn, int km) =>
    OdometerReading(
      id: OdometerReadingId.tryParse('odo_${_id.substring(0, 25)}$suffix')!,
      vehicleId: _vehicleId,
      occurredOn: occurredOn,
      odometer: Distance.fromKm(km),
      odometerUnit: DistanceUnit.km,
      source: OdometerSource.manual,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

ReadingSeries seriesOf(List<OdometerReading> readings) =>
    ReadingSeries.from(readings, const []);

void main() {
  group('rung 1 — the newest completing service record', () {
    test('the newer of two records wins, with its cumulative odometer', () {
      final anchor = resolveAnchor(
        item(baselineDate: '2020-01-01', baselineKm: 50000),
        [
          record('A', '2024-06-01', 90000),
          record('B', '2026-07-14', 112000),
        ],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2026-07-14'));
      expect(anchor.odometerMetres, const Distance.fromKm(112000).metres);
    });

    test('a record whose lines reference a DIFFERENT item is ignored', () {
      // A brake job does not reset the inspection clock. The line's
      // `service_item_id` is the only thing that ties a record to an item.
      final anchor = resolveAnchor(
        item(baselineDate: '2024-06-01', baselineKm: 90000),
        [record('A', '2026-07-14', 112000, forItem: _otherItemId)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2024-06-01'), reason: 'fell to the baseline');
      expect(anchor.odometerMetres, const Distance.fromKm(90000).metres);
    });
  });

  group('the ladder falls through, rung by rung', () {
    test('rung 2 — the item baseline, when no record references it', () {
      final anchor = resolveAnchor(
        item(baselineDate: '2024-06-01', baselineKm: 90000),
        const [],
        vehicle(purchaseDate: '2020-01-01', purchaseKm: 50000),
        seriesOf([reading('A', '2019-01-01', 40000)]),
      );

      expect(anchor.date, day('2024-06-01'));
      expect(anchor.odometerMetres, const Distance.fromKm(90000).metres);
    });

    test('rung 3 — the vehicle purchase facts', () {
      final anchor = resolveAnchor(
        item(),
        const [],
        vehicle(purchaseDate: '2020-01-01', purchaseKm: 50000),
        seriesOf([reading('A', '2019-01-01', 40000)]),
      );

      expect(anchor.date, day('2020-01-01'));
      expect(anchor.odometerMetres, const Distance.fromKm(50000).metres);
    });

    test('rung 4 — the earliest odometer reading and its date', () {
      final anchor = resolveAnchor(
        item(),
        const [],
        vehicle(),
        seriesOf([
          reading('B', '2026-01-01', 100000),
          reading('A', '2025-01-01', 90000),
        ]),
      );

      expect(anchor.date, day('2025-01-01'), reason: 'earliest, not newest');
      expect(anchor.odometerMetres, const Distance.fromKm(90000).metres);
    });

    test('nothing at all gives an empty anchor, never a zero', () {
      // The caller turns this into `unknown`. §14 requires that it never
      // becomes `overdue`: a used car whose history nobody wrote down is not a
      // car that missed a service.
      final anchor = resolveAnchor(
        item(),
        const [],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, isNull);
      expect(anchor.odometerMetres, isNull);
      expect(anchor.isEmpty, isTrue);
    });
  });

  test('the two axes resolve INDEPENDENTLY down the same ladder', () {
    // A baseline date with no baseline odometer. The time axis anchors on the
    // baseline; the distance axis keeps falling until a rung carries a number.
    //
    // Collapsing the whole item to `unknown` because one half was missing is
    // exactly what §14 forbids for a second-hand car with a service book: the
    // book gives dates, the previous owner never wrote the mileage, and the
    // inspection is still due in June.
    final anchor = resolveAnchor(
      item(baselineDate: '2024-06-01'),
      const [],
      vehicle(purchaseDate: '2020-01-01', purchaseKm: 50000),
      seriesOf(const []),
    );

    expect(anchor.date, day('2024-06-01'), reason: 'rung 2 had a date');
    expect(
      anchor.odometerMetres,
      const Distance.fromKm(50000).metres,
      reason: 'rung 2 had no odometer, so the distance axis took rung 3',
    );
  });

  group('from_due anchors on the date it WAS due', () {
    // SPEC.md §3: "registration falls in June whenever you paid."
    final inspection = item(
      rollover: ServiceRollover.fromDue,
      intervalMonths: 12,
      baselineDate: '2024-06-01',
      baselineKm: 90000,
    );

    test('done LATE anchors on the cycle it satisfied, not the next one', () {
      // Baseline 2024-06-01, 12 months, done 2026-07-14 — six weeks late.
      // The cycle that record satisfied is 2026-06-01, so the next is
      // 2027-06-01.
      //
      // SPEC's literal walk — "the smallest k >= 1 whose result is AFTER the
      // record's occurred_on" — gives 2027-06-01 as the ANCHOR and therefore
      // 2028-06-01 as the due date: a full year late, on the item whose whole
      // purpose is a legal deadline. That paragraph is corrected in this PR.
      final anchor = resolveAnchor(
        inspection,
        [record('A', '2026-07-14', 112000)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2026-06-01'));
    });

    test('done EARLY does not skip a cycle', () {
      // Done 2026-05-20, twelve days before the 2026-06-01 cycle. The largest
      // cycle on or before that date is 2025-06-01, so the next due is
      // 2026-06-01 — this year, not next.
      final anchor = resolveAnchor(
        inspection,
        [record('A', '2026-05-20', 111000)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2025-06-01'));
    });

    test('done exactly ON the due date anchors on that date', () {
      final anchor = resolveAnchor(
        inspection,
        [record('A', '2026-06-01', 111500)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2026-06-01'));
    });

    test("only the DATE is walked; the odometer stays the record's", () {
      final anchor = resolveAnchor(
        inspection,
        [record('A', '2026-07-14', 112000)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.odometerMetres, const Distance.fromKm(112000).metres);
    });

    test('a record BEFORE the first cycle anchors on its own date', () {
      // The job was done before the baseline the cycle is measured from — a
      // service book entry back-dated past the date the owner typed as the
      // start, or an import. No cycle has been satisfied, so walking forward
      // from the base gives a candidate LATER than the record, and anchoring
      // on a future date would make the item due a year after a service that
      // has already happened.
      final anchor = resolveAnchor(
        inspection,
        [record('A', '2023-01-15', 80000)],
        vehicle(),
        seriesOf(const []),
      );

      expect(
        anchor.date,
        day('2023-01-15'),
        reason: 'the baseline is 2024-06-01, which is after this record',
      );
    });

    test('falls back to purchase_date as the cycle base', () {
      final anchor = resolveAnchor(
        item(
          rollover: ServiceRollover.fromDue,
          intervalMonths: 12,
        ),
        [record('A', '2026-07-14', 112000)],
        vehicle(purchaseDate: '2024-06-01', purchaseKm: 90000),
        seriesOf(const []),
      );

      expect(anchor.date, day('2026-06-01'));
    });

    test('with no interval to walk it behaves like from_actual', () {
      // An item with `from_due` and no `interval_months` has no cycle. The
      // record's own date is the only honest answer.
      final anchor = resolveAnchor(
        item(rollover: ServiceRollover.fromDue, baselineDate: '2024-06-01'),
        [record('A', '2026-07-14', 112000)],
        vehicle(),
        seriesOf(const []),
      );

      expect(anchor.date, day('2026-07-14'));
    });
  });

  test("from_actual anchors on the record's own date and odometer", () {
    final anchor = resolveAnchor(
      item(
        intervalMonths: 12,
        baselineDate: '2024-06-01',
        baselineKm: 90000,
      ),
      [record('A', '2026-07-14', 112000)],
      vehicle(),
      seriesOf(const []),
    );

    expect(anchor.date, day('2026-07-14'));
    expect(anchor.odometerMetres, const Distance.fromKm(112000).metres);
  });
}
