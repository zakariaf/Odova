# EPIC-02 — Calm tokens and theme

| | |
|---|---|
| **Epic** | EPIC-02 — Calm tokens and theme |
| **Depends on** | EPIC-01 |
| **Estimate** | **6 h (CC) · ~6 weeks (human)** over 8 tasks |
| **Spec sections** | §2 Non-negotiables (storage is canonical; derived values are never persisted — a colour is derived from a `DueState`, never stored beside it) · §5 Languages, RTL and formats → *Fonts* · §17 *Accessibility gate* |
| **Screens** | none |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

---

## Where we are now

EPIC-01 left a Flutter app that runs and is completely undesigned. Concretely:

- `pubspec.yaml`, `pubspec.lock` and the seven directories under `lib/` exist.
  **`lib/theme/` is an empty directory with a README** naming its owner and pointing at
  `design-system-structure`.
- `lib/app/app.dart` builds a `MaterialApp` with no `theme:` and no `darkTheme:` — it is
  showing Flutter's stock M3 baseline, which is a purple that appears nowhere in Calm.
- The analyzer is armed and real (`very_good_analysis` 10.3.0), `flutter analyze
  --fatal-infos --fatal-warnings` is clean, `flutter test` is green, and three CI jobs
  pass.
- `tools/audit_deps.sh` is live and already refuses `google_fonts` — which matters here,
  because the lazy way to get Vazirmatn is the one thing this app may never do.
- `test/support/pump_app.dart` exists and takes `locale` and `themeMode`. It currently
  pumps an unthemed app; this epic is what gives it something to pin.

What the repo has held all along, and what this epic finally consumes:

- `design/calm/odova.css` — 82 KB, 124 custom properties, 63 of them re-declared under
  `[data-theme="dark"]`. **This is the only source of values.** The `calm-tokens` skill
  repeatedly cites a `tokens.json`; there is no such file in this repo. Read the CSS.
- `design/calm/ACCESSIBILITY-FINDING.md` — two live WCAG 1.4.3 failures in the light
  theme, filed and deliberately not fixed, because the fix is a design judgement.
- `design/_fonts/Vazirmatn.woff2` — the mockup font, in a format **Flutter's font loader
  cannot read**, with no `OFL.txt` beside it.
- `.claude/skills/calm-tokens/examples/` — five reference Dart files
  (`calm_palette.dart`, `calm_colors.dart`, `calm_scales.dart`,
  `calm_shapes_and_motion.dart`, `calm_theme.dart`). They are worked examples to port
  from, not files to copy: every value in them must be re-checked against `odova.css`
  before it lands.

Deliberately still missing after this epic: every widget. `lib/ui/calm/` stays empty.
Tokens and theme only — a component that consumes them is EPIC-03's.

## What we will have when this is done

- `lib/theme/calm/` contains exactly eight files — `calm_palette.dart`, `calm_colors.dart`,
  `calm_type.dart`, `calm_space.dart`, `calm_shapes.dart`, `calm_motion.dart`,
  `calm_status.dart`, `calm_theme.dart` — and they hold **every colour literal, font size,
  radius, duration and curve in the application**.
- `buildCalmTheme(Brightness.light)` and `buildCalmTheme(Brightness.dark)` each return a
  `ThemeData` carrying all five extensions. Running the app and flipping the system theme
  moves it between Calm's warm sand paper and its `#1D1815` ground, with no purple
  anywhere.
- `bash .claude/skills/calm-tokens/scripts/check_raw_values.sh` and
  `check_extension_fields.sh` are green over `lib/`, run in CI, and each has been seen red
  on a planted violation.
- `flutter test test/theme/` proves, without opening a design tool: that every Tier-1
  constant traces to a line in `odova.css`; that all 56 colour roles exist in both
  brightnesses with no dark slot falling through to light; that every extension field
  survives `copyWith` and `lerp`; that Vazirmatn's `wght` axis is intact and covers the
  Sorani letters; and that every declared contrast pair meets its threshold **or is a
  named, dated exception**.
- `design/calm/ACCESSIBILITY-FINDING.md` has an answer written into it: either the token
  values changed and all 112 references were re-shot in the same PR, or the failures are
  listed in `test/theme/calm_contrast_test.dart` as explicit exceptions with the decision
  and the date. There is no third outcome where the app just ships them quietly.
- Later epics get their colour authority: `calm-visual-parity` decides an app surface
  against *these token values*, never against the reference PNG's pixels, because the
  committed references are palette-quantised. Getting these numbers right is what makes
  every screen epic's parity check meaningful.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Rule 12 (RTL and a11y by construction) and rule 14 are what tasks 2.5 and 2.8 enforce. |
