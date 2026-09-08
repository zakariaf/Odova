/// `costs` under the artboard's own data.
///
/// The reference draws a specific vehicle: The Golf, this year so far, €273
/// per month, €0.29 per kilometre, €2,184 over eight months, and three
/// category rows at 59/29/12%. The capture needs exactly those, so this is a
/// fake repository rather than a seeded store — a drift stream never delivers
/// inside a widget test's fake async and the capture would photograph the
/// pre-data frame.
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../features/home/home_fixture.dart';
import 'parity_capture.dart';

/// Tab 3, ready to be a capture's `child`.
Widget costsBackdrop({required bool rtl, required Locale locale}) =>
    ProviderScope(
      overrides: <Override>[
        settingsProvider.overrideWith(
          (ref) => Stream.value(homeSettings(golfId)),
        ),
        vehiclesProvider.overrideWith(
          (ref) => Stream.value([
            homeVehicle(golfId, rtl ? 'گلف' : 'The Golf'),
          ]),
        ),
        costsRepositoryProvider.overrideWithValue(
          const _ArtboardCostsRepository(),
        ),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 9, 2, 12)),
        ),
        deviceLocalesProvider.overrideWithValue(
          artboardDeviceLocales(locale),
        ),
      ],
      // The artboard has `This year` selected, not the twelve-month default —
      // so the capture selects it too. Comparing a twelve-month screen with a
      // this-year reference measures the fixture, not the layout.
      child: const _CostsAtThisYear(),
    );

/// The screen with §12's `This year` chip selected, as the artboard has it.
class _CostsAtThisYear extends ConsumerStatefulWidget {
  const _CostsAtThisYear();

  @override
  ConsumerState<_CostsAtThisYear> createState() => _CostsAtThisYearState();
}

class _CostsAtThisYearState extends ConsumerState<_CostsAtThisYear> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so `ensureLoaded` has run and the choice lands on
    // a loaded state rather than racing it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(costsProvider.notifier)
            .choose(
              CostsRangeChoice.thisYear,
              golfId.body,
              today: CivilDate.tryParse('2026-09-02')!,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const CostsScreen();
}

/// The figures the reference draws.
class _ArtboardCostsRepository implements CostsRepository {
  const _ArtboardCostsRepository();

  @override
  Future<CostsInputs> read(
    String vehicleId, {
    required CostRange? range,
  }) async {
    final eur = Currency.tryParse('EUR')!;

    return CostsInputs(
      // 1,290 / 640 / 254 — the reference's 59 / 29 / 12 percent.
      amountsByRow: {
        CostCategoryRow.fuel: [Money(129000, eur)],
        CostCategoryRow.service: [Money(64000, eur)],
        CostCategoryRow.insuranceAndTax: [Money(25400, eur)],
      },
      // 20,000 km over the range, which with 2,184 gives the reference's
      // €0.29 per kilometre.
      readings: const [
        (
          id: 'odo_a',
          occurredOn: '2025-12-31',
          createdAtUtcMs: 1,
          odometer: Distance.fromKm(100000),
        ),
        (
          id: 'odo_b',
          occurredOn: '2026-08-30',
          createdAtUtcMs: 2,
          odometer: Distance.fromKm(107500),
        ),
      ],
      corrections: const [],
      firstRecordOn: CivilDate.tryParse('2018-03-04'),
      thisMonthAmounts: [Money(6400, eur)],
      // The reference draws eight columns, J through A, with a green band on
      // three of them.
      monthlyPoints: [
        for (var m = 1; m <= 8; m++)
          MonthlyCostPoint(
            month: MonthKey(
              calendar: CalmCalendar.gregorian,
              year: 2026,
              month: m,
            ),
            amounts: {
              CostCategoryRow.fuel: Money(14000 + (m % 3) * 1500, eur),
              CostCategoryRow.service: Money(
                m == 3 || m == 7 || m == 8 ? 9000 : 0,
                eur,
              ),
              CostCategoryRow.insuranceAndTax: Money(2000, eur),
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
