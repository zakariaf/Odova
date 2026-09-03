# EPIC-03 — The Calm component library

| | |
|---|---|
| **Epic** | EPIC-03 — The Calm component library |
| **Depends on** | EPIC-02 |
| **Estimate** | **7 h (CC) · ~7 weeks (human)** |
| **Spec sections** | §9 Home · §10 Logging · §11 History · §12 Fuel insights and costs · §13 Settings — for the widgets those screens use, and the product rules attached to them |
| **Screens** | none — this epic builds `lib/ui/calm/` and no feature screen |

The shared rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, a screen is not done until it matches its reference, and
`SPEC.md` wins — are stated once in `epics/README.md`. They are not repeated here.

---

## Where we are now

Today the repository is at specification stage: `SPEC.md`, `design/`, `tools/`, `.claude/skills/`
and the repo gates. **There is no Flutter app** — no `pubspec.yaml`, no `lib/`, no `test/`.
`l10n.yaml` sits at the root and is inert until `pubspec.yaml` exists.

Two epics run before this one. When EPIC-03 starts:

**EPIC-01 has created the app.** `pubspec.yaml` on Flutter 3.44.6 with a committed lockfile,
`analysis_options.yaml` extending the pinned `very_good_analysis` include with `strict-casts`
and `strict-raw-types`, `lib/main.dart`, `lib/app.dart`, a `ProviderScope` composition root, and
`test/support/harness.dart` carrying the `Device` value type and the `pumpApp` extension from
`widget-golden-and-a11y-testing`. CI's Flutter lane is armed.

**EPIC-02 has built the token layer**, `lib/theme/calm/`:

- `calm_palette.dart` — the only file in the app with a colour literal.
- `calm_colors.dart`, `calm_type.dart`, `calm_space.dart`, `calm_shapes.dart`,
  `calm_motion.dart` — the five `ThemeExtension`s `CalmColors` · `CalmType` · `CalmSpace` ·
  `CalmShapes` · `CalmMotion`, each with an asserting `of(context)` and an honest `lerp`.
- `calm_status.dart` — `enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }`,
  `DueDriver`, `DueConfidence`, `CalmStatusStyle` with its `of(context, state)` / `resolve`, and
  the normative `CalmStatusMark` geometry constants. This is the **only** file allowed to switch
  over `DueState` and yield a colour.
- `calm_theme.dart` — `buildCalmTheme(Brightness)`, the two hand-authored `ColorScheme`s, and
  `splashFactory: NoSplash.splashFactory` + `highlightColor: Colors.transparent` set app-wide.
- Vazirmatn bundled as a variable TTF with `OFL.txt` registered through `LicenseRegistry`, and
  `CalmType.latin` / `CalmType.arabicScript` both attached to both `ThemeData`s.

**Deliberately still missing when this epic starts:** `lib/ui/calm/` is empty — there is not one
widget in the app. There is no `lib/l10n/` and no `AppLocalizations` (EPIC-04 owns that), so the
strings in this epic's tests and specimens are **test fixtures passed in as constructor
parameters**, never literals inside a widget. There is no `lib/features/`, no router and no
screen. Nothing renders yet.

The reference implementations this epic starts from already exist in the repo, as skill examples:

| File | Ships |
|---|---|
| `.claude/skills/calm-components/examples/calm_pressable.dart` | `CalmPressable`, `CalmTapTarget`, `CalmDirectionalIcon`, the press-scale constants, the focus-ring constants |
| `.claude/skills/calm-components/examples/calm_button.dart` | `CalmButton`, `CalmButtonExplain` |
| `.claude/skills/calm-components/examples/calm_card.dart` | `CalmSurface`, `CalmCard` and its seven variants |
| `.claude/skills/calm-components/examples/calm_rows.dart` | `CalmRowGroup`, `CalmListRow` |
| `.claude/skills/calm-components/examples/calm_field.dart` | `CalmField` |
| `.claude/skills/calm-components/examples/calm_number_pad.dart` | `CalmNumberPad`, `CalmNumberPadKey` |
| `.claude/skills/calm-components/examples/calm_tile.dart` | `CalmTile` |
| `.claude/skills/calm-due-state-and-status/examples/calm_due_card.dart` | `CalmDueCard`, `CalmDueView` |
| `.claude/skills/calm-due-state-and-status/examples/calm_status_dot.dart` | `CalmStatusDot` |
| `.claude/skills/calm-layout-and-motion/examples/calm_scaffold.dart` | `CalmScaffold`, `CalmAppBar`, `CalmTabBar` |
| `.claude/skills/calm-layout-and-motion/examples/calm_all_clear.dart` | `CalmAllClear`, `CalmEmptyState` |

Those are compilable references, not sketches. Start from them, keep the constructor signatures
in `calm-components/references/component-inventory.md` § *Constructor parameters* exactly — a
screen epic composes against that table — and write the test first anyway. **Seven widgets have
no shipped example and are authored from the reference prose**: `CalmChip`, `CalmBadge`,
`CalmSwitch`, `CalmSegmented`, `CalmStepper`, `CalmSheet`, `CalmDialog`, `CalmSnackbar`.

---

## What we will have when this is done

- `lib/ui/calm/` contains every widget in `calm-components/references/component-inventory.md`,
  and a screen epic can build a screen without inventing a `Container`.
- A **specimen app** — `example/calm_gallery.dart`, run with `flutter run -t example/calm_gallery.dart` —
  showing every widget in every state, with a theme switch and a direction switch. Someone can hold
  it beside `design/calm/system.html` in a browser and compare, which is the only review that sees
  type weight and optical alignment.
- `flutter test` is green, including the golden lane: **88 committed specimen goldens** — 22
  widgets × {light, dark} × {LTR, RTL} — each specimen stacking that widget's states in one
  column, plus the per-state geometry assertions that are the real gate.
