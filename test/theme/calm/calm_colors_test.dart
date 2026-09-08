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
import '../../support/calm_ramps.dart';
import '../../support/calm_theme_harness.dart';
import '../../support/contrast.dart';
import 'calm_role_slots.dart';

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
          calmRoleToSlot,
          contains(role),
          reason: '$role has no slot in the table above',
        );
        expect(
          calmHex(calmRoleToSlot[role]!(colours)),
          hex,
          reason: '$label $role should be $hex',
        );
      }
    }
  });

  test('the two alpha slots trace to the CSS too', () {
    // `scrim` and `sheen` are the only CalmColors slots whose CSS value is an
    // `rgba()` rather than a hex, so they appear in neither the role sweep nor
    // the palette's hex trace — the two mechanisms that catch everything else.
    // Without this, `Color.fromRGBO(44, 34, 26, 0.4)` instead of `0.44` ships a
    // measurably wrong scrim behind every sheet and dialog, silently.
    for (final (label, colours, block) in [
      ('light', calmColorsLight, lightTokenBlock()),
      ('dark', calmColorsDark, darkTokenBlock()),
    ]) {
      for (final (name, token, slot) in <(String, String, Color)>[
        ('scrim', '--scrim', colours.scrim),
        ('sheen', '--elev-sheen', colours.sheen),
      ]) {
        final css = rgbaToken(block, token);
        expect(css, isNotNull, reason: '$label $token is not in the CSS');

        expect((slot.r * 255).round(), css!.r, reason: '$label $name red');
        expect((slot.g * 255).round(), css.g, reason: '$label $name green');
        expect((slot.b * 255).round(), css.b, reason: '$label $name blue');
        expect(slot.a, closeTo(css.a, 0.002), reason: '$label $name alpha');
      }
    }
  });

  test('the slot table covers every role the CSS declares', () {
    // Guard the guard: a role added to the CSS and not to the table would be
    // skipped by the loop above rather than failing it.
    expect(
      calmRoleToSlot.keys.toSet(),
      colourRolesIn(lightTokenBlock()).keys.toSet(),
    );
  });

  test('calmColorsDark reads a dark primitive for all 56 roles', () {
    // odova.css declares all 56 in both blocks and no role has the same value
    // in both, so this is unconditional: any equal pair is a slot that fell
    // through to light, and that is invisible until someone opens the app at
    // night.
    for (final MapEntry(key: role, value: slot) in calmRoleToSlot.entries) {
      expect(
        slot(calmColorsDark),
        isNot(slot(calmColorsLight)),
        reason: '$role is the same colour in both themes',
      );
    }
  });

  testOfAsserts('CalmColors', CalmColors.of);

  test('lerp interpolates every field', () {
    // The bug everyone ships once: a field added to the constructor and
    // forgotten in lerp does not transition, and nothing says so.
    final half = calmColorsLight.lerp(calmColorsDark, 0.5);

    for (final MapEntry(key: role, value: slot) in calmRoleToSlot.entries) {
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
    for (final MapEntry(key: role, value: slot) in calmRoleToSlot.entries) {
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
      for (final MapEntry(key: name, value: ramp) in rampsOf(colours).entries) {
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
