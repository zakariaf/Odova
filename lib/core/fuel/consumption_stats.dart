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

/// One segment's consumption.
Consumption segmentConsumption(FuelSegment segment) => segment.consumption;

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
    // Two different situations, and only one of them gets better with time.
    // There were no segments — log another full fill — versus there were
    // segments and NONE of them converts to this unit, which is a CNG car
    // asked for litres per 100 km. A driver of one was being told to keep
    // logging, forever.
    return list.isEmpty
        ? const Err(InsufficientData(have: 0, need: 1))
        : Err(UnitNotApplicable(unit.wire));
  }

  // Lower is better for fuel-per-distance, higher for distance-per-fuel.
  final wantLowest = unit.isFuelPerDistance == best;
  ranked.sort((a, b) {
    final byValue = wantLowest
        ? a.value.compareTo(b.value)
        : b.value.compareTo(a.value);
    // A stated tiebreak, so two runs agree and a golden vector stays valid.
    return byValue != 0
        ? byValue
        : a.segment.toFillUpId.compareTo(b.segment.toFillUpId);
  });

  return Ok(ranked.first);
}
