// The figures `costs.fuel` shows.
//
// SPEC.md §3 Fuel maths and §12. The rule that matters is stated once and is
// easy to get wrong: the lifetime average is TOTAL OVER TOTAL, never a mean of
// the per-segment figures.
//
// The difference is not academic. A 40 km segment at 12 L/100 km and a 900 km
// segment at 6 L/100 km have a mean of 9.0 and a true average of 6.26. A mean
// of means over-weights the short segment, and for anyone who tops up in town
// it drifts several percent high — permanently, in the number they quote when
// they sell the car.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/value_equality.dart';

/// The lifetime average over [segments].
///
/// Total volume over total distance. See the file header for why this is not
/// the mean of the per-segment figures.
Result<Consumption, ConsumptionUnavailable> averageConsumption(
  Iterable<FuelSegment> segments,
) {
  final list = segments.toList();
  if (list.isEmpty) {
    return const Err(InsufficientData(have: 0, need: 1));
  }

  final distance = Distance(
    list.fold(0, (sum, s) => sum + s.distance.metres),
  );
  final quantity = FuelQuantity.sumOf(list.map((s) => s.quantity));
  if (quantity == null) {
    // Segments of different fuel FORMS in one list — litres beside watt-hours.
    // A total across them would be arithmetic on two different physical
    // things. NOT insufficiency: more fills will not help, and the sentence
    // "one more full fill" is advice that cannot work.
    return const Err(MixedFuelForms());
  }

  return Ok(Consumption(distance: distance, quantity: quantity));
}

/// A segment and its figure, for the best/worst rows.
@immutable
class RankedSegment with ValueEquality {
  /// Creates a ranked segment.
  const RankedSegment({required this.segment, required this.value});

  /// Which segment.
  ///
  /// Carried whole rather than as a number, because the UI shows the closing
  /// fill's DATE beside the figure — "6.1 L/100 km, 14 August" — and a bare
  /// double could not say when.
  final FuelSegment segment;

  /// Its consumption in the unit that was asked for.
  final double value;

  @override
  List<Object?> get props => [segment, value];
}

/// The most economical segment, in [unit].
///
/// "Best" depends on the unit's direction: lower is better in L/100 km and
/// higher is better in MPG. Getting that backwards makes the thirstiest tank
/// the best one, which is why `ConsumptionUnit.isFuelPerDistance` exists.
Result<RankedSegment, ConsumptionUnavailable> bestSegment(
  Iterable<FuelSegment> segments,
  ConsumptionUnit unit,
) => _rank(segments, unit, best: true);

/// The least economical segment, in [unit].
Result<RankedSegment, ConsumptionUnavailable> worstSegment(
  Iterable<FuelSegment> segments,
  ConsumptionUnit unit,
) => _rank(segments, unit, best: false);

/// The newest segment's consumption.
///
/// `Unavailable` when there is none — which includes the case where the newest
/// pair of fills was DISCARDED, because a discarded segment is not in the list
/// at all and "last tank" then means the one before it, not a guess about the
/// one that failed.
Result<Consumption, ConsumptionUnavailable> lastSegment(
  Iterable<FuelSegment> segments,
) {
  final list = segments.toList();
  if (list.isEmpty) {
    return const Err(InsufficientData(have: 0, need: 1));
  }
  return Ok(list.last.consumption);
}

Result<RankedSegment, ConsumptionUnavailable> _rank(
  Iterable<FuelSegment> segments,
  ConsumptionUnit unit, {
  required bool best,
}) {
  final list = segments.toList();
  final ranked = <RankedSegment>[];
  for (final segment in list) {
    final value = segment.consumption.asUnit(unit);
    if (value != null) {
      ranked.add(RankedSegment(segment: segment, value: value));
    }
  }

  if (ranked.isEmpty) {
    // THREE different situations, and `asUnit`'s `null` does not distinguish
    // them — it means both "this form has no such unit" and "this segment is
    // not measurable". Collapsing them told a diesel driver whose segments all
    // measured zero distance that litres per 100 km does not apply to their
    // car.
    if (list.isEmpty) {
      // Log another full fill. The only one of the three that time fixes.
      return const Err(InsufficientData(have: 0, need: 1));
    }

    final unmeasurable = list.where((s) => !s.consumption.isComputable);
    if (unmeasurable.length == list.length) {
      // Every segment has no distance or no fuel. The unit is fine; the data
      // is not, and the fill ids say which rows.
      final first = unmeasurable.first;
      return Err(
        NonPositiveDistance(
          fromFillUpId: first.fromFillUpId,
          toFillUpId: first.toFillUpId,
        ),
      );
    }

    // Measurable segments that this unit cannot express: a CNG car asked for
    // litres per 100 km. No number of fills will help, and the placeholder
    // this replaced said "one more full fill".
    return Err(UnitNotApplicable(unit.wire));
  }

  // Lower is better for fuel-per-distance, higher for distance-per-fuel.
  final wantLowest = unit.isFuelPerDistance == best;
  int compare(RankedSegment a, RankedSegment b) {
    final byValue = wantLowest
        ? a.value.compareTo(b.value)
        : b.value.compareTo(a.value);
    // A stated tiebreak, so two runs agree and a golden vector stays valid.
    return byValue != 0
        ? byValue
        : a.segment.toFillUpId.compareTo(b.segment.toFillUpId);
  }

  // A fold, not a sort. Only the first element is wanted and this is called
  // twice per screen — `bestSegment` and `worstSegment` — so a ten-year
  // history was two full sorts of ~900 segments to read two of them. The
  // comparator is the same one, so the tiebreak and the determinism are too.
  return Ok(ranked.reduce((a, b) => compare(a, b) <= 0 ? a : b));
}
