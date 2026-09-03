// SPEC.md §5's numerals table.
//
// The mistake this file exists to prevent is switching on the language subtag:
// `ar-MA` is written with Latin digits and `ar-EG` is not, so a resolver that
// reads "ar" and stops ships Arabic-Indic digits to Morocco.
import 'dart:io';

import 'package:odova/core/l10n/numerals.dart';
import 'package:test/test.dart';

void main() {
  group('resolveNumerals reads the region, not the language', () {
    test('the Maghreb writes Arabic with Latin digits', () {
      for (final tag in ['ar-MA', 'ar-DZ', 'ar-TN', 'ar-LY']) {
        expect(
          resolveNumerals(CalmNumerals.auto, tag),
          CalmNumerals.latin,
          reason: tag,
        );
      }
    });

    test('every other Arabic region writes Arabic-Indic', () {
      for (final tag in ['ar', 'ar-EG', 'ar-SA', 'ar-IQ']) {
        expect(
          resolveNumerals(CalmNumerals.auto, tag),
          CalmNumerals.arabicIndic,
          reason: tag,
        );
      }
    });

    test('fa and ckb write Extended Arabic-Indic', () {
      for (final tag in ['fa', 'fa-IR', 'fa-AF', 'ckb', 'ckb-IQ', 'ckb-IR']) {
        expect(
          resolveNumerals(CalmNumerals.auto, tag),
          CalmNumerals.extendedArabicIndic,
          reason: tag,
        );
      }
    });

    test('the Latin-script three write Latin', () {
      for (final tag in ['en-US', 'de-DE', 'fr-FR', 'pt-BR']) {
        expect(
          resolveNumerals(CalmNumerals.auto, tag),
          CalmNumerals.latin,
          reason: tag,
        );
      }
    });
  });

  test('an explicit setting is never overridden by auto', () {
    // Younger Persian and Gulf users often prefer Latin digits for money and
    // odometer readings, and the setting is how they say so.
    expect(
      resolveNumerals(CalmNumerals.latin, 'fa-IR'),
      CalmNumerals.latin,
    );
    expect(
      resolveNumerals(CalmNumerals.arabicIndic, 'en-US'),
      CalmNumerals.arabicIndic,
    );
  });

  test('the withdrawn NUMERAL name `persian` appears nowhere', () {
    // `persian` is alive as a CALENDAR value and dead as a numeral one, so a
    // blanket grep over lib/ is wrong — it fires on CalmCalendar.persian,
    // which is correct code. The rule is narrower and this states it twice:
    // no CalmNumerals value is spelled that way, and no file that DEFINES a
    // numbering system mentions it.
    expect(
      CalmNumerals.values.map((n) => n.wire),
      isNot(contains('persian')),
    );

    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      // Only where a numbering system is decided. Elsewhere the word is a
      // calendar, a language or a font.
      if (!source.contains('CalmNumerals')) continue;
      if (RegExp("['\"]persian['\"]").hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('the four wire values are exactly what is stored and exported', () {
    expect(CalmNumerals.values.map((n) => n.wire).toList(), [
      'auto',
      'latin',
      'arabic_indic',
      'extended_arabic_indic',
    ]);
  });

  group('shapeDigits', () {
    test('is 1:1 by codepoint and leaves separators alone', () {
      // The separators are NOT shaped here: they are chosen by the formatter,
      // which runs first. Shaping is the last step and it only moves digits.
      const input = '1,234.56';
      final shaped = shapeDigits(input, CalmNumerals.extendedArabicIndic);
      expect(shaped, '۱,۲۳۴.۵۶');
      // Same length, so a live-echoing field needs no caret adjustment.
      expect(shaped.length, input.length);
    });

    test('maps into the right block for each system', () {
      expect(shapeDigits('456', CalmNumerals.extendedArabicIndic), '۴۵۶');
      expect(shapeDigits('456', CalmNumerals.arabicIndic), '٤٥٦');
      expect(shapeDigits('456', CalmNumerals.latin), '456');
    });

    test('leaves everything that is not an ASCII digit alone', () {
      expect(
        shapeDigits('VW Golf TDI 2.0', CalmNumerals.arabicIndic),
        'VW Golf TDI ٢.٠',
      );
    });

    test('asserts on auto', () {
      // `auto` is a stored value, not a rendering decision. Shaping with it
      // would silently draw Latin digits for a Persian user.
      expect(
        () => shapeDigits('1', CalmNumerals.auto),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('foldDigitsToAscii is the inverse of shapeDigits', () {
    for (final numerals in [
      CalmNumerals.latin,
      CalmNumerals.arabicIndic,
      CalmNumerals.extendedArabicIndic,
    ]) {
      const original = '1234567890.5';
      expect(
        foldDigitsToAscii(shapeDigits(original, numerals)),
        original,
        reason: numerals.wire,
      );
    }
  });
}
