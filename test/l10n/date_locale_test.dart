// The locale a DATE formatter is given, which is not the one a NUMBER
// formatter is given.
//
// `numberFormatLocale` exists to borrow SYMBOLS: it maps `ckb` to `fa` and
// Maghreb Arabic to `de`, because `intl` has no Kurdish number symbols and no
// European-separator Arabic. `calendar.dart` states the principle those
// borrows rest on — "separators are shapes and month names are words."
//
// Feeding those borrows to `DateFormat` imports the donor's WORDS. A Moroccan
// user's history rows came back reading `Mi., 2. Sept.` — German — and a
// Kurdish user's read `چهارشنبه ۲ سپتامبر`, which is Persian.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/l10n/date_format.dart';
import 'package:odova/l10n/date_locale.dart';

void main() {
  // `DateFormat.localeExists` reads the same table `initializeDateFormatting`
  // populates, and throws until it has run. `bootstrap()` runs it on the cold
  // path for exactly this reason.
  setUpAll(initializeDateFormatting);

  group('dateFormatLocale', () {
    test('never borrows a donor language for its words', () {
      // The two borrows `numberFormatLocale` makes, and the whole reason this
      // function exists separately from it.
      expect(dateFormatLocale('ckb-IQ'), isNot('fa'));
      expect(dateFormatLocale('ar-MA'), isNot('de'));
    });

    test('resolves to the same LANGUAGE it was given', () {
      // Which is the property that matters. `intl` carries `de` but not
      // `de_DE`, so the exact tag is not the point — the point is that the
      // words come from the language the user reads.
      for (final (tag, language) in const [
        ('de-DE', 'de'),
        ('fr-FR', 'fr'),
        ('fa-IR', 'fa'),
        ('ar-EG', 'ar'),
      ]) {
        expect(dateFormatLocale(tag), startsWith(language), reason: tag);
      }
    });

    test('falls back to the LANGUAGE when the region is unknown to intl', () {
      expect(dateFormatLocale('de-LI'), startsWith('de'));
    });

    test('falls back to en for a language intl has no data for', () {
      // §5 is explicit that an unsupported device locale gets English words
      // with that region's separators. The words come from here.
      for (final tag in ['bo-CN', 'kab-DZ', 'ceb-PH', 'ii-CN', 'sat-IN']) {
        expect(dateFormatLocale(tag), 'en', reason: tag);
      }
    });
  });

  group('the date functions do not throw on an unsupported device locale', () {
    // A Tibetan-locale phone opening the report used to be a red screen:
    // `DateFormat.yMMMM('bo-CN')` throws `ArgumentError`, and nothing caught
    // it. §5 says such a device gets English words, not a crash.
    for (final tag in ['bo-CN', 'kab-DZ', 'tzm-MA', 'sat-IN']) {
      test(tag, () {
        expect(() => formatMonthYear('2026-09-02', tag), returnsNormally);
        expect(() => formatLongDate('2026-09-02', tag), returnsNormally);
        expect(() => formatRowDate('2026-09-02', tag), returnsNormally);
        expect(() => formatDayMonth('2026-09-02', tag), returnsNormally);
      });
    }
  });

  test('a Maghreb Arabic row date is in ARABIC, not German', () {
    // The measured failure: `Mi., 2. Sept.` on an Arabic phone.
    final row = formatRowDate('2026-09-02', 'ar-MA');

    expect(row, isNot(contains('Mi')));
    expect(
      row.runes.any((r) => r >= 0x0600 && r <= 0x06FF),
      isTrue,
      reason: 'Arabic script, whatever the digits are',
    );
  });

  test('a Kurdish row date is not in Persian', () {
    // `سپتامبر` is the Persian name for September. Kurdish is `ئەیلوول`, and
    // `kurdishGregorianMonthNames` exists to say so.
    expect(formatRowDate('2026-09-02', 'ckb-IQ'), isNot(contains('سپتامبر')));
  });
}
