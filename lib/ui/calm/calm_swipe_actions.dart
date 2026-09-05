// Swipe-to-reveal row actions.
//
// SPEC.md §8: "Swipe (end actions) — **Mark as sold** (amber), **Delete**
// (red). Declared as `endActions`; the physical direction flips in RTL."
//
// **`endActions`, never `rightActions`.** A component named for a side puts
// Delete under the user's thumb in English and under their other thumb in
// Arabic, and half the shipped locales are right-to-left. The declaration is
// logical and the physics follow `Directionality`.
//
// Not `Dismissible`: that reveals one action and then removes the row, and this
// needs two actions and a row that survives both. Not a package either —
// `dependency-hygiene` would ask what a slidable list pulls in, and the answer
// for 120 lines of `GestureDetector` is "more than it is worth".
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// How loud a swipe action is.
enum CalmSwipeTone {
  /// Amber. A change the user can undo by doing the opposite.
  caution,

  /// Red. Destructive, and behind a confirmation of its own.
  danger,
}

/// One revealed action.
@immutable
class CalmSwipeAction {
  /// Creates an action.
  const CalmSwipeAction({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  /// Already localised, and shown as TEXT beneath the icon.
  ///
  /// Never icon-only. SPEC.md §8's two actions are a sale and a permanent
  /// delete, and a bin glyph is not a sentence anybody should have to guess at
  /// before destroying eight years of history.
  final String label;

  /// The glyph above the label.
  final IconData icon;

  /// Amber or red.
  final CalmSwipeTone tone;

  /// What it does. The row closes first.
  final VoidCallback onPressed;
}

/// The width one action occupies once revealed.
const kCalmSwipeActionWidth = 88.0;

/// The height a revealed action needs: a glyph, a gap and two lines of caption.
///
/// A FUNCTION of the tokens, not a number. The tiles are stretched to the row's
/// height, so a row shorter than this overflows them — and pinning it to a
/// literal would leave the two to drift the first time the caption scale
/// changed.
///
/// EXACTLY the content, with no padding of its own. The first version added
/// `s2` above and below "for breathing room", which made every swipeable row
/// 16pt taller than its design — visible against the `reminders.list`
/// reference, where a 64pt row came out at 82. The tile is centred in whatever
/// height it gets; this is the floor at which it stops overflowing, not a
/// comfortable size for it.
double calmSwipeActionMinHeight(BuildContext context) {
  final space = CalmSpace.of(context);
  final caption = CalmType.of(context).caption;
  // `scale(fontSize)`, NOT `scale(1) * fontSize`. A `TextScaler` is not a
  // ratio: on Android 14 and later the system scaler is non-linear, so
  // `scale(1)` is the scaled size of a ONE-POINT font and multiplying a 13pt
  // caption by it computes a line box materially smaller than the text
  // actually occupies. The floor would then be too low at exactly the setting
  // it matters at, and the two-line tile overflows — which is the 4pt Persian
  // "امروز انجام شد" overflow this function exists to prevent.
  final line =
      MediaQuery.textScalerOf(context).scale(caption.fontSize ?? 13) *
      (caption.height ?? 1.4);
  // CEILED per line. A text line box is laid out in whole logical pixels, so
  // `13 * 1.4` occupies 19 and not 18.2 — and the 0.8 the two of them gain is
  // exactly the overflow this function exists to prevent.
  return space.iconSm + space.s1 + line.ceilToDouble() * 2;
}

/// How far the row must travel before it stays open.
///
/// Half of one action. Below it the row springs back: a row left ajar is a row
/// whose next tap lands on Delete.
const double kCalmSwipeOpenThreshold = kCalmSwipeActionWidth / 2;

/// A row that reveals [endActions] when swiped toward the start edge.
class CalmSwipeActions extends StatefulWidget {
  /// Creates a swipeable row.
  const CalmSwipeActions({
    required this.child,
    required this.endActions,
    super.key,
  });

  /// The row itself.
  final Widget child;

  /// What the swipe reveals, nearest the row first.
  ///
  /// SPEC.md §8 lists Mark as sold before Delete, so the most destructive
  /// action is the furthest to reach — the one place in the app where extra
  /// distance is the feature.
  final List<CalmSwipeAction> endActions;

  @override
  State<CalmSwipeActions> createState() => _CalmSwipeActionsState();
}

class _CalmSwipeActionsState extends State<CalmSwipeActions>
    with SingleTickerProviderStateMixin {
  /// How far the row has travelled toward the start edge, in logical pixels.
  ///
  /// Always POSITIVE and always logical: the `Directionality` turns it into a
  /// physical offset at paint time, and nothing above that line knows which way
  /// is left.
  double _offset = 0;

  double get _maxOffset => widget.endActions.length * kCalmSwipeActionWidth;

  void _close() => setState(() => _offset = 0);

  void _run(CalmSwipeAction action) {
    // CLOSED first. A row still open under a dialog is a row the user taps
    // through when the dialog closes.
    _close();
    action.onPressed();
  }

  void _onDragUpdate(DragUpdateDetails details, bool rtl) {
    // A drag toward the START edge opens; the other way is a drag toward
    // start-actions this row does not have, and it must do nothing at all
    // rather than rubber-band something into view.
    final delta = rtl ? details.delta.dx : -details.delta.dx;
    setState(() => _offset = (_offset + delta).clamp(0, _maxOffset));
  }

  void _onDragEnd(DragEndDetails details) {
    final open = _offset >= kCalmSwipeOpenThreshold;
    if (open && _offset < _maxOffset) {
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _offset = open ? _maxOffset : 0);
  }

  @override
  Widget build(BuildContext context) {
    final motion = CalmMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      // The gesture is never the only path. TalkBack and VoiceOver both spend
      // horizontal swipes on navigation, so a screen-reader user cannot make
      // this one — SPEC.md §17, and `accessibility-as-code`'s rule.
      customSemanticsActions: {
        for (final action in widget.endActions)
          CustomSemanticsAction(label: action.label): () => _run(action),
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, rtl),
        onHorizontalDragEnd: _onDragEnd,
        // A tap anywhere on an OPEN row closes it rather than reaching the row
        // underneath. The row's own onTap is inside `child` and only sees taps
        // once this is shut.
        onTap: _offset > 0 ? _close : null,
        child: Stack(
          children: [
            // The actions sit BEHIND the row and do not move. The row slides
            // off them, which is what makes the reveal read as uncovering
            // rather than as pushing.
            // Not BUILT while the row is shut, rather than built and hidden:
            // an offstage button still takes focus in a traversal and still
            // reports itself to a screen reader, which would put two Deletes in
            // the tree — the custom action and a button nobody can see.
            if (_offset > 0)
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                child: _EndActions(actions: widget.endActions, onRun: _run),
              ),
            // The ROW is at least as tall as the tallest action it reveals.
            //
            // The tiles are stretched to the row's height by the
            // `PositionedDirectional` above, so a row shorter than its own
            // actions overflows THEM — which is what a 64pt reminder row did
            // against a two-line Persian "امروز انجام شد", by 4pt. Measured
            // from the tokens rather than pinned to a number, so a change to
            // the caption scale moves both together.
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: calmSwipeActionMinHeight(context),
              ),
              child: AnimatedSlide(
                duration: calmDuration(context, motion.quick),
                curve: motion.easeOut,
                // Logical, so the row travels toward the start edge in both
                // directions without this widget knowing which one that is.
                offset: Offset(
                  (rtl ? 1 : -1) * _offset / _rowWidth(context),
                  0,
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The row's own width, which `AnimatedSlide` measures its fraction against.
  double _rowWidth(BuildContext context) {
    final width = (context.findRenderObject() as RenderBox?)?.size.width ?? 0;
    // Before the first layout there is nothing to divide by, and 1 makes the
    // fraction a no-op rather than a NaN — a NaN offset throws in the paint
    // phase, which is a crash on the frame the row first appears.
    return width > 0 ? width : 1;
  }
}

class _EndActions extends StatelessWidget {
  const _EndActions({required this.actions, required this.onRun});

  final List<CalmSwipeAction> actions;
  final void Function(CalmSwipeAction) onRun;

  @override
  Widget build(BuildContext context) {
    // FULL width from the first pixel of the drag, with the row sliding over
    // it. The version that sized this box to the travelled distance put a
    // 176-wide Row inside an 88-wide box for the whole gesture and overflowed
    // every frame of it — and a laid-out-but-overflowing child is replaced by
    // an error widget, so the first action's label vanished from the tree
    // rather than merely being clipped.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in actions)
          CalmSwipeActionButton(
            action: action,
            onPressed: () => onRun(action),
          ),
      ],
    );
  }
}

/// One action's button. Public so a test can measure its target.
class CalmSwipeActionButton extends StatelessWidget {
  /// Creates a button.
  const CalmSwipeActionButton({
    required this.action,
    required this.onPressed,
    super.key,
  });

  /// What it runs.
  final CalmSwipeAction action;

  /// Runs it, after the row has closed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    // TINT behind INK, never `base` behind white. `CalmRamp.base` is held to
    // 3:1 as a graphic and its own doc says several bases "MUST NOT carry
    // text"; the ink/tint pairs are the ones Calm certifies at 4.5:1 in both
    // themes, and `calm_contrast_test.dart` measures both of these. A saturated
    // slab is the iOS convention and it is not one Calm can prove.
    final (Color ground, Color ink) = switch (action.tone) {
      CalmSwipeTone.caution => (colors.due.tint, colors.due.ink),
      CalmSwipeTone.danger => (colors.dangerTint, colors.danger),
    };

    return CalmPressable(
      onTap: onPressed,
      pressScale: 1,
      // Square: the action is a full-bleed slab behind the row, and a
      // rounded focus ring would float inside a rectangle with no edge.
      borderRadius: 0,
      child: ColoredBox(
        color: ground,
        child: ConstrainedBox(
          // `--touch-min: 52`, not Material's 48. SPEC.md §1: this happens at a
          // fuel pump, in the rain, one-handed. The row is 76 tall, so the
          // height constraint binds only if somebody shortens it.
          // Width only. The HEIGHT is the row's, imposed by the
          // `PositionedDirectional` that stretches these behind it, so a
          // `minHeight` here can never bind — it was in the first version and
          // a mutation that set it to zero passed every test, which is the
          // definition of a constraint nobody would notice removing.
          // `swipeActionClearsTouchMin` guards the pairing instead.
          constraints: const BoxConstraints.tightFor(
            width: kCalmSwipeActionWidth,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: space.s1,
              children: [
                Icon(action.icon, size: space.iconSm, color: ink),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: space.s2),
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    // Two lines, because "Als verkauft markieren" is three
                    // words and SPEC.md §8's RTL note says German rows wrap
                    // rather than truncate.
                    maxLines: 2,
                    style: type.caption.copyWith(color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
