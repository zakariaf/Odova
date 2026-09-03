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

  /// The file could not be written.
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

  try {
    final content = reader.read(database);
    final file = File(
      '${directory.path}/${migrationSafetyCopyName(fromVersion)}',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(content),
      flush: true,
    );
    return (file, null);
  } on FileSystemException {
    return (null, SafetyCopyFailure.writeFailed);
  }
}
