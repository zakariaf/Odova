// The whole store, read once — and the two things that would corrupt a file.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/repositories/store_reader.dart';

late AppDatabase _db;

Future<void> _seed() async {
  await _db.customStatement('''
    INSERT INTO settings (
      id, created_at_utc_ms, updated_at_utc_ms, schema_version, language,
      calendar, numerals, first_day_of_week, theme, currency_default,
      currency_display, distance_unit, volume_unit, consumption_unit,
      notification_time_minutes, quiet_hours_from_minutes,
      quiet_hours_to_minutes
    ) VALUES ('settings', 1, 1, 1, 'en', 'gregorian', 'auto', 1, 'system',
              'EUR', 'none', 'km', 'l', 'l_100km', 540, 1260, 480);
  ''');
  await _db.customStatement('''
    INSERT INTO vehicles (
      id, name, vehicle_type, is_business, fuel_kind_default, status,
      sort_order, notifications_muted, created_at_utc_ms, updated_at_utc_ms
    ) VALUES ('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', 'Golf', 'car', 0, 'diesel',
              'active', 0, 0, 1000, 1000);
  ''');
  // One live, one soft-deleted.
  for (final (id, deleted) in [
    ('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH', 'NULL'),
    ('fil_01K1Y4T8R2E6W0Q3A7S1D5F9GJ', '5000'),
  ]) {
    await _db.customStatement('''
      INSERT INTO fill_ups (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, fuel_kind,
        quantity_ml, quantity_unit, total_cost_minor, currency, is_full_tank,
        chain_broken, created_at_utc_ms, updated_at_utc_ms, deleted_at_utc_ms
      ) VALUES ('$id', 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-07-29',
                214256000, 'km', 'diesel', 44020, 'l', 7351, 'EUR', 1, 0,
                2000, 2000, $deleted);
    ''');
  }
  await _db.customStatement('''
    INSERT INTO service_records (
      id, vehicle_id, occurred_on, odometer_unit, odometer_estimated,
      cost_estimated, created_at_utc_ms, updated_at_utc_ms
    ) VALUES ('srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
              'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-05-22', 'km', 0, 0,
              3000, 3000);
  ''');
  await _db.customStatement('''
    INSERT INTO service_lines (
      id, service_record_id, label, amount_minor, currency
    ) VALUES ('lin_01K0C4V2H9B8N3Q7ZE5RY6TMX1',
              'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX', 'Ölwechsel', 9820, 'EUR');
  ''');
}

void main() {
  setUp(() async {
    _db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
    await _seed();
  });
  tearDown(() => _db.close());

  test('a soft-deleted row is not in the snapshot', () async {
    // §3 makes a deleted row invisible to every query, and an export is a
    // query. §6 §7 says the same from the file's side.
    final store = await readStoreSnapshot(_db);

    expect(store.fillUps, hasLength(1));
    expect(
      store.fillUps.single.id.toString(),
      'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH',
    );
  });

  test('a service arrives with its lines attached', () async {
    // In ONE query for all of them. Four hundred round trips through the
    // executor is the difference between an export and a wait.
    final store = await readStoreSnapshot(_db);

    expect(store.services.single.lines, hasLength(1));
    expect(store.services.single.lines.single.label, 'Ölwechsel');
  });

  test(
    "a fill-up's emitted reading is not exported as a standalone one",
    () async {
      // §6 §7: it is re-derived from the fill-up on import, so exporting it
      // would duplicate every fill's reading on the next round trip — the
      // record count growing on each cycle.
      await _db.customStatement('''
      INSERT INTO odometer_readings (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
        source_id, created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('odo_01K2S1D9F4H7J0P3N6Q9T2W5YB',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-07-29', 214256000,
                'km', 'fillup', 'fil_01K1Y4T8R2E6W0Q3A7S1D5F9GH', 2000, 2000);
    ''');
      await _db.customStatement('''
      INSERT INTO odometer_readings (
        id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
        created_at_utc_ms, updated_at_utc_ms
      ) VALUES ('odo_01K2S1D9F4H7J0P3N6Q9T2W5YC',
                'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD', '2026-08-01', 215000000,
                'km', 'manual', 2100, 2100);
    ''');

      final store = await readStoreSnapshot(_db);

      expect(store.odometerReadings, hasLength(1));
      expect(store.odometerReadings.single.source.wire, 'manual');
    },
  );

  test('the counts are SQL, and they exclude deleted rows', () async {
    // `settings.backup` draws these on every open. A screen that read twelve
    // thousand records to print "12,000" is a screen that takes a second to
    // appear.
    final counts = await readRecordCounts(_db);

    expect(counts['vehicles'], 1);
    expect(counts['fillups'], 1);
    expect(counts['services'], 1);
    expect(counts['trips'], 0);
  });

  test(
    'a store with no settings row refuses rather than inventing one',
    () async {
      // Exporting one would write a file claiming defaults the user never
      // chose, and an importer on the other phone would apply them.
      await _db.customStatement('DELETE FROM settings;');

      expect(readStoreSnapshot(_db), throwsA(isA<StateError>()));
    },
  );
}
