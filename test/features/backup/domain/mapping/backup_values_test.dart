// The four value shapes every projection shares.
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/backup/domain/mapping/backup_values.dart';
import 'package:test/test.dart';

void main() {
  test('money is a pair, never a decimal string', () {
    // §3 stores integer minor units and an ISO code, and §6 keeps the pair
    // together for the same reason the database does: half a price is not a
    // smaller price, it is an unknown one. A decimal string would also make
    // the file's meaning depend on the reader's idea of how many decimals a
    // currency has.
    expect(moneyJson(Money(7351, Currency.tryParse('EUR')!)), {
      'amount_minor': 7351,
      'currency': 'EUR',
    });
  });

  test('a three-decimal currency keeps its own exponent implicitly', () {
    // 12,500 fils is 12.5 IQD. The file says 12500 and IQD and lets the
    // reader's `Currency` table decide, which is the only way a number
    // written today still means the same thing in ten years.
    expect(moneyJson(Money(12_500, Currency.tryParse('IQD')!)), {
      'amount_minor': 12_500,
      'currency': 'IQD',
    });
  });

  test('distances export as canonical metres', () {
    expect(metresOrNull(const Distance.fromKm(215_104)), 215_104_000);
    expect(metresOrNull(null), isNull);
  });

  test('timestamps are RFC 3339 UTC with a Z and no sub-second noise', () {
    // §6's worked example has `2026-09-02T16:41:07Z`. Dart's own
    // `toIso8601String` appends `.000`, which is three characters of nothing
    // in every row of a 12,000-record file and a difference from the spec's
    // example a byte comparison would catch.
    final at = DateTime.utc(2026, 9, 2, 16, 41, 7).millisecondsSinceEpoch;

    expect(rfc3339(at), '2026-09-02T16:41:07Z');
    expect(rfc3339OrNull(null), isNull);
  });
}
