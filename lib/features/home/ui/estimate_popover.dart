// One sentence and at most one action, anchored to the value it explains.
//
// SPEC.md §9: "Tapping an estimated value or a `—` opens a transient popover
// anchored to it — one sentence, one action." And the sentence is deliberately
// small: "No percentage, no bar, no tier name: the tilde and the word 'about'
// are the whole vocabulary." A confidence bar would invite the user to reason
// about a number the app is already telling them not to trust.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_button.dart';

/// What a popover offers, if anything.
///
/// Dismissal-only is a real answer and the consumption tile's: §9 gives that
/// one no button, because there is nothing to do but drive and fill up, and a
/// button that only closes a popover is a control that does nothing.
@immutable
class EstimatePopoverAction {
  /// Creates an action.
  const EstimatePopoverAction({required this.label, required this.onPressed});

  /// The button's words, already localised.
  final String label;

  /// What it does.
  final VoidCallback onPressed;
}

/// The popover body.
class EstimatePopover extends StatelessWidget {
  /// Creates the popover.
  const EstimatePopover({required this.message, super.key, this.action});

  /// The one sentence.
  final String message;

  /// The one action, or null for dismissal only.
  final EstimatePopoverAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final action = this.action;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: EdgeInsetsDirectional.all(space.s4),
      decoration: ShapeDecoration(
        color: colors.surface,
        shadows: shapes.elev2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapes.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: space.s3,
        children: [
          Text(message, style: type.body.copyWith(color: colors.ink2)),
          if (action != null)
            CalmButton(
              label: action.label,
              variant: CalmButtonVariant.tonal,
              size: CalmButtonSize.sm,
              block: true,
              onPressed: action.onPressed,
            ),
        ],
      ),
    );
  }
}

/// Shows [body] anchored under the widget at [context].
///
/// TRANSIENT — a tap outside closes it and nothing is written. §9 puts it on a
/// value rather than behind an info icon, so the explanation is where the
/// question is.
Future<void> showEstimatePopover(
  BuildContext context, {
  required EstimatePopover body,
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
