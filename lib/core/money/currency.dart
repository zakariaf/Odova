// An ISO 4217 currency and its minor-unit exponent.
//
// SPEC.md §3 Canonical units (Money) and §3 Currency. The exponent is the whole
// point of this type: a hardcoded 100 is a 100x error on the yen, which has no
// subunit, and a 10x error on the Kuwaiti dinar, which has a thousand.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// Currencies whose minor-unit exponent is not 2.
///
/// The ISO 4217 MINOR-UNIT exponent — what the stored integer is in —
/// deliberately not `intl`'s `currencyFractionDigits`, which carries CLDR's
/// CASH ROUNDING. The two agree on eleven of these twelve and disagree on IQD,
/// where CLDR says 0 because Iraqi cash does not circulate in fils and ISO says
/// 3 because the dinar is divided into a thousand of them. SPEC.md §5 states
/// IQD 3 for display too, so this table serves both.
const currencyExponents = <String, int>{
  'JPY': 0,
  'KRW': 0,
  'VND': 0,
  'CLP': 0,
  'ISK': 0,
  // Zero, and the toman display path depends on it: dividing by ten is only a
  // rial-to-toman conversion if the minor unit IS the rial. At the default
  // exponent of 2 the same stored integer reads a hundredfold apart between the
  // two display modes.
  'IRR': 0,
  'AFN': 0,
  'KWD': 3,
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'OMR': 3,
  'TND': 3,
  'LYD': 3,
};

/// A currency.
///
/// A type rather than a `String`, so an amount cannot be built with a
/// three-character string that is not a currency, and so the exponent travels
/// with the code. [tryParse] returns null for anything that is not three
/// letters — the caller turns that into a typed failure, because "default to
/// two decimals" is how a yen amount ends up a hundred times too small.
@immutable
class Currency with ValueEquality {
  const Currency._(this.code);

  /// Reads a three-letter ISO 4217 code, or null.
  ///
  /// Case-insensitive on the way in and upper-case on the way out, because
  /// `eur` and `EUR` are the same currency and two spellings of it in one
  /// database is two currencies to every `groupBy`.
  static Currency? tryParse(String code) {
    final upper = code.toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(upper)) return null;
    return Currency._(upper);
  }

  /// The three-letter code.
  final String code;

  /// How many decimal places this currency has.
  int get exponent => currencyExponents[code] ?? 2;

  /// How many minor units make one major unit: 100 for EUR, 1 for JPY, 1000
  /// for KWD.
  int get minorPerMajor => switch (exponent) {
    0 => 1,
    1 => 10,
    2 => 100,
    3 => 1000,
    _ => throw StateError('exponent $exponent is not an ISO 4217 exponent'),
  };

  @override
  List<Object?> get props => [code];

  @override
  String toString() => code;
}
