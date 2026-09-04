// Rounding, half away from zero, once.
//
// SPEC.md §3 Display conversion and rounding.
import 'package:odova/core/rounding/rounding.dart';
import 'package:test/test.dart';

double _pow10(int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

void main() {
  group('half away from zero, never half-even', () {
    test('the four cases SPEC.md names', () {
      // Half-even is the better rule for accumulating statistics and it looks
      // BROKEN to somebody checking against their phone calculator: 2.5 would
      // round to 2, and the user concludes the app cannot add up.
      expect(roundHalfAwayFromZero(2.5), 3.0);
      expect(roundHalfAwayFromZero(-2.5), -3.0);
      expect(roundHalfAwayFromZero(0.05, decimals: 1), 0.1);
      expect(roundHalfAwayFromZero(-0.05, decimals: 1), -0.1);
    });

    test('half-even would give a different answer, and that is the point', () {
      // 0.5, 1.5, 2.5, 3.5 under half-even are 0, 2, 2, 4. Under this rule
      // they are 1, 2, 3, 4 — which is what a calculator shows.
      expect(
        [0.5, 1.5, 2.5, 3.5].map(roundHalfAwayFromZero),
        [1.0, 2.0, 3.0, 4.0],
      );
    });

    test('ordinary values are unsurprising', () {
      expect(roundHalfAwayFromZero(6.44, decimals: 1), 6.4);
      expect(roundHalfAwayFromZero(6.46, decimals: 1), 6.5);
      expect(roundHalfAwayFromZero(1234.5678, decimals: 3), 1234.568);
      expect(roundHalfAwayFromZero(0), 0.0);
    });

    test('a non-finite value is refused, not rounded', () {
      // Consumption over a zero distance is infinite, and an Infinity that
      // silently rounds to some large number is a figure on a screen.
      expect(() => roundHalfAwayFromZero(double.nan), throwsArgumentError);
      expect(() => roundHalfAwayFromZero(double.infinity), throwsArgumentError);
      expect(() => roundHalfAwayFromZero(1, decimals: -1), throwsArgumentError);
    });
  });

  group('nothing rounds a rounded value', () {
    test('one rounding and two give different answers', () {
      // 6.449 to one decimal is 6.4. Rounding to two first gives 6.45, and
      // rounding THAT gives 6.5. The second is wrong, and the only defence is
      // rounding once from the canonical value.
      const canonical = 6.449;
      expect(roundHalfAwayFromZero(canonical, decimals: 1), 6.4);

      final doubleRounded = roundHalfAwayFromZero(
        roundHalfAwayFromZero(canonical, decimals: 2),
        decimals: 1,
      );
      expect(doubleRounded, 6.5);
      expect(
        doubleRounded,
        isNot(roundHalfAwayFromZero(canonical, decimals: 1)),
        reason: 'the wrong implementation must fail loudly, not quietly',
      );
    });
  });

  group('the decimals table, one case per row of SPEC.md §3', () {
    test('odometer readings are whole', () {
      // The table entry is what is asserted; the rounding call takes the
      // default, because passing an explicit 0 is what the analyzer objects to
      // and the point of the table is naming the ROW, not the number.
      expect(Decimals.odometer, 0);
      expect(roundHalfAwayFromZero(186512.7), 186513.0);
    });

    test('a segment distance rounds by its own magnitude', () {
      // The rule is on the VALUE, not the field: 96 km shows a tenth because a
      // tenth is the difference between two short trips, and 1,240 km does not.
      expect(Decimals.forSegmentDistance(1240), 0);
      expect(Decimals.forSegmentDistance(96.4), 1);
      expect(Decimals.forSegmentDistance(-96.4), 1, reason: 'on magnitude');
      expect(Decimals.forSegmentDistance(100), 0, reason: 'the boundary');
    });

    test('volume and energy are two', () {
      expect(Decimals.volume, 2);
      expect(Decimals.energy, 2);
      expect(roundHalfAwayFromZero(45.204, decimals: Decimals.volume), 45.2);
    });

    test('consumption is one', () {
      expect(Decimals.consumption, 1);
      expect(
        roundHalfAwayFromZero(6.4375, decimals: Decimals.consumption),
        6.4,
      );
    });

    test('a unit price is THREE, not two', () {
      // Fuel is priced to a tenth of a cent. Two decimals loses the difference
      // between two stations, which is the number the user is comparing.
      expect(Decimals.unitPrice, 3);
      expect(
        roundHalfAwayFromZero(1.7365, decimals: Decimals.unitPrice),
        1.737,
      );
    });

    test('a cost per distance is three, and 0.089 must not become 0.09', () {
      // A 1% error in a figure people compare between cars.
      expect(Decimals.costPerDistance, 3);
      expect(
        roundHalfAwayFromZero(0.0894, decimals: Decimals.costPerDistance),
        0.089,
      );
      expect(
        roundHalfAwayFromZero(0.0894, decimals: 2),
        0.09,
        reason: 'which is what two decimals would have done',
      );
    });

    test('a percentage is whole', () {
      expect(Decimals.percentage, 0);
      expect(roundHalfAwayFromZero(17.5), 18.0);
    });
  });
  group('quantiseForGolden is not the display rule', () {
    test('they disagree at an exact decimal tie', () {
      // Pinned, because the two look interchangeable and are not. A reviewer
      // reasonably proposed collapsing them; swapping one for the other
      // silently rewrites every committed vector, and a golden file edited by
      // a refactor is worse than no golden file — it carries authority.
      for (final tie in [0.1234565, 1.0000015, 2.0000025, 0.0000005]) {
        expect(
          quantiseForGolden(tie),
          isNot(roundHalfAwayFromZero(tie, decimals: 6)),
          reason: '$tie',
        );
      }
    });

    test('and agree everywhere else, which is why the trap exists', () {
      // 200,000 seeded values across seven magnitudes: they agree on all but
      // the ties. A test written against ordinary values would find them
      // identical and conclude they are the same function.
      var state = 20260904;
      int next() => state = (state * 1103515245 + 12345) & 0x7FFFFFFF;

      var disagreements = 0;
      for (var i = 0; i < 200000; i++) {
        final value = (next() / 0x7FFFFFFF - 0.5) * _pow10(next() % 7);
        if (quantiseForGolden(value) !=
            roundHalfAwayFromZero(value, decimals: 6)) {
          disagreements++;
        }
      }

      expect(
        disagreements,
        lessThan(10),
        reason: 'they agree on ordinary values; the difference is at ties',
      );
    });

    test('null passes through, because a refusal is not a zero', () {
      expect(quantiseForGolden(null), isNull);
    });
  });
}
