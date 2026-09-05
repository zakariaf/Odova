// The frame: four tabs, four stacks, and a + in the middle.
//
// SPEC.md §7. The bar itself is EPIC-03's `CalmTabBar` and this file adds
// nothing to its geometry — it supplies the four labels, the current index and
// what each tap does, and that is all a shell should be. Every question about
// where the + sits, how tall a slot is or what an active label weighs is
// answered in `lib/ui/calm/calm_scaffold.dart`, once, for all 28 screens.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/app/routing/tab_reselected.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// The four tabs and the docked central `+`.
class AppShell extends ConsumerWidget {
  /// Creates the shell around [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// go_router's handle on the four branches.
  ///
  /// It owns the `IndexedStack`, which is what makes each tab keep its own
  /// stack: switching tabs moves the index, it does not rebuild the branch
  /// from its root.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // The shell is the only thing that can empty a branch, so the two events
    // SPEC.md §7 allows post a request and this applies it. `listen`, not
    // `watch`: a reset is an event, and watching it would re-apply the last one
    // on every unrelated rebuild of the shell.
    ref.listen(tabStackResetProvider, (previous, next) {
      if (next == null || next == previous) return;
      // Fire and forget: it walks the four branches a frame at a time, and
      // there is nothing here that can wait for it.
      unawaited(
        applyStackReset(navigationShell, selectHome: next.selectHome),
      );
    });

    // `PopScope`, never `WillPopScope`: WillPopScope cannot see a predictive
    // back gesture and cannot say whether the pop actually happened, and
    // predictive back is Android 14's default.
    //
    // Only reached when the active BRANCH has nothing left to pop — the branch
    // Navigator handles its own stack first, and this route sits below it. So
    // by the time it fires the user is at a tab root, and SPEC.md §7 says a
    // tab root that is not Home goes to Home, and Home exits.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(0);
      },
      child: _body(context, ref, l10n),
    );
  }

  /// What a tap on tab [index] does.
  ///
  /// SPEC.md §7's *Tab-root behaviour*, both halves. A tap on a DIFFERENT tab
  /// goes to that tab exactly where it was left — that is what `indexedStack`
  /// is for, and resetting here would scroll History to the top every time the
  /// user came back to it. A tap on the tab you are already on pops it to its
  /// root and scrolls that root to the top; the pop is `initialLocation: true`
  /// and the scroll is a tick the root listens to, because the roots do not
  /// exist yet and their scroll controllers are the feature epics'.
  void _onTab(WidgetRef ref, int index) {
    final reselected = index == navigationShell.currentIndex;
    navigationShell.goBranch(index, initialLocation: reselected);
    if (reselected) {
      ref.read(tabReselectedProvider.notifier).reselect(index);
    }
  }

  Widget _body(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Stack(
      children: [
        // The branch is told a tab bar is under it. The bar belongs to the
        // SHELL, not to any screen — no tab root passes `tabBar:` to
        // `CalmScaffold` — so without this every screen inside a branch
        // believed there was nothing below, and a snackbar shown from one
        // floated 62pt too low: under the bar, with its Undo swallowed by the
        // `+`. The write happened and the recovery window did not exist.
        Positioned.fill(
          child: CalmChromeScope(hasTabBar: true, child: navigationShell),
        ),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: CalmTabBar(
            index: navigationShell.currentIndex,
            labels: [
              l10n.tabHome,
              l10n.tabHistory,
              l10n.tabCosts,
              l10n.tabSettings,
            ],
            icons: const [
              CalmTabIcons.home,
              CalmTabIcons.history,
              CalmTabIcons.costs,
              CalmTabIcons.settings,
            ],
            addLabel: l10n.tabLogA11y,
            onChanged: (index) => _onTab(ref, index),
            // `push` on the ROOT navigator, which is what puts the form over
            // the tab bar instead of inside the tab. `context.push` finds the
            // root because the log route is declared outside the shell.
            onAdd: () => context.push(Routes.log(LogType.fillUp)),
          ),
        ),
      ],
    );
  }
}

/// The four glyphs the reference draws in the bar.
///
/// Held here rather than in `calm_scaffold.dart` because they are this app's
/// four destinations, not part of the design system's vocabulary: a second
/// product built on Calm would have different tabs and the same bar.
///
/// **These are approximations and the first parity check on a tab root will
/// say so.** `design/calm/screens.html` draws four hand-authored SVG paths, and
/// one of them is a problem worth raising rather than copying: the Costs glyph
/// is an arc with two horizontal strokes, which is a euro sign — in an app that
/// ships six locales and stores an ISO 4217 code per vehicle. `payments` is
/// currency-neutral and deliberately not the reference's shape; EPIC-09 either
/// re-shoots the artboard with a neutral glyph or the design decides the euro
/// is intended.
abstract final class CalmTabIcons {
  /// A house.
  static const IconData home = Icons.home_outlined;

  /// A clock face.
  static const IconData history = Icons.schedule_outlined;

  /// Money, without naming a currency.
  static const IconData costs = Icons.payments_outlined;

  /// Sliders.
  static const IconData settings = Icons.tune;
}
