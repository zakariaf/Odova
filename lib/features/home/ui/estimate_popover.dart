// One sentence and at most one action, anchored to the value it explains.
//
// SPEC.md §9: "Tapping an estimated value or a `—` opens a transient popover
// anchored to it — one sentence, one action." And the sentence is deliberately
// small: "No percentage, no bar, no tier name: the tilde and the word 'about'
// are the whole vocabulary." A confidence bar would invite the user to reason
// about a number the app is already telling them not to trust.
import 'package:flutter/material.dart';
import 'package:odova/ui/calm/calm_popover.dart';

/// Shows [body] anchored under the widget at [context].
///
/// TRANSIENT — a tap outside closes it and nothing is written. §9 puts it on a
/// value rather than behind an info icon, so the explanation is where the
/// question is.
Future<void> showEstimatePopover(
  BuildContext context, {
  required CalmPopover body,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  final frame = overlay.size;
  final rtl = Directionality.of(context) == TextDirection.rtl;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => Stack(
      children: [
        Positioned(
          // CLAMPED to the frame, and anchored on the leading edge in both
          // directions. It used to be `left: origin.dx` with no bound: in RTL
          // the first glance tile sits on the RIGHT, so `dx` was near the
          // screen width, the popover is up to 280 wide, and a left-positioned
          // child in a Stack gets loose constraints — so it laid out past the
          // trailing edge and was clipped. The same happened at the bottom for
          // a value near the fold.
          //
          // §9 says the popover is "anchored to" the value; it does not say the
          // anchor may leave the screen.
          left: _clamp(
            rtl ? anchor.right - kCalmPopoverMaxWidth : anchor.left,
            kCalmPopoverMaxWidth,
            frame.width,
          ),
          top: _clamp(anchor.bottom, kCalmPopoverMinHeight, frame.height),
          child: Material(type: MaterialType.transparency, child: body),
        ),
      ],
    ),
  );
}

/// The tallest the popover is assumed to be when it is being kept on screen.
///
/// A guess, and deliberately a small one: the popover sizes itself to one
/// sentence and at most one button, and reserving more than it needs would
/// push it up the screen away from the value it is explaining. Being a little
/// low is recoverable — the sheet is transient and a tap anywhere closes it.
const double kCalmPopoverMinHeight = 120;

/// [start] moved back inside a [extent]-long axis, never past zero.
double _clamp(double start, double size, double extent) =>
    start + size <= extent
    ? (start < 0 ? 0 : start)
    : (extent - size).clamp(0, extent);
