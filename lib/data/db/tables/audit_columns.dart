// The four columns every entity carries, defined once.
//
// SPEC.md §3 Identity, timestamps, deletion. Two exemptions, both deliberate:
// `service_lines` is a child row that lives and dies with its parent and needs
// only an `id`, and `settings` is a singleton whose id is the literal string
// `settings`.
import 'package:drift/drift.dart';

/// `id`, `created_at`, `updated_at`, `deleted_at`.
///
/// Times are UTC epoch MILLISECONDS in an integer column, never a `DateTime`
/// and never a string. Drift's `DateTime` column type is either an integer of
/// seconds or an ISO string depending on a build option, and both lose
/// something this app needs: seconds is not enough resolution to order two
/// saves in the same second, and a string cannot be compared with `<` across
/// a zone change.
///
/// The bookkeeping times are instants. Event dates — when a service HAPPENED —
/// are a different thing entirely and use `civilDate()`, because "3 September"
/// is not an instant and turning it into one puts it on the wrong day for
/// somebody in a different zone.
mixin AuditColumns on Table {
  /// `<prefix>_<ULID>`; see `RecordId`.
  TextColumn get id => text()();

  /// When the row was first written. UTC epoch milliseconds.
  IntColumn get createdAtUtcMs => integer().named('created_at_utc_ms')();

  /// When it was last changed. UTC epoch milliseconds.
  ///
  /// Never less than [createdAtUtcMs] — but repaired on READ rather than
  /// blocked on write. See `repairAuditTimes`.
  IntColumn get updatedAtUtcMs => integer().named('updated_at_utc_ms')();

  /// When it was soft-deleted, or null.
  ///
  /// Soft delete is what makes Undo possible for the length of a snackbar.
  /// After that the row is purged, so a settled database has this null on
  /// every row that exists.
  IntColumn get deletedAtUtcMs =>
      integer().nullable().named('deleted_at_utc_ms')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  bool get isStrict => true;
}
