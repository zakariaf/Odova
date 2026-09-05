// The one order due items are shown in.
//
// SPEC.md §9 *Ordering*, and it is used twice: Home's three cards and
// `reminders.list`'s first group are "sorted by `projected_due_date` exactly as
// Home sorts". Two comparators would be two orders, and the second one is
// always the one a user notices.
//
// Pure Dart, no Flutter. One sort key — the projected due date — and overdue
// items float on it because their dates are in the past. That is the whole
// reason the engine projects a date for the distance axis: without it, "overdue
// by 1,400 km" and "due in three weeks" cannot be ordered against each other at
// all.
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/time/civil_date.dart';

/// §9's ordering rules 1 and 4, in one comparator.
int compareAssessedItems(AssessedItem a, AssessedItem b) {
  final byDate = compareDueDates(
    a.$2.projectedDueDate,
    b.$2.projectedDueDate,
  );
  if (byDate != 0) return byDate;

  final bySeverity = dueSeverity(a.$2.state).compareTo(dueSeverity(b.$2.state));
  if (bySeverity != 0) return bySeverity;

  return (a.$1.label ?? '').compareTo(b.$1.label ?? '');
}

/// Two projected dates, with "no date at all" sorting LAST.
///
/// An item with no projected date has no place on the axis the rest are ordered
/// by, and putting it first would give the primary slot to the item the app
/// knows least about.
int compareDueDates(CivilDate? a, CivilDate? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Worst first. Only an ORDERING, never a colour — the colour is
/// `CalmStatusStyle`'s and nothing here asks for one.
int dueSeverity(DueState state) => switch (state) {
  DueState.overdue => 0,
  DueState.due => 1,
  DueState.needsOdometer => 2,
  DueState.dueSoon => 3,
  DueState.unknown => 4,
  DueState.ok => 5,
};