| `calm-design-system` | The routing table across the six `calm-*` skills, and `scripts/check_calm_layering.sh` — the gate that keeps `lib/theme/calm/` below `lib/ui/calm/` and stops a token file importing a widget. |
| `calm-tokens` | **The spine of this epic.** Owns the two tiers, the five extension names, the `CalmRamp`, the `ColorScheme` mapping, and both gate scripts. Its four references are the lookup tables every task reads. |
| `design-system-structure` | The general contract `calm-tokens` instantiates: two tiers, `ThemeExtension`, asserting `of()`, hand-authored `ColorScheme`, bundle-don't-fetch fonts, `lerp` honestly or snap deliberately. Read it before `calm-tokens`, as that skill says. |
| `calm-typography-and-rtl` | Owns the nine type roles, the 13px floor, the three weights, the Arabic-script metric compensation, the `em`→logical-pixel tracking conversion, and the Vazirmatn bundling and `LicenseRegistry` obligation. Tasks 2.4 and 2.5 are this skill. |
| `accessibility-as-code` | Task 2.8. Owns the never-colour-alone floor and reading a11y flags from `MediaQuery`; `calm-tokens` owns only the measured ratios. |
| `ci-pipeline-and-gates` | Task 2.7 promotes two gate scripts into CI under named contracts, with self-test arms, and the three-criteria bar a grep gate must clear. |
| `testing-strategy` | Every task here is a pure-Dart test over a value table — fast, no widget harness. This is the shape that keeps them that way. |

`calm-visual-parity` is **not** listed: this epic builds no screen and there is nothing to
compare. The first screen epic loads it.

---

## Tasks

### Task 2.1 — Tier 1: `CalmPalette`, and a test that it traces to the CSS

- **Goal** — every colour literal the application will ever contain exists in one file,
  named by measured value, and each one is provably a line in `design/calm/odova.css`.
- **Spec** — §2 (derived values are never persisted; a palette that drifts from the design
  is a second source of truth for what the app looks like).
- **Skills** — `calm-tokens` (rules 1–2, `references/the-token-tables.md`),
  `design-system-structure` (rule 2).
- **Write these tests first**
  - `test/theme/calm_palette_test.dart` → `'every CalmPalette constant appears as a hex in design/calm/odova.css'`:
    reflects over the constants (or parses the file), extracts each `0xFFRRGGBB`, and
    asserts the six-digit hex occurs in the CSS, case-insensitively. This is the test that
    catches a transcription typo, and it is the whole reason Tier 1 is one file.
  - `test/theme/calm_palette_test.dart` → `'every distinct colour in odova.css has a CalmPalette constant'`:
    the other direction. Parses `--color-*`, `--chart-*` and `--elev-*` declarations in
    both the `:root` and `[data-theme="dark"]` blocks, collects the distinct hexes, and
    asserts each has a constant. Expect **98** — the 96 distinct hexes across 56 roles × 2
    themes, plus the two `--elev-*` shadow tints. If the count differs from 98, the CSS has
    moved since the skill was written: report the real number in the progress file rather
    than editing the test to match.
  - `test/theme/calm_palette_test.dart` → `'constant names are <family><lightness>, never a rank or an appearance name'`:
    asserts each name matches `^[a-z]+[0-9]{2}$` and that none contains `grey`, `dark`,
    `light`, `primary` or `brand`-as-a-prefix. A rank scale has no room to insert and lies
    in dark mode; an appearance name inverts catastrophically.
  - `test/theme/calm_palette_test.dart` → `'CalmPalette is referenced nowhere outside lib/theme/calm/'`:
    a grep test mirroring `check_raw_values.sh`'s second rule. A widget naming `sand96` has
    hardcoded light mode.
- **Then build**
  - `lib/theme/calm/calm_palette.dart` — `abstract final class CalmPalette`, constants
    named `<family><L>` where L is measured OKLCH lightness × 100 (`sand96`, `bark59`,
    `clay48`, `terracotta57`). Each constant carries a trailing comment naming the roles it
    fills, prefixed `l:` or `d:` for the theme, exactly as the skill's example does.
  - Port from `.claude/skills/calm-tokens/examples/calm_palette.dart`, then **re-verify
    every value against `odova.css`**. The example is a worked reference, not the source of
    truth, and the tests above are what make that distinction real.
