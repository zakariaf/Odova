// A total over amounts that may be in different currencies.
//
// SPEC.md §12 Ground rules: money never mixes. The app has no network, so any
// exchange rate it used would be invented — and a made-up rate silently
// rewrites the resale value of somebody's service history. So a total across
// currencies GROUPS rather than summing, and the screen shows two lines.
import 'package:meta/meta.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/value_equality.dart';

/// Amounts grouped by currency.
@immutable
class MoneyTotal with ValueEquality {
  /// Creates a total from [amounts], grouping by currency.
  factory MoneyTotal(Iterable<Money> amounts) {
    final byCurrency = <Currency, int>{};
    final counts = <Currency, int>{};
    for (final amount in amounts) {
      byCurrency.update(
        amount.currency,
        (sum) => sum + amount.amountMinor,
        ifAbsent: () => amount.amountMinor,
      );
      counts.update(amount.currency, (n) => n + 1, ifAbsent: () => 1);
    }
    // Sort the ENTRIES, rather than sorting the codes and parsing each one
    // back into a `Currency` to index the maps with. `tryParse` is a regex
    // match plus an allocation, it ran twice per currency, and it returns a
    // NULLABLE key — so a failure would have interpolated the string "null"
    // into the equality encoding instead of failing.
    final ordered = byCurrency.entries.toList()
      ..sort((a, b) => a.key.code.compareTo(b.key.code));
    return MoneyTotal._(
      Map.unmodifiable(byCurrency),
      Map.unmodifiable(counts),
      // Computed ONCE, in the factory. `props` is read by both `==` and
      // `hashCode`, so one comparison between two totals used to be four
      // sorts and four lists of interpolated strings — and this type is
      // headed for a `.distinct(valuesEqual)` on a watched stream, where that
      // happens on every emission.
      List.unmodifiable([
        for (final entry in ordered) ...[
          '${entry.key.code}:${entry.value}',
          '${entry.key.code}x${counts[entry.key]}',
        ],
      ]),
    );
  }

  const MoneyTotal._(this.byCurrency, this._counts, this.props);

  /// The summed amount per currency.
  final Map<Currency, int> byCurrency;

  final Map<Currency, int> _counts;

  /// Whether anything was totalled at all.
  bool get isEmpty => byCurrency.isEmpty;

  /// Whether more than one currency is present.
  ///
  /// The screen reads this to decide between one figure and a list. There is
  /// no third option that adds them up.
  bool get isMixed => byCurrency.length > 1;

  /// The currency with the most ROWS behind it, or null when empty.
  ///
  /// Rows and not magnitude, per SPEC.md §12: a household that logs 400
  /// fill-ups in euros and one 8,000-euro-equivalent repair in pounds is a
  /// euro household. Ties break on the code, so the answer is deterministic
  /// rather than dependent on map order.
  Currency? get dominantCurrency {
    if (_counts.isEmpty) return null;
    final entries = _counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.code.compareTo(b.key.code);
      });
    return entries.first.key;
  }

  /// The total in [currency], or zero.
  Money inCurrency(Currency currency) =>
      Money(byCurrency[currency] ?? 0, currency);

  /// Encoded as sorted strings rather than the maps themselves.
  ///
  /// A `Map` in `props` compares by IDENTITY, so two totals built from the same
  /// amounts would never be equal. Sorting makes the encoding independent of
  /// insertion order, which is the property a caller expects.
  ///
  /// The ROW COUNTS are in here too, and leaving them out was a real bug the
  /// props-completeness gate caught: [dominantCurrency] reads them, so two
  /// totals with identical sums but different row counts compared EQUAL while
  /// answering differently about which currency leads. A `distinct` on a
  /// stream would then swallow the change and the screen would keep the old
  /// primary currency.
  @override
  final List<Object?> props;

  @override
  String toString() {
    final parts =
        (byCurrency.entries.toList()
              ..sort((a, b) => a.key.code.compareTo(b.key.code)))
            .map((e) => '${e.value} ${e.key}')
            .join(', ');
    return 'MoneyTotal($parts)';
  }
}
