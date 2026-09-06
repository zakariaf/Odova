// What a write to the past actually changed.
//
// SPEC.md §11: "A record's odometer or date is an input to every derived
// number after it. Correcting a 2019 fill-up from 89,204 to 98,204 km changes
// two segments, the lifetime average, every cost-per-km figure since, the
// daily-distance estimate, the projected odometer, and every reminder's
// projected due date — which changes what the OS has scheduled."
//
// §11 chooses the blunt instrument deliberately: "Invalidate whole vehicles,
// not dependency subgraphs … the fine-grained 'which segments does this touch'
// graph is forty lines of subtle code guarding a recompute that costs
// single-digit milliseconds, and a cache that is wrong is worse than one that
// is cold."
//
// So what this file holds is not the recompute — that is the existing engines,
// re-run — but the DIFF between the vehicle's derived values before and after.
// Two things depend on being able to answer "what actually moved":
//
//   1. **The snackbar.** §11's messages count things: "14 later fuel figures
//      recalculated". Counting the rows the user touched would say that for an
//      edit that changed a vendor name.
//   2. **The notification rebuild.** §11 fires it only "if any status, due_on
//      or due_at_odometer_m changed". Firing unconditionally would re-schedule
//      every pending notification for an edit that moved nothing — and iOS
//      gives an app a limited budget of them.
//
// Pure Dart, no Flutter import. Nothing here is ever written to storage: §2
// makes every derived value a pure function computed at read time, and a
// stored diff would be the second copy of a fact.
import 'package:meta/meta.dart';
import 'package:odova/core/due/due_state.dart';

/// The three facts §11 watches on a due item.
///
/// Only three, and named rather than "the whole assessment": a due state also
/// carries a progress fraction and a confidence, and neither of those should
/// wake a phone at eight in the morning.
@immutable
class DueFacts {
  /// Creates the facts.
  const DueFacts({required this.state, this.dueOn, this.dueAtOdometerM});

  /// What a card renders.
  final DueState state;

  /// The date it is due, if it has one.
  final String? dueOn;

  /// The odometer it is due at, if it has one.
  final int? dueAtOdometerM;

  @override
  bool operator ==(Object other) =>
      other is DueFacts &&
      other.state == state &&
      other.dueOn == dueOn &&
      other.dueAtOdometerM == dueAtOdometerM;

  @override
  int get hashCode => Object.hash(state, dueOn, dueAtOdometerM);

  @override
  String toString() => 'DueFacts($state, $dueOn, $dueAtOdometerM)';
}

/// A vehicle's derived values at one instant.
///
/// Taken BEFORE the write and again after it. §11's step 5 shows the snackbar
/// last, and it can only be honest because step 2 kept what the numbers were.
@immutable
class RecomputeSnapshot {
  /// Creates a snapshot.
  const RecomputeSnapshot({
    this.consumptionByFillUp = const {},
    this.dueByItem = const {},
  });

  /// Each fill's consumption figure, or null where it has none.
  ///
  /// Null is a VALUE here and not an absence: a fill that had a figure and
  /// lost one has changed, and so has a fill that gained one, and neither
  /// shows up if the map only holds the fills that have figures.
  final Map<String, double?> consumptionByFillUp;

  /// Each reminder's three watched facts.
  final Map<String, DueFacts> dueByItem;
}

/// What moved between two snapshots.
@immutable
class RecomputeDiff {
  /// Creates a diff.
  const RecomputeDiff({
    required this.changedConsumptionCount,
    required this.changedDueItemIds,
  });

  /// How many consumption figures are different.
  final int changedConsumptionCount;

  /// Which reminders' watched facts moved.
  final Set<String> changedDueItemIds;

  /// Whether the OS schedule has to be rebuilt.
  bool get needsScheduleRebuild => changedDueItemIds.isNotEmpty;

  /// Whether §11's "Saved" is the honest message.
  bool get changedNothing =>
      changedConsumptionCount == 0 && changedDueItemIds.isEmpty;
}

/// What changed between [before] and [after].
RecomputeDiff diffRecompute({
  required RecomputeSnapshot before,
  required RecomputeSnapshot after,
}) {
  // The UNION of both key sets, so an id present on one side only is counted.
  // Correcting an odometer can close a segment that was discarded — a figure
  // the user did not have before — and can open one that was closed.
  final fills = {
    ...before.consumptionByFillUp.keys,
    ...after.consumptionByFillUp.keys,
  };
  var changed = 0;
  for (final id in fills) {
    if (before.consumptionByFillUp[id] != after.consumptionByFillUp[id]) {
      changed++;
    }
  }

  final items = {...before.dueByItem.keys, ...after.dueByItem.keys};
  final movedItems = <String>{};
  for (final id in items) {
    // A reminder that disappeared counts: it has pending notifications that
    // must not fire. So does one that appeared.
    if (before.dueByItem[id] != after.dueByItem[id]) movedItems.add(id);
  }

  return RecomputeDiff(
    changedConsumptionCount: changed,
    changedDueItemIds: Set.unmodifiable(movedItems),
  );
}
