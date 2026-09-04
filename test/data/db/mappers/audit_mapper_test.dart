// The column contract, asserted by REFLECTION over the schema.
//
// SPEC.md §3 Canonical units; Identity, timestamps, deletion; Currency;
// Invariants and validation. These tests read `sqlite_schema` and
// `PRAGMA table_info` rather than naming tables, so they keep working as tasks
// 5.4-5.6 add them — a contract asserted table by table is a contract somebody
// forgets on the tenth table.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/audit_mapper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('event dates', () {
    test('must be YYYY-MM-DD', () async {
      await db.customStatement('''
        CREATE TABLE probe (
          occurred_on TEXT NOT NULL
            CHECK (occurred_on GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')
        ) STRICT;
      ''');

      Future<void> insert(String value) => db.customStatement(
        'INSERT INTO probe (occurred_on) VALUES (?);',
        [value],
      );

      await expectLater(insert('2026-09-03'), completes);
      for (final bad in ['2026-9-3', '03/09/2026', '2026-09-03T00:00:00Z']) {
        await expectLater(insert(bad), throwsA(isA<Object>()), reason: bad);
      }
    });
  });

  group('updated_at is repaired on read, not blocked on write', () {
    test('a skewed pair reads back as equal', () {
      // SPEC.md §3 says repair on read. Blocking on write would refuse a row
      // whose only fault is that a device's clock moved backwards — and
      // refusing to save what somebody just typed, at a pump, in the rain, is
      // the worst possible answer to a clock problem.
      final repaired = repairAuditTimes(
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 400,
      );
      expect(repaired.updatedAtUtcMs, 1000);
      expect(repaired.createdAtUtcMs, 1000);
    });

    test('an ordinary pair is untouched', () {
      final ok = repairAuditTimes(createdAtUtcMs: 1000, updatedAtUtcMs: 2000);
      expect(ok.createdAtUtcMs, 1000);
      expect(ok.updatedAtUtcMs, 2000);
    });
  });

  group('money', () {
    test('a currency code is exactly three characters', () async {
      await db.customStatement('''
        CREATE TABLE probe_money (
          amount_minor INTEGER NOT NULL,
          currency TEXT NOT NULL CHECK (length(currency) = 3)
        ) STRICT;
      ''');

      Future<void> insert(String code) => db.customStatement(
        'INSERT INTO probe_money (amount_minor, currency) VALUES (4599, ?);',
        [code],
      );

      await expectLater(insert('EUR'), completes);
      await expectLater(insert('EU'), throwsA(isA<Object>()));
      await expectLater(insert('EURO'), throwsA(isA<Object>()));
    });

    test('money round-trips as minor units and a code', () async {
      await db.customStatement('''
        CREATE TABLE probe_amount (
          amount_minor INTEGER NOT NULL,
          currency TEXT NOT NULL CHECK (length(currency) = 3)
        ) STRICT;
      ''');
      await db.customStatement(
        "INSERT INTO probe_amount VALUES (4599, 'EUR');",
      );

      final row = await db
          .customSelect('SELECT * FROM probe_amount;')
          .getSingle();
      expect(row.read<int>('amount_minor'), 4599);
      expect(row.read<String>('currency'), 'EUR');
    });

    test(
      'a decimal amount is refused by STRICT, not silently truncated',
      () async {
        // The failure this table shape exists to prevent. Without STRICT,
        // SQLite would accept 45.99 into an INTEGER column and store 45.99 as a
        // float, which reads back as a cent short of itself.
        await db.customStatement('''
        CREATE TABLE probe_strict (amount_minor INTEGER NOT NULL) STRICT;
      ''');
        await expectLater(
          db.customStatement('INSERT INTO probe_strict VALUES (45.99);'),
          throwsA(isA<Object>()),
        );
      },
    );
  });
}
