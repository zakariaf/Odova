// SPEC.md §17's data-safety gate: a migration loses no record.
//
// Counts AND a content hash, before and after. Counts alone would not notice a
// migration that copied the right number of rows with the wrong values in them,
// which is exactly what a mis-mapped column does — and it is the failure that
// survives review, because everything still looks populated.
//
// At v1 the ladder is a no-op and what is being proven is the HARNESS. From the
// first bump on, this is the test that catches a step that copied nothing.
@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/app_database_opener.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/large_fixture.dart';

void main() {
  late Directory dir;
  late File dbFile;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('odova_zero_loss');
    dbFile = File('${dir.path}/odova.sqlite');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Creates the schema, then fills it.
  Future<void> seed() async {
    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    await db.customStatement('SELECT 1;');
    await db.close();

    final raw = sqlite3.open(dbFile.path);
    seedLargeFixture(raw);
    raw.dispose();
  }

  test(
    '12,000 records survive an open with identical counts and hash',
    () async {
      final tables = const SchemaReaderV1().tables;

      await seed();

      final before = sqlite3.open(dbFile.path);
      final countsBefore = rowCounts(before, tables);
      final hashBefore = contentHash(before, tables);
      before.dispose();

      expect(
        countsBefore.values.reduce((a, b) => a + b),
        greaterThanOrEqualTo(largeFixtureRecordCount - 4),
        reason: 'the fixture has to actually be large, or this proves nothing',
      );

      final stopwatch = Stopwatch()..start();
      final outcome = await openMigratedDatabase(dbFile, safetyDirectory: dir);
      stopwatch.stop();

      expect(outcome, isA<OpenedCleanly>());
      await (outcome as OpenedCleanly).database.close();

      final after = sqlite3.open(dbFile.path);
      final countsAfter = rowCounts(after, tables);
      final hashAfter = contentHash(after, tables);
      after.dispose();

      expect(countsAfter, countsBefore);
      expect(hashAfter, hashBefore);

      // Reported, not asserted as a hard limit. SPEC.md §17's budget is 3
      // seconds on the FLOOR device; CI is not that device, and a hard timing
      // assertion on a shared runner is a flaky test rather than a gate.
      // ignore: avoid_print
      print(
        'ladder over ${countsBefore.values.reduce((a, b) => a + b)} '
        'records: ${stopwatch.elapsedMilliseconds} ms',
      );
    },
  );

  test('the oracle notices a single changed value', () async {
    // Guard the guard. A hash that did not actually cover the row CONTENT
    // would pass every migration, including one that emptied a column — and
    // the counts would agree.
    final tables = const SchemaReaderV1().tables;
    await seed();

    final database = sqlite3.open(dbFile.path);
    final before = contentHash(database, tables);

    database.execute(
      'UPDATE fill_ups SET total_cost_minor = total_cost_minor + 1 '
      'WHERE id = (SELECT id FROM fill_ups LIMIT 1);',
    );

    final after = contentHash(database, tables);
    final counts = rowCounts(database, tables);
    database.dispose();

    expect(after, isNot(before), reason: 'the hash must cover row content');
    expect(
      counts.values.reduce((a, b) => a + b),
      greaterThan(0),
      reason: 'counts alone would not have noticed',
    );
  });

  test('the fixture is deterministic from its seed', () async {
    // Two runs of the same seed produce the same database, so a failure is
    // reproducible from the test name alone. Different seeds must NOT — a
    // fixture that ignores its seed is a fixture that tests one shape forever.
    final tables = const SchemaReaderV1().tables;

    Future<String> hashFor(int seed, String name) async {
      final file = File('${dir.path}/$name.sqlite');
      final db = AppDatabase.forTesting(
        NativeDatabase(file, setup: applyPragmas),
      );
      await db.customStatement('SELECT 1;');
      await db.close();

      final raw = sqlite3.open(file.path);
      seedLargeFixture(raw, seed: seed);
      final hash = contentHash(raw, tables);
      raw.dispose();
      return hash;
    }

    expect(await hashFor(1, 'a'), await hashFor(1, 'b'));
    expect(await hashFor(1, 'c'), isNot(await hashFor(2, 'd')));
  });
}
