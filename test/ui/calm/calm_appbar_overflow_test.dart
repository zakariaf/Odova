// The vehicle bar at 200%, with a status pill beside the name.
//
// SPEC.md §9 puts an overdue count beside the vehicle name on Home, and §17
// requires 200% text scale. In German at 2x the pill measures 355pt against
// 358pt of content width — so the bar overflowed by five pixels with the
// vehicle name's `Expanded` already collapsed to nothing, which is a yellow-
// and-black banner over the one screen the app is for.
//
// `accessibility-as-code` forbids the two cheap ways out: a `FittedBox` shrinks
// the type below the size the user asked for, and an `ellipsis` hides the
// count. The bar takes a second line instead, which its `minHeight` already
// allowed for.
//
// Nothing caught this. The parity captures shoot at `TextScaler.noScaling`, and
// Home is not in `test/a11y/screen_sweep_test.dart` — it needs repository
// fakes, which is the same reason 25 screens are outside that sweep.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/a11y_harness.dart';

/// The vehicle bar with a pill, under one case.
Widget bar(String title, String pill) => CalmScaffold(
  appBar: CalmAppBar(
    title: title,
    showVehicleChevron: true,
    onTapVehicle: () {},
    actions: [
      CalmBadge(
        kind: CalmBadgeKind.overdue,
        icon: Icons.circle,
        label: pill,
      ),
    ],
  ),
  children: const [],
);

void main() {
  for (final testCase in a11yMatrix.where((c) => c.textScale == 2.0)) {
    testWidgets('the vehicle bar and its pill fit at ${testCase.name}', (
      tester,
    ) async {
      // The German string, whatever the locale under test: it is the width
      // constraint §13 names, and the bar has to hold the longest thing any of
      // the six can put in it.
      await pumpA11y(
        tester,
        testCase,
        bar('Der Volkswagen Golf VII Variant', '3 überfällig'),
      );

      expectNoOverflow(tester);
    });
  }

  testWidgets('and at the default scale it is still one line', (tester) async {
    // The other half. A bar that solved the overflow by wrapping at every
    // scale would have moved the pill under the name on every screen, and the
    // reference draws them side by side.
    await pumpA11y(tester, const A11yCase(), bar('The Golf', '1 overdue'));

    final title = tester.getRect(find.byType(CalmVehicleTitle));
    final pill = tester.getRect(find.byType(CalmBadge));

    expect(
      pill.top,
      lessThan(title.bottom),
      reason: 'the pill dropped to a second line at the default scale',
    );
  });
}
