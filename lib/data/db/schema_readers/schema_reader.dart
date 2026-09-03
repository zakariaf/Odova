// One reader per shipped schema version, resolvable by number.
//
// SPEC.md §6.3.3 and §6.4.4. The safety copy taken before a migration must be
// written by the reader for the version ALREADY ON DISK — not by the code that
// is about to run. A copy taken through the code that is about to migrate is a
// copy taken through the crash: if the new mapper misreads a column, the
// "safety" copy carries the same misreading and the escape route is as broken
// as the thing it was escaping.
//
// **Readers are never deleted.** A user who skipped four updates opens the app
// with a v1 file and a v5 binary, and the only way to write their safety copy
// is a reader that still understands v1. That is why they are numbered rather
// than being one function with an `if`.
import 'package:sqlite3/common.dart';

/// Reads a database of one specific schema version into plain JSON.
///
/// Plain JSON on purpose: the safety copy has to be readable by a human and by
/// a future importer that has never heard of this version's Dart classes.
abstract class SchemaReader {
  /// Creates a reader.
  const SchemaReader();

  /// Which schema version this reader understands.
  int get version;

  /// Every table this version has, in dependency order.
  List<String> get tables;

  /// Reads the whole database.
  ///
  /// `SELECT *` per table rather than a typed query: the reader must not
  /// depend on the generated classes, which move with the CURRENT schema and
  /// would stop compiling the moment a column is dropped in a later version.
  ///
  /// Takes a raw `sqlite3` database rather than a drift `QueryExecutor`,
  /// because this runs BEFORE drift has opened anything. Going through drift
  /// would mean opening the database with the code that is about to migrate
  /// it, which is the one thing this reader exists to avoid.
  Map<String, Object?> read(CommonDatabase database) {
    final content = <String, Object?>{};
    for (final table in tables) {
      final result = database.select('SELECT * FROM $table;');
      content[table] = [for (final row in result) Map<String, Object?>.of(row)];
    }
    return {
      'schema_version': version,
      'tables': content,
    };
  }
}

/// The reader for schema v1.
class SchemaReaderV1 extends SchemaReader {
  /// Creates the v1 reader.
  const SchemaReaderV1();

  @override
  int get version => 1;

  @override
  List<String> get tables => const [
    'settings',
    'vehicles',
    'service_items',
    'service_records',
    'service_lines',
    'trips',
    'fill_ups',
    'expenses',
    'odometer_readings',
    'odometer_corrections',
  ];
}

/// Every reader this build still carries, by version.
///
/// Adding a version adds an entry and never removes one. A gap here is a user
/// whose safety copy cannot be written at all, which is the one case this
/// whole file exists to prevent.
const schemaReaders = <int, SchemaReader>{1: SchemaReaderV1()};

/// The reader for [version], or null if this build has none.
///
/// Null is a real answer and the caller must handle it: a database written by a
/// NEWER version than this build knows about is not something to guess at.
SchemaReader? readerForVersion(int version) => schemaReaders[version];
