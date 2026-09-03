// CalmShapes: the silhouettes, and the shadows that are part of them.
//
// In Calm a silhouette INCLUDES its shadow, because there is no border to fall
// back on. Radii are brightness-independent; the shadows are not — warm clay
// tint in light, black at roughly six times the alpha in dark — so this is the
// extension with two instances.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:odova/theme/calm/calm_palette.dart';

/// Converts a CSS `blur-radius` to Flutter's [BoxShadow.blurRadius].
///
/// CSS blur-radius is **2σ**; Flutter converts with
/// `Shadow.convertRadiusToSigma(r) = r * 0.57735 + 0.5`. Pasting the CSS number
/// straight in therefore ships a shadow 1.2–1.65× too soft — the ratio is
/// `1.155 + 1/cssBlur`, so 1.65× on the 2px first layer — and it survives
/// review because it looks exactly like the token. This introduces no design
/// value; it is a unit change, and
/// `test/theme/calm/calm_shapes_test.dart` re-derives it from the CSS.
double _blur(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;

BoxShadow _shadow(
  Color tint,
  double dy,
  double cssBlur,
  double spread,
  double alpha,
) => BoxShadow(
  offset: Offset(0, dy),
  blurRadius: _blur(cssBlur),
  spreadRadius: spread,
  color: tint.withValues(alpha: alpha),
);

/// `0 <dy>px <cssBlur>px <spread>px rgba(76, 50, 32, <alpha>)`.
BoxShadow _light(double dy, double cssBlur, double spread, double alpha) =>
    _shadow(CalmPalette.shadowTint, dy, cssBlur, spread, alpha);

/// The same, with `rgba(0, 0, 0, <alpha>)`.
BoxShadow _dark(double dy, double cssBlur, double spread, double alpha) =>
    _shadow(CalmPalette.shadowTintBlack, dy, cssBlur, spread, alpha);

/// Calm's radii and its five elevation levels.
@immutable
class CalmShapes extends ThemeExtension<CalmShapes> {
  /// Creates the slot set.
  const CalmShapes({
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radius2xl,
    required this.radius3xl,
    required this.radiusPill,
    required this.elev0,
    required this.elev1,
    required this.elev2,
    required this.elev3,
    required this.elev4,
  });

  /// `--radius-xs`. A mark inside a surface.
  final double radiusXs;

  /// `--radius-sm`. A small mark: a badge, a swatch.
  final double radiusSm;

  /// `--radius-md`. An icon tile.
  final double radiusMd;

  /// `--radius-lg`. A field.
  final double radiusLg;

  /// `--radius-xl`. A standalone row, a tile.
  final double radiusXl;

  /// `--radius-2xl`. A card. The most common silhouette in the app.
  final double radius2xl;

  /// `--radius-3xl`. A sheet, and the primary due card.
  final double radius3xl;

  /// `--radius-pill`, 999.
  ///
  /// A sentinel, not a measurement. Reach it only through a [StadiumBorder]:
  /// `BorderRadius.circular(999)` on a `ClipRRect` allocates a path Skia
  /// re-clamps on every frame, and it renders almost right.
  final double radiusPill;

  /// `--elev-0`. Flat. `--elev-0` is `none`, so this is an empty list
  /// rather than a
  /// transparent shadow — Flutter paints nothing for an empty list.
  final List<BoxShadow> elev0;

  /// `--elev-1`. A card at rest. Two stacked layers, already unit-converted.
  final List<BoxShadow> elev1;

  /// `--elev-2`. A raised card, and a pressed sheet.
  final List<BoxShadow> elev2;

  /// `--elev-3`. A sheet.
  final List<BoxShadow> elev3;

  /// `--elev-4`. A dialog — the highest thing on screen.
  final List<BoxShadow> elev4;

  /// The slots for this [BuildContext]'s theme.
  static CalmShapes of(BuildContext context) {
    final extension = Theme.of(context).extension<CalmShapes>();
    assert(
      extension != null,
      'CalmShapes is missing from this ThemeData. Build it with '
      'buildCalmTheme().',
    );
    return extension!;
  }

  /// The card silhouette. Components ask for a shape, never a number, so
  /// re-shaping the whole system is one edit.
  RoundedRectangleBorder card() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius2xl));

  /// The sheet silhouette: top corners only, per `.sheet` in odova.css.
  RoundedRectangleBorder sheet() => RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius3xl)),
  );

  @override
  CalmShapes copyWith({
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radius2xl,
    double? radius3xl,
    double? radiusPill,
    List<BoxShadow>? elev0,
    List<BoxShadow>? elev1,
    List<BoxShadow>? elev2,
    List<BoxShadow>? elev3,
    List<BoxShadow>? elev4,
  }) {
    return CalmShapes(
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radius2xl: radius2xl ?? this.radius2xl,
      radius3xl: radius3xl ?? this.radius3xl,
      radiusPill: radiusPill ?? this.radiusPill,
      elev0: elev0 ?? this.elev0,
      elev1: elev1 ?? this.elev1,
      elev2: elev2 ?? this.elev2,
      elev3: elev3 ?? this.elev3,
      elev4: elev4 ?? this.elev4,
    );
  }

  /// Interpolates every slot towards [other].
  ///
  /// Shadow lists interpolate with [BoxShadow.lerpList], which handles a
  /// length mismatch by fading the extra layers — `elev0` is empty, so a
  /// flat-to-raised transition works.
  @override
  CalmShapes lerp(covariant CalmShapes? other, double t) {
    if (other == null) return this;
    return CalmShapes(
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radius2xl: lerpDouble(radius2xl, other.radius2xl, t)!,
      radius3xl: lerpDouble(radius3xl, other.radius3xl, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      elev0: BoxShadow.lerpList(elev0, other.elev0, t)!,
      elev1: BoxShadow.lerpList(elev1, other.elev1, t)!,
      elev2: BoxShadow.lerpList(elev2, other.elev2, t)!,
      elev3: BoxShadow.lerpList(elev3, other.elev3, t)!,
      elev4: BoxShadow.lerpList(elev4, other.elev4, t)!,
    );
  }
}

