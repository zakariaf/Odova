// Three §17 rules, over real screens, at 100% and 200%.
//
// SPEC.md §17's accessibility gate and per-locale gate. One matrix rather than
// three near-identical harnesses, because the three defects live in the same
// place: a screen pumped at 200% in German either overflows, or announces
// nothing, or has a target a thumb misses — and pumping it three times to ask
// three questions costs three times as much and finds the same screens.
//
// Deliberately NOT all 28 screens. The epic's sweep over every screen is a
// bigger job than this task, and a sweep that pumps a screen needing eight
// repository fakes is a sweep that tests the fakes. These are the screens that
// render with no more than the app's own defaults — which is also why the ones
// missing are named in the progress file rather than quietly absent.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/first_run/presentation/first_run_language_screen.dart';
import 'package:odova/features/settings/presentation/about_screen.dart';
import 'package:odova/features/settings/presentation/licences_screen.dart';

import '../support/a11y_harness.dart';

/// The screens this sweep can pump with the app's own defaults.
final _screens = <String, Widget Function()>{
  'firstrun.language': FirstRunLanguageScreen.new,
  'settings.about': AboutScreen.new,
  'settings.licences': LicencesScreen.new,
};

void main() {
  for (final MapEntry(key: id, value: build) in _screens.entries) {
    // One `testWidgets` per case. An overflow is reported once per
    // RenderObject, so a loop inside a single test hides every failure after
    // the first — the exact shape that makes a sweep look clean.
    for (final testCase in a11yMatrix.where(
      (c) => c.locale.languageCode == 'de' || c.locale.languageCode == 'ar',
    )) {
      testWidgets('$id does not overflow at ${testCase.name}', (tester) async {
        await pumpA11y(tester, testCase, build());
        expectNoOverflow(tester);
      });
    }

    testWidgets('$id announces everything it shows', (tester) async {
      await pumpA11y(tester, const A11yCase(), build());
      expectEverythingLabelled(tester);
    });

    testWidgets('$id has no tap target under 48pt', (tester) async {
      await pumpA11y(tester, const A11yCase(), build());
      await expectTapTargets(tester);
    });
  }
}
