// Money and units on screen.
//
// SPEC.md §5's money table, asserted by CODEPOINT — German separates its euro
// with a NO-BREAK space and French with one too, and "a space" passes on the
// wrong character every time.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money.dart';
import 'package:odova/l10n/bidi.dart';
import 'package:odova/l10n/money_format.dart';
import 'package:odova/l10n/numerals.dart';
import 'package:odova/l10n/unit_format.dart';

String _codepoints(String s) => s.runes
    .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
    .join(' ');

/// The rendered run with its isolate removed, for comparing against SPEC's
/// table — which prints what a reader sees, not what the layout engine gets.
String _visible(String isolated) => stripBidi(isolated);

void main() {
  group('every amount is one isolate', () {
    test('the run is FSI ... PDI, and the minus is inside it', () {
      // A minus outside the isolate migrates to the far end of the line under
      // RTL, so -1,234.56 reads as 1,234.56- with the sign next to something
      // else entirely.
      final negative = formatMoney(
        const Money.of(-123456, 'EUR'),
        'de-DE',
        numerals: CalmNumerals.auto,
      );
      expect(negative.codeUnitAt(0), 0x2068, reason: _codepoints(negative));
      expect(
        negative.codeUnitAt(negative.length - 1),
        0x2069,
        reason: _codepoints(negative),
      );
      final inside = _visible(negative);
      expect(inside.startsWith('-'), isTrue, reason: _codepoints(inside));
    });
  });

  group("SPEC.md §5's money table", () {
    test('en-US puts the symbol before', () {
      expect(
        _visible(
          formatMoney(
            const Money.of(123456, 'USD'),
            'en-US',
            numerals: CalmNumerals.auto,
          ),
        ),
        r'$1,234.56',
      );
    });

    test('de-DE puts it after, separated by a NO-BREAK space', () {
      final actual = _visible(
        formatMoney(
          const Money.of(123456, 'EUR'),
          'de-DE',
          numerals: CalmNumerals.auto,
        ),
      );
      expect(actual, contains('1.234,56'));
      expect(actual.trimRight().endsWith('€'), isTrue);
      // U+00A0, not U+0020. A plain space lets the symbol wrap onto its own
      // line, which is how an amount ends up looking like two amounts.
      expect(
        actual.runes.contains(0x00A0),
        isTrue,
        reason: _codepoints(actual),
      );
    });

    test(
      'fa-IR with toman divides by ten, drops the decimals and labels it',
      () {
        // 1234.56 rials is 123 tomans — SPEC's table shows ۱٬۲۳۵ تومان for
        // 12345.6 rials, so the rounding is on the toman, not the rial.
        final actual = _visible(
          formatMoney(
            const Money.of(12345, 'IRR'),
            'fa-IR',
            numerals: CalmNumerals.auto,
            display: CalmCurrencyDisplay.toman,
          ),
        );
        expect(actual, endsWith('تومان'));
        expect(actual, contains('۱٬۲۳۵'), reason: _codepoints(actual));
        expect(actual, isNot(contains('.')));
        expect(actual, isNot(contains('٫')));
      },
    );
  });

  group('toman is display only', () {
    test('the stored amount is still IRR minor units', () {
      const money = Money.of(12345, 'IRR');
      // Whatever the display setting says, the integer does not move.
      expect(money.minorUnits, 12345);
      expect(money.currency, 'IRR');
      expect(formatForExport(money.minorUnits), '12345');
    });

    test('IRT appears nowhere in the tree', () {
      // Not an ISO 4217 code. A non-ISO code in a backup would fail the file's
      // own validation, which is why the toman is a formatter branch and not a
      // currency.
      final offenders = <String>[];
      for (final dir in ['lib', 'test']) {
        for (final file in Directory(dir).listSync(recursive: true)) {
          if (file is! File || !file.path.endsWith('.dart')) continue;
          if (file.path.endsWith('money_and_units_test.dart')) continue;
          final source = file
              .readAsLinesSync()
              .where((line) => !line.trimLeft().startsWith('//'))
              .join('\n');
          if (RegExp("['\"]IRT['\"]").hasMatch(source)) {
            offenders.add(file.path);
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });

  test('decimal places come from the ISO minor unit', () {
    expect(currencyDecimals('JPY'), 0);
    // Zero, and the toman path depends on it: dividing by ten is only a
    // rial-to-toman conversion if the minor unit IS the rial. At the default
    // exponent of 2 the same stored integer read a hundredfold apart between
    // the two display modes.
    expect(currencyDecimals('IRR'), 0);
    expect(currencyDecimals('AFN'), 0);
    expect(currencyDecimals('KWD'), 3);
    expect(currencyDecimals('IQD'), 3);
    expect(currencyDecimals('EUR'), 2);
    expect(currencyDecimals('USD'), 2);
    // A dinar rendered with two decimals is out by a factor of ten. The
    // separators are Arabic here and the digits are Latin, which is exactly
    // what `numerals: latin` on an Arabic locale means: the digit SET is the
    // user's setting, the separators are the locale's.
    expect(
      _visible(
        formatMoney(
          const Money.of(1234567, 'IQD'),
          'ar-IQ',
          numerals: CalmNumerals.latin,
        ),
      ),
      contains('1٬234٫567'),
    );
  });

  test('no ARB value puts a currency symbol next to a placeholder', () {
    // Placement, spacing and any RLM belong to the formatter. A translator
    // handed "{amount} €" will move the euro, and they will be right to, and
    // it will be wrong in the other five.
    const symbols = [r'$', '€', '£', '¥', '₽', 'ج.م.', 'د.م.', 'د.ع.', 'تومان'];
    final offenders = <String>[];
    for (final locale in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
      final arb =
          jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
        final value = arb[key]! as String;
        for (final symbol in symbols) {
          if (value.contains(symbol)) offenders.add('$locale.$key: $symbol');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  group('units', () {
    test('a number and its unit are one isolate', () {
      final run = formatWithUnit(
        45.2,
        'لیتر',
        'fa-IR',
        numerals: CalmNumerals.auto,
        decimalDigits: 1,
      );
      expect(run.codeUnitAt(0), 0x2068);
      expect(run.codeUnitAt(run.length - 1), 0x2069);
      // Splitting the number from the label is what puts the unit on the wrong
      // side of the digits.
      expect(_visible(run), '۴۵٫۲ لیتر');
    });

    test("the label is ours, not ICU's", () {
      // ICU renders this as `۴۵٫۲L` — a Latin L, no space.
      final run = _visible(
        formatWithUnit(
          45.2,
          'لیتر',
          'fa-IR',
          numerals: CalmNumerals.auto,
          decimalDigits: 1,
        ),
      );
      expect(run, isNot(contains('L')));
      expect(run, contains('لیتر'));
      expect(run, contains(' '));
    });

    test('mpg (US) and mpg (imp) are distinct units', () {
      // A US gallon is 3.785 L and an imperial gallon is 4.546. Two enum
      // values rather than one plus a flag, so no arithmetic path can treat
      // them as equal.
      expect(
        CalmConsumptionUnit.mpgUs,
        isNot(CalmConsumptionUnit.mpgImperial),
      );
      expect(
        CalmConsumptionUnit.values.map((u) => u.wire).toSet(),
        hasLength(CalmConsumptionUnit.values.length),
      );
      // Only one of the four counts down.
      expect(CalmConsumptionUnit.litresPerHundredKm.higherIsBetter, isFalse);
      expect(CalmConsumptionUnit.mpgUs.higherIsBetter, isTrue);
    });
  });
}
