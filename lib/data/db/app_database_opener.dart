// Opening the database in a way a failed migration cannot survive intact.
//
// SPEC.md §6.3.3, §6.4.4, §14 (*Migration fails on launch*), §17's data-safety
// gate, and `CLAUDE.md` rule 3. The order below is the whole file, and every
// step in it is there because the obvious version loses data:
//
//   1. Read the version already on disk. Not the one the app wants.
//   2. Write the JSON safety copy through the NUMBERED reader for THAT version.
//   3. Checkpoint the WAL and snapshot the three files, with nothing open.
//   4. Open, forcing the migration.
//   5. On a throw: CLOSE the dead connection first, then restore, then rethrow.
//
// Step 5's order is the one people get wrong. Restoring files under an open
// connection leaves SQLite holding page cache for a file that no longer
// exists, and the next write corrupts the restored copy — turning a recoverable
// failure into the unrecoverable one this whole file exists to prevent.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:odova/data/backup/migration_safety_copy.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';
import 'package:sqlite3/sqlite3.dart';

/// The three files a SQLite database in WAL mode occupies.
///
/// The sidecars are not optional. A raw copy of a live WAL database is TORN —
/// the `.sqlite` holds committed pages, the `-wal` holds the ones committed
/// since the last checkpoint, and restoring one without the other produces a
/// file SQLite will happily open and read wrong.
List<File> databaseFiles(File main) => [
  main,
  File('${main.path}-wal'),
  File('${main.path}-shm'),
];

/// What happened while opening.
sealed class OpenOutcome {
  const OpenOutcome();
}

/// The database opened, migrating if it needed to.
final class OpenedCleanly extends OpenOutcome {
  /// Creates the outcome.
  const OpenedCleanly(this.database, {this.safetyCopy});

  /// The open database.
  final AppDatabase database;

  /// The copy taken before the migration, when one ran. Kept on SUCCESS too —
  /// SPEC.md §6.4.4 overwrites it with the next migration rather than deleting
  /// it, because the update that broke something is often noticed a day later.
  final File? safetyCopy;
}

/// The migration was not attempted, because the safety copy could not be
/// written.
///
/// SPEC.md §6.4.4: "Any operation that destroys data writes its file first —
/// import, Delete all data, every schema migration. **No exceptions.**" So a
/// copy that could not be written is a migration that does not run.
///
/// The two cases are different and both are real. `unknownSchemaVersion` means
/// a database written by a NEWER build — a sideload or a rollback — and the
/// only honest answer is to refuse rather than hand it to a migrator that does
/// not understand it. `writeFailed` or `readFailed` means the disk is full or
/// the file is already damaged, and migrating without an escape route is how a
/// semantically-wrong-but-successful migration becomes unrecoverable.
final class MigrationRefused extends OpenOutcome {
  /// Creates the outcome.
  const MigrationRefused({
    required this.atVersion,
    required this.expectedVersion,
    required this.reason,
  });

  /// The version the file is on.
  final int atVersion;

  /// The version this build wanted.
  final int expectedVersion;

  /// Why the copy could not be written.
  final SafetyCopyFailure reason;
}

/// The migration threw, and the snapshot was restored.
///
/// The file is back on [atVersion] byte for byte. The caller brings the app up
/// READ-ONLY rather than retrying: a second attempt runs the same code against
/// the same data and can only make it worse.
final class MigrationRolledBack extends OpenOutcome {
  /// Creates the outcome.
  const MigrationRolledBack({
    required this.atVersion,
    required this.expectedVersion,
    required this.error,
    this.safetyCopy,
  });

  /// The version the file is still on.
  final int atVersion;

  /// The version this build wanted.
  final int expectedVersion;

  /// What went wrong, for the diagnostics log.
  final Object error;

  /// Where the JSON copy went, when one was written.
  final File? safetyCopy;
}

