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
import 'package:odova/core/fuel/fuel_result.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
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
FuelValue<ConsumptionTrend> consumptionTrend(List<FuelSegment> segments) {
  if (segments.length < trendSegmentFloor) {
    return Unavailable(
      InsufficientData(have: segments.length, need: trendSegmentFloor),
    );
  }

  final recent = _totalOverTotal(segments.sublist(segments.length - 3));
  final previous = _totalOverTotal(
    segments.sublist(segments.length - 9, segments.length - 3),
  );
  if (recent == null || previous == null) {
    // Mixed fuel forms in one list: the caller split by fuel kind wrongly.
    return const Unavailable(
      InsufficientData(have: 0, need: trendSegmentFloor),
    );
  }

  // Compared in the CANONICAL ratio, not in a display unit. Doing it in MPG
  // would invert the sign, and doing it in whatever the user has selected
  // would make the verdict depend on a setting.
  final recentRatio = _ratio(recent);
  final previousRatio = _ratio(previous);
  if (recentRatio == null || previousRatio == null || previousRatio == 0) {
    return const Unavailable(
      InsufficientData(have: 0, need: trendSegmentFloor),
    );
  }

  final change = (recentRatio - previousRatio) / previousRatio * 100;

  // Compared at six decimal places, not raw. A change of exactly 8% computes
  // as 7.999999999999999 in binary floating point, so the boundary this rule
  // deliberately places — see [trendBandPercent] — would otherwise be decided
  // by where the float happened to land rather than by the rule. Six places is
  // far finer than anything the UI shows and far coarser than the wobble.
  final compared = roundHalfAwayFromZero(change, decimals: 6);

  return Computed(
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

/// Fuel per metre, the canonical ratio. Null when the forms differ.
double? _ratio(Consumption consumption) {
  if (!consumption.isComputable) return null;
  final quantity = consumption.quantity;
  final amount = switch (quantity) {
    LiquidVolume(:final volume) => volume.millilitres,
    GasMass(:final mass) => mass.grams,
    ElectricEnergy(:final energy) => energy.wattHours,
  };
  return amount / consumption.distance.metres;
}

/// The combined consumption of [segments], total over total.
Consumption? _totalOverTotal(List<FuelSegment> segments) {
  if (segments.isEmpty) return null;
  if (segments.any((s) => s.quantity is! LiquidVolume)) {
    // The non-liquid forms are handled by the same shape; kept narrow here
    // because a mixed list is a caller error rather than a case to support.
    final first = segments.first.quantity.runtimeType;
    if (segments.any((s) => s.quantity.runtimeType != first)) return null;
  }

  final distance = Distance(
    segments.fold(0, (sum, s) => sum + s.distance.metres),
  );

  final quantities = segments.map((s) => s.quantity).toList();
  if (quantities.every((q) => q is LiquidVolume)) {
    return Consumption(
      distance: distance,
      quantity: LiquidVolume(
        Volume(
          quantities.fold(
            0,
            (sum, q) => sum + (q as LiquidVolume).volume.millilitres,
          ),
        ),
      ),
    );
  }
  return null;
}
