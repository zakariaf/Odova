// `FuelSource`, over a real database.
//
// Its provider threw `UnimplementedError` until EPIC-13 task 13.10, so
// `costs.fuel` was a route that crashed on open outside a test while every
// screen test passed against a fake. This is the only test that puts the real
// implementation behind the real interface.
@TestOn('vm')
library;

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
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/features/fuel/data/fuel_source.dart';

import '../../../data/support/test_ids.dart';

const String _body = '01JQ8ZK3M7F0R6XN2E9TB4HCVD';
final VehicleId _vehicleId = VehicleId.tryParse('veh_$_body')!;
final Currency _eur = Currency.tryParse('EUR')!;

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
  });

  tearDown(() => db.close());

  test(
    'a fill with no quantity is skipped, not counted as zero litres',
    () async {
      // `InsightFill.quantity` is non-nullable and every figure on `costs.fuel`
      // divides by it. §10 allows a fill with only a price, so a zero-litre
      // stand-in would put a segment of infinite consumption into the average —
      // worse than a row nobody sees.
      await FillUpRepository(db, testIds()).save(
        FillUp(
          id: FillUpId.tryParse('fil_$_body')!,
          vehicleId: _vehicleId,
          occurredOn: '2026-05-10',
          odometer: const Distance.fromKm(187_000),
          odometerUnit: DistanceUnit.km,
          fuelKind: FuelKind.diesel,
          quantityUnit: VolumeUnit.l,
          totalCost: Money(7420, _eur),
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      final fills = await FuelSource(
        FillUpRepository(db, testIds()),
        OdometerRepository(db),
      ).read(_vehicleId.toString());

      expect(fills, isEmpty);
    },
  );
}
