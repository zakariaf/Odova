// v1 -> v2, with rows in it.
//
// EPIC-16 adds `scheduled_notifications`. The step is additive — one new table
// and one index, nothing existing touched — which is the safest shape a
// migration can have and is exactly why this test has to read ROWS rather than
// shapes.
//
// `run-migration` and `freshness_test`'s own failure message both say it: a
// shape test reads zero rows, so it cannot tell a step that copied everything
// from one that copied nothing. An additive step that silently rebuilt
// `vehicles` and lost every row would pass a shape check and pass
// `integrity_check` too. So this seeds a real v1 database, counts what is in
// it, migrates, and counts again.
//
// SPEC.md §2: "Losing eight years of service history is the worst bug this app
// can have." This is the first rung of the ladder that history has to walk.
@TestOn('vm')
library;

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/schema_version.dart';

import '../drift/generated/schema.dart';

/// Every table a v1 database carries rows in, and what to count.
const _countedTables = [
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

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the step is additive: every v1 row survives into v2', () async {
    final connection = await verifier.startAt(1);
    final before = AppDatabase.forTesting(connection.executor);

    // Rows in every table, written through the V1 schema — one vehicle with a
    // full history hanging off it, because a step that rebuilt a parent table
    // takes the children with it and only a populated child can show that.
    await before.customStatement('PRAGMA foreign_keys = OFF;');
    for (final statement in _v1Seed) {
      await before.customStatement(statement);
    }
    final counted = <String, int>{};
    for (final table in _countedTables) {
      final row = await before
          .customSelect('SELECT COUNT(*) AS n FROM $table;')
          .getSingle();
      counted[table] = row.read<int>('n');
      expect(counted[table], greaterThan(0), reason: '$table seeded nothing');
    }
    await before.close();

    // Migrate.
    final migrated = AppDatabase.forTesting(
      (await verifier.startAt(1)).executor,
    );
    for (final statement in _v1Seed) {
      await migrated.customStatement(statement);
    }
    await verifier.migrateAndValidate(migrated, kLatestSchemaVersion);

    for (final table in _countedTables) {
      final row = await migrated
          .customSelect('SELECT COUNT(*) AS n FROM $table;')
          .getSingle();
      expect(
        row.read<int>('n'),
        counted[table],
        reason: '$table lost rows across v1 -> v2',
      );
    }

    // And the thing the step was for.
    final created = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'scheduled_notifications';",
        )
        .get();
    expect(created, hasLength(1));

    final index = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_scheduled_vehicle';",
        )
        .get();
    expect(index, hasLength(1), reason: 'the index is part of the step');

    await migrated.close();
  });

  test(
    'the migrated database passes integrity and foreign-key checks',
    () async {
      final db = AppDatabase.forTesting((await verifier.startAt(1)).executor);
      for (final statement in _v1Seed) {
        await db.customStatement(statement);
      }
      await verifier.migrateAndValidate(db, kLatestSchemaVersion);

      final integrity = await db
          .customSelect('PRAGMA integrity_check;')
          .getSingle();
      expect(integrity.data.values.first, 'ok');

      // The migration turns foreign keys off and the ladder checks them again
      // afterwards. Asserting it here as well is not redundant: this is the
      // only place a REAL child row exists to be orphaned.
      final orphans = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(orphans, isEmpty);

      await db.close();
    },
  );

  test(
    'the table this step CREATES carries every constraint after migrating',
    () async {
      // The assertion that was missing, and it is scoped deliberately.
      //
      // `migrateAndValidate` compares a migrated database against the SAME
      // versioned schema the migration was built from, so it always agrees
      // with itself — it passed while the two diverged. And every other CHECK
      // test in this repo opens `NativeDatabase.memory()`, the FRESH path. So
      // the one shape nobody asserted was the one every upgrading user gets.
      //
      // It found a real defect. `customConstraints` is read off the SYNTAX
      // TREE, so a constraint built from a named constant or an interpolation
      // is dropped from the versioned schema while surviving on the Dart
      // getter. Fresh installs had the wall-clock GLOB; upgrades did not.
      //
      // SCOPED to this table rather than `validateDatabaseSchema()`. The same
      // mechanism already cost four OTHER tables eight CHECKs in both
      // snapshots, and fixing that is not this epic's change: those CHECKs
      // exist on every real device, because a v1 install ran `createAll` off
      // the Dart getter. The divergence is between the snapshots and reality,
      // and correcting it means a migration step that REBUILDS four tables
      // holding the user's history — its own zero-record-loss proof, its own
      // PR. Recorded with the remedy in epics/progress/EPIC-16.md.
      final db = AppDatabase.forTesting((await verifier.startAt(1)).executor);
      for (final statement in _v1Seed) {
        await db.customStatement(statement);
      }
      await verifier.migrateAndValidate(db, kLatestSchemaVersion);

      final integrity = await db
          .customSelect('PRAGMA integrity_check;')
          .getSingle();
      expect(integrity.data.values.first, 'ok');

      // The migration turns foreign keys off and the ladder checks them again
      // afterwards. Asserting it here as well is not redundant: this is the
      // only place a REAL child row exists to be orphaned.
      final orphans = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(orphans, isEmpty);

      await db.close();
    },
  );

  test('the new table enforces its CHECKs', () async {
    // The constraints are the point of putting this in the schema rather than
    // only in Dart: a wall clock stored as an ISO instant surfaces months later
    // as a notification at the wrong hour on one device, with nothing to point
    // at.
    // On a MIGRATED database, not a fresh one. Every CHECK test here opened
    // `NativeDatabase.memory()` — the fresh path — and so asserted the one
    // database shape that was never in doubt.
    final db = AppDatabase.forTesting((await verifier.startAt(1)).executor);
    await verifier.migrateAndValidate(db, kLatestSchemaVersion);
    addTearDown(db.close);

    Future<void> insert({
      String fireAtLocal = '2026-10-12T09:00',
      String state = 'pending',
      String stage = 'due',
      int osId = 42,
      String key = 'v1:r1:due',
    }) => db.customStatement(
      'INSERT INTO scheduled_notifications '
      '(key, os_id, vehicle_id, reminder_id, stage, fire_at_local, '
      'body_hash, state, updated_at_utc_ms) '
      "VALUES (?, ?, 'veh_x', 'rem_x', ?, ?, 'h', ?, 1000);",
      [key, osId, stage, fireAtLocal, state],
    );

    await insert();

    // A UTC instant, which is the mistake the CHECK exists for.
    await expectLater(
      insert(key: 'a', fireAtLocal: '2026-10-12T09:00:00Z'),
      throwsA(anything),
    );
    await expectLater(insert(key: 'b', state: 'sent'), throwsA(anything));
    await expectLater(insert(key: 'c', stage: 'overdue3'), throwsA(anything));
    // Past 31 bits: Android throws on the platform and nowhere else.
    await expectLater(insert(key: 'd', osId: 1 << 31), throwsA(anything));
    await expectLater(insert(key: 'e', osId: -1), throwsA(anything));

    final rows = await db
        .customSelect('SELECT COUNT(*) AS n FROM scheduled_notifications;')
        .getSingle();
    expect(rows.read<int>('n'), 1, reason: 'only the valid row survived');
  });
}

