// Every expense category has a name in every locale.
//
// SPEC.md §10 draws the chips as Insurance · Road tax · Parking · Toll · Fine ·
// Wash · Tyre storage · Accessory · Finance · Other. Before this existed the
// form rendered `tax_registration` — the WIRE value, which is a storage
// detail, in English, on every phone.
//
// §10 also names these as "the longest strings in the app" and says they wrap
// rather than truncate; that is the layout's job, but it starts with them
// being real strings.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/l10n/expense_labels.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('every category is named in ${locale.languageCode}', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(locale);

      for (final category in ExpenseCategory.values) {
        final label = expenseCategoryLabel(l10n, category);
        expect(label.trim(), isNotEmpty, reason: category.wire);
        expect(
          label,
          isNot(contains(category.wire)),
          reason:
              'the wire value is a storage detail; `tax_registration` is not '
              'a word in any of the six languages',
        );
      }
    });
  }

  testWidgets('the ten labels are distinct', (tester) async {
    // A copy-paste that gave two categories the same name would leave the user
    // with two identical chips and no way to tell which they picked.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final labels = ExpenseCategory.values
        .map((c) => expenseCategoryLabel(l10n, c))
        .toSet();

    expect(labels, hasLength(ExpenseCategory.values.length));
  });
}
