// The CSS and the Dart, held against each other.
//
// `design/calm/odova.css` is the design system's source and
// `lib/theme/calm/calm_palette.dart` is the app's copy of it. Two files with
// the same numbers in them stay the same only while somebody is looking.
//
// **This test exists because of what EPIC-17 task 17.2 missed.** The contrast
// fix moved `--color-ink-3` in the CSS, mirrored it into the palette and
// re-shot 116 reference PNGs — and `CalmField` went on drawing its placeholder
// in `ink4` at 4.23:1 for a day, because nothing compared the two files. A
// mirror kept by hand is a mirror that is right until the day it matters.
//
// It compares the DECLARED VALUES, not the usages: a widget reaching for the
// wrong slot is `check_raw_values.sh`'s job and `rendered_text_contrast_test`'s.
// What this pins is that `--color-ink-3` and `CalmColors.ink3` are the same
// hex, in light and in dark, for every slot the CSS declares.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';

/// Every `--custom-property: #HEX;` inside one CSS block.
///
/// The blocks are `:root, .theme-light { … }` and
/// `:root[data-theme="dark"], .theme-dark { … }`, in that order — so the file
/// is split on the dark selector rather than parsed, which is enough for a
/// declaration list and does not put a CSS parser in the test suite.
Map<String, String> _declarations(String block) {
  final out = <String, String>{};
  for (final m in RegExp(
    r'(--[a-z0-9-]+)\s*:\s*(#[0-9A-Fa-f]{6})\s*;',
  ).allMatches(block)) {
    out[m.group(1)!] = m.group(2)!.toUpperCase();
  }
  return out;
}

/// `#RRGGBB` for an opaque colour.
String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';

/// Which CSS property each `CalmColors` slot mirrors.
///
/// Written out rather than derived from the names: `--color-ink-3` is `ink3`
/// and `--chart-axis-ink` is `chartAxisInk`, and a transformation that handles
/// both would be a second thing to get wrong. A slot missing from this table is
/// a slot nothing checks, which the count assertion below is for.
const Map<String, Color Function(CalmColors)> _mirrored = {
  '--color-bg': _bg,
  '--color-bg-sunk': _bgSunk,
  '--color-surface': _surface,
  '--color-surface-2': _surface2,
  '--color-surface-3': _surface3,
  '--color-divider': _divider,
  '--color-ink': _ink,
  '--color-ink-2': _ink2,
  '--color-ink-3': _ink3,
  '--color-ink-4': _ink4,
  '--color-brand': _brand,
  '--color-brand-strong': _brandStrong,
  '--color-danger': _danger,
  '--color-focus': _focus,
  '--chart-axis-ink': _chartAxisInk,
};

Color _bg(CalmColors c) => c.bg;
Color _bgSunk(CalmColors c) => c.bgSunk;
Color _surface(CalmColors c) => c.surface;
Color _surface2(CalmColors c) => c.surface2;
Color _surface3(CalmColors c) => c.surface3;
Color _divider(CalmColors c) => c.divider;
Color _ink(CalmColors c) => c.ink;
Color _ink2(CalmColors c) => c.ink2;
Color _ink3(CalmColors c) => c.ink3;
Color _ink4(CalmColors c) => c.ink4;
Color _brand(CalmColors c) => c.brand;
Color _brandStrong(CalmColors c) => c.brandStrong;
Color _danger(CalmColors c) => c.danger;
Color _focus(CalmColors c) => c.focus;
Color _chartAxisInk(CalmColors c) => c.chartAxisInk;

void main() {
  final css = File('design/calm/odova.css').readAsStringSync();
  final darkAt = css.indexOf(':root[data-theme="dark"]');
  final light = _declarations(css.substring(0, darkAt));
  final dark = _declarations(css.substring(darkAt));

  test('the two theme blocks were both found', () {
    // The split is positional, so it is worth proving it split. A refactor that
    // renamed the dark selector would put every declaration in `light` and
    // every dark comparison would then compare light against light — and pass.
    expect(darkAt, greaterThan(0), reason: 'no dark block in odova.css');
    expect(light, isNotEmpty);
    expect(dark, isNotEmpty);
    expect(light['--color-bg'], isNot(dark['--color-bg']));
  });

  for (final (name, brightness) in const [
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    test('every mirrored token matches the CSS in $name', () {
      final declared = brightness == Brightness.light ? light : dark;
      final colors = buildCalmTheme(brightness).extension<CalmColors>()!;

      final wrong = <String>[];
      for (final entry in _mirrored.entries) {
        final inCss = declared[entry.key];
        if (inCss == null) {
          wrong.add('${entry.key} is not declared in the $name block');
          continue;
        }
        final inDart = _hex(entry.value(colors));
        if (inCss != inDart)
          wrong.add('${entry.key}: CSS $inCss, Dart $inDart');
      }

      expect(
        wrong,
        isEmpty,
        reason:
            'the stylesheet and the palette disagree in $name:\n'
            '${wrong.map((w) => '  - $w').join('\n')}\n\n'
            'One of them was edited and the other was not. The reference PNGs '
            'are shot from the CSS and the app is drawn from the Dart, so a '
            'difference here is a screen that cannot match its own reference.',
      );
    });
  }

  test('the mirror covers the colour tokens a screen is made of', () {
    // A floor, not a total. Calm declares far more than fifteen properties —
    // gradients, shadows, per-status ramps — and this table deliberately holds
    // the ones every screen is built from. The assertion stops the table being
    // quietly emptied to make a failure go away.
    expect(_mirrored, hasLength(greaterThanOrEqualTo(15)));
  });
}
