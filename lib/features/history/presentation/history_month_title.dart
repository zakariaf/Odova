// A month header's words: `September 2026`, `septembre 2026`, `مهر ۱۴۰۴`.
//
// SPEC.md §11 fixes the format as `LLLL y` in the active locale, and §5 fixes
// the calendar it counts in. The two are separate decisions and both matter:
// a Jalali user's headers "read `مهر ۱۴۰۴` and break at ~23 September", and
// §11 says why in one line — "a reading aid in the wrong calendar is worse
// than none."
//
// The year goes through the numeral shaper like every other digit, because §5
// keeps one numbering system active app-wide and a Latin `1405` beside a
// Persian month name is exactly the mixed rendering that rule exists to stop.
import 'package:intl/intl.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/number_format.dart';

/// [key] as a month header reads it.
String historyMonthTitle(MonthKey key, String formatsTag) {
  final year = formatForDisplay(
    key.year,
    formatsTag,
    numerals: CalmNumerals.auto,
    decimalDigits: 0,
    // NO grouping. A year is not a quantity — `2,026` is a formatting bug that
    // reads as a number of things.
    grouped: false,
  );

  return switch (key.calendar) {
    // ICU knows the Gregorian month names for every locale the app ships, so
    // this asks it rather than carrying twelve words six times.
    CalmCalendar.gregorian =>
      '${DateFormat.LLLL(
        numberFormatLocale(formatsTag),
      ).format(DateTime.utc(2000, key.month))} $year',
    // ICU does not do Jalali month names, so `calendar.dart` carries them —
    // and carries them once, beside the converter.
    CalmCalendar.persian => '${jalaliMonthNames[key.month - 1]} $year',
  };
}
