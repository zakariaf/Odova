// Every column lands in the right field of the right value object.
//
// EPIC-06 swapped the domain models from canonical integers to `Distance`,
// `Money` and `FuelQuantity`, and `row_mappers.dart` became the only layer
// that knows both shapes. That makes it the one place where a crossed wire is
// silent: a fill-up read back with the wrong currency still has a plausible
// number in it, and a service history priced in the wrong currency is worth
// the wrong amount for as long as the app is installed.
//
// The hole this file closes was real and was found by mutation, not by
// reading: replacing `moneyOf(row.totalCostMinor, row.currency)` with
// `moneyOf(row.totalCostMinor, 'USD')` passed all 2,304 tests. Every fixture
// in the suite used EUR, so a hardcoded currency and the stored one were the
// same value everywhere anybody looked.
//
// So every field here holds a DIFFERENT value from every other field of its
// type, and no currency is the fixture default. A mapper that reads the wrong
// column, or invents a constant, cannot produce these numbers.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';

import '../../../support/values.dart';

void main() {
  group('a fill-up', () {
    FillUpRow row({
      int? quantityMl,
      int? quantityG,
      int? energyWh,
      String fuelKind = 'diesel',
      int totalCostMinor = 784500,
      String currency = 'JPY',
    }) => FillUpRow(
      id: 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
      vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
      occurredOn: '2026-09-03',
      odometerM: 186512000,
      odometerUnit: 'km',
      fuelKind: fuelKind,
      quantityMl: quantityMl,
      quantityG: quantityG,
      energyWh: energyWh,
      quantityUnit: 'l',
      totalCostMinor: totalCostMinor,
      currency: currency,
      isFullTank: true,
      chainBroken: false,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    test('is priced in the currency the row stored, not a default', () {
      // JPY, and not because JPY is special: because it is not EUR, which is
      // what every other fixture in the suite happens to use.
      expect(fillUpFromRow(row()).totalCost, money(784500, 'JPY'));
      expect(
        fillUpFromRow(row(currency: 'KWD')).totalCost,
        money(784500, 'KWD'),
      );
    });

    test('the odometer column is metres, and only the odometer column', () {
      // 186,512,000 appears nowhere else in the row, so a mapper reading
      // `quantity_ml` into `odometer` cannot produce it.
      expect(fillUpFromRow(row()).odometer, const Distance(186512000));
    });

    group('the three quantity columns become one sealed value', () {
      test('millilitres become a liquid volume', () {
        final quantity = fillUpFromRow(row(quantityMl: 45200)).quantity;
        expect(quantity, const LiquidVolume(Volume(45200)));
      });

      test('grams become a gas mass', () {
        final quantity = fillUpFromRow(
          row(quantityG: 4520, fuelKind: 'cng'),
        ).quantity;
        expect(quantity, const GasMass(Mass(4520)));
      });

      test('watt-hours become an energy', () {
        final quantity = fillUpFromRow(
          row(energyWh: 52000, fuelKind: 'electric'),
        ).quantity;
        expect(quantity, const ElectricEnergy(Energy(52000)));
      });

      test('all three null is null, never a zero of some unit', () {
        // The schema forbids it; an unmigrated row could still produce it, and
        // SPEC.md §2 says the app never guesses in a way that looks like fact.
        // A zero litre fill-up is a claim; null is the truth.
        expect(fillUpFromRow(row()).quantity, isNull);
      });
    });

    test('the writers are the exact inverse of the reader', () {
      // These three run in the other direction, and the round trip is what
      // proves a liquid does not come back as a mass. A `FuelQuantity` case
      // with no writer would land here as three nulls.
      for (final quantity in const <FuelQuantity>[
        LiquidVolume(Volume(45200)),
        GasMass(Mass(4520)),
        ElectricEnergy(Energy(52000)),
      ]) {
        expect(
          fuelQuantityOf(
            millilitres: millilitresColumn(quantity),
            grams: gramsColumn(quantity),
            wattHours: wattHoursColumn(quantity),
          ),
          quantity,
          reason: '$quantity did not survive the split and rejoin',
        );
        // Exactly one column, which is what the schema's CHECK requires.
        final columns = [
          millilitresColumn(quantity),
          gramsColumn(quantity),
          wattHoursColumn(quantity),
        ];
        expect(
          columns.where((c) => c != null),
          hasLength(1),
          reason: '$quantity',
        );
      }
    });
  });

  group('a vehicle', () {
    VehicleRow row({
      int? purchasePriceMinor = 1850000,
      String? purchasePriceCurrency = 'KWD',
      int? soldPriceMinor = 1200000,
      String? soldPriceCurrency = 'JPY',
      String? currency = 'ISK',
    }) => VehicleRow(
      id: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
      name: 'The Golf',
      vehicleType: 'car',
      isBusiness: false,
      fuelKindDefault: 'diesel',
      status: 'active',
      sortOrder: 0,
      notificationsMuted: false,
      purchaseOdometerM: 120000000,
      purchasePriceMinor: purchasePriceMinor,
      purchasePriceCurrency: purchasePriceCurrency,
      soldPriceMinor: soldPriceMinor,
      soldPriceCurrency: soldPriceCurrency,
      expectedAnnualM: 15000000,
      currency: currency,
      noticeDistanceM: 500000,
      createdAtUtcMs: 1000,
      updatedAtUtcMs: 1000,
    );

    test('keeps its three currencies apart', () {
      // A vehicle carries THREE independent currency columns, and SPEC.md §12
      // says money never mixes. A mapper that read the vehicle's default
      // currency into the purchase price would be invisible on any vehicle
      // whose three agree — which is most of them.
      final vehicle = vehicleFromRow(row());
      expect(vehicle.purchasePrice, money(1850000, 'KWD'));
      expect(vehicle.soldPrice, money(1200000, 'JPY'));
      expect(vehicle.currency, currencyOf('ISK'));
    });

    test('keeps its three distances apart', () {
      final vehicle = vehicleFromRow(row());
      expect(vehicle.purchaseOdometer, const Distance(120000000));
      expect(vehicle.expectedAnnual, const Distance(15000000));
      expect(vehicle.noticeDistance, const Distance(500000));
    });

    test('an amount without its currency is null, not a bare number', () {
      // Half a price is not a price. The pair is read together or not at all.
      expect(
        vehicleFromRow(row(purchasePriceCurrency: null)).purchasePrice,
        isNull,
      );
      expect(vehicleFromRow(row(soldPriceMinor: null)).soldPrice, isNull);
    });

    test(
      'a stored code that is not ISO 4217 throws rather than defaulting',
      () {
        // `length(currency) = 3` is a CHECK, so this row cannot come from this
        // app. Defaulting to two decimals would render a yen amount a hundred
        // times too small and never say so.
        expect(() => currencyOf('EU'), throwsStateError);
        expect(() => currencyOf('euro'), throwsStateError);
      },
    );
  });

  group('an odometer correction', () {
    test('previous and replacement do not swap', () {
      // The offset is `previous - replacement`, so swapping them negates every
      // corrected reading in the history and the arithmetic stays consistent
      // while being backwards.
      final correction = odometerCorrectionFromRow(
        const OdometerCorrectionRow(
          id: 'cor_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          fromReadingId: 'odo_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          previousM: 187412000,
          newM: 12000,
          odometerUnit: 'km',
          reason: 'cluster_replaced',
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      expect(correction.previous, const Distance(187412000));
      expect(correction.replacement, const Distance(12000));
      expect(correction.offset, const Distance(187400000));
    });
  });
}
