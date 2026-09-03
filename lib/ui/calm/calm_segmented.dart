// CalmSegmented — a tinted pill track whose options flex equally.
//
// Selection is the raised `surface` pill PLUS semibold weight PLUS
// Semantics(selected: true). Three signals, because `surface` on `surface2` is
// 1.16:1 and the pill is otherwise carried by elev1 alone.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// The painted height of one option.
const double kCalmSegmentedOptionHeight = 46;

/// A segmented control.
class CalmSegmented extends StatelessWidget {
  /// Creates a segmented control.
  const CalmSegmented({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  /// The options, already localised. Order mirrors for free: it is a Row.
  final List<String> labels;

  /// The selected index.
  final int index;

  /// Reports the tapped index.
  final ValueChanged<int> onChanged;

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
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: CalmSegmentedOption(
                  label: labels[i],
                  selected: i == index,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One option. Public so a test can measure the paint and read its semantics.
class CalmSegmentedOption extends StatelessWidget {
  /// Creates an option.
  const CalmSegmentedOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// The word.
  final String label;

  /// Whether this is the chosen one.
  final bool selected;

  /// What tapping it does.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final type = CalmType.of(context);

    return Semantics(
      selected: selected,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: kCalmSegmentedOptionHeight / 2,
        pressScale: kCalmPressScaleChip,
        // Paints 46, hits 52.
        expandTapTarget: true,
        child: AnimatedContainer(
          duration: calmDuration(context, motion.base),
          curve: motion.easeStandard,
          height: kCalmSegmentedOptionHeight,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? colors.surface : Colors.transparent,
            shape: const StadiumBorder(),
            shadows: selected ? shapes.elev1 : shapes.elev0,
          ),
          child: Text(
            label,
            style: type.label.copyWith(
              color: selected ? colors.ink : colors.ink2,
              fontWeight: selected ? type.semi : type.medium,
            ),
          ),
        ),
      ),
    );
  }
}
