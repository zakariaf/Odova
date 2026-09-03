# EPIC-02 — Calm tokens and theme

Branch `epic/02-calm-tokens-and-theme`. One line per task, plus what the next
epic needs to know.

## Tasks

- **2.1 `CalmPalette`** — 98 constants. The count was verified against the CSS
  *before* the expectation was written: parsing `:root` and `[data-theme="dark"]`
  gives 56 roles each and **96 distinct hexes**, exactly the epic's prediction,
  plus the two `--elev-*` shadow tints. The trace runs both ways, so neither a
  transcription typo nor a colour the app can never render survives.
  `shadowTintDark` was renamed `shadowTintBlack` — the naming rule forbids an
  appearance word because it inverts between themes, and `Dark` is that word.
  The two shadow tints are exempt from `<family><lightness>` with the reason in
  the source: they are not rungs on any ramp.

- **2.2 `CalmRamp` and `CalmColors`** — 37 fields, seven four-rung families, both
  instances. The strongest test in the epic is the **56-role trace table**: every
  CSS role against the accessor it must reach, written out rather than derived,
  with a second test asserting the table covers every role the CSS declares.
  `calmColorsDark` is asserted unconditionally to differ from light on all 56 —
  the epic hedged, but the CSS declares all 56 in both blocks and no role shares
  a value.

- **2.3 `CalmSpace`, `CalmShapes`, `CalmMotion`** — the CSS blur conversion is
  proved rather than trusted, in both themes and at all five levels, with a
  guard-the-guard case pinning `_expectedBlur(2)` to 0.866 so a wrong
  expectation cannot pass a wrong implementation. `CalmMotion.lerp` steps and
  the test asserts the source says why.

- **2.4 Vazirmatn** — the upstream variable TTF (v33.003), 241 KB, with
  `OFL.txt` registered through `LicenseRegistry` from `bootstrap()`. The font
  gates are a **Dart sfnt reader** (`test/support/ttf_reader.dart`) rather than
  `fonttools`, so they run anywhere `flutter test` runs.

- **2.5 `CalmType`** — nine roles, three weight slots, two whole script
  variants. Both unit errors planted and seen red.

- **2.6 `buildCalmTheme`** — both `ColorScheme`s stated role by role, all 33
  asserted; five extensions on both brightnesses; Material elevation and splash
  off. The app paints Calm in all four theme/direction combinations.

- **2.7 The four token gates in CI** — fourteen self-test arms, all seen red.

- **2.8 The contrast audit** — see *The accessibility decision* below.

## What the next epic needs to know

1. **`DueState`, `DueDriver` and `DueConfidence` live in
   `lib/core/due/due_state.dart`, not in `lib/theme/calm/calm_status.dart`.**
   EPIC-02, EPIC-03, EPIC-08 and EPIC-10 all describe the enum as living in
   `calm_status.dart`; EPIC-07 requires `lib/core/due/` — which may not import
   Flutter — to *return* it. Both cannot hold, because `calm_status.dart` needs
   `Color`. The enums are pure Dart and `calm_status.dart` **re-exports** them,
   so `import 'package:odova/theme/calm/calm_status.dart'` still yields
   `DueState` and every epic's text stays true. What a state IS belongs to the
   domain; what it LOOKS LIKE belongs to the theme.

