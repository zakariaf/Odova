// CalmButton — lib/ui/calm/calm_button.dart
//
// Big. This is the system you can hit one-handed at a pump, in the rain:
// 42/52/60pt pills with generous inline padding, a scale-and-tint press, and a
// disabled state that is never allowed on screen without a line underneath
// saying what is missing (SPEC.md §10).
//
// Never ElevatedButton/FilledButton/TextButton/OutlinedButton/IconButton: M3
// sizes them at 40pt, gives them a ripple, and drives their elevation from a
// tonal model that has nothing to do with --elev-1.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_motion.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/theme/calm/calm_type.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

enum CalmButtonVariant {
  primary,
  secondary,
  tonal,
  quiet,
  danger,
  dangerSolid,

  /// Takes the colour of the due item it acts on ("Log it" on an overdue
  /// card). Resolves through CalmStatusStyle, never a named status slot.
  onState,
  icon,
}

enum CalmButtonSize { sm, md, lg }

class CalmButton extends StatelessWidget {
  const CalmButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = CalmButtonVariant.primary,
    this.size = CalmButtonSize.md,
    this.icon,
    this.block = false,
    this.loading = false,
    this.dueState,
  });

  final String label;

  /// Null means disabled — and a disabled button owes the user a
  /// [CalmButtonExplain] beneath it.
  final VoidCallback? onPressed;

  final CalmButtonVariant variant;
  final CalmButtonSize size;
  final IconData? icon;
  final bool block;
  final bool loading;
  final DueState? dueState;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final enabled = onPressed != null && !loading;

    // .btn--lg 60 / .btn--md 52 / .btn--sm 42
    final height = switch (size) {
      CalmButtonSize.sm => 42.0,
      CalmButtonSize.md => 52.0,
      CalmButtonSize.lg => 60.0,
    };
    final padInline = switch (size) {
      CalmButtonSize.sm => space.s4,
      CalmButtonSize.md => space.s6,
      CalmButtonSize.lg => space.s7,
    };

    final (Color background, Color foreground, List<BoxShadow> shadow) =
        !enabled
            // .btn:disabled — a colour swap, not an opacity fade.
            ? (colors.surface2, colors.ink4, shapes.elev0)
            : switch (variant) {
                CalmButtonVariant.primary => (
                    colors.brand,
                    colors.onBrand,
                    shapes.elev1,
                  ),
                CalmButtonVariant.secondary => (
                    colors.brandSoft,
                    colors.brandSoftInk,
                    shapes.elev0,
                  ),
                CalmButtonVariant.tonal => (
                    colors.surface2,
                    colors.ink,
                    shapes.elev0,
                  ),
                CalmButtonVariant.quiet => (
                    Colors.transparent,
                    colors.brand,
                    shapes.elev0,
                  ),
                CalmButtonVariant.danger => (
                    colors.dangerTint,
                    colors.danger,
                    shapes.elev0,
                  ),
                CalmButtonVariant.dangerSolid => (
                    colors.danger,
                    colors.onBrand,
                    shapes.elev1,
                  ),
                // A caller holding a BuildContext uses `of`; `resolve` takes a
                // CalmColors and exists for tests. The graphic slot is `base`.
                CalmButtonVariant.onState => (
                    CalmStatusStyle.of(
                      context,
                      dueState ?? DueState.unknown,
                    ).base,
                    colors.onBrand,
                    shapes.elev1,
                  ),
                CalmButtonVariant.icon => (
                    colors.surface2,
                    colors.ink2,
                    shapes.elev0,
                  ),
              };

    final textStyle = (size == CalmButtonSize.sm ? type.label : type.bodyLg)
        .copyWith(color: foreground, fontWeight: type.semi, height: 1.2);

    return CalmPressable(
      onTap: enabled ? onPressed : null,
      enabled: enabled,
      borderRadius: shapes.radiusPill,
      semanticLabel: label,
      // .btn--sm paints 42; the target is still 52.
      expandTapTarget: size == CalmButtonSize.sm,
      child: _CalmButtonBody(
        label: label,
        icon: icon,
        height: height,
        padInline: padInline,
        block: block,
        iconOnly: variant == CalmButtonVariant.icon,
        loading: loading,
        background: background,
        foreground: foreground,
        shadow: shadow,
        textStyle: textStyle,
      ),
    );
  }
}

class _CalmButtonBody extends StatelessWidget {
  const _CalmButtonBody({
    required this.label,
    required this.icon,
    required this.height,
    required this.padInline,
    required this.block,
    required this.iconOnly,
    required this.loading,
    required this.background,
    required this.foreground,
    required this.shadow,
    required this.textStyle,
  });

  final String label;
  final IconData? icon;
  final double height;
  final double padInline;
  final bool block;
  final bool iconOnly;
  final bool loading;
  final Color background;
  final Color foreground;
  final List<BoxShadow> shadow;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final motion = CalmMotion.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final pressed = CalmPressState.of(context);

    // .btn--primary:active — one step darker AND the shadow drops out.
    final fill =
        pressed && background == colors.brand ? colors.brandStrong : background;

    return AnimatedContainer(
      duration: calmDuration(context, motion.quick), // --dur-quick, 160ms
      curve: motion.easeOut,
      height: height,
      width: iconOnly ? height : null,
      constraints:
          block ? const BoxConstraints(minWidth: double.infinity) : null,
      padding: iconOnly
          ? EdgeInsets.zero
          : EdgeInsetsDirectional.symmetric(horizontal: padInline),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(shapes.radiusPill),
        boxShadow: pressed ? shapes.elev0 : shadow,
      ),
      child: Row(
        mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground), // .btn .icon { 20px }
            if (!iconOnly) SizedBox(width: space.s2),
          ],
          if (!iconOnly)
            Flexible(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Kept in the tree at zero opacity so the button does not
                  // change width when it starts loading and shove whatever is
                  // beside it under the user's thumb.
                  Opacity(
                    opacity: loading ? 0 : 1,
                    child: Text(label, style: textStyle, maxLines: 1),
                  ),
                  if (loading)
                    SizedBox(
                      width: 20,
                      height: 20, // .btn.is-loading::after { 20px }
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: foreground,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// SPEC.md §10: "a greyed-out Save tells the user nothing." A disabled
/// CalmButton is never on screen without this line underneath it.
class CalmButtonExplain extends StatelessWidget {
  const CalmButtonExplain({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.only(top: space.s2),
      child: Text(
        reason,
        textAlign: TextAlign.center,
        style: type.caption.copyWith(color: colors.ink3),
      ),
    );
  }
}
