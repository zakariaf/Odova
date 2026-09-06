// SPEC.md §12's `costs.fuel` numbers.
//
// Two rules decide most of this file.
//
// EVERY AVERAGE IS TOTAL OVER TOTAL. A mean of per-segment figures weights a
// 40 km tank the same as a 900 km one, and the error runs several percent high
// — on the screen a user opens to decide whether the car got thirstier.
//
// A SEGMENT WHOSE FILLS MIX CURRENCIES CONTRIBUTES VOLUME AND DISTANCE BUT NO
// MONEY. Dividing euros by litres bought in pounds is the arithmetic §12
// forbids outright, and the exclusion belongs in the core so a second screen
// cannot forget it.
@TestOn('vm')
library;

import 'package:odova/core/fuel/fuel_insights.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

InsightFill fill(
  String id, {
  required int km,
  required int litres,
  required int costMinor,
  Currency? currency,
  String occurredOn = '2026-01-01',
  bool full = true,
}) => (
  id: id,
  occurredOn: occurredOn,
  createdAtUtcMs: 0,
  fuelKind: 'diesel',
  cumulativeM: km * 1000,
  quantity: LiquidVolume(Volume(litres * 1000)),
  isFullTank: full,
  chainBroken: false,
  tankCapacityMl: 60000,
  cost: Money(costMinor, currency ?? eur),
);

void main() {
  group('total over total, never a mean of means', () {
    // A 40 km tank and a 900 km one. Both burn a plausible amount, but the
    // short one is far thirstier per kilometre — averaging the two FIGURES
    // weights it equally with the long one and reports a car that is worse
    // than it is.
    final fills = [
      fill('a', km: 0, litres: 40, costMinor: 6000),
      // 40 km on 8 L = 20 L/100 km.
      fill('b', km: 40, litres: 8, costMinor: 1200),
      // 900 km on 54 L = 6 L/100 km.
      fill('c', km: 940, litres: 54, costMinor: 8100),
    ];

    test('averageConsumption weights by distance, not by segment', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      // Total: 62 L over 940 km = 6.60 L/100 km.
      // Mean of means: (20 + 6) / 2 = 13.0 — nearly DOUBLE, and the number a
      // naive implementation prints.
      expect(insights.averageLitresPer100Km, closeTo(6.6, 0.05));
      expect(
        insights.averageLitresPer100Km,
        isNot(closeTo(13.0, 0.5)),
        reason: 'the mean of means is 13.0 and is wrong',
      );
    });

    test('avgPricePaid is total cost over total quantity', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      // 15,300 minor over 102 L across all three fills = 150 minor per litre.
      expect(insights.averageUnitPriceMinor, closeTo(150, 0.5));
    });
  });

  group('the exact fills a segment is built from', () {
    // "Those AFTER the opening fill, up to and including the closing one."
    // Off by one here is the most common bug in this category — including the
    // opening fill's own volume double-counts a tank that was burned before
    // the segment began.
    final fills = [
      fill('open', km: 0, litres: 40, costMinor: 6000),
      fill('mid', km: 300, litres: 20, costMinor: 3000),
      fill('close', km: 600, litres: 25, costMinor: 3750),
    ];

    test('names them, so an off-by-one is legible', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      expect(
        insights.costedFillIds,
        {'mid', 'close'},
        reason: 'not `open` — its fuel belongs to the segment before it',
      );
    });

    test('and the per-distance figure uses exactly that cost', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      // 6,750 minor over 600 km.
      expect(insights.costPerKmMinor, closeTo(6750 / 600, 0.01));
    });
  });

  group('mixed currencies', () {
    final fills = [
      fill('a', km: 0, litres: 40, costMinor: 6000),
      fill('b', km: 500, litres: 30, costMinor: 4500),
      // A tank bought abroad.
      fill('c', km: 1000, litres: 30, costMinor: 3800, currency: gbp),
    ];

    test('the mixed segment contributes volume and distance but no money', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      // Both segments count for consumption: 60 L over 1,000 km.
      expect(insights.averageLitresPer100Km, closeTo(6.0, 0.05));
      // Only the euro one counts for money.
      expect(insights.costedFillIds, {'b'});
    });

    test('and it is COUNTED, so the screen can say why a figure is thin', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      expect(insights.mixedCurrencySegments, 1);
    });

    test('a single-currency history counts none', () {
      final insights = FuelInsights.forFills([
        fill('a', km: 0, litres: 40, costMinor: 6000),
        fill('b', km: 500, litres: 30, costMinor: 4500),
      ], currency: eur);

      expect(insights.mixedCurrencySegments, 0);
    });
  });

  group('best, worst and last', () {
    final fills = [
      fill('a', km: 0, litres: 40, costMinor: 6000),
      fill('b', km: 500, litres: 25, costMinor: 3750, occurredOn: '2026-02-01'),
      fill(
        'c',
        km: 1000,
        litres: 40,
        costMinor: 6000,
        occurredOn: '2026-03-01',
      ),
      fill(
        'd',
        km: 1500,
        litres: 30,
        costMinor: 4500,
        occurredOn: '2026-04-01',
      ),
    ];

    test('best and worst carry the CLOSING fill date', () {
      // The date a user recognises is the one they were at the pump — the
      // fill that ended the tank, not the one that started it.
      final insights = FuelInsights.forFills(fills, currency: eur);

      expect(insights.bestOccurredOn, '2026-02-01');
      expect(insights.worstOccurredOn, '2026-03-01');
    });

    test('last is the NEWEST segment, not the best one', () {
      final insights = FuelInsights.forFills(fills, currency: eur);

      expect(insights.lastLitresPer100Km, closeTo(6.0, 0.05));
    });
  });

  group('per fuel kind', () {
    test('two kinds are never merged into one average', () {
      // §12: a bi-fuel LPG car has TWO averages. Merging them produces a
      // figure for a fuel the car does not burn.
      final petrol = [
        fill('p1', km: 0, litres: 40, costMinor: 6000),
        fill('p2', km: 500, litres: 30, costMinor: 4500),
      ];
      final lpg = [
        for (final f in [
          fill('l1', km: 0, litres: 60, costMinor: 4000),
          fill('l2', km: 400, litres: 48, costMinor: 3200),
        ])
          (
            id: f.id,
            occurredOn: f.occurredOn,
            createdAtUtcMs: f.createdAtUtcMs,
            fuelKind: 'lpg',
            cumulativeM: f.cumulativeM,
            quantity: f.quantity,
            isFullTank: f.isFullTank,
            chainBroken: f.chainBroken,
            tankCapacityMl: f.tankCapacityMl,
            cost: f.cost,
          ),
      ];

      final byKind = FuelInsights.byFuelKind(
        [...petrol, ...lpg],
        currency: eur,
      );

      expect(byKind.keys.toSet(), {'diesel', 'lpg'});
      expect(
        byKind['diesel']!.averageLitresPer100Km,
        isNot(byKind['lpg']!.averageLitresPer100Km),
      );
    });
  });

  test('an empty history yields no figures rather than zeros', () {
    // Zero L/100 km is a claim: it says the car uses no fuel.
    final insights = FuelInsights.forFills(const [], currency: eur);

    expect(insights.averageLitresPer100Km, isNull);
    expect(insights.costPerKmMinor, isNull);
    expect(insights.costedFillIds, isEmpty);
  });

  test('a single fill has no segment and therefore no average', () {
    // §3: "your first figure arrives at your next full fill."
    final insights = FuelInsights.forFills([
      fill('a', km: 0, litres: 40, costMinor: 6000),
    ], currency: eur);

    expect(insights.averageLitresPer100Km, isNull);
  });
}
