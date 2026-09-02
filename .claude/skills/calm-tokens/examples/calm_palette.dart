// lib/theme/calm/calm_palette.dart — TIER 1.
//
// The ONLY file in the app allowed a colour literal. Every value is copied from
// design/calm/odova.css; nothing here was chosen by an engineer.
//
// Names are `<family><L>` where L is measured OKLCH lightness x 100 — a fact
// about the pixel, so the name cannot lie in either theme. Families are Calm's
// own hue families. The trailing comment records which CSS role(s) each value
// serves, `l:` light and `d:` dark, so a palette diff is reviewable against the
// design without opening the CSS.
//
// A primitive is NEVER read outside lib/theme/calm/ — scripts/check_raw_values.sh
// fails the build on `CalmPalette.` in feature code. Widgets read CalmColors.
import 'package:flutter/painting.dart' show Color;

abstract final class CalmPalette {

  // sand — the paper ramp (warm off-white in light, warm charcoal-brown in dark)
  static const sand18 = Color(0xFF151110); // d:bg-sunk
  static const sand21 = Color(0xFF1D1815); // d:bg
  static const sand25 = Color(0xFF272019); // d:surface, d:chart-plot
  static const sand28 = Color(0xFF31281F); // d:surface-2
  static const sand32 = Color(0xFF3C3127); // d:surface-3
  static const sand90 = Color(0xFFE9DCC9); // l:surface-3
  static const sand93 = Color(0xFFEFE6D9); // l:bg-sunk
  static const sand94 = Color(0xFFF3EADC); // l:surface-2
  static const sand96 = Color(0xFFF8F2E9); // l:bg
  static const sand99 = Color(0xFFFFFCF7); // l:surface, l:chart-plot

  // bark — the ink ramp, plus the divider and the inverse surface
  static const bark24 = Color(0xFF241D17); // d:ink-inverse
  static const bark27 = Color(0xFF2C241E); // l:surface-inverse, l:ink
  static const bark32 = Color(0xFF3A3028); // d:divider, d:chart-grid
  static const bark43 = Color(0xFF5C4E43); // l:ink-2
  static const bark54 = Color(0xFF7B6C5C); // d:ink-4
  static const bark59 = Color(0xFF8B7B6C); // l:ink-3, l:chart-axis-ink
  static const bark65 = Color(0xFF9C8B79); // d:ink-3, d:chart-axis-ink
  static const bark70 = Color(0xFFAC9C8B); // l:ink-4
  static const bark78 = Color(0xFFC6B6A4); // d:ink-2
  static const bark88 = Color(0xFFE4D7C4); // l:chart-grid
  static const bark89 = Color(0xFFE6D9C6); // l:divider
  static const bark94 = Color(0xFFF3EADE); // d:ink
  // bark94b lands on the same measured lightness as bark94 (L 94.0 vs 94.4) and
  // is 1/2/3 away in RGB. Two names for one perceptual value; see
  // references/contrast-audit.md, finding 7.
  static const bark94b = Color(0xFFF2E8DB); // d:surface-inverse
  static const bark99 = Color(0xFFFFFBF4); // l:ink-inverse

  // clay — brand
  static const clay25 = Color(0xFF2A1E15); // d:on-brand
  static const clay31 = Color(0xFF3C2E23); // d:brand-soft
  static const clay40 = Color(0xFF5F3E2E); // l:brand-strong
  static const clay43 = Color(0xFF6A452F); // l:brand-soft-ink
  static const clay48 = Color(0xFF7A5340); // l:brand
  static const clay75 = Color(0xFFD3A480); // d:brand
  static const clay81 = Color(0xFFE0B694); // d:brand-soft-ink
  static const clay83 = Color(0xFFE7BE9D); // d:brand-strong
  static const clay91 = Color(0xFFEDE0D3); // l:brand-soft
  static const clay98 = Color(0xFFFFF9F1); // l:on-brand

  // terracotta — overdue. A confident clay, never a siren red.
  static const terracotta30 = Color(0xFF402720); // d:overdue-tint
  static const terracotta37 = Color(0xFF55372B); // d:overdue-edge
  static const terracotta46 = Color(0xFF8C3E28); // l:overdue-ink
  static const terracotta57 = Color(0xFFB4573E); // l:overdue
  static const terracotta73 = Color(0xFFE39172); // d:overdue
  static const terracotta82 = Color(0xFFF0B79B); // d:overdue-ink
  static const terracotta85 = Color(0xFFE9C7B7); // l:overdue-edge
  static const terracotta93 = Color(0xFFF7E2D8); // l:overdue-tint

