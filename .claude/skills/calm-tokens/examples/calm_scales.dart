// lib/theme/calm/{calm_type,calm_space,calm_shapes,calm_motion}.dart
//
// The four non-colour extensions, shown together so the shared shape is visible;
// in the app they are four files, matching the contract layout. Every number is
// from design/calm/odova.css. The only arithmetic here is unit conversion
// (CSS em -> logical px, CSS blur-radius -> Flutter blurRadius), each stated inline.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// --font-latin, verbatim from the token. Every name in it is a system or
// proprietary face — none is bundleable and the design names no substitute; the
// CSS generics (system-ui, -apple-system, sans-serif) have no Flutter equivalent
// and are dropped. calm-typography-and-rtl owns the replacement face and the
// Vazirmatn cascade for fa/ar/ckb.
const _latinFamily = 'Avenir Next';
const _latinFallback = <String>['Avenir', 'Optima', 'Helvetica Neue'];

// --tracking-*. CSS em is relative to font-size; Flutter letterSpacing is
// logical pixels. Multiply, always: pasting -0.02 into letterSpacing is a 46x
// error at display size that reads as "tracking does nothing".
const _trackTight = -0.02;
const _trackNormal = -0.005;

TextStyle _role(double fs, double lh, FontWeight fw, double trackingEm) => TextStyle(
      fontFamily: _latinFamily,
      fontFamilyFallback: _latinFallback,
      fontSize: fs,
      height: lh,
      fontWeight: fw,
      letterSpacing: fs * trackingEm,
    );

@immutable
class CalmType extends ThemeExtension<CalmType> {
  const CalmType({
    required this.display,
    required this.hero,
    required this.titleLg,
    required this.title,
    required this.headline,
    required this.bodyLg,
    required this.body,
    required this.label,
    required this.caption,
    required this.regular,
    required this.medium,
    required this.semi,
  });

  // --fs-x / --lh-x plus the weight and tracking the .t-x utility applies.
  // Nothing below 13px exists: `caption` IS the floor.
  final TextStyle display, hero, titleLg, title, headline, bodyLg, body, label, caption;

  /// --fw-regular 400, --fw-medium 500, --fw-semi 600. Slots, so a component can
  /// step a role up in weight (`type.body.copyWith(fontWeight: type.semi)`)
  /// without inventing a fontSize. --fw-bold 700 is deliberately not exposed:
  /// no `.t-*` role uses it, and a slot nobody fills is a slot someone misuses.
  final FontWeight regular, medium, semi;

  static CalmType of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmType>();
    assert(ext != null, 'CalmType missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmType copyWith({
    TextStyle? display,
    TextStyle? hero,
    TextStyle? titleLg,
    TextStyle? title,
    TextStyle? headline,
    TextStyle? bodyLg,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
    FontWeight? regular,
    FontWeight? medium,
    FontWeight? semi,
  }) {
    return CalmType(
      display: display ?? this.display,
      hero: hero ?? this.hero,
      titleLg: titleLg ?? this.titleLg,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      bodyLg: bodyLg ?? this.bodyLg,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      regular: regular ?? this.regular,
      medium: medium ?? this.medium,
      semi: semi ?? this.semi,
    );
  }

  @override
  CalmType lerp(covariant CalmType? other, double t) {
    if (other == null) return this;
    return CalmType(
      display: TextStyle.lerp(display, other.display, t)!,
      hero: TextStyle.lerp(hero, other.hero, t)!,
      titleLg: TextStyle.lerp(titleLg, other.titleLg, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      // DELIBERATE STEP, like CalmMotion's: a weight is a discrete slot, the
      // same in both themes, so there is nothing to interpolate. `t < 0.5`
      // rather than `return this` so both endpoints still land.
      regular: t < 0.5 ? regular : other.regular,
      medium: t < 0.5 ? medium : other.medium,
      semi: t < 0.5 ? semi : other.semi,
    );
  }
}

