// CalmSurface — the one place a Calm background, radius, shadow and sheen are
// assembled.
//
// Flutter's BoxShadow cannot draw an INSET shadow, so `--elev-sheen`
// (`inset 0 1px 0 rgba(255,255,255,.7)`) is carried as a colour on CalmColors
// and painted here as a 1px top-edge highlight inside the surface's own
// ClipRRect. Skip it and every card sits a shade flatter than the specimen
// sheet.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// The one place a Calm background, radius, shadow and sheen are assembled.
/// Nothing outside lib/ui/calm/ may build a BoxDecoration.
class CalmSurface extends StatelessWidget {
  /// Creates a surface.
  const CalmSurface({
    required this.child,
    required this.color,
    required this.radius,
    super.key,
    this.shadow = const <BoxShadow>[],
    this.sheen = true,
    this.padding = EdgeInsets.zero,
    this.gradient,
  });

  /// What sits on it.
  final Widget child;

  /// Its ground, read from a Calm slot by the caller.
  final Color color;

  /// Its corner radius, from `CalmShapes`.
  final double radius;

  /// Its elevation layers, from `CalmShapes`. Empty means flat.
  final List<BoxShadow> shadow;

  /// The inset top highlight. Off on `inverse` and on tinted surfaces, which
  /// carry no shadow to be lit from.
  final bool sheen;

  /// Inset padding. Directional, so it mirrors.
  final EdgeInsetsGeometry padding;

  /// Replaces [color] when non-null: the due card's state-tint-to-surface
  /// fade, the all-clear's sage radial wash.
  ///
  /// It exists because two cards were building their own BoxDecoration to get
  /// one, and both then silently lost the sheen — `.due-card` and `.allclear`
  /// BOTH declare `--elev-sheen` in odova.css, and a missing parameter is not
  /// a design decision.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    // `sheen` is --elev-sheen carried as a Color on CalmColors, NOT on
    // CalmShapes: Flutter's BoxShadow has no inset mode, so the token is a
    // colour that this file paints as a 1px top-edge highlight.
    final colors = CalmColors.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
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
