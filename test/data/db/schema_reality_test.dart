// The schema is what SQLite has, not what the Dart reads like.
//
// Two of drift's APIs look like schema constraints and are not, and both cost
// this epic a test cycle:
//
//   `.withLength(min: 3, max: 3)` is a DART-side validator on the generated
//   companion. It emits nothing into `CREATE TABLE`, so a row written by an
//   import, a migration or raw SQL walks straight past it.
//
//   `.references(Table, #column)` compiled, generated, analysed clean — and
//   emitted no `REFERENCES` clause at all. A service item pointing at a
//   vehicle that does not exist was accepted, and the cascade that Undo
//   depends on did not exist.
//
// Neither is visible in a diff. Both are visible in `sqlite_schema`, which is
// what these read.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';

import '../../support/source_tree.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Map<String, String>> schemas() async {
    final rows = await db
        .customSelect(
          "SELECT name, sql FROM sqlite_schema WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%';",
        )
        .get();
    return {
      for (final row in rows) row.read<String>('name'): row.read<String>('sql'),
    };
  }

  test('withLength appears in no table definition', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/data/db/tables')) {
      if (sourceWithoutLineComments(file).contains('withLength(')) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'withLength is a Dart-side validator and emits no SQL. Use '
          "customConstraint('CHECK (length(col) = n)').",
    );
  });

  test('every column that names a currency is length-checked in SQL', () async {
    // Derived from the schema rather than listed, so a currency column added
    // to a table three tasks from now is covered without editing this test.
    final missing = <String>[];
    for (final MapEntry(key: table, value: sql) in (await schemas()).entries) {
      final columns = await db.customSelect('PRAGMA table_info($table);').get();
      for (final column in columns) {
        final name = column.read<String>('name');
        if (!name.contains('currency')) continue;
        if (name.endsWith('_display')) continue; // an enum, checked separately
        if (!sql.contains('length($name) = 3')) missing.add('$table.$name');
      }
    }
    expect(missing, isEmpty);
  });

  test('every *_id column that names another table has a REFERENCES', () async {
    // `.references()` generating nothing is silent. This asks SQLite what
    // foreign keys it actually has, per table, and compares against the
    // columns whose name says they point somewhere.
    const knownNotForeign = {
      // The row's own id, and a settings pointer that must survive the
      // vehicle being erased — SPEC.md §3 keeps history when a vehicle goes.
      'id',
      'active_vehicle_id',
    };

    final missing = <String>[];
    for (final table in (await schemas()).keys) {
      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list($table);')
          .get();
      final declared = foreignKeys.map((r) => r.read<String>('from')).toSet();

      final columns = await db.customSelect('PRAGMA table_info($table);').get();
      for (final column in columns) {
        final name = column.read<String>('name');
        if (!name.endsWith('_id') || knownNotForeign.contains(name)) continue;
        if (!declared.contains(name)) missing.add('$table.$name');
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          "drift's .references() can compile and emit nothing. Write the "
          'foreign key as a customConstraint and let this test read it back.',
    );
  });
}
