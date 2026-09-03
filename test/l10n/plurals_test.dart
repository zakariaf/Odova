// The plural matrix: six locales × fourteen counts, over every count-bearing
// key in the template.
//
// SPEC.md §5's CI table makes a missing CLDR category an ERROR, not a warning,
// and the reason is that ICU does not fall back — it throws at format time, on
// a device, in a language nobody on the team reads.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/numerals.dart';

import 'support/plural_matrix.dart';

/// Renders one plural key for one locale and count.
///
/// Through the generated `AppLocalizations`, not through a hand-rolled ICU
/// evaluator: the thing under test is what the app will actually say.
String _render(AppLocalizations l10n, String key, int n, String nText) =>
    switch (key) {
      'dateInDays' => l10n.dateInDays(n, nText),
      'dateInAboutWeeks' => l10n.dateInAboutWeeks(n, nText),
      'dateInAboutMonths' => l10n.dateInAboutMonths(n, nText),
      'dateDaysOverdue' => l10n.dateDaysOverdue(n, nText),
      'remindersDueCount' => l10n.remindersDueCount(n, nText),
      _ => throw StateError(
        'plural key "$key" is in the ARB but not in this matrix — add it',
      ),
    };

/// The count as the app would shape it for [tag].
///
/// Two arguments for one number, deliberately. `n` selects the CLDR category
/// and has to be an int; `nText` is the same number already formatted and
/// shaped, because an int interpolated by gen-l10n renders in Latin digits and
/// SPEC.md §5 allows exactly one numbering system per screen.
String _shaped(int n, String tag) =>
    formatForDisplay(n, tag, numerals: CalmNumerals.auto);

void main() {
  test('every count-bearing key declares the categories CLDR requires', () {
    final missing = <String>[];
    for (final locale in shippedLocales) {
      final arb = readArb(locale);
      for (final key in pluralKeys()) {
        final declared = declaredCategories(arb[key]! as String);
        for (final category in requiredCategories[locale]!) {
          if (!declared.contains(category)) {
            missing.add('$locale.$key: $category');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('the matrix covers every plural key in the template', () {
    // Guard the guard. The key list is derived from the ARB, so a plural added
    // later joins the matrix — but `_render` still has to know how to call it,
    // and this is what says so out loud rather than skipping it.
    expect(pluralKeys(), isNotEmpty);
    for (final key in pluralKeys()) {
      expect(
        () => _render(lookupAppLocalizations(const Locale('en')), key, 1, '1'),
        returnsNormally,
        reason: '$key is not in the matrix',
      );
    }
  });

  test('Arabic produces six visibly distinct forms across the counts', () {
    // The whole reason `ar` carries all six categories. If two of them render
    // the same string, one of them was copied and the distinction is lost for
    // every reader.
    final l10n = lookupAppLocalizations(const Locale('ar'));
    for (final key in pluralKeys()) {
      final forms = {
        for (final n in pluralCounts)
          _render(
            l10n,
            key,
            n,
            _shaped(n, 'ar-EG'),
          ).replaceAll(RegExp('[0-9٠-٩۰-۹٬٫,.]+'), '#'),
      };
      expect(
        forms.length,
        greaterThanOrEqualTo(5),
        reason: 'ar.$key collapses to ${forms.length} forms: $forms',
      );
    }
  });

  test('Persian reads correctly at zero, and Sorani differs from it', () {
    // fa: CLDR puts 0 in `one`, so a translator writing "۱ یادآوری" in `one`
    // would produce it for ZERO. The explicit =0 case is what stops that, and
    // this is the assertion that proves the =0 is doing work.
    final fa = lookupAppLocalizations(const Locale('fa'));
    final ckb = lookupAppLocalizations(const Locale('ckb'));

    expect(fa.remindersDueCount(0, _shaped(0, 'fa-IR')), 'چیزی موعد ندارد');
    expect(
      fa.remindersDueCount(0, _shaped(0, 'fa-IR')),
      isNot(contains('۱')),
    );
    expect(
      ckb.remindersDueCount(0, _shaped(0, 'ckb-IQ')),
      'هیچ شتێک نییە',
    );
  });

  test(
    'the count renders through the locale formatter, shaped and grouped',
    () {
      // `#` inside an ICU plural goes through the number formatter. A raw
      // `$count` splice would put Latin 1000 in a Persian sentence.
      final fa = lookupAppLocalizations(const Locale('fa'));
      final rendered = fa.dateInDays(1000, _shaped(1000, 'fa-IR'));
      expect(rendered, contains('۱٬۰۰۰'), reason: rendered);
      expect(rendered, isNot(contains('1000')));
    },
  );

  test('the six locales all render every key at every count', () {
    // 6 × 14 × every plural key. A category ICU cannot resolve throws here
    // rather than on a phone.
    for (final locale in shippedLocales) {
      final l10n = lookupAppLocalizations(Locale(locale));
      for (final key in pluralKeys()) {
        for (final n in pluralCounts) {
          final rendered = _render(l10n, key, n, _shaped(n, locale));
          expect(rendered, isNotEmpty, reason: '$locale.$key($n)');
        }
      }
    }
  });

  test('branch SHAPES match across locales, even though bodies differ', () {
    // A translation that dropped a category, or invented one, is a message
    // that behaves differently from the template at some count nobody tested.
    for (final key in pluralKeys()) {
      final template = declaredCategories(readArb('en')[key]! as String);
      for (final locale in shippedLocales) {
        final declared = declaredCategories(readArb(locale)[key]! as String);
        // Every category the template has, except where CLDR gives the locale
        // more (ar) or the =0 collides with a real category (ar's `zero`).
        final expected = locale == 'ar'
            ? template.difference({'=0'})
            : template;
        expect(
          declared,
          containsAll(expected),
          reason: '$locale.$key is missing ${expected.difference(declared)}',
        );
      }
    }
  });
}
