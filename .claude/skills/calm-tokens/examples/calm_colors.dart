// lib/theme/calm/calm_colors.dart — TIER 2. The 58 semantic colour slots.
//
// Widgets read THESE, never CalmPalette: a widget that names a primitive has
// hardcoded one brightness. The two instances live in calm_theme.dart, so this
// file is pure structure and can be reviewed without reading a single hex.
//
// The seven CalmRamp fields are deliberately NOT flat colours. SPEC.md §9 makes
// due status a three-signal thing (dot shape, colour, wording) and forbids the
// app from guessing in a way that looks like fact; a ramp keeps the graphic
// colour and the text colour apart so no one can render 13px text in a 3.44:1
// status base. Resolution goes through CalmStatusStyle — see
// calm-due-state-and-status. Nothing outside lib/theme/calm/ reads .overdue.
import 'package:flutter/material.dart';

/// One semantic family: the four rungs every Calm state colour ships with.
@immutable
class CalmRamp {
  const CalmRamp({
    required this.base,
    required this.ink,
    required this.tint,
    required this.edge,
  });

  /// The graphic — status dot, ring, progress fill, chart mark. Held to 3:1
  /// against its background; several bases are under 4.5 and MUST NOT carry text.
  final Color base;

  /// Text on [tint]. Every ink/tint pair in Calm clears 4.5:1 in both themes.
  final Color ink;

  /// The fill behind [ink].
  final Color tint;

  /// The 1px boundary of [tint]. Calm has no hard borders elsewhere.
  final Color edge;

  CalmRamp copyWith({Color? base, Color? ink, Color? tint, Color? edge}) => CalmRamp(
        base: base ?? this.base,
        ink: ink ?? this.ink,
        tint: tint ?? this.tint,
        edge: edge ?? this.edge,
      );

  CalmRamp lerp(CalmRamp other, double t) => CalmRamp(
        base: Color.lerp(base, other.base, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        tint: Color.lerp(tint, other.tint, t)!,
        edge: Color.lerp(edge, other.edge, t)!,
      );
}

@immutable
class CalmColors extends ThemeExtension<CalmColors> {
  const CalmColors({
    required this.bg,
    required this.bgSunk,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.surfaceInverse,
    required this.divider,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.inkInverse,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.brandSoftInk,
    required this.onBrand,
    required this.danger,
    required this.dangerTint,
    required this.focus,
    required this.scrim,
    required this.sheen,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.chartGrid,
    required this.chartAxisInk,
    required this.chartPlot,
    required this.overdue,
    required this.due,
    required this.dueSoon,
    required this.ok,
    required this.unknown,
    required this.needsOdometer,
    required this.business,
  });

  // Surface ramp: --color-bg .. --color-divider.
  final Color bg, bgSunk, surface, surface2, surface3, surfaceInverse, divider;

  // Ink ramp. ink3 is below AA on every light surface — see contrast-audit.md.
  final Color ink, ink2, ink3, ink4, inkInverse;

  // Brand. Calm ships exactly one brand hue; there is no secondary.
  final Color brand, brandStrong, brandSoft, brandSoftInk, onBrand;

  // Destructive, focus, and the two overlay colours. `danger` is for delete
  // and restore, never for a due state — overdue is terracotta, not an alarm.
  // `sheen` is --elev-sheen, an INSET shadow: Flutter has none, so it is carried
  // as a colour and painted as a 1px top highlight by CalmCard.
  final Color danger, dangerTint, focus, scrim, sheen;

  // Chart. chart1..5 alias brand/ok/due/dueSoon/business in both themes, on
  // purpose: a legend swatch and a status dot must never disagree.
  final Color chart1, chart2, chart3, chart4, chart5, chartGrid, chartAxisInk, chartPlot;

  // Semantic families. Read via CalmStatusStyle, never directly.
  final CalmRamp overdue, due, dueSoon, ok, unknown, needsOdometer, business;

  /// Assert, never `?? fallback`: a fallback would ship a palette no contrast
  /// test has ever seen, which is the one failure this extension exists to stop.
  static CalmColors of(BuildContext context) {
    final ext = Theme.of(context).extension<CalmColors>();
    assert(ext != null, 'CalmColors missing. Build ThemeData via buildCalmTheme().');
    return ext!;
  }

  @override
  CalmColors copyWith({
    Color? bg,
    Color? bgSunk,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? surfaceInverse,
    Color? divider,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? inkInverse,
    Color? brand,
    Color? brandStrong,
    Color? brandSoft,
    Color? brandSoftInk,
    Color? onBrand,
    Color? danger,
    Color? dangerTint,
    Color? focus,
    Color? scrim,
    Color? sheen,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? chartGrid,
    Color? chartAxisInk,
    Color? chartPlot,
    CalmRamp? overdue,
    CalmRamp? due,
    CalmRamp? dueSoon,
    CalmRamp? ok,
    CalmRamp? unknown,
    CalmRamp? needsOdometer,
    CalmRamp? business,
  }) {
    return CalmColors(
      bg: bg ?? this.bg,
      bgSunk: bgSunk ?? this.bgSunk,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      inkInverse: inkInverse ?? this.inkInverse,
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandSoft: brandSoft ?? this.brandSoft,
      brandSoftInk: brandSoftInk ?? this.brandSoftInk,
      onBrand: onBrand ?? this.onBrand,
      danger: danger ?? this.danger,
      dangerTint: dangerTint ?? this.dangerTint,
      focus: focus ?? this.focus,
      scrim: scrim ?? this.scrim,
      sheen: sheen ?? this.sheen,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      chartGrid: chartGrid ?? this.chartGrid,
      chartAxisInk: chartAxisInk ?? this.chartAxisInk,
      chartPlot: chartPlot ?? this.chartPlot,
      overdue: overdue ?? this.overdue,
      due: due ?? this.due,
      dueSoon: dueSoon ?? this.dueSoon,
      ok: ok ?? this.ok,
      unknown: unknown ?? this.unknown,
      needsOdometer: needsOdometer ?? this.needsOdometer,
      business: business ?? this.business,
    );
  }

  /// Every field, every time. A slot added to the constructor and forgotten
  /// here transitions as a hard cut forever and nothing catches it — which is
  /// exactly what scripts/check_extension_fields.sh greps for.
  @override
  CalmColors lerp(covariant CalmColors? other, double t) {
    if (other == null) return this;
    return CalmColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSunk: Color.lerp(bgSunk, other.bgSunk, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      inkInverse: Color.lerp(inkInverse, other.inkInverse, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandStrong: Color.lerp(brandStrong, other.brandStrong, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandSoftInk: Color.lerp(brandSoftInk, other.brandSoftInk, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerTint: Color.lerp(dangerTint, other.dangerTint, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      sheen: Color.lerp(sheen, other.sheen, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartAxisInk: Color.lerp(chartAxisInk, other.chartAxisInk, t)!,
      chartPlot: Color.lerp(chartPlot, other.chartPlot, t)!,
      overdue: overdue.lerp(other.overdue, t),
      due: due.lerp(other.due, t),
      dueSoon: dueSoon.lerp(other.dueSoon, t),
      ok: ok.lerp(other.ok, t),
      unknown: unknown.lerp(other.unknown, t),
      needsOdometer: needsOdometer.lerp(other.needsOdometer, t),
      business: business.lerp(other.business, t),
    );
  }
}
