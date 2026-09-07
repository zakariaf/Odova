// The real `CostsRepository` and `FuelRepository`, over a real database.
//
// Both providers threw `UnimplementedError` until EPIC-13 task 13.10, so
// `costs` and `costs.fuel` were routes that crashed the moment anyone opened
// them outside a test. Every screen test passed the whole time, against a
// fake. This file exists so that cannot happen again: it is the only test in
// the tree that puts the real implementation behind the real interface.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/features/costs/data/costs_source.dart';
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
    await FillUpRepository(db, testIds()).save(
      FillUp(
        id: FillUpId.tryParse('fil_$_body')!,
        vehicleId: _vehicleId,
        occurredOn: '2026-05-10',
        odometer: const Distance.fromKm(187_000),
        odometerUnit: DistanceUnit.km,
        fuelKind: FuelKind.diesel,
        quantity: const LiquidVolume(Volume(42_000)),
        quantityUnit: VolumeUnit.l,
        totalCost: Money(7420, _eur),
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
    await ExpenseRepository(db, testIds()).save(
      Expense(
        id: ExpenseId.tryParse('exp_$_body')!,
        vehicleId: _vehicleId,
        occurredOn: '2026-05-01',
        category: ExpenseCategory.toll,
        amount: Money(1200, _eur),
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );
  });

  tearDown(() => db.close());

  CostsSource source() => CostsSource(
    FillUpRepository(db, testIds()),
    ExpenseRepository(db, testIds()),
    ServiceRepository(db, testIds()),
    OdometerRepository(db),
    TripRepository(db, testIds()),
    CalmCalendar.gregorian,
  );

  test(
    'the fuel row and the tolls row arrive, in their own categories',
    () async {
      final inputs = await source().read(
        _vehicleId.toString(),
        range: CostRange.months(
          6,
          today: CivilDate.tryParse('2026-09-07')!,
        ),
      );

      expect(inputs.amountsByRow[CostCategoryRow.fuel], [Money(7420, _eur)]);
      expect(
        inputs.amountsByRow[CostCategoryRow.parkingAndTolls],
        [Money(1200, _eur)],
      );
      // The earliest record, which is where `All` starts.
      expect(inputs.firstRecordOn, CivilDate.tryParse('2026-05-01'));
      // And the readings the per-distance figure divides by — the fill-up's
      // derived one, which arrived without anybody asking for it.
      expect(inputs.readings, isNotEmpty);
    },
  );

  test('a record outside the range is not counted', () async {
    final inputs = await source().read(
      _vehicleId.toString(),
      // One completed month: August 2026. Both records are in May.
      range: CostRange.months(1, today: CivilDate.tryParse('2026-09-07')!),
    );

    expect(inputs.amountsByRow, isEmpty);
    // But the range still knows when the history starts, so `All` can offer
    // a wider one.
    expect(inputs.firstRecordOn, CivilDate.tryParse('2026-05-01'));
  });

  test(
    'the fuel source reads the CUMULATIVE odometer, not the raw one',
    () async {
      // A cluster swap BEFORE the fill: the dash was replaced at 100,000 km and
      // restarted at zero, so every later raw number is 100,000 short of the
      // truth. Without a correction in the fixture the two readings are equal
      // and the test proves nothing — which is how a `fill.odometer.metres`
      // here would survive review.
      final odometer = OdometerRepository(db);
      final earlier = OdometerReadingId.tryParse('odo_$_body')!;
      await odometer.saveReading(
        OdometerReading(
          id: earlier,
          vehicleId: _vehicleId,
          occurredOn: '2026-01-01',
          odometer: Distance.zero,
          odometerUnit: DistanceUnit.km,
          source: OdometerSource.manual,
          createdAtUtcMs: 500,
          updatedAtUtcMs: 500,
        ),
        vehicleUnit: DistanceUnit.km,
      );
      await odometer.saveCorrection(
        OdometerCorrection(
          id: OdometerCorrectionId.tryParse('cor_$_body')!,
          vehicleId: _vehicleId,
          fromReadingId: earlier,
          previous: const Distance.fromKm(100_000),
          replacement: Distance.zero,
          odometerUnit: DistanceUnit.km,
          reason: OdometerCorrectionReason.clusterReplaced,
          createdAtUtcMs: 500,
          updatedAtUtcMs: 500,
        ),
      );

      final fills = await FuelSource(
        FillUpRepository(db, testIds()),
        odometer,
      ).read(_vehicleId.toString());

      expect(fills, hasLength(1));
      // The RAW number in the `fill_ups` row is 187,000 km. The truth, with the
      // 100,000 km the old cluster covered folded back in, is 287,000.
      expect(fills.single.cumulativeM, 287_000_000);
      expect(fills.single.cost, Money(7420, _eur));
    },
  );

  test(
    'this month is spread by the allocator, like the chart column',
    () async {
      // An annual premium paid this month. The first version of `_thisMonth`
      // filtered by month and took the amount WHOLE, so it read €1,200 while
      // the chart column for the same month showed one twelfth — two numbers on
      // one screen disagreeing, under a caption promising the opposite.
      await ExpenseRepository(db, testIds()).save(
        Expense(
          id: ExpenseId.tryParse('exp_01JQ8ZK3M7F0R6XN2E9TB4HCVE')!,
          vehicleId: _vehicleId,
          occurredOn: '2026-09-01',
          category: ExpenseCategory.insurance,
          amount: Money(120_000, _eur),
          coversFrom: '2026-09-01',
          coversTo: '2027-08-31',
          odometerUnit: DistanceUnit.km,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      final inputs = await source().read(
        _vehicleId.toString(),
        range: CostRange.months(6, today: CivilDate.tryParse('2026-09-07')!),
      );

      final thisMonth = inputs.thisMonthAmounts.fold<int>(
        0,
        (sum, m) => sum + m.amountMinor,
      );
      // Roughly a twelfth of €1,200 — 30 days of a 365-day window — and
      // emphatically not €1,200.
      expect(thisMonth, lessThan(15_000));
      expect(thisMonth, greaterThan(5000));
    },
  );

  test('the headline is on the accrual, like the chart under it', () async {
    // §12 opens by saying costs are accrual and the screen prints a caption
    // under the headline promising it. `_byRow` filtered `occurred_on` and
    // took each amount whole, so a €1,200 premium paid in month 1 of a
    // 12-month range was counted in FULL by the headline and by twelfths in
    // the chart directly beneath — two numbers on one screen disagreeing,
    // under a caption saying they cannot.
    await ExpenseRepository(db, testIds()).save(
      Expense(
        id: ExpenseId.tryParse('exp_01JQ8ZK3M7F0R6XN2E9TB4HCVF')!,
        vehicleId: _vehicleId,
        occurredOn: '2026-09-01',
        category: ExpenseCategory.insurance,
        amount: Money(120_000, _eur),
        coversFrom: '2026-09-01',
        coversTo: '2027-08-31',
        odometerUnit: DistanceUnit.km,
        createdAtUtcMs: 1000,
        updatedAtUtcMs: 1000,
      ),
    );

    final inputs = await source().read(
      _vehicleId.toString(),
      // Three completed months: June, July, August 2026. The policy starts in
      // September, so NONE of it falls in range.
      range: CostRange.months(3, today: CivilDate.tryParse('2026-09-07')!),
    );

    expect(
      inputs.amountsByRow[CostCategoryRow.insuranceAndTax],
      isNull,
      reason: 'a policy that has not started yet costs nothing in range',
    );
  });
}
