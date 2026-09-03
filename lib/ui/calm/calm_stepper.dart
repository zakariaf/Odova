// CalmStepper — a pill track with two raised buttons and a tabular value.
//
// The − and + glyphs never mirror; their ORDER does, for free, because this is
// a Row. A minus means the same thing in Sorani, and flipping the glyph draws
// a plus that leans.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// `.stepper__btn` — the painted size of each button.
const double kCalmStepperButtonSize = 48;

/// `.stepper__value` — the minimum width of the value between them.
const double kCalmStepperValueWidth = 84;

/// A − / value / + control.
class CalmStepper extends StatelessWidget {
  /// Creates a stepper.
  ///
  /// [value] is already formatted and already localised — the digits of a
  /// Persian reading are `۰۱۲۳`, and formatting them is not this widget's job.
  const CalmStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
    super.key,
  });

  /// The formatted value.
  final String value;

  /// Null-free by design: a stepper at its floor still reads as a stepper.
  final VoidCallback onDecrement;

  /// One more.
  final VoidCallback onIncrement;

  /// The screen-reader label for −. Localised by the caller.
  final String decrementLabel;

  /// The screen-reader label for +. Localised by the caller.
  final String incrementLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface2,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(space.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CalmStepperButton(
              icon: Icons.remove,
              onTap: onDecrement,
              semanticLabel: decrementLabel,
            ),
            CalmStepperValue(value: value),
            _CalmStepperButton(
              icon: Icons.add,
              onTap: onIncrement,
              semanticLabel: incrementLabel,
            ),
          ],
        ),
      ),
    );
  }
}

/// The value between the two buttons.
///
/// A fixed 84pt of tabular figures: a stepper whose track resizes as the
/// number goes from 9 to 10 moves both buttons under the user's thumb.
class CalmStepperValue extends StatelessWidget {
  /// Creates the value read-out.
  const CalmStepperValue({required this.value, super.key});

  /// The formatted value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final type = CalmType.of(context);

    return SizedBox(
      width: kCalmStepperValueWidth,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: CalmType.tabular(
          type.bodyLg.copyWith(color: colors.ink, fontWeight: type.semi),
        ),
      ),
    );
  }
}

class _CalmStepperButton extends StatelessWidget {
  const _CalmStepperButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);

    return CalmPressable(
      onTap: onTap,
      borderRadius: kCalmStepperButtonSize / 2,
      semanticLabel: semanticLabel,
      // Paints 48, hits 52.
      expandTapTarget: true,
      child: Builder(
        builder: (context) {
          final pressed = CalmPressState.of(context);
          return AnimatedContainer(
            duration: calmDuration(context, motion.instant),
            curve: motion.easeOut,
            width: kCalmStepperButtonSize,
            height: kCalmStepperButtonSize,
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: const CircleBorder(),
              shadows: pressed ? shapes.elev0 : shapes.elev1,
            ),
            // The glyph is NOT a CalmDirectionalIcon: a minus is a minus in
            // all six locales.
            child: Icon(icon, size: 20, color: colors.ink),
          );
        },
      ),
    );
  }
}
