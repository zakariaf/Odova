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
//
// It originally covered four of the nine mappers, because the other five were
// private methods on the repositories and unreachable from here — including
// `serviceLineFromRow`, which carries the price of a service line. They are all
// in `row_mappers.dart` now and all of them are below.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/models/settings.dart';
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
  group('an expense', () {
    test('keeps its amount with its own currency', () {
      final expense = expenseFromRow(
        const ExpenseRow(
          id: 'exp_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          occurredOn: '2026-02-01',
          category: 'insurance',
          amountMinor: 42000,
          currency: 'ISK',
          odometerM: 187000000,
          odometerUnit: 'mi',
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      expect(expense.amount, money(42000, 'ISK'));
      expect(expense.odometer, const Distance(187000000));
    });
  });

  group('a trip', () {
    test('keeps its three distances apart', () {
      // Start, end and the manual override are three independent columns, and
      // `Trip.distance` prefers the endpoints. A mapper that crossed two of
      // them would produce a plausible trip length.
      final trip = tripFromRow(
        const TripRow(
          id: 'trp_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          purpose: 'business',
          startedOn: '2026-03-01',
          endedOn: '2026-03-05',
          startOdometerM: 187100000,
          endOdometerM: 187900000,
          manualDistanceM: 12345,
          odometerUnit: 'mi',
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      expect(trip.startOdometer, const Distance(187100000));
      expect(trip.endOdometer, const Distance(187900000));
      expect(trip.manualDistance, const Distance(12345));
      expect(
        trip.distance,
        const Distance(800000),
        reason: 'the endpoints win; the manual figure is not 12345 here',
      );
    });
  });

  group('a service line', () {
    test('is priced in the currency the row stored', () {
      // The mapper that was on the untested side of the public/private split,
      // carrying the price of a service line — the number a used-car buyer
      // reads off eight years of history.
      final line = serviceLineFromRow(
        const ServiceLineRow(
          id: 'lin_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          serviceRecordId: 'srv_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          label: 'Oil and filter',
          amountMinor: 89000,
          currency: 'KWD',
        ),
      );

      expect(line.amount, money(89000, 'KWD'));
    });
  });

  group('a service item', () {
    test('keeps its four distances apart', () {
      // Interval, target, baseline and notice window: four metre columns on
      // one row, and the due engine reads all four. Crossing any two produces
      // a due date that is wrong in a way nothing downstream can detect.
      final item = serviceItemFromRow(
        const ServiceItemRow(
          id: 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          vehicleId: 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
          kind: 'oil_and_filter',
          intervalDistanceM: 15000000,
          targetOdometerM: 195000000,
          baselineOdometerM: 180000000,
          noticeDistanceM: 500000,
          isTracked: true,
          isActive: true,
          notify: true,
          priority: 'normal',
          rollover: 'from_actual',
          repeats: true,
          snoozeUntilOdometerM: 191000000,
          snoozeCount: 0,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      expect(item.intervalDistance, const Distance(15000000));
      expect(item.targetOdometer, const Distance(195000000));
      expect(item.baselineOdometer, const Distance(180000000));
      expect(item.noticeDistance, const Distance(500000));
      expect(item.snoozeUntilOdometer, const Distance(191000000));
    });
  });

  group('the settings row', () {
    test('reads its currency and its notice window', () {
      final settings = settingsFromRow(
        const SettingsRow(
          id: AppSettings.id,
          schemaVersion: 1,
          language: 'system',
          calendar: 'gregorian',
          numerals: 'auto',
          firstDayOfWeek: 1,
          theme: 'system',
          currencyDefault: 'KWD',
          currencyDisplay: 'none',
          distanceUnit: 'mi',
          volumeUnit: 'gal_uk',
          consumptionUnit: 'mpg_uk',
          noticeDistanceM: 500000,
          notificationTimeMinutes: 540,
          quietHoursFromMinutes: 1260,
          quietHoursToMinutes: 480,
          weekdaysOnly: false,
          notifyService: true,
          notifyOdometer: true,
          notifyBackup: true,
          onboardingDone: false,
          createdAtUtcMs: 1000,
          updatedAtUtcMs: 1000,
        ),
      );

      expect(settings.currencyDefault, isoCurrency('KWD'));
      expect(settings.noticeDistance, const Distance(500000));
      // The units are a PREFERENCE and not a scale: they come back as read.
      expect(settings.distanceUnit.wire, 'mi');
      expect(settings.consumptionUnit.wire, 'mpg_uk');
    });
  });
}