- **Verify**
  ```bash
  flutter test test/theme/calm_palette_test.dart
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Both directions of the CSS↔Dart trace pass.
  - [ ] The constant count is recorded in the progress file, with the real number if it is
        not 98.
  - [ ] No name encodes a rank, an appearance or a brand.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 2.2 — `CalmRamp` and `CalmColors`

- **Goal** — the semantic colour tier: 37 fields, seven four-rung status families, both
  brightness instances, an asserting `of(context)`, and an honest `lerp`.
- **Spec** — §2 (derived values are never persisted — a status colour is a pure function of
  a `DueState`); §9 Home (due status is a three-signal thing, of which colour is one).
- **Skills** — `calm-tokens` (rules 3, 4, 5, 7, 8; `references/the-token-tables.md`),
  `design-system-structure` (rules 3, 6, 7).
- **Write these tests first**
  - `test/theme/calm_colors_test.dart` → `'CalmColors.of asserts, naming the extension and the builder'`:
    pumps a widget under a bare `Theme` with no extension and asserts the thrown message
    contains both `CalmColors` and `buildCalmTheme()`. Never `?? fallback` — a fallback
    ships a palette the contrast test never saw.
  - `test/theme/calm_colors_test.dart` → `'calmColorsDark reads a dark primitive for all 56 roles'`:
    asserts no field of `calmColorsDark` is identical to the same field of
    `calmColorsLight` unless the CSS declares that role only once. A slot that falls
    through to light is invisible until someone opens the app at night.
  - `test/theme/calm_colors_test.dart` → `'lerp interpolates every field'`: builds
    `calmColorsLight.lerp(calmColorsDark, 0.5)` and asserts each field differs from both
    endpoints wherever the endpoints differ. This is the bug everyone ships once.
  - `test/theme/calm_colors_test.dart` → `'copyWith round-trips every field'`.
  - `test/theme/calm_ramp_test.dart` → `'all seven families are CalmRamps with four distinct rungs'`:
    `overdue`, `due`, `dueSoon`, `ok`, `unknown`, `needsOdometer`, `business` — asserts each
    has `base`, `ink`, `tint`, `edge` and that `base != ink` (they are different jobs:
    `base` is the graphic, `ink` is text on `tint`).
  - `test/theme/calm_ramp_test.dart` → `'every ink-on-tint pair clears 4.5:1 in both themes'`:
    fourteen assertions. This is the pair the skill guarantees, and it is the one that
    makes `ink` safe as a text colour when `base` is not.
  - `test/theme/calm_colors_test.dart` → `'chart1..chart5 alias brand, ok, due, dueSoon and business'`:
    asserts identity, so a legend swatch and a status dot can never disagree.
- **Then build**
  - `lib/theme/calm/calm_colors.dart` — the `CalmRamp` value class (`base`, `ink`, `tint`,
    `edge`, plus its own `lerp`) and `class CalmColors extends ThemeExtension<CalmColors>`
    with the 37 fields the skill's table lists: the paper ramp
    (`bg bgSunk surface surface2 surface3 surfaceInverse divider`), the ink ramp
    (`ink ink2 ink3 ink4 inkInverse`), brand
    (`brand brandStrong brandSoft brandSoftInk onBrand`), `danger dangerTint focus scrim
    sheen`, the chart slots (`chart1..chart5 chartGrid chartAxisInk chartPlot`), and the
    seven `CalmRamp` families.
  - `sheen` is `--elev-sheen`, an **inset** shadow. Flutter has no inset `BoxShadow`, so it
    is carried as a plain `Color` here and painted as a 1px top highlight by `CalmCard` in
    EPIC-03. Leave the comment saying so; it saves the next reader an afternoon looking for
    an API that does not exist.
  - `lib/theme/calm/calm_status.dart` — `CalmStatusStyle`, the only sanctioned route from a
    status to a colour. A widget never names a family directly. The `DueState` enum it
    resolves lands with the due engine; for now the function takes the enum's eventual
    shape and is exercised by the tests above.
  - `const calmColorsLight` and `const calmColorsDark` go in `calm_theme.dart` (task 2.6),
    not here — this file is the type.
- **Verify**
  ```bash
  flutter test test/theme/calm_colors_test.dart test/theme/calm_ramp_test.dart
  bash .claude/skills/calm-tokens/scripts/check_extension_fields.sh lib/theme/calm
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] 37 fields, seven ramps, both instances, no dark slot falling through to light.
  - [ ] `of()` asserts with a message naming the extension and `buildCalmTheme()`.
  - [ ] `check_extension_fields.sh` reports every field carried through `copyWith` and
        `lerp`.
  - [ ] All fourteen ink-on-tint pairs clear 4.5:1.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 2.3 — `CalmSpace`, `CalmShapes` and `CalmMotion`

- **Goal** — the three non-colour extensions, with both unit conversions done correctly and
  the one deliberate `lerp` step commented.
- **Spec** — §17 *Accessibility gate* (minimum touch target 48×48 dp — the space and metric
  tokens are where that floor is expressed); §2 (no layout code uses left or right — the
  radius tokens are directional-safe by being scalars, not `BorderRadius.only`).
- **Skills** — `calm-tokens` (rules 3, 5, 9, 10; `references/the-scale-tokens.md`),
  `calm-layout-and-motion`, `design-system-structure` (rule 8).
