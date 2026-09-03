// TIER 1 — the only file in the app allowed a colour literal. Every value
// is copied from
// design/calm/odova.css; nothing here was chosen by an engineer.
//
// Names are `<family><L>` where L is measured OKLCH lightness x 100 — a fact
// about the pixel, so the name cannot lie in either theme. Families are Calm's
// own hue families. The trailing comment records which CSS role(s) each value
// serves, `l:` light and `d:` dark, so a palette diff is reviewable against the
// design without opening the CSS.
//
// A primitive is NEVER read outside lib/theme/calm/ — check_raw_values.sh fails
// the build on `CalmPalette.` in feature code, and
// test/theme/calm_palette_test.dart says the same thing where a person reads it.
// Widgets read CalmColors.
//
// Ported from .claude/skills/calm-tokens/examples/calm_palette.dart and then
// re-verified value by value against odova.css: the example is a worked
// reference, not the source of truth, and the two-direction trace in
// calm_palette_test.dart is what makes that distinction real.
import 'package:flutter/painting.dart' show Color;

/// Calm's measured colours: 96 across 56 roles and two themes, plus the two
/// `--elev-*` shadow tints.
abstract final class CalmPalette {
  // sand — the paper ramp: warm off-white in light, warm charcoal-brown in
  // dark.
  /// Dark `--color-bg-sunk`.
  static const sand18 = Color(0xFF151110);

  /// Dark `--color-bg`.
  static const sand21 = Color(0xFF1D1815);

  /// Dark `--color-surface`, `--chart-plot`.
  static const sand25 = Color(0xFF272019);

  /// Dark `--color-surface-2`.
  static const sand28 = Color(0xFF31281F);

  /// Dark `--color-surface-3`.
  static const sand32 = Color(0xFF3C3127);

  /// Light `--color-surface-3`.
  static const sand90 = Color(0xFFE9DCC9);

  /// Light `--color-bg-sunk`.
  static const sand93 = Color(0xFFEFE6D9);

  /// Light `--color-surface-2`.
  static const sand94 = Color(0xFFF3EADC);

  /// Light `--color-bg`.
  static const sand96 = Color(0xFFF8F2E9);

  /// Light `--color-surface`, `--chart-plot`.
  static const sand99 = Color(0xFFFFFCF7);

  // bark — the ink ramp, plus the divider and the inverse surface
  /// Dark `--color-ink-inverse`.
  static const bark24 = Color(0xFF241D17);

  /// Light `--color-surface-inverse`, `--color-ink`.
  static const bark27 = Color(0xFF2C241E);

  /// Dark `--color-divider`, `--chart-grid`.
  static const bark32 = Color(0xFF3A3028);

  /// Light `--color-ink-2`.
  static const bark43 = Color(0xFF5C4E43);

  /// Dark `--color-ink-4`.
  static const bark54 = Color(0xFF7B6C5C);

  /// Light `--color-ink-3`, `--chart-axis-ink`.
  static const bark59 = Color(0xFF8B7B6C);

  /// Dark `--color-ink-3`, `--chart-axis-ink`.
  static const bark65 = Color(0xFF9C8B79);

  /// Light `--color-ink-4`.
  static const bark70 = Color(0xFFAC9C8B);

  /// Dark `--color-ink-2`.
  static const bark78 = Color(0xFFC6B6A4);

  /// Light `--chart-grid`.
  static const bark88 = Color(0xFFE4D7C4);

  /// Light `--color-divider`.
  static const bark89 = Color(0xFFE6D9C6);

  /// Dark `--color-ink`.
  static const bark94 = Color(0xFFF3EADE);
  // bark94b lands on the same measured lightness as bark94 (L 94.0 vs 94.4) and
  // is 1/2/3 away in RGB. Two names for one perceptual value; see
  // references/contrast-audit.md, finding 7.
  /// Dark `--color-surface-inverse`.
  static const bark94b = Color(0xFFF2E8DB);

  /// Light `--color-ink-inverse`.
  static const bark99 = Color(0xFFFFFBF4);

  // clay — brand
  /// Dark `--color-on-brand`.
  static const clay25 = Color(0xFF2A1E15);

