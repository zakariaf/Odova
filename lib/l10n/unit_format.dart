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
