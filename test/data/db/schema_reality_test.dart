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

  test('every foreign key states what happens on delete', () async {
    // SQLite's default is NO ACTION, which is not a decision — it is the
    // absence of one, and it shows up as a constraint failure at delete time
    // rather than as the cascade or the detach the design intended. SPEC.md §3
    // specifies both behaviours by name: a vehicle CASCADES to its history, and
    // a deleted ServiceItem SETS NULL on its lines so the work that was
    // actually done survives.
    final offenders = <String>[];
    for (final MapEntry(key: table, value: sql) in (await schemas()).entries) {
      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list($table);')
          .get();

      for (final key in foreignKeys) {
        final column = key.read<String>('from');
        final onDelete = key.read<String>('on_delete');
        if (onDelete == 'NO ACTION') {
          offenders.add('$table.$column');
        }
      }
      // And the action is written in the schema text, so a reviewer reading
      // the table file sees it rather than having to ask SQLite.
      if (foreignKeys.isNotEmpty && !sql.contains('ON DELETE')) {
        offenders.add('$table (no ON DELETE in the CREATE TABLE)');
      }
    }

    expect(offenders, isEmpty);
  });

  test('no column stores a derived value', () async {
    // SPEC.md §2: derived values are never persisted. Consumption, cost per
    // km, monthly totals, next-due dates, due status and the CUMULATIVE
    // odometer are pure functions computed at read time. A stored one survives
    // an import and is then wrong forever — the corrections applied twice, or
    // not at all, and nothing to say which.
    const derived = [
      'cumulative',
      'consumption',
      'cost_per_km',
      'next_due',
      'due_status',
      'monthly_total',
      'projected',
    ];
    // A stored PREFERENCE about how a derived value is displayed is not a
    // stored derived value. `consumption_unit` says "show me mpg"; it does not
    // hold a consumption figure.
    const settingsNotValues = {'consumption_unit'};

    final offenders = <String>[];
    for (final table in (await schemas()).keys) {
      final columns = await db.customSelect('PRAGMA table_info($table);').get();
      for (final column in columns) {
        final name = column.read<String>('name');
        if (settingsNotValues.contains(name)) continue;
        for (final word in derived) {
          if (name.contains(word)) offenders.add('$table.$name');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('every *_id column that names another table has a REFERENCES', () async {
    // `.references()` generating nothing is silent. This asks SQLite what
    // foreign keys it actually has, per table, and compares against the
    // columns whose name says they point somewhere.
    // Every exception is named, with the reason, because "it isn't a foreign
    // key" is exactly what somebody says about a column that should have been
    // one.
    const knownNotForeign = {
      // The row's own id.
      'id',
      // A settings pointer, not a child row: it must survive the vehicle
      // being erased rather than take the settings row with it.
      'active_vehicle_id',
      // POLYMORPHIC. `odometer_readings.source_id` points into one of five
      // tables depending on `source`, and SQLite has no polymorphic
      // reference. The fan-out in task 5.9 keeps it consistent — a derived
      // reading is deleted with its parent by that code, not by a constraint —
      // which is a real weakening and is why it is written down here.
      'source_id',
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