- Six gate scripts run clean over `lib/`:
  `calm-components/scripts/check_component_hygiene.sh`,
  `calm-tokens/scripts/check_raw_values.sh`,
  `calm-design-system/scripts/check_calm_layering.sh`,
  `calm-design-system/scripts/check_calm_rejects.sh`,
  `calm-layout-and-motion/scripts/check_touch_targets.sh`,
  `calm-due-state-and-status/scripts/check_status_encoding.sh`.
- Not one `Border` in the tree outside `calm_field.dart` and `calm_pressable.dart`; not one live
  splash; not one `fontSize`, hex, radius or `Duration` literal outside `lib/theme/calm/`.

**This epic has no visual-parity gate, and that is deliberate.** `calm-visual-parity` compares a
*screen* against one of the 112 images in `design/reference/calm/`; there is no reference image
for a lone `CalmChip`. The goldens and the geometry assertions are what protect this epic, and
they protect it against regression, not against being wrong on day one. Being right on day one is
what the specimen app and the review against `design/calm/system.html` are for. Do not add a
parity test to a widget — `calm-visual-parity` names that as an anti-pattern, because a check with
nothing to compare against always passes.

---

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Dumb widgets, extracted `const` widget classes never `_buildX()` methods, the complexity limits, directional geometry, the naming rules every file here obeys. |
| `calm-components` | Owns this epic. The 22 widgets, their variants and states, the token each state reads, the hit floor, and the constructor signatures a screen will call. |
| `calm-tokens` | Every value these widgets render is a `Calm*.of(context)` slot read; this skill is the slot list and the no-raw-values gate. |
| `calm-due-state-and-status` | `CalmDueCard`, `CalmStatusDot`, `CalmBadge` and `CalmButton.onState` resolve through `CalmStatusStyle`, never a named colour slot; and the dot *shape* is normative. |
| `calm-layout-and-motion` | `CalmScaffold`, `CalmAppBar`, `CalmTabBar`, `CalmAllClear`, the fixed chrome metrics, the 52 touch floor and the reduced-motion contract. |
| `calm-typography-and-rtl` | Which of the nine type roles each widget renders, the 13px floor, tabular figures, and the six glyphs that mirror. |
| `widget-composition` | Extracting these as named `const` `StatelessWidget`s, and the layout primitives underneath. |
| `widget-golden-and-a11y-testing` | The `pumpApp` harness, the pinned device, the overflow × text-scale matrix, `getSize`-measured tap targets, `isSemantics`, and the two golden lanes. |
| `accessibility-as-code` | The `Semantics` role and enabled state every interactive widget declares, `MergeSemantics` on a composite row, and never colour alone. |
| `forms-and-input` | `CalmField`, `CalmStepper`, `CalmSegmented` and `CalmSwitch` are the skin; `Form`, validators, focus traversal and keyboard types are this skill's, and the two must not disagree. |

---

## Tasks

### Task 3.1 — Build the press primitive, the tap-target box and the directional icon

- **Goal** — every Calm widget can be pressed, focused and disabled the same way, and a 40pt
  control can be hit with a gloved thumb.
- **Spec** — §10 *Logging* (a fill-up is four taps at a pump, in the rain); §2 *Non-negotiables*
  (no hard-coded `left`/`right`).
- **Skills** — `calm-components` (`references/interaction-and-press.md`), `calm-layout-and-motion`,
  `accessibility-as-code`, `widget-golden-and-a11y-testing`.
- **Write these tests first** — `test/ui/calm/calm_pressable_test.dart`:
  - `press steps the surface ramp and scales to the widget's press scale` — pump a
    `CalmPressable(pressScale: kCalmPressScaleButton)` over `colors.surface2`, send a pointer
    down, `pump(motion.instant)`, assert the `AnimatedScale.scale` is `0.98` and the animated
    decoration colour is `CalmColors.of(context).surface3`. Fails if either channel is missing —
    both fire, because the tint is what survives reduced motion.
  - `reduced motion collapses the duration to zero, never to a shorter one` — pump under
    `MediaQuery(data: …copyWith(disableAnimations: true))`; assert `AnimatedScale.duration ==
    Duration.zero`. Fails on any non-zero duration, including a "gentler" 40ms.
  - `a 40pt child reports a 52pt hit area under expandTapTarget` —
    `tester.getSize(find.byType(CalmTapTarget))` is `Size(52, 52)` while the painted child
    measures 40. Fails if the paint grew instead of the target.
  - `a tap 5pt outside the painted box still fires onTap` — `tapAt` inside the padded ring.
    Fails if the gesture falls through.
  - `keyboard focus draws the ring outside the box and does not resize the control` —
    `getSize` before and after `focusNode.requestFocus()` are equal, and a `Border` of
    `colors.focus` at `kCalmFocusWidth` exists in the tree only while focused. Fails if focus
    changes the size by so much as 6pt, which is what an inside border would do.
  - `Enter and Space activate through ActivateIntent` — each fires `onTap` exactly once. Fails
    if a focusable widget is unusable from a keyboard.
  - `disabled absorbs the tap and reports enabled: false` — a sibling behind it never fires, and
    `getSemantics(...)` matches `isSemantics(hasEnabledState: true, isEnabled: false)`.
  - `CalmDirectionalIcon mirrors under RTL and is untouched under LTR` — the `Transform`'s
    `scaleX` is `-1` only under `Directionality(TextDirection.rtl)`.
  - `the theme kills every Material feedback channel` — `buildCalmTheme(Brightness.light)
    .splashFactory` is `NoSplash.splashFactory` and `highlightColor` is transparent. EPIC-02
    built it; this is the consumer's assertion, and it is the reason a stray Material widget is
    silent.
