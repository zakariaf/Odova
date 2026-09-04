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

/// `.segmented--stack .segmented__opt` — 66, for an icon over a label.
const double kCalmSegmentedStackHeight = 66;

/// `.segmented--stack .segmented__opt { gap: 3px }`.
///
/// Three is not on Calm's 4/8/12 scale and is not a token; it is the one gap in
/// the stylesheet that isn't, and it is here rather than in `CalmSpace` so the
/// scale stays the scale.
const double kCalmSegmentedStackGap = 3;

/// A segmented control.
class CalmSegmented extends StatelessWidget {
  /// Creates a segmented control.
  const CalmSegmented({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
    this.icons,
    this.numeric = false,
  }) : assert(
         icons == null || icons.length == labels.length,
         'CalmSegmented was given a different number of icons and labels, so '
         'one option would be drawn without its glyph.',
       );

  /// The options, already localised. Order mirrors for free: it is a Row.
  final List<String> labels;

  /// `.segmented--stack` — one glyph per option, above its label.
  ///
  /// Null is the plain 46pt row of words. Non-null makes every option 66pt with
  /// the icon stacked over caption-sized text, which is `firstrun.vehicle`'s
  /// vehicle-type control. There is no half-stacked state: the length is
  /// asserted against [labels] so a missing glyph is a build failure rather
  /// than one option that silently looks like a different control.
  final List<IconData>? icons;

  /// `num` — tabular, lining figures.
  ///
  /// For a control whose labels are numbers. Without it the Eastern digits of
  /// `۱۰–۲۰` and `۲۰–۳۰` are different widths, so the selected pill changes
  /// size as the selection moves — on a control whose whole job is to sit still
  /// while it travels.
  final bool numeric;

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
                  icon: icons?[i],
                  numeric: numeric,
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
    this.icon,
    this.numeric = false,
  });

  /// The glyph above the label, on a `.segmented--stack` option.
  final IconData? icon;

  /// Tabular, lining figures — see `CalmSegmented.numeric`.
  final bool numeric;

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
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    final height = icon == null
        ? kCalmSegmentedOptionHeight
        : kCalmSegmentedStackHeight;
    final foreground = selected ? colors.ink : colors.ink2;

    // `.segmented__opt` is `--fs-label`; `.segmented--stack` drops it to
    // `--fs-caption`, because a stacked option carries two things in the height
    // a flat one gives to one.
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: (icon == null ? type.label : type.caption).copyWith(
        color: foreground,
        fontWeight: selected ? type.semi : type.medium,
        fontFeatures: numeric
            ? const [FontFeature.tabularFigures(), FontFeature.liningFigures()]
            : null,
      ),
    );

    return Semantics(
      selected: selected,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: height / 2,
        pressScale: kCalmPressScaleChip,
        child: AnimatedContainer(
          duration: calmDuration(context, motion.base),
          curve: motion.easeStandard,
          height: height,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? colors.surface : Colors.transparent,
            shape: const StadiumBorder(),
            shadows: selected ? shapes.elev1 : shapes.elev0,
          ),
          child: icon == null
              ? text
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: kCalmSegmentedStackGap,
                  children: [
                    // The glyph never mirrors: a car silhouette that flips is
                    // a car facing the wrong way, not a mirrored layout.
                    Icon(icon, size: space.iconMd, color: foreground),
                    text,
                  ],
                ),
        ),
      ),
    );
  }
}
