// SPEC.md §12's numbers, and the three refusals that go with them.
//
// The sentence that shapes `costPerDistance`, and the reason it takes readings
// rather than an odometer estimate:
//
//   "Cost per distance uses MEASURED READINGS ONLY, never the projected
//    odometer: a projection grows while the app sits unopened, so yesterday's
//    cost per kilometre would differ from today's with no new data."
//
// That is not a rounding concern — it is a figure that moves on its own, on
// the screen a user opens to check whether the car got cheaper. The engine
// that produces estimates is deliberately not imported here.
import 'package:meta/meta.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';

/// Why a figure is a dash or a soft number.
///
/// A CODE, never a sentence: §2 keeps user-facing strings out of the core so
/// they can be translated, mirrored and digit-shaped at the edge. The reason
/// still comes FROM here — §12 requires every dash to carry one, and a widget
/// inventing its own would drift from the condition that produced it.
enum CostReason {
  /// `distanceBetween` < 100 km.
  notEnoughDistance,

  /// A boundary reading is more than 45 days from its boundary date.
  boundaryReadingStale,

  /// `completedMonths` < 1.
  noCompletedMonth,

  /// There is no reading at all to measure between.
  noReadings,
}

/// §12's three treatments for a derived figure.
///
/// Sealed, and the three are genuinely different SCREENS: exact prints a
/// number, estimated prints one with the estimate treatment and a tap
/// explanation, absent prints a dash. Collapsing estimated into absent hides a
/// usable figure; collapsing it into exact states a shaky one as fact.
@immutable
sealed class CostFigure {
  /// Creates a figure.
  const CostFigure();
}

/// A figure the app stands behind.
@immutable
final class CostExact extends CostFigure {
  /// Creates an exact figure.
  const CostExact({this.minorPerKm, this.minorPerMonth});

  /// Minor units per kilometre.
  final int? minorPerKm;

  /// Minor units per completed month.
  final int? minorPerMonth;
}

/// A figure whose inputs are further apart than §12 likes.
@immutable
final class CostEstimated extends CostFigure {
  /// Creates an estimated figure.
  const CostEstimated({
    required this.minorPerKm,
    required this.boundaryGapDays,
  });

  /// The figure itself — it IS shown, with the estimate treatment.
  final int minorPerKm;

  /// How far the worst boundary reading is from its boundary date, which §12's
  /// explanation quotes back: "readings 62 days apart from the dates shown".
  final int boundaryGapDays;
}

/// No figure, and why.
@immutable
final class CostAbsent extends CostFigure {
  /// Creates an absence.
  const CostAbsent(this.reason);

  /// Which of §12's conditions produced the dash.
  final CostReason reason;
}

/// §12's `totalCost`, grouped and never summed across currencies.
MoneyTotal totalCost({required List<Money> amounts}) => MoneyTotal(amounts);

/// §12's `costPerMonth`.
CostFigure costPerMonth({required Money total, required CostRange range}) {
  final months = range.completedMonths;
  // §12: "Come back after the end of the month — there isn't a full month to
  // average yet." Dividing by zero months would throw; dividing by a clamped
  // one would state a month's cost for a period that had none.
  if (months < 1) return const CostAbsent(CostReason.noCompletedMonth);
  return CostExact(minorPerMonth: total.amountMinor ~/ months);
}

/// §12's minimum distance before a per-distance figure means anything.
const int kMinimumCostDistanceKm = 100;

/// How far a boundary reading may sit from its boundary date.
const int kBoundaryReadingToleranceDays = 45;

/// §12's `costPerDistance`, from MEASURED readings only.
CostFigure costPerDistance({
  required Money total,
  required List<ReadingPoint> readings,
  required List<CorrectionPoint> corrections,
  required CostRange range,
}) {
  if (readings.isEmpty) return const CostAbsent(CostReason.noReadings);

  final sorted = [...readings]..sort(compareReadings);
  final cumulative = cumulativeBySorted(sorted, corrections);

  // §12: "a = last OdometerReading with occurred_on <= from (ELSE the earliest
  // reading)". The fallback is what keeps a vehicle added mid-range from
  // blanking the figure entirely.
  final a = _lastAtOrBefore(sorted, range.from) ?? sorted.first;
  final b = _lastAtOrBefore(sorted, range.to);
  if (b == null) return const CostAbsent(CostReason.noReadings);

  final from = cumulative[a.id] ?? a.odometer;
  final to = cumulative[b.id] ?? b.odometer;
  final metres = to.metres - from.metres;
  final km = metres ~/ 1000;

  if (km < kMinimumCostDistanceKm) {
    return const CostAbsent(CostReason.notEnoughDistance);
  }

  final perKm = total.amountMinor ~/ km;

  // The worst of the two gaps, because §12's explanation names one number and
  // the honest one to name is the larger.
  final gap = [
    _gapDays(a.occurredOn, range.from),
    _gapDays(b.occurredOn, range.to),
  ].reduce((x, y) => x > y ? x : y);

  return gap > kBoundaryReadingToleranceDays
      ? CostEstimated(minorPerKm: perKm, boundaryGapDays: gap)
      : CostExact(minorPerKm: perKm);
}

ReadingPoint? _lastAtOrBefore(List<ReadingPoint> sorted, CivilDate boundary) {
  ReadingPoint? found;
  for (final r in sorted) {
    final on = CivilDate.tryParseOrNull(r.occurredOn);
    if (on == null || on > boundary) continue;
    found = r;
  }
  return found;
}

int _gapDays(String isoDate, CivilDate boundary) {
  final on = CivilDate.tryParseOrNull(isoDate);
  if (on == null) return 0;
  final days = on.daysUntil(boundary);
  return days < 0 ? -days : days;
}
