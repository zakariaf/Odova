// CalmChip and CalmChipBar — the filter row.
//
// A chip PAINTS 40 and HITS 52. Growing the paint to clear the floor would
// ship a filter bar 30% taller than the design; the target grows instead.
//
// Selection carries three signals — fill, ink and weight — because brand on
// surface2 is not a 3:1 difference, and a filter bar read in sunlight is
// exactly where that shows.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// `.chip` min-height.
const double kCalmChipHeight = 40;

/// `.chip.is-disabled { opacity: .45 }`.
const double kCalmChipDisabledOpacity = 0.45;

/// One filter chip.
class CalmChip extends StatelessWidget {
  /// Creates a chip.
  const CalmChip({
    required this.label,
    required this.onTap,
    super.key,
    this.selected = false,
    this.business = false,
    this.enabled = true,
    this.icon,
  });

  /// The word, already localised. It is never truncated: a filter whose word
  /// is cut is a filter nobody can name.
  final String label;

  /// What pressing it does.
  final VoidCallback onTap;

  /// Draws the chip on `brand` with `onBrand` ink at semibold weight.
  final bool selected;

  /// Draws the chip on the `business` ramp — the trip-purpose filter.
  final bool business;

  /// False fades the chip to 45% and stops it responding.
  final bool enabled;

  /// A leading glyph, 17pt.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final chip = _CalmChipBody(
      label: label,
      selected: selected,
      business: business,
      icon: icon,
    );

    if (!enabled) {
      // AbsorbPointer, not IgnorePointer: a disabled chip must eat its own tap
      // rather than hand it to the chip behind it in the scroll view.
      return Opacity(
        opacity: kCalmChipDisabledOpacity,
        child: AbsorbPointer(child: Semantics(enabled: false, child: chip)),
      );
    }

    return Semantics(
      selected: selected,
      child: CalmPressable(
        onTap: onTap,
        borderRadius: kCalmChipHeight / 2,
        pressScale: kCalmPressScaleChip,
        // No semanticLabel: the chip's own Text is the label, and one here
        // would be announced on top of it — "Fuel, Fuel".
        // Paints 40, hits 52.
        expandTapTarget: true,
        child: chip,
      ),
    );
  }
}

class _CalmChipBody extends StatelessWidget {
  const _CalmChipBody({
    required this.label,
    required this.selected,
    required this.business,
    required this.icon,
  });

  final String label;
  final bool selected;
  final bool business;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final pressed = CalmPressState.of(context);

    final (Color background, Color foreground) = selected
        ? (colors.brand, colors.onBrand)
        : business
        ? (colors.business.tint, colors.business.ink)
        : (pressed ? colors.surface3 : colors.surface2, colors.ink2);

    return AnimatedContainer(
      duration: calmDuration(context, motion.quick),
      curve: motion.easeOut,
      constraints: const BoxConstraints(minHeight: kCalmChipHeight),
      padding: EdgeInsetsDirectional.symmetric(horizontal: space.s4),
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: foreground), // .chip .icon { 17px }
            SizedBox(width: space.s2),
          ],
          Text(
            label,
            style: type.label.copyWith(
              color: foreground,
              fontWeight: selected ? type.semi : type.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// The horizontally scrolling filter row.
class CalmChipBar extends StatelessWidget {
  /// Creates a chip bar.
  const CalmChipBar({required this.chips, super.key});

  /// The chips, in order. The row starts at the `start` edge in both
  /// directions — Flutter reverses a horizontal scroll view under RTL, so
  /// there is nothing to mirror by hand and nothing to get wrong.
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final space = CalmSpace.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(vertical: space.s1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) SizedBox(width: space.s2),
            chips[i],
          ],
        ],
      ),
    );
  }
}
