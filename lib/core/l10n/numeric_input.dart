// SPEC.md §5's `normalizeNumericInput`, line for line.
//
// A Persian keyboard emits `٫` (U+066B) for the decimal point and `٬` (U+066C)
// for grouping; the OS may emit anything. The one rule that matters more than
// the rest: when the string is still ambiguous after every deterministic step,
// this REJECTS it rather than guessing. A wrong guess here does not fail — it
// silently records 15 litres as 1.5 and corrupts a consumption history that
// nobody will re-derive.
import 'package:odova/core/l10n/numerals.dart';

/// Why an input could not be read as a number.
///
/// A stable code, never a localised string: the message a user sees is an ICU
/// message chosen by the caller, and this is what the caller switches on.
enum NumericInputFailure {
  /// Nothing but separators, spaces or controls.
  empty,

  /// A character survived normalisation that cannot be part of a number.
  notANumber,

  /// The separators are readable two ways and neither is more likely.
  ///
  /// `1,23,456` is the shape that gets here: a repeated separator, but with
  /// groups that are not the regular threes any of the six locales use.
  ambiguous,
}

/// The outcome of reading a typed number.
sealed class NumericInputResult {
  const NumericInputResult();
}

/// A number the app is willing to act on.
final class NumericInputOk extends NumericInputResult {
  /// Creates a successful read.
  const NumericInputOk(this.canonical, this.value);

  /// The ASCII form, `-`, digits and at most one `.`. This is what is parsed,
  /// compared and stored — never the string the user typed.
  final String canonical;

  /// [canonical] as a number.
  final double value;
}

/// An input the app refuses to guess at.
final class NumericInputRejected extends NumericInputResult {
  /// Creates a rejection.
  const NumericInputRejected(this.failure);

  /// Why.
  final NumericInputFailure failure;
}

/// Bidi controls, and every space used as a grouping separator.
///
/// Written as escapes: a literal U+202E in source reorders the code a reviewer
/// reads, which is the same class of problem this set exists to clean up.
const _stripped = <String>{
  '\u200E', '\u200F', '\u061C', // LRM, RLM, ALM
  '\u2066', '\u2067', '\u2068', '\u2069', // LRI, RLI, FSI, PDI
  '\u00A0', '\u202F', '\u2009', ' ', // NBSP, NNBSP, thin space, space
};

/// Reads a typed number, or says why it could not.
///
/// [groupingSeparator] is the character the ACTIVE locale groups with, AS THE
/// LOCALE WRITES IT — `,` for `en`, `.` for `de`, `٬` U+066C for `fa`. It is
/// mapped through the same ASCII folding as the input before it is compared,
/// which is the bug this signature used to hide: the input's `٬` became `.`
/// on line 3 while the argument stayed `٬`, so `'.' == '٬'` was never true and
/// a Persian `۱٬۲۳۴` — a grouped one thousand two hundred and thirty-four —
/// read as 1.234. A thousandfold error, silent, on the odometer.
///
/// Required rather than defaulted. A default of `,` means every caller that
/// forgets the argument silently gets English disambiguation, which in `de` or
/// `fa` reads `1,5` as fifteen hundred — the exact corruption this file exists
/// to prevent, reachable by omission and compile-clean.
///
/// It is the only locale knowledge this function has, and it decides exactly
/// one thing: whether a lone separator with three digits after it is grouping
/// or a decimal point. `1,5` in German is one and a half; `1,500` in English
/// is fifteen hundred.
NumericInputResult normalizeNumericInput(
  String input, {
  required String groupingSeparator,
}) {
  // 1. Strip the controls and the spaces.
  var s = input;
  for (final char in _stripped) {
    s = s.replaceAll(char, '');
  }

  // 2. Fold every digit block to ASCII.
  s = foldDigitsToAscii(s);

  // 3. Map the Arabic separators onto their ASCII counterparts.
  s = _toAsciiSeparators(s);

  final hasDot = s.contains('.');
  final hasComma = s.contains(',');

  // The SAME folding the input went through. Comparing a raw locale separator
  // against a folded one is a comparison that is never true.
  final grouping = _toAsciiSeparators(groupingSeparator);

  if (hasDot && hasComma) {
    // Both present: the RIGHTMOST is the decimal point, the other is grouping.
    final decimal = s.lastIndexOf('.') > s.lastIndexOf(',') ? '.' : ',';
    final grouping = decimal == '.' ? ',' : '.';
    s = s.replaceAll(grouping, '').replaceAll(decimal, '.');
  } else if (hasDot || hasComma) {
    final separator = hasDot ? '.' : ',';
    final parts = s.split(separator);
    final groups = parts.skip(1).toList();

    if (groups.length > 1) {
      // Repeated: it is grouping. SPEC.md's pseudocode stops here and removes
      // it. This also CHECKS the grouping is regular, which the pseudocode
      // does not: `1.234.567` is a number in five of the six locales, and
      // `1,23,456` is Indian grouping that none of them use. Reading the
      // second as 123456 is a guess, and this function does not guess.
      final regular = groups.every((g) => g.length == 3 && _isDigits(g));
      if (!regular) {
        return const NumericInputRejected(NumericInputFailure.ambiguous);
      }
      s = s.replaceAll(separator, '');
    } else {
      final tail = groups.single;
      // Exactly three digits after it AND the locale groups with it: grouping.
      // Otherwise it is the decimal point — which is why `1٫5` is one and a
      // half rather than fifteen, the case that silently corrupts an amount
      // when digits are folded and separators are not.
      final isGrouping =
          separator == grouping && tail.length == 3 && _isDigits(tail);
      s = isGrouping
          ? s.replaceAll(separator, '')
          : s.replaceAll(separator, '.');
    }
  }

  // 4. Reject anything that is not a plain signed decimal. The pattern admits
  // AT MOST ONE dot, so a separate "too many decimal points" branch after it
  // is unreachable — `1.2.3` and `1.2,3.4` both land here as notANumber. There
  // was one, and the test for it hedged with `anyOf(...)`, which is a test
  // written by somebody who did not know which branch fired and pinned
  // neither.
  if (!RegExp(r'^-?[0-9]*\.?[0-9]*$').hasMatch(s)) {
    return const NumericInputRejected(NumericInputFailure.notANumber);
  }
  // Nothing but a sign and separators.
  if (!RegExp('[0-9]').hasMatch(s)) {
    return const NumericInputRejected(NumericInputFailure.empty);
  }

  // `parse`, not `tryParse`: the pattern above has already established the
  // shape, and `.5`, `5.` and `-.5` all parse. A null-check here would be a
  // branch no input can reach.
  return NumericInputOk(s, double.parse(s));
}

bool _isDigits(String s) => s.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(s);

/// Folds the Arabic separators onto their ASCII counterparts.
///
/// Applied to the input AND to the grouping separator, so the two are
/// comparable.
String _toAsciiSeparators(String s) => s
    .replaceAll('\u066B', ',') // Arabic decimal separator
    .replaceAll('\u066C', '.') // Arabic thousands separator
    .replaceAll('\u060C', ','); // Arabic comma