/// Opens [dbFile], migrating it and restoring it if that fails.
///
/// [safetyDirectory] is app-private storage. [openDatabase] exists so a test
/// can inject a database whose migration throws — the alternative is a real
/// schema bump in a test fixture, which would need its own snapshot and would
/// make this test the thing that breaks when the ladder grows.
Future<OpenOutcome> openMigratedDatabase(
  File dbFile, {
  required Directory safetyDirectory,
  AppDatabase Function(QueryExecutor)? openDatabase,
}) async {
  final build = openDatabase ?? AppDatabase.forTesting;

  // Nothing to migrate, nothing to protect.
  if (!dbFile.existsSync()) {
    return OpenedCleanly(build(NativeDatabase(dbFile, setup: applyPragmas)));
  }

  final fromVersion = _readUserVersion(dbFile);
  final expected = build(NativeDatabase.memory()).schemaVersion;

  if (fromVersion == expected) {
    return OpenedCleanly(build(NativeDatabase(dbFile, setup: applyPragmas)));
  }

  // 2. The JSON copy, through the reader for the version ON DISK.
  //
  // Its failure is HONOURED, not discarded. The first version dropped it on
  // the floor with `final (file, _) = …`, so the app migrated in exactly the
  // two cases the failure exists to prevent: a database from a newer build
  // that this binary has no reader for, and a disk too full to write an escape
  // route. SPEC.md §6.4.4 says "no exceptions" and means it.
  final (safetyCopy, copyFailure) = await _writeSafetyCopy(
    dbFile,
    fromVersion,
    safetyDirectory,
  );
  if (copyFailure != null) {
    return MigrationRefused(
      atVersion: fromVersion,
      expectedVersion: expected,
      reason: copyFailure,
    );
  }

  // 3. The byte snapshot, with nothing open.
  final snapshot = await _snapshot(dbFile);

  // 4. Open and migrate.
  final database = build(NativeDatabase(dbFile, setup: applyPragmas));
  var restored = false;
  try {
    // `customStatement` forces the connection to open, which is what runs the
    // migration. Without it the failure would surface at the first query,
    // long after this function returned an "open" database.
    await database.customStatement('SELECT 1;');
    restored = true; // nothing to restore; the snapshot may go
    return OpenedCleanly(database, safetyCopy: safetyCopy);
  } on Object catch (error) {
    // 5. CLOSE FIRST. Restoring under an open connection leaves SQLite holding
    // page cache for a file that no longer exists, and the next write corrupts
    // the restored copy.
    // Closing can itself throw on a dead connection, and if it does the
    // restore must still run — otherwise the half-migrated file stays and the
    // snapshot is deleted on the way out.
    try {
      await database.close();
    } on Object {
      // Nothing to do about it; the restore below is what matters.
    }

    await _restore(dbFile, snapshot);
    restored = true;

    return MigrationRolledBack(
      atVersion: fromVersion,
      expectedVersion: expected,
      error: error,
      safetyCopy: safetyCopy,
    );
  } finally {
    // Only once the database is known good. The first version deleted the
    // snapshot on EVERY path, so a restore that threw left the user with
    // neither the original nor the copy.
    if (restored) {
      for (final file in snapshot.values) {
        if (file.existsSync()) await file.delete();
      }
    }
  }
}

/// The raw file operations run through `package:sqlite3` rather than drift.
///
/// They happen BEFORE drift opens anything — reading the version already on
/// disk, checkpointing the WAL, taking the copy — and going through drift would
/// mean opening the database with the code that is about to migrate it, which
/// is the one thing the numbered readers exist to avoid.
int _readUserVersion(File dbFile) {
  final database = sqlite3.open(dbFile.path);
  try {
    return database.select('PRAGMA user_version;').single.values.first! as int;
  } finally {
    database.dispose();
  }
}

Future<(File?, SafetyCopyFailure?)> _writeSafetyCopy(
  File dbFile,
  int fromVersion,
  Directory directory,
) async {
  final database = sqlite3.open(dbFile.path);
  try {
    return await writeMigrationSafetyCopy(
      database: database,
      fromVersion: fromVersion,
      directory: directory,
    );
  } finally {
    database.dispose();
  }
}

/// Copies the three files aside, after checkpointing the WAL.
///
/// `wal_checkpoint(TRUNCATE)` folds everything committed into the main file
/// and empties the `-wal`, so the copy is a consistent point in time rather
/// than three files from three moments.
Future<Map<File, File>> _snapshot(File dbFile) async {
  final database = sqlite3.open(dbFile.path);
  try {
    database.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  } finally {
    database.dispose();
  }

  final snapshot = <File, File>{};
  for (final file in databaseFiles(dbFile)) {
    if (!file.existsSync()) continue;
    snapshot[file] = await file.copy('${file.path}.premigration');
  }
  return snapshot;
}

/// Puts [snapshot] back, by RENAME.
///
/// Rename, not delete-then-copy. The first version deleted the live database
/// and then copied each snapshot file back — and on a device that is nearly
/// full, which is exactly when a migration fails, the copy can throw `ENOSPC`
/// after the delete. The user's database was then gone, the snapshot was
/// deleted by a `finally` that ran regardless, and the next launch created a
/// brand-new empty database that looked like a fresh install.
///
/// A rename inside one filesystem is atomic and needs no free space, and
/// app-private storage is one filesystem. Files the failed migration created
/// that the snapshot does not have are still deleted first, so a `-wal` from
/// the attempt cannot be read alongside a restored `.sqlite`.
Future<void> _restore(File dbFile, Map<File, File> snapshot) async {
  for (final file in databaseFiles(dbFile)) {
    if (snapshot.containsKey(file)) continue;
    if (file.existsSync()) await file.delete();
  }
  for (final MapEntry(key: original, value: copy) in snapshot.entries) {
    await copy.rename(original.path);
  }
}