  /// Dark `--color-brand-soft`.
  static const clay31 = Color(0xFF3C2E23);

  /// Light `--color-brand-strong`.
  static const clay40 = Color(0xFF5F3E2E);

  /// Light `--color-brand-soft-ink`.
  static const clay43 = Color(0xFF6A452F);

  /// Light `--color-brand`.
  static const clay48 = Color(0xFF7A5340);

  /// Dark `--color-brand`.
  static const clay75 = Color(0xFFD3A480);

  /// Dark `--color-brand-soft-ink`.
  static const clay81 = Color(0xFFE0B694);

  /// Dark `--color-brand-strong`.
  static const clay83 = Color(0xFFE7BE9D);

  /// Light `--color-brand-soft`.
  static const clay91 = Color(0xFFEDE0D3);

  /// Light `--color-on-brand`.
  static const clay98 = Color(0xFFFFF9F1);

  // terracotta — overdue. A confident clay, never a siren red.
  /// Dark `--color-overdue-tint`.
  static const terracotta30 = Color(0xFF402720);

  /// Dark `--color-overdue-edge`.
  static const terracotta37 = Color(0xFF55372B);

  /// Light `--color-overdue-ink`.
  static const terracotta46 = Color(0xFF8C3E28);

  /// Light `--color-overdue`.
  static const terracotta57 = Color(0xFFB4573E);

  /// Dark `--color-overdue`.
  static const terracotta73 = Color(0xFFE39172);

  /// Dark `--color-overdue-ink`.
  static const terracotta82 = Color(0xFFF0B79B);

  /// Light `--color-overdue-edge`.
  static const terracotta85 = Color(0xFFE9C7B7);

  /// Light `--color-overdue-tint`.
  static const terracotta93 = Color(0xFFF7E2D8);

  // ochre — due
  /// Dark `--color-due-tint`.
  static const ochre31 = Color(0xFF3B2F1B);

  /// Dark `--color-due-edge`.
  static const ochre38 = Color(0xFF4E3F24);

  /// Light `--color-due-ink`.
  static const ochre49 = Color(0xFF7F5A15);

  /// Light `--color-due`.
  static const ochre63 = Color(0xFFB0802C);

  /// Dark `--color-due`.
  static const ochre79 = Color(0xFFDDB45F);

  /// Dark `--color-due-ink`.
  static const ochre85 = Color(0xFFEBCB8B);

  /// Light `--color-due-edge`.
  static const ochre88 = Color(0xFFEAD5AB);

  /// Light `--color-due-tint`.
  static const ochre95 = Color(0xFFF8ECD1);

  // slate — due soon
  /// Dark `--color-due-soon-tint`.
  static const slate31 = Color(0xFF24313A);

  /// Dark `--color-due-soon-edge`.
  static const slate38 = Color(0xFF33454F);

  /// Light `--color-due-soon-ink`.
  static const slate46 = Color(0xFF3F5D6A);

  /// Light `--color-due-soon`.
  static const slate57 = Color(0xFF5B7C8A);

  /// Dark `--color-due-soon`.
  static const slate75 = Color(0xFF93B6C3);

  /// Dark `--color-due-soon-ink`.
  static const slate84 = Color(0xFFB4D0DA);

  /// Light `--color-due-soon-edge`.
  static const slate87 = Color(0xFFC4D8DF);

  /// Light `--color-due-soon-tint`.
  static const slate94 = Color(0xFFE2ECF0);

  // sage — ok
  /// Dark `--color-ok-tint`.
  static const sage30 = Color(0xFF25311F);

  /// Dark `--color-ok-edge`.
  static const sage37 = Color(0xFF35452D);

  /// Light `--color-ok-ink`.
  static const sage45 = Color(0xFF435C46);

  /// Light `--color-ok`.
  static const sage55 = Color(0xFF5D7B60);

  /// Dark `--color-ok`.
  static const sage77 = Color(0xFF9CBF9E);

  /// Dark `--color-ok-ink`.
  static const sage85 = Color(0xFFBBD5BC);

