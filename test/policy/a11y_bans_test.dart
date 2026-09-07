// The one-line ways to make an accessibility failure go away.
//
// SPEC.md §17 treats accessibility as a release blocker. Every name banned here
// converts one into a passing suite in a single line, which is worse than never
// having tested: a red overflow tells somebody a label is clipped at 200%, and
// a swallowed one tells them nothing while looking exactly like success.
//
// Each ban names what it prevents, because a list without reasons is a list
// somebody edits.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';

import '../support/source_tree.dart';

/// What must not appear under `lib/`, and why.
const _bannedInApp = <String, String>{
  // Clamping is the app telling the OS it knows better than the user's own
  // accessibility setting. §17's gate is about 200% being USABLE, not about
  // 200% being prevented.
  'withClampedTextScaling':
      "clamps the user's own text-size setting; §17 requires 200% to work",
  // Deprecated, and worse: a raw factor silently ignores non-linear scaling on
  // newer platforms, so the number in the code stops matching the screen.
  'textScaleFactor':
      'superseded by TextScaler; a raw factor ignores non-linear scaling',
};

/// What must not appear under `test/`, and why.
const _bannedInTests = <String, String>{
  // The two helpers that turn a red overflow green. `expectNoOverflow` READS
  // the pending exception and re-reports it; a helper that discards one is the
  // opposite, and it is indistinguishable from a passing test.
  'ignoreOverflowErrors':
      'discards the failure the 200% lane exists to produce',
};

void main() {
  test('no suppression helper exists under lib/', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      final source = sourceWithoutLineComments(file);
      for (final MapEntry(key: name, value: why) in _bannedInApp.entries) {
        if (source.contains(name)) offenders.add('${file.path}: $name — $why');
      }
    }

    expect(offenders, isEmpty);
  });

  test('no suppression helper exists under test/', () {
    // Scoped to exclude THIS file and the harness, both of which name the bans
    // in order to enforce and document them. A gate that cannot say what it
    // bans is a gate nobody can maintain.
    const explaining = {
      'test/policy/a11y_bans_test.dart',
      'test/support/a11y_harness.dart',
    };

    final offenders = <String>[];
    for (final file in dartFilesUnder('test')) {
      if (explaining.contains(file.path)) continue;
      final source = sourceWithoutLineComments(file);
      for (final MapEntry(key: name, value: why) in _bannedInTests.entries) {
        if (source.contains(name)) offenders.add('${file.path}: $name — $why');
      }
    }

    expect(offenders, isEmpty);
  });

  test('every ban carries a reason', () {
    // The rule that keeps the two maps above from becoming bare lists. A ban
    // nobody explained is a ban the next person deletes when it inconveniences
    // them, and they will be right to.
    for (final entry in [..._bannedInApp.entries, ..._bannedInTests.entries]) {
      expect(
        entry.value,
        isNotEmpty,
        reason: '${entry.key} is banned with no reason given',
      );
      expect(entry.value.length, greaterThan(20), reason: entry.key);
    }
  });

  test('FittedBox shrinks no user-facing label', () {
    // `accessibility-as-code`: shrinking text to fit is how 200% is defeated
    // without anything going red — the label is present, legible to a
    // screenshot, and too small for the person who asked for large text.
    //
    // The allowlist takes PATHS, and each needs a reason in this map. An empty
    // allowlist would be dishonest: the report renderer lays out a fixed-size
    // PDF page, where shrinking is the correct behaviour.
    const allowed = <String, String>{
      'lib/core/report/service_report_writer.dart':
          'a PDF page is a fixed canvas; the reader zooms the document',
    };

    final offenders = <String>[];
    for (final file in dartFilesUnder('lib')) {
      if (allowed.containsKey(file.path)) continue;
      if (sourceWithoutLineComments(file).contains('FittedBox')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'shrink-to-fit defeats 200% without failing anything',
    );
  });
}
