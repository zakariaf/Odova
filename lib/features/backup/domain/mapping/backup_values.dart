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

/// The same instant as [utcMs], written at [offset].
///
/// The offset is signed and carries minutes, because half-hour zones are real
/// and are where a naive formatter goes wrong: Tehran is `+03:30` and
/// Newfoundland is `-03:30`, and both round to the same wrong hour.
String rfc3339Local(int utcMs, Duration offset) {
  final local = DateTime.fromMillisecondsSinceEpoch(
    utcMs + offset.inMilliseconds,
    isUtc: true,
  ).toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), '');
  final sign = offset.isNegative ? '-' : '+';
  final total = offset.inMinutes.abs();
  return '$local$sign${_pad(total ~/ 60)}:${_pad(total % 60)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

/// Every bidi control character Unicode defines, as one class.
///
/// U+200E/200F (LRM/RLM), U+061C (Arabic letter mark), U+202A–U+202E (the
/// deprecated embeddings and the override), and U+2066–U+2069 (the isolates the
/// app's own formatters add around a number).
final RegExp _bidiControls = RegExp(
  '[\u200e\u200f\u061c\u202a-\u202e'
  '\u2066-\u2069]',
);

/// [text] with every bidi control removed.
///
/// SPEC.md §6: no bidi control reaches the file. They are a DISPLAY device — a
/// note copied out of the app carries the isolates the formatter put around a
/// number — and in a stored document they break search, they break sorting, and
/// they break the read-it-in-a-text-editor property that is the whole reason
/// the backup is plain JSON. Nothing is lost by removing them: the underlying
/// characters keep their own directionality.
String stripBidiControls(String text) => text.replaceAll(_bidiControls, '');

/// [value] with every string in it stripped of bidi controls.
///
/// Applied once, at the encode boundary, rather than in each projection. Thirty
/// string fields across nine projections is thirty chances to forget, and the
/// field somebody forgets will be the free-text note — which is the only field
/// a user can paste a control character into.
///
/// Digits are deliberately NOT folded. A note the driver typed in Persian
/// numerals is their text, and rewriting it would be the app editing the user's
/// words to satisfy its own file format. §6's ASCII-digit rule is about the
/// numbers the WRITER emits, and those are JSON integers, which have no other
/// form.
Object? sanitiseForBackup(Object? value) => switch (value) {
  final String text => stripBidiControls(text),
  final Map<String, Object?> map => {
    for (final entry in map.entries) entry.key: sanitiseForBackup(entry.value),
  },
  final List<Object?> list => [
    for (final item in list) sanitiseForBackup(item),
  ],
  _ => value,
};
