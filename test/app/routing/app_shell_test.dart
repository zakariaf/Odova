// The frame: four tabs that each keep their own stack, and a + in the middle
// that opens the log modal from anywhere.
//
// SPEC.md §7. The two halves of the RTL claim — the order mirrors AND the +
// stays at the horizontal centre — fail independently, so they are asserted
// independently by geometry rather than by "it looked right".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/app_router.dart';
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/app/routing/placeholder_screen.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/source_tree.dart';
import 'shell_harness.dart';

/// The shell route, found by walking the graph rather than by index.
StatefulShellRoute _shellRoute() {
  StatefulShellRoute? found;
  void walk(List<RouteBase> routes) {
    for (final route in routes) {
      if (route is StatefulShellRoute) found = route;
      walk(route.routes);
    }
  }

  walk(buildRouter().configuration.routes);
  return found!;
}

/// Every location a branch is rooted at.
List<String> _branchRoots() => [
  for (final branch in _shellRoute().branches)
    branch.initialLocation ?? _firstPath(branch.routes),
];

String _firstPath(List<RouteBase> routes) =>
    routes.whereType<GoRoute>().first.path;

/// The centre of [finder]'s box on the horizontal axis.
double _centreX(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  return rect.left + rect.width / 2;
}

/// The four tab labels, in the order they are painted left to right.
List<String> _paintedOrder(WidgetTester tester, AppLocalizations l10n) {
  final labels = [
    l10n.tabHome,
    l10n.tabHistory,
    l10n.tabCosts,
    l10n.tabSettings,
  ];
  final placed = [
    for (final label in labels) (label, _centreX(tester, find.text(label))),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in placed) entry.$1];
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AppShell)));

