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
import 'package:odova/ui/calm/calm_dialog.dart';
import 'package:odova/ui/calm/calm_overlay_transition.dart';

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
  sheet,

  /// A blocking decision.
  ///
  /// The barrier dismisses, and the caller maps the null result to its own
  /// NEGATIVE outcome explicitly. SPEC.md §7: no dialog is ever dismissed into
  /// a destructive outcome, and a null falling through to a default is exactly
  /// how one would be.
  dialog;

  /// Whether the surface behind stays visible.
  bool get _translucent => this == sheet || this == dialog;

  /// Builds the page.
  Page<T> page<T>(BuildContext context, GoRouterState state, Widget body) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name ?? state.uri.path,
      child: body,
      opaque: !_translucent,
      barrierDismissible: _translucent,
      barrierColor: _translucent ? CalmColors.of(context).scrim : null,
      // Read here and NOT collapsed for reduced motion: the route holds this
      // number from creation and there is a context, but the transition itself
      // is where a user sees movement — so the collapse happens in the builder
      // below, which runs per frame and can ask the CURRENT MediaQuery.
      transitionDuration: CalmMotion.of(context).base,
      reverseTransitionDuration: CalmMotion.of(context).base,
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
      PageKind.dialog => CalmOverlayTransition(
        rise: 0,
        fadeFrom: 0,
        scaleFrom: kCalmDialogScaleFrom,
        curve: motion.easeSettle,
        reverseCurve: motion.easeIn,
        child: child,
      ),
      PageKind.push => _slide(
        animation,
        const Offset(1, 0),
        motion.easeStandard,
        child,
      ),
      // A sheet leaves faster than it arrives, which is what makes a dismissal
      // feel like a dismissal rather than a rewind. `CalmSheet.show` makes the
      // same choice; this is the routed version of it.
      PageKind.modal || PageKind.sheet => _slide(
        animation,
        const Offset(0, 1),
        motion.easeStandard,
        child,
      ),
    };
  }

  Widget _slide(
    Animation<double> animation,
    Offset from,
    Curve curve,
    Widget child,
  ) => SlideTransition(
    position: animation.drive(
      Tween(begin: from, end: Offset.zero).chain(CurveTween(curve: curve)),
    ),
    child: child,
  );
}
