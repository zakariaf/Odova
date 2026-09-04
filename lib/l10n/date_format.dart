// An absolute date, spelled out for a sentence.
//
// SPEC.md §8's sold row reads "Sold 12 March 2024", and `vehicleSoldSummary`'s
// own metadata is explicit that {date} is "an already-formatted ABSOLUTE date —
// a relative one would read 'Sold Today'". Nothing formatted one until the
// garage needed it.
//
// **Two sources, split exactly where `projectDate` splits.** Where Odova ships
// its own month table — the Jalali months in Persian and in Sorani, and the
// Arabic Gregorian months — the parts are composed here, so the day and the
// year go through `formatForDisplay` and come out in the active numbering
// system. Everywhere else ICU's `yMMMMd` is the right answer and composing by
// hand would drop German's trailing dot after the day and upper-case the French
// month.
//
// The year is formatted UNGROUPED. "1,402" is a thousand four hundred and two,
// not a year, and `number_format.dart` carries the flag for exactly this.
import 'package:intl/intl.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/number_format.dart';

/// [isoDate] — a stored `YYYY-MM-DD` — as a spelled-out date in [formatsTag].
///
/// [calendar] overrides the region default, for a user who chose one in
/// `settings.units`. Null takes whatever `resolveCalendar` says the region
/// reads.
///
/// An unparseable string comes back UNCHANGED. A restored backup can carry
/// anything, and showing the raw value is ugly and honest where inventing a
/// date, or rendering an empty gap where a date belongs, is neither
/// (SPEC.md §2).
String formatLongDate(
  String isoDate,
  String formatsTag, {
  CalmCalendar? calendar,
}) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;

  final resolved = resolveCalendar(calendar, formatsTag);
  final parts = projectDate(parsed, resolved, formatsTag);

  if (parts.monthName == null) {
    // ICU owns the word order, the separators and the capitalisation.
    return DateFormat.yMMMMd(formatsTag).format(parsed);
  }

  String number(int value) => formatForDisplay(
    value,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
    grouped: false,
  );

  // Day, month, year — the order all three of these calendars read in. The day
  // is never zero-padded: "Sold 05 March" is a receipt, not a sentence.
  return '${number(parts.day)} ${parts.monthName} ${number(parts.year)}';
}
