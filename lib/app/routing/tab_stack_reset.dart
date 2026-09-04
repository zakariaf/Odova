// Throwing away where the user was, on purpose, exactly twice.
//
// SPEC.md §7 names two events that reset all four tab stacks: switching the
// active vehicle, and finishing an import. Nothing else in the app may. A reset
// is the most destructive thing navigation does — four stacks gone in one call
// — so it has ONE implementation, and `stack_reset_test.dart` greps for its
// callers and names them. Scattered per caller it grows a third that nobody
// argued for.
//
// It is a REQUEST rather than a direct call, because only the shell can do it.
// `GoRouter.go` to a branch's root does NOT empty that branch: go_router keeps
// a match list per branch and restores it, so `go('/')` on a Home branch
// sitting at `/reminders` lands back on `/reminders`. The reset API is
// `StatefulNavigationShell.goBranch(i, initialLocation: true)`, and the shell
// is a widget — so the two callers post a request and `AppShell` applies it.

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A pending reset.
///
/// The tick makes two identical requests two events. Without it, an import
/// immediately after a vehicle switch would be a no-op, because
/// `(selectHome: true) == (selectHome: true)`.
typedef StackReset = ({bool selectHome, int tick});

/// The one way to reset every tab stack.
class TabStackResets extends Notifier<StackReset?> {
  @override
  StackReset? build() => null;

  /// Returns all four tab stacks to their roots.
  ///
  /// [selectHome] is the difference between SPEC.md §7's two rows. Switching
  /// the active vehicle changes WHAT is shown and leaves the user looking at
  /// the same kind of screen, so it keeps the current tab; an import REPLACES,
  /// so every screen in every stack — including the Settings screen the import
  /// was started from — may be showing a record that no longer exists, and it
  /// moves the user to Home.
  void resetAllTabStacks({required bool selectHome}) =>
      state = (selectHome: selectHome, tick: (state?.tick ?? 0) + 1);
}

/// The pending reset, or null.
final tabStackResetProvider = NotifierProvider<TabStackResets, StackReset?>(
  TabStackResets.new,
);

/// Carries out a requested reset on [shell].
///
/// Called by `AppShell` and by nothing else — it needs the live shell, and the
/// live shell exists for exactly as long as a frame does.
///
/// **A frame between each branch, and it is not optional.** go_router stores a
/// branch's stack from the router's match list on the next BUILD, and reads it
/// back on the next `goBranch`. Four synchronous calls therefore collapse into
/// the last one: the router ends up at `/settings`, no build ran in between, and
/// branches 0 to 2 keep exactly the stacks this function was called to throw
/// away. The first version did that and the test caught it — Home was still on
/// `/reminders` after a full reset.
Future<void> applyStackReset(
  StatefulNavigationShell shell, {
  required bool selectHome,
}) async {
  final wasOn = shell.currentIndex;
  for (var index = 0; index < shell.route.branches.length; index++) {
    shell.goBranch(index, initialLocation: true);
    await SchedulerBinding.instance.endOfFrame;
  }
  shell.goBranch(selectHome ? 0 : wasOn, initialLocation: true);
}
