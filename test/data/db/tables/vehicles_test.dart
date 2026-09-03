// The vehicle table's invariants live in the SCHEMA, not at the call site.
//
// SPEC.md §3 Entities (`Vehicle`), §3 Enums, §3 Scope. Each rejection here must
// come back as a SQLite constraint error and not a Dart assertion: an
// invariant enforced in Dart is an invariant an import, a migration or a
// future repository can walk straight past.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/data/db/app_database.dart';

import '../../support/rows.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a minimal vehicle needs only a name, a type and a fuel kind', () async {
    await expectLater(insertVehicle(db), completes);

    final row = await db.customSelect('SELECT * FROM vehicles;').getSingle();
    expect(row.read<String>('name'), 'The Golf');
    expect(row.read<String>('vehicle_type'), 'car');
  });

  test('rejects a vehicle_type outside the five', () async {
    await expectLater(
      insertVehicle(db, vehicleType: 'boat'),
      throwsA(isA<SqliteException>()),
    );
    for (final type in VehicleType.values) {
      await expectLater(
        insertVehicle(db, id: 'veh_${type.name}', vehicleType: type.wire),
        completes,
        reason: type.wire,
      );
    }
  });

  test('rejects a status outside active|archived|sold', () async {
    await expectLater(
      insertVehicle(db, status: 'lost'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects a fuel_kind_default outside the seven', () async {
    await expectLater(
      insertVehicle(db, fuelKind: 'coal'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('accepts null on every per-vehicle override', () async {
    // Null means INHERIT, and it has to survive storage as null. A default at
    // this layer would freeze a vehicle's units at the moment it was created,
    // so changing Settings later would silently not apply to it.
    await insertVehicle(db);
    final row = await db.customSelect('SELECT * FROM vehicles;').getSingle();

    for (final column in [
      'currency',
      'distance_unit',
      'volume_unit',
      'consumption_unit',
      'notice_distance_m',
      'notice_days',
    ]) {
      expect(
        row.data[column],
        isNull,
        reason: '$column was defaulted; null means inherit',
      );
    }
  });

  test('rejects a tank_capacity_ml of zero or less', () async {
    await expectLater(
      insertVehicle(db, tankCapacityMl: 0),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertVehicle(db, id: 'veh_neg', tankCapacityMl: -1),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertVehicle(db, id: 'veh_ok', tankCapacityMl: 55000),
      completes,
    );
  });

  test('every currency column is three characters, checked in SQL', () async {
    // `withLength(min: 3, max: 3)` is a DART-side validator and emits nothing
    // into the schema, so all three of these were unchecked in the database —
    // and an import, a migration or a raw repository write could put `'EU'`
    // in one. The exponent that turns 4599 into 45.99 comes from the code, so
    // a two-letter one makes the amount unreadable rather than merely odd.
    await insertVehicle(db);

    for (final column in [
      'currency',
      'purchase_price_currency',
      'sold_price_currency',
    ]) {
      await expectLater(
        db.customStatement(
          'UPDATE vehicles SET $column = ? WHERE id = ?;',
          ['EU', 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD'],
        ),
        throwsA(isA<SqliteException>()),
        reason: column,
      );
      await expectLater(
        db.customStatement(
          'UPDATE vehicles SET $column = ? WHERE id = ?;',
          ['EUR', 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD'],
        ),
        completes,
        reason: column,
      );
    }
  });

  test('there is no photo column, and no attachment column', () async {
    // SPEC.md §3: "v1 has no photos and no attachments." Withdrawn features
    // come back as a column somebody adds "for later", and then an export
    // schema carries a field nothing writes.
    final columns = await db.customSelect('PRAGMA table_info(vehicles);').get();
    final names = columns.map((c) => c.read<String>('name')).toList();

    for (final banned in [
      'photo_id',
      'photo',
      'attachment_ids',
      'image_path',
    ]) {
      expect(names, isNot(contains(banned)));
    }
  });
}
