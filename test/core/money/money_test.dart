// Money: exact, single-currency, never converted.
//
// SPEC.md §3 Canonical units (Money), §3 Currency, §12 Ground rules.
import 'package:test/test.dart';

import '../../support/values.dart';

void main() {
  group('the exponent comes from ISO 4217, never a hardcoded 100', () {
    test('four currencies with three different exponents', () {
      // A hardcoded 100 is a 100x error on the yen, which has no subunit, and
      // a 10x error on the Kuwaiti dinar, which has a thousand.
      expect(Currency.tryParse('EUR')!.exponent, 2);
      expect(Currency.tryParse('JPY')!.exponent, 0);
      expect(Currency.tryParse('KRW')!.exponent, 0);
      expect(Currency.tryParse('KWD')!.exponent, 3);
    });

    test('minorPerMajor follows the exponent', () {
      expect(Currency.tryParse('EUR')!.minorPerMajor, 100);
      expect(Currency.tryParse('JPY')!.minorPerMajor, 1);
      expect(Currency.tryParse('KWD')!.minorPerMajor, 1000);
    });

    test('IRR is zero, which the toman path depends on', () {
      // Dividing by ten is only a rial-to-toman conversion if the minor unit
      // IS the rial. At the default exponent of 2 the same stored integer
      // reads a hundredfold apart between the two display modes.
      expect(Currency.tryParse('IRR')!.exponent, 0);
      expect(Currency.tryParse('IRR')!.minorPerMajor, 1);
    });

    test('IQD is 3, which is ISO and not CLDR', () {
      // CLDR says 0 because Iraqi cash does not circulate in fils; ISO says 3
      // because the dinar is divided into a thousand of them. The stored
      // integer is in the ISO minor unit, and SPEC.md §5 states 3 for display
      // too.
      expect(Currency.tryParse('IQD')!.exponent, 3);
    });

    test('anything not in the table is 2', () {
      expect(Currency.tryParse('USD')!.exponent, 2);
      expect(Currency.tryParse('SEK')!.exponent, 2);
    });
  });

  group('parsing', () {
    test('an unparseable code is null, never a default', () {
      // "Default to two decimals" is how a yen amount ends up a hundred times
      // too small. The caller turns null into a typed failure.
      for (final bad in ['', 'EU', 'EURO', '12A', 'eu r', '€']) {
        expect(Currency.tryParse(bad), isNull, reason: bad);
      }
    });

    test('a code is upper-cased, so one currency is one key', () {
      expect(Currency.tryParse('eur'), Currency.tryParse('EUR'));
      expect(Currency.tryParse('eur')!.code, 'EUR');
    });
  });

  group('arithmetic', () {
    test('same-currency addition and subtraction are exact', () {
      expect(
        (Money(1050, isoCurrency('EUR')) + Money(295, isoCurrency('EUR')))
            .amountMinor,
        1345,
      );
      expect(
        (Money(1050, isoCurrency('EUR')) - Money(295, isoCurrency('EUR')))
            .amountMinor,
        755,
      );
    });

    test('adding two currencies is a programmer error, not a failure', () {
      // A screen that adds euros to pounds is wrong in its own logic, not
      // handling a runtime condition. `error-handling-typed-results` rule 8: a
      // bug is thrown, a recoverable failure is returned.
      expect(
        () => Money(100, isoCurrency('EUR')) + Money(100, isoCurrency('GBP')),
        throwsArgumentError,
      );
      expect(
        () => Money(100, isoCurrency('EUR')) - Money(100, isoCurrency('GBP')),
        throwsArgumentError,
      );
      expect(
        () => Money(
          100,
          isoCurrency('EUR'),
        ).compareTo(Money(100, isoCurrency('GBP'))),
        throwsArgumentError,
      );
    });

    test('a hundred amounts sum exactly', () {
      // The reason the canonical value is an int: 0.1 + 0.2 is not 0.3, and a
      // fuel log adds hundreds of amounts.
      var total = Money.zero(isoCurrency('EUR'));
      for (var i = 0; i < 100; i++) {
        total += Money(1010, isoCurrency('EUR')); // €10.10
      }
      expect(total.amountMinor, 101000);
    });

    test('a negative amount is representable and recognised', () {
      // Only an Expense may be negative — a refund, a reimbursement, a payout
      // — and this is how a caller asks without reaching for the raw integer.
      expect(Money(-1250, isoCurrency('EUR')).isNegative, isTrue);
      expect(Money(0, isoCurrency('EUR')).isZero, isTrue);
      expect(Money(1, isoCurrency('EUR')).isNegative, isFalse);
    });

    test('money scales by a whole number only', () {
      // Multiplying money by a double is how a percentage becomes a fraction
      // of a cent that then rounds twice. Division goes through `allocate`.
      expect((Money(1050, isoCurrency('EUR')) * 3).amountMinor, 3150);
    });
  });

  test('two amounts of the same value and currency are equal', () {
    expect(Money(1050, isoCurrency('EUR')), Money(1050, isoCurrency('EUR')));
    expect(
      Money(1050, isoCurrency('EUR')),
      isNot(Money(1050, isoCurrency('GBP'))),
    );
    expect({
      Money(1050, isoCurrency('EUR')),
      Money(1050, isoCurrency('EUR')),
    }, hasLength(1));
  });

  test('a yen amount has no subunit', () {
    // ¥4599 is four thousand five hundred and ninety-nine yen, not ¥45.99.
    expect(Money(4599, isoCurrency('JPY')).amountMinor, 4599);
    expect(isoCurrency('JPY').minorPerMajor, 1);
  });
}
