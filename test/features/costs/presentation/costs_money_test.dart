// Tab 3's money formatter, and the currency it was rounding.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/presentation/costs_screen.dart';

void main() {
  test('a three-decimal currency keeps its minor part', () {
    // `% 100 == 0` was true for 12,500 fils — 12.5 IQD, not a whole number —
    // so `wholeOnly` forced `decimalDigits: 0` and the headline printed 13.
    // Six currencies have three decimals, and this app ships `ckb` and `ar`,
    // so IQD is not a hypothetical.
    final iqd = Currency.tryParse('IQD')!;
    expect(iqd.exponent, 3);

    // `en-GB` so the digits are LATIN and the assertion can see them. In
    // `ar-IQ` the same figure renders as `١٢٫٥٠٠`, and a `contains('13')`
    // check against Eastern Arabic-Indic digits passes whatever the code
    // does — which is how the first version of this test survived the
    // mutation it exists to catch.
    final rendered = costsMoney('en-GB', Money(12_500, iqd), wholeOnly: true);

    expect(rendered, contains('12.500'));
    expect(rendered, isNot(contains('13')));
  });

  test('a whole three-decimal amount still drops its zeros', () {
    // The point of `wholeOnly` survives: 12,000 fils IS 12 IQD.
    final iqd = Currency.tryParse('IQD')!;
    final rendered = costsMoney('en-GB', Money(12_000, iqd), wholeOnly: true);

    expect(rendered, contains('12'));
    expect(rendered, isNot(contains('12.000')));
  });

  test('a two-decimal currency is unchanged', () {
    final eur = Currency.tryParse('EUR')!;
    expect(
      costsMoney('en-GB', Money(20_000, eur), wholeOnly: true),
      isNot(contains('.00')),
    );
    expect(
      costsMoney('en-GB', Money(20_050, eur), wholeOnly: true),
      contains('.50'),
    );
  });
}
