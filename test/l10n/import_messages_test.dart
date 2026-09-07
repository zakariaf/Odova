// SPEC.md §6 §5.2's messages, in six languages, with no jargon in any of them.
//
// The three assertions here are the ones a screen test cannot make: that every
// typed failure and warning HAS a message at all, that none of them leaks the
// vocabulary of the parser that produced them, and that the counted ones
// pluralise in every locale's own categories rather than English's two.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/mapping/record_restore.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/import_message.dart';

const List<String> _locales = ['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

Map<String, Object?> _arb(String locale) =>
    json.decode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

/// One of every failure, so the switch cannot be exhaustive by omission.
const List<ImportFailure> _failures = [
  FileTooLarge(bytes: 213_000_000, limitBytes: 67_108_864),
  CompressedFile(),
  NotUtf8(),
  Truncated(),
  NotValidJson(),
  NotOdova(),
  NotMadeByOdova(),
  TooNew(fileVersion: 2, supportedVersion: 1),
  CorruptVersion(),
  MalformedArray('fillups'),
  TooDeep(depth: 200, limit: 32),
  TooDamaged(readable: 812, total: 1204),
  CannotOpenFile(),
];

const List<ImportWarning> _warnings = [
  ContentHashMismatch(),
  RecordCountMismatch(declared: 1204, found: 1180),
  MissingArray('trips'),
  SkippedRecords([SkippedEntry(array: 'fillups', reason: SkipReason.fuel)]),
  CoercedEnums(3),
  OutOfRangeDates(9),
  OrphanRecords(12),
  UnresolvedLinks(4),
  UnmatchedCorrections(3),
  DuplicateIds(3),
  DroppedRules(4),
  TruncatedStrings(2),
];

Future<AppLocalizations> _l10n(String locale) =>
    AppLocalizations.delegate.load(Locale(locale));

void main() {
  test('every failure and warning has a message in all six locales', () async {
    for (final locale in _locales) {
      final l10n = await _l10n(locale);
      for (final failure in _failures) {
        final message = importFailureMessage(
          l10n,
          failure,
          size: '203 MB',
          readable: '812',
          total: '1,204',
        );
        expect(message, isNotEmpty, reason: '$locale / ${failure.code}');
      }
      for (final warning in _warnings) {
        final message = importWarningMessage(
          l10n,
          warning,
          countText: '12',
          declared: '1,204',
          found: '1,180',
          year: '1990',
        );
        expect(message, isNotEmpty, reason: '$locale / ${warning.code}');
      }
    }
  });

  test('every skip reason and every array has a phrase', () async {
    for (final locale in _locales) {
      final l10n = await _l10n(locale);
      for (final reason in SkipReason.values) {
        for (final array in const [
          'vehicles',
          'reminders',
          'odometer_readings',
          'odometer_corrections',
          'fillups',
          'services',
          'expenses',
          'trips',
        ]) {
          final line = skippedEntryLine(
            l10n,
            SkippedEntry(array: array, reason: reason),
            date: '14 August 2026',
          );
          expect(line, contains('14 August 2026'));
          expect(line, isNotEmpty, reason: '$locale / $array / $reason');
        }
      }
    }
  });

  test('no import message uses the vocabulary of a parser', () async {
    // A string-scan over all six ARBs. The skipped-entry list says "Fill-up,
    // 14 August 2026 — the amount of fuel was missing", and never an
    // identifier or the name of a data structure.
    //
    // `.json` is deliberately NOT on this list even though "JSON" is: the
    // extension is the name the file picker shows the user, which is the
    // opposite of jargon — it is the thing they are looking at. So the scan is
    // case-SENSITIVE for JSON and case-insensitive for the rest.
    const forbiddenAnyCase = [
      'schema',
      'parse',
      'entity',
      'record id',
      'ULID',
      'null',
      'array',
    ];
    final offenders = <String>[];

    for (final locale in _locales) {
      final arb = _arb(locale);
      for (final entry in arb.entries) {
        if (!entry.key.startsWith('import')) continue;
        if (entry.key.startsWith('@')) continue;
        final value = entry.value! as String;
        if (value.contains('JSON')) offenders.add('$locale.${entry.key}: JSON');
        for (final word in forbiddenAnyCase) {
          if (value.toLowerCase().contains(word)) {
            offenders.add('$locale.${entry.key}: $word');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the counted messages carry every category their locale needs', () {
    // ICU throws at FORMAT time for a missing category — on a device, in a
    // language nobody on the team reads — so it is asserted here rather than
    // discovered there.
    const required = {
      'en': ['one', 'other'],
      'de': ['one', 'other'],
      'fr': ['one', 'many', 'other'],
      'fa': ['one', 'other'],
      'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
      'ckb': ['one', 'other'],
    };
    const counted = [
      'importWarnSkipped',
      'importWarnOrphans',
      'importWarnUnmatchedCorrections',
      'importWarnDroppedRules',
      'importWarnCoercedEnums',
      'importWarnOutOfRangeDates',
      'importWarnUnresolvedLinks',
      'importWarnDuplicateIds',
      'importWarnTruncatedStrings',
      'importRecordCount',
    ];

    final missing = <String>[];
    for (final MapEntry(key: locale, value: categories) in required.entries) {
      final arb = _arb(locale);
      for (final key in counted) {
        final value = arb[key];
        expect(value, isA<String>(), reason: '$locale.$key is absent');
        for (final category in categories) {
          if (!RegExp(
            '(^|[^A-Za-z=])$category\\s*\\{',
          ).hasMatch(value! as String)) {
            missing.add('$locale.$key: no "$category"');
          }
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('the six Arabic forms are six DIFFERENT sentences', () async {
    // A translator who filled all six categories with the same string has
    // satisfied the category check and translated nothing. Two is the number
    // that catches it: Arabic's dual is a different word, never a copy of the
    // plural.
    final arb = _arb('ar');
    for (final key in const [
      'importWarnSkipped',
      'importWarnOrphans',
      'importRecordCount',
    ]) {
      final value = arb[key]! as String;
      final forms = RegExp(
        r'(zero|one|two|few|many|other)\{([^{}]*(\{[^{}]*\})?[^{}]*)\}',
      ).allMatches(value).map((m) => m.group(2)).toSet();
      expect(forms.length, greaterThanOrEqualTo(5), reason: key);
    }
  });
}
