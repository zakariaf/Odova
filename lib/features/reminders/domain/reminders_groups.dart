// The three groups `reminders.list` draws, in the order SPEC.md §9 gives them.
//
// "Tracked and active, sorted by `projected_due_date` exactly as Home sorts and
// in the same dot/colour/wording vocabulary, so no legend is needed; `ok` items
// appear here with their next due, which is the difference between this screen
// and Home. Then **Paused** (`is_active = false`), greyed, no status. Then
// **Not tracked** (`is_tracked = false`), greyed, `+ Track` in place of a
// status."
//
// Pure Dart, no Flutter. The ORDER of the first group comes from
// `lib/core/due/due_order.dart`, which is the same comparator Home sorts with —
// §9 says "exactly as Home sorts", and two comparators would be two orders.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_order.dart';
import 'package:odova/core/due/due_summary.dart';

/// One row: an item, and what the engine concluded about it if anything did.
///
/// The assessment is null for a PAUSED or UNTRACKED item, and that is the
/// point: §3 excludes both from the due engine, so a row that carried one would
/// be showing a status nothing computed.
typedef ReminderRow = ({ServiceItem item, DueAssessment? assessment});

/// The whole screen, grouped and ordered.
@immutable
class ReminderGroups {
  /// Creates the groups.
  const ReminderGroups({
    required this.active,
    required this.paused,
    required this.notTracked,
  });

  /// Tracked and active, sorted the way Home sorts.
  final List<ReminderRow> active;

  /// `is_active = false`. Greyed, no status.
  final List<ReminderRow> paused;

  /// `is_tracked = false`. Greyed, `+ Track` in place of a status.
  final List<ReminderRow> notTracked;

  /// Whether the vehicle has no items at all — §9's `No reminders yet.`
  bool get isEmpty => active.isEmpty && paused.isEmpty && notTracked.isEmpty;

  /// Whether every tracked item is paused — §9's "Nothing is being tracked on
  /// this vehicle."
  ///
  /// It asks about the TRACKED ones only. A vehicle whose whole catalogue is
  /// untracked has not had anything turned off; it has not turned anything on,
  /// which is first run and a different sentence.
  bool get allPaused => active.isEmpty && paused.isNotEmpty;

  /// How many rows there are, for the header count.
  int get length => active.length + paused.length + notTracked.length;
}

/// Groups [items], attaching each tracked-and-active one's assessment.
///
/// [assessed] is the engine's output — one entry per ELIGIBLE item — so a row
/// missing from it is one the engine did not assess, which is exactly the
/// paused and untracked rows.
ReminderGroups groupReminders({
  required List<ServiceItem> items,
  required List<AssessedItem> assessed,
}) {
  final byId = {
    for (final (item, assessment) in assessed) item.id.toString(): assessment,
  };

  final active = <ReminderRow>[];
  final paused = <ReminderRow>[];
  final notTracked = <ReminderRow>[];

  for (final item in items) {
    if (!item.isTracked) {
      notTracked.add((item: item, assessment: null));
    } else if (!item.isActive) {
      paused.add((item: item, assessment: null));
    } else {
      active.add((item: item, assessment: byId[item.id.toString()]));
    }
  }

  active.sort((a, b) {
    // An item with no assessment sorts last among the active ones, by the same
    // rule `compareDueDates` applies to a missing date: the app has nothing to
    // order it by, and putting it first would put the row it knows least about
    // at the top of the screen.
    final aa = a.assessment;
    final bb = b.assessment;
    if (aa == null && bb == null) {
      return (a.item.label ?? '').compareTo(b.item.label ?? '');
    }
    if (aa == null) return 1;
    if (bb == null) return -1;
    return compareAssessedItems((a.item, aa), (b.item, bb));
  });

  // The two greyed groups keep the order the repository gave them, which is by
  // id and therefore stable. §9 gives them no sort of their own, and inventing
  // one would be a second answer about a list nobody is scanning for urgency.
  return ReminderGroups(
    active: List.unmodifiable(active),
    paused: List.unmodifiable(paused),
    notTracked: List.unmodifiable(notTracked),
  );
}
