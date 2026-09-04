// An absolute date, spelled out.
//
// SPEC.md §8's sold row reads "Sold 12 March 2024", and `vehicleSoldSummary`'s
// own metadata says {date} is "an already-formatted ABSOLUTE date — a relative
// one would read 'Sold Today'". Nothing in the app formatted one until now.
//
// Two sources, and the split is `projectDate`'s: where Odova ships its own
// month table — the Jalali months in Persian and Sorani, and the Arabic
// Gregorian months — the parts are composed here so the numerals go through
// `formatForDisplay`. Everywhere else ICU's own `yMMMMd` is right and
// rewriting it by hand would get German's trailing dot wrong.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/number_format.dart';

void main() {
  // What `bootstrap()` does on the cold-launch path. ICU's date symbols are not
  // compiled in the way its number symbols are, and `DateFormat.yMMMMd('de')`
  // throws until this has run.
  setUpAll(initializeDateFormatting);

  test('the word order is the REGION, which is what SPEC.md §5 asks for', () {
    // SPEC.md §5: formats follow the device region, not the language. The two
    // Englishes are the proof — one reads day-first and the other month-first,
    // and both are correct for the person holding the phone. SPEC's own
    // "12 March 2024" example is the British one.
    //
    // This is also the reason the Latin locales go through ICU rather than a
    // table of ours: a hand-written `'$day $month $year'` would give an
    // American user a date no American writes.
    expect(formatLongDate('2024-03-12', 'en-GB'), '12 March 2024');
    expect(formatLongDate('2024-03-12', 'en-US'), 'March 12, 2024');
    // German's trailing dot after the day and French's lower-case month are
    // the other two things a hand-rolled composition gets wrong.
    expect(formatLongDate('2024-03-12', 'de'), '12. März 2024');
    expect(formatLongDate('2024-03-12', 'fr'), '12 mars 2024');
  });

  test('Persian reads the Jalali date in Persian digits', () {
    // 12 March 2024 is 22 Esfand 1402. The YEAR changes, not just the label —
    // a formatter that shaped the digits and kept 2024 would be a Gregorian
    // date wearing Persian numerals.
    final fa = formatLongDate('2024-03-12', 'fa');
    expect(fa, contains('۱۴۰۲'));
    expect(fa, contains('۲۲'));
    expect(fa, contains('اسفند'));
    expect(fa, isNot(contains('2024')));
  });

  test('Sorani in Iran reads the same calendar in its own month names', () {
    // `ckb-IR` resolves to Jalali (SPEC.md §18 question 9) and `ckb-IQ` does
    // not — the country decides, not the language.
    //
    // The YEAR is asserted through `formatForDisplay` rather than against a
    // literal, because which digits Sorani takes is SPEC.md §18's open
    // question — this pins the calendar, which is settled, without pretending
    // the numeral set is.
    String year(int y, String tag) => formatForDisplay(
      y,
      tag,
      numerals: CalmNumerals.auto,
      decimalDigits: 0,
      grouped: false,
    );
    expect(
      formatLongDate('2024-03-12', 'ckb-IR'),
      contains(year(1402, 'ckb-IR')),
    );
    expect(
      formatLongDate('2024-03-12', 'ckb-IQ'),
      contains(year(2024, 'ckb-IQ')),
    );
    expect(formatLongDate('2024-03-12', 'ckb-IR'), contains('ڕەشەمە'));
  });

  test('Arabic uses its own Gregorian month names', () {
    final ar = formatLongDate('2024-03-12', 'ar');
    expect(ar, contains('مارس'));
    expect(ar, contains('٢٠٢٤'));
  });

  test('every shipped locale formats a date instead of throwing', () {
    // ICU carries no date data for `ckb` at all, and `DateFormat.yMMMMd` throws
    // `Invalid locale` rather than falling back — so a Sorani user in Iraq hit
    // a crash on every screen with a date on it. This is the regression test
    // for that: the loop is over the SHIPPED tags, so a seventh locale cannot
    // be added without someone answering the same question for it.
    for (final tag in [
      'en-GB',
      'en-US',
      'de-DE',
      'de-AT',
      'fr-FR',
      'fr-CA',
      'fa-IR',
      'ar-EG',
      'ar-IQ',
      'ar-MA',
      'ckb-IQ',
      'ckb-IR',
    ]) {
      final formatted = formatLongDate('2024-03-12', tag);
      expect(formatted, isNotEmpty, reason: tag);
      expect(formatted, isNot('2024-03-12'), reason: '$tag fell through raw');
    }
  });

  test('an unparseable date is returned as it was stored', () {
    // A restored backup can carry anything. Showing the raw string is ugly and
    // honest; inventing a date, or rendering an empty line where a date
    // belongs, is neither — SPEC.md §2.
    expect(formatLongDate('not-a-date', 'en'), 'not-a-date');
    expect(formatLongDate('', 'en'), '');
  });

  test('the day is never zero-padded, in any locale', () {
    // "Sold 05 March" is a receipt, not a sentence.
    expect(formatLongDate('2024-03-05', 'en-GB'), startsWith('5 '));
    expect(formatLongDate('2024-03-05', 'de'), startsWith('5. '));
    expect(formatLongDate('2024-03-05', 'fa'), isNot(contains('۰۱۵')));
  });

  test('the calendar can be forced, for a user who chose one', () {
    // `Settings.calendar` overrides the region default, and a Persian speaker
    // who picked Gregorian must get it.
    expect(
      formatLongDate('2024-03-12', 'fa', calendar: CalmCalendar.gregorian),
      contains('۲۰۲۴'),
    );
  });
}
