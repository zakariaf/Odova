// The CSS role table and the hex formatter, in one place.
//
// `calm_colors_test.dart` declares them and `calm_token_source_test.dart` needs
// exactly the same two: one walks the 56 roles against the const `CalmColors`
// objects, the other against what `buildCalmTheme()` hands a widget. Two copies
// of a 56-entry table are two tables that can disagree about which slot a role
// maps to — and the disagreement would be invisible, because each file would
// still pass against its own copy.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// Every one of the 56 CSS roles, and the slot it must land on.
///
/// Written out rather than derived from the token name. A kebab-to-camel rule
/// would map `--color-due-soon-ink` onto something, and whether that something
/// is `dueSoon.ink` or a field called `dueSoonInk` is exactly the decision this
/// table exists to record — the four-rung families are read as `.ink` on a
/// [CalmRamp], never as a flat slot.
final calmRoleToSlot = <String, Color Function(CalmColors)>{
  '--color-bg': (c) => c.bg,
  '--color-bg-sunk': (c) => c.bgSunk,
  '--color-surface': (c) => c.surface,
  '--color-surface-2': (c) => c.surface2,
  '--color-surface-3': (c) => c.surface3,
  '--color-surface-inverse': (c) => c.surfaceInverse,
  '--color-divider': (c) => c.divider,
  '--color-ink': (c) => c.ink,
  '--color-ink-2': (c) => c.ink2,
  '--color-ink-3': (c) => c.ink3,
  '--color-ink-4': (c) => c.ink4,
  '--color-ink-inverse': (c) => c.inkInverse,
  '--color-brand': (c) => c.brand,
  '--color-brand-strong': (c) => c.brandStrong,
  '--color-brand-soft': (c) => c.brandSoft,
  '--color-brand-soft-ink': (c) => c.brandSoftInk,
  '--color-on-brand': (c) => c.onBrand,
  '--color-danger': (c) => c.danger,
  '--color-danger-tint': (c) => c.dangerTint,
  '--color-focus': (c) => c.focus,
  '--color-overdue': (c) => c.overdue.base,
  '--color-overdue-ink': (c) => c.overdue.ink,
  '--color-overdue-tint': (c) => c.overdue.tint,
  '--color-overdue-edge': (c) => c.overdue.edge,
  '--color-due': (c) => c.due.base,
  '--color-due-ink': (c) => c.due.ink,
  '--color-due-tint': (c) => c.due.tint,
  '--color-due-edge': (c) => c.due.edge,
  '--color-due-soon': (c) => c.dueSoon.base,
  '--color-due-soon-ink': (c) => c.dueSoon.ink,
  '--color-due-soon-tint': (c) => c.dueSoon.tint,
  '--color-due-soon-edge': (c) => c.dueSoon.edge,
  '--color-ok': (c) => c.ok.base,
  '--color-ok-ink': (c) => c.ok.ink,
  '--color-ok-tint': (c) => c.ok.tint,
  '--color-ok-edge': (c) => c.ok.edge,
  '--color-unknown': (c) => c.unknown.base,
  '--color-unknown-ink': (c) => c.unknown.ink,
  '--color-unknown-tint': (c) => c.unknown.tint,
  '--color-unknown-edge': (c) => c.unknown.edge,
  '--color-needs-odometer': (c) => c.needsOdometer.base,
  '--color-needs-odometer-ink': (c) => c.needsOdometer.ink,
  '--color-needs-odometer-tint': (c) => c.needsOdometer.tint,
  '--color-needs-odometer-edge': (c) => c.needsOdometer.edge,
  '--color-business': (c) => c.business.base,
  '--color-business-ink': (c) => c.business.ink,
  '--color-business-tint': (c) => c.business.tint,
  '--color-business-edge': (c) => c.business.edge,
  '--chart-1': (c) => c.chart1,
  '--chart-2': (c) => c.chart2,
  '--chart-3': (c) => c.chart3,
  '--chart-4': (c) => c.chart4,
  '--chart-5': (c) => c.chart5,
  '--chart-grid': (c) => c.chartGrid,
  '--chart-axis-ink': (c) => c.chartAxisInk,
  '--chart-plot': (c) => c.chartPlot,
};

/// `#RRGGBB`, upper-cased, to compare against the CSS.
String calmHex(Color c) {
  String channel(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${channel(c.r)}${channel(c.g)}${channel(c.b)}';
}
