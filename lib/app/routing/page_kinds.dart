// Push, modal, sheet and dialog: four visibly different things with four
// different exits, decided once instead of re-decided per screen.
//
// SPEC.md §7 calls the `kind` column binding and does not restate it in the
// edge tables, which only works if the four kinds are mechanical rather than a
// habit. They are: a push keeps the tab bar because it is declared inside a
// branch, and a modal covers it because it is declared with `rootNavigatorKey`.
// Nothing on the screen decides which it is, so no screen can get it wrong.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/ui/calm/calm_pressable.dart' show calmDuration;

/// The two slides, built once per motion rather than once per frame.
///
/// `transitionsBuilder` runs every frame of every push. Building the `Tween`
/// and its `CurveTween` there hands `SlideTransition` a DIFFERENT `Animation`
/// object each time, so it detaches and reattaches its listener per frame on
/// top of the allocations — on the one code path where jank is visible.
///
/// Keyed by the curve rather than held as a top-level constant, because the
/// curve is a theme value and a second theme could carry a different one.
final _horizontal = <Curve, Animatable<Offset>>{};
final _vertical = <Curve, Animatable<Offset>>{};

Animatable<Offset> _fromEnd(CalmMotion motion) => _horizontal.putIfAbsent(
  motion.easeStandard,
  () => Tween(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: motion.easeStandard)),
);

Animatable<Offset> _fromBottom(CalmMotion motion) => _vertical.putIfAbsent(
  motion.easeStandard,
  () => Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).chain(CurveTween(curve: motion.easeStandard)),
);

/// How a destination arrives and how it leaves.
enum PageKind {
  /// A screen inside the current tab. Keeps the tab bar, gets a back control.
  ///
  /// It slides horizontally, which is Material's motion and not Calm's, on
  /// purpose: a user's muscle memory for "back" is built by every other app on
  /// their phone, and this is the one place the platform outranks the design
  /// system.
  push,

  /// A form that takes over the screen.
  ///
  /// Covers the tab bar — mechanically, by being a root-navigator route — and
  /// leaves by swipe-down, Cancel or system back, which SPEC.md §7 says are one
  /// event. `DirtyModalGuard` is what makes them one.
  modal,

  /// A partial-height surface over the screen it came from.
  sheet;

  // There is deliberately no `dialog` member.
  //
  // SPEC.md §7 makes the three global dialogs belong to no feature and gives
  // them no URL — a dialog returns a DECISION and a URL cannot carry one back
  // (`kScreenRoutes` puts all three on the `ScreenDialog` side). So no route
  // ever presents one, and a `PageKind.dialog` would be a second copy of the
  // scrim, the duration and the `CalmOverlayTransition` that `CalmDialog.show`
  // already owns — two definitions of one thing, with no caller to keep them
  // honest.

  /// Whether the surface behind stays visible.
  bool get _translucent => this == sheet;

  /// Builds the page.
  Page<T> page<T>(BuildContext context, GoRouterState state, Widget body) {
    final motion = CalmMotion.of(context);
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name ?? state.uri.path,
      child: body,
      opaque: !_translucent,
      barrierDismissible: _translucent,
      barrierColor: _translucent ? CalmColors.of(context).scrim : null,
      // Collapsed for reduced motion HERE as well as in the builder below.
      // The builder decides what the user sees move; this decides how long the
      // route takes, and they are not the same thing — with the duration left
      // at `motion.base` the outgoing screen stayed mounted for 260ms behind a
      // destination that was already in place. Invisible, because the
      // destination is opaque, and enough to make "the screen behind is gone"
      // untestable without waiting out an animation that is not running.
      transitionDuration: calmDuration(context, motion.base),
      reverseTransitionDuration: calmDuration(context, motion.base),
      transitionsBuilder: (context, animation, secondary, child) =>
          _transition(context, animation, child),
    );
  }

  Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    // `navigation-and-routing` rule 9. A user who asked for no animation is
    // often a user for whom motion is painful, not a user in a hurry, so the
    // destination is simply THERE rather than arriving faster.
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final motion = CalmMotion.of(context);
    return switch (this) {
      PageKind.push => _slide(animation, _fromEnd(motion), child),
      // A sheet leaves faster than it arrives, which is what makes a dismissal
      // feel like a dismissal rather than a rewind. `CalmSheet.show` makes the
      // same choice; this is the routed version of it.
      PageKind.modal || PageKind.sheet => _slide(
        animation,
        _fromBottom(motion),
        child,
      ),
    };
  }

  Widget _slide(
    Animation<double> animation,
    Animatable<Offset> tween,
    Widget child,
  ) => SlideTransition(position: animation.drive(tween), child: child);
}
