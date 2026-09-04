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
import 'package:odova/l10n/number_format.dart';

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
      'dateDaysAgo' => l10n.dateDaysAgo(n, nText),
      'switcherCount' => l10n.switcherCount(n, nText),
      // The delete dialog's two. `confirmDeleteBody` carries FIVE plurals in
      // one message — SPEC.md §2 forbids assembling a sentence from parts, and
      // five is legal ICU. The matrix drives one of them at a time and pins the
      // other four at 2, which is the category most likely to be forgotten in
      // Arabic and the one a `few`/`many` mistake shows up against.
      'confirmDeleteTitle' => l10n.confirmDeleteTitle('The Golf', n, nText),
      'confirmDeleteBody' => l10n.confirmDeleteBody(
        n,
        nText,
        2,
        '2',
        2,
        '2',
        2,
        '2',
        2,
        '2',
      ),
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

  test('Arabic renders each category distinctly, and zero reads as other', () {
    // The whole reason `ar` carries all six categories: if two of them render
    // the same string, one was copied and the distinction is lost for every
    // reader. But `zero` and `other` SHOULD coincide here, and the count is
    // exact rather than a floor because of it — Arabic takes the singular noun
    // after 0 and after 100, so `خلال ٠ يوم` and `خلال ١٠٠ يوم` are both
    // right and both read `يوم`. A `greaterThanOrEqualTo(5)` hedge passes
    // whether that is grammar or a copy-paste, which is a test that has
    // stopped asserting the thing its name claims.
    final l10n = lookupAppLocalizations(const Locale('ar'));
    final digits = RegExp('[0-9٠-٩۰-۹٬٫,.]+');

    for (final key in pluralKeys()) {
      String render(int n) =>
          _render(l10n, key, n, _shaped(n, 'ar-EG')).replaceAll(digits, '#');

      // Read from the TEMPLATE, not from `ar`. The template decides whether
      // zero gets a sentence of its own; each locale then implements that in
      // whatever category CLDR gives it — `=0` in five of the six, and the
      // real `zero` category in Arabic, which is why reading it from the
      // Arabic file finds `zero` on every key and distinguishes nothing.
      final hasExplicitZero = declaredCategories(
        readArb('en')[key]! as String,
      ).contains('=0');

      // 0 and 100 take the same noun. Asserted, not tolerated — except where
      // the message overrides zero with a sentence of its own ("Nothing due"),
      // which is the entire point of an explicit `=0`.
      if (!hasExplicitZero) {
        expect(
          render(0),
          render(100),
          reason: 'ar.$key: zero should read as other',
        );
      }

      // Every other category is its own form: one, two, few, many, other.
      final distinct = {for (final n in pluralCounts) render(n)};
      expect(
        distinct,
        hasLength(hasExplicitZero ? 6 : 5),
        reason: 'ar.$key rendered ${distinct.length} forms: $distinct',
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
