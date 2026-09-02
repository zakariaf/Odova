// CalmSurface and CalmCard — lib/ui/calm/calm_surface.dart, calm_card.dart
//
// Two facts drive this file:
//   1. A Calm card is NEVER bordered. Depth is --elev-1 (two layers) plus the
//      --elev-sheen hairline; when depth is unwanted the variant is
//      flat/tinted/quiet, never a 1px outline. --color-divider against
//      --color-surface is 1.36:1 — a border that is invisible on the phone and
//      obvious in a screenshot.
//   2. Flutter's BoxShadow cannot draw an INSET shadow, so --elev-sheen
//      (inset 0 1px 0 rgba(255,255,255,.7)) is painted as a 1px top-edge
//      highlight inside the surface's own ClipRRect. Skip it and every card
//      sits a shade flatter than the specimen sheet.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_pressable.dart';

/// The one place a Calm background, radius, shadow and sheen are assembled.
/// Nothing outside lib/ui/calm/ may build a BoxDecoration.
class CalmSurface extends StatelessWidget {
  const CalmSurface({
    required this.child,
    required this.color,
    required this.radius,
    super.key,
    this.shadow = const <BoxShadow>[],
    this.sheen = true,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double radius;
  final List<BoxShadow> shadow;

  /// The inset top highlight. Off on `inverse` and on tinted surfaces, which
  /// carry no shadow to be lit from.
  final bool sheen;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // `sheen` is --elev-sheen carried as a Color on CalmColors, NOT on
    // CalmShapes: Flutter's BoxShadow has no inset mode, so the token is a
    // colour that this file paints as a 1px top-edge highlight.
    final colors = CalmColors.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            if (sheen)
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 1,
                child: IgnorePointer(child: ColoredBox(color: colors.sheen)),
              ),
          ],
        ),
      ),
    );
  }
}

enum CalmCardVariant { standard, lg, sm, tinted, flat, raised, quiet, inverse }

/// A card. Big radius, generous padding, layered warm shadow, no border.
class CalmCard extends StatelessWidget {
  const CalmCard({
    required this.child,
    super.key,
    this.variant = CalmCardVariant.standard,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final CalmCardVariant variant;
  final VoidCallback? onTap;
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
      CalmCardVariant.tinted || CalmCardVariant.flat || CalmCardVariant.quiet =>
        shapes.elev0,
      CalmCardVariant.raised || CalmCardVariant.inverse => shapes.elev2,
      _ => shapes.elev1,
    };
    // The ink ramp does not invert with the surface: an inverse card sets its
    // own foreground rather than reusing ink/ink2/ink3.
    final foreground =
        variant == CalmCardVariant.inverse ? colors.inkInverse : colors.ink;

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
      pressScale: kCalmPressScaleButton,
      semanticLabel: semanticLabel,
      child: surface,
    );
  }
}
