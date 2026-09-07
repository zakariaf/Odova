// The escape route is a file the app can actually walk back through.
//
// SPEC.md §6.4.4 calls the pre-migration copy the escape route. Until EPIC-15
// task 15.3 it was a raw table dump: every byte of the user's history, in a
// shape nothing in the app could read. A copy you cannot restore from is a
// reassurance, not a backup.
//
// So this test does the whole loop — a real v1 database, the numbered v1
// reader, the v1 projection, and then `BackupReader` on the result — because
// each half of it passing separately is what let the gap exist.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/backup/migration_safety_copy.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';
import 'package:odova/features/backup/domain/backup_reader.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/export_stamp.dart';

/// The one row every read needs. Its absence is a `StateError`, deliberately:
/// a store with no settings is a store that has not been created.
Future<void> _seedSettings(AppDatabase db) => db.customStatement('''
  INSERT INTO settings (
    id, created_at_utc_ms, updated_at_utc_ms, schema_version, language,
    calendar, numerals, first_day_of_week, theme, currency_default,
    currency_display, distance_unit, volume_unit, consumption_unit,
    notification_time_minutes, quiet_hours_from_minutes,
    quiet_hours_to_minutes
  ) VALUES ('settings', 1, 1, 1, 'en', 'gregorian', 'auto', 1, 'system',
            'EUR', 'none', 'km', 'l', 'l_100km', 540, 1260, 480);
''');

