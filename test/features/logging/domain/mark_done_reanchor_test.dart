// The test that fails if anyone anchors on the due odometer.
//
// SPEC.md §10 and `mark_done.dart`'s own header: "An item due at 186,000 km
// serviced at 187,412 with a 10,000 km interval is next due at 197,412 —
// anchoring on the due value would quietly steal 1,412 km of interval from
// anyone who serviced their car late, every cycle, for ever."
//
// `mark_done_test.dart` covers the pure function's cases. This file exists to
// state the ONE case the epic names as the reason the function exists, in the
// numbers the epic uses, so it cannot be lost in a refactor of the others.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/domain/mark_done.dart';
import 'package:test/test.dart';

final VehicleId _vehicleId = VehicleId.tryParse(
  'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;
final ServiceItemId _itemId = ServiceItemId.tryParse(
  'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;
final ServiceRecordId _recordId = ServiceRecordId.tryParse(
  'srv_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
)!;

ServiceItem _item({
  Distance? intervalDistance,
  int? intervalMonths,
  ServiceRollover rollover = ServiceRollover.fromActual,
}) => ServiceItem(
  id: _itemId,
  vehicleId: _vehicleId,
  kind: ServiceKind.custom,
  label: 'Oil and filter',
  priority: ServicePriority.normal,
  rollover: rollover,
  intervalDistance: intervalDistance,
  intervalMonths: intervalMonths,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

ServiceRecord _record({Distance? odometer, String on = '2026-09-02'}) =>
    ServiceRecord(
      id: _recordId,
      vehicleId: _vehicleId,
      occurredOn: on,
      odometerUnit: DistanceUnit.km,
      odometer: odometer,
      lines: [
        ServiceLine(
          id: ServiceLineId.tryParse('lin_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!,
          serviceRecordId: _recordId,
          label: 'Oil and filter',
          amount: Money(9250, Currency.tryParse('EUR')!),
        ),
      ],
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

void main() {
  test('the epic worked example, in the epic numbers', () {
    // Due at 186,000. Serviced at 187,412 — 1,412 km LATE. Interval 10,000.
    // Next due at 197,412, and never at 196,000.
    final next = nextDueAfterMarkDone(
      item: _item(intervalDistance: const Distance.fromKm(10000)),
      record: _record(odometer: const Distance.fromKm(187412)),
    );

    expect(next.odometer, const Distance.fromKm(197412));
    expect(
      next.odometer,
      isNot(const Distance.fromKm(196000)),
      reason:
          'anchoring on the DUE odometer steals 1,412 km of interval from a '
          'late service, every cycle, for ever',
    );
  });

  test('serviced EARLY moves the next one earlier, by the same rule', () {
    // The other direction, which is the half §10's confirmation panel exists
    // to show: "the consequence of finishing 3,000 km early is what a user
    // needs to see once."
    final next = nextDueAfterMarkDone(
      item: _item(intervalDistance: const Distance.fromKm(10000)),
      record: _record(odometer: const Distance.fromKm(183000)),
    );

    expect(next.odometer, const Distance.fromKm(193000));
  });

  test('a record with no odometer produces no distance half', () {
    // Not a zero, and not the due value. An item whose next distance the app
    // cannot compute says so by having none — §2's rule against a guess that
    // looks like a fact.
    final next = nextDueAfterMarkDone(
      item: _item(intervalDistance: const Distance.fromKm(10000)),
      record: _record(),
    );

    expect(next.odometer, isNull);
  });

  test('from_due keeps the anniversary; from_actual walks it', () {
    // §3: a late annual inspection stays on its anniversary, because the
    // deadline is the fact and the visit is not.
    final fromDue = nextDueAfterMarkDone(
      item: _item(intervalMonths: 12, rollover: ServiceRollover.fromDue),
      record: _record(),
      previousDueOn: '2026-06-01',
    );
    final fromActual = nextDueAfterMarkDone(
      item: _item(intervalMonths: 12),
      record: _record(),
      previousDueOn: '2026-06-01',
    );

    expect(fromDue.date.toString(), '2027-06-01');
    expect(fromActual.date.toString(), '2027-09-02');
  });
}
