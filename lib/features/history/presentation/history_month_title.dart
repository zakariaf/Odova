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
import 'package:odova/core/l10n/locale_resolution.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/date_locale.dart';
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

  // Through `projectDate`, which already owns every one of these decisions
  // and owns them ONCE, beside the converter. Both branches here used to
  // decide for themselves and both were wrong:
  //
  //   - Gregorian asked ICU with `numberFormatLocale`, which borrows `de` for
  //     Maghreb Arabic and `fa` for Kurdish. Measured: `ar-MA` gave
  //     "September 2026" — Latin script AND Latin digits on an Arabic screen —
  //     and `ckb-IQ` gave "سپتامبر", the Persian name, where
  //     `kurdishGregorianMonthNames` has `ئەیلوول`. `ar-IQ` got the Gulf
  //     "سبتمبر" while `formatLongDate` two lines below used the Levantine
  //     "أيلول", so one screen showed a month two ways.
  //   - Persian hard-coded `jalaliMonthNames`, so a Kurdish user reading a
  //     Jalali calendar got Persian words — which is the exact thing
  //     `kurdishJalaliMonthNames` was added to prevent.
  //
  // `projectDate` returns a null `monthName` only where ICU genuinely is the
  // authority, which is the one case left for `DateFormat` below.
  final parts = projectDate(
    // The month's own first day. `projectDate` converts, so for a Jalali key
    // the DATE must already be in that calendar — which it is: `monthIndex`
    // built the key from a converted date, and `key.month` is Mehr rather
    // than September.
    DateTime.utc(2000, key.calendar == CalmCalendar.persian ? 1 : key.month),
    CalmCalendar.gregorian,
    formatsTag,
  );

  final name = switch (key.calendar) {
    CalmCalendar.persian =>
      (languageOf(formatsTag) == 'ckb'
          ? kurdishJalaliMonthNames
          : jalaliMonthNames)[key.month - 1],
    CalmCalendar.gregorian =>
      parts.monthName ??
          DateFormat.LLLL(
            dateFormatLocale(formatsTag),
          ).format(DateTime.utc(2000, key.month)),
  };

  return '$name $year';
}
