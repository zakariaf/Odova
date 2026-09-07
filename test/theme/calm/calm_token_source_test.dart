// The stylesheet and the THEME, held against each other.
//
// `calm_colors_test.dart` already walks all 56 `--color-*` and `--chart-*`
// roles against `calmColorsLight` and `calmColorsDark` — the const objects.
// This walks the same 56 against what `buildCalmTheme()` actually hands a
// widget, which is a different claim: `calm_theme_test.dart` pins that link on
// two slots, `bg` and `elev1`, and everything else was taken on trust.
//
// It exists because of what EPIC-17 task 17.2 missed. The contrast fix moved
// `--color-ink-3` in the CSS, mirrored it into the palette and re-shot 116
// reference PNGs — and `CalmField` went on drawing its placeholder in `ink4`
// for a day. Nothing in that failure was a token being wrong, which is why this
// file is a thin extension of a check that already existed rather than a second
// copy of it: the parser, the role table and the hex formatter all come from
// `test/support/calm_css.dart` and `calm_colors_test.dart`.
//
// What it does NOT check is which slot a widget reaches for. That is
// `check_raw_values.sh`'s job, and the colour a widget actually draws is
// `test/a11y/rendered_text_contrast_test.dart`'s.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';

import '../../support/calm_css.dart';
import 'calm_role_slots.dart';

void main() {
  for (final (name, brightness, block) in [
    ('light', Brightness.light, lightTokenBlock()),
    ('dark', Brightness.dark, darkTokenBlock()),
  ]) {
    test('the $name THEME carries the stylesheet, not just the palette', () {
      final colors = buildCalmTheme(brightness).extension<CalmColors>()!;
      final roles = colourRolesIn(block);
      expect(roles, hasLength(56), reason: '$name declares ${roles.length}');

      final wrong = <String>[];
      for (final MapEntry(key: role, value: declared) in roles.entries) {
        final slot = calmRoleToSlot[role];
        if (slot == null) {
          wrong.add('$role has no slot in calmRoleToSlot');
          continue;
        }
        final drawn = calmHex(slot(colors));
        if (drawn != declared) wrong.add('$role: CSS $declared, theme $drawn');
      }

      expect(
        wrong,
        isEmpty,
        reason:
            'the stylesheet and the built theme disagree in $name:\n'
            '${wrong.map((w) => '  - $w').join('\n')}\n\n'
            'The reference PNGs are shot from the CSS and the app is drawn '
            'from the theme, so a difference here is a screen that cannot '
            'match its own reference however the widget is written.',
      );
    });
  }
}
