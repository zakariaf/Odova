// CalmButton — the one button in the app.
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

/// The eight button treatments. There is one unnamed constructor: `primary` is
/// the default [CalmButton.variant], not a named constructor.
enum CalmButtonVariant {
  /// `brand` on `onBrand` with `elev1` — a screen's one primary action.
  primary,

  /// `brandSoft` on `brandSoftInk`, flat.
  secondary,

  /// `surface2` on `ink`, flat — a neutral secondary.
  tonal,

  /// Transparent on `brand` — a text action.
  quiet,

  /// `dangerTint` on `danger` — a destructive action, stated softly.
  danger,

  /// `danger` on `onBrand` — a destructive action, confirmed.
  dangerSolid,

  /// Takes the colour of the due item it acts on ("Log it" on an overdue
  /// card). Resolves through [CalmStatusStyle], never a named status slot.
  onState,

  /// A square icon-only button on `surface2`.
  icon,
}

/// 42 / 52 / 60. All three report a 52pt hit area.
enum CalmButtonSize {
  /// Paints 42; the tap target is still 52.
  sm,

  /// Paints 52 — the default.
  md,

  /// Paints 60 — a screen's one primary action.
  lg,
}

/// The one button widget.
class CalmButton extends StatelessWidget {
  /// Creates a button. `onPressed: null` is the disabled state, and obliges a
  /// [CalmButtonExplain] beneath it.
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

  /// The label. It wraps to two lines; it is never ellipsised.
  final String label;

  /// Null means disabled — and a disabled button owes the user a
  /// [CalmButtonExplain] beneath it.
  final VoidCallback? onPressed;

  /// The treatment.
  final CalmButtonVariant variant;

  /// The painted height.
  final CalmButtonSize size;

  /// A leading glyph, 20pt.
  final IconData? icon;

  /// Stretches to the full available width.
  final bool block;

  /// Swaps the label for a spinner without changing the button's width.
  final bool loading;

  /// The state [CalmButtonVariant.onState] takes its colour from.
  final DueState? dueState;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);
    final enabled = onPressed != null && !loading;

    if (onPressed == null) _assertExplained(context);

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

    final (
      Color background,
      Color foreground,
      List<BoxShadow> shadow,
    ) = !enabled
        // .btn:disabled — a colour swap, not an opacity fade. Fading takes the
        // ground and the shadow with it and smears both.
        // ink4 here is disabled text, which SC 1.4.3 exempts. It is declared
        // in test/theme/calm/calm_contrast_test.dart's ink4 allowlist.
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
              CalmStatusStyle.of(context, dueState ?? DueState.unknown).base,
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
        .copyWith(color: foreground, fontWeight: type.semi);

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

  /// SPEC.md §10, mechanised: a greyed-out Save tells the user nothing.
  ///
  /// The explanation is a SIBLING, so it does not exist while this build runs
  /// — the check is deferred one frame and then walks down from the nearest
  /// multi-child ancestor. Debug only; in release the whole call is compiled
  /// away with the assert that guards it.
  void _assertExplained(BuildContext context) {
    assert(() {
      // The outer assert exists to strip the whole check in release; the
      // message that matters is on the inner one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        assert(
          _hasExplainNearby(context),
          'A disabled CalmButton ("$label") has no CalmButtonExplain beneath '
          'it. SPEC.md §10: a greyed-out Save tells the user nothing. Say '
          'what is missing, or keep the button enabled and fail on tap.',
        );
      });
      return true;
    }(), 'deferred to the post-frame callback above');
  }

  static bool _hasExplainNearby(BuildContext context) {
    Element? scope;
    context.visitAncestorElements((element) {
      if (element.widget is MultiChildRenderObjectWidget) {
        scope = element;
        return false;
      }
      return true;
    });
    if (scope == null) return false;

    var found = false;
    void walk(Element element) {
      if (found) return;
      if (element.widget is CalmButtonExplain) {
        found = true;
        return;
      }
      element.visitChildren(walk);
    }

    scope!.visitChildren(walk);
    return found;
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
    final fill = pressed && background == colors.brand
        ? colors.brandStrong
        : background;

    final pill = AnimatedContainer(
      duration: calmDuration(context, motion.quick), // --dur-quick, 160ms
      curve: motion.easeOut,
      padding: iconOnly
          ? EdgeInsets.zero
          : EdgeInsetsDirectional.symmetric(
              horizontal: padInline,
              vertical: space.s2,
            ),
      // A StadiumBorder, not BorderRadius.circular(radiusPill). 999 is a
      // sentinel meaning "fully round"; as a real radius it allocates a path
      // Skia re-clamps every frame, and it renders ALMOST right.
      decoration: ShapeDecoration(
        color: fill,
        shape: const StadiumBorder(),
        shadows: pressed ? shapes.elev0 : shadow,
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
                    // ExcludeSemantics, because CalmPressable already declares
                    // the label. Without it the node reads "Save, Save"; with
                    // the Text as the ONLY source it would read nothing while
                    // loading, since RenderOpacity at alpha 0 drops its child
                    // from the semantics tree.
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: textStyle,
                        // No maxLines. Two lines are RESERVED for every size —
                        // German runs ~30% longer than English — but not
                        // imposed: a cap that is reached is a clip, and an
                        // ellipsis on a button hides the verb.
                      ),
                    ),
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

    // The size is OUTSIDE the AnimatedContainer, deliberately. Animating
    // constraints means lerping them, and Flutter cannot interpolate between
    // an unbounded width and a bounded one — so a button that switches to the
    // square `icon` variant, or toggles `block`, would assert mid-tween.
    //
    // minHeight, not a fixed height: the label wraps to two lines and the pill
    // grows to hold them. A fixed height clips German at 200% text scale and
    // reports nothing at all.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: block ? double.infinity : 0,
      ),
      child: iconOnly
          ? SizedBox(width: height, height: height, child: pill)
          : pill,
    );
  }
}

/// The line under a disabled [CalmButton].
///
/// SPEC.md §10: "a greyed-out Save tells the user nothing." A disabled
/// CalmButton is never on screen without this beneath it, and asserts in debug
/// if it is.
class CalmButtonExplain extends StatelessWidget {
  /// Creates the explanation line.
  const CalmButtonExplain({required this.reason, super.key});

  /// What is missing, in the user's words. Already localised.
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
