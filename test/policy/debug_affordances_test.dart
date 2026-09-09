// Nothing that only makes sense in development ships.
//
// SPEC.md §13 is explicit that debug tools are compiled out rather than hidden
// behind seven taps on a version number — the difference matters because a
// hidden affordance is still present in the binary, and §1's fourth fact is
// that this app holds the only copy of eight years of history. A seeder that
// clears the database is one accidental route away from doing it on a real
// phone.
//
// `eraseDatabaseOnSchemaChange` is named because drift ships it, it is exactly
// one line, and it silently drops every table when a schema version moves. In
// an app whose worst possible bug is losing service history, it is the worst
// possible line.
//
// The two grep tests go through `expectNoBannedPatterns` rather than walking
// `lib/` here. That helper skips the analyzer's excluded directories and the
// generated suffixes, and it FAILS ON AN EMPTY WALK — a hand-rolled walk that
// mis-paths `lib/` passes while proving nothing, which is the shape of gate
// this repo has been bitten by before.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/source_gates.dart';

void main() {
  test('no development-only affordance is compiled into lib/', () {
    expectNoBannedPatterns({
      'eraseDatabaseOnSchemaChange':
          'drops every table when the schema version moves, in an app whose '
          'worst bug is losing history',
      'seedDemoData': 'writes rows nobody asked for; fixtures live under test/',
      'loadFixture': 'a fixture loader in the shipped binary',
      'insertDemo': 'a seeder in the shipped binary',
    });
  });

  testWidgets('the debug banner is off in the app as composed', (tester) async {
    // The TREE, not the source. A `contains('debugShowCheckedModeBanner:
    // false')` tests the implementation of the fix: it breaks on a reformat,
    // and it passes if a second MaterialApp is introduced without the flag.
    // What matters is that no CheckedModeBanner is mounted.
    await pumpApp(tester, const SizedBox.shrink());

    expect(
      find.byType(CheckedModeBanner),
      findsNothing,
      reason: 'the DEBUG ribbon ships across every screenshot',
    );
  });
}
