// The Calm token slots this directory's examples read, trimmed to what they use.
// The real, complete extensions — every colour, every step, the hand-authored
// light and dark ColorScheme — are owned by `calm-tokens`. Everything here is a
// value from tokens.json, and this file stands in for lib/theme/calm/, the one
// directory where a raw value is legal.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// `--space-*` (4 8 12 16 20 24 32 40), `--screen-pad` 22, `--touch-min` 52,
/// `--appbar-h` 56, `--tabbar-h` 62.
@immutable
class CalmSpace extends ThemeExtension<CalmSpace> {
  const CalmSpace({
    required this.s2, required this.s3, required this.s4, required this.s5,
    required this.s6, required this.s7, required this.s8,
    required this.screenPad, required this.touchMin,
    required this.appbarH, required this.tabbarH,
  });

  final double s2, s3, s4, s5, s6, s7, s8;
  final double screenPad; // the horizontal gutter, and nothing else
  final double touchMin; // the floor on every hit rect
  final double appbarH, tabbarH;

  // `.tabbar__fab` is 62px with an 18px lift in odova.css; neither figure reached
  // tokens.json (see this skill's findings), so they are named here rather than
  // inlined in a widget.
  double get tabFabSize => 62;
  double get tabFabLift => 18;

  static CalmSpace of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmSpace>();
    assert(ext != null, 'CalmSpace missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmSpace copyWith({double? s2, double? s3, double? s4, double? s5, double? s6,
          double? s7, double? s8, double? screenPad, double? touchMin,
          double? appbarH, double? tabbarH}) =>
      CalmSpace(
          s2: s2 ?? this.s2, s3: s3 ?? this.s3, s4: s4 ?? this.s4,
          s5: s5 ?? this.s5, s6: s6 ?? this.s6, s7: s7 ?? this.s7,
          s8: s8 ?? this.s8, screenPad: screenPad ?? this.screenPad,
          touchMin: touchMin ?? this.touchMin, appbarH: appbarH ?? this.appbarH,
          tabbarH: tabbarH ?? this.tabbarH);

  @override
  CalmSpace lerp(covariant CalmSpace? other, double t) {
    if (other == null) return this;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return CalmSpace(
        s2: d(s2, other.s2), s3: d(s3, other.s3), s4: d(s4, other.s4),
        s5: d(s5, other.s5), s6: d(s6, other.s6), s7: d(s7, other.s7),
        s8: d(s8, other.s8), screenPad: d(screenPad, other.screenPad),
        touchMin: d(touchMin, other.touchMin), appbarH: d(appbarH, other.appbarH),
        tabbarH: d(tabbarH, other.tabbarH));
  }
}

const calmSpace = CalmSpace(
  s2: 8, s3: 12, s4: 16, s5: 20, s6: 24, s7: 32, s8: 40,
  screenPad: 22, touchMin: 52, appbarH: 56, tabbarH: 62,
);

/// One semantic family: the four rungs every Calm state colour ships with.
/// Owned by `calm-tokens`; repeated here so this directory's examples compile
/// alone. `base` is the graphic, `ink` is text on `tint`, `edge` bounds `tint`.
@immutable
class CalmRamp {
  const CalmRamp({required this.base, required this.ink, required this.tint, required this.edge});

  final Color base, ink, tint, edge;

  /// Instance form, matching `calm-tokens`' `calm_colors.dart`. The static
  /// `lerp(a, b, t)` shape reads fine but defeats
  /// `calm-tokens/scripts/check_extension_fields.sh`, which looks for
  /// `other.<field>` to prove every field is actually carried.
  CalmRamp copyWith({Color? base, Color? ink, Color? tint, Color? edge}) => CalmRamp(
        base: base ?? this.base, ink: ink ?? this.ink,
        tint: tint ?? this.tint, edge: edge ?? this.edge,
      );

  CalmRamp lerp(CalmRamp other, double t) => CalmRamp(
        base: Color.lerp(base, other.base, t)!, ink: Color.lerp(ink, other.ink, t)!,
        tint: Color.lerp(tint, other.tint, t)!, edge: Color.lerp(edge, other.edge, t)!,
      );
}

@immutable
class CalmColors extends ThemeExtension<CalmColors> {
  const CalmColors({
    required this.bg, required this.surface, required this.surface2,
    required this.ink, required this.ink2, required this.divider,
    required this.brand, required this.onBrand,
    required this.ok, required this.scrim,
  });

  final Color bg, surface, surface2, ink, ink2, divider, brand, onBrand;

  /// A ramp, never four flat slots: `colors.ok.tint`, never `colors.okTint`.
  final CalmRamp ok;

  final Color scrim;

  static CalmColors of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmColors>();
    assert(ext != null, 'CalmColors missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmColors copyWith({Color? bg, Color? surface, Color? surface2, Color? ink,
          Color? ink2, Color? divider, Color? brand, Color? onBrand,
          CalmRamp? ok, Color? scrim}) =>
      CalmColors(
          bg: bg ?? this.bg, surface: surface ?? this.surface,
          surface2: surface2 ?? this.surface2, ink: ink ?? this.ink,
          ink2: ink2 ?? this.ink2, divider: divider ?? this.divider,
          brand: brand ?? this.brand, onBrand: onBrand ?? this.onBrand,
          ok: ok ?? this.ok, scrim: scrim ?? this.scrim);

  @override
  CalmColors lerp(covariant CalmColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return CalmColors(
        bg: c(bg, other.bg), surface: c(surface, other.surface),
        surface2: c(surface2, other.surface2), ink: c(ink, other.ink),
        ink2: c(ink2, other.ink2), divider: c(divider, other.divider),
        brand: c(brand, other.brand), onBrand: c(onBrand, other.onBrand),
        ok: ok.lerp(other.ok, t), scrim: c(scrim, other.scrim));
  }
}

