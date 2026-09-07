/// A `CostsRepository` with generated amounts and no database.
///
/// §12's tab 3 is read-only and every figure on it is a pure function of the
/// record tables, so a fake here is a fixture rather than a stand-in for
/// behaviour — the arithmetic lives in `lib/core/costs/` and is tested there.
/// What this has to be able to produce is §12's states: first run, one record,
/// a range with no data, and two currencies.
library;

import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';

CivilDate _day(String t) => CivilDate.tryParse(t)!;

/// A repository over a fixed set of amounts.
class FakeCostsRepository implements CostsRepository {
  /// Creates a fake.
  FakeCostsRepository({
    this.fuelMinor = 129000,
    this.serviceMinor = 64000,
    this.insuranceMinor = 25400,
    this.secondCurrency,
    this.readings = const [],
    this.firstRecordOn = '2018-03-04',
  });

  /// Fuel, in minor units of EUR.
  final int fuelMinor;

  /// Service and repairs.
  final int serviceMinor;

  /// Insurance and tax.
  final int insuranceMinor;

  /// An amount in a SECOND currency, for §12's mixed-currency case.
  final Money? secondCurrency;

  /// The vehicle's entered readings.
  final List<ReadingPoint> readings;

  /// When its first record was.
  final String? firstRecordOn;

  /// How many times a range was asked for.
  int reads = 0;

  @override
  Future<CostsInputs> read(
    String vehicleId, {
    required CostRange? range,
  }) async {
    reads++;
    final eur = Currency.tryParse('EUR')!;

    return CostsInputs(
      amountsByRow: {
        if (fuelMinor > 0)
          CostCategoryRow.fuel: [
            Money(fuelMinor, eur),
            ?secondCurrency,
          ],
        if (serviceMinor > 0)
          CostCategoryRow.service: [Money(serviceMinor, eur)],
        if (insuranceMinor > 0)
          CostCategoryRow.insuranceAndTax: [Money(insuranceMinor, eur)],
      },
      readings: readings.isNotEmpty
          ? readings
          : [
              (
                id: 'odo_a',
                occurredOn: '2025-09-01',
                createdAtUtcMs: 1,
                odometer: const Distance.fromKm(100000),
              ),
              (
                id: 'odo_b',
                occurredOn: '2026-08-30',
                createdAtUtcMs: 2,
                odometer: const Distance.fromKm(120000),
              ),
            ],
      corrections: const [],
      firstRecordOn: firstRecordOn == null ? null : _day(firstRecordOn!),
      thisMonthAmounts: [Money(6400, eur)],
      // Eight months, so §12's volume table selects columns rather than rows.
      monthlyPoints: [
        for (var m = 1; m <= 8; m++)
          MonthlyCostPoint(
            month: MonthKey(
              calendar: CalmCalendar.gregorian,
              year: 2026,
              month: m,
            ),
            amounts: {
              CostCategoryRow.fuel: Money(12000 + m * 400, eur),
              CostCategoryRow.service: Money(m.isEven ? 6000 : 0, eur),
            },
          ),
      ],
    );
  }

  @override
  Future<List<HouseholdVehicle>> readHousehold(
    List<HouseholdVehicleFacts> vehicles, {
    required CivilDate today,
    required CostsRangeChoice choice,
  }) async => [
    for (final (i, v) in vehicles.indexed)
      HouseholdVehicle(
        vehicleId: v.id,
        name: v.name,
        // Descending, so the sort in `buildHousehold` has something to do.
        perMonth: Money(20000 - i * 5000, Currency.tryParse('EUR')!),
        isArchived: v.isArchived,
        isSold: v.isSold,
      ),
  ];
}
