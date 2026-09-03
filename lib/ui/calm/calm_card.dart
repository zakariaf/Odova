// CalmCard — every card in the app, in eight variants.
//
// A Calm card is NEVER bordered. Depth is `--elev-1`'s two layers plus the
// `--elev-sheen` hairline; where depth is unwanted the variant is
// flat/tinted/quiet, never a 1px outline. `--color-divider` against
// `--color-surface` is 1.36:1 — a border that is invisible on the phone and
// obvious in a screenshot.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_surface.dart';

/// The eight card shapes Calm ships.
enum CalmCardVariant {
  /// `radius2xl`, `s6` padding, `elev1`. The default.
  standard,

  /// `radius3xl`, `s7` padding. A screen's one primary surface.
  lg,

  /// `radiusXl`, `s5` padding. A card inside a card.
  sm,

  /// `surface2`, flat. A card that is a ground rather than an object.
  tinted,

  /// `surface`, flat. Depth would say "this is separate" and it is not.
  flat,

  /// `elev2`. A card that has been lifted — a sheet's own card.
  raised,

  /// `bgSunk`, flat. A recess.
  quiet,

  /// `surfaceInverse` at `elev2`. The one card that inverts.
  inverse,
}

/// A card. Big radius, generous padding, layered warm shadow, no border.
class CalmCard extends StatelessWidget {
  /// Creates a card.
  const CalmCard({
    required this.child,
    super.key,
    this.variant = CalmCardVariant.standard,
    this.onTap,
    this.semanticLabel,
  });

  /// The card's content.
  final Widget child;

  /// Which of the eight shapes.
  final CalmCardVariant variant;

  /// Null — the common case — means the card is not a control at all, and
  /// carries no gesture and no focus stop.
  final VoidCallback? onTap;

  /// The accessible name, when the card is tappable and its content does
  /// not already read as one.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);

    final radius = switch (variant) {
      CalmCardVariant.lg => shapes.radius3xl, // --radius-3xl, 36
      CalmCardVariant.sm => shapes.radiusXl, //  --radius-xl, 24
      _ => shapes.radius2xl, //                  --radius-2xl, 28
    };
    final pad = switch (variant) {
      CalmCardVariant.lg => space.s7, // --space-7, 32
      CalmCardVariant.sm => space.s5, // --space-5, 20
      _ => space.s6, //                 --space-6, 24
    };
    final background = switch (variant) {
      CalmCardVariant.tinted => colors.surface2,
      CalmCardVariant.quiet => colors.bgSunk,
      CalmCardVariant.inverse => colors.surfaceInverse,
      _ => colors.surface,
    };
    final shadow = switch (variant) {
      CalmCardVariant.tinted ||
      CalmCardVariant.flat ||
      CalmCardVariant.quiet => shapes.elev0,
      CalmCardVariant.raised || CalmCardVariant.inverse => shapes.elev2,
      _ => shapes.elev1,
    };
    // The ink ramp does not invert with the surface: an inverse card sets its
    // own foreground rather than reusing ink/ink2/ink3.
    final foreground = variant == CalmCardVariant.inverse
        ? colors.inkInverse
        : colors.ink;

    final surface = CalmSurface(
      color: background,
      radius: radius,
      shadow: shadow,
      sheen: variant != CalmCardVariant.inverse && shadow.isNotEmpty,
      padding: EdgeInsets.all(pad),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: child,
      ),
    );

    if (onTap == null) return surface;
    return CalmPressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      child: surface,
    );
  }
}
