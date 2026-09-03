// SPEC.md §5's `normalizeNumericInput`.
//
// The rule that matters more than the rest: when the string is still ambiguous
// after every deterministic step, this REJECTS it rather than guessing. A wrong
// guess here does not fail — it silently records 15 litres as 1.5 and corrupts
// a consumption history nobody will ever re-derive.
import 'package:odova/core/l10n/numeric_input.dart';
import 'package:test/test.dart';

/// The parsed value, or a failure if it was rejected.
double? _value(String input, {String groupingSeparator = ','}) {
  final result = normalizeNumericInput(
    input,
    groupingSeparator: groupingSeparator,
  );
  return switch (result) {
    NumericInputOk(:final value) => value,
    NumericInputRejected() => null,
  };
}

NumericInputFailure? _failure(String input, {String groupingSeparator = ','}) {
  final result = normalizeNumericInput(
    input,
    groupingSeparator: groupingSeparator,
  );
  return switch (result) {
    NumericInputOk() => null,
    NumericInputRejected(:final failure) => failure,
  };
}

void main() {
  group('folding', () {
    test('each digit block folds to ASCII', () {
      expect(_value('۱۲۳'), 123); // Extended Arabic-Indic
      expect(_value('١٢٣'), 123); // Arabic-Indic
      expect(_value('123'), 123);
    });

    test('the Arabic separators fold', () {
      // U+066B decimal, U+066C thousands, U+060C comma.
      expect(_value('۱٬۲۳۴٫۵۶'), 1234.56);
      expect(_value('١٬٢٣٤٫٥٦'), 1234.56);
    });

    test('bidi controls and every space-as-grouper are stripped', () {
      // Escapes, not the characters: a literal U+202E in source reorders the
      // code a reviewer reads.
      for (final noise in [
        '\u200E', // LRM
        '\u200F', // RLM
        '\u061C', // ALM
        '\u2066', // LRI
        '\u2069', // PDI
        '\u00A0', // NBSP
        '\u202F', // narrow NBSP
        '\u2009', // thin space
        ' ',
      ]) {
        expect(
          _value('1${noise}234'),
          1234,
          reason: noise.codeUnits.map((c) => c.toRadixString(16)).join(),
        );
      }
    });
  });

  group('disambiguating . from ,', () {
    test('both present: the rightmost is the decimal point', () {
      expect(_value('1.234,56'), 1234.56); // de, fr
      expect(_value('1,234.56'), 1234.56); // en
    });

    test('one separator repeated is grouping', () {
      expect(_value('1.234.567'), 1234567);
      expect(_value('1,234,567'), 1234567);
    });

    test('one separator, three digits after it, and the locale groups with '
        'it: grouping', () {
      expect(_value('1,234'), 1234);
      expect(_value('1.234', groupingSeparator: '.'), 1234);
    });

    test('otherwise it is the decimal point', () {
      // German groups with '.', so a comma is decimal: one and a half.
      expect(_value('1,5', groupingSeparator: '.'), 1.5);
      // The case that silently corrupts an amount when digits are folded and
      // separators are not: U+066B is a DECIMAL point, so this is 1.5 and
      // never 15.
      expect(_value('1٫5', groupingSeparator: '.'), 1.5);
      expect(_value('1.5'), 1.5);
    });

    test('a lone separator with three digits that the locale does NOT group '
        'with is still a decimal point', () {
      // English groups with ',', so a dot with three digits after it is a
      // decimal fraction: 1.234, not 1234.
      expect(_value('1.234'), 1.234);
    });
  });

  group('rejection', () {
    test('an irregular grouping is ambiguous, not a best guess', () {
      // SPEC.md's pseudocode stops at "repeated separator, so grouping" and
      // would return 123456. `1,23,456` is Indian grouping, which none of the
      // six locales use — so reading it as anything is a guess. Recorded as a
      // deliberate strengthening in epics/progress/EPIC-04.md.
      expect(_failure('1,23,456'), NumericInputFailure.ambiguous);
      expect(_value('1,23,456'), isNull);
    });

    test('anything outside [0-9 . -] after normalisation is rejected', () {
      expect(_failure('12a3'), NumericInputFailure.notANumber);
      expect(_failure(r'12$'), NumericInputFailure.notANumber);
      expect(_failure('١٢٣ لیتر'), NumericInputFailure.notANumber);
    });

    test('more than one decimal point is rejected', () {
      expect(
        _failure('1.2.3'),
        anyOf(
          NumericInputFailure.tooManyDecimalPoints,
          NumericInputFailure.ambiguous,
        ),
      );
    });

    test('nothing but noise is rejected as empty', () {
      expect(_failure(''), NumericInputFailure.empty);
      expect(_failure('   '), NumericInputFailure.empty);
      expect(_failure('.'), NumericInputFailure.empty);
    });

    test('a rejection carries a code, never a localised string', () {
      // The message a user sees is an ICU message the caller chooses. This is
      // what the caller switches on, and it is stable across six languages.
      final result = normalizeNumericInput('1,23,456');
      expect(result, isA<NumericInputRejected>());
      expect(
        (result as NumericInputRejected).failure,
        isA<NumericInputFailure>(),
      );
    });
  });

  group('negatives', () {
    test('a leading minus survives', () {
      expect(_value('-1,234.56'), -1234.56);
      expect(_value('-۱٬۲۳۴٫۵۶'), -1234.56);
    });
  });

  test("SPEC.md §5's four round-trip fixtures all read as 1234.56", () {
    // The four strings §5 names by name, in testing item 9.
    expect(_value('1.234,56'), 1234.56);
    expect(_value('1,234.56'), 1234.56);
    expect(_value('۱٬۲۳۴٫۵۶'), 1234.56);
    expect(_value('١٢٣٤٫٥٦'), 1234.56);
  });
}