- **Write these tests first**
  - `test/theme/calm_scales_test.dart` → `'CalmSpace exposes s1..s7 and every metric token from odova.css'`:
    asserts `s1 == 4`, `s2 == 8`, `s6 == 24`, `s7 == 32` and that the field count matches
    the number of `--space-*` and metric declarations parsed out of the CSS.
  - `test/theme/calm_shapes_test.dart` → `'all eight radii exist and radiusPill is the 999 sentinel'`:
    and a second case, `'radiusPill is never used with BorderRadius.circular'` — a grep over
    `lib/` asserting the pill radius only ever reaches a `StadiumBorder`. 999 in a
    `ClipRRect` is a bug that renders almost right.
  - `test/theme/calm_shapes_test.dart` → `'CSS blur is converted, not pasted'`: for each of
    the five `--elev-*` levels, asserts the Dart `blurRadius` equals
    `(cssBlur / 2 - 0.5) / 0.57735` for the CSS value parsed from `odova.css`, within
    0.01. Pasting the CSS number ships every shadow 1.2–1.65× too soft, worst on the tight
    first layer, and it survives review because it looks like the token.
  - `test/theme/calm_shapes_test.dart` → `'CalmShapes has two instances and the elevations differ between them'`:
    the radii are brightness-independent but `--elev-*` is not — warm clay tint in light,
    black at roughly 6× the alpha in dark. One instance is the bug this catches.
  - `test/theme/calm_motion_test.dart` → `'all five durations and four curves exist, and the curve slots keep the ease prefix'`:
    `easeStandard`, `easeSettle` — so a curve can never collide with a duration.
  - `test/theme/calm_motion_test.dart` → `'CalmMotion.lerp steps deliberately and says so'`:
    asserts `lerp(other, 0.4)` returns this and `lerp(other, 0.6)` returns other, and that
    the source carries the comment explaining why. A half-interpolated `Duration` is not an
    observable thing; a bare step-`lerp` with no comment reads as unfinished and the next
    reader will "fix" it.
- **Then build**
  - `lib/theme/calm/calm_space.dart`, `calm_shapes.dart`, `calm_motion.dart` — one
    extension each, each with an asserting `of(context)` whose message names the extension
    and `buildCalmTheme()`.
  - Two `CalmShapes` instances, light and dark, differing only in the `--elev-*` shadow
    lists.
  - Port from `.claude/skills/calm-tokens/examples/calm_scales.dart` and
    `calm_shapes_and_motion.dart`, re-verifying every number against `odova.css`.
- **Verify**
  ```bash
  flutter test test/theme/calm_scales_test.dart test/theme/calm_shapes_test.dart \
               test/theme/calm_motion_test.dart
  bash .claude/skills/calm-tokens/scripts/check_extension_fields.sh lib/theme/calm
  ```
- **Done when**
  - [ ] Space, radii, elevations, durations and curves all exist as slots, each tracing to
        a line in `odova.css`.
  - [ ] Every shadow's `blurRadius` is the converted value, proved by the test, not the CSS
        number.
  - [ ] `CalmShapes` has two instances; `CalmMotion`'s step carries its comment.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 2.4 — Bundle Vazirmatn and register its licence

- **Goal** — the Arabic-script locales have a real font in the binary, with the `wght` axis
  intact, the Sorani letters covered, and SIL OFL 1.1 honoured on the app's licences page.
- **Spec** — §5 *Fonts* (`en`/`de`/`fr` use the platform font; `fa`/`ar`/`ckb` get
  Vazirmatn for the entire UI, Latin runs included); §17 *Per-locale gate* (font coverage
  test: every codepoint in the fa/ar/ckb ARB files has a real glyph in all four joining
  forms, `ڕ ڵ ۆ ێ ھ ە چ ژ گ پ ک ی` included); §2 (no network — the font is an asset, never
  a fetch).
- **Skills** — `calm-typography-and-rtl` (`references/fonts-and-scripts.md`),
  `design-system-structure` (rule 10), `dependency-hygiene`.
- **Write these tests first**
  - `test/theme/font_bundling_test.dart` → `'the Vazirmatn asset is a TTF or OTF, never woff2'`:
    asserts `pubspec.yaml` declares `assets/fonts/Vazirmatn[wght].ttf`, that the file
    exists, and that its first four bytes are not `wOF2`. **This test fails against the
    repo as it stands** — `design/_fonts/` ships only `Vazirmatn.woff2`, which Flutter's
    font loader cannot read. The fix is to take the variable TTF from the upstream
    release, not to convert the mockup file.
  - `test/theme/font_bundling_test.dart` → `'the wght axis reports min 100, default 400, max 900'`:
    parses the `fvar` table. A subsetter that *instances* the font freezes it to one weight
    and then `FontWeight` and the platform bold-text accessibility flag both stop working —
    failing only for the user who turned bold text on, which is nobody in review.
  - `test/theme/font_coverage_test.dart` → `'every Sorani letter has a glyph'`: asserts the
    `cmap` covers `ڕ ڵ ۆ ێ ھ ە چ ژ گ پ ک ی`, plus U+200C ZWNJ. A letter that falls back
    mid-word cannot be joined by the shaper, and the result is ransom-note text —
    unreadable, not merely ugly.
  - `test/theme/font_coverage_test.dart` → `'GSUB and GPOS survive'`: asserts both tables
    are present. Dropping them breaks the joins outright.
  - `test/theme/font_bundling_test.dart` → `'OFL.txt ships as an asset and is registered'`:
    asserts `assets/fonts/OFL.txt` is declared in `pubspec.yaml` and that
    `LicenseRegistry` yields a `Vazirmatn` entry after bootstrap runs.
  - `test/policy/no_google_fonts_test.dart` → `'google_fonts appears nowhere in pubspec.yaml, pubspec.lock or lib/'`:
    `tools/audit_deps.sh` already refuses it at the dependency level; this is the source
    grep beside it, and it is one line to break.
