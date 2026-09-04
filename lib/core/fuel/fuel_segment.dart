// A full tank to the next full tank.
//
// SPEC.md §3 Fuel maths. A segment is the only unit over which consumption can
// be MEASURED rather than estimated: the tank was full at both ends, so
// everything bought in between went into the distance travelled in between.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/value_equality.dart';

/// One full-to-full stretch.
@immutable
class FuelSegment with ValueEquality {
  /// Creates a segment.
  const FuelSegment({
    required this.fromFillUpId,
    required this.toFillUpId,
    required this.distance,
    required this.quantity,
    required this.partialCount,
  });

  /// The full fill that opened it.
  ///
  /// Its OWN fuel is not in [quantity] — that fuel filled the tank for the
  /// distance BEFORE this segment. Getting this wrong is the classic off-by-one
  /// in this whole category, and it shifts every figure by one tank.
  final String fromFillUpId;

  /// The full fill that closed it.
  final String toFillUpId;

  /// How far, in cumulative correction-aware metres.
  final Distance distance;

  /// Everything bought between the two, the closing fill included.
  final FuelQuantity quantity;

  /// How many partial fills are inside it.
  ///
  /// Shown to the user, because a segment with four partials is a segment they
  /// may want to look at.
  final int partialCount;

  /// This segment's consumption, ready to convert.
  Consumption get consumption =>
      Consumption(distance: distance, quantity: quantity);

  @override
  List<Object?> get props => [
    fromFillUpId,
    toFillUpId,
    distance,
    quantity,
    partialCount,
  ];

  @override
  String toString() =>
      'FuelSegment($fromFillUpId -> $toFillUpId, $distance, $quantity)';
}

/// Something worth telling the user about a segment, that does not discard it.
enum FuelWarning {
  /// More fuel than the tank holds, by more than 15%.
  ///
  /// SPEC.md §3: saved WITH a warning. Some people carry a jerrycan, and
  /// refusing the row would lose a real fill-up to protect a heuristic.
  volumeExceedsTank,
}

/// The result of building segments for one fuel kind.
@immutable
class FuelSegmentSet with ValueEquality {
  /// Creates a set.
  const FuelSegmentSet({
    required this.segments,
    required this.discarded,
    required this.warnings,
  });

  /// Nothing at all.
  static const empty = FuelSegmentSet(
    segments: [],
    discarded: {},
    warnings: {},
  );

  /// The measurable stretches, in order.
  final List<FuelSegment> segments;

  /// Fills the user should look at, and WHY, by fill id.
  ///
  /// Flagged rather than corrected, because only the user knows which of two
  /// identical readings is wrong. The reason travels with the id because the
  /// builder is the only thing that knows it: a chain break, a missing
  /// odometer and a backwards reading are three different sentences and three
  /// different fixes, and SPEC.md §3 spells all three separately.
  ///
  /// This used to be a bare `List<String>`, and the reason was computed here
  /// and discarded. A screen given only the ids has two options and both are
  /// wrong: one generic sentence for four problems, or a second
  /// implementation of the discard rules that drifts from this one.
  final Map<String, ConsumptionUnavailable> discarded;

  /// Just the ids, sorted — for a caller that only wants to highlight rows.
  ///
  /// Sorted so two runs agree; the map's own order follows the fill order,
  /// which is stable but is not what a caller comparing two sets wants.
  List<String> get flaggedFillUpIds => discarded.keys.toList()..sort();

  /// Warnings, by the fill they concern.
  final Map<String, Set<FuelWarning>> warnings;

  @override
  List<Object?> get props => [
    ...segments,
    // Sorted ids AND the reasons themselves. Encoding only `code` would make
    // two sets equal whose `NonPositiveDistance` named different conflicting
    // fills — the `MoneyTotal` bug again, where a field was half-encoded and
    // two "equal" values answered a question differently.
    for (final id in flaggedFillUpIds) ...[id, discarded[id]],
    for (final entry in warnings.entries)
      '${entry.key}:${entry.value.map((w) => w.name).toList()..sort()}',
  ];
}
