// Formatting a number for display, and for export.
//
// The order is the whole contract: ICU formats the number — grouping,
// separators, the locale's own conventions — and shaping is the LAST step,
// applied to the finished string. Shaping first would give ICU a digit string
// to group, and it would group it wrong.
import 'package:flutter/widgets.dart';
// `intl` exports a TextDirection of its own — a bidi helper, not the layout
// enum — and it wins the import race. Hidden, so `TextDirection.ltr` below
// means what every other file in this repo means by it.
import 'package:intl/intl.dart' hide TextDirection;
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
const numberSymbolBorrows = <String, String>{
  'ckb': 'fa',
  'ar_MA': 'de',
  'ar_DZ': 'de',
  'ar_TN': 'de',
  'ar_LY': 'de',
};

/// The locale `intl` should format numbers for.
///
/// Never the strings locale: SPEC.md §5 formats on the FULL tag while strings
/// come from the language subtag, so `pt-BR` gets English words with Brazilian
/// separators.
String numberFormatLocale(String formatsTag) {
  final normalised = formatsTag.replaceAll('-', '_');
  for (final MapEntry(key: borrower, value: donor)
      in numberSymbolBorrows.entries) {
    if (normalised == borrower || normalised.startsWith('${borrower}_')) {
      return donor;
    }
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
}) {
  final format = calmDecimalFormat(formatsTag);
  if (decimalDigits != null) {
    format
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
  }
  // Shaping LAST, on the finished string.
  return shapeDigits(
    format.format(value),
    resolveNumerals(numerals, formatsTag),
  );
}

/// Formats [value] for a file.
///
/// ASCII digits, a `.` decimal point and no grouping, whatever the user's
/// settings say. SPEC.md §5: RFC 8259 permits ASCII digits only, and a JSON
/// number containing `۴` is not JSON.
String formatForExport(num value) => value.toString();

/// A number on screen, in the active digit block.
///
/// A widget rather than a call so that the two things that are easy to forget
/// — tabular figures, and the language tag a screen reader needs — happen in
/// one place. SPEC.md §5: numbers are announced in the display digit set.
class CalmFigure extends StatelessWidget {
  /// Creates a figure.
  const CalmFigure(
    this.value, {
    required this.formatsTag,
    required this.numerals,
    super.key,
    this.decimalDigits,
    this.style,
    this.semanticsLabel,
  });

  /// The number. Stored as a number, never as a digit string.
  final num value;

  /// The full BCP 47 tag formats come from.
  final String formatsTag;

  /// The active digit block, or [CalmNumerals.auto] to resolve from
  /// [formatsTag].
  final CalmNumerals numerals;

  /// Fixed decimals, when the caller has a currency or a unit that fixes them.
  final int? decimalDigits;

  /// The text style. Tabular figures are applied on top of it.
  final TextStyle? style;

  /// Overrides what a screen reader says — an estimate's "about", say.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final text = formatForDisplay(
      value,
      formatsTag,
      numerals: numerals,
      decimalDigits: decimalDigits,
    );

    return Text(
      text,
      semanticsLabel: semanticsLabel,
      style: (style ?? const TextStyle()).copyWith(
        // A column of figures that jitters as a digit changes reads as broken
        // rather than as live.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A code that is NEVER shaped: a VIN, a plate, a filename, a version string.
///
/// SPEC.md §5's always-Latin table. The plate is the subtle one — it is
/// verbatim as typed, never shaped either way, because an Iranian plate
/// legitimately contains Persian digits and a Persian letter. Transcribed,
/// not computed.
class CalmCode extends StatelessWidget {
  /// Creates a code.
  const CalmCode(this.value, {super.key, this.style});

  /// The characters, exactly as they are stored.
  final String value;

  /// The text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    value,
    // The direction is pinned rather than inherited: a VIN inside a Persian
    // sentence is a Latin run, and letting it take the paragraph's direction
    // is what reverses it.
    textDirection: TextDirection.ltr,
    style: style,
  );
}