- **Then build**
  - Take the variable `Vazirmatn[wght].ttf` from the upstream release
    (`github.com/rastikerdar/vazirmatn`, SIL OFL 1.1) into `assets/fonts/`, with `OFL.txt`
    beside it. One variable file, `wght` 100–900 — smaller than three statics, and Calm
    only uses 400/500/600.
  - Subset it: keep Latin-1, U+0600–06FF, U+0750–077F, U+08A0–08FF, U+FDF2 and U+200C;
    exclude the U+FB50–FEFF presentation forms; pass `--layout-features='*'`. Then assert
    the `wght` axis still reports min/default/max — the test above is exactly that
    assertion, so run it after subsetting, not before.
  - Declare the family in `pubspec.yaml` under `flutter: fonts:`.
  - Register the licence in `bootstrap()` (EPIC-01 built that function), before `runApp`:
    `LicenseRegistry.addLicense` yielding a `LicenseEntryWithLineBreaks(['Vazirmatn'], …)`
    from `rootBundle.loadString('assets/fonts/OFL.txt')`.
  - Leave `design/_fonts/Vazirmatn.woff2` alone. It belongs to the HTML mockup pipeline and
    is not the app's asset.
- **Verify**
  ```bash
  flutter test test/theme/font_bundling_test.dart test/theme/font_coverage_test.dart \
               test/policy/no_google_fonts_test.dart
  bash tools/audit_deps.sh
  flutter run                             # then: Settings → licences shows Vazirmatn
  ```
- **Done when**
  - [ ] `assets/fonts/Vazirmatn[wght].ttf` is a real TTF with a live `wght` axis.
  - [ ] All twelve Sorani letters and ZWNJ have glyphs; `GSUB`/`GPOS` are present.
  - [ ] `OFL.txt` ships and appears on the app's licences page.
  - [ ] `google_fonts` is absent from the pubspec, the lock and `lib/`.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 2.5 — `CalmType`, and the Arabic-script metric variant

- **Goal** — nine type roles as `TextStyle`s, three weight slots, two locale variants, and
  both unit errors made impossible by test.
- **Spec** — §5 *Fonts* and *Text expansion*; §17 *Per-locale gate* (zero glyph clipping at
  200% text scale, every screen, every locale).
- **Skills** — `calm-typography-and-rtl` (rules 1–7), `calm-tokens` (rule 3),
  `accessibility-as-code`.
- **Write these tests first**
  - `test/theme/calm_type_test.dart` → `'nine roles, no tenth'`: asserts `CalmType` exposes
    exactly `display hero titleLg title headline bodyLg body label caption` as `TextStyle`
    fields, at 46/34/27/22/19/17/15/14/13 px.
  - `test/theme/calm_type_test.dart` → `'nothing is below 13'`: asserts every role's
    `fontSize >= 13`, and a grep case asserting no `fontSize:` literal under 13 anywhere in
    `lib/`, `lib/theme/` included. Read one-handed at a fuel pump in the rain; 11px axis
    labels are a design that assumes an audience sitting down.
  - `test/theme/calm_type_test.dart` → `'tracking is em × fontSize, not em'`: asserts
    `display.letterSpacing == 46 * -0.02` (−0.92) and `body.letterSpacing == 15 * -0.005`,
    reading the `em` values from `odova.css`. Pasting `-0.02` is a 46× error at display
    size that reads in review as "the tracking token does nothing".
  - `test/theme/calm_type_test.dart` → `'only three weights, and they are slots'`: asserts
    `regular`/`medium`/`semi` are 400/500/600, that no role uses 700, and — a grep case —
    that no literal `FontWeight.w600` appears outside `lib/theme/calm/`.
  - `test/theme/calm_type_test.dart` → `'CalmType.forLocale returns the Arabic-script variant for fa, ar and ckb only'`:
    asserts those three get `fontFamily: 'Vazirmatn'` and `en`/`de`/`fr` get
    `fontFamily: null` — the platform font, per §5, which is the decision and not a
    compromise.
  - `test/theme/calm_type_test.dart` → `'the Arabic variant raises leading on all nine roles and zeroes letterSpacing'`:
    asserts `body.height` goes 1.55 → 1.78 and `display.height` 1.04 → 1.20, that
    `caption` is 13 → 13.5 and `label` 14 → 14.5, and that every Arabic-variant role has
    `letterSpacing == 0`. Arabic stacks dots above and drops tails far below the baseline,
    so a Latin-tuned line box clips them silently; any tracking at all breaks the cursive
    joins.
  - `test/theme/calm_type_test.dart` → `'no italic, no all-caps, no monospace'`: asserts no
    role sets `FontStyle.italic` or a monospace family, and greps `lib/` for
    `TextDecoration.underline` used as emphasis. Arabic has no italic; synthesised obliques
    mangle the joins.