2. **`buildCalmTheme(Brightness, {CalmType? type})` takes the locale's type
   variant.** `lib/app/app.dart` passes `CalmType.forLocale(locale)`, so a
   language change carries the Arabic-script metrics with it — SPEC.md §5's
   "no restart" is a rebuild from the root, not a theme animation. **EPIC-04
   owns making that follow the RESOLVED locale**: today it follows the
   *requested* one, and `locale: null` (the shipping default, "follow the
   device") falls back to Latin, so a device set to Persian gets Persian strings
   with Latin type metrics until EPIC-04's locale controller exists. That is the
   one real gap this epic leaves.

3. **`themeMode` is a parameter with no store behind it.**
   `design-system-structure` rule 9 wants the persisted mode restored before
   first paint. There is no settings store; the seam is `OdovaApp.themeMode` and
   **EPIC-14** fills it from `SettingsRepository`.

4. **`lib/ui/calm/` is still empty and `lib/app/app.dart` uses a `Material`, not
   a `Scaffold`.** `check_calm_layering.sh` refuses a raw `Scaffold(` outside
   `lib/ui/calm/`. EPIC-03 builds `CalmScaffold`; until it does, a feature
   screen cannot use `Scaffold` and should not try.

5. **`CalmShapes.card()` and `.sheet()` exist** and `calm_theme.dart` already
   feeds them to `cardTheme` and `bottomSheetTheme`. EPIC-03's `CalmCard` reads
   the same shape rather than composing a second one.

6. **`CalmType.tabular(style)` is how figures line up.** A font feature, never a
   family swap — Calm has no monospace anywhere and `check_type_floor.sh`
   enforces it.

7. **The font is not subsetted, deliberately.** 241 KB is not a size problem in
   an APK, and subsetting needs `fonttools`, whose failure mode is exactly what
   the `fvar` test exists to catch — an *instanced* font that silently kills
   `FontWeight` and the platform bold-text flag. If a later epic wants the
   saving, the command is
   `pyftsubset 'Vazirmatn[wght].ttf' --unicodes='U+0000-00FF,U+0600-06FF,U+0750-077F,U+08A0-08FF,U+FDF2,U+200C' --layout-features='*' --output-file=…`
   and `test/theme/calm/font_bundling_test.dart` is the gate that must stay
   green after it.

8. **Three gates were fixed, and two of them were punishing the comment that
   explains them.** `check_extension_fields.sh` could not see a field
   declaration `dart format` had wrapped across lines — it reported 33 fields
   over a class with 41. `check_calm_layering.sh` and
   `expectNoBannedPatterns` both matched inside comments, so a doc comment
   naming `Scaffold(` or `ColorScheme.fromSeed` in order to forbid it failed the
   build. All three now behave like `check_raw_values.sh`, which had it right.

9. **`test/support/` grew five helpers** every later epic can use:
   `calm_css.dart` (the CSS is the design; parse it, never retype it),
   `contrast.dart`, `ttf_reader.dart`, `capture_context.dart` and
   `analysis_options_source.dart`.

## The accessibility decision — SPEC.md §18 question 25

`design/calm/ACCESSIBILITY-FINDING.md` is answered under `## Decision`, dated
2026-09-03: **ship knowingly, and hand the design judgement to EPIC-17.**
`CLAUDE.md` §9 already assigns the closure there, and the finding document says
in its own words that the remedy is a design judgement rather than an
engineering one.

Eight pairs are recorded as dated exceptions in
`test/theme/calm/calm_contrast_test.dart`, each carrying its measured ratio, and
the test asserts each **still fails at that exact ratio** — so the day the
values change it goes red and forces the exception's removal.

**Writing the test found two things the finding document does not say, and
EPIC-17 needs both:**

- `--color-ink-3` **also fails in dark** — 4.39:1 on `surface-2`, 3.84:1 on
  `surface-3`. The document calls the finding light-theme-only.
- `--color-focus` is **2.82:1 on `surface-3`**, below SC 1.4.11's 3:1 for a
  focus indicator. A control inside a `surface-3` container gets a ring the
  keyboard-only user cannot see. Fixing `ink-3` alone leaves that user no better
  off.

**The cost curve points at deciding early**: today it is two hex values and one
re-shoot of the 112 reference PNGs (~4 minutes, no app code because no screen
exists); after EPIC-15 it is that plus a parity re-check of all 28 built
screens.

Two modelling decisions in that test that look like softening it and are not:
`ink4` is not declared as a text pair, because its only sanctioned use is
disabled text which SC 1.4.3 exempts — the real gate is that nothing outside the
token layer may reach the slot; and ratios compare at two decimal places,
because `due.base` on `due.tint` measures **2.999997257573712**, the design
landing exactly on 3.0 with sRGB float error underneath it.

## Deferred

- No widget. `lib/ui/calm/` is empty; that is EPIC-03.
- The locale→type wiring follows the *requested* locale, not the resolved one
  (item 2 above). EPIC-04.
- `themeMode` has no persistence (item 3). EPIC-14.
- The font is not subsetted (item 7).
