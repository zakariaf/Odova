// The four value shapes every projection in this directory shares.
//
// SPEC.md §6 §2.4 is a MAPPING, never a second model: each projection is a
// pure function from the domain type, so there is no chance for the backup's
// idea of a vehicle and the app's to drift apart.
import 'package:odova/core/l10n/bidi.dart';
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
).toIso8601String().replaceFirst(_fractionalSeconds, 'Z');

/// Dart writes `.000Z` on every UTC instant and §6's timestamps carry no
/// fraction.
///
/// Hoisted, not built per call. This runs twice per record, so a 12,000-record
/// export compiled the same pattern 24,000 times — the same mistake
/// `_bidiControls` below already avoids.
final RegExp _fractionalSeconds = RegExp(r'\.\d+Z$');

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
  ).toIso8601String().replaceFirst(_fractionalSeconds, '');
  final sign = offset.isNegative ? '-' : '+';
  final total = offset.inMinutes.abs();
  return '$local$sign${_pad(total ~/ 60)}:${_pad(total % 60)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

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
  // `stripBidi`, not a second definition of what a bidi control is.
  // `lib/core/l10n/bidi.dart` names this exact caller in its own doc — "used
  // on the way OUT of the render layer: into a semantics label, INTO AN
  // EXPORT, into a filename" — and a private regex here would be a second
  // list to keep in step, silently narrower the day somebody adds to one.
  final String text => stripBidi(text),
  final Map<String, Object?> map => {
    for (final entry in map.entries) entry.key: sanitiseForBackup(entry.value),
  },
  final List<Object?> list => [
    for (final item in list) sanitiseForBackup(item),
  ],
  _ => value,
};
