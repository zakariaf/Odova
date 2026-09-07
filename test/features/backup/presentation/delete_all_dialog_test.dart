// §13's typed confirmation, in all six languages.
//
// The word is the localised IMPERATIVE shown verbatim in the sentence above
// the field, matched case-insensitively after Unicode normalisation. Six cases,
// because three of the six scripts have no case at all and the matcher has to
// be right in both worlds — a rule written for `DELETE` and tested only in
// English would lock a Kurdish user out of a screen they can read perfectly.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/l10n/folded_name.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/dialogs/confirm_delete_dialog.dart';

import '../../../support/pump_app.dart';

const List<String> _locales = ['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

Future<AppLocalizations> _l10n(String tag) =>
    AppLocalizations.delegate.load(Locale(tag));

const DeleteCounts _counts = (
  fillUps: 900,
  services: 40,
  costs: 2000,
  trips: 60,
  reminders: 6,
);

Future<void> _pumpDialog(WidgetTester tester, String tag) async {
  final l10n = await _l10n(tag);
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ConfirmDeleteDialogBody(
        subject: l10n.backupDeleteWord,
        counts: _counts,
        formatCount: (n) => '$n',
        title: l10n.backupDeleteAllTitle,
        body: l10n.backupDeleteAllBody(
          '3 vehicles',
          '3,006 entries',
          'March 2018',
        ),
        note: l10n.backupDeleteAllNote('30'),
        onChoice: (_) {},
      ),
    ),
    locale: Locale(tag),
  );
}

CalmButton _deleteButton(WidgetTester tester) => tester
    .widgetList<CalmButton>(find.byType(CalmButton))
    .firstWhere((b) => b.variant == CalmButtonVariant.dangerSolid);

void main() {
  for (final tag in _locales) {
    testWidgets('$tag — Delete stays disabled until the word matches', (
      tester,
    ) async {
      await _pumpDialog(tester, tag);
      final l10n = await _l10n(tag);
      final word = l10n.backupDeleteWord;

      expect(_deleteButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'something else');
      await tester.pump();
      expect(_deleteButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), word);
      await tester.pump();
      expect(_deleteButton(tester).onPressed, isNotNull, reason: word);
    });

    testWidgets('$tag — the word is shown verbatim above the field', (
      tester,
    ) async {
      // §13: "the localised imperative shown verbatim in the sentence above
      // the field". A user copies what they see; a prompt that named a
      // different string than the matcher accepts is a lock with no key.
      await _pumpDialog(tester, tag);
      final l10n = await _l10n(tag);

      // `textContaining`, because the subject is wrapped in a first-strong
      // ISOLATE before it goes on screen — SPEC.md §2's bidi rule, so a
      // Latin `DELETE` inside a Persian sentence does not reorder it. The
      // assertion is that the word is there, not that the markers are not.
      expect(
        find.textContaining(l10n.backupDeleteWord),
        findsWidgets,
        reason: tag,
      );
    });
  }

  testWidgets('the match is case-insensitive where the script has case', (
    tester,
  ) async {
    await _pumpDialog(tester, 'de');

    await tester.enterText(find.byType(TextField), 'löschen');
    await tester.pump();

    expect(_deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('surrounding whitespace does not defeat it', (tester) async {
    // A phone keyboard's autocomplete adds a trailing space, and a user who
    // typed the right word being told they did not is the worst version of
    // this control.
    await _pumpDialog(tester, 'en');

    await tester.enterText(find.byType(TextField), '  DELETE ');
    await tester.pump();

    expect(_deleteButton(tester).onPressed, isNotNull);
  });

  test('the six words are six distinct strings', () async {
    // A translator who left the English in place has satisfied every widget
    // test above and translated nothing — the field would accept `DELETE` in
    // Sorani, which is a word that user cannot type.
    final words = <String>{};
    for (final tag in _locales) {
      words.add((await _l10n(tag)).backupDeleteWord);
    }

    // Arabic and Persian share `حذف`, which is correct: it is the same word in
    // both. Five distinct strings across six locales.
    expect(words, hasLength(5));
    expect(words, contains('DELETE'));
  });

  test('every word folds to something a user can actually type', () async {
    // `foldedName` strips bidi marks, folds digits and lowercases. A word that
    // folded to empty would leave the lock permanently shut — the same class
    // of bug as the empty-vehicle-name case the dialog already guards.
    for (final tag in _locales) {
      final word = (await _l10n(tag)).backupDeleteWord;
      expect(foldedName(word), isNotEmpty, reason: tag);
      expect(foldedName(word), foldedName(word.toUpperCase()), reason: tag);
    }
  });
}