  /// Light `--color-ok-edge`.
  static const sage87 = Color(0xFFC7DAC4);

  /// Light `--color-ok-tint`.
  static const sage94 = Color(0xFFE4EDE1);

  // stone — unknown ("we have no history"), non-alarming by construction
  /// Dark `--color-unknown-tint`.
  static const stone29 = Color(0xFF332A21);

  /// Dark `--color-unknown-edge`.
  static const stone36 = Color(0xFF453A2E);

  /// Light `--color-unknown-ink`.
  static const stone49 = Color(0xFF6B5D4F);

  /// Light `--color-unknown`.
  static const stone59 = Color(0xFF8A7C6D);

  /// Dark `--color-unknown`.
  static const stone74 = Color(0xFFB7A794);

  /// Dark `--color-unknown-ink`.
  static const stone82 = Color(0xFFCFC1B0);

  /// Light `--color-unknown-edge`.
  static const stone86 = Color(0xFFDCD1BE);

  /// Light `--color-unknown-tint`.
  static const stone93 = Color(0xFFEEE7DB);

  // pebble — needs odometer ("we need a reading"), non-alarming by construction
  /// Dark `--color-needs-odometer-tint`.
  static const pebble28 = Color(0xFF2F2820);

  /// Dark `--color-needs-odometer-edge`.
  static const pebble35 = Color(0xFF40382E);

  /// Light `--color-needs-odometer-ink`.
  static const pebble43 = Color(0xFF574F46);

  /// Light `--color-needs-odometer`.
  static const pebble53 = Color(0xFF736A5F);

  /// Dark `--color-needs-odometer`.
  static const pebble70 = Color(0xFFA99D8F);

  /// Dark `--color-needs-odometer-ink`.
  static const pebble79 = Color(0xFFC3B8AB);

  /// Light `--color-needs-odometer-edge`.
  static const pebble85 = Color(0xFFD5CDC0);

  /// Light `--color-needs-odometer-tint`.
  static const pebble92 = Color(0xFFEAE5DC);

  // plum — business / personal split
  /// Dark `--color-business-tint`.
  static const plum29 = Color(0xFF332530);

  /// Dark `--color-business-edge`.
  static const plum35 = Color(0xFF463442);

  /// Light `--color-business-ink`.
  static const plum42 = Color(0xFF5F4459);

  /// Light `--color-business`.
  static const plum52 = Color(0xFF7C5E74);

  /// Dark `--color-business`.
  static const plum75 = Color(0xFFC6A2C0);

  /// Dark `--color-business-ink`.
  static const plum83 = Color(0xFFD9BDD4);

  /// Light `--color-business-edge`.
  static const plum86 = Color(0xFFDCC9D8);

  /// Light `--color-business-tint`.
  static const plum94 = Color(0xFFF0E6EE);

  // ember — danger (destructive actions only, never a due state)
  /// Dark `--color-danger-tint`.
  static const ember30 = Color(0xFF422520);

  /// Light `--color-danger`.
  static const ember51 = Color(0xFFA5402B);

  /// Dark `--color-danger`.
  static const ember73 = Color(0xFFE68C72);

  /// Light `--color-danger-tint`.
  static const ember92 = Color(0xFFF7DED6);

  // amber — focus ring
  /// Light `--color-focus`.
  static const amber61 = Color(0xFFA8794F);

  /// Dark `--color-focus`.
  static const amber76 = Color(0xFFD6A874);

  // Shadow tints. NOT roles, and deliberately not on a ramp: these are the
  // opaque rgba() bases inside --elev-1..4, hoisted so CalmShapes never writes
  // a literal either. There is no lightness scale to insert them into, so they
  // are the two names in this file that are not <family><lightness> — and
  // `Black` is a fact about the pixel, the way a measured lightness is, not an
  // appearance claim about a theme.
  /// The light theme's `--elev-*` base: `rgba(76, 50, 32, a)`.
  static const shadowTint = Color(0xFF4C3220);

  /// The dark theme's `--elev-*` base: `rgba(0, 0, 0, a)`.
  static const shadowTintBlack = Color(0xFF000000);
}