- **Then build**
  - `lib/theme/calm/calm_type.dart` — the only file in the app that may name a size or a
    family. Nine `TextStyle` fields plus `regular`/`medium`/`semi` as `FontWeight` slots,
    an asserting `of(context)`, `copyWith` and `lerp` over all twelve.
  - `CalmType.forLocale(Locale)` returning one of two whole instances — a second `CalmType`,
    not a per-`Text` family override. Mirror the CSS's single reassignment
    (`[lang="fa"], [lang="ar"], [lang="ckb"] { --font-ui: var(--font-arabic) }`).
  - Declare `fontFamilyFallback` for the Arabic variant ending in a known-good face.
- **Verify**
  ```bash
  flutter test test/theme/calm_type_test.dart
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh
  bash .claude/skills/calm-tokens/scripts/check_extension_fields.sh lib/theme/calm
  ```
- **Done when**
  - [ ] Nine roles, three weight slots, two locale instances.
  - [ ] Both unit conversions proved by test, not by reading.
  - [ ] `check_type_floor.sh` is green.
  - [ ] No literal `FontWeight.*` or `fontSize:` outside `lib/theme/calm/`.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 2.6 — Hand-author both `ColorScheme`s and `buildCalmTheme`

- **Goal** — one function returns a `ThemeData` for each brightness, carrying all five
  extensions, with Material's own elevation and tonal tint zeroed so nothing draws two
  shadows.
