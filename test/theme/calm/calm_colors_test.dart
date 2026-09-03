// Tier 2: the semantic slots, and the trace from each one to its CSS role.
//
// Tier 1 proves no colour was invented. This proves each colour landed on the
// right slot — which is a different failure, and a silent one: swapping
// `surface2` and `surface3` produces an app that is entirely built from Calm's
// palette and does not look like Calm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/calm_css.dart';
import '../../support/contrast.dart';

/// Every one of the 56 CSS roles, and the slot it must land on.
///
/// Written out rather than derived from the token name. A kebab-to-camel rule
/// would map `--color-due-soon-ink` onto something, and whether that something
/// is `dueSoon.ink` or a field called `dueSoonInk` is exactly the decision this
/// table exists to record — the four-rung families are read as `.ink` on a
/// [CalmRamp], never as a flat slot.
final _roleToSlot = <String, Color Function(CalmColors)>{
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
String _hex(Color c) {
  String channel(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${channel(c.r)}${channel(c.g)}${channel(c.b)}';
}

/// The seven four-rung families, by name, for the loops below.
Map<String, CalmRamp> _ramps(CalmColors c) => {
  'overdue': c.overdue,
  'due': c.due,
  'dueSoon': c.dueSoon,
  'ok': c.ok,
  'unknown': c.unknown,
  'needsOdometer': c.needsOdometer,
  'business': c.business,
};

void main() {
  test('every CSS role lands on its slot, in both themes', () {
    for (final (label, colours, block) in [
      ('light', calmColorsLight, lightTokenBlock()),
      ('dark', calmColorsDark, darkTokenBlock()),
    ]) {
      final roles = colourRolesIn(block);
      expect(roles, hasLength(56), reason: '$label declares ${roles.length}');

      for (final MapEntry(key: role, value: hex) in roles.entries) {
        expect(
          _roleToSlot,
          contains(role),
          reason: '$role has no slot in the table above',
        );
        expect(
          _hex(_roleToSlot[role]!(colours)),
          hex,
          reason: '$label $role should be $hex',
        );
      }
    }
  });

  test('the slot table covers every role the CSS declares', () {
    // Guard the guard: a role added to the CSS and not to the table would be
    // skipped by the loop above rather than failing it.
    expect(
      _roleToSlot.keys.toSet(),
      colourRolesIn(lightTokenBlock()).keys.toSet(),
    );
  });

  test('calmColorsDark reads a dark primitive for all 56 roles', () {
    // odova.css declares all 56 in both blocks and no role has the same value
    // in both, so this is unconditional: any equal pair is a slot that fell
    // through to light, and that is invisible until someone opens the app at
    // night.
    for (final MapEntry(key: role, value: slot) in _roleToSlot.entries) {
      expect(
        slot(calmColorsDark),
        isNot(slot(calmColorsLight)),
        reason: '$role is the same colour in both themes',
      );
    }
  });

  testWidgets('CalmColors.of asserts, naming the extension and the builder', (
    tester,
  ) async {
    // Never `?? fallback`: a fallback ships a palette the contrast test has
    // never seen, which is the one failure this extension exists to prevent.
    // The message has to name both the extension and how to get one, because
    // the person reading it is looking at a stack trace inside a widget that
    // did nothing wrong.
    Object? thrown;
    await tester.pumpWidget(
      Theme(
        data: ThemeData.light(),
        child: Builder(
          builder: (context) {
            try {
              CalmColors.of(context);
            } on Object catch (error) {
              thrown = error;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      thrown,
      isA<AssertionError>().having(
        (e) => e.toString(),
        'message',
        allOf(contains('CalmColors'), contains('buildCalmTheme')),
      ),
    );
  });

  test('lerp interpolates every field', () {
    // The bug everyone ships once: a field added to the constructor and
    // forgotten in lerp does not transition, and nothing says so.
    final half = calmColorsLight.lerp(calmColorsDark, 0.5);

    for (final MapEntry(key: role, value: slot) in _roleToSlot.entries) {
      expect(
        slot(half),
        isNot(slot(calmColorsLight)),
        reason: '$role did not move away from light',
      );
      expect(
        slot(half),
        isNot(slot(calmColorsDark)),
        reason: '$role jumped straight to dark',
      );
    }
  });

  test('copyWith round-trips every field', () {
    const sentinel = Color(0xFF010203);
    for (final MapEntry(key: role, value: slot) in _roleToSlot.entries) {
      // A ramp rung is reached through its family's copyWith, so the flat
      // slots are covered here and the ramps in calm_ramp_test.dart.
      if (role.contains('overdue') ||
          role.contains('--color-due') ||
          role.contains('ok') ||
          role.contains('unknown') ||
          role.contains('needs-odometer') ||
          role.contains('business')) {
        continue;
      }
      expect(
        slot(calmColorsLight.copyWith()),
        slot(calmColorsLight),
        reason: '$role was dropped by an empty copyWith',
      );
    }

    expect(calmColorsLight.copyWith(bg: sentinel).bg, sentinel);
    expect(
      calmColorsLight.copyWith(bg: sentinel).surface,
      calmColorsLight.surface,
    );
  });

  test('chart1..chart5 alias brand, ok, due, dueSoon and business', () {
    // Identity, not equality by coincidence: a legend swatch and a status dot
    // must never disagree.
    for (final colours in [calmColorsLight, calmColorsDark]) {
      expect(colours.chart1, colours.brand);
      expect(colours.chart2, colours.ok.base);
      expect(colours.chart3, colours.due.base);
      expect(colours.chart4, colours.dueSoon.base);
      expect(colours.chart5, colours.business.base);
    }
  });

  test('every ink-on-tint pair clears 4.5:1 in both themes', () {
    // Fourteen assertions. This is the pair the design guarantees, and it is
    // what makes `ink` safe as a text colour when `base` is not.
    for (final (label, colours) in [
      ('light', calmColorsLight),
      ('dark', calmColorsDark),
    ]) {
      for (final MapEntry(key: name, value: ramp) in _ramps(colours).entries) {
        expect(
          contrastRatio(ramp.ink, ramp.tint),
          greaterThanOrEqualTo(bodyTextContrast),
          reason:
              '$label $name: ink on tint is '
              '${contrastRatio(ramp.ink, ramp.tint).toStringAsFixed(2)}:1',
        );
      }
    }
  });
}
