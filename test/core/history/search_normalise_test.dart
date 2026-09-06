// What two strings have to look like before they are compared.
//
// SPEC.md §11: "Normalisation before comparison, on BOTH sides: Unicode NFKC;
// case folding; strip combining marks so `Süd` matches `sud`; Arabic-script
// folding … digit folding of Arabic-Indic and Extended Arabic-Indic to ASCII
// so typing `۱۲۳` finds a `123` invoice reference."
//
// Both sides is the load-bearing half. Normalising only the query finds
// nothing typed the other way round, and normalising only the column finds
// nothing at all once the user's keyboard produces a different form of the
// same letter — which every Persian and Arabic keyboard does.
@TestOn('vm')
library;

import 'package:odova/core/history/search_normalise.dart';
import 'package:test/test.dart';

void main() {
  group('Latin', () {
    test('case folds', () {
      expect(normaliseForSearch('SHELL'), normaliseForSearch('shell'));
    });

    test('strips combining marks, so Süd matches sud', () {
      expect(normaliseForSearch('Süd'), normaliseForSearch('sud'));
      expect(normaliseForSearch('Grünstraße'), contains('grun'));
    });

    test('and a decomposed ü matches a precomposed one', () {
      // The same word typed on two keyboards. Without NFKC these are two
      // different strings and neither finds the other.
      expect(normaliseForSearch('Süd'), normaliseForSearch('Süd'));
    });

    test('collapses whitespace rather than matching on it', () {
      expect(normaliseForSearch('  shell   a61 '), 'shell a61');
    });
  });

  group('Arabic script', () {
    test('unifies the alef forms', () {
      // أ إ آ ٱ → ا. A vendor typed with a hamza is the same vendor.
      for (final alef in ['أ', 'إ', 'آ', 'ٱ']) {
        expect(
          normaliseForSearch(
            '$alef'
            'حمد',
          ),
          normaliseForSearch('احمد'),
          reason: alef,
        );
      }
    });

    test('folds ى to ي, ة to ه, and the Persian/Arabic kaf and yeh', () {
      expect(normaliseForSearch('على'), normaliseForSearch('علي'));
      expect(normaliseForSearch('مكة'), normaliseForSearch('مكه'));
      expect(normaliseForSearch('کرمان'), normaliseForSearch('كرمان'));
      expect(normaliseForSearch('یزد'), normaliseForSearch('يزد'));
      expect(normaliseForSearch('ھے'), normaliseForSearch('هي'));
    });

    test('removes tatweel and harakat', () {
      expect(normaliseForSearch('شـــركة'), normaliseForSearch('شركة'));
      expect(normaliseForSearch('شَرِكَة'), normaliseForSearch('شركة'));
    });
  });

  group('digits', () {
    test('folds Arabic-Indic and Extended Arabic-Indic to ASCII', () {
      // §11's reason: "so typing `۱۲۳` finds a `123` invoice reference."
      expect(normaliseForSearch('۱۲۳'), '123');
      expect(normaliseForSearch('١٢٣'), '123');
    });

    test('so a Persian query finds a Latin invoice reference', () {
      expect(
        normaliseForSearch('RE-۲۰۲۶'),
        normaliseForSearch('re-2026'),
      );
    });
  });

  test('normalising twice changes nothing', () {
    // Idempotence, because both sides are normalised and one of them — the
    // column expression — may be normalised again by a later query.
    for (final input in ['Süd', 'أحمد', '۱۲۳', 'Shell  A61', 'مكة']) {
      final once = normaliseForSearch(input);
      expect(normaliseForSearch(once), once, reason: input);
    }
  });

  test('an empty query normalises to empty', () {
    expect(normaliseForSearch(''), '');
    expect(normaliseForSearch('   '), '');
  });
}
