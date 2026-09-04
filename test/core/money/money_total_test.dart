// A total across currencies groups; it never sums.
//
// SPEC.md §12 Ground rules. The app has no network, so any exchange rate it
// used would be invented — and a made-up rate silently rewrites the resale
// value of somebody's service history.
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:test/test.dart';

Currency get _eur => Currency.tryParse('EUR')!;
Currency get _gbp => Currency.tryParse('GBP')!;
Currency get _usd => Currency.tryParse('USD')!;

void main() {
  test('two currencies give two entries, never one sum', () {
    final total = MoneyTotal([Money(124000, _eur), Money(8000, _gbp)]);

    expect(total.byCurrency, hasLength(2));
    expect(total.byCurrency[_eur], 124000);
    expect(total.byCurrency[_gbp], 8000);
    expect(total.isMixed, isTrue);
  });

  test('amounts in one currency add up', () {
    final total = MoneyTotal([
      Money(1050, _eur),
      Money(295, _eur),
      Money(-100, _eur),
    ]);

    expect(total.byCurrency, {_eur: 1245});
    expect(total.isMixed, isFalse);
    expect(total.inCurrency(_eur), Money(1245, _eur));
  });

  test('the dominant currency is the one with the most ROWS', () {
    // Rows and not magnitude, per SPEC.md §12: a household that logs 400
    // fill-ups in euros and one 8,000-euro-equivalent repair in pounds is a
    // euro household. Sorting by magnitude would call it a sterling one.
    final total = MoneyTotal([
      for (var i = 0; i < 400; i++) Money(6000, _eur),
      Money(800000, _gbp),
    ]);

    expect(total.dominantCurrency, _eur);
    expect(
      total.byCurrency[_gbp]! > total.byCurrency[_eur]! ~/ 400,
      isTrue,
      reason: 'the pound row is individually the largest, and still loses',
    );
  });

  test('a tie on row count breaks on the code, deterministically', () {
    // Otherwise the answer depends on map iteration order, and the screen
    // picks a different primary currency between two launches.
    final total = MoneyTotal([Money(100, _usd), Money(100, _eur)]);
    expect(total.dominantCurrency, _eur);

    // Same input, other order.
    expect(
      MoneyTotal([Money(100, _eur), Money(100, _usd)]).dominantCurrency,
      _eur,
    );
  });

  test('an empty total has no dominant currency and no entries', () {
    final total = MoneyTotal(const []);
    expect(total.isEmpty, isTrue);
    expect(total.isMixed, isFalse);
    expect(total.dominantCurrency, isNull);
    expect(total.inCurrency(_eur), Money(0, _eur));
  });

  test('two totals with the same content are equal, whatever the order', () {
    expect(
      MoneyTotal([Money(100, _eur), Money(50, _gbp)]),
      MoneyTotal([Money(50, _gbp), Money(100, _eur)]),
    );
  });

  test('the grouping is not writable through byCurrency', () {
    // A caller that mutated the map would change a value nothing recomputed.
    final total = MoneyTotal([Money(100, _eur)]);
    expect(() => total.byCurrency[_gbp] = 1, throwsUnsupportedError);
  });
}