- **Then build** — `lib/ui/calm/calm_pressable.dart`, starting from
  `.claude/skills/calm-components/examples/calm_pressable.dart`: `CalmPressable` with the
  signature in the inventory table, `CalmTapTarget` (a `RenderShiftedBox` that lays the child out
  naturally, reports `max(child, CalmSpace.of(c).touchMin)`, centres it and hit-tests the padded
  box), `CalmDirectionalIcon`, the `calmDuration(context, full)` helper, and the constants
  `kCalmPressScaleButton` 0.98 / `kCalmPressScaleChip` 0.97 / `kCalmPressScaleKey` 0.96 /
  `kCalmPressScaleFab` 0.94, `kCalmFocusOutset` 3, `kCalmFocusWidth` 3. Use
  `FocusableActionDetector` over a `GestureDetector` — not `InkWell`, at all.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_pressable_test.dart
  bash .claude/skills/calm-components/scripts/check_component_hygiene.sh lib
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is: every test green, no `InkWell`/`InkResponse` reported, no sizing literal under 52
  outside the allowlisted paint sites.
- **Done when**
  - [ ] `CalmPressable`, `CalmTapTarget` and `CalmDirectionalIcon` exist in `lib/ui/calm/` and
        nothing else in the tree defines a press.
  - [ ] Scale **and** tint both fire; under `disableAnimations` the duration is exactly zero.
  - [ ] The focus ring is additive and drawn outside the layout box.
  - [ ] `check_component_hygiene.sh` and `check_touch_targets.sh` are clean.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 3.2 — Build `CalmSurface`, `CalmCard`, `CalmTile` and `CalmIconTile`

- **Goal** — every surface in the app is one of four widgets, with the two-layer warm shadow and
  the sheen drawn once, correctly.
- **Spec** — §9 *Home* (the cards Home stacks); §12 *Fuel insights, costs and reports* (the tile
  trio).
- **Skills** — `calm-components`, `calm-tokens`, `calm-typography-and-rtl`, `widget-composition`.
- **Write these tests first** — `test/ui/calm/calm_card_test.dart`, `test/ui/calm/calm_tile_test.dart`:
  - `a card paints surface, radius2xl and both elev1 layers` — read the `BoxDecoration`; assert
    `color == colors.surface`, radius `shapes.radius2xl`, and `boxShadow.length == 2`. Fails if
    one shadow layer was dropped, which is the difference between the specimen sheet and a flat
    rectangle.
  - `a card paints the sheen as a 1px top highlight inside a ClipRRect` — find the sheen edge and
    assert its colour is `colors.sheen` and its height is 1. Fails if `--elev-sheen` was skipped
    because `BoxShadow` cannot draw inset.
  - `no card variant carries a border` — for each of the seven variants (`standard`, `lg`, `sm`,
    `tinted`, `flat`, `raised`, `quiet`, `inverse`), assert `decoration.border == null`. This is
    the one rule the hygiene script cannot see inside a variant switch.
  - `the inverse variant keeps the ink ramp uninverted` — secondary text reads `colors.inkInverse`
    at 66%, not `ink2`. Fails if the ramp was flipped with the surface.
  - `a card with onTap presses; a card without onTap has no gesture at all` — the second half
    fails if a static card is focusable, which puts an empty stop in the keyboard traversal.
  - `CalmTile renders value at type.title semi with tabular figures and label at caption ink3` —
    assert the `TextStyle.fontFeatures` contain `tabularFigures` and `liningFigures`. Fails if a
    row of three tiles jitters when a digit changes.
  - `three CalmTiles in a Row keep equal widths and mirror their order under RTL` —
    `getRect` on each; under RTL the first tile's `left` is the largest.
  - `CalmIconTile is 44 square, reads its state ramp's tint and ink, and is excluded from semantics` —
    it is a `lead` slot, not a target.
- **Then build** — `lib/ui/calm/calm_surface.dart` (`CalmSurface`), `calm_card.dart` (`CalmCard`,
  seven variants), `calm_tile.dart` (`CalmTile`), `calm_icon_tile.dart` (`CalmIconTile`), from the
  shipped `calm_card.dart` and `calm_tile.dart` examples. `CalmSurface` is the only place the
  sheen is painted.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_card_test.dart test/ui/calm/calm_tile_test.dart
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  bash .claude/skills/calm-components/scripts/check_component_hygiene.sh lib
  ```
  A pass is: green tests, and `check_raw_values.sh` reporting no hex, radius or duration literal
  outside `lib/theme/calm/`.
- **Done when**
  - [ ] All seven `CalmCard` variants render, and none of them has a border.
  - [ ] The sheen is present on every shadowed surface.
  - [ ] `CalmTile` and `CalmIconTile` exist with the inventory's signatures.
  - [ ] `check_raw_values.sh` is clean.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.3 — Build `CalmRowGroup` and `CalmListRow`

- **Goal** — every list in the app is one grouped surface with hairlines between its rows, not a
  stripe of rattling cards.
- **Spec** — §13 *Settings* (the row groups are the whole screen); §11 *History* (the timeline
  rows); §9 *Home* (the see-all row).
- **Skills** — `calm-components`, `calm-tokens`, `accessibility-as-code`, `widget-golden-and-a11y-testing`.
- **Write these tests first** — `test/ui/calm/calm_row_group_test.dart`:
  - `a group of three rows draws one radius, one shadow and two dividers` — assert exactly two
    divider hairlines of `colors.divider`, and none above the first row or below the last. Fails
    on the classic off-by-one that puts a line under the last row.
  - `the group clips its children so the first and last rows inherit the outer radius` — a
    `ClipRRect` of `shapes.radius2xl` wraps the column.
  - `a standalone row draws radiusXl and elev1 of its own` — `CalmListRow(standalone: true)`.
  - `each row size meets its floor` — `md` 64, `lg` 76, `compact` 56, each ≥ `space.touchMin` 52,
    measured with `getSize`, at text scales 1.0 / 1.3 / 1.5 / 2.0 / 3.0 as one `testWidgets` per
    scale (never a loop inside one test — overflow reports once per `RenderObject`).
  - `lead, main and end sit start, centre and end and mirror wholesale under RTL` — `getRect`
    comparison in both directions. Only the disclosure chevron's glyph differs.
  - `showChevron mirrors the disclosure chevron and nothing else does` — the icon tile in `lead`
    has the same transform in both directions.
  - `a switchRow is one MergeSemantics node labelled by the row title` —
    `getSemantics` yields one node matching `isSemantics(label: 'Reminders', isToggled: true)`,
    not four siblings. Fails if a screen reader would read "Reminders, switch, on" as three stops.
  - `a switchRow is not navigable` — tapping the row toggles and does not call an `onTap`
    navigation callback.
  - `a lone CalmListRow outside a group is a visible defect` — a widget test asserting the
    standalone flag is required: constructing `CalmListRow` with `standalone: false` outside a
    `CalmRowGroup` throws an assertion in debug. Fails if the library lets a bare row through.
  - `disabled fades the row to 42% and still absorbs its tap`.
- **Then build** — `lib/ui/calm/calm_row_group.dart` and `lib/ui/calm/calm_list_row.dart`, from
  `.claude/skills/calm-components/examples/calm_rows.dart`. The list parameter is **`rows`**, and
  the disclosure flag is **`showChevron`** — the inventory's signature is the contract a screen
  epic composes against.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_row_group_test.dart
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib
  ```
  A pass is: green tests and no physical-side geometry reported by the i18n bans gate.
