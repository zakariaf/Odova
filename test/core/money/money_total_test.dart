// A total across currencies groups; it never sums.
//
// SPEC.md §12 Ground rules. The app has no network, so any exchange rate it
// used would be invented — and a made-up rate silently rewrites the resale
// value of somebody's service history.
import 'package:odova/core/money/money_total.dart';
import 'package:test/test.dart';

import '../../support/values.dart';

void main() {
  test('two currencies give two entries, never one sum', () {
    final total = MoneyTotal([
      Money(124000, isoCurrency('EUR')),
      Money(8000, isoCurrency('GBP')),
    ]);

    expect(total.byCurrency, hasLength(2));
    expect(total.byCurrency[isoCurrency('EUR')], 124000);
    expect(total.byCurrency[isoCurrency('GBP')], 8000);
    expect(total.isMixed, isTrue);
  });

  test('amounts in one currency add up', () {
    final total = MoneyTotal([
      Money(1050, isoCurrency('EUR')),
      Money(295, isoCurrency('EUR')),
      Money(-100, isoCurrency('EUR')),
    ]);

    expect(total.byCurrency, {isoCurrency('EUR'): 1245});
    expect(total.isMixed, isFalse);
    expect(
      total.inCurrency(isoCurrency('EUR')),
      Money(1245, isoCurrency('EUR')),
    );
  });

  test('the dominant currency is the one with the most ROWS', () {
    // Rows and not magnitude, per SPEC.md §12: a household that logs 400
    // fill-ups in euros and one 8,000-euro-equivalent repair in pounds is a
    // euro household. Sorting by magnitude would call it a sterling one.
    final total = MoneyTotal([
      for (var i = 0; i < 400; i++) Money(6000, isoCurrency('EUR')),
      Money(800000, isoCurrency('GBP')),
    ]);

    expect(total.dominantCurrency, isoCurrency('EUR'));
    expect(
      total.byCurrency[isoCurrency('GBP')]! >
          total.byCurrency[isoCurrency('EUR')]! ~/ 400,
      isTrue,
      reason: 'the pound row is individually the largest, and still loses',
    );
  });

  test('a tie on row count breaks on the code, deterministically', () {
    // Otherwise the answer depends on map iteration order, and the screen
    // picks a different primary currency between two launches.
    final total = MoneyTotal([
      Money(100, isoCurrency('USD')),
      Money(100, isoCurrency('EUR')),
    ]);
    expect(total.dominantCurrency, isoCurrency('EUR'));

    // Same input, other order.
    expect(
      MoneyTotal([
        Money(100, isoCurrency('EUR')),
        Money(100, isoCurrency('USD')),
      ]).dominantCurrency,
      isoCurrency('EUR'),
    );
  });

  test('an empty total has no dominant currency and no entries', () {
    final total = MoneyTotal(const []);
    expect(total.isEmpty, isTrue);
    expect(total.isMixed, isFalse);
    expect(total.dominantCurrency, isNull);
    expect(total.inCurrency(isoCurrency('EUR')), Money(0, isoCurrency('EUR')));
  });

  test('two totals with the same content are equal, whatever the order', () {
    expect(
      MoneyTotal([
        Money(100, isoCurrency('EUR')),
        Money(50, isoCurrency('GBP')),
      ]),
      MoneyTotal([
        Money(50, isoCurrency('GBP')),
        Money(100, isoCurrency('EUR')),
      ]),
    );
  });

  test('equal totals cannot disagree about the dominant currency', () {
    // The bug the props-completeness gate caught. The ROW COUNTS drive
    // `dominantCurrency` and were outside equality, so these two compared
    // EQUAL while answering differently — and a `distinct` on a stream would
    // have swallowed the change, leaving the screen on the old primary
    // currency.
    final euroLed = MoneyTotal([
      Money(50, isoCurrency('EUR')),
      Money(50, isoCurrency('EUR')),
      Money(100, isoCurrency('GBP')),
    ]);
    final poundLed = MoneyTotal([
      Money(100, isoCurrency('EUR')),
      Money(50, isoCurrency('GBP')),
      Money(50, isoCurrency('GBP')),
    ]);

    expect(euroLed.byCurrency, poundLed.byCurrency, reason: 'same sums');
    expect(euroLed.dominantCurrency, isoCurrency('EUR'));
    expect(poundLed.dominantCurrency, isoCurrency('GBP'));
    expect(euroLed, isNot(poundLed), reason: 'so they must not be equal');
  });

  test('the grouping is not writable through byCurrency', () {
    // A caller that mutated the map would change a value nothing recomputed.
    final total = MoneyTotal([Money(100, isoCurrency('EUR'))]);
    expect(
      () => total.byCurrency[isoCurrency('GBP')] = 1,
      throwsUnsupportedError,
    );
  });
}
