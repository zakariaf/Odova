// lib/theme/calm/{calm_shapes,calm_motion}.dart
//
// CalmShapes carries radii AND elevation, because in Calm a silhouette includes
// its shadow — there is no border to fall back on. Radii are brightness-
// independent; the shadows are not (warm clay tint in light, black in dark), so
// CalmShapes is the second extension with two instances.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'calm_palette.dart';

// CSS blur-radius is 2 sigma. Flutter converts BoxShadow.blurRadius with
// Shadow.convertRadiusToSigma(r) = r * 0.57735 + 0.5. Pasting the CSS number
// straight into blurRadius therefore ships a shadow 1.2-1.65x too soft (worst on
// the tight 2px layer), which is why hand-ported Calm shadows look mushy. This
// is the inverse of that map; it introduces no design value, only a unit change.
double _blur(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;

BoxShadow _sh(Color tint, double dy, double cssBlur, double spread, double alpha) => BoxShadow(
      offset: Offset(0, dy),
      blurRadius: _blur(cssBlur),
      spreadRadius: spread,
      color: tint.withValues(alpha: alpha),
    );

/// `0 <dy>px <cssBlur>px <spread>px rgba(76, 50, 32, <alpha>)`.
BoxShadow _l(double dy, double cssBlur, double spread, double alpha) =>
    _sh(CalmPalette.shadowTint, dy, cssBlur, spread, alpha);

/// The same, with `rgba(0, 0, 0, <alpha>)`.
BoxShadow _d(double dy, double cssBlur, double spread, double alpha) =>
    _sh(CalmPalette.shadowTintDark, dy, cssBlur, spread, alpha);

@immutable
class CalmShapes extends ThemeExtension<CalmShapes> {
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

  // --radius-xs .. --radius-3xl. Calm's silhouettes are 16-36 for anything the
  // user thinks of as a surface; 8 and 12 are for marks inside one.
  final double radiusXs, radiusSm, radiusMd, radiusLg, radiusXl, radius2xl, radius3xl;

  /// --radius-pill, 999. A sentinel, not a measurement: reach it only through
  /// [pill], never BorderRadius.circular(radiusPill) on a ClipRRect — Skia
  /// re-clamps that path every frame.
  final double radiusPill;

  // --elev-0 .. --elev-4, both stacked shadows each, already unit-converted.
  final List<BoxShadow> elev0, elev1, elev2, elev3, elev4;

  static CalmShapes of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmShapes>();
    assert(ext != null, 'CalmShapes missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  /// The card silhouette. Components ask for a shape, never a number, so a
  /// re-shape of the whole system is one edit.
  RoundedRectangleBorder card() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius2xl));

  /// The sheet silhouette: top corners only, per `.sheet` in odova.css
  /// (border-start-start-radius / border-start-end-radius: --radius-3xl).
  RoundedRectangleBorder sheet() => RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius3xl)),
      );

  StadiumBorder pill() => const StadiumBorder();

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

CalmShapes _shapes({
  required List<BoxShadow> elev1,
  required List<BoxShadow> elev2,
  required List<BoxShadow> elev3,
  required List<BoxShadow> elev4,
}) =>
    CalmShapes(
      radiusXs: 8,
      radiusSm: 12,
      radiusMd: 16,
      radiusLg: 20,
      radiusXl: 24,
      radius2xl: 28,
      radius3xl: 36,
      radiusPill: 999,
      elev0: const <BoxShadow>[], // --elev-0: none
      elev1: elev1,
      elev2: elev2,
      elev3: elev3,
      elev4: elev4,
    );

/// --elev-1 .. --elev-4 under `:root`.
final calmShapesLight = _shapes(
  elev1: <BoxShadow>[_l(1, 2, 0, 0.05), _l(2, 8, 0, 0.05)],
  elev2: <BoxShadow>[_l(2, 4, 0, 0.05), _l(10, 22, -6, 0.10)],
  elev3: <BoxShadow>[_l(4, 10, 0, 0.06), _l(20, 40, -10, 0.14)],
  elev4: <BoxShadow>[_l(8, 18, 0, 0.08), _l(36, 68, -14, 0.20)],
);

