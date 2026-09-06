// The month header's words, in both calendars.
//
// SPEC.md §11 fixes `LLLL y` in the active locale; §5 fixes the calendar. The
// combination is what makes a Jalali user's headers read `مهر ۱۴۰۴` and break
// at ~23 September — §11: "a reading aid in the wrong calendar is worse than
// none."
@TestOn('vm')
library;

import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/features/history/presentation/history_month_title.dart';
import 'package:test/test.dart';

void main() {
  // ICU's month names come from per-locale data that is loaded, not compiled
  // in. Without this every locale falls back to en_US and the French assertion
  // passes for the wrong reason.
  setUpAll(initializeDateFormatting);

  test('a Gregorian month reads in the active locale', () {
    const september = MonthKey(
      calendar: CalmCalendar.gregorian,
      year: 2026,
      month: 9,
    );

    expect(historyMonthTitle(september, 'en'), 'September 2026');
    expect(historyMonthTitle(september, 'de'), 'September 2026');
    expect(historyMonthTitle(september, 'fr'), 'septembre 2026');
  });

  test('a Jalali month reads in Persian words and Persian digits', () {
    const mehr = MonthKey(
      calendar: CalmCalendar.persian,
      year: 1405,
      month: 7,
    );

    final title = historyMonthTitle(mehr, 'fa');

    expect(title, contains('مهر'));
    expect(
      title,
      isNot(contains('1405')),
      reason: '§5 keeps one numbering system active app-wide',
    );
  });

  test('the year is never grouped', () {
    // `2,026` reads as a quantity of things rather than a year.
    const key = MonthKey(
      calendar: CalmCalendar.gregorian,
      year: 2026,
      month: 1,
    );

    expect(historyMonthTitle(key, 'en'), isNot(contains(',')));
    expect(historyMonthTitle(key, 'de'), isNot(contains('.')));
  });

  group('the regional month tables are used, not a borrowed locale', () {
    // Both branches used to decide for themselves and both were wrong. These
    // are the measured outputs from before the fix.

    test('Maghreb Arabic is in Arabic script, not German', () {
      // Measured: "September 2026". `numberFormatLocale` borrows `de` for the
      // Maghreb because intl has no European-separator Arabic — a SYMBOL
      // borrow, handed to a function that returns WORDS.
      final title = historyMonthTitle(
        const MonthKey(calendar: CalmCalendar.gregorian, year: 2026, month: 9),
        'ar-MA',
      );

      expect(title, isNot(contains('September')));
      expect(
        title.runes.any((r) => r >= 0x0600 && r <= 0x06FF),
        isTrue,
        reason: 'Arabic script',
      );
    });

    test('Kurdish Gregorian uses the Kurdish name, not the Persian one', () {
      // Measured: "سپتامبر" — Persian. `kurdishGregorianMonthNames` has
      // `ئەیلوول`, and exists precisely so this cannot happen.
      final title = historyMonthTitle(
        const MonthKey(calendar: CalmCalendar.gregorian, year: 2026, month: 9),
        'ckb-IQ',
      );

      expect(title, contains(kurdishGregorianMonthNames[8]));
      expect(title, isNot(contains('سپتامبر')));
    });

    test('Kurdish Jalali uses the Kurdish name, not the Persian one', () {
      // Measured: "شهریور ۱۴۰۵" — Persian words on a Kurdish screen, which is
      // the sentence `kurdishJalaliMonthNames`' own doc comment uses.
      final title = historyMonthTitle(
        const MonthKey(calendar: CalmCalendar.persian, year: 1405, month: 6),
        'ckb-IR',
      );

      expect(title, contains(kurdishJalaliMonthNames[5]));
      expect(title, isNot(contains(jalaliMonthNames[5])));
    });

    test(
      'Iraqi Arabic uses the Levantine name the rest of the screen uses',
      () {
        // The header said "سبتمبر" (Gulf) while `formatLongDate` on the same
        // screen said "أيلول" (Levantine) — one month, two names, one screen.
        final title = historyMonthTitle(
          const MonthKey(
            calendar: CalmCalendar.gregorian,
            year: 2026,
            month: 9,
          ),
          'ar-IQ',
        );

        expect(title, contains(arabicMonthNames('ar-IQ')[8]));
      },
    );
  });
}