- **Done when**
  - [ ] Dividers appear between rows only.
  - [ ] Every row size measured ≥52 at every text scale in the matrix.
  - [ ] A `switchRow` is one semantics node, and it is not navigable.
  - [ ] A bare `CalmListRow` outside a group asserts in debug.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.4 — Build `CalmButton` and `CalmButtonExplain`

- **Goal** — one button widget covers every action in the app, and a disabled button always says
  why.
- **Spec** — §10 *Logging* ("a greyed-out Save tells the user nothing"; Save on the five `log.*`
  forms is never disabled); §13 *Settings*.
- **Skills** — `calm-components`, `calm-due-state-and-status`, `calm-typography-and-rtl`,
  `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_button_test.dart`:
  - `each size paints its height and every one reports a 52pt hit area` — `sm` paints 42, `md` 52,
    `lg` 60; `getSize` on the tap target is ≥52 for all three. Fails if `sm` was grown to 52
    instead of padded.
  - `primary drops its shadow while pressed and steps to brandStrong` — assert
    `boxShadow.isEmpty` during the press and the fill is `colors.brandStrong`.
  - `each variant reads its documented pair` — a table-driven test over `primary`
    (`brand`/`onBrand`), `secondary` (`brandSoft`/`brandSoftInk`), `tonal` (`surface2`/`ink`),
    `danger` (`dangerTint`/`danger`), `disabled` (`surface2`/`ink4`). Fails the moment a variant
    reads a slot the inventory does not name.
  - `onState resolves through CalmStatusStyle, not a colour slot` — build `CalmButton(dueState:
    DueState.needsOdometer)` and assert its fill equals
    `CalmStatusStyle.resolve(colors, DueState.needsOdometer).base` — **not** `colors.overdue.base`.
    This is the test that stops a new owner's eleven unknown items rendering as accusations.
  - `a disabled button without a CalmButtonExplain beneath it fails a debug assertion` — the SPEC
    §10 rule, mechanised. Fails if a screen can ship a silent grey Save.
  - `loading keeps the button's width` — `getSize` with `loading: true` equals `getSize` with
    `loading: false`; the label stays in the tree at `Opacity(0)`. Fails if the row reflows and
    moves the next control under the user's thumb.
  - `the label wraps to two lines and never ellipsises` — pump the longest German string
    (`"Sicherung & Wiederherstellung"`) at 200% text scale on `Device.compact`; assert
    `takeException()` is null **and** the painted text height spans two lines, and that no
    `TextOverflow.ellipsis` is set. The exception check alone is not enough — a clipped
    `RenderParagraph` reports nothing.
  - `a button is a Semantics button with an enabled state and a tap action`.
- **Then build** — `lib/ui/calm/calm_button.dart` from
  `.claude/skills/calm-components/examples/calm_button.dart`. **One unnamed constructor**; there is
  no `CalmButton.primary()`. `onPressed: null` is the disabled state.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_button_test.dart
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh lib
  ```
  A pass is: green tests, and the status gate reporting no `case DueState.` arm outside
  `lib/theme/calm/calm_status.dart`.
- **Done when**
  - [ ] Three sizes, eight variants, five states, all reading inventory slots.
  - [ ] `onState` goes through `CalmStatusStyle`; the status gate is clean.
  - [ ] A disabled button without an explanation is a debug assertion.
  - [ ] The German label at 200% wraps, and is asserted to fit.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.5 — Build `CalmChip`, `CalmBadge` and `CalmStatusDot`

- **Goal** — status is legible without colour, everywhere it appears.
- **Spec** — §9 *Home* (the due states); §11 *History* (the filter chip bar); §12 (the business
  badge).
- **Skills** — `calm-due-state-and-status`, `calm-components`, `calm-tokens`, `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_chip_test.dart`, `test/ui/calm/calm_status_test.dart`:
  - `a chip paints 40 and reports 52` — `getSize` on the paint box and on the tap target.
  - `a selected chip carries brand fill and semi weight and Semantics(selected: true)` — three
    signals, because the fill alone is not a 3:1 difference.
  - `the chip bar scrolls horizontally and starts at the start edge in both directions` —
    `getRect` of the first chip under LTR and RTL.
  - `each of the eleven badge kinds reads exactly one (tint, ink) pair off its ramp` — a
    table-driven test over `overdue` … `count`. Fails if any badge reads `colors.<state>.base`.
  - `the six status dots have six distinct silhouettes` — assert the shape descriptor per state:
    filled ● `overdue`, ring ◉ `due`, small ● `dueSoon`, filled ● `ok`, 2px outline at 70%
    `unknown`, hollow ◌ `needsOdometer`; and assert the 12pt/8pt diameters and the 3px/2px ring
    strokes come from `CalmStatusMark`, not a local literal.
  - `a grayscale render still separates unknown from overdue` — port
    `.claude/skills/calm-due-state-and-status/examples/status_grayscale_test.dart`; it asserts the
    luminance-only rendering keeps the six distinguishable. Fails whenever someone "simplifies"
    two dots to the same silhouette.
  - `CalmStatusDot takes a resolved CalmStatusStyle, not a DueState` — a compile-level contract,
    asserted by the signature test; and the dot is wrapped in `ExcludeSemantics`, because the
    wording carries the meaning.
- **Then build** — `lib/ui/calm/calm_chip.dart`, `lib/ui/calm/calm_badge.dart`,
  `lib/ui/calm/calm_status_dot.dart` (the last from
  `.claude/skills/calm-due-state-and-status/examples/calm_status_dot.dart`). `CalmChip` and
  `CalmBadge` have no shipped example — author them from the inventory rows and
  `references/redundant-encoding.md`.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_chip_test.dart test/ui/calm/calm_status_test.dart
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh lib
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  ```
- **Done when**
  - [ ] Chip hit area 52 with a 40pt paint; selection carries three signals.
  - [ ] Eleven badge kinds, each on one ramp pair.
  - [ ] Six visually distinct dot silhouettes, proven in grayscale.
  - [ ] No widget outside `calm_status.dart` switches on `DueState`.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.6 — Build the input kit: `CalmField`, `CalmStepper`, `CalmSegmented`, `CalmSwitch`

