// Delete, Undo, purge, and the two cascades that behave differently.
//
// SPEC.md §3 Identity, timestamps, deletion. Every claim here is about what
// SURVIVES, which is the property this app values above every feature: a delete
// that takes rows nobody asked for is unrecoverable, and a soft delete that
// leaks into a query shows the user something they deleted.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/deletion.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final VehicleId _otherId = VehicleId.tryParse(
  'veh_01JV7B5X4G2K9M6P0S3D8FNRTC',
)!;

Vehicle _vehicle(VehicleId id, String name) => Vehicle(
  id: id,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  late AppDatabase db;
  late VehicleRepository vehicles;
  late ServiceRepository services;
  late FillUpRepository fillUps;
  late OdometerRepository odometer;

  /// Populates one vehicle with one row in every child table.
  Future<void> populate(VehicleId vehicleId, String suffix) async {
    await vehicles.save(_vehicle(vehicleId, 'Car $suffix'));

    final recordId = ServiceRecordId.tryParse(
      'srv_${_body.substring(0, 25)}$suffix',
    )!;
    await services.saveItem(
      ServiceItem(
        id: ServiceItemId.tryParse('rem_${_body.substring(0, 25)}$suffix')!,
        vehicleId: vehicleId,
        kind: ServiceKind.oilAndFilter,
        priority: ServicePriority.normal,
        rollover: ServiceRollover.fromActual,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
        intervalDistanceM: 15000000,
      ),
    );
    await services.saveRecord(
      ServiceRecord(
        id: recordId,
        vehicleId: vehicleId,
        occurredOn: '2026-09-03',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
        lines: [
          ServiceLine(
            id: ServiceLineId.tryParse(
              'lin_${_body.substring(0, 25)}$suffix',
            )!,
            serviceRecordId: recordId,
            label: 'Oil and filter',
            amountMinor: 8900,
            currency: 'EUR',
          ),
        ],
      ),
    );
    await fillUps.save(
      FillUp(
        id: FillUpId.tryParse('fil_${_body.substring(0, 25)}$suffix')!,
        vehicleId: vehicleId,
        occurredOn: '2026-09-03',
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantityUnit: VolumeUnit.l,
        totalCostMinor: 7845,
        currency: 'EUR',
        quantityMl: 45200,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    await ExpenseRepository(db, testIds()).save(
      Expense(
        id: ExpenseId.tryParse('exp_${_body.substring(0, 25)}$suffix')!,
        vehicleId: vehicleId,
        occurredOn: '2026-09-03',
        category: ExpenseCategory.insurance,
        amountMinor: 42000,
        currency: 'EUR',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    await TripRepository(db, testIds()).save(
      Trip(
        id: TripId.tryParse('trp_${_body.substring(0, 25)}$suffix')!,
        vehicleId: vehicleId,
        purpose: TripPurpose.business,
        startedOn: '2026-09-01',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    final readingId = OdometerReadingId.tryParse(
      'odo_${_body.substring(0, 25)}$suffix',
    )!;
    await odometer.saveReading(
      OdometerReading(
        id: readingId,
        vehicleId: vehicleId,
        occurredOn: '2026-09-03',
        odometerM: 186512000,
        odometerUnit: DistanceUnit.km,
        source: OdometerSource.manual,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
      vehicleUnit: DistanceUnit.km,
    );
    await odometer.saveCorrection(
      OdometerCorrection(
        id: OdometerCorrectionId.tryParse(
          'cor_${_body.substring(0, 25)}$suffix',
        )!,
        vehicleId: vehicleId,
        fromReadingId: readingId,
        previousM: 186512000,
        newM: 0,
        odometerUnit: DistanceUnit.km,
        reason: OdometerCorrectionReason.clusterReplaced,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  }

  Future<int> countLive(String table) async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM $table '
                'WHERE deleted_at_utc_ms IS NULL;',
              )
              .getSingle())
          .read<int>('n');

  Future<int> countRaw(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table;').getSingle())
          .read<int>('n');

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    vehicles = VehicleRepository(db);
    services = ServiceRepository(db, testIds());
    fillUps = FillUpRepository(db, testIds());
    odometer = OdometerRepository(db);
  });
  tearDown(() => db.close());

  test('a vehicle delete stamps every child with the SAME timestamp', () async {
    // Undo restores by timestamp, so one stamp across the set is what makes
    // "undo that delete" possible at all.
    await populate(_vehicleId, 'A');

    // The fixture has to reach every table, or this walks over empty ones and
    // asserts nothing. `odometer_corrections` was missing from the first
    // version and the empty-set comparison is what found it.
    for (final table in ['vehicles', ...vehicleChildTables]) {
      expect(await countRaw(table), isPositive, reason: '$table is empty');
    }

    await softDeleteVehicle(db, _vehicleId, 5000);

    for (final table in ['vehicles', ...vehicleChildTables]) {
      final stamps = await db
          .customSelect(
            'SELECT DISTINCT deleted_at_utc_ms AS d FROM $table '
            'WHERE deleted_at_utc_ms IS NOT NULL;',
          )
          .get();
      expect(
        stamps.map((r) => r.read<int>('d')).toSet(),
        {5000},
        reason: table,
      );
    }
  });

  test('a deleted vehicle is invisible to every repository read', () async {
    await populate(_vehicleId, 'A');
    await softDeleteVehicle(db, _vehicleId, 5000);

    expect(await vehicles.watchAll().first, isEmpty);
    expect(
      await vehicles.findById(_vehicleId),
      isA<Err<Vehicle, PersistFailure>>(),
    );
    expect(await services.watchItems(_vehicleId).first, isEmpty);
    expect(await services.watchRecords(_vehicleId).first, isEmpty);
    expect(await fillUps.watchForVehicle(_vehicleId).first, isEmpty);
    expect(await odometer.watchReadings(_vehicleId).first, isEmpty);
  });

  test('undo restores exactly the set that was stamped', () async {
    // A row deleted BEFORE the vehicle carries a different timestamp and must
    // stay deleted. Undoing "everything currently deleted" would resurrect a
    // fill-up the user removed five minutes earlier, which is a data change
    // nobody asked for.
    await populate(_vehicleId, 'A');
    await db.customStatement(
      'UPDATE fill_ups SET deleted_at_utc_ms = 100 WHERE vehicle_id = ?;',
      [_vehicleId.toString()],
    );

    await softDeleteVehicle(db, _vehicleId, 5000);
    await undoDeleteVehicle(db, _vehicleId, 5000);

    expect(await countLive('vehicles'), 1);
    expect(await countLive('service_records'), 1);
    expect(
      await countLive('fill_ups'),
      0,
      reason: 'the earlier delete must survive the undo',
    );
  });

  test('a delete does not touch another vehicle', () async {
    await populate(_vehicleId, 'A');
    await populate(_otherId, 'B');

    await softDeleteVehicle(db, _vehicleId, 5000);

    expect(await countLive('vehicles'), 1);
    expect(await countLive('fill_ups'), 1);
    expect((await vehicles.watchAll().first).single.id, _otherId);
  });

  test(
    'purge removes the rows permanently, and leaves no deleted_at',
    () async {
      // SPEC.md §3: after the window the row is purged, so a settled database
      // has `deleted_at IS NULL` on everything that exists — no bin, no
      // tombstones, nothing deleted in the export.
      await populate(_vehicleId, 'A');
      await softDeleteVehicle(db, _vehicleId, 5000);

      final removed =
          (await purgeDeleted(db, 5000) as Ok<Map<String, int>, PersistFailure>)
              .value;
      expect(removed['vehicles'], 1);

      for (final table in [
        'vehicles',
        ...vehicleChildTables,
        'service_lines',
      ]) {
        expect(await countRaw(table), 0, reason: table);
      }

      final orphanStamps = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM vehicles '
            'WHERE deleted_at_utc_ms IS NOT NULL;',
          )
          .getSingle();
      expect(orphanStamps.read<int>('n'), 0);
    },
  );

  test('purge leaves rows deleted AFTER the cutoff alone', () async {
    // The undo window has not closed for those yet. Purging them would delete
    // something the user can still undo, which is the one operation in the
    // data layer that cannot be taken back.
    await populate(_vehicleId, 'A');
    await softDeleteVehicle(db, _vehicleId, 9000);

    await purgeDeleted(db, 5000);
    expect(await countRaw('vehicles'), 1);

    await purgeDeleted(db, 9000);
    expect(await countRaw('vehicles'), 0);
  });

  test('erase permanently is a hard delete with nothing to undo', () async {
    await populate(_vehicleId, 'A');
    await eraseVehiclePermanently(db, _vehicleId);

    for (final table in ['vehicles', ...vehicleChildTables, 'service_lines']) {
      expect(await countRaw(table), 0, reason: table);
    }
    // And undo cannot bring it back, because there is nothing stamped.
    await undoDeleteVehicle(db, _vehicleId, 5000);
    expect(await countRaw('vehicles'), 0);
  });

  test('deleting a service item never touches history', () async {
    // SPEC.md §3: every referencing line is rewritten to null and KEEPS its
    // label and amount. Deleting a reminder definition must not destroy the
    // record of work that was actually done.
    await populate(_vehicleId, 'A');
    final itemId = ServiceItemId.tryParse('rem_${_body.substring(0, 25)}A')!;
    final recordId = ServiceRecordId.tryParse(
      'srv_${_body.substring(0, 25)}A',
    )!;

    await db.customStatement(
      'UPDATE service_lines SET service_item_id = ? WHERE id = ?;',
      [itemId.toString(), 'lin_${_body.substring(0, 25)}A'],
    );
    await db.customStatement('DELETE FROM service_items WHERE id = ?;', [
      itemId.toString(),
    ]);

    final record =
        (await services.findRecordById(recordId)
                as Ok<ServiceRecord, PersistFailure>)
            .value;
    expect(record.lines, hasLength(1));
    expect(record.lines.single.serviceItemId, isNull);
    expect(record.lines.single.label, 'Oil and filter');
    expect(record.lines.single.amountMinor, 8900);
  });

  test('service_lines carries no deleted_at, deliberately', () async {
    // It is a child row that lives and dies with its record, and the schema's
    // ON DELETE CASCADE removes it. A `deleted_at` here would be a second
    // answer about whether a line exists — and the two would disagree the
    // first time a record was undeleted.
    final columns = await db
        .customSelect('PRAGMA table_info(service_lines);')
        .get();
    expect(
      columns.map((c) => c.read<String>('name')),
      isNot(contains('deleted_at_utc_ms')),
    );
    expect(vehicleChildTables, isNot(contains('service_lines')));
  });
}
