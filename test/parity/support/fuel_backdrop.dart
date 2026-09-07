/// The REAL `costs.fuel`, over fills the app does the arithmetic on.
///
/// SPEC.md §12. The artboard draws 6.7 L/100 km averaged over 34 full tanks,
/// a twelve-point chart, a best of 5.8 on 12 June and a worst of 8.1 on
/// 3 February — and every one of those is a DERIVED figure. §2 forbids storing
/// one, so the fixture stores fills and lets `FuelInsights.forFills` produce
/// the numbers, exactly as the screen does on a real phone.
///
/// A staged `FuelInsights` would have been shorter and would have proved
/// nothing: the capture would photograph the numbers this file typed rather
/// than the numbers the app computes, which is the one thing a parity shot of
/// a chart is for.
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/fuel/application/fuel_notifier.dart';
import 'package:odova/features/fuel/presentation/fuel_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import 'settings_backdrop.dart';
import 'vehicles_backdrop.dart';

/// The twelve consumption figures the chart plots, oldest first.
///
/// Read off `costs.fuel-light-ltr.png`: the line starts near 6.9, peaks at 8.0,
/// dips to the marked best and ends at 6.4. The best and worst MARKS are not
/// in this window — the artboard's legend names 5.8 on 12 June and 8.1 on
/// 3 February, both from the wider 34-tank history — so the fixture carries
/// both windows and the screen decides which is which.
const List<double> kChartConsumption = [
  6.9,
  7.4,
  6.5,
  6.1,
  7.0,
  8.0,
  6.8,
  6.3,
  5.8,
  7.1,
  6.6,
  6.4,
];

/// The 22 older tanks that make the average 34 tanks rather than 12.
///
/// Flat at the average on purpose: they exist to make the COUNT right — "34
/// full tanks" is on the artboard — without moving a figure the chart draws.
const List<double> kOlderConsumption = [
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  6.7,
  8.1,
];

/// 500 km between fills, so a consumption figure is litres / 5.
///
/// A round segment length keeps the fixture readable: 6.9 L/100 km over 500 km
/// is 34.5 L, and a reader can check the arithmetic in their head rather than
/// trusting a generator.
const int kSegmentMetres = 500000;

/// The fills the artboard's history contains, oldest first.
///
/// One reading per fill and a cumulative odometer that only ever rises, because
/// `buildFuelSegments` discards a segment it cannot trust — §2's "a broken fuel
/// segment is discarded rather than averaged" — and a fixture that broke the
/// chain would draw a chart with holes in it and no error anywhere.
List<InsightFill> artboardFills() {
  final values = [...kOlderConsumption, ...kChartConsumption];
  final fills = <InsightFill>[];

  // The chain starts one segment BEFORE the first plotted point: consumption is
  // measured between two fills, so N points need N+1 fills.
  var cumulative = 92000000;
  var day = CivilDate.tryParse('2025-01-06')!;

  fills.add(_fill(0, day, cumulative, 40));

  for (final (i, value) in values.indexed) {
    cumulative += kSegmentMetres;
    day = day.addDays(14);
    fills.add(_fill(i + 1, day, cumulative, value * kSegmentMetres / 100000));
  }
  return fills;
}

InsightFill _fill(int i, CivilDate on, int cumulativeM, double litres) => (
  id: 'fil_${i.toString().padLeft(26, '0')}',
  occurredOn: on.toString(),
  createdAtUtcMs: 1000 + i,
  fuelKind: 'diesel',
  cumulativeM: cumulativeM,
  quantity: LiquidVolume(Volume((litres * 1000).round())),
  isFullTank: true,
  chainBroken: false,
  tankCapacityMl: null,
  // €1.734 a litre, which is the artboard's "last per L". Rounded to the cent
  // it stores, because §2 keeps money in minor units and a float here would
  // put a third of a cent into every total.
  cost: Money((litres * 173.4).round(), Currency.tryParse('EUR')!),
);

/// A repository that hands over the artboard's history.
class _ArtboardFuel implements FuelRepository {
  @override
  Future<List<InsightFill>> read(String vehicleId) async => artboardFills();
}

/// `costs.fuel` over the artboard's fills, ready to be a capture's `child`.
Widget fuelBackdrop({required bool rtl, required Locale locale}) =>
    ProviderScope(
      overrides: <Override>[
        fuelRepositoryProvider.overrideWithValue(_ArtboardFuel()),
        settingsProvider.overrideWith(
          (ref) => Stream.value(settingsFixture(language: locale.languageCode)),
        ),
        vehiclesProvider.overrideWith(
          (ref) => Stream.value(artboardGarage(rtl: rtl, includeSold: false)),
        ),
        activeVehicleIdProvider.overrideWithValue(artboardGolfId),
        clockProvider.overrideWithValue(Clock.fixed(kSettingsCaptureDay)),
        deviceLocalesProvider.overrideWithValue([
          Locale(
            locale.languageCode,
            locale.languageCode == 'en' ? 'GB' : 'DE',
          ),
        ]),
      ],
      child: const FuelScreen(),
    );