/// Calm's light shapes: `:root`'s `--elev-*`, warm clay tint.
final calmShapesLight = CalmShapes(
  radiusXs: 8,
  radiusSm: 12,
  radiusMd: 16,
  radiusLg: 20,
  radiusXl: 24,
  radius2xl: 28,
  radius3xl: 36,
  radiusPill: 999,
  elev0: const [],
  elev1: [
    _light(1, 2, 0, 0.05),
    _light(2, 8, 0, 0.05),
  ],
  elev2: [
    _light(2, 4, 0, 0.05),
    _light(10, 22, -6, 0.10),
  ],
  elev3: [
    _light(4, 10, 0, 0.06),
    _light(20, 40, -10, 0.14),
  ],
  elev4: [
    _light(8, 18, 0, 0.08),
    _light(36, 68, -14, 0.20),
  ],
);

/// Calm's dark shapes: `[data-theme="dark"]`'s `--elev-*`, pure black at
/// roughly six times the alpha. Elevation in dark is carried by surface tint
/// far more than by shadow, so these are darker, not lighter.
final calmShapesDark = CalmShapes(
  radiusXs: 8,
  radiusSm: 12,
  radiusMd: 16,
  radiusLg: 20,
  radiusXl: 24,
  radius2xl: 28,
  radius3xl: 36,
  radiusPill: 999,
  elev0: const [],
  elev1: [
    _dark(1, 2, 0, 0.32),
    _dark(2, 8, 0, 0.22),
  ],
  elev2: [
    _dark(2, 6, 0, 0.36),
    _dark(12, 24, -8, 0.42),
  ],
  elev3: [
    _dark(6, 14, 0, 0.40),
    _dark(24, 44, -12, 0.50),
  ],
  elev4: [
    _dark(10, 22, 0, 0.46),
    _dark(40, 76, -16, 0.62),
  ],
);
