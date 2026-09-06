// Reading a typed amount into minor units, exactly.
//
// The whole point of this file is the half-way case. `double.parse('8500.005')
// * 100` is 850000.49999999994, so the rounding that looks correct on paper
// takes half a cent off the user's number — and it does it for every amount
// ending .005, .025, .045, .065 and .085, which is a fifth of all three-decimal
// inputs a fuel price can have.
@TestOn('vm')
library;

import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:test/test.dart';

final Currency _eur = Currency.tryParse('EUR')!;
final Currency _jpy = Currency.tryParse('JPY')!;
final Currency _kwd = Currency.tryParse('KWD')!;

void main() {
  test('a plain amount is its minor units', () {
    expect(minorUnitsFrom('8500.50', _eur), 850050);
    expect(minorUnitsFrom('0', _eur), 0);
    expect(minorUnitsFrom('0.01', _eur), 1);
    expect(minorUnitsFrom('12', _eur), 1200);
  });

  test('a half unit rounds away from zero, in both directions', () {
    // The case a double cannot do. Each of these is exactly .5 of a minor
    // unit, and every one of them rounds DOWN through a binary double.
    expect(minorUnitsFrom('8500.005', _eur), 850001);
    expect(minorUnitsFrom('0.005', _eur), 1);
    expect(minorUnitsFrom('0.025', _eur), 3);
    expect(minorUnitsFrom('0.045', _eur), 5);
    expect(minorUnitsFrom('0.065', _eur), 7);
    expect(minorUnitsFrom('0.085', _eur), 9);
    expect(minorUnitsFrom('-0.005', _eur), -1);
  });

  test('extra decimals round, missing ones pad', () {
    expect(minorUnitsFrom('1.004', _eur), 100);
    expect(minorUnitsFrom('1.006', _eur), 101);
    expect(minorUnitsFrom('1.9999', _eur), 200);
    expect(minorUnitsFrom('1.5', _eur), 150);
    expect(minorUnitsFrom('.5', _eur), 50);
  });

  test("the exponent is the currency's, not two", () {
    // JPY has no minor unit and KWD has three. A hard-coded 100 stores a
    // hundred times too much yen and a tenth of a dinar.
    expect(minorUnitsFrom('8500', _jpy), 8500);
    expect(minorUnitsFrom('8500.5', _jpy), 8501);
    expect(minorUnitsFrom('8500.4', _jpy), 8500);
    expect(minorUnitsFrom('8.5005', _kwd), 8501);
    expect(minorUnitsFrom('8.5004', _kwd), 8500);
  });

  test('anything that is not a canonical number is refused', () {
    for (final text in ['', '-', '1,5', '1.2.3', ' 1', '+1', 'twelve', '1e3']) {
      expect(minorUnitsFrom(text, _eur), isNull, reason: text);
    }
  });

  test('a big amount stays exact', () {
    // 2^53 minor units is where a double stops counting by ones. An integer
    // path has no such edge, and an eight-year-old import can carry any number
    // the schema allows. Assembled rather than written as a literal: the
    // analyzer refuses one this size, because it is not exact under
    // dart2js — which is itself the point being made.
    final exact = int.parse('12345678901234567');
    expect(minorUnitsFrom('123456789012345.67', _eur), exact);
  });

  test('a value that cannot be rounded without wrapping is refused', () {
    // `int.tryParse` refuses anything past the 64-bit range, but a magnitude
    // sitting exactly ON the maximum wraps to the minimum when the half-up
    // adds one — a large negative amount for a large positive number. The one
    // caller today rejects negatives; the next one might not.
    expect(minorUnitsFrom('92233720368547758.075', _eur), isNull);
    expect(minorUnitsFrom('92233720368547758.07', _eur), isNotNull);
  });

  group('scaleByPowerOfTen — the arithmetic without the currency', () {
    test('scales by string at any number of places', () {
      expect(scaleByPowerOfTen('8500.50', 2), 850050);
      expect(scaleByPowerOfTen('8.7', 3), 8700);
      expect(scaleByPowerOfTen('12', 0), 12);
      expect(scaleByPowerOfTen('1.2345', 3), 1235);
    });

    test('the half-way cases a double loses, at each exponent', () {
      // 8500.005 * 100 is 850000.49999999994 as a double, and rounds DOWN.
      expect(scaleByPowerOfTen('8500.005', 2), 850001);
      expect(scaleByPowerOfTen('-8500.005', 2), -850001);
      // 1.0005 * 1000 is 1000.4999999999999 as a double.
      expect(scaleByPowerOfTen('1.0005', 3), 1001);
      expect(scaleByPowerOfTen('0.045', 2), 5);
      expect(scaleByPowerOfTen('0.085', 2), 9);
    });

    test('minorUnitsFrom is this function at the currency exponent', () {
      for (final amount in ['8500.005', '0.045', '12', '-0.085', '1.4999']) {
        expect(minorUnitsFrom(amount, _eur), scaleByPowerOfTen(amount, 2));
        expect(minorUnitsFrom(amount, _jpy), scaleByPowerOfTen(amount, 0));
        expect(minorUnitsFrom(amount, _kwd), scaleByPowerOfTen(amount, 3));
      }
    });

    test('refuses what is not a canonical decimal', () {
      expect(scaleByPowerOfTen('', 2), isNull);
      expect(scaleByPowerOfTen('1,5', 2), isNull);
      expect(scaleByPowerOfTen('1.2.3', 2), isNull);
    });
  });
}