void main() {
  testWidgets('the shell has four branches, rooted at the four tab roots', (
    tester,
  ) async {
    // Fails if anyone adds a fifth. The roots come from `Routes.tabRoots`,
    // which the shell, the depth test and `resetAllTabStacks` all read, so the
    // order lives in one place rather than three that can disagree.
    expect(_branchRoots(), Routes.tabRoots);
  });

  testWidgets('the + is not a branch', (tester) async {
    // SPEC.md §7: a tab is a place you can be; logging is an act that finishes
    // and returns you. A log branch would give it a stack to come back to.
    for (final root in _branchRoots()) {
      expect(root, isNot(startsWith('/log')), reason: root);
    }
  });

  testWidgets('tapping + pushes log.fillup as a modal from every tab', (
    tester,
  ) async {
    for (final root in Routes.tabRoots) {
      await pumpShell(tester, root);

      expect(find.byType(CalmTabBar), findsOneWidget, reason: root);
      await tester.tap(find.byType(CalmTabFab));
      await tester.pumpAndSettle();

      final router = GoRouter.of(
        tester.element(find.byType(PlaceholderScreen)),
      );
      expect(
        router.state.uri.toString(),
        Routes.log(LogType.fillUp),
        reason: 'from $root',
      );
      // Pushed on the ROOT navigator, which is what makes it cover the bar
      // rather than sit inside the tab.
      expect(find.byType(CalmTabBar), findsNothing, reason: 'from $root');

      // And PUSHED, not gone to. SPEC.md §7: logging is an act that finishes
      // and RETURNS you. `context.go` puts the form at the same location with
      // the same bar hidden, so the two are indistinguishable until you try to
      // leave — and then `go` has nothing to go back to and the user is
      // stranded in a modal with no tab bar.
      expect(router.canPop(), isTrue, reason: 'from $root: nothing to pop to');
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), root, reason: 'did not return');
      expect(find.byType(CalmTabBar), findsOneWidget, reason: 'from $root');
    }
  });

  testWidgets('the + opens on the Fill-up segment', (tester) async {
    // Asserted as the route's `type` parameter, not as a widget's state: a
    // default held in a StatefulWidget is a default a deep link bypasses.
    await pumpShell(tester, Routes.home);
    await tester.tap(find.byType(CalmTabFab));
    await tester.pumpAndSettle();

    final screen = tester.widget<PlaceholderScreen>(
      find.byType(PlaceholderScreen),
    );
    expect(screen.screenId, LogType.fillUp.screenId);
  });

  testWidgets('each branch keeps its own stack across a tab switch', (
    tester,
  ) async {
    // The whole reason for `indexedStack`. Without it the Settings stack is
    // rebuilt from its root on the way back and the user loses their place.
    await pumpShell(tester, Routes.settingsUnits);

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.tabHistory));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(AppShell))).state.uri.toString(),
      Routes.history,
    );

    await tester.tap(find.text(l10n.tabSettings));
    await tester.pumpAndSettle();
    expect(
      GoRouter.of(tester.element(find.byType(AppShell))).state.uri.toString(),
      Routes.settingsUnits,
    );
  });

  testWidgets('the bar renders home, history, +, costs, settings in LTR', (
    tester,
  ) async {
    await pumpShell(tester, Routes.home);

    final l10n = _l10n(tester);
    expect(_paintedOrder(tester, l10n), [
      l10n.tabHome,
      l10n.tabHistory,
      l10n.tabCosts,
      l10n.tabSettings,
    ]);
    // The + sits between History and Costs, in the centre slot.
    final fab = _centreX(tester, find.byType(CalmTabFab));
    expect(fab, greaterThan(_centreX(tester, find.text(l10n.tabHistory))));
    expect(fab, lessThan(_centreX(tester, find.text(l10n.tabCosts))));
  });

  testWidgets('the order mirrors in RTL and the + stays centred', (
    tester,
  ) async {
    // SPEC.md §7 states both halves and they fail independently: a bar built
    // from `left`/`right` mirrors nothing, and a + positioned inside its slot
    // rather than in the bar drifts when the slots are unequal.
    await pumpShell(tester, Routes.home, locale: const Locale('fa'));

    final l10n = _l10n(tester);
    expect(_paintedOrder(tester, l10n), [
      l10n.tabSettings,
      l10n.tabCosts,
      l10n.tabHistory,
      l10n.tabHome,
    ]);

    final frame = tester.getRect(find.byType(CalmTabBar));
    expect(
      _centreX(tester, find.byType(CalmTabFab)),
      closeTo(frame.left + frame.width / 2, 1),
    );
  });

  testWidgets('labels are always visible under the icons', (tester) async {
    // No icon-only mode exists to fall into.
    await pumpShell(tester, Routes.home);

    final l10n = _l10n(tester);
    for (final label in [
      l10n.tabHome,
      l10n.tabHistory,
      l10n.tabCosts,
      l10n.tabSettings,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('German and Sorani labels wrap rather than truncate', (
    tester,
  ) async {
    // `Einstellungen` and `ڕێکخستنەکان` are the long ones, and a bar that
    // ellipsises them says nothing at all in the fourth slot.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final locale in [const Locale('de'), const Locale('ckb')]) {
      await pumpShell(
        tester,
        Routes.home,
        locale: locale,
        wrap: (app) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: app,
        ),
      );

      final l10n = _l10n(tester);
      for (final label in [
        l10n.tabHome,
        l10n.tabHistory,
        l10n.tabCosts,
        l10n.tabSettings,
      ]) {
        final text = tester.widget<Text>(find.text(label));
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: '${locale.languageCode}: $label',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.languageCode}: $label overflowed its slot',
        );
      }
    }
  });

  testWidgets('the active tab is signalled by colour and weight together', (
    tester,
  ) async {
    // A bar that signals with colour alone says nothing in a grayscale render
    // and nothing to a user who cannot separate the two hues.
    await pumpShell(tester, Routes.home);

    final l10n = _l10n(tester);
    final active = tester.widget<Text>(find.text(l10n.tabHome)).style!;
    final idle = tester.widget<Text>(find.text(l10n.tabCosts)).style!;

    expect(active.color, isNot(idle.color));
    expect(active.fontWeight, isNot(idle.fontWeight));
  });

  testWidgets('every tab item and the + are hittable across their whole face', (
    tester,
  ) async {
    // Asserted by TAPPING the extremes, not by measuring a box. `CalmPressable`
    // wraps every control in `CalmTapTarget`, which sizes to `max(child, 52)`
    // unconditionally — so a size assertion on the pressable passes whatever
    // the control does, and proves the floor exists rather than that this
    // control reaches it.
    //
    // The + is where it matters. It is drawn overhanging the 62pt bar, and
    // `RenderBox.hitTest` rejects a position outside a box's own size before it
    // ever reaches the child: written the CSS way, as a negative offset inside
    // the bar, the overhanging 18pt of the app's most-pressed control would be
    // dead.
    await pumpShell(tester, Routes.home);

    final l10n = _l10n(tester);
    final circle = tester.getRect(
      find.descendant(
        of: find.byType(CalmTabFab),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(circle.width, greaterThanOrEqualTo(52));
    expect(circle.height, greaterThanOrEqualTo(52));

    for (final point in [
      Offset(circle.center.dx, circle.top + 1),
      Offset(circle.center.dx, circle.bottom - 1),
      Offset(circle.left + 1, circle.center.dy),
      Offset(circle.right - 1, circle.center.dy),
    ]) {
      await pumpShell(tester, Routes.home);
      await tester.tapAt(point);
      await tester.pumpAndSettle();

      final router = GoRouter.of(
        tester.element(find.byType(PlaceholderScreen)),
      );
      expect(
        router.state.uri.toString(),
        Routes.log(LogType.fillUp),
        reason: 'the + is dead at $point',
      );
    }

    // A tab item takes a tap above and below its label, not only on the two
    // lines of type. Measured on the pressable rather than the slot: the slot
    // is 62 and the target inside it is 52, centred — so the outermost 5pt at
    // each edge of a slot is inert. That is within Calm's own 52 floor and is
    // EPIC-03's decision, but it is a real 5pt of dead bar and it is recorded
    // in this epic's progress file for EPIC-17's design pass rather than
    // changed here, where it would be a design-system edit inside a routing
    // task.
    await pumpShell(tester, Routes.home);

    final target = tester.getRect(
      find
          .ancestor(
            of: find.text(l10n.tabSettings),
            matching: find.byType(CalmPressable),
          )
          .first,
    );
    expect(target.height, greaterThanOrEqualTo(52));

    for (final dy in [target.top + 1, target.bottom - 1]) {
      await pumpShell(tester, Routes.home);
      await tester.tapAt(Offset(target.center.dx, dy));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(AppShell))).state.uri.toString(),
        Routes.settings,
        reason: 'the Settings tab is dead at y=$dy',
      );
    }
  });

  testWidgets('MaterialApp.router is mounted exactly once', (tester) async {
    await pumpShell(tester, Routes.home);
    expect(find.byType(MaterialApp), findsOneWidget);

    // And the plain constructor is gone from the source: a `MaterialApp(` left
    // behind would mount a second Navigator that the router knows nothing
    // about, and every `context.go` inside it would silently do nothing.
    final source = sourceWithoutLineComments(
      dartFilesUnder(
        'lib/app',
      ).firstWhere((f) => f.path.endsWith('app.dart')),
    );
    expect(RegExp(r'MaterialApp\(').hasMatch(source), isFalse);
    expect(source, contains('MaterialApp.router('));
  });
}
