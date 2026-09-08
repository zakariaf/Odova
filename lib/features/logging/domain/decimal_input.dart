// A typed decimal on its way to an integer column.
//
// SPEC.md §3 stores canonical integers — millilitres, grams, watt-hours, minor
// units — and §10 lets the user type them in any of six locales. This file is
// the step between, and it is deliberately thin: EPIC-04 already built the
// PARSER (`normalizeNumericInput`), which handles every separator and digit set
// §10's Field kit lists and refuses an ambiguous grouping rather than guessing.
// A second parser here would be a second set of rules about `1,234`.
//
// What was missing is the conversion. `(litres * 1000).round()` looks harmless
// and is not: 8.7 is 8.699999999999999 in binary and truncating gives 8699 mL,
// which is a millilitre lost on a fill-up and a litre lost over a year of them.
// The money side already had `minorUnitsFrom` for exactly this reason; the fuel
// side did not, and this gives it the same treatment — scale by string, round
// half away from zero, never touch a double.
import 'package:flutter/services.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/minor_units.dart';
import 'package:odova/l10n/number_format.dart';

/// What a typed decimal turned out to be.
///
/// Three outcomes and not `double?`: "the user has not typed this yet" and
/// "the user typed something I could not read" are different states of a form,
/// and a nullable double collapses them into one.
sealed class DecimalInput {
  const DecimalInput();
}

/// A number the app can act on.
final class DecimalOk extends DecimalInput {
  /// Creates the result.
  const DecimalOk(this.canonical, this.value);

  /// The ASCII form — `-`, digits, at most one `.`. This is what is scaled and
  /// stored; the string the user typed never is.
  final String canonical;

  /// The same number as a double, for comparisons and display only.
  final double value;
}

/// Nothing was typed.
final class DecimalEmpty extends DecimalInput {
  /// Creates the result.
  const DecimalEmpty();
}

/// Something was typed and it could mean two things.
///
/// §10 refuses rather than picking: `1,234,5` is not a number, and a form that
/// chose one reading would be wrong for half the world silently.
final class DecimalAmbiguous extends DecimalInput {
  /// Creates the result.
  const DecimalAmbiguous();
}

/// Reads [raw] in a locale whose thousands separator is [groupingSeparator].
///
/// A thin mapping over `normalizeNumericInput`, so that the logging forms speak
/// in the three outcomes they actually branch on rather than in the parser's
/// five failure modes — `notANumber` and `ambiguous` are the same thing to a
/// form, which is "show the one sentence and keep what they typed".
DecimalInput parseDecimal(String raw, {required String groupingSeparator}) =>
    switch (normalizeNumericInput(raw, groupingSeparator: groupingSeparator)) {
      NumericInputOk(:final canonical, :final value) => DecimalOk(
        canonical,
        value,
      ),
      NumericInputRejected(failure: NumericInputFailure.empty) =>
        const DecimalEmpty(),
      NumericInputRejected() => const DecimalAmbiguous(),
    };

/// Whole millilitres from a canonical decimal, or null if it is not a quantity.
///
/// Null for a negative: §10 gives the keypad no minus key, so a negative litre
/// figure can only arrive by paste, and it is not a volume.
int? millilitresFrom(String canonical) => _scaled(canonical, 3);

/// Whole grams from a canonical decimal — CNG and LPG are sold by mass.
int? gramsFrom(String canonical) => _scaled(canonical, 3);

/// Whole watt-hours from a canonical decimal — a charge is sold by energy.
int? wattHoursFrom(String canonical) => _scaled(canonical, 3);

/// [canonical] × 10^[places] for a QUANTITY, or null if it is not one.
///
/// The scaling itself is `scaleByPowerOfTen`, which money already uses and
/// which exists because multiplying a double and rounding once took half a
/// cent off every amount ending `.005`. Volume, mass and energy scale by the
/// same factor of a thousand and deserve the same arithmetic.
///
/// What this adds is the sign rule: §10 gives the keypad no minus key, so a
/// negative litre figure can only arrive by paste, and it is not a volume.
int? _scaled(String canonical, int places) =>
    canonical.startsWith('-') ? null : scaleByPowerOfTen(canonical, places);

/// How many decimal places a money field in [currency] accepts.
///
/// From the ISO 4217 exponent, per §10 — 2 for EUR, 0 for JPY, 3 for KWD.
int decimalsFor(Currency currency) => currency.exponent;

/// Refuses a keystroke that would put more than [decimals] after the separator.
///
/// §10 gives money "decimal places = the ISO 4217 exponent" and the odometer
/// "no decimal". The refusal belongs at the KEYSTROKE: a field that accepts a
/// third decimal on a euro amount and rounds it at Save is the app quietly
/// disagreeing with the receipt in the user's other hand.
///
/// It also refuses a minus sign at every width. §10: "a negative sign is never
/// produced by the keypad — the refund switch owns the sign", because a minus
/// key is inconsistent across platforms and reverses badly in RTL.
class DecimalFieldFormatter extends TextInputFormatter {
  /// Creates the formatter.
  DecimalFieldFormatter({
    required this.decimals,
    required this.groupingSeparator,
  });

  /// How many digits may follow the decimal separator. Zero means none, and
  /// then no separator may be typed either.
  final int decimals;

  /// The locale's thousands separator, so a grouped figure is not mistaken for
  /// a decimal one while it is half typed.
  final String groupingSeparator;

  /// Whether [text] is something this field would hold.
  ///
  /// Public because it is the whole rule, and a test that had to build a
  /// `TextEditingValue` pair to ask a yes/no question would be testing Flutter.
  bool wouldAccept(String text) {
    if (text.isEmpty) return true;
    if (text.contains('-')) return false;

    final read = normalizeNumericInput(
      text,
      groupingSeparator: groupingSeparator,
    );
    // A half-typed number is not a rejection: "42." is on the way to "42.6".
    // Only a value the parser can read is measured for its decimals.
    if (read is! NumericInputOk) return !_hasTooManyDecimals(text);
    return !_hasTooManyDecimals(read.canonical);
  }

  bool _hasTooManyDecimals(String canonical) {
    final dot = canonical.indexOf('.');
    if (dot < 0) return false;
    if (decimals == 0) return true;
    return canonical.length - dot - 1 > decimals;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => wouldAccept(newValue.text) ? newValue : oldValue;
}

/// [raw] re-rendered in [formatsTag]'s own digits, or unchanged if unreadable.
///
/// §10: "On blur the field re-renders canonically in the active numbering
/// system." Unchanged when it cannot be read, because replacing what the user
/// typed with the app's guess about it is how a mis-parse becomes permanent.
///
/// [grouped] is REQUIRED and has no default, because the two edges of a focus
/// change want opposite answers and a default is a way to get one of them by
/// accident. True is the blurred field, which is what §10 and the artboard both
/// describe — `log.fillup` reads `187,412`. False is the focused one, which
/// must hold an UNGROUPED string: `DecimalFieldFormatter` reads `187,41` — one
/// backspace into `187,412` — as a decimal rather than a grouping, and
/// `decimals: 0` then refuses the keystroke silently. This shipped grouping on
/// blur and nothing on focus, which made the field uneditable in five of the
/// six locales; a mutation then showed the default was never exercised, so it
/// is gone.
String canonicalDisplay(
  String raw,
  String formatsTag, {
  required int decimals,
  required bool grouped,
}) {
  final read = parseDecimal(
    raw,
    groupingSeparator: groupingSeparatorFor(formatsTag),
  );
  if (read is! DecimalOk) return raw;
  return formatForDisplay(
    read.value,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: decimals,
    grouped: grouped,
  );
}