- **Goal** — the five `log.*` forms and the Settings screens have inputs whose four states are
  unambiguous and whose labels survive German at 200%.
- **Spec** — §10 *Logging* (validation on blur and on Save, never on keystroke; the computed `ƒ`
  third of the price trio; the tappable unit affix); §13 *Settings* (§*Units & formats*).
- **Skills** — `calm-components` (`references/forms-and-fields.md`), `forms-and-input`,
  `calm-typography-and-rtl`, `accessibility-as-code`, `widget-golden-and-a11y-testing`.
- **Write these tests first** — `test/ui/calm/calm_field_test.dart`,
  `test/ui/calm/calm_input_kit_test.dart`:
  - `the field's three (ring, fill) pairs are exactly rest, focus and error` — a table-driven test:
    rest `(transparent, surface2, 1.5)`, focus `(brand, surface, 2.0)`, error
    `(overdue.base, overdue.tint, 2.0)`. Fails if a fourth combination appeared.
  - `gaining focus does not change the field's height` — `getSize` before and after; the
    transparent 1.5 rest ring exists precisely so the box does not move by 4pt.
  - `error text is overdue.ink, not danger` — Calm's error voice is the overdue terracotta;
    `danger` is reserved for destructive actions.
  - `the error replaces the hint in the same slot, and there is only ever one helper line`.
  - `the field, its label, its hint and its error are one semantics node` — `getSemantics` yields
    one node whose `label` is the field label and whose `value` carries the error. Fails if a
    blind user would never hear the error.
  - `the computed state reads bgSunk plus ink2 plus the ƒ badge and stays editable` — three
    signals, never colour alone; typing into it still fires `onChanged`.
  - `the affix sits on the end edge in both directions` — `getRect` under LTR and RTL; the field
    reserves 76pt of end padding for it and 56pt of start padding for `lead`.
  - `nothing in the field is a fixed height` — at 200% text scale the box grows and the label
    above it wraps; `takeException()` is null **and** a `getRect` fit assertion places the label
    inside its cell. No `FittedBox`, no `ellipsis`, no `withClampedTextScaling`.
  - `CalmStepper's buttons paint 48 and report 52; the − + order mirrors and the glyphs do not`.
  - `CalmSwitch paints 56×34, reports a 52pt tall target, and its thumb travels toward the end edge in both directions`.
  - `CalmSegmented marks selection with the raised pill AND semi weight AND Semantics(selected: true)` —
    `surface` on `surface2` is 1.16:1, so the pill alone is not a signal.
  - `each option paints 46 and reports 52`.
