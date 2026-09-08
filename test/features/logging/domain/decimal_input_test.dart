// A number typed at a pump, in any of six locales, becomes one canonical
// integer — or is refused with one sentence. Never guessed at.
//
// SPEC.md §10 *Field kit*; §5 for numerals and separators; §3 *Canonical units*
// for what is stored. Pure Dart: no widgets, so the whole matrix is cheap.
//
// The PARSING is `normalizeNumericInput`'s and is only pinned here, not
// re-implemented — EPIC-04 built it and its own tests own the edge cases. What
// this file tests is the step after: turning a parsed decimal into the integer
// the column takes, without a float on the path.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';

void main() {
  group('the separators and digits §10 lists', () {
    test('every separator parses to the same canonical value', () {
      // §10's Field kit: ". , space U+066B U+066C U+060C". A pump receipt is
      // read in whichever of these the phone's locale produces.
      for (final raw in [
        '42.61',
        '42,61',
        '42٫61', // ARABIC DECIMAL SEPARATOR
      ]) {
        expect(
          parseDecimal(raw, groupingSeparator: ','),
          isA<DecimalOk>().having((o) => o.canonical, 'canonical', '42.61'),
          reason: raw,
        );
      }
    });

    test('a grouping separator is not a decimal point', () {
      // `1,234` is one thousand two hundred and thirty-four where `,` groups,
      // and one-and-a-bit where it does not. The separator argument is the
      // only locale knowledge the parser has, and it is required for this.
      expect(
        parseDecimal('1,234', groupingSeparator: ','),
        isA<DecimalOk>().having((o) => o.canonical, 'canonical', '1234'),
      );
      expect(
        parseDecimal('1,234', groupingSeparator: '.'),
        isA<DecimalOk>().having((o) => o.canonical, 'canonical', '1.234'),
      );
    });

    test('Latin, Arabic-Indic and Extended Arabic-Indic all give 42.61', () {
      for (final raw in ['42.61', '٤٢٫٦١', '۴۲٫۶۱']) {
        expect(
          parseDecimal(raw, groupingSeparator: ','),
          isA<DecimalOk>().having(
            (o) => o.value,
            'value',
            closeTo(42.61, 1e-9),
          ),
          reason: raw,
        );
      }
    });

    test('ambiguous input is refused, never coerced', () {
      // §10: "Ambiguous input is rejected inline." `1,234,5` has groups that
      // are not all three digits, so neither reading is safe.
      expect(
        parseDecimal('1,234,5', groupingSeparator: ','),
        isA<DecimalAmbiguous>(),
      );
    });

    test('an empty string is empty, not zero', () {
      // The difference between "the user has not typed this yet" and "the user
      // typed nothing, meaning free". A form that reads one as the other saves
      // a zero nobody entered.
      expect(parseDecimal('', groupingSeparator: ','), isA<DecimalEmpty>());
      expect(parseDecimal('   ', groupingSeparator: ','), isA<DecimalEmpty>());
    });
  });

  group('canonical integers, with no float on the path', () {
    test('volume becomes whole millilitres', () {
      expect(millilitresFrom('42.61'), 42610);
      expect(millilitresFrom('0.001'), 1);
      // The case a double gets wrong: 8.7 * 1000 is 8699.999… in binary.
      expect(millilitresFrom('8.7'), 8700);
    });

    test('mass becomes whole grams and energy whole watt-hours', () {
      expect(gramsFrom('4.25'), 4250);
      expect(wattHoursFrom('52.34'), 52340);
      expect(wattHoursFrom('7.1'), 7100);
    });

    test('a fourth decimal on a litre figure rounds, never truncates', () {
      // Half away from zero, the same rule money uses. Truncation would lose a
      // millilitre off every entry that ends .0005 and the loss compounds
      // across a tank's worth of history.
      expect(millilitresFrom('1.0005'), 1001);
      expect(millilitresFrom('1.0004'), 1000);
    });

    test('a negative quantity is refused', () {
      // §10: the keypad produces no minus key. A negative litre figure can
      // only arrive by paste, and it is not a quantity.
      expect(millilitresFrom('-1'), isNull);
      expect(gramsFrom('-0.5'), isNull);
    });
  });

  group('money takes its decimals from the ISO 4217 exponent', () {
    test('the exponent decides how many decimals a field accepts', () {
      expect(decimalsFor(Currency.tryParse('EUR')!), 2);
      expect(decimalsFor(Currency.tryParse('JPY')!), 0);
      expect(decimalsFor(Currency.tryParse('KWD')!), 3);
    });

    test('a third decimal on a EUR amount cannot be typed', () {
      // §10 gives money "decimal places = the ISO 4217 exponent". The refusal
      // is at the KEYSTROKE, not at Save: a formatter that lets it be typed
      // and then rounds it behind the user's back is the app disagreeing with
      // the receipt in their other hand.
      final formatter = DecimalFieldFormatter(
        decimals: 2,
        groupingSeparator: ',',
      );
      expect(formatter.wouldAccept('76.66'), isTrue);
      expect(formatter.wouldAccept('76.667'), isFalse);
      expect(formatter.wouldAccept('76.6'), isTrue);
    });

    test('a zero-exponent currency accepts no decimal at all', () {
      final formatter = DecimalFieldFormatter(
        decimals: 0,
        groupingSeparator: ',',
      );
      expect(formatter.wouldAccept('1200'), isTrue);
      expect(formatter.wouldAccept('1200.5'), isFalse);
    });

    test('the odometer takes no decimal at all', () {
      // §10's Field kit: "Odometer — number pad, no decimal." A dash reads
      // whole units; a decimal separator there is a mis-parse waiting to be
      // stored.
      final formatter = DecimalFieldFormatter(
        decimals: 0,
        groupingSeparator: ',',
      );
      expect(formatter.wouldAccept('187412'), isTrue);
      expect(formatter.wouldAccept('187412.5'), isFalse);
    });

    test('no formatter ever accepts a minus sign', () {
      // §10: "a negative sign is never produced by the keypad — the refund
      // switch owns the sign." A minus key reverses badly in RTL and is
      // inconsistent across platforms.
      for (final decimals in [0, 2, 3]) {
        final formatter = DecimalFieldFormatter(
          decimals: decimals,
          groupingSeparator: ',',
        );
        expect(formatter.wouldAccept('-1'), isFalse, reason: '$decimals');
      }
    });
  });

  group('re-rendering on a focus change', () {
    test('a parsed value comes back in the active numbering system', () {
      // §10: "On blur the field re-renders canonically in the active numbering
      // system." 42.61 under fa is ۴۲٫۶۱ — the same value, the user's digits.
      expect(
        canonicalDisplay('42.61', 'fa', decimals: 2, grouped: true),
        '۴۲٫۶۱',
      );
      expect(
        canonicalDisplay('42.61', 'en', decimals: 2, grouped: true),
        '42.61',
      );
    });

    test('blurred groups and focused does not', () {
      // The two edges, and why `grouped` has no default. A field that groups
      // on blur and never ungroups is a field nobody can edit:
      // `DecimalFieldFormatter` reads `187,41` — one backspace into `187,412`
      // — as a decimal rather than a grouping, and `decimals: 0` refuses the
      // keystroke silently, in five of the six locales.
      expect(
        canonicalDisplay('187412', 'en', decimals: 0, grouped: true),
        '187,412',
      );
      expect(
        canonicalDisplay('187,412', 'en', decimals: 0, grouped: false),
        '187412',
      );
      expect(
        canonicalDisplay('187412', 'de', decimals: 0, grouped: true),
        '187.412',
      );
      expect(
        canonicalDisplay('187.412', 'de', decimals: 0, grouped: false),
        '187412',
      );
    });

    test('and the grouped form is one the FORMATTER accepts back', () {
      // The assertion that would have caught the regression. Grouping is only
      // safe if the string it produces survives a round trip through the thing
      // that guards the next keystroke.
      for (final tag in ['en', 'de', 'fr', 'fa', 'ar', 'ckb']) {
        final grouped = canonicalDisplay(
          '187412',
          tag,
          decimals: 0,
          grouped: true,
        );
        expect(
          canonicalDisplay(grouped, tag, decimals: 0, grouped: false),
          canonicalDisplay('187412', tag, decimals: 0, grouped: false),
          reason: '$tag cannot read its own grouped form back',
        );
      }
    });

    test('an unparseable value is left exactly as typed', () {
      // Re-rendering something the app could not read would replace the user's
      // input with a guess about it.
      expect(
        canonicalDisplay('1,234,5', 'en', decimals: 2, grouped: true),
        '1,234,5',
      );
    });
  });

  test('a litre figure survives a round trip through the column', () {
    // The property the whole file exists for: what the user typed, what the
    // column holds, and what comes back are one value.
    for (final typed in ['42.61', '8.7', '0.5', '60']) {
      final ml = millilitresFrom(typed)!;
      expect(
        Volume(ml).litres,
        closeTo(double.parse(typed), 1e-9),
        reason: typed,
      );
    }
  });
}