  // ochre — due
  static const ochre31 = Color(0xFF3B2F1B); // d:due-tint
  static const ochre38 = Color(0xFF4E3F24); // d:due-edge
  static const ochre49 = Color(0xFF7F5A15); // l:due-ink
  static const ochre63 = Color(0xFFB0802C); // l:due
  static const ochre79 = Color(0xFFDDB45F); // d:due
  static const ochre85 = Color(0xFFEBCB8B); // d:due-ink
  static const ochre88 = Color(0xFFEAD5AB); // l:due-edge
  static const ochre95 = Color(0xFFF8ECD1); // l:due-tint

  // slate — due soon
  static const slate31 = Color(0xFF24313A); // d:due-soon-tint
  static const slate38 = Color(0xFF33454F); // d:due-soon-edge
  static const slate46 = Color(0xFF3F5D6A); // l:due-soon-ink
  static const slate57 = Color(0xFF5B7C8A); // l:due-soon
  static const slate75 = Color(0xFF93B6C3); // d:due-soon
  static const slate84 = Color(0xFFB4D0DA); // d:due-soon-ink
  static const slate87 = Color(0xFFC4D8DF); // l:due-soon-edge
  static const slate94 = Color(0xFFE2ECF0); // l:due-soon-tint

  // sage — ok
  static const sage30 = Color(0xFF25311F); // d:ok-tint
  static const sage37 = Color(0xFF35452D); // d:ok-edge
  static const sage45 = Color(0xFF435C46); // l:ok-ink
  static const sage55 = Color(0xFF5D7B60); // l:ok
  static const sage77 = Color(0xFF9CBF9E); // d:ok
  static const sage85 = Color(0xFFBBD5BC); // d:ok-ink
  static const sage87 = Color(0xFFC7DAC4); // l:ok-edge
  static const sage94 = Color(0xFFE4EDE1); // l:ok-tint

  // stone — unknown ("we have no history"), non-alarming by construction
  static const stone29 = Color(0xFF332A21); // d:unknown-tint
  static const stone36 = Color(0xFF453A2E); // d:unknown-edge
  static const stone49 = Color(0xFF6B5D4F); // l:unknown-ink
  static const stone59 = Color(0xFF8A7C6D); // l:unknown
  static const stone74 = Color(0xFFB7A794); // d:unknown
  static const stone82 = Color(0xFFCFC1B0); // d:unknown-ink
  static const stone86 = Color(0xFFDCD1BE); // l:unknown-edge
  static const stone93 = Color(0xFFEEE7DB); // l:unknown-tint

  // pebble — needs odometer ("we need a reading"), non-alarming by construction
  static const pebble28 = Color(0xFF2F2820); // d:needs-odometer-tint
  static const pebble35 = Color(0xFF40382E); // d:needs-odometer-edge
  static const pebble43 = Color(0xFF574F46); // l:needs-odometer-ink
  static const pebble53 = Color(0xFF736A5F); // l:needs-odometer
  static const pebble70 = Color(0xFFA99D8F); // d:needs-odometer
  static const pebble79 = Color(0xFFC3B8AB); // d:needs-odometer-ink
  static const pebble85 = Color(0xFFD5CDC0); // l:needs-odometer-edge
  static const pebble92 = Color(0xFFEAE5DC); // l:needs-odometer-tint

  // plum — business / personal split
  static const plum29 = Color(0xFF332530); // d:business-tint
  static const plum35 = Color(0xFF463442); // d:business-edge
  static const plum42 = Color(0xFF5F4459); // l:business-ink
  static const plum52 = Color(0xFF7C5E74); // l:business
  static const plum75 = Color(0xFFC6A2C0); // d:business
  static const plum83 = Color(0xFFD9BDD4); // d:business-ink
  static const plum86 = Color(0xFFDCC9D8); // l:business-edge
  static const plum94 = Color(0xFFF0E6EE); // l:business-tint

  // ember — danger (destructive actions only, never a due state)
  static const ember30 = Color(0xFF422520); // d:danger-tint
  static const ember51 = Color(0xFFA5402B); // l:danger
  static const ember73 = Color(0xFFE68C72); // d:danger
  static const ember92 = Color(0xFFF7DED6); // l:danger-tint

  // amber — focus ring
  static const amber61 = Color(0xFFA8794F); // l:focus
  static const amber76 = Color(0xFFD6A874); // d:focus

  // Shadow tints. Not roles — these are the rgba() bases inside --elev-1..4,
  // hoisted so CalmShapes never writes a literal either.
  static const shadowTint = Color(0xFF4C3220); // l:elev-* rgba(76, 50, 32, a)
  static const shadowTintDark = Color(0xFF000000); // d:elev-* rgba(0, 0, 0, a)
}

