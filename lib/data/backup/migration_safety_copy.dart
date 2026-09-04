// The JSON copy written before every migration.
//
// SPEC.md §6.4.4: "Any operation that destroys data writes its file first —
// import, Delete all data, every schema migration. No exceptions." One file per
// destructive operation KIND, three at most, each overwritten only by the next
// operation of the same kind — so an import can never eat the copy a wipe left.
import 'dart:convert';
import 'dart:io';

import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:sqlite3/common.dart';

/// The name SPEC.md §6.4.4 gives the migration copy.
///
/// The VERSION and not a timestamp, deliberately: a second migration from the
/// same starting version overwrites its own copy rather than accumulating one
/// per attempt, and a user who has updated four times has one file, not four.
String migrationSafetyCopyName(int fromVersion) =>
    'odova-safety-migration-$fromVersion.json';

/// Why a safety copy could not be written.
enum SafetyCopyFailure {
  /// This build has no reader for the version on disk.
  ///
  /// A database written by a NEWER version than this binary knows. Reading it
  /// with the newest reader available would produce a copy of a misreading, so
  /// the copy is refused and the caller must not migrate.
  unknownSchemaVersion,

  /// The database could not be read.
  ///
  /// A missing table, a corrupt page, a value the encoder cannot represent.
  /// Distinct from [writeFailed] because it means the file on disk is already
  /// damaged, and the caller has more to worry about than the copy.
  readFailed,

  /// The file could not be written. Usually a full disk.
  writeFailed,
}

/// Writes the pre-migration safety copy for [database], read at [fromVersion].
///
/// Read through the NUMBERED reader for the version on disk, never through the
/// current code. A copy taken by the code that is about to migrate is a copy
/// taken through the crash: if the new mapper misreads a column, the copy
/// carries the same misreading and the escape route is as broken as the thing
/// it was escaping.
///
/// Returns the file, or a failure. It is never a throw: the caller decides
/// whether to proceed without one, and that decision is a product decision.
Future<(File?, SafetyCopyFailure?)> writeMigrationSafetyCopy({
  required CommonDatabase database,
  required int fromVersion,
  required Directory directory,
}) async {
  final reader = readerForVersion(fromVersion);
  if (reader == null) return (null, SafetyCopyFailure.unknownSchemaVersion);

  final String encoded;
  try {
    encoded = const JsonEncoder.withIndent('  ').convert(reader.read(database));
  } on Object {
    // `on Object`, not `on FileSystemException`. `SELECT *` throws
    // `SqliteException` for a missing table or a corrupt page, and
    // `JsonEncoder.convert` throws `JsonUnsupportedObjectError`, which is an
    // ERROR and not an Exception — so both escaped a function whose doc says
    // "it is never a throw", straight out through `openMigratedDatabase` into
    // the app's entry point.
    //
    // That is the crash loop SPEC.md §14 names as the worst possible outcome:
    // the user cannot open the app to export their data, and the only remedy
    // left is uninstalling, which deletes it. A database with `user_version =
    // 1` and a missing table — a process killed during first-run schema
    // creation — reaches it on every launch.
    return (null, SafetyCopyFailure.readFailed);
  }

  final file = File(
    '${directory.path}/${migrationSafetyCopyName(fromVersion)}',
  );

  try {
    // Written to a temp file and RENAMED, never straight to the canonical
    // path. `writeAsString` opens with truncate, so a second attempt at the
    // same migration destroys the first attempt's copy before it has produced
    // a replacement — and if the disk fills partway, what is left under the
    // canonical name is a truncated file that is not valid JSON and no longer
    // holds the user's history. The good copy would have been destroyed by the
    // attempt to refresh it.
    //
    // `rename` is atomic within a filesystem, and app-private storage is one
    // filesystem.
    final temporary = File('${file.path}.writing');
    await temporary.writeAsString(encoded, flush: true);
    await temporary.rename(file.path);
    return (file, null);
  } on FileSystemException {
    return (null, SafetyCopyFailure.writeFailed);
  }
}
