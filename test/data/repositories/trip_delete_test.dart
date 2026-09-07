// Deleting a trip, and what survives it.
//
// SPEC.md §10: "Deleting a trip does not delete its expenses or fill-ups —
// they lose the trip link and stay in history." A cascade here would take a
// week of tolls out of the cost dashboard because somebody tidied up a trip.
@TestOn('vm')
library;

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final TripId _tripId = TripId.tryParse('trp_$_body')!;
final ExpenseId _expenseId = ExpenseId.tryParse('exp_$_body')!;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await VehicleRepository(db, testIds()).save(
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
    await TripRepository(db, testIds()).save(
      Trip(
        id: _tripId,
        vehicleId: _vehicleId,
        purpose: TripPurpose.business,
        startedOn: '2026-09-01',
        endedOn: '2026-09-02',
        startOdometer: const Distance(187_000_000),
        endOdometer: const Distance(187_145_000),
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    await ExpenseRepository(db, testIds()).save(
      Expense(
        id: _expenseId,
        vehicleId: _vehicleId,
        tripId: _tripId,
        occurredOn: '2026-09-02',
        category: ExpenseCategory.toll,
        amount: Money(1200, Currency.tryParse('EUR')!),
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  });

  tearDown(() => db.close());

  Future<int> liveReadings() async {
    final rows = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM odometer_readings '
          'WHERE source_id = ? AND deleted_at_utc_ms IS NULL;',
          variables: [Variable<String>(_tripId.toString())],
        )
        .getSingle();
    return rows.read<int>('n');
  }

  test(
    'a delete takes BOTH derived readings, and an undo brings both back',
    () async {
      // Two, because a trip emits `trip_start` and `trip_end` — they differ by
      // source alone, and a delete that stamped one would leave the due engine
      // computing distance from half a trip.
      expect(await liveReadings(), 2);

      await TripRepository(db, testIds()).delete(_tripId, deletedAtUtcMs: 2000);
      expect(await liveReadings(), 0);

      await TripRepository(db, testIds()).undelete(_tripId);
      expect(await liveReadings(), 2);
    },
  );

  test('the trip goes and its expense stays in history', () async {
    await TripRepository(db, testIds()).delete(_tripId, deletedAtUtcMs: 2000);

    expect(
      await TripRepository(db, testIds()).watchForVehicle(_vehicleId).first,
      isEmpty,
    );
    // The toll is still there. It is money the household spent, and a trip is
    // only a label on it.
    final expenses = await ExpenseRepository(
      db,
      testIds(),
    ).watchForVehicle(_vehicleId).first;
    expect(expenses.map((e) => e.id), [_expenseId]);
  });
}
