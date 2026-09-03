// Money on screen: the symbol, its side, its spacing, and the isolate that
// holds the whole thing together.
//
// SPEC.md §5: money is ONE atomic, isolate-wrapped unit. Placement, spacing and
// any RLM belong here and never to a translation string — a translator handed
// "{amount} €" will move the euro, and they will be right to, and it will be
// wrong in the other five.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money.dart';
import 'package:odova/l10n/bidi.dart';
import 'package:odova/l10n/numerals.dart';

/// `Settings.currency_display`.
enum CalmCurrencyDisplay {
  /// The ISO currency, formatted by CLDR.
  iso('iso'),

  /// Iranian toman: the stored IRR amount divided by ten, zero decimals, and
  /// the word تومان.
  ///
  /// DISPLAY ONLY. Nobody quotes a service in rials, but `IRT` is not an ISO
  /// 4217 code and a non-ISO code in a backup would fail the file's own
  /// validation. Storage and export stay IRR minor units.
  toman('toman');

  const CalmCurrencyDisplay(this.wire);

  /// The stored value.
  final String wire;
}

/// Currency labels Odova supplies itself.
///
/// Only where CLDR's own symbol is wrong for this app's readers, and each one
/// is a label rather than a symbol — the same principle as the unit
/// abbreviations, and for the same reason.
const _labelOverrides = <String, String>{
  // Not an ISO code: the toman is ten rials and exists only on price tags.
  'toman': 'تومان',
};

/// Formats [money] for the screen.
///
/// The result is a single isolate: `FSI … PDI`. Splitting a number from its
/// symbol is what puts `€` on the wrong side of a Persian sentence, and
/// wrapping only the digits is what lets a minus sign migrate to the far end
/// of the line.
String formatMoney(
  Money money,
  String formatsTag, {
  required CalmNumerals numerals,
  CalmCurrencyDisplay display = CalmCurrencyDisplay.iso,
}) {
  final resolved = resolveNumerals(numerals, formatsTag);

  if (display == CalmCurrencyDisplay.toman && money.currency == 'IRR') {
    // Divide by ten and drop the decimals — but only here, on the way to a
    // pixel. The stored integer does not move.
    final tomans = (money.minorUnits / 10).round();
    final digits = shapeDigits(
      calmDecimalFormat(formatsTag).format(tomans),
      resolved,
    );
    return isolate('$digits ${_labelOverrides['toman']}');
  }

  // simpleCurrency, not currency: the latter uses the CODE as the symbol
  // unless one is supplied, so USD renders as `USD1,234.56` rather than
  // `$1,234.56`, and it does it without any error.
  final format = NumberFormat.simpleCurrency(
    locale: numberFormatLocale(formatsTag),
    name: money.currency,
    decimalDigits: currencyDecimals(money.currency),
  );

  return isolate(shapeDigits(format.format(money.major), resolved));
}

/// The currency symbol CLDR gives [currency] in [formatsTag].
String currencySymbolFor(String currency, String formatsTag) =>
    NumberFormat.simpleCurrency(
      locale: numberFormatLocale(formatsTag),
      name: currency,
    ).currencySymbol;
