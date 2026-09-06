// SPEC.md §12's business split: the one row that goes on a tax form.
//
//   businessShare = Σ tripDistance(purpose = business)
//                 / Σ tripDistance(all trips in range)
//
// The denominator is LOGGED TRIP distance, not vehicle distance, and §12's
// caption says so out loud: "Worked out from the trips you logged, not from
// all your driving." §12 is explicit elsewhere that "trip distances are never
// summed into vehicle distance — people log some trips, not all", and dividing
// business trips by the odometer would understate the share by however much
// driving went unlogged. On a tax form that is not a rounding error.
@TestOn('vm')
library;

import 'package:odova/core/costs/business_share.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

TripLeg leg(int km, TripPurpose purpose) =>
    (distance: Distance.fromKm(km), purpose: purpose);

void main() {
  test('is business distance over LOGGED trip distance', () {
    // 1,200 business of 2,000 logged. The vehicle may have driven 50,000 in
    // the range; it is not the denominator.
    final share = businessShare([
      leg(1200, TripPurpose.business),
      leg(500, TripPurpose.personal),
      leg(300, TripPurpose.commute),
    ]);

    expect(share, 60);
  });

  test('a commute is not business', () {
    // §12 gives `business`, `commute` and `personal` as separate purposes.
    // Rolling commuting into business is the single easiest way to overstate
    // a deduction.
    expect(
      businessShare([
        leg(1000, TripPurpose.commute),
        leg(1000, TripPurpose.personal),
      ]),
      0,
    );
  });

  test('all-business is 100 and no-business is 0', () {
    expect(businessShare([leg(500, TripPurpose.business)]), 100);
    expect(businessShare([leg(500, TripPurpose.personal)]), 0);
  });

  test('no trips at all is NULL, not zero', () {
    // Zero is a claim — it says none of the driving was business. Null says
    // the app does not know, and §12 hides the row entirely for it.
    expect(businessShare(const []), isNull);
  });

  test('trips with no distance are null rather than a division by zero', () {
    expect(
      businessShare([
        leg(0, TripPurpose.business),
        leg(0, TripPurpose.personal),
      ]),
      isNull,
    );
  });

  test('the share is a whole percentage, rounded to nearest', () {
    // §12 prints `62%`. One decimal on a tax-form figure invites a precision
    // the underlying data does not have — the distances come from odometer
    // readings the user typed.
    expect(
      businessShare([
        leg(2, TripPurpose.business),
        leg(1, TripPurpose.personal),
      ]),
      67,
      reason: '66.67 rounds to 67',
    );
  });
}
