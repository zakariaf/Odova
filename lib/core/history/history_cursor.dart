// Where a page of history stopped.
//
// SPEC.md §11 *Pagination*: "Keyset, never offset."
//
//     sort key = (occurred_on DESC, created_at DESC, id DESC)
//
// The reason is in the spec and it is not performance: "Offset pagination
// would renumber the list the moment a backdated 2019 entry is saved." A user
// scrolling through eight years while a restore writes rows underneath them is
// the ordinary case for this screen, not an edge one.
//
// The third key is free. §3 makes every id a ULID, so `id DESC` is a stable
// deterministic tiebreak — "two fills on the same day at the same station keep
// a stable order across rebuilds", which is what stops a list flickering
// between two orderings.
//
// Pure Dart, no Flutter import.
import 'package:meta/meta.dart';

/// The position a page stopped at, as the three sort keys.
@immutable
class HistoryCursor {
  /// Creates a cursor.
  const HistoryCursor({
    required this.occurredOn,
    required this.createdAtUtcMs,
    required this.id,
  });

  /// The day, as `YYYY-MM-DD`. The first and coarsest key.
  final String occurredOn;

  /// When the row was written. Separates two entries on one day.
  final int createdAtUtcMs;

  /// The row's id. A ULID, so it breaks the remaining tie deterministically.
  final String id;

  /// Whether this cursor sorts strictly BEFORE [other] in the timeline.
  ///
  /// "Before" means further down the screen: the list descends on all three
  /// keys, so a page resumes with everything strictly less than where it
  /// stopped. Written once rather than as SQL in three places, because getting
  /// the tuple comparison wrong by a single `=` either duplicates the boundary
  /// row or skips it, and neither is visible in a page of sixty.
  bool sortsBelow(HistoryCursor other) {
    final byDate = occurredOn.compareTo(other.occurredOn);
    if (byDate != 0) return byDate < 0;
    if (createdAtUtcMs != other.createdAtUtcMs) {
      return createdAtUtcMs < other.createdAtUtcMs;
    }
    return id.compareTo(other.id) < 0;
  }

  @override
  String toString() => 'HistoryCursor($occurredOn, $createdAtUtcMs, $id)';
}
