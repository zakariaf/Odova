// One reader per shipped schema version, and none of them ever deleted.
//
// SPEC.md §6.3.3 and §6.4.4. A user who skipped four updates opens the app with
// a v1 file and a v5 binary, and the only thing that can write their safety
// copy is a reader that still understands v1. That is why these are numbered
// rather than being one function with an `if`.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:odova/data/db/schema_version.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('there is a reader for every shipped version', () {
    // The gap this catches is a user whose safety copy cannot be written at
    // all — which is the one case the whole mechanism exists to prevent.
    for (var version = 1; version <= kLatestSchemaVersion; version++) {
      expect(
        readerForVersion(version),
        isNotNull,
        reason: 'no reader for schema v$version',
      );
      expect(readerForVersion(version)!.version, version);
    }
  });

  test('a version this build does not know returns null, not a guess', () {
    // A database written by a NEWER version than this binary. Reading it with
    // the newest reader available would produce a copy of a misreading, and a
    // corrupt safety copy is worse than none: it looks like an escape route.
    expect(readerForVersion(kLatestSchemaVersion + 1), isNull);
    expect(readerForVersion(0), isNull);
  });

  test('the v1 reader lists all ten SPEC §3 entities', () {
    // A table missing from this list is a table missing from every safety
    // copy — silently, because the JSON still parses and still looks complete.
    expect(const SchemaReaderV1().tables, hasLength(10));
    expect(
      const SchemaReaderV1().tables,
      containsAll(const [
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
      ]),
    );
  });

  test('it reads every row of every table it lists', () {
    final database = sqlite3.openInMemory();
    addTearDown(database.dispose);

    database
      ..execute('CREATE TABLE settings (id TEXT) STRICT;')
      ..execute("INSERT INTO settings VALUES ('settings');");
    for (final table in const SchemaReaderV1().tables.skip(1)) {
      database
        ..execute('CREATE TABLE $table (id TEXT, name TEXT) STRICT;')
        ..execute("INSERT INTO $table VALUES ('a', 'one'), ('b', 'two');");
    }

    final content = const SchemaReaderV1().read(database);
    expect(content['schema_version'], 1);

    final tables = content['tables']! as Map<String, Object?>;
    expect(tables.keys, hasLength(10));
    expect(tables['vehicles'], hasLength(2));
    expect((tables['vehicles']! as List).first, {'id': 'a', 'name': 'one'});
  });
}