- **Then build** — `lib/ui/calm/calm_field.dart` (from the shipped example — one of only two files
  in the tree allowed to construct a `Border`), plus `calm_stepper.dart`, `calm_segmented.dart`,
  `calm_switch.dart`, authored from `references/forms-and-fields.md`. Neutralise
  `InputDecoration` completely (`border: InputBorder.none`, `isDense: true`,
  `contentPadding: EdgeInsets.zero`, `filled: false`) and let the wrapper own fill, radius,
  padding and ring.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_field_test.dart test/ui/calm/calm_input_kit_test.dart
  bash .claude/skills/calm-components/scripts/check_component_hygiene.sh lib
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh lib
  ```
  A pass is: green tests, and the hygiene gate confirming `calm_field.dart` and
  `calm_pressable.dart` are the only files with a `Border`.
- **Done when**
  - [ ] Four field states, three ring/fill pairs, one stable height.
  - [ ] Field + label + hint + error is one semantics node.
  - [ ] Stepper, switch and segmented each paint their design size and report ≥52.
  - [ ] Selection in `CalmSegmented` carries three signals.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 3.7 — Build the chrome: `CalmScaffold`, `CalmAppBar`, `CalmTabBar`

- **Goal** — every screen in the app sits in the same frame, with the `+` where the thumb is.
- **Spec** — §7 *Screen map and navigation* (the four tabs and the central `+`); §9 *Home* (the
  vehicle chevron exists only with ≥2 vehicles); §10 *Logging* (the modal head: Cancel · title · Save).
- **Skills** — `calm-layout-and-motion`, `calm-components` (`references/overlays-and-chrome.md`),
  `adaptive-layout`, `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_chrome_test.dart`:
  - `the scaffold pads its body by screenPad inline and mirrors` — `getRect` of the body under
    both directions; 22pt on the start edge each time.
  - `the scaffold pads for the keyboard with viewInsetsOf` — pump with a bottom `viewInsets` of
    320 and assert the footer rides above it. Fails if the pinned primary action ends up under the
    keyboard, which SPEC §10 forbids.
  - `the app bar is bg, draws no shadow and no bottom hairline` — it is part of the page, not a
    card.
  - `the four app-bar shapes render` — default 56, `large` (titleLg + optional caption subtitle),
    `vehicle` (title and chevron are **one** 52pt target), `modal` (a 1fr auto 1fr grid).
  - `the vehicle chevron and its target exist only when a chevron callback is given` — with one
    vehicle it is plain text and the garage is invisible until it is real (§9).
  - `the tab bar is 62 tall with five equal slots and a top divider hairline only`.
  - `the active tab is brand AND semi weight` — colour and weight, so it survives grayscale.
  - `the + is 62pt, offset −18, and presses to 0.94` — and its hit area is ≥52 even where it
    overhangs.
  - `tab slot order mirrors under RTL and the + stays centre` — `getRect` per slot.
  - `every chrome button reports ≥52` — a `getSize` loop across leading, actions and tab items,
    at every scale in the matrix.
- **Then build** — `lib/ui/calm/calm_scaffold.dart` (`CalmScaffold`, `CalmAppBar`, `CalmTabBar`)
  from `.claude/skills/calm-layout-and-motion/examples/calm_scaffold.dart`. The body parameter is
  **`children`**, a list the scaffold scrolls and spaces — there is no `body`. `CalmTabBar` takes
  exactly four `labels` plus the `+`. Do **not** use `Scaffold.appBar`: `CalmAppBar` is an
  ordinary widget in a `Column`, because `large` and `vehicle` are two lines tall.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_chrome_test.dart
  bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh lib
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  ```
- **Done when**
  - [ ] Four app-bar shapes; the vehicle target is one pill.
  - [ ] Tab bar 62 tall, `+` 62 at −18, order mirrors, `+` stays centre.
  - [ ] Keyboard insets read through `viewInsetsOf`.
  - [ ] The layering gate confirms no feature-level Material chrome.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.8 — Build the overlays: `CalmSheet`, `CalmDialog`, `CalmSnackbar`

- **Goal** — the app's three ways of interrupting someone all behave the same, and Undo is always
  reachable.
- **Spec** — §10 *Logging* (confirmation is a snackbar with Undo, never a dialog; a dialog exists
  for discarding a dirty form, confirming a delete that names what dies, and deleting a vehicle);
  §11 *History*; §13 *Settings* (`settings.import` is a blocking modal).
- **Skills** — `calm-components` (`references/overlays-and-chrome.md`), `calm-layout-and-motion`,
  `ui-states-and-feedback`, `motion-and-haptics`, `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_overlays_test.dart`:
  - `the sheet rounds its top two corners logically` — assert `BorderRadiusDirectional.only(topStart:, topEnd:)`
    and that no `topLeft`/`topRight` appears in the file. The RTL gate greps for the physical form.
  - `the sheet enters with a 24pt rise and a fade from 0.6 over motion.sheet` — 420ms with
    `easeStandard`, the slowest motion in the system.
  - `the sheet exits over motion.base with easeIn` — exits are not symmetric; `--ease-in` is
    declared in `odova.css` and this is the slot it exists for.
  - `the scrim and the surface end on the same frame` — otherwise the scrim flashes over an empty
    screen.
  - `every overlay animation collapses to zero under disableAnimations` — the sheet appears, it
    does not slide. Fails on a shorter duration.
  - `CalmSheet.show pins isScrollControlled, a transparent background, the barrier colour and useSafeArea` —
    none of those is a decision a feature re-makes.
  - `dialog actions are stacked, full-width and ≥52, destructive first and Cancel last`.
  - `dialog text is start-aligned, not centred` — centred body copy is unreadable at Sorani line
    lengths.
  - `the snackbar sits tabbarH + homebarH + s3 above the bottom edge` — `getRect`; it must never
    cover the `+`.
  - `the snackbar action renders inkInverse semi, not brand` — the known contrast defect: brand on
    `surfaceInverse` is 2.28:1 light / 1.85:1 dark. Fails if someone "fixes" it back to brand.
  - `only one snackbar shows at a time and it routes through ScaffoldMessenger` — a second call
    replaces the first and the first's Undo does not linger.
