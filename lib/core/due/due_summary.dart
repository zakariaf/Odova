// The two per-vehicle rollups every list in the app reads.
//
// SPEC.md §3 *Derived values*, and §8's garage status-dot table — which is the
// only consumer with a stated shape and the reason `DueSummary` carries more
// than counts:
//
//   any overdue          filled red     "Oil and filter overdue"
//   any due / due_soon   filled amber   "Oil due in 3 days"
//   all ok               small grey     "All good"
//   any needs_odometer   hollow ring    "Odometer needs updating"
//   all unknown / none   hollow ring    "No reminders yet"
//
// That third column needs the item's LABEL. A `Map<DueState,int>` cannot supply
// one, so the row could not be built from §3's "status counts" alone.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// One item and what the engine concluded about it.
typedef AssessedItem = (ServiceItem, DueAssessment);

/// What a vehicle's reminders add up to.
@immutable
class DueSummary with ValueEquality {
  /// Creates a summary.
  const DueSummary({required this.counts, this.worst, this.worstItem});

  /// How many eligible items are in each state. States with none are absent
  /// rather than zero, so `counts.isEmpty` means "nothing to report".
  final Map<DueState, int> counts;

  /// The assessment of the item a caller should name first.
  final DueAssessment? worst;

  /// The item that assessment belongs to.
  ///
  /// **Beyond SPEC.md §3's "status counts", and added in the same PR that adds
  /// it to the spec.** §8's garage row reads "Oil and filter overdue", and a
  /// count cannot say "Oil and filter".
  final ServiceItem? worstItem;

  @override
  List<Object?> get props => [
    for (final state in DueState.values) '${state.name}:${counts[state]}',
    worst,
    worstItem?.id,
  ];

  @override
  String toString() => 'DueSummary($counts, worst: ${worst?.state.name})';
}

/// The earliest projected due date over tracked, active, unsnoozed items.
///
/// Null when there is nothing to report — never a far-future sentinel, which
/// would sort and format and eventually appear on a screen as a real date in
/// the year 9999.
CivilDate? nextDue(List<AssessedItem> items, {CivilDate? today}) {
  CivilDate? earliest;
  for (final (item, assessment) in items) {
    if (!isEligible(item)) continue;
    if (_isSnoozed(item, today)) continue;

    final projected = assessment.projectedDueDate;
    if (projected == null) continue;
    if (earliest == null || projected < earliest) earliest = projected;
  }
  return earliest;
}

/// The counts, and the item a caller should name first.
DueSummary dueSummary(List<AssessedItem> items) {
  final counts = <DueState, int>{};
  AssessedItem? worst;

  for (final entry in items) {
    final (item, assessment) = entry;
    if (!isEligible(item)) continue;

    counts.update(assessment.state, (n) => n + 1, ifAbsent: () => 1);
    if (worst == null || _isWorse(entry, worst)) worst = entry;
  }

  return DueSummary(
    counts: Map.unmodifiable(counts),
    worst: worst?.$2,
    worstItem: worst?.$1,
  );
}

/// Whether [item] is snoozed as of [today].
///
/// A snoozed item keeps its state and its card — SPEC.md §3 — but it is not
/// the NEXT thing due, because the user has said "not yet" and the home screen
/// would otherwise keep offering it.
bool _isSnoozed(ServiceItem item, CivilDate? today) {
  if (today == null) return false;
  final until = CivilDate.tryParse(item.snoozedUntil ?? '');
  return until != null && until > today;
}

/// Whether [candidate] should take the worst slot from [current].
///
/// Severity, then the earlier projection, then priority. An item with no
/// projection sorts after one that has a date at the same severity: a date is
/// more actionable than none.
bool _isWorse(AssessedItem candidate, AssessedItem current) {
  final bySeverity = _rank(
    candidate.$2.state,
  ).compareTo(_rank(current.$2.state));
  if (bySeverity != 0) return bySeverity > 0;

  final a = candidate.$2.projectedDueDate;
  final b = current.$2.projectedDueDate;
  if (a != null && b != null && a != b) return a < b;
  if (a != null && b == null) return true;
  if (a == null && b != null) return false;

  return _priority(candidate.$1) > _priority(current.$1);
}

/// Severity for the worst-item choice.
///
/// `needsOdometer` sits BELOW `due` and `overdue` here, and that is the whole
/// rule `calm-due-state-and-status` states: an accusation the app can support
/// beats one it cannot. A hollow ring where a red dot belongs understates the
/// only item the user needs to act on today.
int _rank(DueState state) => switch (state) {
  DueState.unknown => 0,
  DueState.ok => 1,
  DueState.dueSoon => 2,
  DueState.needsOdometer => 3,
  DueState.due => 4,
  DueState.overdue => 5,
};

/// Safety before normal before low, per §3.
int _priority(ServiceItem item) => switch (item.priority) {
  ServicePriority.safety => 2,
  ServicePriority.normal => 1,
  ServicePriority.low => 0,
};
