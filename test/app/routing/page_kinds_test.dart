// Four kinds, four exits, and the one difference that is mechanical.
//
// SPEC.md §7 calls the `kind` column binding and does not restate it in the
// edge tables. That only works if the kinds are produced by the graph rather
// than by a habit — so the tab-bar difference is asserted by TREE MEMBERSHIP,
// not by a flag on a screen. A screen cannot get it wrong because a screen does
// not decide it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/app_router.dart';
import 'package:odova/app/routing/dirty_modal_guard.dart';
import 'package:odova/app/routing/page_kinds.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../support/source_tree.dart';
import 'shell_harness.dart';

void main() {
  testWidgets('a push keeps the tab bar', (tester) async {
    await pumpShell(tester, Routes.costsFuel);
    expect(find.byType(CalmTabBar), findsOneWidget);
  });

  testWidgets('a modal covers the tab bar', (tester) async {
    // The mechanical difference, and it is produced by the modal being a
    // root-navigator route rather than by anything on the screen.
    await pumpShell(tester, Routes.log(LogType.fillUp));
    expect(find.byType(CalmTabBar), findsNothing);
  });

  testWidgets('every modal route in the graph is on the root navigator', (
    tester,
  ) async {
    // The general form of the test above. Walking the graph rather than
    // checking one screen is what makes the rule hold for the modals EPIC-09
    // onwards adds, none of which exist to be pumped yet.
    const modalPaths = {
      '/log/:type',
      '/vehicle-switcher',
      '/first-run/language',
      '/first-run/vehicle',
    };

    final onRoot = <String>{};
    void walk(List<RouteBase> routes, {required bool insideShell}) {
      for (final route in routes) {
        if (route is GoRoute) {
          if (!insideShell || route.parentNavigatorKey != null) {
            onRoot.add(route.path);
          }
          walk(route.routes, insideShell: insideShell);
        } else if (route is StatefulShellRoute) {
          for (final branch in route.branches) {
            walk(branch.routes, insideShell: true);
          }
        }
      }
    }

    walk(buildRouter().configuration.routes, insideShell: false);
    expect(onRoot.intersection(modalPaths), modalPaths);
  });

  testWidgets('reduced motion collapses every kind to no movement', (
    tester,
  ) async {
    // `navigation-and-routing` rule 9. Asserted mid-transition: the widget must
    // already be at its final position on the first frame, because a user who
    // asked for no animation is often a user for whom motion is painful, not a
    // user in a hurry.
    for (final kind in PageKind.values) {
      // Unmounted between cases: `MaterialApp.router` keeps its first delegate,
      // so without this every kind after the first is measured against `push`.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _TransitionProbe(kind: kind, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      // One frame. The destination must already be in place — not on its way
      // there faster.
      await tester.pump();
      await tester.pump();

      expect(
        tester.getTopLeft(find.text('arrived')),
        Offset.zero,
        reason: '${kind.name} still moved',
      );
    }
  });

  testWidgets('with motion on, a kind that moves is not there yet', (
    tester,
  ) async {
    // The other arm. Without it the test above passes against a build that has
    // no transitions at all, which is a different bug that looks identical.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const _TransitionProbe(kind: PageKind.modal, disableAnimations: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.getTopLeft(find.text('arrived')), isNot(Offset.zero));
    await tester.pumpAndSettle();
  });

  testWidgets('a sheet is partial height and the screen behind stays visible', (
    tester,
  ) async {
    // `opaque: false` is what makes it a sheet rather than a full screen the
    // user has to remember they came from.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const _TransitionProbe(kind: PageKind.sheet, disableAnimations: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('arrived'), findsOneWidget);
    expect(
      find.text('go'),
      findsOneWidget,
      reason: 'the screen behind is gone',
    );
  });

  testWidgets('tapping the scrim dismisses a sheet and a dialog', (
    tester,
  ) async {
    for (final kind in [PageKind.sheet, PageKind.dialog]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _TransitionProbe(kind: kind, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // The barrier is the whole frame minus the surface; the probe's surface
      // is at the top-start, so the bottom-end corner is scrim.
      final frame = tester.getSize(find.byType(MaterialApp));
      await tester.tapAt(Offset(frame.width - 4, frame.height - 4));
      await tester.pumpAndSettle();

      expect(find.text('arrived'), findsNothing, reason: kind.name);
    }
  });

  testWidgets('an opaque kind has no scrim to tap through', (tester) async {
    // The other arm: a push and a modal cover the screen, so there is nothing
    // behind them to tap and nothing to dismiss by tapping. Without this, the
    // test above passes against four translucent kinds.
    for (final kind in [PageKind.push, PageKind.modal]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _TransitionProbe(kind: kind, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('go'), findsNothing, reason: kind.name);
      final frame = tester.getSize(find.byType(MaterialApp));
      await tester.tapAt(Offset(frame.width - 4, frame.height - 4));
      await tester.pumpAndSettle();
      expect(find.text('arrived'), findsOneWidget, reason: kind.name);
    }
  });

  testWidgets('a modal returns to the screen it was opened from', (
    tester,
  ) async {
    await pumpShell(tester, Routes.costsFuel);

    await tester.tap(find.byType(CalmTabFab));
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.log(LogType.fillUp));

    goBack(tester);
    await tester.pumpAndSettle();

    expect(locationOf(tester), Routes.costsFuel);
    expect(
      find.byType(CalmTabBar),
      findsOneWidget,
      reason: 'the tab came back',
    );
  });

  testWidgets('and the scroll position it was opened at', (tester) async {
    // §7 promises the POSITION, not only the screen. A caller scrolled deep
    // into a list who logs a fill-up and comes back to the top has been sent
    // somewhere they did not ask to go. It holds because the caller's route
    // stays MOUNTED under the modal, and it stops holding the moment a modal
    // becomes a `go` instead of a `push` — so it is tested over the mechanism
    // rather than over a screen, because no screen in the app scrolls yet.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const _ScrollingCallerProbe(kind: PageKind.modal));
    await tester.pumpAndSettle();

    tester.widget<Scrollable>(find.byType(Scrollable)).controller!.jumpTo(900);
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('arrived'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scrollable>(find.byType(Scrollable)).controller!.offset,
      900,
    );
  });

  group('the dirty-modal guard', () {
    testWidgets('dismissing a clean modal is silent', (tester) async {
      for (final gesture in DismissGesture.values) {
        final probe = _GuardProbe(dirty: false);
        await tester.pumpWidget(probe.app);
        await tester.pumpAndSettle();

        await probe.dismiss(tester, gesture);

        expect(probe.asked, isFalse, reason: gesture.name);
        expect(probe.popped, isTrue, reason: gesture.name);
      }
    });

    testWidgets('dismissing a dirty modal asks before it pops', (tester) async {
      // Three gestures, and SPEC.md §7 says they are ONE event: swipe-down,
      // Cancel and system back all land here. A guard wired to two of the three
      // loses a user's typing on the third and looks fine in every test that
      // exercises the other two.
      for (final gesture in DismissGesture.values) {
        final probe = _GuardProbe(dirty: true);
        await tester.pumpWidget(probe.app);
        await tester.pumpAndSettle();

        await probe.dismiss(tester, gesture);

        expect(probe.asked, isTrue, reason: gesture.name);
        expect(probe.popped, isFalse, reason: '${gesture.name}: kept editing');
      }
    });

    testWidgets('discarding pops, and drops every draft', (tester) async {
      // §10: Discard drops every SEGMENT's draft, not only the visible one. The
      // guard's contract is one `onDiscard`, so EPIC-11's four-segment log
      // modal inherits it rather than deciding it again per segment.
      final probe = _GuardProbe(dirty: true, answer: true);
      await tester.pumpWidget(probe.app);
      await tester.pumpAndSettle();

      await probe.dismiss(tester, DismissGesture.systemBack);

      expect(probe.discarded, 1);
      expect(probe.popped, isTrue);
    });

    test('lib/features/ contains no PopScope', () {
      // The guard owns it. A second `PopScope` in a feature is a second answer
      // to "what happens on back", and the two will disagree.
      final offenders = <String>[];
      for (final file in dartFilesUnder('lib/features')) {
        if (RegExp(r'\bPopScope\b').hasMatch(sourceWithoutLineComments(file))) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('DirtyModalGuard is the only PopScope outside the shell', () {
      // Two implementations of "what happens on back" is one too many, and the
      // second is always the one a lost draft came from.
      final owners = <String>[];
      for (final file in dartFilesUnder('lib')) {
        if (RegExp('PopScope[<(]').hasMatch(sourceWithoutLineComments(file))) {
          owners.add(file.path);
        }
      }
      expect(owners..sort(), [
        'lib/app/routing/app_shell.dart',
        'lib/app/routing/dirty_modal_guard.dart',
      ]);
    });
  });
}

/// Two screens and a button, so a transition can be watched mid-flight.
class _TransitionProbe extends StatelessWidget {
  const _TransitionProbe({
    required this.kind,
    required this.disableAnimations,
  });

  final PageKind kind;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: TextButton(
                onPressed: () => context.push('/next'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/next',
          pageBuilder: (context, state) => kind.page<void>(
            context,
            state,
            // topStart and SMALL: "did it move" is then
            // `getTopLeft == Offset.zero` rather than a number somebody has to
            // maintain, and the rest of the frame is barrier — which is what a
            // translucent kind has to have for a tap-out to exist at all.
            const Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 120,
                height: 80,
                child: Material(child: Text('arrived')),
              ),
            ),
          ),
        ),
      ],
    );

    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildCalmTheme(Brightness.light),
      ),
    );
  }
}

