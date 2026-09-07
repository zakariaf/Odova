// What was odd about a file that is still going to be imported — §6 §5.2.
//
// The dividing line against `ImportFailure` is simple and it is the rule §5.3
// calls never-silently-drop: a warning means the data is COMING IN. Records
// whose vehicle cannot be found arrive under a placeholder vehicle; records
// with a date in 1974 arrive with their date; a reminder whose `rule` this
// build no longer has arrives without it. Nothing here is a reason to lose a
// row, and every one of them is a reason to tell the user something.
//
// Each carries a count, and the ones with a detail view carry the list. The
// count is what the preview shows; the list is what the "Tap to see which ones"
// screen shows, and it exists because a user who knows exactly what was lost
// can retype three rows.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// One skipped record, described the way a person would describe it.
///
/// Type, date and a plain reason — "Fill-up, 14 August 2026 — the amount of
/// fuel was missing". Never an identifier: a ULID tells the user nothing and
/// makes the list look like a crash report.
@immutable
class SkippedEntry with ValueEquality {
  /// Creates a description of one skipped record.
  const SkippedEntry({
    required this.array,
    required this.reason,
    this.occurredOn,
  });

  /// Which array it came from, for the type word in the message.
  final String array;

  /// Why it could not be read, as a message KEY. Never a sentence: the list is
  /// rendered in the user's language, and three of the six are right-to-left.
  final String reason;

  /// Its date, if the record had a readable one. Null when the date was the
  /// thing that was wrong.
  final String? occurredOn;

  @override
  List<Object?> get props => [array, reason, occurredOn];
}

/// Something worth telling the user about a file that will still be imported.
@immutable
sealed class ImportWarning with ValueEquality {
  /// Creates a warning.
  const ImportWarning();

  /// A stable identifier, unique within this family.
  String get code;

  /// How many records it concerns. One, for the whole-file warnings.
  int get count;
}

/// Rung 8 — `content_hash` does not match the file's own bytes.
///
/// A WARNING and never a refusal. There is no secret and no signature, so
/// anyone who edits the file can recompute it; a mismatch means "not
/// byte-for-byte what Odova wrote", which is also true of a legitimate
/// hand-edit somebody made on purpose.
final class ContentHashMismatch extends ImportWarning {
  /// Creates the warning.
  const ContentHashMismatch();

  @override
  String get code => 'content_hash_mismatch';

  @override
  int get count => 1;

  @override
  List<Object?> get props => const [];
}

/// Rung 8 — `record_counts.total` disagrees with what was found.
///
/// Carries BOTH numbers, because "it lists 1,204 records and 1,180 were found"
/// is a fact the user can act on and "the counts do not match" is not.
final class RecordCountMismatch extends ImportWarning {
  /// Creates the warning.
  const RecordCountMismatch({required this.declared, required this.found});

  /// What the envelope claimed.
  final int declared;

  /// What the reader counted.
  final int found;

  @override
  String get code => 'record_count_mismatch';

  @override
  int get count => 1;

  @override
  List<Object?> get props => [declared, found];
}

/// Rung 7 — a top-level array was absent and is being treated as empty.
final class MissingArray extends ImportWarning {
  /// Creates the warning.
  const MissingArray(this.array);

  /// Which one.
  final String array;

  @override
  String get code => 'missing_array';

  @override
  int get count => 1;

  @override
  List<Object?> get props => [array];
}

/// Rung 9 — records that could not be read at all.
final class SkippedRecords extends ImportWarning {
  /// Creates the warning.
  const SkippedRecords(this.entries);

  /// One entry per skipped record, for the detail view.
  final List<SkippedEntry> entries;

  @override
  String get code => 'skipped_records';

  @override
  int get count => entries.length;

  @override
  List<Object?> get props => [entries.length];
}

/// Rung 9 — an enum value this build does not know, coerced to `other`.
///
/// The record SURVIVES. An unknown category must not cost a user their €612
/// insurance row, and a category is a label on an amount rather than the amount
/// itself.
final class CoercedEnums extends ImportWarning {
  /// Creates the warning.
  const CoercedEnums(this.count);

  @override
  final int count;

  @override
  String get code => 'coerced_enums';

  @override
  List<Object?> get props => [count];
}

/// Rung 10 — dates before 1990, or more than two years after `exported_at`.
///
/// Imported, then flagged. A phone whose clock was wrong is still the user's
/// history, and they are the only one who can say which date was meant.
final class OutOfRangeDates extends ImportWarning {
  /// Creates the warning.
  const OutOfRangeDates(this.count);

  @override
  final int count;

  @override
  String get code => 'out_of_range_dates';

  @override
  List<Object?> get props => [count];
}

/// Rung 11 — records whose `vehicle_id` matches no vehicle in the file.
///
/// §5.3: they are attached to a vehicle named "Recovered records" and never
/// deleted. A placeholder the user can see beats a number in a report they will
/// not read.
final class OrphanRecords extends ImportWarning {
  /// Creates the warning.
  const OrphanRecords(this.count);

  @override
  final int count;

  @override
  String get code => 'orphan_records';

  @override
  List<Object?> get props => [count];
}

/// Rung 11 — a `trip_id` or `service_item_id` that resolves to nothing.
///
/// Nulled, not dropped. The link is a convenience; the amount and the date are
/// the record.
final class UnresolvedLinks extends ImportWarning {
  /// Creates the warning.
  const UnresolvedLinks(this.count);

  @override
  final int count;

  @override
  String get code => 'unresolved_links';

  @override
  List<Object?> get props => [count];
}

/// Rung 11 — a correction whose `from_reading_id` resolves to nothing.
///
/// SKIPPED, and this is the one link failure that must not be repaired by
/// guessing. A correction applied to an arbitrary reading rewrites a mileage
/// history that looked fine, and the user would have no way of knowing which
/// number the app invented.
final class UnmatchedCorrections extends ImportWarning {
  /// Creates the warning.
  const UnmatchedCorrections(this.count);

  @override
  final int count;

  @override
  String get code => 'unmatched_corrections';

  @override
  List<Object?> get props => [count];
}

/// Rung 12 — the same id appears more than once in the file.
///
/// The first occurrence wins. First and not last, because a file whose tail was
/// appended twice is the common shape, and the first copy is the one the rest
/// of the document's links were written against.
final class DuplicateIds extends ImportWarning {
  /// Creates the warning.
  const DuplicateIds(this.count);

  @override
  final int count;

  @override
  String get code => 'duplicate_ids';

  @override
  List<Object?> get props => [count];
}

/// Migration — a `rule` value the current build no longer has.
final class DroppedRules extends ImportWarning {
  /// Creates the warning.
  const DroppedRules(this.count);

  @override
  final int count;

  @override
  String get code => 'dropped_rules';

  @override
  List<Object?> get props => [count];
}

/// §5.4 — a string longer than 1 MB, truncated.
final class TruncatedStrings extends ImportWarning {
  /// Creates the warning.
  const TruncatedStrings(this.count);

  @override
  final int count;

  @override
  String get code => 'truncated_strings';

  @override
  List<Object?> get props => [count];
}
