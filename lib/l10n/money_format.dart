// Money on screen: the symbol, its side, its spacing, and the isolate that
// holds the whole thing together.
//
// SPEC.md §5: money is ONE atomic, isolate-wrapped unit. Placement, spacing and
// any RLM belong here and never to a translation string — a translator handed
// "{amount} €" will move the euro, and they will be right to, and it will be
// wrong in the other five.
// **Not in `lib/core/`, and the purity gate is why.** This places a currency symbol for a locale, which
// means it takes `package:intl` — and a domain function that formats has taken
// a locale as a HIDDEN input: the same computation then answers differently in
// Tehran and Toronto. Formatting is a presentation act and lives at the edge.
//
// EPIC-04 moved these into `lib/core/l10n/` on the reasoning that they import
// no Flutter, which was true and not the whole rule. EPIC-06's
// `tools/check_core_purity.sh` caught it on its first run.

import 'package:intl/intl.dart' hide TextDirection;
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money.dart';
import 'package:odova/l10n/number_format.dart';

/// `Settings.currency_display`.
enum CalmCurrencyDisplay {
  /// The ISO currency, formatted by CLDR. SPEC.md §3 spells the wire value
  /// `none`, and the enum name is the code's word for the same thing.
  iso('none'),

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

/// Currency symbols Odova supplies itself, per (currency, script) pair.
///
/// `NumberFormat.simpleCurrency` resolves its symbol from a LOCALE-INDEPENDENT
/// map, so the locale argument changes the pattern and never the symbol: every
/// currency SPEC.md §5's table names for an RTL locale came out in Latin —
/// `Rial۱٬۲۳۴٫۵۶`, `١٬٢٣٤٫٥٦ E£`, `1.234,56 dh`, `din۱۲۳٫۴۵۶`. The table is
/// the same mechanism as the unit abbreviations: ICU formats the number, the
/// label is ours.
const arabicScriptCurrencySymbols = <String, String>{
  'EGP': 'ج.م.',
  'MAD': 'د.م.',
  'IQD': 'د.ع.',
  'IRR': 'ریال',
  'SAR': 'ر.س.',
  'AED': 'د.إ.',
  'KWD': 'د.ك.',
  'AFN': '؋',
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
      foldDigitsToAscii(calmDecimalFormat(formatsTag).format(tomans)),
      resolved,
    );
    return isolate('$digits $tomanLabel');
  }

  // simpleCurrency, not currency: the latter uses the CODE as the symbol
  // unless one is supplied, so USD renders as `USD1,234.56` rather than
  // `$1,234.56`, and it does it without any error.
  final format = NumberFormat.simpleCurrency(
    locale: numberFormatLocale(formatsTag),
    name: money.currency,
    decimalDigits: currencyDecimals(money.currency),
  );

  var rendered = format.format(money.major);

  // Substitute the Arabic-script symbol where SPEC.md §5's table names one.
  // Done on the formatted string rather than by passing `symbol:` so ICU still
  // decides the PLACEMENT and the spacing, which is the half that differs by
  // locale and the half a translation string must never carry.
  final ours = arabicScriptCurrencySymbols[money.currency];
  if (ours != null && _usesArabicScript(formatsTag)) {
    rendered = rendered.replaceFirst(format.currencySymbol, ours);
  }

  // Folded first: see formatForDisplay. The formatter's own zero-digit would
  // otherwise defeat an explicit `numerals: latin`.
  return isolate(shapeDigits(foldDigitsToAscii(rendered), resolved));
}

/// The toman label. Not an ISO currency, so it has no CLDR symbol.
const tomanLabel = 'تومان';

bool _usesArabicScript(String formatsTag) =>
    const {'fa', 'ar', 'ckb'}.contains(languageOf(formatsTag));
