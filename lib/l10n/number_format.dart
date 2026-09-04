// Formatting a number for display, and for export.
//
// The order is the whole contract: ICU formats the number — grouping,
// separators, the locale's own conventions — and shaping is the LAST step,
// applied to the finished string. Shaping first would give ICU a digit string
// to group, and it would group it wrong.
// `intl` exports a TextDirection of its own — a bidi helper, not the layout
// enum — and it wins the import race. Hidden, so `TextDirection.ltr` below
// means what every other file in this repo means by it.
// **Not in `lib/core/`, and the purity gate is why.** This formats a number for a locale, which
// means it takes `package:intl` — and a domain function that formats has taken
// a locale as a HIDDEN input: the same computation then answers differently in
// Tehran and Toronto. Formatting is a presentation act and lives at the edge.
//
// EPIC-04 moved these into `lib/core/l10n/` on the reasoning that they import
// no Flutter, which was true and not the whole rule. EPIC-06's
// `tools/check_core_purity.sh` caught it on its first run.

import 'package:intl/intl.dart' hide TextDirection;
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';

/// Locales `intl` has no number symbols for, and who lends them.
///
/// Both borrows are measured rather than assumed, and both have a test that
/// pins the reason.
///
/// `ckb` — Persian, for the same reason the framework delegates borrow it:
/// Sorani uses the Perso-Arabic letterforms and the Extended Arabic-Indic
/// digit block, and its separators are Persian's. Without the borrow `intl`
/// formats Latin, which would put `1,234.56` under a Sorani UI beside
/// Persian-shaped digits everywhere else on the screen.
///
/// The Maghreb — German. SPEC.md §5's verified output for `ar-MA` is
/// `1.234,56`: Latin digits with a `.` group and a `,` decimal, which is the
/// European convention the Maghreb writes Arabic in. `intl` carries no `ar_MA`
/// and plain `ar` yields `1,234.56` — AMERICAN separators under an Arabic UI.
/// German is the donor because its separators are exactly SPEC's, not because
/// the languages are related.
const numberSymbolBorrows = <String, String>{'ckb': 'fa'};

/// The locale `intl` should format numbers for.
///
/// Never the strings locale: SPEC.md §5 formats on the FULL tag while strings
/// come from the language subtag, so `pt-BR` gets English words with Brazilian
/// separators.
String numberFormatLocale(String formatsTag) {
  final normalised = formatsTag.replaceAll('-', '_');
  final language = languageOf(formatsTag);
  final region = regionOf(formatsTag);

  final borrowed = numberSymbolBorrows[language];
  if (borrowed != null) return borrowed;

  // Arabic, by region, and BOTH branches matter.
  //
  // `intl` carries `ar` and `ar_EG` and almost nothing between them. Plain
  // `ar`'s symbols are Latin-digit with AMERICAN separators, so every Arabic
  // tag that is not `ar_EG` fell through to it and rendered `١,٢٣٤.٥٦` —
  // Arabic-Indic digits with a comma group and a full-stop decimal, a hybrid
  // CLDR never emits. The first version fixed only the Maghreb, which is the
  // half that is Latin-digit anyway.
  if (language == 'ar') {
    return maghrebRegions.contains(region)
        // SPEC.md §5's verified `1.234,56`: Latin digits, European
        // separators. German's symbols are exactly that shape; `intl` has no
        // European-separator Arabic at all.
        ? 'de'
        // U+066C group, U+066B decimal — what `ar_EG` carries and what SPEC's
        // table requires for Arabic outside the Maghreb.
        : 'ar_EG';
  }

  // Verified, and falling back to the LANGUAGE rather than to intl's default.
  // Handing NumberFormat a tag it does not know does not throw and does not
  // fall back to the language — it falls back to en_US, so `ar_MA` came out
  // `1,234.56` instead of `1.234,56`: American separators under an Arabic UI,
  // silently, for every locale intl happens not to carry.
  return Intl.verifiedLocale(
    normalised,
    NumberFormat.localeExists,
    onFailure: (_) => Intl.verifiedLocale(
      normalised.split('_').first,
      NumberFormat.localeExists,
      onFailure: (_) => 'en_US',
    )!,
  )!;
}

/// A decimal formatter for [formatsTag].
NumberFormat calmDecimalFormat(String formatsTag) =>
    NumberFormat.decimalPattern(numberFormatLocale(formatsTag));

/// The character [formatsTag] groups thousands with.
///
/// The one piece of locale knowledge `normalizeNumericInput` needs, and the
/// reason it is read from the formatter rather than from a table: a table is a
/// second source of truth that drifts from ICU on the first locale nobody
/// checked.
String groupingSeparatorFor(String formatsTag) {
  // Read out of a formatted sample rather than out of a symbols table: the
  // table is a second source of truth, and it drifts from the formatter on the
  // first locale nobody checked. 1000 groups exactly once in every locale the
  // app ships, so the character between the 1 and the first 0 IS the grouper.
  // Folded to ASCII FIRST. Without that the scan trips over the very digits it
  // exists to serve: `۱٬۰۰۰` has no ASCII digit in it at all, so the first
  // "non-digit" character is the leading ۱.
  final formatted = foldDigitsToAscii(
    calmDecimalFormat(formatsTag).format(1000),
  );
  final digits = RegExp('[0-9]');
  for (final char in formatted.split('')) {
    if (!digits.hasMatch(char)) return char;
  }
  return '';
}

/// Formats [value] for the screen: ICU's grouping and separators, then the
/// active digit block.
String formatForDisplay(
  num value,
  String formatsTag, {
  required CalmNumerals numerals,
  int? decimalDigits,
  bool grouped = true,
}) {
  final format = calmDecimalFormat(formatsTag);
  // A COUNT is not a quantity. A year grouped reads "1,900" in English and
  // "۱٬۹۰۰" in Persian — a thousand nine hundred, which is not a year anybody
  // has driven a car in. The digit BLOCK still follows the locale; this drops
  // the separator, not the shaping.
  if (!grouped) format.turnOffGrouping();
  if (decimalDigits != null) {
    format
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
  }
  // Folded to ASCII, THEN shaped. `shapeDigits` only maps ASCII into a block,
  // so without the fold it cannot map back OUT of one — and `ar_EG`'s symbols
  // carry `zeroDigit: ٠`, so the formatter emits Arabic-Indic digits on its
  // own. A user who set `numerals: latin` on an Arabic locale got Arabic-Indic
  // digits anyway, with the setting silently doing nothing. SPEC.md §5 offers
  // that row precisely because younger Gulf and Persian readers pick it.
  return shapeDigits(
    foldDigitsToAscii(format.format(value)),
    resolveNumerals(numerals, formatsTag),
  );
}

/// Formats [value] for a file.
///
/// ASCII digits, a `.` decimal point and no grouping, whatever the user's
/// settings say. SPEC.md §5: RFC 8259 permits ASCII digits only, and a JSON
/// number containing `۴` is not JSON.
///
/// Throws on a non-finite value rather than writing one. `toString()` on a
/// NaN or an infinity yields `NaN` / `Infinity`, which no JSON parser will
/// read back — and a derived value CAN be non-finite: consumption over a
/// zero-distance segment, cost per km with no odometer delta. SPEC.md §2 calls
/// losing eight years of history the worst bug this app can have, so an
/// unparseable backup is worth a crash at the point of the mistake rather than
/// a caller convention nobody enforces.
String formatForExport(num value) {
  if (value is double && !value.isFinite) {
    throw ArgumentError.value(value, 'value', 'not representable in JSON');
  }
  return value.toString();
}
