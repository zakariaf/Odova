// Which end of a newest-first list is the newest.
//
// Home draws one fill-up. It used to take it out of `watchForVehicle`'s list,
// which is ordered `occurred_on DESC, id DESC` — and it took the WRONG end, so
// the screen read out the oldest fill-up the vehicle ever had. A one-element
// fixture cannot tell `first` from `last`, which is why no test saw it.
//
// `watchLatestForVehicle` removes the choice: `LIMIT 1` in the query, one row
// out. This asserts that the row it picks is the recent one, over a real
// database, with the two rows deliberately written oldest-last so an
// implementation that ignored the ORDER BY would still pass by accident.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/test_ids.dart';

const String _b = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_b')!;

void main() {
  late AppDatabase db;
  late FillUpRepository fillUps;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fillUps = FillUpRepository(db, testIds());
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

  FillUp fillUp(String suffix, String occurredOn, int cents) => FillUp(
    id: FillUpId.tryParse('fil_${_b.substring(0, 25)}$suffix')!,
    vehicleId: _vehicleId,
    occurredOn: occurredOn,
    odometerUnit: DistanceUnit.km,
    fuelKind: FuelKind.diesel,
    quantity: const LiquidVolume(Volume(45200)),
    quantityUnit: VolumeUnit.l,
    totalCost: Money(cents, Currency.tryParse('EUR')!),
    createdAtUtcMs: 1000,
    updatedAtUtcMs: 1000,
  );

  test(
    'the latest fill-up is the most recent one, not the first written',
    () async {
      // Written NEWEST FIRST, so "whatever was inserted last" is the old one.
      await fillUps.save(fillUp('A', '2026-09-02', 7420));
      await fillUps.save(fillUp('B', '2026-08-01', 5130));

      final latest = await fillUps.watchLatestForVehicle(_vehicleId).first;

      expect(latest?.occurredOn, '2026-09-02');
      expect(latest?.totalCost.amountMinor, 7420);
    },
  );

  test('a vehicle with no fill-ups has no latest one', () async {
    expect(await fillUps.watchLatestForVehicle(_vehicleId).first, isNull);
  });

  test(
    'a soft-deleted newest fill-up hands the row back to the one before',
    () async {
      await fillUps.save(fillUp('A', '2026-09-02', 7420));
      await fillUps.save(fillUp('B', '2026-08-01', 5130));
      // Raw, because a fill-up is soft-deleted through the vehicle cascade and
      // this test is about the query's WHERE, not about that path.
      await db.customStatement(
        'UPDATE fill_ups SET deleted_at_utc_ms = 2000 WHERE occurred_on = ?;',
        ['2026-09-02'],
      );

      final latest = await fillUps.watchLatestForVehicle(_vehicleId).first;

      expect(latest?.occurredOn, '2026-08-01');
    },
  );
}