- **Then build** — `lib/ui/calm/calm_sheet.dart`, `calm_dialog.dart`, `calm_snackbar.dart`. No
  shipped example — author from `references/overlays-and-chrome.md`. Provide `CalmSheet.show<T>()`
  as the call site, never a bare `showModalBottomSheet`.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_overlays_test.dart
  bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh lib
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib
  ```
  A pass is: green tests, and the bans gate reporting no `BorderRadius.only(topLeft:` anywhere.
- **Done when**
  - [ ] Sheet, dialog and snackbar exist with their documented entry and exit motion.
  - [ ] All four durations collapse to `Duration.zero` under reduced motion.
  - [ ] The snackbar clears the tab bar and always carries its action.
  - [ ] No physical corner names in the tree.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.9 — Build `CalmNumberPad` and `CalmNumberPadKey`

- **Goal** — an odometer reading can be entered one-handed, at a pump, in the rain, in the user's
  own digits.
- **Spec** — §10 *Logging* → `log.odometer` and the fill-up odometer field; §1 (the odometer is the
  number that keeps every projection honest).
- **Skills** — `calm-components` (`references/overlays-and-chrome.md`), `calm-typography-and-rtl`,
  `forms-and-input`, `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_number_pad_test.dart`:
  - `keys are 68pt in a 3-column grid with s3 gutters, and every key reports ≥52` — `getSize` per
    key.
  - `the confirm key spans two columns and reads brand/onBrand` — `getRect` width is two columns
    plus one gutter.
  - `a key press steps to surface3, scales 0.96 and drops its shadow over motion.instant`.
  - `the grid does not mirror` — under RTL, the `1` key is still at the start of the visual first
    row in the same physical position as under LTR; assert the key `getRect` list is identical in
    both directions. A mirrored keypad is a wrong keypad.
  - `only the backspace glyph flips` — the one directional icon on the pad.
  - `the display renders the value at type.display with tabular lining figures` — 46/1.04 semi,
    tight tracking, on `surface2` at `radius2xl`.
  - `the pad plus its display fit the bottom two-thirds of a 375×667 screen with the value visible` —
    pin `Device.compact` and assert with `getRect` that the display's top is above the fold. Fails
    if a key size crept up and pushed the value off screen.
  - `every label the pad renders arrives as a constructor parameter` — `confirmLabel`,
    `decimalLabel`, `secondaryLabel`, `backspaceSemanticLabel`, `unit`, `hint`. No string literal
    inside the widget; EPIC-04 supplies the ARB values later.
  - `backspace exposes its accessible name` — from `backspaceSemanticLabel`.
- **Then build** — `lib/ui/calm/calm_number_pad.dart` from
  `.claude/skills/calm-components/examples/calm_number_pad.dart`. The **digits themselves** are
  rendered from whatever string the caller passes; the numbering-system mapping is EPIC-04's, and
  this widget must not do arithmetic on them.
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_number_pad_test.dart
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh lib
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  ```
- **Done when**
  - [ ] 68pt keys, a two-column confirm, the documented press.
  - [ ] The grid is byte-identical in geometry under both directions; only backspace flips.
  - [ ] Everything fits above the fold on `Device.compact`.
  - [ ] Every string is a parameter.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.10 — Build the answer surfaces: `CalmDueCard`, `CalmAllClear`, `CalmEmptyState`

- **Goal** — Home can say "here is what needs doing", "nothing needs doing", or "you have not added
  anything yet", and the second of those is the best-looking screen in the app.
- **Spec** — §9 *Home* (the primary card, the secondary cards, the all-clear state); §3 *The due
  engine* (the six states, the confidence rungs); §1 (the app would rather show a dash than a
  plausible lie).
- **Skills** — `calm-due-state-and-status`, `calm-layout-and-motion`
  (`references/the-all-clear-state.md`), `calm-components`, `calm-typography-and-rtl`,
  `accessibility-as-code`.
- **Write these tests first** — `test/ui/calm/calm_due_card_test.dart`,
  `test/ui/calm/calm_all_clear_test.dart`:
  - `the primary density is radius3xl with a tint→surface gradient on elev2; the secondary is 72 tall at radiusXl` —
    `getSize` and the decoration.
  - `all six DueStates render, each resolving through CalmStatusStyle` — a table-driven test;
    assert the fill equals `CalmStatusStyle.resolve(colors, state).tint` for each. Fails the moment
    `needsOdometer` borrows terracotta.
  - `every card renders dot AND word AND copy pattern` — three signals; find the mark, the status
    line and the label for each state.
  - `DueConfidence.defaulted renders no date and no figure` — the card carries the
    not-knowing sentence and its action label becomes the update-odometer one. Both arrive as
    constructor strings on `CalmDueView`; the widget contains no sentence of its own. (The ICU
    message `home.dueSoonNoConfidence` is EPIC-04's; the status gate greps `lib/` for the English
    sentence as a Dart literal, so it must not appear here.)
  - `an estimated figure keeps its ~ inside the visible title string` — `CalmListRow` and
    `CalmDueCard` have no estimate flag by design; the `~` lives in the formatted string so it
    survives a grayscale golden.
  - `a snoozed item keeps its state and its colour and gains a fourth line` — snoozing suppresses
    the notification, not the truth.
  - `the progress fill animates its width over motion.slow with easeStandard and fills toward the end edge` —
    under RTL it fills right to left.
  - `CalmAllClear renders the ok radial wash, a 92pt mark with a 12pt halo, and the since block as surface2/radiusXl` —
    and it takes `headline`, `nextLine`, optional `fuzzLine` and an optional
    `CalmSinceLine{label, figure}`, never a pre-joined sentence.
  - `CalmAllClear is not CalmEmptyState` — a test asserting the two are distinct widgets with
    distinct art. The all-clear is the most common state in the product (§9) and must never render
    as a grey icon in a box.
  - `CalmEmptyState renders icon, title, body capped at 28ch and a centred ≥52 action`.
- **Then build** — `lib/ui/calm/calm_due_card.dart` (from
  `.claude/skills/calm-due-state-and-status/examples/calm_due_card.dart`, taking a `CalmDueView`
  and a `CalmDueDensity` — not named constructors and not loose strings), and
  `lib/ui/calm/calm_all_clear.dart` (`CalmAllClear`, `CalmEmptyState`, from
  `.claude/skills/calm-layout-and-motion/examples/calm_all_clear.dart`).
- **Verify**
  ```bash
  flutter test test/ui/calm/calm_due_card_test.dart test/ui/calm/calm_all_clear_test.dart
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh lib
  ```
  A pass is: green tests, and the status gate reporting no direct state-slot read and no
  uncertainty sentence built in Dart.
- **Done when**
  - [ ] Six states × two densities render, all through `CalmStatusStyle`.
  - [ ] `defaulted` confidence shows no date and no figure.
  - [ ] `CalmAllClear` exists as its own surface, distinct from `CalmEmptyState`.
  - [ ] The status-encoding gate is clean.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 3.11 — Build the specimen gallery, the golden matrix and the accessibility floor

- **Goal** — every widget's every state is visible in one place, committed as a golden, and
  measured against the accessibility floor.
- **Spec** — §17 *Definition of done for v1* → *Accessibility gate* (48×48 minimum everywhere,
  visible focus indicator, full keyboard traversal) and *Per-locale gate* (zero glyph clipping at
  200% text scale).
- **Skills** — `widget-golden-and-a11y-testing`, `accessibility-as-code`, `calm-tokens`
  (`references/contrast-audit.md`), `calm-typography-and-rtl`, `testing-strategy`.
- **Write these tests first**
  - `test/ui/calm/goldens/calm_specimens_test.dart`, tagged `@Tags(['golden'])`, `setUpAll(loadAppFonts)`:
    one `testWidgets` per (widget, theme, direction) — 22 × 2 × 2 = 88 — each pumping that widget's
    states stacked in one column and calling
    `matchesGoldenFile('goldens/<widget>-<theme>-<dir>.png')`. RTL specimens pump under
    `Directionality(TextDirection.rtl)` with Persian fixture strings and Extended Arabic-Indic
    digit fixtures, so glyph joining and the `۰۱۲۳` block are actually exercised. Fails on any
    unblessed change; **cannot** fail on a widget that was wrong the day it was written, which is
    why the gallery review below is in the Done-when list too.
  - `test/ui/calm/calm_touch_targets_test.dart` — `every interactive Calm widget reports ≥52 in
    both dimensions`: a `getSize` loop over the gallery, one `testWidgets` per text scale in
    `[1.0, 1.3, 1.5, 2.0, 3.0]`, never a loop inside one test. `meetsGuideline` is advisory only,
    and always via `await expectLater` — it skips every node flush with the view edge.
  - `test/ui/calm/calm_overflow_matrix_test.dart` — `Device.all × [1.0, 1.3, 1.5, 2.0, 3.0] ×
    [false, true] bold`, one `testWidgets` per tuple over the gallery: `takeException()` is null
    **and** a `getRect` fit assertion places each label inside its computed cell. The fit
    assertion is the real gate; a clipped `RenderParagraph` reports nothing.
  - `test/ui/calm/calm_contrast_test.dart` — pure-Dart WCAG **and** APCA over the token values
    each widget reads, looped over both themes: every ink-on-tint pair used by a badge, a due card
    or a status line clears 4.5:1, and the anchor line reads `ink2` not `ink3` (`ink3` at 13px
    measures 3.02–3.99:1 in light). Never `meetsGuideline(textContrastGuideline)` — it screenshots
    and histograms, and white on `#FAFAFA` passes it.
  - `test/ui/calm/calm_traversal_test.dart` — `every focusable widget is reachable by keyboard and
    draws a visible ring`, and `traversal order follows layout order in both directions`.
- **Then build** — `example/calm_gallery.dart` (the runnable specimen app, with a theme toggle and
  a direction toggle), `test/ui/calm/support/specimens.dart` (the one list of widget × state
  builders both the gallery and the golden test read, so a new state cannot be added to one and
  not the other), and the committed goldens under `test/ui/calm/goldens/`. Wire the golden lane
  and the six gate scripts into CI, and block `--update-goldens` there.
- **Verify**
  ```bash
  flutter test
  flutter test --tags golden
  bash .claude/skills/calm-components/scripts/check_component_hygiene.sh lib
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh lib
  bash .claude/skills/calm-design-system/scripts/check_calm_layering.sh lib
  bash .claude/skills/calm-design-system/scripts/check_calm_rejects.sh lib
  bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh lib test
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh lib
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh lib
  flutter run -t example/calm_gallery.dart      # then open design/calm/system.html beside it
  ```
  A pass is: `flutter test` green, 88 goldens matched, all seven scripts silent, and the gallery
  reviewed against `design/calm/system.html` in a browser at both themes and both directions.
- **Done when**
  - [ ] `example/calm_gallery.dart` runs and shows every widget in every state.
  - [ ] 88 specimen goldens are committed and green; both lanes call `loadAppFonts()`; CI blocks
        `--update-goldens`.
  - [ ] Every interactive widget measured ≥52 at every scale, by `getSize`, not by eye.
  - [ ] The overflow × scale × bold matrix is green **and** backed by fit assertions.
  - [ ] Contrast asserted in pure Dart over token values, in both themes.
  - [ ] The gallery has been opened beside `design/calm/system.html` by a human and the
        differences the tests cannot see — type weight, icon shape, optical alignment — are either
        fixed or filed as findings against the design.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] Every widget in `calm-components/references/component-inventory.md` exists in `lib/ui/calm/`
      with the constructor signature that table gives it.
