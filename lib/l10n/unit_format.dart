// A number and its unit, as one thing.
//
// SPEC.md §5: unit abbreviations come from OUR translation files, not the
// platform unit formatter. CLDR's short forms are wrong in places — ICU renders
// 45.2 L in fa-IR as `۴۵٫۲L`, a Latin L with no space, and km in ckb-IQ as a
// Latin `km`. ICU formats the number; the label is ours.
// **Not in `lib/core/`, and the purity gate is why.** This joins a number to a unit label for a locale, which
// means it takes `package:intl` — and a domain function that formats has taken
// a locale as a HIDDEN input: the same computation then answers differently in
// Tehran and Toronto. Formatting is a presentation act and lives at the edge.
//
// EPIC-04 moved these into `lib/core/l10n/` on the reasoning that they import
// no Flutter, which was true and not the whole rule. EPIC-06's
// `tools/check_core_purity.sh` caught it on its first run.

import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/number_format.dart';

/// Formats [value] with [label] as a single isolated run.
///
/// One isolate around BOTH, not one around the number: `۴۵٫۲ لیتر` split into
/// two runs puts the unit on the wrong side of the digits, and a minus sign
/// outside the isolate migrates to the far end of the line.
String formatWithUnit(
  num value,
  String label,
  String formatsTag, {
  required CalmNumerals numerals,
  int? decimalDigits,
}) {
  final digits = formatForDisplay(
    value,
    formatsTag,
    numerals: numerals,
    decimalDigits: decimalDigits,
  );
  return isolate('$digits $label');
}

/// The fuel-consumption units Odova stores.
///
/// `mpgUs` and `mpgImperial` are DIFFERENT units — a US gallon is 3.785 L and
/// an imperial gallon is 4.546 — and SPEC.md §5 forbids conflating them in
/// storage or on a chart axis. Two enum values rather than one plus a flag, so
/// there is no arithmetic path that can treat them as equal.
enum CalmConsumptionUnit {
  /// Litres per hundred kilometres. Lower is better.
  litresPerHundredKm('l_per_100km'),

  /// Kilometres per litre. Higher is better.
  kmPerLitre('km_per_l'),

  /// Miles per US gallon.
  mpgUs('mpg_us'),

  /// Miles per imperial gallon.
  mpgImperial('mpg_imp');

  const CalmConsumptionUnit(this.wire);

  /// The stored value.
  final String wire;

  /// Whether a larger number means a more efficient vehicle.
  ///
  /// The one place the four differ in a way a chart has to know about: an axis
  /// that puts "better" at the top has to know which way that is.
  bool get higherIsBetter => this != CalmConsumptionUnit.litresPerHundredKm;
}
