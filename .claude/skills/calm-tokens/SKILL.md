---
name: calm-tokens
description: >-
  Owns Odova's Calm token set as Dart: two tiers (primitives named by measured value, semantic
  slots named by role) exposed as five ThemeExtensions — CalmColors, CalmType, CalmSpace,
  CalmShapes, CalmMotion — each with an asserting of(context) and an honest lerp, plus hand-
  authored light and dark ColorScheme instances rather than ColorScheme.fromSeed, whose seed
  algorithm does not preserve Calm's warm ramp. Semantic states are CalmRamp values
  (base/ink/tint/edge). Every hex, radius, duration and fontSize is confined to lib/theme/calm/**
  behind a no-raw-values gate; a legitimate new need is a new token slot, never an ignore comment.
  Use when creating or editing ThemeData/ThemeExtension/ColorScheme, adding or renaming a token,
  reaching for fromSeed or a raw Color/Duration/BorderRadius/fontSize in feature code, checking a
  contrast pair, or asking what Calm's value for a colour, size, radius or curve actually is.---

# calm-tokens

Calm ships as 412 CSS classes over 124 custom properties, 63 of which are re-declared under
`[data-theme="dark"]`. This skill is the one place those values become Dart, and the reason it is
worth writing down is that most of the interesting decisions are *not* transcription: which of
Calm's 56 colour roles a widget is even allowed to name, why a seed algorithm cannot produce this
palette, what a CSS blur radius means to Skia, and which five light-theme pairs fail today.
`design-system-structure` owns the general shape of all of this — two tiers, `ThemeExtension`, an
asserting `of()`, the no-raw-values gate. **Read that first; this skill owns Calm's content, its
contract, and its defects.**

Read the reference for the task at hand:
- `references/the-token-tables.md` — every colour token, light and dark side by side, grouped
  surface ramp / ink ramp / brand / the seven four-rung semantic families / chart, with the
  Tier-1 primitive each maps to. The lookup table.
- `references/the-scale-tokens.md` — type (size, leading, weight, tracking per role), spacing and
  metrics, radius, the two elevation sets, and motion, plus the two unit conversions (CSS `em` →
  logical pixels, CSS blur → `blurRadius`) that are the usual source of a bad port.
- `references/colorscheme-mapping.md` — which Calm slot fills which M3 role in both brightnesses,
  the measured reason `ColorScheme.fromSeed` cannot reach Calm's ramp, and the roles Calm parks
  on a neutral on purpose.
- `references/contrast-audit.md` — every pair measured, the seven findings, and the shape of the
  unit test that keeps them from regressing.

Run `scripts/check_raw_values.sh` and `scripts/check_extension_fields.sh` before a PR.

## Non-negotiable rules

1. **Every value comes from `design/calm/odova.css`.** If a hex, size, duration or curve is not
   in `tokens.json`, the design does not have it — that is a question for the design, never a
   number you pick. WHY: Calm's ramps are hand-tuned (the surface ramp's chroma rises .007 → .029
   on purpose); one invented in-between value breaks a relationship nobody documented.
2. **Two tiers, and no widget touches Tier 1.** `lib/theme/calm/calm_palette.dart` is the only
   file in the app with a colour literal; its constants are named `<family><L>` where L is
   measured OKLCH lightness × 100 (`clay48`, `sand96`, `terracotta57`). Everything else reads a
   slot. WHY: a measured name cannot lie in either theme, and `sand96` in a widget is a widget
   that has hardcoded light mode — `check_raw_values.sh` fails on `CalmPalette.` outside
   `lib/theme/calm/`.
3. **Five extensions, these exact names, this exact naming map.** `CalmColors`, `CalmType`,
   `CalmSpace`, `CalmShapes`, `CalmMotion`, one file each under `lib/theme/calm/`.
   `--color-ink-2` → `.ink2`; `--space-4` → `.s4`; `--radius-2xl` → `.radius2xl`; `--dur-base` →
   `.base`; `--ease-standard` → `.easeStandard` and `--ease-settle` → `.easeSettle` (the `ease`
   prefix stays, so a curve never collides with a duration); `--fs-title` + `--lh-title` + the
   weight and tracking of `.t-title` collapse into one `CalmType.of(c).title`. On top of the nine
   roles, `CalmType` carries `--fw-regular/medium/semi` as three `FontWeight` slots — `.regular`,
   `.medium`, `.semi` — so a component can step a role up in weight without inventing a
   `fontSize`; `--fw-bold` gets no slot because no role uses it. WHY: five other Calm skills and
   every widget name in the contract are written against these identifiers; a rename is a rename
   of the whole system.
4. **`of(context)` asserts, and the message names the extension and the builder.**
   `assert(ext != null, 'CalmColors missing. Build ThemeData via buildCalmTheme().')` — never
   `?? fallback`. WHY: a fallback ships a palette the contrast test never saw, on the one device
   with no debugger attached.
5. **`lerp` carries every field.** Colours through `Color.lerp`, doubles through `lerpDouble`,
   `TextStyle.lerp`, `BoxShadow.lerpList`; `CalmMotion` is a **commented deliberate step**,
   because a half-interpolated `Duration` is not an observable thing. `scripts/check_extension_fields.sh`
   fails on a field missing from `copyWith` or `lerp`. WHY: the compiler cannot see a forgotten
   field — `copyWith`'s signature is yours and `lerp` just drops it — so the new slot silently
   never transitions, forever.
6. **Hand-author `ColorScheme` for both brightnesses; `ColorScheme.fromSeed` is banned in
   `lib/`.** Seeding on `--color-brand` (`#7A5340`, OKLCH H 47°) regenerates the paper at a
   clay-pink hue instead of Calm's ochre 78–81°, and flattens the surface ramp's deliberate
   4× chroma rise to M3's constant neutral chroma. WHY: there is no seed that produces this ramp,
   so there is nothing to "seed plus override" — and `fromSeed`'s per-role overrides do not
   propagate anyway (`design-system-structure`, rule 4).
7. **Both `ThemeData`s carry all five extensions, and dark is authored, not inverted.** Dark
   raises every chroma-bearing slot (`clay48` → `clay75`, `terracotta57` → `terracotta73`)
   because a light-theme saturation on `#1D1815` loses roughly two stops of contrast. WHY: an
   extension attached to one brightness makes `of()` assert only in the theme nobody tested.
8. **A status colour is reached through `CalmStatusStyle`, never by naming a family.** Each
   family is a `CalmRamp` of four rungs: `base` is the *graphic* (dot, ring, progress fill),
   `ink` is *text on `tint`*, `edge` is the fill's boundary. `--color-due` measures 3.44:1 on
   `surface`: a legal 12pt dot and an illegal status line. WHY: SPEC.md §9 makes due status a
   three-signal thing (dot shape, colour, wording); a flat `Color due` invites the fourth
   mistake — rendering 13px text in it. Resolution lives in `calm-due-state-and-status`.
9. **Elevation is a `CalmShapes` `BoxShadow` list, and Material's own elevation is zeroed.**
   `elevation: 0`, `shadowColor: Colors.transparent`, `surfaceTintColor: Colors.transparent` on
   every component theme, plus `surfaceTint: c.surface` on the scheme. WHY: Calm's `--elev-*` is
   two stacked warm-tinted shadows; left alone, a `Card` draws Calm's *and* M3's tonal lift, and
   the ramp reads muddy.
10. **CSS blur is not `blurRadius`, and CSS `em` is not `letterSpacing`.** CSS blur-radius is
    2σ, Flutter's is `r * 0.57735 + 0.5`; CSS tracking is relative to font size, Flutter's is
    logical pixels. Convert: `blurRadius = (cssBlur / 2 - 0.5) / 0.57735`,
    `letterSpacing = fontSize * em`. WHY: skipping the first ships every shadow 1.2-1.65× too
    soft, worst on the tight first layer; skipping the second makes `--tracking-tight` a 46×
    error at display size that reads as "the tracking token does nothing".
11. **AA is a unit test over both `CalmColors` instances, not a review opinion.** Declare the
    `(fg, bg, minRatio)` triples and fail the build. WHY: five light pairs fail *today* —
    `ink3` on every light surface, `ink4` below 3:1, `--color-due` at 3.00 on its own tint and
    2.95 on `surface2`, `--color-focus` at 2.82 on `surface3`, `--chart-3` at 2.48 over
    `--chart-grid` (`references/contrast-audit.md`). Shipping them knowingly is a decision;
    shipping the next one by accident is a defect.
12. **The gate is the law: no raw value, no primitive, no `// ignore` outside
    `lib/theme/calm/`.** A legitimate new need is a new slot. WHY: "one directory to diff" is the
    only property that makes a palette fix a one-commit change.

## The two tiers

```dart
// lib/theme/calm/calm_palette.dart — TIER 1, the only colour literals in the app.
// <family><L>, L = measured OKLCH lightness x 100. The comment records the roles.
abstract final class CalmPalette {
  static const sand96 = Color(0xFFF8F2E9);        // l:bg
  static const bark59 = Color(0xFF8B7B6C);        // l:ink-3, l:chart-axis-ink
  static const clay48 = Color(0xFF7A5340);        // l:brand, l:chart-1
  static const terracotta57 = Color(0xFFB4573E);  // l:overdue
}
```

Calm has no synonym problem to solve — most hexes serve exactly one role — so the tier looks
redundant until dark: `ink3` is `bark59` in light and `bark65` in dark, and only the slot name is
stable across both. Full file: `examples/calm_palette.dart` (98 constants: the 96 distinct
hexes across all 56 roles × 2 themes, plus the two `--elev-*` shadow tints).

## The four-rung ramp

Every stateful family in Calm ships the same four values, and keeping them in one object is what
stops `base` being used as a text colour:

```dart
@immutable
class CalmRamp {
  const CalmRamp({required this.base, required this.ink, required this.tint, required this.edge});
  final Color base; // the graphic. 3:1. Several bases are under 4.5 — never text.
  final Color ink;  // text on `tint`. Every ink/tint pair clears 4.5:1, both themes.
  final Color tint; // the fill
  final Color edge; // the 1px boundary of the fill
  CalmRamp lerp(CalmRamp other, double t) => CalmRamp(
        base: Color.lerp(base, other.base, t)!,
        ink: Color.lerp(ink, other.ink, t)!,
        tint: Color.lerp(tint, other.tint, t)!,
        edge: Color.lerp(edge, other.edge, t)!,
      );
}
```

Seven families use it: `overdue`, `due`, `dueSoon`, `ok`, `unknown`, `needsOdometer`, `business`.
The first six are `DueState`; `business` is the trip category. Full class, all 37 `CalmColors`
fields, `of`, `copyWith` and `lerp`: `examples/calm_colors.dart`. The two instances and the theme
builder: `examples/calm_theme.dart`.

## What `CalmColors` does and does not expose

| On the extension, flat | Why |
|---|---|
| `bg bgSunk surface surface2 surface3 surfaceInverse divider` | the paper ramp; `surfaceInverse` equals `ink` in light on purpose |
| `ink ink2 ink3 ink4 inkInverse` | `ink3` and `ink4` carry live AA findings — see the audit |
| `brand brandStrong brandSoft brandSoftInk onBrand` | one brand hue; there is no secondary |
| `danger dangerTint focus scrim sheen` | `danger` is delete/restore only — overdue is terracotta, never an alarm |
| `chart1..chart5 chartGrid chartAxisInk chartPlot` | `chart1..5` alias brand/ok/due/dueSoon/business so a legend and a dot cannot disagree |
| `overdue due dueSoon ok unknown needsOdometer business` | `CalmRamp`, read through `CalmStatusStyle` |

`sheen` is `--elev-sheen`, an **inset** shadow. Flutter has no inset `BoxShadow`, so it is carried
as a `Color` and painted by `CalmCard` as a 1px top highlight — a Flutter gap, recorded here so
nobody spends an afternoon looking for the API.

## Hand-authoring the scheme

```dart
ColorScheme _scheme(Brightness brightness, CalmColors c) => ColorScheme(
      brightness: brightness,
      primary: c.brand, onPrimary: c.onBrand,
      primaryContainer: c.brandSoft, onPrimaryContainer: c.brandSoftInk,
      // Parked on the neutral pair: Calm's other eight hues all MEAN something
      // (ochre = due, plum = business trip). A stock widget reaching `tertiary`
      // must render as plain text, never as a false status colour.
      tertiary: c.ink, onTertiary: c.surface,
      surface: c.surface, onSurface: c.ink,
      surfaceContainerHighest: c.surface3, onSurfaceVariant: c.ink2,
      outline: c.divider, outlineVariant: c.divider,
      error: c.danger, onError: c.inkInverse,
      // No --color-danger-ink exists; `danger` on `dangerTint` is 4.86:1 light.
      errorContainer: c.dangerTint, onErrorContainer: c.danger,
      surfaceTint: c.surface, // a no-op: M3's tonal lift would put clay in #FFFCF7
    );
```

The full 24-role mapping, with the measured contrast for every `on` pair and the argument against
`fromSeed`, is `references/colorscheme-mapping.md`. Naming the roles correctly is what buys the
free theming: a Material `TextField` resolves `surfaceContainerHighest`, `onSurfaceVariant`,
`outline` and `error` unaided, so `CalmField` needs no per-widget `InputDecoration` patch.

## Anti-patterns

- **A hex, `Colors.*`, `Cubic(...)`, `Duration(milliseconds: 240)`, `BorderRadius.circular(28)`,
  `fontSize: 15` or `CalmPalette.sand96` in `lib/ui/calm/`** — the gate fails; the fix is a slot
  read or a new slot, never `// ignore`.
- **`ColorScheme.fromSeed(seedColor: CalmPalette.clay48)`** — produces a rosy paper ramp at
  H 47° and a flat neutral chroma. There is no seed for Calm.
- **A flat `Color overdue` on `CalmColors`, or `Text(style: TextStyle(color: c.due.base))`** —
  `base` is a graphic colour; `--color-due` on `surface` is 3.44:1 and on `surface2` is 2.95:1.
- **Pasting the CSS number into `blurRadius`, or `-0.02` into `letterSpacing`** — both are unit
  errors, both survive review because they look like the token.
- **`CalmShapes` with one instance** — the radii are brightness-independent but `--elev-*` is
  not (warm clay tint in light, black and roughly 6× the alpha in dark).
- **`BorderRadius.circular(shapes.radiusPill)` on a `ClipRRect`** — `--radius-pill` is 999, a
  sentinel; use `StadiumBorder`.
- **Adding a slot to the constructor and `copyWith` but not `lerp`** — `check_extension_fields.sh`
  exists because this is the bug everyone ships once.
- **Reading `tertiary`, `onPrimaryFixed`, `primaryFixedDim` or any role the mapping table does
  not list** — an unstated role is a value nobody chose and the gate cannot see it.
- **Darkening `--color-divider` to chase a contrast ratio** — a separator is decorative;
  SC 1.4.11 does not govern it, and Calm's whole premise is layered shadow, never a hard border.
- **Treating `unknown` or `needsOdometer` as a muted `overdue`** — SPEC.md §1 forbids the app
  from guessing in a way that looks like fact; both families are non-alarming by construction.

## Definition of done

- [ ] `scripts/check_raw_values.sh` and `scripts/check_extension_fields.sh` are clean over `lib/`.
- [ ] `lib/theme/calm/` contains exactly `calm_palette.dart`, `calm_colors.dart`, `calm_type.dart`,
      `calm_space.dart`, `calm_shapes.dart`, `calm_motion.dart`, `calm_status.dart`,
      `calm_theme.dart` — and every colour literal in the app is in the first of those.
- [ ] All 56 colour roles, 9 type roles, 16 space/metric values, 8 radii, 5 elevations, 5
      durations and 4 curves exist as slots; every one traces to a line in `tokens.json`.
- [ ] `calmColorsDark` reads a dark primitive for all 56 roles — no slot falls through to light.
- [ ] `ColorScheme` is hand-authored for both brightnesses, `fromSeed`/`dynamic_color` appear
      nowhere in `lib/`, and every role a widget reads is stated.
- [ ] All five extensions are attached to **both** `ThemeData`s; `of()` asserts with a message
      naming the extension.
- [ ] `lerp` covers every field; `CalmMotion`'s step carries the comment saying it is deliberate.
- [ ] A `calm_contrast_test.dart` walks the declared pairs over both instances; the five known
      light failures are in the test as explicit, dated exceptions, not silently absent.
- [ ] Component themes zero Material elevation and surface tint; no `Card` draws two shadows.
- [ ] Shadow blur and letter spacing are converted, not pasted.

## Related skills

- See `calm-design-system` for the front door and the routing table to the other five Calm skills.
- See `calm-due-state-and-status` for `DueState`, `CalmStatusStyle`, and the redundant encoding
  that decides which rung of a `CalmRamp` a widget is handed.
- See `calm-typography-and-rtl` for which face is bundled, the Vazirmatn cascade, the per-locale
  leading bump, the 13px floor and the no-monospace rule — this skill only carries the numbers.
- See `calm-layout-and-motion` for what the duration and curve tokens are spent on, the 52px
  touch floor, and reduced motion.
- See `calm-components` for the widgets that consume these slots.
- See `design-system-structure` for the general two-tier/ThemeExtension/`of()`/gate contract this
  skill instantiates — do not re-derive it here.
- See `accessibility-as-code` for the never-colour-alone floor and reading a11y flags from
  `MediaQuery`; this skill only owns the measured ratios.
- See `dataviz` for series ordering and chart form; `chart1..5` are its palette.
- See `app-startup-and-bootstrap` for restoring the theme before first paint.
- See `lint-and-style-config` and `ci-pipeline-and-gates` for promoting both scripts into CI.
- See `widget-golden-and-a11y-testing` for the greyscale golden that proves colour is never the
  only signal.

## References

- Flutter API — `ThemeExtension`: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Flutter API — `ColorScheme` (role list, `fromSeed`): https://api.flutter.dev/flutter/material/ColorScheme-class.html
- Flutter API — `BoxShadow` / `Shadow.convertRadiusToSigma`: https://api.flutter.dev/flutter/painting/Shadow/convertRadiusToSigma.html
- Flutter API — `TextStyle.letterSpacing` (logical pixels): https://api.flutter.dev/flutter/painting/TextStyle/letterSpacing.html
- Flutter API — `Color.withValues`: https://api.flutter.dev/flutter/dart-ui/Color/withValues.html
- Flutter API — `Color.computeLuminance`: https://api.flutter.dev/flutter/dart-ui/Color/computeLuminance.html
- CSS Backgrounds 3 — `box-shadow` blur radius is 2σ: https://www.w3.org/TR/css-backgrounds-3/#shadow-blur
- CSS Values 4 — the `em` unit: https://www.w3.org/TR/css-values-4/#font-relative-lengths
- Material Design 3 — colour roles: https://m3.material.io/styles/color/roles
- W3C WAI — WCAG 2.2 SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WAI — WCAG 2.2 SC 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
