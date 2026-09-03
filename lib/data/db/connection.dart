// Opening the database, and the four settings that make it safe.
//
// SPEC.md §3 Durability and §14 Storage and scale. Three of these four pragmas
// are per-CONNECTION and do not persist in the file, so they belong in `setup`,
// which SQLite runs on every open — not in `onCreate`, which runs once in the
// life of the database.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The database file's name inside the application support directory.
const databaseFileName = 'odova.sqlite';

/// Applies the four pragmas to a raw connection.
///
/// One function, called from `setup`, because a second call site is a second
/// answer. The connection test asserts there is exactly one `journal_mode`
/// mention in this file for that reason.
///
/// - `journal_mode = WAL` — a reader never blocks the writer, which is what
///   lets a watched stream re-read while a save is in flight.
/// - `synchronous = FULL` — WAL's default is NORMAL, which can lose the last
///   committed transactions after a power cut. This store holds hand-entered
///   data that no server has a copy of (SPEC.md §2), so the fsync is bought.
/// - `foreign_keys = ON` — OFF by default, per connection. Without it every
///   `ON DELETE CASCADE` in the schema is decoration.
/// - `busy_timeout` — wait rather than return SQLITE_BUSY to a caller who
///   would only have retried.
void applyPragmas(Database database) {
  database
    ..execute('PRAGMA journal_mode = WAL;')
    ..execute('PRAGMA synchronous = FULL;')
    ..execute('PRAGMA foreign_keys = ON;')
    ..execute('PRAGMA busy_timeout = 5000;');
}

/// The app's database connection, opened lazily on a background isolate.
///
/// The file lives in the application SUPPORT directory, not Documents. On iOS
/// Documents is user-visible and iCloud-backed, and a half-written WAL syncing
/// to iCloud is a corruption vector for a file the user cannot regenerate.
QueryExecutor openConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  return NativeDatabase.createInBackground(
    File('${directory.path}/$databaseFileName'),
    setup: applyPragmas,
  );
});
