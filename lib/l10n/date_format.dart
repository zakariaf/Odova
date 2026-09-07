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
import 'package:odova/l10n/date_locale.dart';
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
  // Defaulted, so every existing caller keeps the locale's own digits. It is
  // a parameter because `settings.units`' preview has to render the numeral
  // system the user is CHOOSING, not the one their locale implies — and a
  // preview with the date in one digit set and the distance beside it in
  // another is the exact confusion the preview exists to remove.
  CalmNumerals numerals = CalmNumerals.auto,
}) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;

  final resolved = resolveCalendar(calendar, formatsTag);
  final parts = projectDate(parsed, resolved, formatsTag);

  if (parts.monthName == null) {
    // ICU owns the word order, the separators and the capitalisation. It also
    // renders Latin digits whatever the locale, so the shaping happens here:
    // without it a Persian user on the Gregorian calendar reads `12 March
    // 2026` beside `۱۴۲٬۳۸۰ کیلومتر`.
    // FOLDED to ASCII, then shaped. `shapeDigits` only maps ASCII into a
    // block, and ICU already renders Persian digits for a `fa` locale — so
    // shaping alone could never turn them back into Latin ones, and a user who
    // chose Latin numerals on a Persian phone read `۱۲ مارس ۲۰۲۶` beside
    // `142,380 km`. `number_format.dart` documents the same order for the same
    // reason.
    return shapeDigits(
      foldDigitsToAscii(
        DateFormat.yMMMMd(dateFormatLocale(formatsTag)).format(parsed),
      ),
      resolveNumerals(numerals, formatsTag),
    );
  }

  String number(int value) => formatForDisplay(
    value,
    formatsTag,
    numerals: numerals,
    decimalDigits: 0,
    grouped: false,
  );

  // Day, month, year — the order all three of these calendars read in. The day
  // is never zero-padded: "Sold 05 March" is a receipt, not a sentence.
  return '${number(parts.day)} ${parts.monthName} ${number(parts.year)}';
}

/// A date without its year — `12 August`, `12. August`, `۱۲ اوت`.
///
/// SPEC.md §10's odometer helper draws the last reading's date this way,
/// beside the delta, because the year is noise on a line whose whole job is
/// "was that a few weeks ago or a few months". `MMMMd` is the ICU skeleton for
/// it, so the day-month ORDER comes from the locale rather than from this
/// file — `August 12` in en-US and `12 August` in en-GB, which is the same
/// decision `formatLongDate` already delegates.
/// [isoDate] as a month and a year — "March 2018".
///
/// SPEC.md §12's ownership span. A purchase DAY is a precision the seller did
/// not offer and the buyer has no use for, and "4 March 2018" invites a
/// question about a date the app cannot defend.
///
/// Through the display calendar like every other date here, so a Persian
/// seller's document reads `اسفند ۱۳۹۶`.
String formatMonthYear(
  String isoDate,
  String formatsTag, {
  CalmCalendar? calendar,
}) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;

  final resolved = resolveCalendar(calendar, formatsTag);
  final parts = projectDate(parsed, resolved, formatsTag);
  final name = parts.monthName;

  // ICU owns the word order for a Gregorian month-year; a projected calendar
  // has already given us the month's name and its own year number.
  if (name == null) {
    return DateFormat.yMMMM(dateFormatLocale(formatsTag)).format(parsed);
  }

  return '$name ${formatForDisplay(
    parts.year,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
    grouped: false,
  )}';
}

/// SPEC.md §10's odometer helper draws the last reading's date this way,
/// beside the delta, because the year is noise on a line whose whole job is
/// "was that a few weeks ago or a few months". `MMMMd` is the ICU skeleton for
/// it, so the day-month ORDER comes from the locale rather than from this
/// file — `August 12` in en-US and `12 August` in en-GB, which is the same
/// decision `formatLongDate` already delegates.
String formatDayMonth(String iso, String formatsTag) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat.MMMMd(dateFormatLocale(formatsTag)).format(parsed);
}

/// A date at its shortest — `2 Sep`, `2. Sep.`, `۲ سپتامبر`.
///
/// SPEC.md §10 draws `log.odometer`'s date as a KEY on the number pad, beside
/// Save, where there is room for about six characters. `MMMd` is the ICU
/// skeleton for it, so the abbreviation and the day-month order are the
/// locale's rather than ours.
String formatShortDayMonth(String iso, String formatsTag) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat.MMMd(dateFormatLocale(formatsTag)).format(parsed);
}

/// A row's date: `Wed 2 Sep`, `mer. 2 sept.`, `چهارشنبه ۲ سپتامبر`.
///
/// SPEC.md §11's rows carry the weekday because the timeline is read for
/// recall — "was that the Saturday I drove to Munich" — and drop the year
/// because the month header above the row already carries it. `MMMEd` is the
/// ICU skeleton for exactly that, so the field ORDER is the locale's.
String formatRowDate(String iso, String formatsTag) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat.MMMEd(dateFormatLocale(formatsTag)).format(parsed);
}

/// A bare year — `2026`, `۲۰۲۶` — with no grouping separator.
///
/// `formatForDisplay` with `grouped: false` and not a raw `int.toString()`:
/// the year is a figure on the screen like any other, and four locales draw
/// their own digits. Grouping is off because `2,026` is not a year.
String formatYear(String isoOrYear, String formatsTag) {
  final year = int.tryParse(isoOrYear.split('-').first);
  if (year == null) return isoOrYear;
  return formatForDisplay(
    year,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
    grouped: false,
  );
}

/// A time of day from minutes past midnight — `09:00`, `۹:۰۰`.
///
/// Through ICU's `jm` skeleton, which is the LOCALE-PREFERRED one: `09:00` in
/// de-DE, `9:00 AM` in en-US. `Hm` is the fixed 24-hour skeleton, and this
/// documented locale-awareness while using it — so an American user opened a
/// time picker offering "9:00 PM" and read `21:00` back on the row beside it.
///
/// The digits are shaped afterwards, because `DateFormat` renders Latin ones
/// and §5 keeps one numbering system active app-wide.
String formatMinutesOfDay(
  int minutes,
  String formatsTag, {
  CalmNumerals numerals = CalmNumerals.auto,
}) {
  final clamped = minutes.clamp(0, 24 * 60 - 1);
  final at = DateTime.utc(2000, 1, 2, clamped ~/ 60, clamped % 60);
  return shapeDigits(
    foldDigitsToAscii(DateFormat.jm(dateFormatLocale(formatsTag)).format(at)),
    resolveNumerals(numerals, formatsTag),
  );
}

/// An ISO-8601 weekday's name — `Monday`, `Montag`, `دوشنبه`.
///
/// From ICU's own symbols rather than from our ARB files, which is the
/// opposite of the rule for UNIT labels and for the same reason: §5 says unit
/// abbreviations are ours because ICU's are wrong for us, and weekday names
/// are exactly what ICU is authoritative about. Six translations of "Monday"
/// would be six chances to disagree with the calendar the user is looking at.
String weekdayName(String formatsTag, int isoWeekday) {
  // 2000-01-03 was a Monday, so `+ isoWeekday - 1` lands on the day asked for
  // without any arithmetic about where a week starts.
  final day = DateTime.utc(2000, 1, 2 + isoWeekday);
  return DateFormat.EEEE(dateFormatLocale(formatsTag)).format(day);
}