/// The three ways SPEC.md §7 says a modal is dismissed.
enum DismissGesture { swipeDown, cancel, systemBack }

/// A modal wrapped in the guard, with every decision recorded.
class _GuardProbe {
  _GuardProbe({required this.dirty, this.answer = false});

  /// Whether the fake form has unsaved edits.
  final bool dirty;

  /// What the discard dialog answers when it is opened.
  final bool answer;

  /// Whether the guard asked before popping.
  bool asked = false;

  /// How many times the draft was dropped.
  int discarded = 0;

  /// Whether the modal actually left.
  bool popped = false;

  late final Widget app = MaterialApp(
    theme: buildCalmTheme(Brightness.light),
    home: DirtyModalGuard(
      isDirty: () => dirty,
      onDiscard: () => discarded++,
      confirmDiscard: (context) async {
        asked = true;
        return answer;
      },
      onDismissed: () => popped = true,
      // The Builder is INSIDE the guard on purpose. `DirtyModalGuard.of` walks
      // up from the context it is handed, so a Cancel built from a context
      // above the guard finds nothing — which the guard asserts about rather
      // than silently popping.
      child: Material(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => DirtyModalGuard.of(context).requestDismiss(),
              child: const Text('Cancel'),
            ),
          ),
        ),
      ),
    ),
  );

  /// Performs [gesture] and settles.
  Future<void> dismiss(WidgetTester tester, DismissGesture gesture) async {
    switch (gesture) {
      case DismissGesture.swipeDown:
        await tester.fling(
          find.byType(DirtyModalGuard),
          const Offset(0, 400),
          1200,
        );
      case DismissGesture.cancel:
        await tester.tap(find.text('Cancel'));
      case DismissGesture.systemBack:
        await systemBack();
    }
    await tester.pumpAndSettle();
  }
}

/// A scrolled caller with a modal over it.
///
/// Its own router, because the app's screens are placeholders and none of them
/// scrolls yet — the claim under test is the MECHANISM (the caller stays
/// mounted under a pushed route), not any particular screen.
class _ScrollingCallerProbe extends StatefulWidget {
  const _ScrollingCallerProbe({required this.kind});

  final PageKind kind;

  @override
  State<_ScrollingCallerProbe> createState() => _ScrollingCallerProbeState();
}

class _ScrollingCallerProbeState extends State<_ScrollingCallerProbe> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: Stack(
              children: [
                ListView(
                  controller: _controller,
                  children: const [SizedBox(height: 3000)],
                ),
                // Pinned, not in the list: the caller has to still be tappable
                // after it is scrolled, and a button that scrolls away makes
                // the test about the list rather than about the modal.
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: TextButton(
                    onPressed: () => context.push('/next'),
                    child: const Text('go'),
                  ),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/next',
          pageBuilder: (context, state) => widget.kind.page<void>(
            context,
            state,
            const Material(child: Center(child: Text('arrived'))),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      theme: buildCalmTheme(Brightness.light),
    );
  }
}
