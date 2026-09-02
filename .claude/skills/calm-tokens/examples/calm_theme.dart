// lib/theme/calm/calm_theme.dart
//
// The two CalmColors instances and the single theme builder. In the app the
// instances sit at the foot of calm_colors.dart; they are here so one file shows
// the whole fold: primitive -> slot -> ColorScheme -> ThemeData.
//
// Light and dark are authored independently. Dark is NOT an inversion: the dark
// brand rises from clay48 to clay75 and every status base rises with it, because
// a light-theme chroma on a #1D1815 ground loses ~2 stops of contrast.
import 'package:flutter/material.dart';

import 'calm_colors.dart';
import 'calm_palette.dart';
import 'calm_scales.dart';
import 'calm_shapes_and_motion.dart';

/// The `:root` block of design/calm/odova.css, slot by slot.
const calmColorsLight = CalmColors(
  bg: CalmPalette.sand96,
  bgSunk: CalmPalette.sand93,
  surface: CalmPalette.sand99,
  surface2: CalmPalette.sand94,
  surface3: CalmPalette.sand90,
  surfaceInverse: CalmPalette.bark27,
  divider: CalmPalette.bark89,
  ink: CalmPalette.bark27,
  ink2: CalmPalette.bark43,
  ink3: CalmPalette.bark59,
  ink4: CalmPalette.bark70,
  inkInverse: CalmPalette.bark99,
  brand: CalmPalette.clay48,
  brandStrong: CalmPalette.clay40,
  brandSoft: CalmPalette.clay91,
  brandSoftInk: CalmPalette.clay43,
  onBrand: CalmPalette.clay98,
  danger: CalmPalette.ember51,
  dangerTint: CalmPalette.ember92,
  focus: CalmPalette.amber61,
  scrim: Color.fromRGBO(44, 34, 26, 0.44), // --scrim
  sheen: Color.fromRGBO(255, 255, 255, 0.7), // --elev-sheen; a 1px top highlight, not a shadow
  chart1: CalmPalette.clay48,
  chart2: CalmPalette.sage55,
  chart3: CalmPalette.ochre63,
  chart4: CalmPalette.slate57,
  chart5: CalmPalette.plum52,
  chartGrid: CalmPalette.bark88,
  chartAxisInk: CalmPalette.bark59,
  chartPlot: CalmPalette.sand99,
  overdue: CalmRamp(
    base: CalmPalette.terracotta57,
    ink: CalmPalette.terracotta46,
    tint: CalmPalette.terracotta93,
    edge: CalmPalette.terracotta85,
  ),
  due: CalmRamp(
    base: CalmPalette.ochre63,
    ink: CalmPalette.ochre49,
    tint: CalmPalette.ochre95,
    edge: CalmPalette.ochre88,
  ),
  dueSoon: CalmRamp(
    base: CalmPalette.slate57,
    ink: CalmPalette.slate46,
    tint: CalmPalette.slate94,
    edge: CalmPalette.slate87,
  ),
  ok: CalmRamp(
    base: CalmPalette.sage55,
    ink: CalmPalette.sage45,
    tint: CalmPalette.sage94,
    edge: CalmPalette.sage87,
  ),
  unknown: CalmRamp(
    base: CalmPalette.stone59,
    ink: CalmPalette.stone49,
    tint: CalmPalette.stone93,
    edge: CalmPalette.stone86,
  ),
  needsOdometer: CalmRamp(
    base: CalmPalette.pebble53,
    ink: CalmPalette.pebble43,
    tint: CalmPalette.pebble92,
    edge: CalmPalette.pebble85,
  ),
  business: CalmRamp(
    base: CalmPalette.plum52,
    ink: CalmPalette.plum42,
    tint: CalmPalette.plum94,
    edge: CalmPalette.plum86,
  ),
);

/// The `[data-theme="dark"]` block. Every one of the 56 colour roles is
/// overridden there, so a slot that still reads a light primitive here is a bug.
const calmColorsDark = CalmColors(
  bg: CalmPalette.sand21,
  bgSunk: CalmPalette.sand18,
  surface: CalmPalette.sand25,
  surface2: CalmPalette.sand28,
  surface3: CalmPalette.sand32,
  surfaceInverse: CalmPalette.bark94b,
  divider: CalmPalette.bark32,
  ink: CalmPalette.bark94,
  ink2: CalmPalette.bark78,
  ink3: CalmPalette.bark65,
  ink4: CalmPalette.bark54,
  inkInverse: CalmPalette.bark24,
  brand: CalmPalette.clay75,
  brandStrong: CalmPalette.clay83,
  brandSoft: CalmPalette.clay31,
  brandSoftInk: CalmPalette.clay81,
  onBrand: CalmPalette.clay25,
  danger: CalmPalette.ember73,
  dangerTint: CalmPalette.ember30,
  focus: CalmPalette.amber76,
  scrim: Color.fromRGBO(12, 9, 7, 0.62), // --scrim
  sheen: Color.fromRGBO(255, 236, 214, 0.05), // --elev-sheen; a 1px top highlight, not a shadow
  chart1: CalmPalette.clay75,
  chart2: CalmPalette.sage77,
  chart3: CalmPalette.ochre79,
  chart4: CalmPalette.slate75,
  chart5: CalmPalette.plum75,
  chartGrid: CalmPalette.bark32,
  chartAxisInk: CalmPalette.bark65,
  chartPlot: CalmPalette.sand25,
  overdue: CalmRamp(
    base: CalmPalette.terracotta73,
    ink: CalmPalette.terracotta82,
    tint: CalmPalette.terracotta30,
    edge: CalmPalette.terracotta37,
  ),
  due: CalmRamp(
    base: CalmPalette.ochre79,
    ink: CalmPalette.ochre85,
    tint: CalmPalette.ochre31,
    edge: CalmPalette.ochre38,
  ),
  dueSoon: CalmRamp(
    base: CalmPalette.slate75,
    ink: CalmPalette.slate84,
    tint: CalmPalette.slate31,
    edge: CalmPalette.slate38,
  ),
  ok: CalmRamp(
    base: CalmPalette.sage77,
    ink: CalmPalette.sage85,
    tint: CalmPalette.sage30,
    edge: CalmPalette.sage37,
  ),
  unknown: CalmRamp(
    base: CalmPalette.stone74,
    ink: CalmPalette.stone82,
    tint: CalmPalette.stone29,
    edge: CalmPalette.stone36,
  ),
  needsOdometer: CalmRamp(
    base: CalmPalette.pebble70,
    ink: CalmPalette.pebble79,
    tint: CalmPalette.pebble28,
    edge: CalmPalette.pebble35,
  ),
  business: CalmRamp(
    base: CalmPalette.plum75,
    ink: CalmPalette.plum83,
    tint: CalmPalette.plum29,
    edge: CalmPalette.plum35,
  ),
);

