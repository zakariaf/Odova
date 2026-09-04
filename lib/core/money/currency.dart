// An ISO 4217 currency and its minor-unit exponent.
//
// SPEC.md §3 Canonical units (Money) and §3 Currency. The exponent is the whole
// point of this type: a hardcoded 100 is a 100x error on the yen, which has no
// subunit, and a 10x error on the Kuwaiti dinar, which has a thousand.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// Currencies whose minor-unit exponent is not 2.
///
/// This is what the STORED INTEGER is in, which is a decision this app makes
/// rather than a standard it copies — and it deliberately follows neither ISO
/// 4217 nor CLDR everywhere, because the two disagree in both directions.
///
/// Eleven of these fourteen are the same in both. The exceptions are the whole
/// reason this comment is long:
///
/// **IQD is 3 — ISO's answer, not CLDR's.** CLDR says 0 because Iraqi cash does
/// not circulate in fils; ISO says 3 because the dinar is divided into a
/// thousand of them. SPEC.md §5 states IQD 3 for display, so the table serves
/// both.
///
/// **AFN is 0 — CLDR's answer, not ISO's.** ISO assigns the afghani exponent 2
/// (100 pul); CLDR says 0, and the pul has not circulated for decades. SPEC.md
/// §5 ships `fa-AF`, so this is a locale the app actually serves, and storing
/// tenths of a pul nobody can spend would put two meaningless zeroes on every
/// Afghan amount. EPIC-04's table said the same and carried this sentence;
/// EPIC-06 deleted that file and dropped the sentence with it, leaving a value
/// that looked like an oversight.
///
/// **IRR is 0** for the same reason, and the toman display path depends on it:
/// dividing by ten is only a rial-to-toman conversion if the minor unit IS the
/// rial.
///
/// The exponent drives BOTH `minorPerMajor` (what the stored integer means) and
/// the formatter's decimal places, so **changing a row here silently
/// reinterprets every amount already stored in that currency by a factor of a
/// hundred.** Anyone "correcting" this table to match one standard has to
/// migrate the data too.
const currencyExponents = <String, int>{
  'JPY': 0,
  'KRW': 0,
  'VND': 0,
  'CLP': 0,
  'ISK': 0,
  'IRR': 0,
  // ISO says 2, CLDR says 0, and this app says 0. See the note above — it is a
  // deliberate departure from ISO and not a typo.
  'AFN': 0,
  'KWD': 3,
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'OMR': 3,
  'TND': 3,
  'LYD': 3,
};

/// Three letters, A-Z.
///
/// Top level, so it is compiled ONCE. `tryParse` is on the hottest read path
/// in the app — `row_mappers` calls it for every fill-up, expense, service line
/// and vehicle, and drift's stream invalidation is table-level, so the whole
/// query re-maps on every write. A `RegExp` built inside the function is a
/// compile per row.
final _isoCode = RegExp(r'^[A-Z]{3}$');

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
    if (!_isoCode.hasMatch(upper)) return null;
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
