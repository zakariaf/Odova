// TIER 2 — the semantic colour slots.
//
// Widgets read THESE, never CalmPalette: a widget that names a primitive has
// hardcoded one brightness. The two instances live in calm_theme.dart, so this
// file is pure structure and can be reviewed without reading a single hex.
//
// The seven CalmRamp fields are deliberately NOT flat colours. SPEC.md §9 makes
// due status a three-signal thing and §1 forbids the app from guessing in a way
// that looks like fact; a ramp keeps the graphic colour and the text colour
// apart so nobody can render 13px text in a 3.44:1 status base. Resolution goes
// through CalmStatusStyle — see calm-due-state-and-status. Nothing outside
// lib/theme/calm/ reads `.overdue`.
import 'package:flutter/material.dart';

/// One semantic family: the four rungs every Calm state colour ships with.
@immutable
class CalmRamp {
  /// Creates a family from its four rungs.
  const CalmRamp({
    required this.base,
    required this.ink,
    required this.tint,
    required this.edge,
  });

  /// The graphic — status dot, ring, progress fill, chart mark.
  ///
  /// Held to 3:1 against its background. Several bases are under 4.5:1 and
  /// MUST NOT carry text; that is what [ink] is for.
  final Color base;

  /// Text on [tint]. Every ink/tint pair in Calm clears 4.5:1 in both themes.
  final Color ink;

  /// The fill behind [ink].
  final Color tint;

  /// The 1px boundary of [tint]. Calm has no hard borders elsewhere, and this
  /// one is 1.23-1.34:1 on the tint — it cannot signify.
  final Color edge;

  /// Returns a copy with the given rungs replaced.
  CalmRamp copyWith({Color? base, Color? ink, Color? tint, Color? edge}) =>
      CalmRamp(
        base: base ?? this.base,
        ink: ink ?? this.ink,
        tint: tint ?? this.tint,
        edge: edge ?? this.edge,
      );

