// Opening the database, and the four settings that make it safe.
//
// SPEC.md §3 Durability and §14 Storage and scale. Three of these four pragmas
// are per-CONNECTION and do not persist in the file, so they belong in `setup`,
// which SQLite runs on every open — not in `onCreate`, which runs once in the
// life of the database.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:odova/core/history/search_normalise.dart';
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
  registerSearchFold(database);
}

/// Exposes SPEC.md §11's search normalisation to SQL.
///
/// §11 refuses a stored index — "a stale index surviving a Replace import
/// would be a nasty bug" — so the fold has to happen INSIDE the query, over
/// each text column, on every search.
///
/// Spelled out as nested `REPLACE`s it does not parse: seventy-two
/// substitutions is past what SQLite's parser will nest, and it answers
/// "parser stack overflow" rather than running slowly. A registered function
/// is the better answer regardless, because there is then exactly ONE
/// normaliser — `normaliseForSearch` — and both sides of the comparison call
/// it. §11 requires "normalisation before comparison, on both sides", and two
/// implementations cannot promise that: they drift on the first letter added
/// to one of them.
///
/// Called from [applyPragmas], so it reaches the app's connection and every
/// executor a test opens through the same hook.
void registerSearchFold(Database database) {
  database.createFunction(
    functionName: 'odova_search_fold',
    argumentCount: const AllowedArgumentCount(1),
    // The same input always folds to the same output, so SQLite may cache it
    // and use it in an index expression later.
    deterministic: true,
    directOnly: false,
    function: (args) {
      final value = args.first;
      return value is String ? normaliseForSearch(value) : '';
    },
  );
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
