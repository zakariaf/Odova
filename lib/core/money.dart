// Money, as an integer and a code.
//
// SPEC.md §2: storage is canonical — minor currency units plus an ISO 4217
// code. Never a double, because 0.1 + 0.2 is not 0.3 and a fuel log adds up
// hundreds of amounts; and never a bare number, because an amount without its
// currency is a number somebody will add to a different one.
//
// EPIC-06 owns the full value-object layer. This is the minimum EPIC-04's
// formatter needs, in the place EPIC-06 will extend rather than replace.

/// CLDR's minor-unit exponent, where it is not 2.
///
/// The default is 2. These are the ones that are not, and they are not
/// cosmetic: rendering an Iraqi dinar with two decimals is out by a factor of
/// ten, and rendering a yen with two invents a subunit that does not exist.
/// This is the ISO 4217 MINOR-UNIT exponent — what the stored integer is in —
/// and it is deliberately not `intl`'s `currencyFractionDigits`, which carries
/// CLDR's *cash rounding*. The two agree on eleven of these twelve and
/// disagree on IQD, where CLDR says 0 because Iraqi cash does not circulate in
/// fils and ISO says 3 because the dinar is divided into a thousand of them.
/// SPEC.md §5 states IQD 3 for display too, so this table serves both.
const currencyDecimalsOverrides = <String, int>{
  'JPY': 0,
  // Zero, and the toman display path depends on it: dividing minorUnits by ten
  // is only a rial-to-toman conversion if the minor unit IS the rial. With the
  // default exponent of 2 the same stored integer read a hundredfold apart
  // between the two display modes.
  'IRR': 0,
  // CLDR gives Afghanistan's afghani zero digits too. SPEC.md §5 ships fa-AF.
  'AFN': 0,
  'KRW': 0,
  'VND': 0,
  'CLP': 0,
  'ISK': 0,
  'KWD': 3,
  'BHD': 3,
  'IQD': 3,
  'JOD': 3,
  'OMR': 3,
  'TND': 3,
  'LYD': 3,
};

/// How many decimal places [currency] has.
int currencyDecimals(String currency) =>
    currencyDecimalsOverrides[currency.toUpperCase()] ?? 2;

/// An amount in one currency.
///
/// [minorUnits] is what is stored and exported: cents, fils, rials. The major
/// value is a projection for display, computed on read and never persisted.
extension type const Money((int minorUnits, String currency) _value) {
  /// Creates an amount.
  const Money.of(int minorUnits, String currency)
    : _value = (minorUnits, currency);

  /// The stored integer.
  int get minorUnits => _value.$1;

  /// The ISO 4217 code. Three letters, uppercase, and a real one:
  /// `IRT` is not an ISO code and must appear nowhere.
  String get currency => _value.$2;

  /// The amount as a decimal, for a formatter. Computed, never stored.
  double get major => minorUnits / _pow10(currencyDecimals(currency));
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
