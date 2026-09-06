// Undo, on the four tables logging writes.
//
// SPEC.md §10 makes Undo the only confirmation logging gets: "A wrong entry
// costs one tap to fix; a confirmation dialog is paid for on every correct
// entry." That trade only holds if Undo actually works, and until now none of
// these tables had a soft delete to undo.
//
// §3's contract, from `deletion.dart`: "Delete is immediate and permanent to
// the user; soft in storage only for the length of the snackbar." Undo restores
// exactly the set that was STAMPED — not everything currently deleted, which
// would resurrect a row deleted five minutes ago.
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
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/test_ids.dart';

const String _b = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_b')!;

void main() {
  late AppDatabase db;
  late FillUpRepository fillUps;
  late ExpenseRepository expenses;
  late ServiceRepository services;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: applyPragmas));
    fillUps = FillUpRepository(db, testIds());
    expenses = ExpenseRepository(db, testIds());
    services = ServiceRepository(db, testIds());
    await VehicleRepository(db, testUlids()).save(
      Vehicle(
        id: _vehicleId,
        name: 'The Golf',
        vehicleType: VehicleType.car,
        fuelKindDefault: FuelKind.diesel,
        status: VehicleStatus.active,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  });
  tearDown(() => db.close());

  Future<int> liveCount(String table) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM $table '
          'WHERE deleted_at_utc_ms IS NULL;',
        )
        .getSingle();
    return row.read<int>('n');
  }

  FillUp fillUp() => FillUp(
    id: FillUpId.tryParse('fil_$_b')!,
    vehicleId: _vehicleId,
    occurredOn: '2026-09-02',
    odometer: const Distance.fromKm(187412),
    odometerUnit: DistanceUnit.km,
    fuelKind: FuelKind.diesel,
    quantity: const LiquidVolume(Volume(42610)),
    quantityUnit: VolumeUnit.l,
    totalCost: Money(7666, Currency.tryParse('EUR')!),
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  Expense expense() => Expense(
    id: ExpenseId.tryParse('exp_$_b')!,
    vehicleId: _vehicleId,
    occurredOn: '2026-09-02',
    category: ExpenseCategory.parking,
    amount: Money(500, Currency.tryParse('EUR')!),
    odometerUnit: DistanceUnit.km,
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  ServiceRecord record() => ServiceRecord(
    id: ServiceRecordId.tryParse('srv_$_b')!,
    vehicleId: _vehicleId,
    occurredOn: '2026-09-02',
    odometerUnit: DistanceUnit.km,
    lines: [
      ServiceLine(
        id: ServiceLineId.tryParse('lin_$_b')!,
        serviceRecordId: ServiceRecordId.tryParse('srv_$_b')!,
        label: 'Oil and filter',
        amount: Money(9250, Currency.tryParse('EUR')!),
      ),
    ],
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  test('a fill-up soft-deletes and comes back', () async {
    await fillUps.save(fillUp());
    expect(await liveCount('fill_ups'), 1);

    final gone = await fillUps.delete(fillUp().id, deletedAtUtcMs: 2000);
    expect(gone, isA<Ok<void, PersistFailure>>());
    expect(await liveCount('fill_ups'), 0);

    await fillUps.undelete(fillUp().id);
    expect(await liveCount('fill_ups'), 1);
  });

  test('deleting a fill-up takes its derived reading with it', () async {
    // §3: every record carrying an odometer emits one. A delete that left the
    // reading behind would leave the due engine computing from a fill-up the
    // user has just undone.
    await fillUps.save(fillUp());
    expect(await liveCount('odometer_readings'), 1);

    await fillUps.delete(fillUp().id, deletedAtUtcMs: 2000);
    expect(await liveCount('odometer_readings'), 0);

    await fillUps.undelete(fillUp().id);
    expect(
      await liveCount('odometer_readings'),
      1,
      reason: 'the reading comes back with the record that emitted it',
    );
  });

  test('an expense soft-deletes and comes back', () async {
    await expenses.save(expense());
    await expenses.delete(expense().id, deletedAtUtcMs: 2000);
    expect(await liveCount('expenses'), 0);

    await expenses.undelete(expense().id);
    expect(await liveCount('expenses'), 1);
  });

  test('a service record soft-deletes and comes back', () async {
    await services.saveRecord(record());
    await services.deleteRecord(record().id, deletedAtUtcMs: 2000);
    expect(await liveCount('service_records'), 0);

    await services.undeleteRecord(record().id);
    expect(await liveCount('service_records'), 1);
  });

  test('deleting something that is not there reports NotFound', () async {
    // Never a silent success: the caller shows an Undo, and an Undo for
    // something that did not happen is worse than an error.
    final result = await fillUps.delete(fillUp().id, deletedAtUtcMs: 2000);
    expect(result, isA<Err<void, PersistFailure>>());
  });

  test('undo restores only the row it names', () async {
    // The set that was STAMPED, not everything currently deleted — otherwise
    // an Undo resurrects a row deleted five minutes ago.
    await fillUps.save(fillUp());
    await expenses.save(expense());
    await fillUps.delete(fillUp().id, deletedAtUtcMs: 1500);
    await expenses.delete(expense().id, deletedAtUtcMs: 2000);

    await expenses.undelete(expense().id);

    expect(await liveCount('expenses'), 1);
    expect(await liveCount('fill_ups'), 0, reason: 'the older delete stands');
  });

  test('a delete and an undo both reach a watching stream', () async {
    // The screen that shows the Undo is watching this list. `customUpdate`
    // takes an `updates:` set naming the tables it touched, and drift uses it
    // to decide which streams re-emit — an empty set means "nothing changed",
    // so Home would keep showing the fill-up the user just removed until
    // something unrelated invalidated the table.
    await fillUps.save(fillUp());

    final seen = <int>[];
    final sub = fillUps
        .watchForVehicle(_vehicleId)
        .listen((rows) => seen.add(rows.length));
    await pumpEventQueue();

    await fillUps.delete(fillUp().id, deletedAtUtcMs: 2000);
    await pumpEventQueue();

    await fillUps.undelete(fillUp().id);
    await pumpEventQueue();

    await sub.cancel();
    expect(seen, [1, 0, 1]);
  });

  test('deleting a service record re-emits its watching stream', () async {
    await services.saveRecord(record());

    final seen = <int>[];
    final sub = services
        .watchRecords(_vehicleId)
        .listen((rows) => seen.add(rows.length));
    await pumpEventQueue();

    await services.deleteRecord(record().id, deletedAtUtcMs: 2000);
    await pumpEventQueue();

    await services.undeleteRecord(record().id);
    await pumpEventQueue();

    await sub.cancel();
    expect(seen, [1, 0, 1]);
  });
}
