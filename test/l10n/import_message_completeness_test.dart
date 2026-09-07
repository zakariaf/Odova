// Every record type the format has, named in every language.
//
// The three switches that turn an array name into words all ended in a
// catch-all, and one of them lied: `_kindLabel`'s `_ => importKindReadings`
// rendered `odometer_corrections` as "Odometer readings" — two different
// record types under one name, on the screen whose whole job is telling the
// user what is about to change.
//
// A catch-all that returns a real label cannot be caught by reading the code,
// because it compiles and it renders something plausible. This is what catches
// it: the vocabulary is `kBackupArrays`, and every entry has to be named.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/backup/domain/backup_format.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/mapping/record_restore.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/import_message.dart';

const List<String> _locales = ['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

Future<AppLocalizations> _l10n(String tag) =>
    AppLocalizations.delegate.load(Locale(tag));

void main() {
  test('every array has a type word, and no two share one', () async {
    for (final tag in _locales) {
      final l10n = await _l10n(tag);

      final words = <String, String>{
        for (final array in kBackupArrays)
          array: skippedEntryLine(
            l10n,
            SkippedEntry(array: array, reason: SkipReason.incomplete),
          ),
      };

      for (final entry in words.entries) {
        // The raw array name reaching the screen is the fallback, and the
        // fallback means somebody added a record type and not a word for it.
        expect(
          entry.value,
          isNot(contains(entry.key)),
          reason: '$tag: ${entry.key} has no type word',
        );
      }
      // Eight arrays, eight distinct lines. A duplicate is the bug that was
      // there: two types rendering as one.
      expect(
        words.values.toSet(),
        hasLength(kBackupArrays.length),
        reason: tag,
      );
    }
  });

  test('every skip reason has a phrase, in every language', () async {
    for (final tag in _locales) {
      final l10n = await _l10n(tag);

      final phrases = {
        for (final reason in SkipReason.values)
          reason: skippedEntryLine(
            l10n,
            SkippedEntry(array: 'fillups', reason: reason),
          ),
      };

      // Five distinct, not six: `incomplete` is the honest fallback and any
      // future reason lands on it, which is a real answer rather than a wrong
      // label — the six words are a closed vocabulary the restorers choose
      // from, and "part of it was missing" is true of any of them.
      expect(
        phrases.values.toSet(),
        hasLength(SkipReason.values.length),
        reason: tag,
      );
    }
  });
}
