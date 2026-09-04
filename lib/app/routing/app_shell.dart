// The frame: four tabs, four stacks, and a + in the middle.
//
// SPEC.md §7. The bar itself is EPIC-03's `CalmTabBar` and this file adds
// nothing to its geometry — it supplies the four labels, the current index and
// what each tap does, and that is all a shell should be. Every question about
// where the + sits, how tall a slot is or what an active label weighs is
// answered in `lib/ui/calm/calm_scaffold.dart`, once, for all 28 screens.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

/// The four tabs and the docked central `+`.
class AppShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// go_router's handle on the four branches.
  ///
  /// It owns the `IndexedStack`, which is what makes each tab keep its own
  /// stack: switching tabs moves the index, it does not rebuild the branch
  /// from its root.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        Positioned.fill(child: navigationShell),
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
            // Task 8.3 owns what a tap on the CURRENT tab does. Until then it
            // lands where the branch already is — `goBranch`'s default — rather
            // than resetting to the root, because a reset that arrives before
            // its tests is a reset nobody proved.
            onChanged: navigationShell.goBranch,
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
