// The four-rung shape every Calm state family ships with.
//
// SPEC.md §9 makes due status a three-signal thing and §1 forbids the app from
// guessing in a way that looks like fact. A ramp is what keeps the graphic
// colour and the text colour apart, so nobody can render 13px text in a 3.44:1
// status base.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/contrast.dart';

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
  test('all seven families are CalmRamps with four distinct rungs', () {
    for (final (label, colours) in [
      ('light', calmColorsLight),
      ('dark', calmColorsDark),
    ]) {
      final ramps = _ramps(colours);
      expect(ramps, hasLength(7));

      for (final MapEntry(key: name, value: ramp) in ramps.entries) {
        // base and ink are different jobs, not two names for one colour: base
        // is the graphic and is held to 3:1, ink is text on tint and is held
        // to 4.5:1. A family where they coincide has one of the two wrong.
        expect(
          {ramp.base, ramp.ink, ramp.tint, ramp.edge},
          hasLength(4),
          reason: '$label $name has a repeated rung',
        );
      }
    }
  });

  test('the base rung clears 3:1 on the surface it is drawn on', () {
    // base is a non-text graphic — a status dot, a progress fill, a chart mark
    // — so 1.4.11's 3:1 applies, not 4.5:1. Several bases are under 4.5 on
    // purpose, which is exactly why they must never carry text.
    for (final (label, colours) in [
      ('light', calmColorsLight),
      ('dark', calmColorsDark),
    ]) {
      for (final MapEntry(key: name, value: ramp) in _ramps(colours).entries) {
        final ratio = contrastRatio(ramp.base, colours.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(largeTextAndGraphicContrast),
          reason:
              '$label $name base on surface is '
              '${ratio.toStringAsFixed(2)}:1',
        );
      }
    }
  });

  test('copyWith and lerp carry all four rungs', () {
    final light = calmColorsLight.overdue;
    final dark = calmColorsDark.overdue;

    expect(light.copyWith().base, light.base);
    expect(light.copyWith().ink, light.ink);
    expect(light.copyWith().tint, light.tint);
    expect(light.copyWith().edge, light.edge);

    final half = light.lerp(dark, 0.5);
    for (final (name, a, b, mid) in [
      ('base', light.base, dark.base, half.base),
      ('ink', light.ink, dark.ink, half.ink),
      ('tint', light.tint, dark.tint, half.tint),
      ('edge', light.edge, dark.edge, half.edge),
    ]) {
      expect(mid, isNot(a), reason: '$name did not move away from light');
      expect(mid, isNot(b), reason: '$name jumped straight to dark');
    }
  });
}
