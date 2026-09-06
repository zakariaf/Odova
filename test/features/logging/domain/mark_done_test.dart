// A reminder resets because work was recorded, from the reading the user
// actually entered — never from the odometer it was due at.
//
// SPEC.md §10 *Marking a reminder done → a service record*: "There is no 'just
// mark it done' state anywhere — a reminder resets because work was recorded,
// never because a switch was flipped. That rule is what makes `report.service`
// worth money at resale."
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/logging/domain/mark_done.dart';

const String _b = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_b')!;
final ServiceItemId _itemId = ServiceItemId.tryParse('rem_$_b')!;

/// [noDistance] rather than a nullable interval: `intervalDistance ?? default`
/// cannot tell "not given" from "deliberately absent", and a time-only item is
/// exactly the second one.
ServiceItem _item({
  ServiceRollover rollover = ServiceRollover.fromActual,
  bool noDistance = false,
  int? intervalMonths,
}) => ServiceItem(
  id: _itemId,
  vehicleId: _vehicleId,
  kind: ServiceKind.oilAndFilter,
  intervalDistance: noDistance ? null : const Distance.fromKm(10000),
  intervalDistanceUnit: noDistance ? null : DistanceUnit.km,
  intervalMonths: intervalMonths,
  isTracked: true,
  priority: ServicePriority.normal,
  rollover: rollover,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

ServiceRecord _record(int km, String on) => ServiceRecord(
  id: ServiceRecordId.tryParse('srv_$_b')!,
  vehicleId: _vehicleId,
  occurredOn: on,
  odometer: Distance.fromKm(km),
  odometerUnit: DistanceUnit.km,
  lines: [
    ServiceLine(
      id: ServiceLineId.tryParse('lin_$_b')!,
      serviceRecordId: ServiceRecordId.tryParse('srv_$_b')!,
      serviceItemId: _itemId,
      label: 'Oil and filter',
      amount: Money(9250, Currency.tryParse('EUR')!),
    ),
  ],
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  test('re-anchors from the ACTUAL odometer, not the due odometer', () {
    // §10's own worked example, and the epic calls it "the test that fails if
    // anyone anchors on the due value". An item due at 186,000 km, the work
    // actually done at 187,412 km, a 10,000 km interval: the next one is due
    // at 197,412 and not at 196,000.
    //
    // Anchoring on the due value would quietly steal 1,412 km of interval from
    // a user who serviced their car late, every cycle, for ever.
    final next = nextDueAfterMarkDone(
      item: _item(),
      record: _record(187412, '2026-09-02'),
    );

    expect(next.odometer?.km, 197412);
  });

  test('an early service still anchors on what was entered', () {
    // The mirror case: finishing 3,000 km EARLY moves the next one earlier
    // too. §10 shows this in the confirmation panel precisely because it is the
    // consequence a user needs to see once.
    final next = nextDueAfterMarkDone(
      item: _item(),
      record: _record(183000, '2026-09-02'),
    );

    expect(next.odometer?.km, 193000);
  });

  test('a distance-only item names one axis and leaves the other empty', () {
    // §10: "A distance-only or time-only item names one axis." A date invented
    // for an item with no month interval would be a fact the app made up.
    final next = nextDueAfterMarkDone(
      item: _item(),
      record: _record(187412, '2026-09-02'),
    );

    expect(next.odometer, isNotNull);
    expect(next.date, isNull);
  });

  test('a time-only item names the date and leaves the odometer empty', () {
    final next = nextDueAfterMarkDone(
      item: _item(noDistance: true, intervalMonths: 12),
      record: _record(187412, '2026-09-02'),
    );

    expect(next.date?.toString(), '2027-09-02');
    expect(next.odometer, isNull);
  });

  test('both intervals give both halves of the pair', () {
    // §10's panel: "Next due at 197,412 km or September 2027 — whichever comes
    // first." Both, because the consequence of finishing early is only visible
    // when the two are seen together.
    final next = nextDueAfterMarkDone(
      item: _item(intervalMonths: 12),
      record: _record(187412, '2026-09-02'),
    );

    expect(next.odometer?.km, 197412);
    expect(next.date?.toString(), '2027-09-02');
  });

  test('from_due anchors the cycle, not the record', () {
    // §3's other rollover: an annual inspection stays on its anniversary
    // however late it was actually done, because the DEADLINE is the fact and
    // the visit is not.
    final next = nextDueAfterMarkDone(
      item: _item(
        rollover: ServiceRollover.fromDue,
        noDistance: true,
        intervalMonths: 12,
      ),
      record: _record(187412, '2026-11-20'),
      previousDueOn: '2026-09-02',
    );

    expect(
      next.date?.toString(),
      '2027-09-02',
      reason: 'the anniversary holds; the late visit does not move it',
    );
  });
}
