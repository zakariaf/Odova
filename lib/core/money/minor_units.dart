// Reading a typed amount into minor units, with no double on the path.
//
// `NumericInputOk.canonical` is already the ASCII form — an optional `-`,
// digits, at most one `.` — so the conversion is string arithmetic, and string
// arithmetic is the only kind that is exact.
//
// The alternative shipped first and looked harmless: `double.parse(canonical) *
// currency.minorPerMajor`, rounded once. 8,500.005 is 850,000.5 minor units
// and rounds to 850001; as a binary double it is 850000.49999999994 and rounds
// DOWN. So does every amount ending .005, .025, .045, .065 and .085 — the app
// quietly taking half a cent off a number the user typed exactly.
//
// SPEC.md §2: storage is canonical, in minor units. `value-objects-money-and-
// units` says the same thing as a rule: money never travels through a double.
//
// Pure Dart, no Flutter import.
import 'package:odova/core/money/currency.dart';

/// [canonical] as a whole number of [currency]'s minor units, or null.
///
/// [canonical] is `NumericInputOk.canonical` — ASCII, an optional leading `-`,
/// digits and at most one `.`. Anything else returns null rather than a
/// plausible wrong number: an amount the app cannot read exactly is an amount
/// it refuses, the same way `normalizeNumericInput` refuses an ambiguous one.
///
/// More decimals than the currency has are rounded HALF AWAY FROM ZERO on the
/// digit after the last one that fits: `8500.005` in EUR is `850001`, and
/// `-8500.005` is `-850001`. Fewer are padded. A currency with no minor unit
/// at all — JPY, IRR — takes the integer part, rounded the same way.
int? minorUnitsFrom(String canonical, Currency currency) {
  final negative = canonical.startsWith('-');
  final digits = negative ? canonical.substring(1) : canonical;
  if (digits.isEmpty) return null;

  final point = digits.indexOf('.');
  final whole = point == -1 ? digits : digits.substring(0, point);
  final fraction = point == -1 ? '' : digits.substring(point + 1);
  // One `.` at most, and nothing but digits either side. `int.parse` would
  // accept `+5` and ` 5`, and `canonical` is documented to contain neither —
  // but this function is public and its callers will not all be this file.
  if (fraction.contains('.') || !_isDigits(whole) || !_isDigits(fraction)) {
    return null;
  }

  final exponent = currency.exponent;
  // Padded to one MORE digit than fits, because that extra digit is the one
  // the rounding decision reads.
  final padded = fraction.padRight(exponent + 1, '0');
  final kept = padded.substring(0, exponent);
  final decider = padded.codeUnitAt(exponent) - _zero;

  final magnitude = int.tryParse('${whole.isEmpty ? '0' : whole}$kept');
  if (magnitude == null) return null;
  final rounded = decider >= 5 ? magnitude + 1 : magnitude;
  return negative ? -rounded : rounded;
}

const int _zero = 0x30;

bool _isDigits(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit < _zero || unit > _zero + 9) return false;
  }
  return true;
}
