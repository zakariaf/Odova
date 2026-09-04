// SPEC.md §3's `buildFuelSegments`, line for line.
//
// The pseudocode is short and every line of it is load-bearing. The one that
// causes the most bugs in this category is `pending = []` after opening: the
// OPENING fill's own fuel belongs to the segment BEFORE it, not the one it
// starts, because that fuel filled the tank for the distance already travelled.
// Getting it wrong shifts every figure in the app by one tank, and the result
// looks entirely plausible.
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';

/// One fill-up, reduced to what the segment builder needs.
///
/// Deliberately not the domain `FillUp`: this is pure domain logic and takes
/// the CUMULATIVE odometer, which only the repository can compute. Passing the
/// model would mean either the engine reaching for corrections or the caller
/// hoping the raw dash number is comparable — and it is not, across a cluster
/// swap.
typedef FillUpPoint = ({
  String id,
  String occurredOn,
  int createdAtUtcMs,
  String fuelKind,

  /// Cumulative metres, correction-aware. Null means the fill had no reading.
  int? cumulativeM,
  FuelQuantity quantity,
  bool isFullTank,
  bool chainBroken,

  /// The vehicle's tank size, for the jerrycan warning. Null means unknown.
  int? tankCapacityMl,
});

/// Orders fills the way SPEC.md §3 does: `(occurred_on, odometer, created_at)`.
///
/// The created-at tiebreak is SPEC.md §14's rule for two fills on the same day,
/// and it is what makes the output independent of the order rows came back in.
/// A fill with no odometer sorts as if it were at zero — it breaks the chain
/// either way, so its position only has to be deterministic.
int compareFills(FillUpPoint a, FillUpPoint b) {
  final byDate = a.occurredOn.compareTo(b.occurredOn);
  if (byDate != 0) return byDate;
  final byOdometer = (a.cumulativeM ?? 0).compareTo(b.cumulativeM ?? 0);
  if (byOdometer != 0) return byOdometer;
  final byCreated = a.createdAtUtcMs.compareTo(b.createdAtUtcMs);
  return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
}

/// Builds the full-to-full segments for ONE fuel kind.
///
/// Total: it never throws and never returns null. Every rejection is a flagged
/// fill or an absent segment, because SPEC.md §3 would rather show a dash than
/// a number the user would believe.
///
/// [fills] need not be sorted, and must all be of one fuel kind — use
/// [buildFuelSegmentsByKind] otherwise. A bi-fuel car has two independent
/// series and merging them would treat an LPG fill as a petrol chain break.
FuelSegmentSet buildFuelSegments(Iterable<FillUpPoint> fills) {
  final ordered = [...fills]..sort(compareFills);

  final segments = <FuelSegment>[];
  final discarded = <String, ConsumptionUnavailable>{};
  final warnings = <String, Set<FuelWarning>>{};

  FillUpPoint? open;
  var pending = <FillUpPoint>[];

  for (final fill in ordered) {
    _warnIfOverTank(fill, warnings);

    // A break: the user missed a fill, or this one has no reading. The segment
    // that would have closed here is DISCARDED — not averaged, not pro-rated.
    // A new one opens here only if this fill is itself full and readable.
    if (fill.chainBroken || fill.cumulativeM == null) {
      // Two different sentences and two different fixes. A missing odometer is
      // something the user can supply; a chain break is a fill-up they did not
      // log. Telling them the chain broke when the reading is simply absent
      // sends them looking for a fill-up that never happened.
      discarded[fill.id] = fill.cumulativeM == null
          ? MissingOdometer(fill.id)
          : ChainBroken(fill.id);
      open = (fill.isFullTank && fill.cumulativeM != null) ? fill : null;
      pending = [];
      continue;
    }

    // Nothing open yet: only a full fill can start a segment, and its own fuel
    // is NOT part of it — hence the empty `pending`.
    if (open == null) {
      open = fill.isFullTank ? fill : null;
      pending = [];
      continue;
    }

    pending.add(fill);

    if (!fill.isFullTank) continue;

    final distance = Distance(fill.cumulativeM! - open.cumulativeM!);
    final quantity = FuelQuantity.sumOf(pending.map((f) => f.quantity));

    if (distance.metres > 0 && quantity != null && !quantity.isZero) {
      segments.add(
        FuelSegment(
          fromFillUpId: open.id,
          toFillUpId: fill.id,
          distance: distance,
          quantity: quantity,
          // The closing fill is in `pending` and is not a partial.
          partialCount: pending.length - 1,
        ),
      );
    } else {
      // Two fills at the same odometer, or a distance running backwards. A
      // data error, and BOTH fills are named because only the user knows which
      // of the two numbers is wrong. Never a 0 L/100 km.
      //
      // The reason carries BOTH ids on both entries, so a row highlighted in
      // the list can say which other row it conflicts with — "this reading and
      // the one on 3 September are the same number" is actionable and "check
      // this fill-up" is not.
      final reason = NonPositiveDistance(
        fromFillUpId: open.id,
        toFillUpId: fill.id,
      );
      discarded[open.id] = reason;
      discarded[fill.id] = reason;
    }

    open = fill;
    pending = [];
  }

  return FuelSegmentSet(
    segments: segments,
    discarded: discarded,
    warnings: warnings,
  );
}

