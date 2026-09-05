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
  final origin = box.localToGlobal(
    box.size.bottomLeft(Offset.zero),
    ancestor: overlay,
  );

  return showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => Stack(
      children: [
        Positioned(
          left: origin.dx,
          top: origin.dy,
          child: Material(type: MaterialType.transparency, child: body),
        ),
      ],
    ),
  );
}