- **Spec** — §2 (no layout code uses left or right — component themes must not reintroduce
  directional insets); §9 (the home screen's calm depends on one shadow system, not two).
- **Skills** — `calm-tokens` (rules 6, 7, 9; `references/colorscheme-mapping.md`),
  `design-system-structure` (rules 4, 5, 9).
- **Write these tests first**
  - `test/theme/calm_theme_test.dart` → `'ColorScheme.fromSeed and dynamic_color appear nowhere in lib/'`:
    a grep case. `check_raw_values.sh` bans them globally, `lib/theme/calm/` included;
    this test states the reason in a place a person reads. Seeding on `--color-brand`
    `#7A5340` (OKLCH H 47°) regenerates the paper at a clay-pink hue instead of Calm's
    ochre 78–81° and flattens the surface ramp's deliberate 4× chroma rise.
  - `test/theme/calm_theme_test.dart` → `'every M3 role the app reads is explicitly stated'`:
    asserts the 24 roles in `references/colorscheme-mapping.md` are set, in both
    brightnesses, and that `tertiary` is parked on the neutral pair (`ink` / `surface`) —
    Calm's other eight hues all mean something, and a stock widget reaching `tertiary` must
    render as plain text, never as a false status colour.
  - `test/theme/calm_theme_test.dart` → `'both ThemeDatas carry all five extensions'`:
    asserts `extension<CalmColors>()`, `<CalmType>`, `<CalmSpace>`, `<CalmShapes>`,
    `<CalmMotion>` are non-null on light **and** dark. An extension attached to one
    brightness makes `of()` assert only in the theme nobody tested.
  - `test/theme/calm_theme_test.dart` → `'Material elevation and surface tint are zeroed on every component theme'`:
    walks the component themes and asserts `elevation: 0`,
    `shadowColor: Colors.transparent`, `surfaceTintColor: Colors.transparent`, plus
    `surfaceTint == c.surface` on the scheme. Left alone, a `Card` draws Calm's two stacked
    warm shadows *and* M3's tonal lift, and the ramp reads muddy.
  - `test/theme/calm_theme_test.dart` → `'a Material TextField themes itself with no InputDecoration patch'`:
    pumps a bare `TextField` under each theme and asserts its fill, outline and helper
    colours resolve to `surfaceContainerHighest`, `outline` and `onSurfaceVariant`. Naming
    the roles correctly is what buys the free theming; if this fails, a role is missing
    rather than a widget needing a patch.
  - `test/theme/calm_theme_test.dart` → `'the app paints Calm, not Flutter's baseline'`:
    pumps `lib/app/app.dart` through `pumpApp` in all four theme/direction combinations and
    asserts the scaffold background is `calmColorsLight.bg` / `calmColorsDark.bg`. This is
    the test EPIC-01's placeholder screen has been waiting for.
- **Then build**
  - `lib/theme/calm/calm_theme.dart` — `const calmColorsLight`, `const calmColorsDark`, the
    two `CalmShapes` instances, the private `_scheme(Brightness, CalmColors)` builder, and
    `ThemeData buildCalmTheme(Brightness brightness)`.
  - Wire it into `lib/app/app.dart`: `theme: buildCalmTheme(Brightness.light)`,
    `darkTheme: buildCalmTheme(Brightness.dark)`. `ThemeMode` comes from settings in a
    later epic; for now it follows the system.
  - Restoring a persisted theme before first paint is `design-system-structure` rule 9 and
    `app-startup-and-bootstrap` rule 5 — there is no settings store yet, so leave the seam
    in `bootstrap()` with a comment naming the epic that fills it. Do not invent a
    `shared_preferences` read here.
  - Teach `test/support/pump_app.dart` to apply `buildCalmTheme` for its `themeMode`
    argument, so the four-combination harness later epics capture parity with is real from
    now on.
- **Verify**
  ```bash
  flutter test test/theme/
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh
  flutter run                             # flip the system theme; the paper changes, no purple
  ```
- **Done when**
  - [ ] `buildCalmTheme` returns a complete `ThemeData` for both brightnesses, all five
        extensions attached to each.
  - [ ] All 24 M3 roles stated; `fromSeed` and `dynamic_color` absent from `lib/`.
  - [ ] No component draws two shadows.
  - [ ] `pumpApp` applies the real theme, and the four-combination test passes.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 2.7 — Promote both token gates into CI, with self-tests

- **Goal** — a stray hex, a Tier-1 reference in a widget, or a field missing from `lerp`
  fails the build on GitHub, and each of those has been seen to go red.
- **Spec** — §17 (the gates are how the definition of done stays true after the person who
  wrote it moves on).
- **Skills** — `ci-pipeline-and-gates` (rules 1, 7, 9, 10), `calm-tokens` (rule 12),
  `calm-design-system`.
- **Write these tests first** — the tests are self-test arms; the thing under test is a
  script. New section in `tools/check_gates_selftest.sh`, `== calm token gates ==`:
  - `'check_raw_values is green over the real lib/'`.
  - `'check_raw_values is red on a hex planted in lib/ui/'` — write
    `Color(0xFFFF0000)` into a scratch file under `lib/ui/`, assert non-zero, remove,
    assert green again.
  - `'check_raw_values is red on a CalmPalette reference outside lib/theme/calm/'` — the
    second rule, and the one people forget exists.
  - `'check_raw_values is red on ColorScheme.fromSeed even inside lib/theme/calm/'` — that
    ban is global, and the arm is what proves the script's path exemption does not leak.
  - `'check_extension_fields is green over lib/theme/calm'`.
  - `'check_extension_fields is red on a field dropped from lerp'` — delete one field's
    line from a `lerp` body, assert non-zero, restore.
  - `'check_type_floor is green'` and `'check_type_floor is red on a fontSize below 13'`.
  - `'check_calm_layering is green'` — asserts `lib/theme/calm/` imports no widget layer.
- **Then build**
  - The three `calm-*` scripts stay where they are, under `.claude/skills/<skill>/scripts/`
    — they are vendored with their skills and versioned with them. CI calls them by path;
    do not copy them into `tools/`, or there are two versions of each gate within a month.
  - Add to the `app` job in `.github/workflows/ci.yml`, each with the `Contract:` comment
    the workflow's own rule requires:
    - *Contract: every aesthetic value in the app lives in one directory.*
      `bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib`
    - *Contract: a new theme slot transitions and patches, or it is not a slot.*
      `bash .claude/skills/calm-tokens/scripts/check_extension_fields.sh lib/theme/calm`
    - *Contract: 13px is the floor, at a fuel pump in the rain.*
      `bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh`
    - *Contract: tokens sit below components; the layer never inverts.*
      `bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh`
  - Register every arm in `tools/check_gates_selftest.sh`. A gate that has only ever been
    green is a comment (`CLAUDE.md`), and the `repo` job already runs the self-test on
    every push.
- **Verify**
  ```bash
  bash tools/check_gates_selftest.sh      # every new arm shows ok on both sides
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  git push                                # three green jobs, now with four more gates
  ```
- **Done when**
  - [ ] Four gate scripts run in CI, each under a named contract.
  - [ ] Nine self-test arms pass, and each red arm was seen red before the fix.
  - [ ] No gate is duplicated between `.claude/skills/` and `tools/`.
  - [ ] No `continue-on-error` anywhere.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 2.8 — The contrast test, and a decision on the live accessibility finding

- **Goal** — every declared contrast pair is a unit test over both `CalmColors` instances,
  and the two known light-theme WCAG failures are answered in writing rather than shipped
  in silence.
- **Spec** — §17 *Accessibility gate* — "currently the weakest area of this spec and
  treated as a release blocker, not a polish item"; specifically *"lighter text still meets
  4.5:1 contrast"*.
- **Skills** — `accessibility-as-code`, `calm-tokens` (rule 11,
  `references/contrast-audit.md`), `calm-visual-parity` is **not** needed — nothing here
  has a reference image.
- **Write these tests first**
  - `test/theme/calm_contrast_test.dart` → `'every declared (fg, bg, minRatio) triple meets its threshold in both themes'`:
    the audit as executable code. Thresholds are 4.5:1 for text under 18.66px — which is
    every Calm role except `display`, `hero`, `titleLg` and `title` — and 3:1 for large
    text and non-text graphics (status dots, progress fills, focus rings, chart marks).
    Declare the triples from `references/contrast-audit.md`; compute with
    `Color.computeLuminance`.
  - `test/theme/calm_contrast_test.dart` → `'the known light-theme failures are explicit, dated exceptions'`:
    a second list, `knownContrastExceptions`, each entry carrying the pair, the measured
    ratio, the threshold, the date and one line of decision. The test asserts each listed
    exception **still fails** — so when the design is fixed the test goes red and forces
    the exception's removal. An exception that silently becomes stale is how a fixed bug
    gets recorded as permanent.
  - `test/theme/calm_contrast_test.dart` → `'no pair is missing from the declaration'`:
    asserts the triple list covers every `(ink*, surface*)` combination and every
    `(ramp.ink, ramp.tint)` pair, so adding an ink slot without declaring its pairs fails
    rather than passing by omission.
  - `test/theme/calm_contrast_test.dart` → `'ink4 is never reachable as a text or affordance colour'`:
    a grep case over `lib/` once components exist; for now it asserts `CalmColors.ink4` is
    referenced only from `lib/theme/calm/`. Disabled uses are exempt under SC 1.4.3;
    `.row__chev` and the chart label in the CSS are not, and both must move to `ink3` or
    `ink2` when EPIC-03 builds them.
- **Then build** — this task's deliverable is a **decision**, then the code that records
  it. `design/calm/ACCESSIBILITY-FINDING.md` states both failures and their cost:

  | Failure | Measured | Options |
  |---|---|---|
  | `--color-ink-3` `#8B7B6C` fails 4.5:1 on all four light surfaces (3.67 / 3.99 / 3.42 / 3.02), used as `color:` in 47 CSS rules, 25 of them at 13–14px | worst 3.02 on `surface-3` | `#6B5F53` clears all four (5.57 / 6.06 / 5.20 / 4.59). `#776758` clears three and requires never placing tertiary text on `surface-3`. |
  | `--color-ink-4` `#AC9C8B` used for `::placeholder`, 2.60:1 on `surface` | below even the 3:1 non-text floor | point placeholders at the corrected `ink3`. Its other uses (`.row__chev`, `.is-disabled`) are defensible; only the placeholder use is a failure. |

  Exactly one of two paths, and the epic is not done until one is complete:

  - **Fix.** Change the two values in `design/calm/odova.css`, rebuild `screens.html`,
    re-shoot and re-optimise **all 108 Calm reference PNGs** (about 4 minutes per the
    finding), and say in the PR what changed and why. `calm-visual-parity` rule 7: a
    deliberate design change regenerates the reference set **in the same PR**. Then
    `CalmPalette` gains `bark*` constants at the new lightness and the exception list is
    empty.
  - **Ship knowingly.** Leave the values, add both pairs to `knownContrastExceptions` with
    today's date and the sentence justifying it, and append the decision to
    `ACCESSIBILITY-FINDING.md` under a `## Decision` heading with who made it. §17 calls
    accessibility a release blocker, so this path also files the follow-up as a `§18
    Decisions still open` entry in `SPEC.md`.

  Whichever is taken, the test file is the record and the finding document gets the
  outcome. Do not take a third path — widening a threshold, or dropping a pair from the
  declaration, is falsifying the test.
- **Verify**
  ```bash
  flutter test test/theme/calm_contrast_test.dart
  # if the fix path was taken:
  node tools/build_screens.mjs && node tools/shoot_design.mjs && node tools/optimise_png.mjs
  git status --short design/reference/calm/   # 108 files changed, in this PR
  ```
- **Done when**
  - [ ] Every declared pair passes, over both `CalmColors` instances.
  - [ ] The exception list is either empty (fix path) or complete, dated and mirrored in
        `ACCESSIBILITY-FINDING.md` under `## Decision` (ship-knowingly path).
  - [ ] If values changed, all 108 Calm reference PNGs were regenerated in the same PR and
        the PR says what changed.
  - [ ] No threshold was widened and no pair was dropped.
  - [ ] The decision, and who made it, is in the progress file.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

## Definition of done

- [ ] `lib/theme/calm/` contains exactly the eight files named in `calm-tokens`'
      definition of done, and holds every colour literal, font size, radius, duration and
      curve in the application.
- [ ] All 56 colour roles, 9 type roles, the space and metric values, 8 radii, 5
      elevations, 5 durations and 4 curves exist as slots, each tracing to a line in
      `design/calm/odova.css`.
- [ ] `calmColorsDark` reads a dark primitive for all 56 roles — no slot falls through to
      light.
- [ ] `buildCalmTheme` hand-authors both `ColorScheme`s; `fromSeed` and `dynamic_color`
      appear nowhere in `lib/`.
- [ ] Vazirmatn ships as a TTF with a live `wght` axis and full Sorani coverage; `OFL.txt`
      is registered; `google_fonts` is absent from the pubspec, the lock and `lib/`.
- [ ] The four token gates run in CI under named contracts, and every self-test arm added
      in this epic has been seen red.
- [ ] The two WCAG findings in `design/calm/ACCESSIBILITY-FINDING.md` have a written
      decision behind them, in the test file and in the document.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-02.md`.** It
> starts empty. Append one line per task as it completes — what was built, what was
> deferred, and anything the next epic needs to know. It is the running log for this epic
> and the handover to the next one.
