// The two CalmColors instances: `:root` and `[data-theme="dark"]` from
// design/calm/odova.css, slot by slot.
//
// Light and dark are authored independently. Dark is NOT an inversion: the dark
// brand rises from clay48 to clay75 and every status base rises with it,
// because a light-theme chroma on a #1D1815 ground loses about two stops of
// contrast. test/theme/calm/calm_colors_test.dart asserts every one of the 56
// roles lands on its slot in both themes, and that no slot is the same colour
// in both — a slot that fell through to light is invisible until somebody opens
// the app at night.
//
// The ColorScheme mapping and buildCalmTheme() arrive in task 2.6.
import 'package:flutter/material.dart';

import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_palette.dart';

/// Calm's light theme: the `:root` block of `design/calm/odova.css`.
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
  sheen: Color.fromRGBO(
    255,
    255,
    255,
    0.7,
  ), // --elev-sheen; a 1px top highlight, not a shadow
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
/// overridden there, so a slot that still reads a light primitive here is a
/// bug.
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
  sheen: Color.fromRGBO(
    255,
    236,
    214,
    0.05,
  ), // --elev-sheen; a 1px top highlight, not a shadow
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