/// --elev-1 .. --elev-4 under `[data-theme="dark"]`. Black, and far heavier: a
/// warm tint on a warm charcoal ground reads as a smudge, not a lift.
final calmShapesDark = _shapes(
  elev1: <BoxShadow>[_d(1, 2, 0, 0.32), _d(2, 8, 0, 0.22)],
  elev2: <BoxShadow>[_d(2, 6, 0, 0.36), _d(12, 24, -8, 0.42)],
  elev3: <BoxShadow>[_d(6, 14, 0, 0.40), _d(24, 44, -12, 0.50)],
  elev4: <BoxShadow>[_d(10, 22, 0, 0.46), _d(40, 76, -16, 0.62)],
);

@immutable
class CalmMotion extends ThemeExtension<CalmMotion> {
  const CalmMotion({
    required this.instant,
    required this.quick,
    required this.base,
    required this.slow,
    required this.sheet,
    required this.easeStandard,
    required this.easeOut,
    required this.easeIn,
    required this.easeSettle,
  });

  // --dur-*.
  final Duration instant, quick, base, slow, sheet;

  /// --ease-*. `easeSettle` overshoots (y1 = 1.24): use it for transforms,
  /// never for a colour, which would interpolate past the target and clamp
  /// visibly.
  final Curve easeStandard, easeOut, easeIn, easeSettle;

  static CalmMotion of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmMotion>();
    assert(ext != null, 'CalmMotion missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  /// The one place a widget asks "how long?". Reduced motion collapses to zero,
  /// never to a shorter duration — the user asked for stop. The catalogue of
  /// which moment spends which token is owned by calm-layout-and-motion.
  static Duration resolve(BuildContext context, Duration full) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;

  @override
  CalmMotion copyWith({
    Duration? instant,
    Duration? quick,
    Duration? base,
    Duration? slow,
    Duration? sheet,
    Curve? easeStandard,
    Curve? easeOut,
    Curve? easeIn,
    Curve? easeSettle,
  }) {
    return CalmMotion(
      instant: instant ?? this.instant,
      quick: quick ?? this.quick,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      sheet: sheet ?? this.sheet,
      easeStandard: easeStandard ?? this.easeStandard,
      easeOut: easeOut ?? this.easeOut,
      easeIn: easeIn ?? this.easeIn,
      easeSettle: easeSettle ?? this.easeSettle,
    );
  }

  /// DELIBERATE STEP, not an unfinished lerp. A half-interpolated duration or
  /// curve is not observable: both are read once, when an animation starts.
  /// `t < 0.5 ? this : other` (never `return this`) so both endpoints land.
  @override
  CalmMotion lerp(covariant CalmMotion? other, double t) {
    if (other == null) return this;
    return CalmMotion(
      instant: t < 0.5 ? instant : other.instant,
      quick: t < 0.5 ? quick : other.quick,
      base: t < 0.5 ? base : other.base,
      slow: t < 0.5 ? slow : other.slow,
      sheet: t < 0.5 ? sheet : other.sheet,
      easeStandard: t < 0.5 ? easeStandard : other.easeStandard,
      easeOut: t < 0.5 ? easeOut : other.easeOut,
      easeIn: t < 0.5 ? easeIn : other.easeIn,
      easeSettle: t < 0.5 ? easeSettle : other.easeSettle,
    );
  }
}

const calmMotion = CalmMotion(
  instant: Duration(milliseconds: 90),
  quick: Duration(milliseconds: 160),
  base: Duration(milliseconds: 240),
  slow: Duration(milliseconds: 360),
  sheet: Duration(milliseconds: 420),
  easeStandard: Cubic(0.32, 0.72, 0, 1),
  easeOut: Cubic(0.2, 0.8, 0.2, 1),
  easeIn: Cubic(0.4, 0, 1, 1),
  easeSettle: Cubic(0.34, 1.24, 0.64, 1),
);