- [ ] Every widget renders rest, pressed, disabled and — where it applies — focus and error, in
      light **and** dark, LTR **and** RTL.
- [ ] Presses go through `CalmPressable`; no `InkWell`, no live splash, no Material substitute.
- [ ] No `CalmCard`, `CalmRowGroup`, `CalmTile` or `CalmSheet` draws a border; the only `Border`s
      in the tree are the field ring and the focus ring.
- [ ] Rows appear only inside a `CalmRowGroup` or as `CalmListRow.standalone`.
- [ ] Every disabled `CalmButton` is accompanied by a `CalmButtonExplain`.
- [ ] Every state-tinted widget resolves through `CalmStatusStyle`; a grayscale specimen still
      tells `unknown` from `overdue`.
- [ ] Every tappable widget has a ≥52pt hit area, asserted by `getSize`.
- [ ] All seven gate scripts listed in Task 3.11 are clean over `lib/`.
- [ ] The specimen gallery has been reviewed against `design/calm/system.html` by a human, in both
      themes and both directions.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

This epic builds no screen, so it carries no `calm-visual-parity` line. The first screen epic
inherits that gate, and inherits these widgets with it.

---

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-03.md`.** It starts empty.
Append one line per task as it completes — what was built, what was deferred, and anything the
next epic needs to know. It is the running log for this epic and the handover to the next one.
