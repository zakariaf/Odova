// The four value shapes every projection in this directory shares.
//
// SPEC.md §6 §2.4 is a MAPPING, never a second model: each projection is a
// pure function from the domain type, so there is no chance for the backup's
// idea of a vehicle and the app's to drift apart.
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';

/// Money as `{amount_minor, currency}`, never a decimal string.
///
/// §3 stores integer minor units and an ISO 4217 code, and §6 keeps that pair
/// together in the file for the same reason it is together in the database:
/// half a price is not a smaller price, it is an unknown one. A decimal string
/// would also make the file's meaning depend on the reader's idea of how many
/// decimals a currency has, which is exactly the question `Currency.exponent`
/// exists to answer once.
Map<String, Object?> moneyJson(Money money) => {
  'amount_minor': money.amountMinor,
  'currency': money.currency.code,
};

/// [money] as its pair, or null.
Map<String, Object?>? moneyJsonOrNull(Money? money) =>
    money == null ? null : moneyJson(money);

/// A distance in canonical metres, or null.
int? metresOrNull(Distance? distance) => distance?.metres;

/// A UTC millisecond timestamp as RFC 3339 with a `Z`.
///
/// Always UTC in the record fields. §6 puts the writer's local offset in the
/// ENVELOPE once, so a reader can tell what "2026-09-02" meant to the person
/// who wrote it, without every row carrying an offset that would then have to
/// be trusted.
String rfc3339(int utcMs) => DateTime.fromMillisecondsSinceEpoch(
  utcMs,
  isUtc: true,
).toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

/// The same, or null.
String? rfc3339OrNull(int? utcMs) => utcMs == null ? null : rfc3339(utcMs);