// Hand-authored, both brightnesses, every role Calm consumes stated by name.
// ColorScheme.fromSeed cannot produce this: seeding on `brand` (OKLCH H 47) drags
// the paper ramp off its ochre H 78-81 and flattens a chroma rise the design
// makes on purpose (.007 -> .029 across surface..surface3). Full argument and the
// per-role contrast numbers: references/colorscheme-mapping.md.
ColorScheme _scheme(Brightness brightness, CalmColors c) => ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.brandSoftInk,
      // One brand hue. `secondary` repeats it rather than inventing a second.
      secondary: c.brand,
      onSecondary: c.onBrand,
      secondaryContainer: c.surface2,
      onSecondaryContainer: c.ink2,
      // Parked on the neutral pair on purpose: Calm's other eight hues all MEAN
      // something (ochre = due, plum = business trip). A stock widget reaching
      // `tertiary` must render as plain text, never as a false status colour.
      tertiary: c.ink,
      onTertiary: c.surface,
      tertiaryContainer: c.surface2,
      onTertiaryContainer: c.ink2,
      surface: c.surface,
      onSurface: c.ink,
      surfaceDim: c.bgSunk,
      surfaceBright: c.surface,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.bg,
      surfaceContainer: c.surface2,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface3,
      onSurfaceVariant: c.ink2,
      outline: c.divider,
      outlineVariant: c.divider,
      error: c.danger,
      onError: c.inkInverse,
      errorContainer: c.dangerTint,
      // Calm ships no --color-danger-ink; `danger` on `dangerTint` is 4.86:1
      // light / 5.51:1 dark, so it passes AA — but it is a hole in the palette.
      onErrorContainer: c.danger,
      inverseSurface: c.surfaceInverse,
      onInverseSurface: c.inkInverse,
      inversePrimary: c.brandSoft,
      scrim: c.scrim,
      shadow: CalmPalette.shadowTint,
      // A no-op: M3's tonal elevation overlay would put clay into #FFFCF7.
      surfaceTint: c.surface,
    );

// Material's own text roles, so a stock widget picks up Calm type unaided.
// Colour is deliberately absent — it comes from CalmColors at the call site.
TextTheme _textTheme(CalmType t) => TextTheme(
      displayLarge: t.display,
      displayMedium: t.hero,
      displaySmall: t.titleLg,
      headlineLarge: t.titleLg,
      headlineMedium: t.title,
      headlineSmall: t.headline,
      titleLarge: t.title,
      titleMedium: t.headline,
      titleSmall: t.label,
      bodyLarge: t.bodyLg,
      bodyMedium: t.body,
      bodySmall: t.caption,
      labelLarge: t.label,
      labelMedium: t.label,
      labelSmall: t.caption,
    );

/// The one theme builder. Every extension is attached to BOTH brightnesses;
/// an extension missing from one makes `of()` assert on that theme only, which
/// is the bug that ships because nobody ran the app in dark.
ThemeData buildCalmTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? calmColorsDark : calmColorsLight;
  final shapes = isDark ? calmShapesDark : calmShapesLight;

  return ThemeData(
    brightness: brightness,
    colorScheme: _scheme(brightness, c),
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    focusColor: c.focus,
    textTheme: _textTheme(calmType),
    // Calm paints its own layered shadow. Left on, Material draws a second one.
    cardTheme: CardThemeData(
      elevation: 0,
      color: c.surface,
      margin: EdgeInsets.zero,
      shape: shapes.card(),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    // The design has no divider-width token: odova.css draws every separator as
    // `box-shadow: 0 1px 0 var(--color-divider)`, so 1 is read off the rule.
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    extensions: <ThemeExtension<dynamic>>[
      c,
      calmType,
      calmSpace,
      shapes,
      calmMotion,
    ],
  );
}

/// Injected once, at the composition root. `themeMode` arrives already restored
/// from settings — see app-startup-and-bootstrap for the main() ordering that
/// keeps the first frame from flashing the wrong theme.
class CalmApp extends StatelessWidget {
  const CalmApp({super.key, required this.themeMode, required this.home});

  final ThemeMode themeMode;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildCalmTheme(Brightness.light),
      darkTheme: buildCalmTheme(Brightness.dark),
      themeMode: themeMode,
      // Calm's own motion tokens drive every transition; Material's implicit
      // kThemeAnimationDuration cross-fade is not one of them.
      themeAnimationStyle: AnimationStyle.noAnimation,
      home: home,
    );
  }
}