/// Builds segments for every fuel kind present, independently.
///
/// SPEC.md §3: "a bi-fuel LPG car has two consumption series and the app never
/// merges them". Neither series sees the other's fills at all, so an LPG fill
/// between two petrol fills is not a petrol chain break.
Map<String, FuelSegmentSet> buildFuelSegmentsByKind(
  Iterable<FillUpPoint> fills,
) {
  final byKind = <String, List<FillUpPoint>>{};
  for (final fill in fills) {
    byKind.putIfAbsent(fill.fuelKind, () => []).add(fill);
  }
  return {
    for (final entry in byKind.entries)
      entry.key: buildFuelSegments(entry.value),
  };
}

/// Warns when a fill is more than 15% over the tank.
///
/// A WARNING and not a rejection. SPEC.md §3: some people carry a jerrycan, and
/// refusing the row would lose a real fill-up to protect a heuristic.
void _warnIfOverTank(FillUpPoint fill, Map<String, Set<FuelWarning>> into) {
  final capacity = fill.tankCapacityMl;
  if (capacity == null || capacity <= 0) return;

  final quantity = fill.quantity;
  if (quantity is! LiquidVolume) return;

  if (quantity.volume.millilitres * 100 > capacity * 115) {
    into.putIfAbsent(fill.id, () => {}).add(FuelWarning.volumeExceedsTank);
  }
}

/// Why [set] holds no segments, given the [fills] it was built from.
///
/// Null once there IS a figure. "No segments" is one state on screen and five
/// different sentences, and the difference lives entirely in the fills — which
/// is why this takes both and why it is here rather than on [FuelSegmentSet].
///
/// The ORDER is the design. A data error outranks everything, because it is
/// the one the user can act on today; an EV that never marks a charge full
/// outranks the opening fill, because ticking a box is also actionable; and
/// [FirstFill] is last, because "your first figure arrives at your next full
/// fill" is the only one of the five that is not a task.
ConsumptionUnavailable? whyNoSegments(
  Iterable<FillUpPoint> fills,
  FuelSegmentSet set,
) {
  if (set.segments.isNotEmpty) return null;

  final list = fills.toList();
  if (list.isEmpty) {
    // TWO, not one: a segment needs a full fill to open it and a full fill to
    // close it. Telling a new user they need one more would be wrong on the
    // day they log it.
    return const InsufficientData(have: 0, need: 2);
  }

  // The first discard in fill order, so the sentence points at the earliest
  // row the user can fix rather than at whichever the map happened to hold.
  for (final fill in [...list]..sort(compareFills)) {
    final reason = set.discarded[fill.id];
    if (reason != null) return reason;
  }

  // SPEC.md §3: "full" for an EV means the driver's usual charge target, which
  // only they can say. The app shows cost per distance only, and SAYS SO —
  // this is the saying so.
  if (list.every((f) => f.quantity is ElectricEnergy) &&
      !list.any((f) => f.isFullTank)) {
    return const NoFullCharge();
  }

  return const FirstFill();
}