  /// Interpolates every rung towards [other].
  CalmRamp lerp(CalmRamp other, double t) => CalmRamp(
    base: Color.lerp(base, other.base, t)!,
    ink: Color.lerp(ink, other.ink, t)!,
    tint: Color.lerp(tint, other.tint, t)!,
    edge: Color.lerp(edge, other.edge, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is CalmRamp &&
      other.base == base &&
      other.ink == ink &&
      other.tint == tint &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(base, ink, tint, edge);
}

/// Calm's semantic colour slots: the roles, not the pixels.
///
/// Read through `CalmColors.of(context)`. The two instances are
/// `calmColorsLight` and `calmColorsDark` in `calm_theme.dart`.
@immutable
class CalmColors extends ThemeExtension<CalmColors> {
  /// Creates the slot set. Every field is required: a default here would be a
  /// colour no contrast test has ever seen.
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

  /// `--color-bg`. The page ground. Warm off-white in light, #1D1815 in dark.
  final Color bg;

  /// `--color-bg-sunk`. A recess below [bg] — a sunken well, never a shadow.
  final Color bgSunk;

  /// `--color-surface`. A card. The most common ground in the app.
  final Color surface;

  /// `--color-surface-2`. A surface one step warmer than [surface].
  final Color surface2;

  /// `--color-surface-3`. The warmest surface, and a pressed row's ground.
  final Color surface3;

  /// `--color-surface-inverse`. The inverted card. In light it IS [ink]; that
  /// is deliberate.
  final Color surfaceInverse;

  /// `--color-divider`. The hairline between rows in a group. It cannot
  /// signify.
  final Color divider;

  /// `--color-ink`. Primary text. Warm brown-black, never pure black.
  final Color ink;

  /// `--color-ink-2`. Secondary text, and the anchor line on a due card.
  final Color ink2;

  /// `--color-ink-3`. Tertiary text. Below AA on every LIGHT surface — see
  /// `design/calm/ACCESSIBILITY-FINDING.md` and
  /// `test/theme/calm/calm_contrast_test.dart`.
  final Color ink3;

  /// `--color-ink-4`. Disabled text and the row chevron. Below even the 3:1
  /// non-text floor in light; it may not carry text or an affordance.
  final Color ink4;

  /// `--color-ink-inverse`. Text on [surfaceInverse].
  final Color inkInverse;

  /// `--color-brand`. Clay. The one action colour in the product.
  final Color brand;

  /// `--color-brand-strong`. A pressed primary button.
  final Color brandStrong;

  /// `--color-brand-soft`. A tonal button's ground, and a selected row.
  final Color brandSoft;

  /// `--color-brand-soft-ink`. Text on [brandSoft].
  final Color brandSoftInk;

  /// `--color-on-brand`. Text on [brand].
  final Color onBrand;

  /// `--color-danger`. Destructive actions only — delete and restore. Never a
  /// due
  /// state: overdue is terracotta, not an alarm.
  final Color danger;

  /// `--color-danger-tint`. The ground behind [danger] text.
  final Color dangerTint;

  /// `--color-focus`. The keyboard focus ring.
  final Color focus;

  /// `--scrim`. The overlay behind a sheet or a dialog. Carries alpha.
  final Color scrim;

  /// `--elev-sheen`. The 1px top highlight on a card.
  ///
  /// `--elev-sheen` is an INSET shadow and Flutter has none, so the token
  /// is carried here as a colour and painted as a one-pixel edge by
  /// `CalmCard`. That saves the next reader an afternoon looking for an API
  /// that does not exist.
  final Color sheen;

  /// `--chart-1`. Series 1. Identical to [brand], so a legend swatch and a
  /// status
  /// dot can never disagree.
  final Color chart1;

  /// `--chart-2`. Series 2. Identical to `ok.base`.
  final Color chart2;

  /// `--chart-3`. Series 3. Identical to `due.base`.
  final Color chart3;

  /// `--chart-4`. Series 4. Identical to `dueSoon.base`.
  final Color chart4;

  /// `--chart-5`. Series 5. Identical to `business.base`.
  final Color chart5;

  /// `--chart-grid`. Grid lines. Drawn UNDER every fill — see the contrast
  /// audit's
  /// finding 5, where a due-coloured bar crossing a grid line is below the
  /// non-text floor.
  final Color chartGrid;

  /// `--chart-axis-ink`. Axis labels.
  final Color chartAxisInk;

  /// `--chart-plot`. The plot ground.
  final Color chartPlot;

  /// The `overdue` family: `base`, `ink`, `tint`, `edge`. Past the due point
  /// and past grace.
  final CalmRamp overdue;

  /// The `due` family: `base`, `ink`, `tint`, `edge`. At or past the due point,
  /// inside grace.
  final CalmRamp due;

  /// The `dueSoon` family: `base`, `ink`, `tint`, `edge`. Inside the notice
  /// window.
  final CalmRamp dueSoon;

  /// The `ok` family: `base`, `ink`, `tint`, `edge`. Nothing to do.
  final CalmRamp ok;

  /// The `unknown` family: `base`, `ink`, `tint`, `edge`. No anchor at all.
  /// Never borrows overdue's terracotta.
  final CalmRamp unknown;

  /// The `needsOdometer` family: `base`, `ink`, `tint`, `edge`. An anchor, but
  /// no usable odometer. Asks for a reading.
  final CalmRamp needsOdometer;

  /// The `business` family: `base`, `ink`, `tint`, `edge`. The
  /// business/personal split. Not a due state.
  final CalmRamp business;

  /// The slots for this [BuildContext]'s theme.
  ///
  /// Asserts rather than falling back. A `?? someDefault` would ship a palette
  /// no contrast test has ever seen, which is the one failure this extension
  /// exists to prevent — and it would do it silently, on whichever screen
  /// forgot the theme.
  static CalmColors of(BuildContext context) {
    final extension = Theme.of(context).extension<CalmColors>();
    assert(
      extension != null,
      'CalmColors is missing from this ThemeData. Build it with '
      'buildCalmTheme().',
    );
    return extension!;
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

  /// Interpolates every slot towards [other].
  ///
  /// Every field, every time. A slot added to the constructor and forgotten
  /// here transitions as a hard cut forever and nothing catches it — which is
  /// what check_extension_fields.sh greps for.
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
