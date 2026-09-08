// The tab bar has a `Material` of its own.
//
// SPEC.md §7 mounts the bar in `AppShell` as a SIBLING of the navigation
// shell — it belongs to the frame, not to any screen — so it sits outside
// every route and inherits no `Material`. A `Text` with no `Material` ancestor
// renders in Flutter's missing-style treatment: the right glyphs with a yellow
// underline under them.
//
// **This shipped for four epics and no test could see it.** `pumpApp` mounts a
// `MaterialApp`, which supplies one; `test/parity/support/parity_capture.dart`
// met the exact failure when it mounted the bar for its own captures, fixed it
// there, and recorded that "on device the route's own `MaterialPage` supplies
// one" — a sentence that was wrong, in a comment, for four epics. Running the
// app on a simulator is what showed four yellow-underlined labels on every
// screen.
//
// So this test deliberately does NOT use `pumpApp`. It pumps the bar under a
// bare `Directionality` and asserts the widget brings its own — which is the
// only arrangement that can tell the difference.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

void main() {
  testWidgets('the shell wraps its tab bar in a Material', (tester) async {
    // The shell itself needs a router and a database, so this asserts the
    // relationship rather than mounting it: whatever `AppShell` puts around
    // `CalmTabBar`, a `Material` has to be part of it.
    final source = await tester.runAsync(
      () => File(
        'lib/app/routing/app_shell.dart',
      ).readAsString(),
    );

    final bar = source!.indexOf('child: CalmTabBar(');
    expect(bar, greaterThan(0), reason: 'the shell stopped mounting the bar');

    // The 400 characters before it, which is where a wrapper would be.
    final before = source.substring(bar - 400 < 0 ? 0 : bar - 400, bar);
    expect(
      before,
      contains('MaterialType.transparency'),
      reason:
          'CalmTabBar is mounted with no Material above it. On device its four '
          'labels then render with a yellow underline, on every screen.',
    );
  });

  testWidgets('and a bare CalmTabBar really does draw the yellow underline', (
    tester,
  ) async {
    // The other half, and the reason the assertion above is worth having: it
    // proves the failure is real rather than a story about Flutter.
    //
    // It does NOT throw. That is the whole problem — Flutter paints the
    // missing-style treatment and says nothing, so four wrong labels on every
    // screen produced no exception, no failing test and no log line for four
    // epics. The only thing that noticed was a person looking at a simulator.
    for (final wrapped in const [false, true]) {
      // A real `MaterialApp` with NO `Material` under it, which is the shell's
      // own arrangement. `WidgetsApp` installs a sentinel `DefaultTextStyle` —
      // 48pt red monospace, double-underlined in yellow — on the assumption
      // that a route's `Material` will replace it. `CalmTabBar` sets its own
      // colour, size and family with `copyWith`, so those three are right and
      // the DECORATION is inherited: the exact thing the simulator shows.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildCalmTheme(Brightness.light),
          home: wrapped
              ? const Material(
                  type: MaterialType.transparency,
                  child: _Bar(),
                )
              : const _Bar(),
        ),
      );

      final label = tester.renderObject<RenderParagraph>(find.text('Home'));
      final style = label.text.style;

      if (wrapped) {
        expect(
          style?.decoration,
          isNot(TextDecoration.underline),
          reason: 'a Material above it is supposed to fix this',
        );
      } else {
        expect(
          style?.decoration,
          TextDecoration.underline,
          reason:
              'if this stops being underlined, Flutter changed its '
              'missing-style treatment and the assertion above guards nothing',
        );
        expect(style?.decorationColor, const Color(0xFFFFFF00));
      }
    }
  });
}

/// The bar, with the four labels the shell gives it.
class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) => const CalmTabBar(
    index: 0,
    labels: ['Home', 'History', 'Costs', 'Settings'],
    icons: [
      CalmTabIcons.home,
      CalmTabIcons.history,
      CalmTabIcons.costs,
      CalmTabIcons.settings,
    ],
    addLabel: 'Log',
    onChanged: _ignore,
    onAdd: _ignoreVoid,
  );
}

void _ignore(int _) {}
void _ignoreVoid() {}
