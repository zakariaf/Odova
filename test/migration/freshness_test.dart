// The version the app claims, the snapshots on disk, and the ladder between
// them.
//
// SPEC.md §6.3 Versioning and migration; §17 Data-safety gate. Three things
// have to agree, and none of them is checked by the compiler:
//
//   `kLatestSchemaVersion` — what this build expects.
//   `drift_schemas/odova/`  — the committed snapshots.
//   `lib/data/schema_versions.dart` — the generated ladder.
//
// Bumping the constant without a snapshot makes `stepByStep` throw "Unknown
// migration from N" on a user's device. Adding a snapshot without bumping the
// constant means the migration never runs, and the app reads columns that are
// not there. Neither shows up until an update ships.
@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/schema_version.dart';

/// The version numbers `drift_schemas/odova/` actually holds.
List<int> committedSnapshotVersions() {
  final dir = Directory('drift_schemas/odova');
  expect(dir.existsSync(), isTrue, reason: 'run drift_dev make-migrations');

  return dir
      .listSync()
      .whereType<File>()
      .map((f) => RegExp(r'drift_schema_v(\d+)\.json$').firstMatch(f.path))
      .nonNulls
      .map((m) => int.parse(m.group(1)!))
      .toList()
    ..sort();
}

void main() {
  test('the committed snapshots run 1..kLatestSchemaVersion with no gaps', () {
    // A gap means a user two versions behind has no path forward: the ladder
    // has no step for the version they are on, and `stepByStep` throws.
    final versions = committedSnapshotVersions();

    expect(versions, isNotEmpty);
    expect(
      versions,
      List.generate(kLatestSchemaVersion, (i) => i + 1),
      reason: 'a missing snapshot is a version nobody can migrate off',
    );
  });

  test('AppDatabase.schemaVersion equals kLatestSchemaVersion', () async {
    // The two drifting apart means no migration runs on a user's device.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, kLatestSchemaVersion);
  });

  test('a fresh database opens at the current version', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final row = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(row.data.values.first, kLatestSchemaVersion);
  });

  test('a fresh database passes integrity and foreign-key checks', () async {
    // The baseline every future migration is measured against. Asserting it
    // at v1, when the ladder is empty, is what makes the same two assertions
    // meaningful after the first bump.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final integrity = await db
        .customSelect('PRAGMA integrity_check;')
        .getSingle();
    expect(integrity.data.values.first, 'ok');

    final orphans = await db.customSelect('PRAGMA foreign_key_check;').get();
    expect(orphans, isEmpty);
  });

  test('every from -> to pair migrates and validates', () async {
    // The nested loop from `run-migration`. At v1 it runs ZERO pairs, and that
    // is the point: it is written once, now, so a future bump cannot forget
    // the skip paths — the version that goes from 1 to 3 without ever being 2.
    final pairs = <(int, int)>[];
    for (var from = 1; from < kLatestSchemaVersion; from++) {
      for (var to = from + 1; to <= kLatestSchemaVersion; to++) {
        pairs.add((from, to));
      }
    }

    expect(
      pairs,
      isEmpty,
      reason:
          'v${pairs.firstOrNull?.$1} -> v${pairs.firstOrNull?.$2} has no '
          'verification yet. Add it here with the era-correct fixtures from '
          'test/drift/generated/, and assert row counts either side — a shape '
          'test reads zero rows, so it cannot tell a step that copied '
          'everything from one that copied nothing.',
    );
  });

  test('the generated ladder and the era-correct classes are committed', () {
    // Committed rather than generated on demand: a broken future `drift_dev`
    // must not stop the app building, and the era-correct classes are what
    // let a migration test WRITE rows in the old shape. Generating them at
    // test time would generate them from today's schema, which is the one
    // shape a migration test must not use.
    expect(File('lib/data/schema_versions.dart').existsSync(), isTrue);
    expect(File('test/drift/generated/schema.dart').existsSync(), isTrue);

    for (final version in committedSnapshotVersions()) {
      expect(
        File('test/drift/generated/schema_v$version.dart').existsSync(),
        isTrue,
        reason: 'v$version has a snapshot but no era-correct classes',
      );
    }
  });
}
