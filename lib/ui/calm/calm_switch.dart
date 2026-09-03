// CalmSwitch — 56x34 with a 28pt thumb travelling 22pt toward the END edge.
//
// AlignmentDirectional does the mirroring, so there is no second code path for
// fa, ar and ckb and nothing to get wrong.
//
// Never the tap target of the row it sits in: `CalmListRow.switchRow` is not
// navigable, the whole row toggles, and the pair is one MergeSemantics node.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// The painted track size.
const Size kCalmSwitchTrackSize = Size(56, 34);

/// The thumb's diameter.
const double kCalmSwitchThumbSize = 28;

/// The inset of the thumb inside the track — and therefore half the reason its
/// travel is 22 and not 28.
const double kCalmSwitchInset = 3;

/// A Calm switch.
class CalmSwitch extends StatelessWidget {
  /// Creates a switch.
  const CalmSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  });

  /// On or off.
  final bool value;

  /// Null disables it.
  final ValueChanged<bool>? onChanged;

  /// Only for a switch that stands alone. Inside a `CalmListRow.switchRow` the
  /// row's title is the label and this stays null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    // Through CalmPressable, not around it. The first version hand-assembled
    // Semantics + CalmTapTarget + a raw GestureDetector — a strict subset of
    // the primitive — because there was no way to say "toggle, not button".
    // The cost was invisible: a standalone switch had no
    // FocusableActionDetector, so it was unreachable by Tab, drew no focus
    // ring and could not be activated by keyboard, against SPEC.md §17. And
    // the traversal matrix enumerates CalmPressable, so the one control that
    // opted out was the one control it could not check.
    return CalmPressable(
      onTap: onChanged == null ? null : () => onChanged(!value),
      enabled: onChanged != null,
      borderRadius: kCalmSwitchTrackSize.height / 2,
      pressScale: 1, // the thumb travels; the track does not squeeze
      toggled: value,
      semanticLabel: semanticLabel,
      child: CalmSwitchTrack(value: value, enabled: onChanged != null),
    );
  }
}

/// The painted 56x34 track. Public so a test can measure the paint rather than
/// the 52pt target around it.
class CalmSwitchTrack extends StatelessWidget {
  /// Creates the track.
  const CalmSwitchTrack({
    required this.value,
    super.key,
    this.enabled = true,
  });

  /// On or off.
  final bool value;

  /// False fades it.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: SizedBox.fromSize(
        size: kCalmSwitchTrackSize,
        child: AnimatedContainer(
          duration: calmDuration(context, motion.base),
          curve: motion.easeSettle,
          decoration: ShapeDecoration(
            color: value ? colors.brand : colors.surface3,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(kCalmSwitchInset),
            child: AnimatedAlign(
              duration: calmDuration(context, motion.base),
              curve: motion.easeSettle,
              // Directional, so the thumb travels toward the END edge — which
              // is the LEFT edge in fa, ar and ckb.
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: const CalmSwitchThumb(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 28pt thumb.
class CalmSwitchThumb extends StatelessWidget {
  /// Creates the thumb.
  const CalmSwitchThumb({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);

    return SizedBox.square(
      dimension: kCalmSwitchThumbSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.surface,
          shape: const CircleBorder(),
          shadows: shapes.elev1,
        ),
      ),
    );
  }
}