// Note the absentee: `--color-ink-3` (#8B7B6C) is NOT exposed here. It measures
// 3.99:1 on --color-surface and 3.42:1 on --color-surface-2, so it fails AA for
// the 13px caption text it is used on throughout odova.css. These examples use
// `ink2` (7.81:1) for every secondary line. See this skill's findings.
const calmColorsLight = CalmColors(
  bg: Color(0xFFF8F2E9), // --color-bg
  surface: Color(0xFFFFFCF7), // --color-surface
  surface2: Color(0xFFF3EADC), // --color-surface-2
  ink: Color(0xFF2C241E), // --color-ink
  ink2: Color(0xFF5C4E43), // --color-ink-2
  divider: Color(0xFFE6D9C6), // --color-divider
  brand: Color(0xFF7A5340), // --color-brand
  onBrand: Color(0xFFFFF9F1), // --color-on-brand
  ok: CalmRamp(
    base: Color(0xFF5D7B60), // --color-ok
    ink: Color(0xFF435C46), // --color-ok-ink
    tint: Color(0xFFE4EDE1), // --color-ok-tint
    edge: Color(0xFFC7DAC4), // --color-ok-edge
  ),
  scrim: Color(0x702C221A), // --scrim rgba(44, 34, 26, 0.44)
);

const calmColorsDark = CalmColors(
  bg: Color(0xFF1D1815),
  surface: Color(0xFF272019),
  surface2: Color(0xFF31281F),
  ink: Color(0xFFF3EADE),
  ink2: Color(0xFFC6B6A4),
  divider: Color(0xFF3A3028),
  brand: Color(0xFFD3A480),
  onBrand: Color(0xFF2A1E15),
  ok: CalmRamp(
    base: Color(0xFF9CBF9E),
    ink: Color(0xFFBBD5BC),
    tint: Color(0xFF25311F),
    edge: Color(0xFF35452D),
  ),
  scrim: Color(0x9E0C0907), // --scrim rgba(12, 9, 7, 0.62)
);

/// `--fs-*` and `--lh-*` collapse into one TextStyle per slot, per the contract.
@immutable
class CalmType extends ThemeExtension<CalmType> {
  const CalmType({
    required this.titleLg, required this.title,
    required this.headline, required this.bodyLg, required this.caption,
  });

  final TextStyle titleLg, title, headline, bodyLg, caption;

  static CalmType of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmType>();
    assert(ext != null, 'CalmType missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmType copyWith({TextStyle? titleLg, TextStyle? title, TextStyle? headline,
          TextStyle? bodyLg, TextStyle? caption}) =>
      CalmType(
          titleLg: titleLg ?? this.titleLg, title: title ?? this.title,
          headline: headline ?? this.headline, bodyLg: bodyLg ?? this.bodyLg,
          caption: caption ?? this.caption);

  @override
  CalmType lerp(covariant CalmType? other, double t) {
    if (other == null) return this;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return CalmType(
        titleLg: s(titleLg, other.titleLg), title: s(title, other.title),
        headline: s(headline, other.headline), bodyLg: s(bodyLg, other.bodyLg),
        caption: s(caption, other.caption));
  }
}

const calmType = CalmType(
  // 27/1.18 semibold, --tracking-tight -0.02em -> -0.54 at 27px
  titleLg: TextStyle(fontSize: 27, height: 1.18, fontWeight: FontWeight.w600, letterSpacing: -0.54),
  title: TextStyle(fontSize: 22, height: 1.26, fontWeight: FontWeight.w600, letterSpacing: -0.44),
  headline: TextStyle(fontSize: 19, height: 1.32, fontWeight: FontWeight.w600),
  bodyLg: TextStyle(fontSize: 17, height: 1.5),
  // --fs-caption 13: the floor. Nothing in Calm is smaller, in any locale.
  caption: TextStyle(fontSize: 13, height: 1.45),
);

/// Radii and elevation. `--elev-*` is layered, low-opacity and warm-tinted, never
/// a border; the five-extension contract has no CalmElevation, so it rides here.
@immutable
class CalmShapes extends ThemeExtension<CalmShapes> {
  const CalmShapes({required this.radiusXl, required this.radius3xl, required this.elev2});

  final BorderRadius radiusXl; // --radius-xl 24
  final BorderRadius radius3xl; // --radius-3xl 36
  final List<BoxShadow> elev2;

  static CalmShapes of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmShapes>();
    assert(ext != null, 'CalmShapes missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmShapes copyWith({BorderRadius? radiusXl, BorderRadius? radius3xl, List<BoxShadow>? elev2}) =>
      CalmShapes(
          radiusXl: radiusXl ?? this.radiusXl,
          radius3xl: radius3xl ?? this.radius3xl,
          elev2: elev2 ?? this.elev2);

  @override
  CalmShapes lerp(covariant CalmShapes? other, double t) {
    if (other == null) return this;
    return CalmShapes(
        radiusXl: BorderRadius.lerp(radiusXl, other.radiusXl, t)!,
        radius3xl: BorderRadius.lerp(radius3xl, other.radius3xl, t)!,
        elev2: BoxShadow.lerpList(elev2, other.elev2, t)!);
  }
}

const calmShapesLight = CalmShapes(
  radiusXl: BorderRadius.all(Radius.circular(24)),
  radius3xl: BorderRadius.all(Radius.circular(36)),
  // --elev-2: 0 2px 4px rgba(76,50,32,.05), 0 10px 22px -6px rgba(76,50,32,.10)
  elev2: [
    BoxShadow(color: Color(0x0D4C3220), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A4C3220), blurRadius: 22, spreadRadius: -6, offset: Offset(0, 10)),
  ],
);