void main() {
  test('every numbered reader carries a projection, by construction', () {
    // `toBackupDocument` is an ABSTRACT member of `SchemaReader`, so a new
    // numbered reader cannot compile without one. The first version put the
    // projections in a `switch` with a `_ => raw` fallback, which meant the
    // next schema bump would ship an escape route `BackupReader` refuses at
    // rung 4 — and the only signal would be a user who cannot restore.
    //
    // Asserted over every reader this build carries rather than over v1, so
    // it keeps meaning something when there are three.
    for (final entry in schemaReaders.entries) {
      final document = entry.value.toBackupDocument(
        const {'schema_version': 1, 'tables': <String, Object?>{}},
        kTestExportStamp,
      );

      expect(document['format'], 'odova.backup', reason: 'v${entry.key}');
      // Its OWN version, never a constant that moves: a v5 binary writing a
      // v1 database must stamp 1.
      expect(document['format_version'], entry.key, reason: 'v${entry.key}');
    }
  });

  late Directory dir;
  late File dbFile;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('odova_safety_import');
    dbFile = File('${dir.path}/odova.sqlite');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('the copy of a real v1 database imports', () async {
    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    await db.customStatement('''
      INSERT INTO vehicles (
        id, name, vehicle_type, is_business, fuel_kind_default, status,
        sort_order, notifications_muted, notes,
        created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'VW Käfer', 'car', 0,
                'diesel', 'active', 0, 0, 'Zahnriemen laut Werkstatt',
                1000, 1000);
    ''');
    await db.customStatement('''
      INSERT INTO fill_ups (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, fuel_kind,
        quantity_ml, quantity_unit, total_cost_minor, currency,
        is_full_tank, chain_broken, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-07-29', 214256000,
                'km', 'diesel', 44020, 'l', 7351, 'EUR', 1, 0, 2000, 2000);
    ''');
    // A row the user deleted. §6 §7 keeps it out of the file, and a "safety"
    // copy that resurrected it would be a copy that changes the data.
    await db.customStatement('''
      INSERT INTO expenses (
        id, vehicle_id, occurred_on, category, amount_minor, currency,
        odometer_unit, created_at_utc_ms, updated_at_utc_ms,
        deleted_at_utc_ms
      ) VALUES ('exp_01K1R9T6Y2W5Q8Z3E7B0N4MJDF',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-01-03', 'insurance',
                61200, 'EUR', 'km', 3000, 3000, 4000);
    ''');
    await db.close();

    final raw = sqlite3.open(dbFile.path);
    final (file, failure) = await writeMigrationSafetyCopy(
      database: raw,
      fromVersion: 1,
      directory: dir,
      stamp: kTestExportStamp,
    );
    raw.dispose();
    expect(failure, isNull);

    final result = await const BackupReader().read(file!);
    final plan = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail(
        'the safety copy did not import: ${failure.code}',
      ),
    };

    expect(plan.store.vehicles.single.name, 'VW Käfer');
    expect(plan.store.vehicles.single.notes, 'Zahnriemen laut Werkstatt');
    expect(plan.store.fillUps.single.totalCost.amountMinor, 7351);
    expect(plan.store.fillUps.single.quantity!.amount, 44020);
    // Deleted stays deleted.
    expect(plan.store.expenses, isEmpty);
    expect(plan.recordsInFile, 2);
  });

  test(
    'an electric and a gas fill keep their own unit through the copy',
    () async {
      // v1 has three quantity COLUMNS and the file has three quantity KEYS, and
      // the mapping between them is the one that fails silently: watt-hours
      // written into `quantity_ml` come back as 41.5 litres of diesel, and
      // nothing in the file or on the screen would say so.
      final db = AppDatabase.forTesting(
        NativeDatabase(dbFile, setup: applyPragmas),
      );
      await db.customStatement('''
      INSERT INTO vehicles (
        id, name, vehicle_type, is_business, fuel_kind_default, status,
        sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'e-up', 'car', 0,
                'electric', 'active', 0, 0, 1000, 1000);
    ''');
      await db.customStatement('''
      INSERT INTO fill_ups (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, fuel_kind,
        energy_wh, quantity_unit, total_cost_minor, currency,
        is_full_tank, chain_broken, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-07-29', 214256000,
                'km', 'electric', 41500, 'l', 1290, 'EUR', 1, 0, 2000, 2000);
    ''');
      await db.customStatement('''
      INSERT INTO fill_ups (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, fuel_kind,
        quantity_g, quantity_unit, total_cost_minor, currency,
        is_full_tank, chain_broken, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-07-30', 214300000,
                'km', 'cng', 4300, 'l', 3900, 'EUR', 1, 0, 2100, 2100);
    ''');
      await db.close();

      final raw = sqlite3.open(dbFile.path);
      final (file, _) = await writeMigrationSafetyCopy(
        database: raw,
        fromVersion: 1,
        directory: dir,
        stamp: kTestExportStamp,
      );
      raw.dispose();

      final document =
          jsonDecode(file!.readAsStringSync()) as Map<String, Object?>;
      final rows = (document['fillups']! as List).cast<Map<String, Object?>>();

      expect(rows[0]['energy_wh'], 41500);
      expect(rows[0].containsKey('quantity_ml'), isFalse);
      expect(rows[1]['quantity_g'], 4300);
      expect(rows[1].containsKey('quantity_ml'), isFalse);

      final plan = switch (await const BackupReader().read(file)) {
        Ok(:final value) => value,
        Err(:final failure) => fail('did not import: ${failure.code}'),
      };
      expect(
        plan.store.fillUps.map((f) => f.quantity.runtimeType.toString()),
        ['ElectricEnergy', 'GasMass'],
      );
    },
  );

  test('the copy verifies its own hash, and warns about nothing', () async {
    // It wrote `"content_hash": null`, so `contentHashMatches` found nothing
    // and every pre-migration copy imported with "this file has been edited
    // since Odova saved it" — on the ONE file a user reaches after a bad
    // update, where a spurious damage warning is the last thing they need.
    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    await _seedSettings(db);
    await db.close();

    final raw = sqlite3.open(dbFile.path);
    final (file, _) = await writeMigrationSafetyCopy(
      database: raw,
      fromVersion: 1,
      directory: dir,
      stamp: kTestExportStamp,
    );
    raw.dispose();

    final plan = switch (await const BackupReader().read(file!)) {
      Ok(:final value) => value,
      Err(:final failure) => fail('did not import: ${failure.code}'),
    };
    expect(
      plan.warnings.whereType<ContentHashMismatch>(),
      isEmpty,
      reason: 'the escape route must verify against itself',
    );
  });

  test('a reading from a previous restore is in the copy', () async {
    // "Standalone" is `source_id IS NULL`, which is how `store_reader` and
    // `record_backup` both define it. Filtering on `source == 'manual'`
    // dropped every reading whose source was `import` — one that arrived in an
    // earlier restore — from the escape route.
    final db = AppDatabase.forTesting(
      NativeDatabase(dbFile, setup: applyPragmas),
    );
    await _seedSettings(db);
    await db.customStatement('''
      INSERT INTO vehicles (
        id, name, vehicle_type, is_business, fuel_kind_default, status,
        sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'Golf', 'car', 0, 'diesel',
                'active', 0, 0, 1000, 1000);
    ''');
    await db.customStatement('''
      INSERT INTO odometer_readings (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
        created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('odo_01K2S1D9F4H7J0P3N6Q9T2W5YB',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-08-01', 215000000,
                'km', 'import', 2100, 2100);
    ''');
    await db.close();

    final raw = sqlite3.open(dbFile.path);
    final (file, _) = await writeMigrationSafetyCopy(
      database: raw,
      fromVersion: 1,
      directory: dir,
      stamp: kTestExportStamp,
    );
    raw.dispose();

    final document =
        jsonDecode(file!.readAsStringSync()) as Map<String, Object?>;
    expect(document['odometer_readings']! as List, hasLength(1));
  });
}
