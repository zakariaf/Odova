// The schema-wide contract, asserted by REFLECTION.
//
// SPEC.md §3 Canonical units; Identity, timestamps, deletion. These read
// `sqlite_schema` and `PRAGMA table_info` rather than naming tables, so they
// keep working as tasks 5.5 and 5.6 add them — a contract asserted table by
// table is a contract somebody forgets on the tenth table.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
  });

  tearDown(() => db.close());

  /// Every table in the schema, by name.
  Future<List<String>> tableNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_schema WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%';",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  test('no column in any table has type REAL', () async {
    // The float-money guard, and it is schema-wide on purpose: a REAL added to
    // the tenth table three epics from now is caught by this test without
    // anybody editing it. Money in a float is how 0.1 + 0.2 becomes a cent
    // that does not reconcile, over eight years of receipts.
    final offenders = <String>[];
    for (final table in await tableNames()) {
      final columns = await db.customSelect('PRAGMA table_info($table);').get();
      for (final column in columns) {
        if (column.read<String>('type').toUpperCase() == 'REAL') {
          offenders.add('$table.${column.read<String>('name')}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('every table is STRICT', () async {
    // Without STRICT, SQLite stores whatever you give it: `'abc'` in an
    // INTEGER column is accepted and read back as a string. A wrong type
    // becomes impossible rather than unlikely.
    final rows = await db
        .customSelect(
          "SELECT name, sql FROM sqlite_schema WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%';",
        )
        .get();

    final offenders = [
      for (final row in rows)
        if (!row
            .read<String>('sql')
            .trimRight()
            .toUpperCase()
            .endsWith('STRICT'))
          row.read<String>('name'),
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'add `bool get isStrict => true;` to these tables',
    );
  });

  test('the schema-wide tests actually saw tables', () async {
    // The guard the two above need. A reflection test over an empty schema
    // passes while asserting nothing, which is the shape of gate that reports
    // green for three epics and then turns out never to have run.
    expect(
      await tableNames(),
      isNotEmpty,
      reason: 'no tables — the reflection tests above asserted nothing',
    );
  });

  group('the audit columns', () {
    test(
      'every table carries id, created_at, updated_at and deleted_at',
      () async {
        // Except the two SPEC.md §3 exempts: `service_lines` is a child row
        // that lives and dies with its parent, and `settings` is a singleton
        // whose id is the literal string `settings`.
        const childRows = {'service_lines'};

        // And one table that is not an ENTITY at all.
        //
        // `scheduled_notifications` is device bookkeeping — what the app
        // believes the OS is holding (SPEC.md §6.1). It has no ULID, no
        // created-at and no soft delete because it is not history: it does not
        // go in the backup (§6 §7), it does not survive an import, and §6.2
        // rebuilds it from scratch after one. Its identity is the notification
        // KEY, which is `<vehicle>:<reminder>:<stage>` and is meaningful, not
        // generated.
        //
        // Exempted here rather than given the audit columns, because giving it
        // an `id` and a `deleted_at` would make it look like an entity — and
        // the next person to write an export projection would include it,
        // putting one phone's OS notification ids into a file that gets
        // restored onto another.
        const notEntities = {'scheduled_notifications'};
        const required = {
          'id',
          'created_at_utc_ms',
          'updated_at_utc_ms',
          'deleted_at_utc_ms',
        };

        final missing = <String>[];
        for (final table in await tableNames()) {
          final columns = await db
              .customSelect('PRAGMA table_info($table);')
              .get();
          final names = columns.map((c) => c.read<String>('name')).toSet();
          if (notEntities.contains(table)) continue;
          final want = childRows.contains(table) ? {'id'} : required;
          for (final column in want) {
            if (!names.contains(column)) missing.add('$table.$column');
          }
        }
        expect(missing, isEmpty);
      },
    );
  });
}
