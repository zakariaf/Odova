// No modal in this app can lose a user's typing silently.
//
// SPEC.md §7 states two rules that hold everywhere: dismissing a dirty modal
// opens `dialog.discard`, and dismissing a clean one is silent. It also says
// the three ways out — swipe-down, Cancel and system back — are ONE event. That
// sentence is the whole reason this is a widget rather than a habit: a guard
// wired to two of the three loses a draft on the third, and looks correct in
// every test that exercises the other two.
//
// Every modal wraps in this. `page_kinds_test.dart` asserts `lib/features/`
// holds no `PopScope` of its own, because a second answer to "what happens on
// back" is an answer that will disagree.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps a modal's body and decides what a dismissal means.
class DirtyModalGuard extends StatefulWidget {
  /// Creates the guard.
  const DirtyModalGuard({
    required this.isDirty,
    required this.onDiscard,
    required this.confirmDiscard,
    required this.child,
    super.key,
    this.onDismissed,
  });

  /// Whether there is anything to lose.
  ///
  /// A callback rather than a bool, because the answer changes with every
  /// keystroke and the guard is not rebuilt for any of them.
  final bool Function() isDirty;

  /// Drops the draft.
  ///
  /// SPEC.md §10: Discard drops EVERY segment's draft, not only the visible
  /// one. One callback rather than one per segment, so EPIC-11's four-segment
  /// log modal inherits that rule instead of deciding it again four times.
  final VoidCallback onDiscard;

  /// Asks the user. True discards; false keeps editing.
  ///
  /// Injected so this file does not depend on the dialog, and so a test can
  /// answer without pumping one. Task 8.8 supplies `showDiscardDialog` as the
  /// app's answer.
  final Future<bool> Function(BuildContext context) confirmDiscard;

  /// The modal's body.
  final Widget child;

  /// Called when the modal actually leaves.
  ///
  /// Defaults to popping the enclosing route. A test passes its own so it can
  /// assert the decision without a Navigator.
  final VoidCallback? onDismissed;

  /// The nearest guard, for a Cancel control inside the modal.
  ///
  /// Cancel is one of §7's three gestures and must go through the same code
  /// path as the other two — a Cancel button that calls `Navigator.pop`
  /// directly is the third gesture that loses the draft.
  static DirtyModalGuardState of(BuildContext context) {
    final state = context.findAncestorStateOfType<DirtyModalGuardState>();
    assert(state != null, 'No DirtyModalGuard above this Cancel control');
    return state!;
  }

  @override
  State<DirtyModalGuard> createState() => DirtyModalGuardState();
}

/// The guard's state, reachable through [DirtyModalGuard.of].
class DirtyModalGuardState extends State<DirtyModalGuard> {
  bool _asking = false;

  /// Handles one dismissal, whichever gesture produced it.
  Future<void> requestDismiss() async {
    // Three gestures can arrive while the dialog is already open — a swipe
    // during the fade, a second system back. Without this the user is asked
    // twice and answers the wrong question the second time.
    if (_asking) return;

    if (!widget.isDirty()) {
      _leave();
      return;
    }

    // `try`/`finally`, because the alternative traps the user. If
    // `confirmDiscard` completes with an ERROR — a missing localisation for a
    // locale, a `CalmColors.of` assertion from a guard mounted outside the
    // theme, a dialog that throws during a route transition — a bare
    // `_asking = false` after the await never runs. Every subsequent swipe,
    // Cancel and system back then returns at the guard above, with
    // `canPop: false` over them, and the user is trapped in a modal with no
    // exit but killing the app. That is the failure this file exists to
    // prevent, arriving through the file itself.
    // Caught, not just unwound. If the question cannot be ASKED — a missing
    // localisation for a locale, a `CalmColors.of` assertion from a guard
    // mounted outside the theme, a dialog that throws during a route
    // transition — the answer is KEEP. Discarding on a failure to ask would
    // throw away a draft because the app could not phrase a question about it,
    // and SPEC.md §7's rule that no dismissal is ever the destructive outcome
    // holds for an error as much as for a tap-out.
    //
    // And `finally`, because a bare reset after the await never runs on a
    // throw: `_asking` would stay true, every later swipe, Cancel and system
    // back would return at the guard above with `canPop: false` over them, and
    // the user would be trapped in the modal with no exit but killing the app.
    bool discard;
    _asking = true;
    try {
      discard = await widget.confirmDiscard(context);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'odova',
          context: ErrorDescription('asking whether to discard a draft'),
        ),
      );
      return;
    } finally {
      _asking = false;
    }
    if (!discard) return;

    // `mounted` BEFORE the drop, not after. A guard unmounted while the dialog
    // was open — the route replaced under it, the vehicle switched — otherwise
    // threw away every segment's draft on the way out of a modal that is no
    // longer there.
    if (!mounted) return;
    widget.onDiscard();
    _leave();
  }

  void _leave() {
    final dismissed = widget.onDismissed;
    if (dismissed != null) {
      dismissed();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // `canPop: false` and a manual pop, because the decision is asynchronous:
    // the framework cannot wait for a dialog, so the pop it was going to do has
    // to be refused and re-issued after the answer.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Fire and forget: the framework cannot wait for a dialog, which is
        // why `canPop` is false and the pop is re-issued after the answer.
        unawaited(requestDismiss());
      },
      child: GestureDetector(
        // Swipe-down, §7's third gesture. `onVerticalDragEnd` rather than a
        // drag-tracking sheet: the modal does not follow the finger, so a
        // partial drag is not a partial dismissal and cannot leave the screen
        // half-gone if the user changes their mind.
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > _dismissVelocity) {
            unawaited(requestDismiss());
          }
        },
        child: widget.child,
      ),
    );
  }
}

/// Downward pixels per second that count as a dismissal.
///
/// High enough that scrolling a long form to its end does not throw the form
/// away — SPEC.md §1's user is logging one-handed at a pump, and an accidental
/// dismissal there costs them the fill-up they came to record.
const double _dismissVelocity = 700;
