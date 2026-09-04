// Is the car getting thirstier?
//
// SPEC.md §3 Fuel maths (`consumptionTrend`) and §12. The app says "getting
// thirstier" only when it is, because a false alarm is the one the user
// remembers — and the second one teaches them to ignore the app.
//
// The comparison is the LAST THREE tanks against the SIX before them, which is
// why nine is the floor: three points is not a trend, and a nine-segment
// history is about a year of driving for most people.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/value_equality.dart';

/// How many segments a verdict needs: the last 3 against the 6 before.
const trendSegmentFloor = 9;

/// The band inside which nothing is reported, as a percentage.
///
/// **SPEC.md says "a ±8% threshold" without saying whether the boundary is
/// inclusive.** Exactly 8.0% is treated as `steady` and only strictly more than
/// 8% alarms, because the rule exists to SUPPRESS false alarms — and a rule
/// written to suppress them should not fire at its own edge. Recorded as a
/// decision in the PR and in `epics/progress/EPIC-06.md`.
const trendBandPercent = 8.0;

/// Which way consumption is going.
enum TrendDirection {
  /// More fuel per distance than before.
  thirstier,

  /// Less.
  leaner,

  /// Inside the band.
  steady,
}

/// A verdict, and the two figures the UI quotes beside it.
@immutable
class ConsumptionTrend with ValueEquality {
  /// Creates a trend.
  const ConsumptionTrend({
    required this.direction,
    required this.recent,
    required this.previous,
    required this.changePercent,
  });

  /// Which way.
  final TrendDirection direction;

  /// The last three tanks, as one total-over-total figure.
  ///
  /// Carried because the UI says "Last 3 tanks 7.1, the 6 before 6.5" — a bare
  /// direction would leave the user with an assertion and no evidence.
  final Consumption recent;

  /// The six before them.
  final Consumption previous;

  /// How much [recent] differs from [previous], as a signed percentage.
  ///
  /// Positive means more fuel per distance.
  final double changePercent;

  @override
  List<Object?> get props => [direction, recent, previous, changePercent];
}

/// The trend over [segments], oldest first.
///
/// Returns `insufficientData` below [trendSegmentFloor]. Only VALID segments
/// count — a discarded pair is not in the list, so nine here means nine
/// measured tanks and not nine attempts.
Result<ConsumptionTrend, ConsumptionUnavailable> consumptionTrend(
  List<FuelSegment> segments,
) {
  if (segments.length < trendSegmentFloor) {
    return Err(
      InsufficientData(have: segments.length, need: trendSegmentFloor),
    );
  }

  // The whole run, checked ONCE, before the windows are cut.
  //
  // Checking each window separately proves the forms match within each and
  // NOTHING between them, so six charge segments followed by three petrol ones
  // passed both checks and produced a confident verdict comparing watt-hours
  // per metre against millilitres per metre — it read as "-40%, leaner". A
  // range-extender EV, or a bi-fuel car an importer landed under one
  // `fuel_kind`, is exactly that list.
  final window = segments.sublist(segments.length - trendSegmentFloor);
  if (FuelQuantity.sumOf(window.map((s) => s.quantity)) == null) {
    return const Err(MixedFuelForms());
  }

  final recent = _totalOverTotal(segments.sublist(segments.length - 3));
  final previous = _totalOverTotal(
    segments.sublist(segments.length - 9, segments.length - 3),
  );
  if (recent == null || previous == null) {
    // Unreachable now that the whole window is checked above, and kept
    // because `_totalOverTotal` is nullable and a silent `!` here would be the
    // next person's bug.
    return const Err(MixedFuelForms());
  }

  // Compared in the CANONICAL ratio, not in a display unit. Doing it in MPG
  // would invert the sign, and doing it in whatever the user has selected
  // would make the verdict depend on a setting.
  final recentRatio = _ratio(recent);
  final previousRatio = _ratio(previous);
  if (recentRatio == null || previousRatio == null || previousRatio == 0) {
    // A window with no distance or no fuel in it. `buildFuelSegments` discards
    // both, so this is unreachable from the builder and reachable from an
    // arbitrary list — and it is NOT a mixed-form problem, which the line
    // above already ruled out. Named as the non-positive-distance pair the
    // window actually contains, so the sentence points at rows.
    final offender = segments.firstWhere(
      (s) => !s.consumption.isComputable,
      orElse: () => segments.last,
    );
    return Err(
      NonPositiveDistance(
        fromFillUpId: offender.fromFillUpId,
        toFillUpId: offender.toFillUpId,
      ),
    );
  }

  final change = (recentRatio - previousRatio) / previousRatio * 100;

  // Compared at six decimal places, not raw. A change of exactly 8% computes
  // as 7.999999999999999 in binary floating point, so the boundary this rule
  // deliberately places — see [trendBandPercent] — would otherwise be decided
  // by where the float happened to land rather than by the rule. Six places is
  // far finer than anything the UI shows and far coarser than the wobble.
  final compared = roundHalfAwayFromZero(change, decimals: 6);

  return Ok(
    ConsumptionTrend(
      direction: switch (compared) {
        > trendBandPercent => TrendDirection.thirstier,
        < -trendBandPercent => TrendDirection.leaner,
        _ => TrendDirection.steady,
      },
      recent: recent,
      previous: previous,
      changePercent: change,
    ),
  );
}

/// Fuel per metre, the canonical ratio.
///
/// Null when the segment is not computable.
///
/// The unit of the numerator is whatever [Consumption.quantity]'s form is —
/// millilitres, grams or watt-hours — so two ratios are only comparable when
/// their segments share a form. [consumptionTrend] proves that over the WHOLE
/// nine-segment window before cutting it in two; proving it per window, which
/// is what it used to do, proves nothing across the seam.
double? _ratio(Consumption consumption) {
  if (!consumption.isComputable) return null;
  return consumption.quantity.amount / consumption.distance.metres;
}

/// The combined consumption of [segments], total over total.
///
/// Null when the segments do not share a fuel form. This used to be null for
/// every form EXCEPT litres, which meant `consumptionTrend` refused an
/// electric or CNG history no matter how many segments it had — the app
/// claiming not to know something it did know, which SPEC.md §2 forbids more
/// strongly than it forbids being wrong.
Consumption? _totalOverTotal(List<FuelSegment> segments) {
  final quantity = FuelQuantity.sumOf(segments.map((s) => s.quantity));
  if (quantity == null) return null;

  return Consumption(
    distance: Distance(segments.fold(0, (sum, s) => sum + s.distance.metres)),
    quantity: quantity,
  );
}
