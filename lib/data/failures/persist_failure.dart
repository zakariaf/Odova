// Why a write did not happen.
//
// `error-handling-typed-results` rules 1 and 3: recoverable failures are
// VALUES, and each one carries a stable code plus typed params — never a
// user-facing string, because a baked-in message cannot be translated,
// mirrored or digit-shaped, and this app ships in six languages of which three
// are right-to-left.
//
// Sealed, so a `switch` over it needs no `default:` and adding a variant is a
// compile error at every call site rather than a case that falls through.
import 'package:meta/meta.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/value_equality.dart';

/// Why a write against the local database did not happen.
@immutable
sealed class PersistFailure extends Failure with ValueEquality {
  const PersistFailure();
}

/// The database refused the write for a reason that is not a business rule.
///
/// Disk full, file locked, a corrupt page. The [detail] is the driver's own
/// message, kept for the diagnostics log and never shown as-is.
final class WriteFailed extends PersistFailure {
  /// Creates the failure.
  const WriteFailed(this.detail);

  /// What the driver said. Diagnostics only.
  final String detail;

  @override
  String get code => 'write_failed';

  @override
  List<Object?> get props => [detail];
}

/// A schema constraint refused the row.
///
/// Every one of these corresponds to a `CHECK` or a foreign key that
/// `lib/data/db/tables/` states, so [constraint] names the invariant rather
/// than quoting SQLite.
final class ConstraintViolated extends PersistFailure {
  /// Creates the failure.
  const ConstraintViolated(this.constraint);

  /// Which invariant, in this app's words.
  final String constraint;

  @override
  String get code => 'constraint_violated';

  @override
  List<Object?> get props => [constraint];
}

/// The row is not there.
final class NotFound extends PersistFailure {
  /// Creates the failure.
  const NotFound(this.id);

  /// What was asked for.
  final String id;

  @override
  String get code => 'not_found';

  @override
  List<Object?> get props => [id];
}

/// The reading would make the history non-monotonic.
///
/// Carries the neighbour it conflicts with and that neighbour's date, because
/// SPEC.md §3's three resolutions — fix the typo, record a correction, accept
/// it as backdated — all need both, and a bare refusal gives the user nothing
/// to act on.
final class OdometerWouldGoBackwards extends PersistFailure {
  /// Creates the failure.
  const OdometerWouldGoBackwards({
    required this.previousCumulative,
    required this.previousOccurredOn,
    required this.attemptedCumulative,
  });

  /// What the conflicting neighbour reads, cumulatively, in metres.
  final Distance previousCumulative;

  /// And when.
  final String previousOccurredOn;

  /// What was offered, in metres.
  final Distance attemptedCumulative;

  @override
  String get code => 'odometer_would_go_backwards';

  @override
  List<Object?> get props => [
    previousCumulative,
    previousOccurredOn,
    attemptedCumulative,
  ];
}

/// A reading emitted by a fill-up, a service or a trip cannot be edited on its
/// own.
///
/// SPEC.md §3: a derived reading follows its parent. Editing it directly would
/// leave the reading and the record that produced it disagreeing, with nothing
/// to say which is right.
final class DerivedReadingNotEditable extends PersistFailure {
  /// Creates the failure.
  const DerivedReadingNotEditable({
    required this.readingId,
    required this.source,
  });

  /// The reading.
  final String readingId;

  /// What produced it — the thing the user should edit instead.
  final String source;

  @override
  String get code => 'derived_reading_not_editable';

  @override
  List<Object?> get props => [readingId, source];
}

/// The store is read-only because a migration failed.
///
/// SPEC.md §6.3.3 and §14: a failed migration comes up READ-ONLY with an honest
/// banner rather than a crash loop. Reads still work — seeing the history and
/// being able to export it is the whole point of not crashing — and every write
/// returns this so a second attempt cannot make the file worse.
final class StoreReadOnly extends PersistFailure {
  /// Creates the failure.
  const StoreReadOnly({required this.atVersion, required this.expectedVersion});

  /// The version the file is still on.
  final int atVersion;

  /// The version this build wanted.
  final int expectedVersion;

  @override
  String get code => 'store_read_only';

  @override
  List<Object?> get props => [atVersion, expectedVersion];
}

/// The row points at something that is not there.
///
/// The import case: a backup file whose fill-up names a vehicle the file does
/// not contain.
final class OrphanReference extends PersistFailure {
  /// Creates the failure.
  const OrphanReference({required this.field, required this.target});

  /// Which column.
  final String field;

  /// What it pointed at.
  final String target;

  @override
  String get code => 'orphan_reference';

  @override
  List<Object?> get props => [field, target];
}
