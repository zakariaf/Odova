// The three global dialogs cannot write, and this asserts the reason rather
// than the symptom.
//
// SPEC.md §7 makes them global: each returns a DECISION and the caller acts on
// it. The first version of this claim used a "repository double that fails the
// test if touched" — a `List<String>` the dialog was never handed, so it came
// back empty for every possible implementation, including one that deleted the
// vehicle. A double a function never receives proves nothing.
//
// So the claim is structural: none of the three takes a port a write could
// travel through, and none of their files imports one.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The three dialog files, and the ports each is allowed to take.
const _dialogs = ['discard_dialog', 'confirm_delete_dialog', 'snooze_dialog'];

/// What a write would have to travel through.
///
/// A repository, a database, a Riverpod handle, or the provider library that
/// reaches all three. A dialog holding any of them could persist a decision
/// before its caller had a chance to refuse it.
const _ports = [
  'Repository',
  'AppDatabase',
  'WidgetRef',
  'ProviderContainer',
  'Ref ',
  'flutter_riverpod',
  'package:drift',
  'data/repositories',
  'data/db',
];

void main() {
  for (final dialog in _dialogs) {
    test('$dialog holds no port a write could travel through', () {
      final source =
          File(
                'lib/ui/dialogs/$dialog.dart',
              )
              .readAsLinesSync()
              .where((l) => !l.trimLeft().startsWith('//'))
              .join('\n');

      for (final port in _ports) {
        expect(
          source,
          isNot(contains(port)),
          reason: '$dialog names "$port" — a decision could be persisted there',
        );
      }
    });
  }

  test('and none of them imports anything outside the UI layer', () {
    // The general form. A port this file has not thought of still has to be
    // imported, and `lib/core/` plus `lib/ui/` plus `lib/l10n/` cannot reach a
    // database.
    const allowed = [
      'package:flutter/',
      'package:odova/core/',
      'package:odova/l10n/',
      'package:odova/theme/',
      'package:odova/ui/',
    ];

    for (final dialog in _dialogs) {
      final imports = RegExp("^import '([^']+)';", multiLine: true)
          .allMatches(File('lib/ui/dialogs/$dialog.dart').readAsStringSync())
          .map((m) => m.group(1)!);

      for (final uri in imports) {
        expect(
          allowed.any(uri.startsWith),
          isTrue,
          reason: '$dialog imports $uri, which is outside the UI layer',
        );
      }
    }
  });
}
