// SPEC.md §12's business split — the one figure on these screens that goes on
// a tax form.
//
//   businessShare = Σ tripDistance(purpose = business)
//                 / Σ tripDistance(all trips in range)
//
// The denominator is LOGGED TRIP distance, never vehicle distance, and §12's
// caption says so to the user: "Worked out from the trips you logged, not from
// all your driving."
//
// §12 is explicit elsewhere that "trip distances are never summed into vehicle
// distance — people log some trips, not all". Dividing business trips by the
// odometer would understate the share by however much driving went unlogged,
// and on a tax form that is not a rounding error. Using the odometer is the
// obvious mistake here precisely because it looks more complete.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/distance.dart';

/// One trip, reduced to what the share needs.
typedef TripLeg = ({Distance distance, TripPurpose purpose});

/// The whole-percentage business share of [legs], or null when unknowable.
///
/// NULL and not zero when there is nothing to divide. Zero is a claim — it
/// says none of the driving was business — and §12 hides the row entirely
/// rather than printing a figure it cannot support.
///
/// Rounded to a whole percentage. §12 prints `62%`, and a decimal place on a
/// figure derived from hand-typed odometer readings claims a precision the
/// data does not have.
int? businessShare(List<TripLeg> legs) {
  var business = 0;
  var total = 0;

  for (final leg in legs) {
    final metres = leg.distance.metres;
    total += metres;
    // `business` ONLY. `commute` is a separate purpose in §10's enum, and
    // rolling it in is the single easiest way to overstate a deduction —
    // in most jurisdictions the drive to a regular workplace is not
    // deductible at all.
    if (leg.purpose == TripPurpose.business) business += metres;
  }

  if (total <= 0) return null;
  return (business * 100 / total).round();
}
