// Fuel money, per currency, never blended.
//
// SPEC.md §3 Fuel maths, §3 Currency, §12, §14. The app has no exchange rate,
// so a price per litre that added euros to pounds and divided by litres is a
// number with no meaning that looks like a price — and somebody would compare
// it between two cars.
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_money.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/rounding/rounding.dart';
import 'package:test/test.dart';

import '../../support/values.dart';

FillUpCost fill(
  String id, {
  required int cents,
  required int millilitres,
  Currency? currency,
}) => (
  id: id,
  cost: Money(cents, currency ?? isoCurrency('EUR')),
  quantity: LiquidVolume(Volume(millilitres)),
);

void main() {
  group('unit price', () {
    test('is total over quantity, to three decimals per litre', () {
      // 78.45 EUR for 45.2 L is 1.735 EUR/L.
      final price = unitPrice(fill('a', cents: 7845, millilitres: 45200));
      final perMillilitre = (price as Ok<double, ConsumptionUnavailable>).value;
      final perLitre = perMillilitre * 1000 / 100; // minor -> major, mL -> L

      expect(
        roundHalfAwayFromZero(perLitre, decimals: Decimals.unitPrice),
        1.736,
      );
    });

    test('is DERIVED and stored nowhere', () {
      // SPEC.md §3: the form takes any two of {total, quantity, price} and
      // computes the third; only total and quantity persist. Store all three
      // and they will one day disagree, and then nobody knows which is the
      // receipt. The schema gate for this lives in
      // test/data/db/tables/event_tables_test.dart.
      expect(
        unitPrice(fill('a', cents: 7845, millilitres: 45200)),
        isA<Ok<double, ConsumptionUnavailable>>(),
      );
    });

    test('a zero quantity is Unavailable, never a division', () {
      expect(
        unitPrice(fill('a', cents: 7845, millilitres: 0)),
        isA<Err<double, ConsumptionUnavailable>>(),
      );
    });
  });

  group('average price paid', () {
    test('is total over total, not the mean of the unit prices', () {
      // A 5 L motorway top-up at 2.00 and a 60 L supermarket fill at 1.60.
      // The mean of the two prices is 1.80; the average actually paid is
      // 1.631, which sits near the supermarket because that is where the fuel
      // came from.
      final average = avgPricePaid([
        fill('motorway', cents: 1000, millilitres: 5000),
        fill('supermarket', cents: 9600, millilitres: 60000),
      ]);

      final perLitre = average[isoCurrency('EUR')]! * 1000 / 100;
      expect(roundHalfAwayFromZero(perLitre, decimals: 3), 1.631);
      expect(perLitre, isNot(closeTo(1.8, 0.05)), reason: 'not the mean');
    });

    test('a zero-quantity fill does not poison the average', () {
      // Without the skip it contributes its COST and no quantity, so the
      // average price rises for every other fill in that currency — and an
      // imported row with a missing quantity is exactly how one arrives.
      final average = avgPricePaid([
        fill('good', cents: 9600, millilitres: 60000),
        fill('broken', cents: 5000, millilitres: 0),
      ]);

      final perLitre = average[isoCurrency('EUR')]! * 1000 / 100;
      expect(roundHalfAwayFromZero(perLitre, decimals: 3), 1.6);
    });

    test('returns one figure per currency, never one blended', () {
      final average = avgPricePaid([
        fill('a', cents: 7845, millilitres: 45200),
        fill(
          'b',
          cents: 6000,
          millilitres: 40000,
          currency: isoCurrency('GBP'),
        ),
      ]);

      expect(average.keys.toSet(), {isoCurrency('EUR'), isoCurrency('GBP')});
    });
  });

  group('spend and volume', () {
    test('spend is per currency', () {
      final spend = fuelSpend([
        fill('a', cents: 7845, millilitres: 45200),
        fill('b', cents: 5000, millilitres: 30000),
        fill(
          'c',
          cents: 6000,
          millilitres: 40000,
          currency: isoCurrency('GBP'),
        ),
      ]);

      expect(spend.byCurrency[isoCurrency('EUR')], 12845);
      expect(spend.byCurrency[isoCurrency('GBP')], 6000);
      expect(spend.isMixed, isTrue, reason: 'never one blended figure');
      // A `MoneyTotal` and not a bare map, so the caller gets the two things
      // SPEC.md §12's "one figure or a list" decision actually needs. A map
      // makes the screen re-derive both, and `dominantCurrency` in particular
      // is a rule (most ROWS, ties on the code) rather than a `.first`.
      expect(
        spend.dominantCurrency,
        isoCurrency('EUR'),
        reason: 'two euro rows, one pound',
      );
    });

    test('volume sums the fills', () {
      final volume = fuelVolume([
        fill('a', cents: 0, millilitres: 45200),
        fill('b', cents: 0, millilitres: 30000),
      ]);

      expect(
        ((volume as Ok<FuelQuantity, ConsumptionUnavailable>).value
                as LiquidVolume)
            .volume
            .millilitres,
        75200,
      );
    });

    test('volume over nothing is Unavailable, not zero', () {
      expect(
        fuelVolume(const []),
        isA<Err<FuelQuantity, ConsumptionUnavailable>>(),
      );
    });

    test('volume across two FORMS is Unavailable, not a coerced total', () {
      // This used to sum the canonical integers and rebuild in the FIRST
      // fill's form, so 45.2 L of diesel plus 4,000 g of CNG came back as
      // 49.2 litres — a number with no physical meaning, presented as a fact
      // and indistinguishable from a correct one. It can arise: an importer
      // landing a bi-fuel car's fills under one `fuel_kind` produces exactly
      // this list.
      final mixed = fuelVolume([
        fill('a', cents: 0, millilitres: 45200),
        (
          id: 'b',
          cost: Money(0, isoCurrency('EUR')),
          quantity: const GasMass(Mass(4000)),
        ),
      ]);

      expect(mixed, isA<Err<FuelQuantity, ConsumptionUnavailable>>());
    });
  });

  group('cost per distance', () {
    FuelSegment segment(String to, {required int km}) => FuelSegment(
      fromFillUpId: '${to}_from',
      toFillUpId: to,
      distance: Distance(km * 1000),
      quantity: const LiquidVolume(Volume(45200)),
      partialCount: 0,
    );

    test('uses exactly the fills whose fuel built the segment', () {
      // The fills AFTER the opening one, up to and including the closing one.
      // An open, unmeasured segment at the end contributes neither cost nor
      // distance — charging its fuel against a distance that excludes it makes
      // the figure high by exactly one tank, and it looks entirely plausible.
      final result = fuelCostPerDistance(
        [segment('b', km: 600)],
        {
          'a': fill('a', cents: 7000, millilitres: 40000),
          'b': fill('b', cents: 7845, millilitres: 45200),
          'open': fill('open', cents: 9999, millilitres: 50000),
        },
        {
          'b': ['b'],
        },
      );

      // 78.45 EUR over 600 km.
      final perKm = result.minorPerMetre[isoCurrency('EUR')]! * 1000 / 100;
      expect(roundHalfAwayFromZero(perKm, decimals: 3), 0.131);
      expect(result.excludedSegmentCount, 0);
    });

    test('a segment spanning two currencies is excluded AND counted', () {
      // SPEC.md §14: a tank filled across a border. It still contributed its
      // volume and distance to the CONSUMPTION figure; only the money is
      // unanswerable. Counted rather than silently dropped, because the UI
      // says "1 tank spanned two currencies — no cost per kilometre for it",
      // and a silent drop makes the figure quietly cover less than the user
      // thinks.
      final result = fuelCostPerDistance(
        [segment('b', km: 600), segment('d', km: 500)],
        {
          'b1': fill('b1', cents: 4000, millilitres: 20000),
          'b': fill(
            'b',
            cents: 4000,
            millilitres: 25000,
            currency: isoCurrency('GBP'),
          ),
          'd': fill('d', cents: 7000, millilitres: 40000),
        },
        {
          'b': ['b1', 'b'],
          'd': ['d'],
        },
      );

      expect(result.excludedSegmentCount, 1);
      expect(result.minorPerMetre.keys, [
        isoCurrency('EUR'),
      ], reason: 'only the clean one');
    });

    test('no figure ever blends two currencies', () {
      final result = fuelCostPerDistance(
        [segment('b', km: 600), segment('d', km: 500)],
        {
          'b': fill('b', cents: 7845, millilitres: 45200),
          'd': fill(
            'd',
            cents: 6000,
            millilitres: 40000,
            currency: isoCurrency('GBP'),
          ),
        },
        {
          'b': ['b'],
          'd': ['d'],
        },
      );

      expect(result.minorPerMetre.keys.toSet(), {
        isoCurrency('EUR'),
        isoCurrency('GBP'),
      });
      expect(result.minorPerMetre, hasLength(2));
    });

    test('a segment with no contributing fills is skipped, not divided by', () {
      final result = fuelCostPerDistance(
        [segment('b', km: 600)],
        const {},
        const {},
      );
      expect(result.minorPerMetre, isEmpty);
    });

    test('a segment with only SOME of its costs is excluded, not halved', () {
      // The numerator dropped the fills that had no cost row and the
      // denominator kept the whole segment distance, so a 600 km tank whose
      // middle top-up was saved without a total reported roughly 40% less per
      // kilometre — presented as a fact and entirely plausible.
      //
      // A partial cost is not a smaller cost; it is an unknown one, which is
      // the same argument `moneyOrNull` makes about half a price.
      final result = fuelCostPerDistance(
        [segment('d', km: 600)],
        {
          'b': fill('b', cents: 5000, millilitres: 20000),
          // 'c' contributed fuel and has no cost row.
          'd': fill('d', cents: 4000, millilitres: 25200),
        },
        {
          'd': ['b', 'c', 'd'],
        },
      );

      expect(result.minorPerMetre, isEmpty);
      expect(
        result.excludedSegmentCount,
        1,
        reason: 'SPEC.md §12 has a data-quality row; it needs the count',
      );
    });

    test('a segment with NO costs at all is counted as excluded too', () {
      // It used to `continue` with no counter, so the data-quality row said
      // nothing had been left out while a tank had been.
      final result = fuelCostPerDistance(
        [segment('b', km: 600)],
        const {},
        {
          'b': ['a', 'b'],
        },
      );

      expect(result.minorPerMetre, isEmpty);
      expect(result.excludedSegmentCount, 1);
    });
  });
}