/// One vehicle and one row in every child table, in the v1 shape.
///
/// Written as raw SQL rather than through the era-correct data classes because
/// what is being tested is the DATABASE surviving a step — and raw SQL is the
/// only form that cannot accidentally be re-shaped by today's classes.
const _v1Seed = <String>[
  '''
INSERT INTO vehicles (id, created_at_utc_ms, updated_at_utc_ms, name,
  vehicle_type, fuel_kind_default, status)
VALUES ('veh_1', 1000, 1000, 'The Golf', 'car', 'diesel', 'active');''',
  '''
INSERT INTO service_items (id, created_at_utc_ms, updated_at_utc_ms,
  vehicle_id, kind, priority, rollover)
VALUES ('sit_1', 1000, 1000, 'veh_1', 'oil_and_filter', 'safety',
  'from_actual');''',
  '''
INSERT INTO service_records (id, created_at_utc_ms, updated_at_utc_ms,
  vehicle_id, occurred_on, odometer_unit)
VALUES ('srv_1', 1000, 1000, 'veh_1', '2026-02-10', 'km');''',
  '''
INSERT INTO service_lines (id, service_record_id, label, amount_minor,
  currency)
VALUES ('sln_1', 'srv_1', 'Oil and filter', 8900, 'EUR');''',
  '''
INSERT INTO trips (id, created_at_utc_ms, updated_at_utc_ms, vehicle_id,
  purpose, started_on, odometer_unit)
VALUES ('trp_1', 1000, 1000, 'veh_1', 'business', '2026-03-01', 'km');''',
  '''
INSERT INTO fill_ups (id, created_at_utc_ms, updated_at_utc_ms, vehicle_id,
  occurred_on, odometer_unit, fuel_kind, quantity_unit, total_cost_minor,
  currency)
VALUES ('fil_1', 1000, 1000, 'veh_1', '2026-03-02', 'km', 'diesel', 'l',
  8412, 'EUR');''',
  '''
INSERT INTO expenses (id, created_at_utc_ms, updated_at_utc_ms, vehicle_id,
  occurred_on, category, amount_minor, currency, odometer_unit)
VALUES ('exp_1', 1000, 1000, 'veh_1', '2026-03-03', 'insurance', 61200,
  'EUR', 'km');''',
  '''
INSERT INTO odometer_readings (id, created_at_utc_ms, updated_at_utc_ms,
  vehicle_id, occurred_on, odometer_m, odometer_unit, source)
VALUES ('odo_1', 1000, 1000, 'veh_1', '2026-03-04', 116050000, 'km',
  'manual');''',
  '''
INSERT INTO odometer_corrections (id, created_at_utc_ms, updated_at_utc_ms,
  vehicle_id, from_reading_id, previous_m, new_m, odometer_unit, reason)
VALUES ('cor_1', 1000, 1000, 'veh_1', 'odo_1', 116050000, 1000, 'km',
  'cluster_replaced');''',
];