// One instance: the type scale is brightness-independent. Colour comes from
// CalmColors at the call site, never baked into a TextStyle.
final calmType = CalmType(
  display: _role(46, 1.04, FontWeight.w600, _trackTight),
  hero: _role(34, 1.12, FontWeight.w600, _trackTight),
  titleLg: _role(27, 1.18, FontWeight.w600, _trackTight),
  title: _role(22, 1.26, FontWeight.w600, _trackTight),
  headline: _role(19, 1.32, FontWeight.w600, _trackNormal),
  bodyLg: _role(17, 1.50, FontWeight.w400, _trackNormal),
  body: _role(15, 1.55, FontWeight.w400, _trackNormal),
  label: _role(14, 1.40, FontWeight.w500, _trackNormal),
  caption: _role(13, 1.45, FontWeight.w500, _trackNormal),
  regular: FontWeight.w400, // --fw-regular
  medium: FontWeight.w500, // --fw-medium
  semi: FontWeight.w600, // --fw-semi
);

@immutable
class CalmSpace extends ThemeExtension<CalmSpace> {
  const CalmSpace({
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.s5,
    required this.s6,
    required this.s7,
    required this.s8,
    required this.s9,
    required this.s10,
    required this.screenPad,
    required this.appbarH,
    required this.statusbarH,
    required this.tabbarH,
    required this.homebarH,
    required this.touchMin,
  });

  // --space-1 .. --space-10. NOT a x2 scale past s6 — never compute a step.
  final double s1, s2, s3, s4, s5, s6, s7, s8, s9, s10;

  // Metrics are distances, so they live here. screenPad is off-ramp on purpose:
  // it is the gutter, not a spacing step. touchMin is 52, not Material's 48 —
  // SPEC.md §1, logging happens at a pump, in the rain, one-handed.
  final double screenPad, appbarH, statusbarH, tabbarH, homebarH, touchMin;

  static CalmSpace of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmSpace>();
    assert(ext != null, 'CalmSpace missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmSpace copyWith({
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    double? s5,
    double? s6,
    double? s7,
    double? s8,
    double? s9,
    double? s10,
    double? screenPad,
    double? appbarH,
    double? statusbarH,
    double? tabbarH,
    double? homebarH,
    double? touchMin,
  }) {
    return CalmSpace(
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      s4: s4 ?? this.s4,
      s5: s5 ?? this.s5,
      s6: s6 ?? this.s6,
      s7: s7 ?? this.s7,
      s8: s8 ?? this.s8,
      s9: s9 ?? this.s9,
      s10: s10 ?? this.s10,
      screenPad: screenPad ?? this.screenPad,
      appbarH: appbarH ?? this.appbarH,
      statusbarH: statusbarH ?? this.statusbarH,
      tabbarH: tabbarH ?? this.tabbarH,
      homebarH: homebarH ?? this.homebarH,
      touchMin: touchMin ?? this.touchMin,
    );
  }

  @override
  CalmSpace lerp(covariant CalmSpace? other, double t) {
    if (other == null) return this;
    return CalmSpace(
      s1: lerpDouble(s1, other.s1, t)!,
      s2: lerpDouble(s2, other.s2, t)!,
      s3: lerpDouble(s3, other.s3, t)!,
      s4: lerpDouble(s4, other.s4, t)!,
      s5: lerpDouble(s5, other.s5, t)!,
      s6: lerpDouble(s6, other.s6, t)!,
      s7: lerpDouble(s7, other.s7, t)!,
      s8: lerpDouble(s8, other.s8, t)!,
      s9: lerpDouble(s9, other.s9, t)!,
      s10: lerpDouble(s10, other.s10, t)!,
      screenPad: lerpDouble(screenPad, other.screenPad, t)!,
      appbarH: lerpDouble(appbarH, other.appbarH, t)!,
      statusbarH: lerpDouble(statusbarH, other.statusbarH, t)!,
      tabbarH: lerpDouble(tabbarH, other.tabbarH, t)!,
      homebarH: lerpDouble(homebarH, other.homebarH, t)!,
      touchMin: lerpDouble(touchMin, other.touchMin, t)!,
    );
  }
}

const calmSpace = CalmSpace(
  s1: 4,
  s2: 8,
  s3: 12,
  s4: 16,
  s5: 20,
  s6: 24,
  s7: 32,
  s8: 40,
  s9: 56,
  s10: 72,
  screenPad: 22,
  appbarH: 56,
  statusbarH: 54,
  tabbarH: 62,
  homebarH: 34,
  touchMin: 52,
);
