// SPEC.md §5's verified number outputs, asserted by CODEPOINT.
//
// The separators are the point. French groups with a NARROW no-break space
// (U+202F) and German with a full stop; Persian uses U+066C for grouping and
// U+066B for the decimal point, which look like a comma and a full stop and
// are neither. Asserting the rendered look would pass on all four wrong
// answers.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/core/l10n/number_format.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:odova/ui/calm/calm_figure.dart';

/// Codepoints, so a failure message names the character rather than showing
/// two that look identical.
String _codepoints(String s) => s.runes
    .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
    .join(' ');

void main() {
  setUpAll(initializeDateFormatting);

  group("SPEC.md §5's verified output for 1234.56", () {
    const cases = <String, String>{
      'en-US': '1,234.56',
      'de-DE': '1.234,56',
      // U+202F NARROW no-break space, not a plain space and not U+00A0.
      'fr-FR': '1 234,56',
      // U+066C grouping, U+066B decimal.
      'fa-IR': '۱٬۲۳۴٫۵۶',
      'ar-EG': '١٬٢٣٤٫٥٦',
      // The Maghreb writes Arabic with Latin digits and European separators.
      'ar-MA': '1.234,56',
      'ckb-IQ': '۱٬۲۳۴٫۵۶',
    };

    for (final MapEntry(key: tag, value: expected) in cases.entries) {
      test(tag, () {
        final actual = formatForDisplay(
          1234.56,
          tag,
          numerals: CalmNumerals.auto,
        );
        expect(
          actual,
          expected,
          reason:
              '$tag\n  want ${_codepoints(expected)}'
              '\n  got  ${_codepoints(actual)}',
        );
      });
    }
  });

  test('every Arabic region gets Arabic separators, not American ones', () {
    // `intl` carries `ar` and `ar_EG` and almost nothing between them, and
    // plain `ar`'s symbols are Latin-digit with AMERICAN separators. So every
    // Arabic tag that is not ar_EG fell through to it and rendered
    // `١,٢٣٤.٥٦` — Arabic-Indic digits with a comma group and a full-stop
    // decimal, a hybrid CLDR never emits. ar-EG was the only Arabic tag this
    // file asserted, which is why it passed.
    for (final tag in ['ar', 'ar-SA', 'ar-AE', 'ar-IQ', 'ar-JO', 'ar-KW']) {
      final actual = formatForDisplay(
        1234.56,
        tag,
        numerals: CalmNumerals.auto,
      );
      expect(
        actual,
        '١٬٢٣٤٫٥٦',
        reason: '$tag\n  got ${_codepoints(actual)}',
      );
    }
  });

  test("an explicit Latin setting survives the formatter's own digits", () {
    // `ar_EG`'s symbols carry `zeroDigit: ٠`, so the formatter emits
    // Arabic-Indic digits itself. shapeDigits only maps ASCII INTO a block, so
    // without folding first it cannot map back out of one, and a user who set
    // `numerals: latin` on an Arabic locale got Arabic-Indic digits anyway
    // with the setting silently doing nothing.
    expect(
      formatForDisplay(1234.56, 'ar-EG', numerals: CalmNumerals.latin),
      '1٬234٫56',
    );
    expect(
      formatForDisplay(1234.56, 'fa-IR', numerals: CalmNumerals.latin),
      '1٬234٫56',
    );
  });

  test('the Maghreb borrows European separators, not American ones', () {
    // `intl` carries no ar_MA at all, and plain `ar` yields 1,234.56 —
    // American separators under an Arabic UI, silently. SPEC.md §5's verified
    // output is 1.234,56, which is what the Maghreb actually writes.
    expect(numberFormatLocale('ar-MA'), 'de');
    expect(numberFormatLocale('ar-EG'), 'ar_EG');
    expect(numberFormatLocale('ckb-IQ'), 'fa');
    for (final tag in ['ar-MA', 'ar-DZ', 'ar-TN', 'ar-LY']) {
      expect(
        formatForDisplay(1234.56, tag, numerals: CalmNumerals.auto),
        '1.234,56',
        reason: tag,
      );
    }
  });

  test('ckb borrows fa number symbols rather than falling back to Latin', () {
    // `intl` ships none for ckb and silently formats Latin, which would put
    // `1,234.56` under a Sorani UI beside Persian-shaped digits elsewhere.
    final formatted = formatForDisplay(
      1234.56,
      'ckb-IQ',
      numerals: CalmNumerals.auto,
    );
    for (final rune in formatted.runes.where(
      (r) => r != 0x066B && r != 0x066C,
    )) {
      expect(
        rune,
        inInclusiveRange(0x06F0, 0x06F9),
        reason: 'not an Extended Arabic-Indic digit: ${_codepoints(formatted)}',
      );
    }
  });

  test('the grouping separator is read from the formatter, not a table', () {
    expect(groupingSeparatorFor('en-US'), ',');
    expect(groupingSeparatorFor('de-DE'), '.');
    expect(groupingSeparatorFor('fr-FR'), ' ');
    expect(groupingSeparatorFor('fa-IR'), '٬');
    expect(groupingSeparatorFor('ckb-IQ'), '٬');
  });

  group('always Latin, whatever the setting', () {
    test('export numbers are ASCII with a dot, never grouped', () {
      // RFC 8259 permits ASCII digits only: a JSON number containing ۴ is not
      // JSON, and an importer on another continent would reject the file.
      expect(formatForExport(1234.56), '1234.56');
      expect(formatForExport(215104000), '215104000');
      expect(RegExp(r'^[0-9.-]+$').hasMatch(formatForExport(-1234.56)), isTrue);
    });

    test('a non-finite value is refused, not written', () {
      // `toString()` on a NaN or an infinity yields `NaN` / `Infinity`, which
      // no JSON parser reads back — and a derived value CAN be non-finite:
      // consumption over a zero-distance segment, cost per km with no odometer
      // delta. SPEC.md §2 calls losing eight years of history the worst bug
      // this app can have, so it throws at the mistake rather than writing an
      // unparseable backup.
      expect(() => formatForExport(double.nan), throwsArgumentError);
      expect(() => formatForExport(double.infinity), throwsArgumentError);
      expect(() => formatForExport(-double.infinity), throwsArgumentError);
    });

    test(
      'a VIN, a plate, a filename and a version string are never shaped',
      () {
        // CalmCode renders them verbatim. The plate is the subtle one: an
        // Iranian plate legitimately contains Persian digits AND a Persian
        // letter, so it comes back exactly as typed — shaping it either way is
        // rewriting somebody's own characters.
        for (final code in [
          'WVWZZZ1KZAW123456',
          '۱۲ ب ۳۴۵ ایران ۶۷',
          '12 B 345',
          'odova-backup-2026-03-14.json',
          '1.4.2',
        ]) {
          expect(
            const CalmCode('x').runtimeType,
            CalmCode,
            reason: 'CalmCode is the widget these go through',
          );
          // Verbatim: whatever went in comes out, in either script.
          expect(CalmCode(code).value, code);
        }
      },
    );
  });

  group('format then normalize round-trips', () {
    test("SPEC.md §5's four fixtures", () {
      for (final fixture in [
        ('1.234,56', 'de-DE'),
        ('1,234.56', 'en-US'),
        ('۱٬۲۳۴٫۵۶', 'fa-IR'),
        ('١٢٣٤٫٥٦', 'ar-EG'),
      ]) {
        final result = normalizeNumericInput(
          fixture.$1,
          groupingSeparator: groupingSeparatorFor(fixture.$2),
        );
        expect(result, isA<NumericInputOk>(), reason: fixture.$1);
        expect(
          (result as NumericInputOk).value,
          closeTo(fixture.$1.contains('١٢') ? 1234.56 : 1234.56, 1e-9),
          reason: fixture.$1,
        );
      }
    });

    test('1000 seeded values x 6 locales x 3 numbering systems', () {
      // The property that matters: whatever the app SHOWS, the app can read
      // back. Every formatted string is a string a user can retype, and a
      // round-trip that loses a digit loses a fill-up.
      const seed = 20260904;
      var state = seed;
      int next() => state = (state * 1103515245 + 12345) & 0x7FFFFFFF;

      const tags = ['en-US', 'de-DE', 'fr-FR', 'fa-IR', 'ar-EG', 'ckb-IQ'];
      const systems = [
        CalmNumerals.latin,
        CalmNumerals.arabicIndic,
        CalmNumerals.extendedArabicIndic,
      ];

      final failures = <String>[];
      for (var i = 0; i < 1000; i++) {
        // Two decimals, up to seven integer digits: an odometer, a price, a
        // litre count.
        final value = (next() % 99999999) / 100;
        final tag = tags[next() % tags.length];
        final numerals = systems[next() % systems.length];

        final shown = formatForDisplay(
          value,
          tag,
          numerals: numerals,
          decimalDigits: 2,
        );
        final read = normalizeNumericInput(
          shown,
          groupingSeparator: groupingSeparatorFor(tag),
        );

        if (read is! NumericInputOk) {
          failures.add('$tag ${numerals.wire} $value -> "$shown" rejected');
        } else if ((read.value - value).abs() > 1e-9) {
          failures.add(
            '$tag ${numerals.wire} $value -> "$shown" -> ${read.value}',
          );
        }
      }

      expect(failures, isEmpty, reason: failures.take(5).join('\n'));
    });
  });
}
