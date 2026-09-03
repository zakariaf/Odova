# EPIC-17 — Accessibility, text scale and screen readers

| | |
|---|---|
| **Epic** | EPIC-17 — Accessibility, text scale and screen readers |
| **Depends on** | EPIC-08, EPIC-10, EPIC-11 |
| **Estimate** | **14 h (CC) · ~3 months (human)** over 10 tasks |
| **Spec sections** | §17 Definition of done → Accessibility gate (the release blocker) · §17 → Per-locale gate · §14 Edge cases → Language and input |
| **Screens** | all 28, as a sweep: `home` · `history` · `costs` · `costs.fuel` · `report.service` · `reminders.list` · `reminders.edit` · `log.fillup` · `log.service` · `log.expense` · `log.odometer` · `trips.list` · `trips.edit` · `vehicles` · `vehicle.edit` · `vehicle.switcher` · `settings` · `settings.language` · `settings.units` · `settings.notifications` · `settings.backup` · `settings.import` · `settings.about` · `firstrun.language` · `firstrun.vehicle` · `dialog.discard` · `dialog.confirmDelete` · `dialog.snooze` |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

`SPEC.md` §17 calls accessibility "currently the weakest area of this spec and treated as a
release blocker, not a polish item". This is the epic where that gate is actually met. It
is not a final-week tidy-up and it is not a sweep of `Semantics` widgets over a finished
app: it changes real widgets on real screens, so every task that touches a screen carries
a parity gate, and the epic ends with the live contrast finding in
`design/calm/ACCESSIBILITY-FINDING.md` either fixed or formally accepted in writing.

---

## Where we are now

EPIC-01 created the Flutter app; before it there was no `pubspec.yaml` and no `lib/`. By
the time this epic starts, all 28 screens exist and match their references in
`design/reference/calm/`, the six locales render, and the app is usable. What it is not,
yet, is accessible — not because anyone was careless, but because the screens were built
against reference PNGs shot at 100% text scale in one theme pair, and a PNG cannot show a
missing `Semantics` label or a `Row` that overflows at 200%.

What this epic requires from its predecessors, by capability:

| From | What must exist before Task 17.1 |
|---|---|
| EPIC-10 | `home` complete: due cards through `CalmStatusStyle`, the odometer strip with its `~` estimates, `CalmAllClear`, the reminder surfaces. This is the screen the accessibility gate is mostly about. |
| EPIC-11 | The four log modals — `log.fillup`, `log.service`, `log.expense`, `log.odometer` — with their forms, the `ƒ` computed badge on the fill-up price trio, and the bottom-anchored Save. |
| Earlier still | `lib/theme/calm/` with the five `ThemeExtension`s and the no-raw-values gate; `lib/ui/calm/` with the component library; six ARB files through `gen_l10n`; `test/support/harness.dart` with `pumpApp` pinning `physicalSize` and `devicePixelRatio`; `test/parity/` with the four-combination capture tests and `design/reference/_parity/` sheets. |

What genuinely does not exist today, and is this epic's work:

- No contrast assertion of any kind. `design/calm/ACCESSIBILITY-FINDING.md` documents two
  **live WCAG failures in the light theme** — `--color-ink-3` `#8B7B6C` at 3.02–3.99:1
  across four surfaces, used as `color:` in 47 CSS rules, and `--color-ink-4` `#AC9C8B` on
  placeholders at 2.39:1 — and nothing in the repo will go red about either.
- No text-scale matrix. `pumpApp` can layer a `textScaler`; nothing walks
  6 locales × 100%/200% × bold on/off over every screen.
- No traversal-order assertions, no touch-target assertions, no colour-blind pass, and no
  non-visual alternative for either chart.

Deliberately still missing when this epic ends: the six-locale screenshot goldens signed
off by native fa and ar readers (§17 per-locale gate), and the on-device TalkBack /
VoiceOver / Switch Access passes. Both are human work that `design-review-workflow` owns.
This epic makes them cheap and short; it cannot do them.

## What we will have when this is done

- Turn the system text size to its maximum on an Android phone in German, open every one of
  the 28 screens, and nothing is clipped, truncated, shrunk or overlapping. Do the same in
  Sorani and Persian, right to left, and the same is true.
- Turn on TalkBack and walk `home`: it reads *"about 187,400 kilometres, estimated"*, not
  *"tilde 187400"*; it reads *"Oil and filter, overdue, was due at 186,512 kilometres"*,
  not *"card, button"*; the not-knowing card reads *"Odova needs a reading to say when"*
  and offers one action.
- `flutter test test/a11y/` is green, and it is the thing that goes red when someone adds an
  unlabelled `Icon`, a `FittedBox`, a `TextOverflow.ellipsis` on a real label, or a colour
  pair that fails AA. The contrast test walks a declared table of foreground/background
  pairs, so a token change fails the build rather than the review.
- `design/calm/ACCESSIBILITY-FINDING.md` ends with a dated resolution line: either the two
  token values changed and the calm reference set was re-shot in the same PR, or a named
  person accepted the failure in writing with the reason. It is not carried past this epic.
- Both charts on `costs` and `costs.fuel` have a screen-reader summary and an accessible
  data table behind one control, and `report.service` reads as a document rather than as a
  grid of unlabelled cells.
- Every screen still matches its reference in all four combinations — this epic changes
  semantics and flexibility, not the design.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door, and rule 12: RTL and a11y by construction, never clamped, never colour-only. |
| `accessibility-as-code` | The authoring discipline this whole epic applies — semantics on every node, no clamping, redundant encoding, contrast against the composited background, 44px targets, authored traversal. |
| `widget-golden-and-a11y-testing` | The verification half: the `pumpApp` harness, the overflow net that never suppresses, computed geometry over blessed pixels, `isSemantics`, `simulatedAccessibilityTraversal`, and the honest limits of `meetsGuideline`. |
| `calm-visual-parity` | Every task here changes a referenced screen. Parity is what proves the accessibility work did not quietly redesign anything, and it is what re-gates the set if the contrast finding is fixed. |
| `calm-tokens` | The contrast table is written against the token slots, and a fix to `--color-ink-3` is a token change under the no-raw-values gate — not a widget-local colour. |
| `calm-due-state-and-status` | The six `DueState` members, their marks, labels and copy patterns. Its redundant-encoding rules are precisely what the colour-blind pass is designed to survive. |
| `calm-typography-and-rtl` | The 13px floor, the nine-step scale, why German and Sorani are the worst cases at 200%, and the six glyphs that mirror. |
| `i18n-rtl-l10n` | Every announcement is an ARB key with ICU plurals; focus order in RTL; `Directional`-only geometry; FSI/PDI isolation so a Latin workshop name inside a Persian screen is read correctly. |
| `calm-components` | The `ƒ` badge, the segmented control the chart table hides behind, and the 52 pt hit floor all live in `lib/ui/calm/` — the fixes land once, in the component, not per screen. |
| `adaptive-layout` | At 200% the fold guarantee is void and rows reflow; branch on the constraints you are given, never on the device. |
| `ci-pipeline-and-gates` | The last task turns the §17 gate into a required job, and states honestly what CI cannot prove. |
| `design-review-workflow` | The end-of-build human sweep this epic hands off to, and its rule that every accessibility-floor violation is a BLOCKER. |

---

## Tasks

### Task 17.1 — The accessibility test lane

- **Goal** — the repo gains a way to fail a build for an accessibility defect, before any
  defect is fixed.
- **Spec** — §17 Accessibility gate; §17 Per-locale gate (the 200% and longest-string rows).
- **Skills** — `widget-golden-and-a11y-testing`, `accessibility-as-code`, `i18n-rtl-l10n`
  (the matrix is six locales, not one).
- **Write these tests first** — `test/a11y/harness_selftest_test.dart`, which tests the
  harness itself, because a harness that silently swallows is worse than none:
  - `pumpA11y pins textScaler, boldText and accessibleNavigation from the tuple it is given`
  - `an overflow at TextScaler.linear(2.0) fails the test` — a deliberately fixed-height
    `SizedBox(height: 20)` around a `Text` must produce a red failure, not a warning.
  - `takeException and ignoreOverflowErrors are absent from the harness` — a source grep,
    because the one-line "fix" for a red overflow is to suppress it.
  - `the matrix enumerates 6 locales x 2 scales x 2 bold states` — 24 tuples, named, so a
    dropped locale is visible in the test name rather than in a count.
  - `an unlabelled Icon fails the semantics sweep` — a fixture widget with a bare
    `Icon(Icons.star)` is reported with its widget path.
  - `withClampedTextScaling and textScaleFactor appear nowhere under lib/` — the ban from
    `accessibility-as-code`, as a policy test with the offending paths in the message.
  - `FittedBox and TextOverflow.ellipsis appear on no user-facing label` — allowlisted only
    where the allowlist entry names a reason.
- **Then build** — `test/support/a11y_harness.dart` (`pumpA11y`, `a11yMatrix`,
  `expectNoOverflow`, `expectLabelled`) layered on the existing `pumpApp`, and
  `test/policy/a11y_bans_test.dart`. One `testWidgets` per tuple — overflow reports once
  per `RenderObject`, so a loop inside one test hides every failure after the first.
- **Verify**
  ```bash
  flutter test test/a11y/harness_selftest_test.dart test/policy/
  bash .claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh
  ```
  The self-test's deliberate-overflow case must be seen to fail when its guard is removed —
  run it once inverted, then restore it. A gate nobody has watched go red is not a gate.
- **Done when**
  - [ ] The harness is proven to fail on an overflow, an unlabelled icon and a clamp.
  - [ ] The 24-tuple matrix is enumerated, not counted.
  - [ ] No suppression helper exists anywhere in `test/`.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 17.2 — Contrast as unit tests, and closing the live finding

- **Goal** — every foreground/background pair the design declares is asserted against AA in
  both themes, and the two known light-theme failures stop being a document.
- **Spec** — §17 Accessibility gate ("lighter text still meets 4.5:1 contrast"); §9 Home
  (the estimated treatment); the live finding in `design/calm/ACCESSIBILITY-FINDING.md`.
- **Skills** — `calm-tokens`, `accessibility-as-code`, `widget-golden-and-a11y-testing`
  (pure-Dart WCAG on colour values), `calm-due-state-and-status`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/contrast_test.dart`, walking a declared table
  rather than a hand-written list of `expect`s:
  - `every declared body pair clears 4.5:1 in light` and `... in dark`
  - `every declared large or hero pair clears 3:1 in both themes`
  - `ink3 on bg, surface, surface-2 and surface-3 clears 4.5:1` — **red on the first run**
    at 3.67 / 3.99 / 3.42 / 3.02. This is failure 1 from the finding, made executable.
  - `the placeholder ink clears 4.5:1 on surface and on bg` — **red on the first run** at
    2.60 and 2.39. Failure 2.
  - `every CalmRamp ink clears 4.5:1 on its own tint, for all six DueState members, in both
    themes`
  - `the anchor line's ink2 clears 4.5:1 on every state tint` — 6.37:1 light / 6.61:1 dark
    per `calm-due-state-and-status` rule 10; the test pins it so a "tidy" back to ink3 fails.
  - `the estimated text treatment clears 4.5:1` — §17 states it as a fact; this makes it one.
  - `no pair in the table is declared against a gradient or a translucent fill`
  - `the table covers every ThemeExtension colour slot that is ever used as a foreground` —
    a completeness assertion, so adding a slot without a pair fails.
- **Then build** — `lib/theme/calm/calm_contrast_pairs.dart`: a `const` list of
  `ContrastPair { foreground slot, background slot, TextRole role }` declared once, next to
  the tokens, so the test and the theme cannot disagree. Then resolve the finding, one of
  two ways, and write which one into the finding file with a date and a name:
  1. **Fix** — `--color-ink-3` → `#6B5F53` (the only candidate in the finding that clears
     all four surfaces; `#7E6E5F` fails `--color-surface-3` at 3.63) and point
     `.input::placeholder` / `.textarea::placeholder` at the corrected `--color-ink-3`.
     Then mirror both into `lib/theme/calm/`, rebuild `design/calm/screens.html`, **re-shoot
     and re-optimise the calm reference set in this same PR**, and say in the PR what
     changed and why. `calm-visual-parity` rule 7 — a reference set that lags the design is
     worse than none.
  2. **Accept** — a named person records that Calm's softness is worth the failure, the
     failing pairs are marked `@Skip` with that decision quoted in the skip reason, and the
     acceptance is copied into `epics/progress/EPIC-17.md`. Silence is not an option.
- **Verify**
  ```bash
  flutter test test/a11y/contrast_test.dart
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh
  # if the tokens changed, the whole reference set moved — re-capture and re-gate:
  flutter test test/parity/
  node tools/compare_to_reference.mjs build/parity/home-light-ltr.png home \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-light-ltr.png    # look at the side-by-side
  ```
  A pass is: contrast green, no raw colour outside `lib/theme/calm/`, and — if the tokens
  moved — every screen in `design/reference/calm/` still passing against the **re-shot**
  references.
- **Done when**
  - [ ] The contrast table exists, is complete, and is the only place a pair is declared.
  - [ ] Both failures in `design/calm/ACCESSIBILITY-FINDING.md` are fixed or accepted in
        writing, with a date and a name, in that file.
  - [ ] If fixed, `design/calm/odova.css`, `screens.html` and the calm reference set moved
        together in one PR — no widened tolerance anywhere.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 17.3 — Semantics that read the meaning: Home and the vehicle surfaces

- **Goal** — a screen-reader user hears what the car needs, not what widgets are on screen.
- **Spec** — §9 Home; §17 Accessibility gate (the estimated-value and screen-reader-language
  rows); §8 First run, the garage, and vehicles.
- **Skills** — `accessibility-as-code`, `calm-due-state-and-status`, `i18n-rtl-l10n`,
  `widget-golden-and-a11y-testing`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/home_semantics_test.dart`:
  - `an estimated odometer is announced as "about 187,400 kilometres, estimated"` — the
    literal from §17, from ARB, in all six locales. Fails if the label is the raw glyph run.
  - `the tilde is part of the visible string and survives colour and weight being stripped`
  - `a due card announces item, state and anchor` — "Oil and filter, overdue, was due at
    186,512 kilometres" — never "card, button".
  - `the not-knowing card announces "Odova needs a reading to say when" and offers exactly
    one action, Update odometer`
  - `no state is announced through colour` — every `DueState` node exposes a `value` naming
    the state in words.
  - `a snoozed item keeps its state in the announcement and adds "Snoozed until 12 October"`
  - `CalmAllClear announces the good state rather than reading as an empty list`
  - `no confidence percentage, bar or tier name appears in any label` — a grep over the
    rendered semantics for "measured", "assumed", "%".
  - `the odometer strip is one tap target of at least 48x48 and announces its action`
  - `a Latin workshop name inside a Persian screen carries its own language tag`

  `test/a11y/vehicle_surfaces_semantics_test.dart` over `reminders.list`,
  `reminders.edit`, `vehicle.switcher`, `vehicles`, `vehicle.edit`, `settings.language`,
  `firstrun.language` and `firstrun.vehicle`:
  - `every status dot has an adjacent label or a group header naming its state`
  - `an untracked standard row announces that it is not tracked, not merely greyed`
  - `the delete control on a referenced reminder announces "Turn this off", not "Delete"`
  - `the firstRun vehicle screen announces that name and odometer are required`
  - `the "I already have an Odova backup" link is reachable in traversal before Save`
- **Then build** — `Semantics` authored into the Calm components and the screen widgets:
  display-only labels, `value` for state, `liveRegion` where a state changes under the
  user, `ExcludeSemantics` on decorative marks, and an `estimatedValueSemantics` helper in
  `lib/ui/calm/` so the "about … , estimated" sentence is built once from ARB and not
  concatenated per screen.
- **Verify**
  ```bash
  flutter test test/a11y/home_semantics_test.dart \
               test/a11y/vehicle_surfaces_semantics_test.dart
  flutter test test/parity/home_parity_test.dart test/parity/reminders_list_parity_test.dart \
               test/parity/reminders_edit_parity_test.dart \
               test/parity/vehicle_switcher_parity_test.dart \
               test/parity/vehicles_parity_test.dart test/parity/vehicle_edit_parity_test.dart \
               test/parity/settings_language_parity_test.dart \
               test/parity/firstrun_language_parity_test.dart \
               test/parity/firstrun_vehicle_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/home-light-ltr.png home \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl, and for every screen id above — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-light-ltr.png    # look at the side-by-side
  ```
  Semantics green; parity unchanged. Adding a label must move no pixel — if it did, a
  `Semantics` wrapper introduced a layout box, which is a bug in the wrapper.
- **Done when**
  - [ ] Every announcement is an ARB key; no sentence is concatenated in Dart.
  - [ ] Uncertainty is announced as uncertainty on every screen that renders it.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 17.4 — Semantics and one-handed reach: the log modals, trips and dialogs

- **Goal** — a fill-up can be logged at a pump, one-handed, by someone using a screen reader
  or a switch.
- **Spec** — §10 Logging; §17 Accessibility gate (the `ƒ` badge row, the one-handed Save
  row, the keyboard/switch traversal row); §7 Global dialogs.
- **Skills** — `accessibility-as-code`, `calm-components` (the badge and the hit floor),
  `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/log_modal_semantics_test.dart` over
  `log.fillup`, `log.service`, `log.expense` and `log.odometer`:
  - `the computed field's badge has the accessible name "calculated from the other two"` —
    the literal from §17, from ARB.
  - `tapping the badge clears it and hands over the keyboard, and the announcement follows`
  - `the least-recently-touched of the other two becomes computed, and says so`
  - `Save sits in the bottom third of a 6.7-inch viewport` — a computed-geometry assertion
    on `getRect`, not a golden. A fill-up is logged at a pump in the rain or the design has
    failed.
  - `Save is announced with the reason when it is disabled` — never a silently dead button.
  - `the segmented selector announces the selected segment and is hidden in edit mode`
  - `every field label sits above its input and is associated with it`
  - `the odometer stepper's increment and decrement are each at least 48x48`
  - `full keyboard traversal reaches every field and Save, with a visible focus indicator`
  - `the unit label on log.odometer is announced as a control, not as text` — it is
    tappable per §14 and a user cannot discover that otherwise.

  `test/a11y/dialog_semantics_test.dart` over `dialog.discard`, `dialog.confirmDelete`,
  `dialog.snooze` and `trips.list` / `trips.edit`:
  - `each dialog announces its question and both actions`
  - `dialog.confirmDelete announces what dies, including the entry count`
  - `tap-outside and system back both resolve to the negative action`
  - `dialog.snooze announces the distance option only when the item has a distance interval`
  - `the trips purpose control announces its selection and wraps to a 2x2 grid in German`
- **Then build** — the semantics and the geometry fixes across the four log modals, the two
  trip screens and the three dialogs. Where a control is smaller than 48 dp painted, the
  hit area is expanded rather than the paint — `calm-components` already sets a 52 pt hit
  floor, and this task makes it assertable.
- **Verify**
  ```bash
  flutter test test/a11y/log_modal_semantics_test.dart test/a11y/dialog_semantics_test.dart
  flutter test test/parity/log_fillup_parity_test.dart test/parity/log_service_parity_test.dart \
               test/parity/log_expense_parity_test.dart test/parity/log_odometer_parity_test.dart \
               test/parity/trips_list_parity_test.dart test/parity/trips_edit_parity_test.dart \
               test/parity/dialog_discard_parity_test.dart \
               test/parity/dialog_confirm_delete_parity_test.dart \
               test/parity/dialog_snooze_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/log.fillup-light-ltr.png log.fillup \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl, and for every screen id above — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.fillup-light-ltr.png   # look at the side-by-side
  ```
- **Done when**
  - [ ] The `ƒ` badge, the one-handed Save and the switch traversal rows of §17 are each a
        named passing test.
  - [ ] `dialog.snooze` has the same semantics treatment as the other two.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

> **Resolved before this epic starts.** `dialog.snooze` was the one screen in the §7 table
> with no reference image. The artboard was added to `design/calm/screens.html` and the four
> images re-shot, so `design/reference/calm/` now holds 112 images for 28 screens and this
> dialog is gated like any other. Nothing here ships ungated.

### Task 17.5 — A non-visual alternative for both charts and the report

- **Goal** — the two charts and the service report are usable with the screen off.
- **Spec** — §17 Accessibility gate ("Both charts have a non-visual alternative: a
  screen-reader summary and an accessible data table behind one control"); §12 Fuel
  insights, costs and reports.
- **Skills** — `accessibility-as-code` (a painted chart has no semantics unless you author
  them), `calm-components`, `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`,
  `calm-visual-parity`.
- **Write these tests first** — `test/a11y/charts_semantics_test.dart` over `costs`,
  `costs.fuel`, `report.service` and `history`:
  - `each chart exposes a one-sentence summary naming range, direction and period` — e.g.
    "Consumption over 12 months, from 7.1 to 6.4 litres per 100 kilometres, trending down".
  - `one control switches each chart to an accessible data table` — one control, per §17,
    not a per-point traversal.
  - `the data table announces row and column headers`
  - `every chart tap target is at least 48x48` — §17 names chart tap targets explicitly.
  - `the chart is ExcludeSemantics while the table is the announced representation` — two
    representations of the same data must not both be read.
  - `a mixed-currency window announces both figures side by side and never a blend` — §14,
    "Fill-ups in a second currency": €1.72/L · £1.48/L, two announcements.
  - `an em-dash cost cell in report.service is announced as "cost not recorded"` — not as
    "dash", and not silently skipped.
  - `history rows announce type, date, odometer and amount in that order`
  - `the odometer-correction divider row announces that it is not tappable`
- **Then build** — `ChartSemantics` in `lib/ui/calm/`, the summary builders (pure, from the
  same series the painter draws, so the two cannot disagree), and the table view behind one
  `CalmSegmented` control on each chart.
- **Verify**
  ```bash
  flutter test test/a11y/charts_semantics_test.dart
  flutter test test/parity/costs_parity_test.dart test/parity/costs_fuel_parity_test.dart \
               test/parity/report_service_parity_test.dart test/parity/history_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/costs.fuel-light-ltr.png costs.fuel \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl, and for costs, report.service and history — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/costs.fuel-light-ltr.png   # look at the side-by-side
  ```
  The table control is a new element on two referenced screens: if it changes the band
  profile, that is a **deliberate design change** and the reference set is re-shot in this
  PR. It is never a widened tolerance.
- **Done when**
  - [ ] Both charts have a summary and a table, behind one control each.
  - [ ] The summary is computed from the plotted series, not written by hand.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 17.6 — 200% text scale, in six locales, on every screen

- **Goal** — the biggest text setting in the longest language does not break a single screen.
- **Spec** — §17 Per-locale gate ("Zero glyph clipping at 200% text scale on every screen,
  in every locale"); §14 Edge cases → "200% text scale plus the longest translation"; §5
  Languages, RTL and formats.
- **Skills** — `widget-golden-and-a11y-testing`, `calm-typography-and-rtl`,
  `i18n-rtl-l10n`, `accessibility-as-code`, `adaptive-layout`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/text_scale_matrix_test.dart`, one `testWidgets`
  per screen × tuple, named so a failure names the screen and the locale:
  - `<screen> has no overflow at 200% in de` for all 28 screens — German runs ~30% longer
    and Calm's type is already large, so this is the first wall.
  - `<screen> has no overflow at 200% in ckb` — Sorani is the second, and its translation
    quality is the largest RTL risk in §18.
  - `<screen> has no overflow at 200% in en, fr, fa and ar`
  - `<screen> has no overflow at 200% with boldText on`
  - `tab labels fit their 12-character budget in all six locales` — the budget is declared
    in ARB metadata (§5); the test reads the metadata rather than a copy of it.
  - `the three settings.notifications category labels fit their 22-character budget`
  - `home scrolls in reading order at 200% with the primary card first and nothing clipped` —
    §9 voids the above-the-fold guarantee at 200%; this asserts what replaces it.
  - `no card, sentence block or text container has a fixed pixel height` — a widget-tree
    walk over the 28 screens, because §14 forbids it by construction.
  - `a button wraps to two lines rather than shrinking` — `settings.backup`'s "Back up now"
    in German is the named case in §13.
  - `the costs filter chip row scrolls rather than truncating or shrinking`
  - `the trips purpose control becomes a 2x2 grid in German rather than shrinking`
  - `the costs.fuel Last tank / Best / Worst strip becomes two columns below 380 dp or at
    150%`
- **Then build** — the layout fixes each red test demands: intrinsic heights, `Wrap` over
  `Row`, labels above inputs, `Flexible` where a fixed width crept in. Never a `FittedBox`,
  never an `ellipsis`, never a clamp — those turn a loud test failure into a silent device
  failure, which is the exact trade `accessibility-as-code` forbids.
- **Verify**
  ```bash
  flutter test test/a11y/text_scale_matrix_test.dart
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.backup-light-ltr.png   # look at the side-by-side
  ```
  Every tuple green; the type floor holds at 13px; and parity — which is shot at 100% scale
  — is unchanged, proving the flexibility work did not move the default layout. If a screen
  moved at 100%, that is a regression, not a fix.
- **Done when**
  - [ ] All 28 screens pass at 200% in all six locales, with bold on and off.
  - [ ] No fixed pixel height survives on any text container.
  - [ ] No clamp, `FittedBox` or label `ellipsis` was added anywhere.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 17.7 — The colour-blind and grayscale pass

- **Goal** — the app says the same thing with every colour removed.
- **Spec** — §17 Accessibility gate; §3 Domain model → `DueState`; §9 Home.
- **Skills** — `calm-due-state-and-status` (its redundant-encoding rules are what this pass
  tests), `accessibility-as-code`, `widget-golden-and-a11y-testing`, `calm-tokens`.
- **Write these tests first** — `test/a11y/redundant_encoding_test.dart`:
  - `no two DueState hues differ by 3:1` — asserts the *premise*: 1.51:1 in light, 1.36:1
    in dark, measured over the tokens. Colour is a mood here, not a signal, and this test
    is why every other assertion in this task exists.
  - `every state renders a distinct mark shape` — six silhouettes, compared as geometry;
    `calm-due-state-and-status` records two known collisions in the shipped CSS, and this
    test either confirms they were fixed or names them.
  - `every state renders its word` — the label, from ARB, in six locales.
  - `every surface rendering a state renders mark and label together` — a bare coloured dot
    with no adjacent label or group header fails.
  - `overdue sorts to the top under its own header` — position is the fourth channel.
  - `success is never green alone` — a check glyph and the word accompany it.
  - `danger red appears only on destructive actions` — a token-usage walk.
  - `no widget outside calm_status.dart switches on DueState to pick a colour`
  - `a grayscale render of home is still unambiguous` — the six states are distinguishable
    with saturation zeroed, asserted through mark geometry rather than by eye.
- **Then build** — whatever the mark set needs to make six silhouettes distinct, the missing
  labels, and the sort/header that carries position. Marks are `CalmStatusMark` constants in
  `lib/theme/calm/calm_status.dart` — the one place `design-system-structure` allows a
  literal — and nowhere else.
- **Verify**
  ```bash
  flutter test test/a11y/redundant_encoding_test.dart
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh
  flutter test test/parity/home_parity_test.dart test/parity/reminders_list_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/reminders.list-light-ltr.png reminders.list \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/reminders.list-light-ltr.png   # look at the side-by-side
  ```
  Plus the human half `design-review-workflow` owns: a deuteranopia, protanopia and
  tritanopia simulation over `home` and `reminders.list`, looked at by a person.
- **Done when**
  - [ ] The six marks are geometrically distinct and the known collisions are closed or named.
  - [ ] No state anywhere is carried by colour alone.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 17.8 — Focus order, traversal and reachability, including RTL

- **Goal** — a linear scanner reaches the important control early, in both directions, and
  a thumb reaches Save.
- **Spec** — §17 Accessibility gate (full keyboard/switch traversal, the one-handed row);
  §5 Languages, RTL and formats; §7 Tab bar → RTL.
- **Skills** — `accessibility-as-code` (traversal is authored, never inherited from layout),
  `i18n-rtl-l10n`, `widget-golden-and-a11y-testing`, `adaptive-layout`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/traversal_test.dart`:
  - `home traversal is ordered by urgency, not by layout` — the overdue card is reached
    before the odometer strip, whatever the visual arrangement.
  - `sortKey order equals priority order on every screen that authors one`
  - `traversal order is identical in LTR and RTL` — direction mirrors the *geometry*, not
    the reading order of a list.
  - `the tab bar mirrors in RTL with Settings leftmost and the + still centred`
  - `no screen relies on layout order for traversal` — a walk asserting an authored
    `sortKey` wherever visual order and priority differ.
  - `simulatedAccessibilityTraversal reaches every interactive node on all 28 screens` — an
    unreachable control is invisible to a switch user even when it is labelled.
  - `every primary action on a modal is within the bottom third of a 6.7-inch viewport`
  - `no affordance is long-press-only or precise-gesture-only`
  - `a visible focus indicator is present on every focusable node in both themes`
  - `six glyphs mirror and no others` — `calm-typography-and-rtl`'s list, as a test, so an
    over-eager mirror of a logo or a chart axis fails.
- **Then build** — `sortKey`s authored from priority, focus traversal groups on the forms,
  the RTL mirroring fixes, and any reachability change the geometry assertions demand.
- **Verify**
  ```bash
  flutter test test/a11y/traversal_test.dart
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-dark-rtl.png    # look at the side-by-side
  ```
  The i18n ban script must find no `left`/`right` outside the icon-asset layer. And be
  honest about the limit `accessibility-as-code` states: Flutter publishes no Switch Access
  support statement and no API simulates scanning, so these tests guard *intent*. The
  conformance evidence is a real device, and it belongs to `design-review-workflow`.
- **Done when**
  - [ ] Traversal is authored from priority on every screen where it differs from layout.
  - [ ] LTR and RTL traversal orders match, and only the six glyphs mirror.
  - [ ] The on-device switch pass is scheduled or recorded as outstanding.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 17.9 — Touch targets, everywhere, including the awkward ones

- **Goal** — nothing in the app needs a precise finger.
- **Spec** — §17 Accessibility gate ("Minimum touch target 48×48 dp everywhere, including
  the odometer stepper and chart tap targets").
- **Skills** — `accessibility-as-code`, `calm-components` (the 52 pt hit-area floor),
  `widget-golden-and-a11y-testing`, `adaptive-layout`, `calm-visual-parity`.
- **Write these tests first** — `test/a11y/touch_targets_test.dart`:
  - `every interactive node on all 28 screens has a hit rect of at least 48x48` — computed
    from `getRect` over the real tree, one `testWidgets` per screen so the failure names it.
  - `the odometer stepper's increment and decrement each clear 48x48` — named in §17
    because it is the one most likely to be drawn small.
  - `chart tap targets clear 48x48` — also named in §17.
  - `a painted control smaller than 48 dp expands its hit area, not its paint` — asserts the
    painted size is unchanged against the reference geometry while the rect grew.
  - `adjacent targets do not overlap` — an expanded hit area that swallows its neighbour is
    a worse bug than a small one.
  - `every target is single-tap` — no long-press-only path, restated as a screen-level walk.
  - `the tab bar's five slots each clear 48x48 at 200% text scale`
- **Then build** — hit-area expansion where needed, in the Calm components rather than per
  screen, so the fix lands once. Where §17 says 48 and `accessibility-as-code` says 44,
  build 48: the spec is the product decision (see the finding below).
- **Verify**
  ```bash
  flutter test test/a11y/touch_targets_test.dart
  bash .claude/skills/calm-components/scripts/check_component_hygiene.sh
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.odometer-light-rtl.png   # look at the side-by-side
  ```
  Every screen green, and parity unchanged — a hit area is not paint, so no reference image
  should move. If one did, the paint changed and that is the finding.
- **Done when**
  - [ ] All 28 screens pass the 48 dp assertion, including the stepper and the charts.
  - [ ] The fix lives in `lib/ui/calm/`, not sprinkled across screens.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

> **Two floors, one number.** `SPEC.md` §17 says 48×48 dp. `accessibility-as-code` rule 8
> says 44×44 logical pixels (the iOS/WCAG 2.5.5 floor). `calm-components` sets a 52 pt hit
> area on its controls. They do not contradict each other so much as stack: build **48**,
> which satisfies §17 and clears 44, and let `calm-components`' 52 stand where it already
> does. Record the choice in `epics/progress/EPIC-17.md` so nobody relitigates it in review.

### Task 17.10 — Turn the §17 accessibility gate into something CI runs

- **Goal** — the release blocker in §17 is a command, not a checklist someone reads.
- **Spec** — §17 Definition of done → Accessibility gate, every row; §17 Per-locale gate.
- **Skills** — `ci-pipeline-and-gates`, `widget-golden-and-a11y-testing`,
  `accessibility-as-code`, `design-review-workflow`.
- **Write these tests first** — `test/a11y/gate_coverage_test.dart`, which tests the gate's
  completeness rather than the app:
  - `every row of the SPEC section 17 accessibility gate maps to a named test` — the eight
    rows are declared as a `const` list with the test name that covers each; a row with no
    test fails.
  - `every one of the 28 screens appears in the text-scale matrix`
  - `every one of the 28 screens appears in the touch-target walk`
  - `every one of the 28 screens appears in a semantics test`
  - `a screen added to the router without an a11y test fails this test` — the walk is over
    the route table, so a new screen cannot arrive unguarded.
  - `the accessibility finding file records a resolution` — the file must contain a dated
    "Resolved" or "Accepted" line; a finding carried forward silently fails the build. This
    is the assertion that stops this epic's central promise from rotting.
- **Then build** — the `a11y` job in `.github/workflows/ci.yml`, running
  `flutter test test/a11y/ test/policy/` plus the ban greps, wired as a required check; and
  the sign-off artefact `design/calm/A11Y-SIGNOFF.md` that `design-review-workflow` fills
  in on the release build — the on-device TalkBack, VoiceOver and Switch Access passes, the
  native fa and ar RTL reads, and the CVD simulation. Be honest in the workflow file about
  what CI cannot prove: real fonts, real screen readers, real devices.
- **Verify**
  ```bash
  flutter test test/a11y/ test/policy/
  bash .claude/skills/ci-pipeline-and-gates/scripts/ci-gates.sh
  bash .claude/skills/ci-pipeline-and-gates/scripts/banned-strings.sh
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  ```
  A pass is a green `a11y` job on a pull request, and a red one when a label is deleted from
  any screen — try it once and put the result in the progress file.
- **Done when**
  - [ ] Every §17 accessibility row maps to a named test, asserted by a test.
  - [ ] The `a11y` job is required, and has been seen to fail.
  - [ ] `design/calm/A11Y-SIGNOFF.md` exists, with the human passes named and either done or
        scheduled.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type
        weight, icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] Every one of the 28 screens renders at 200% text scale in all six locales, bold on and
      off, with no truncation, clipping, shrinking or overlap.
- [ ] No `MediaQuery.withClampedTextScaling`, no `textScaleFactor`, no `FittedBox` and no
      `TextOverflow.ellipsis` on a user-facing label exists under `lib/`.
- [ ] Every interactive node is labelled, every icon labelled or excluded, every state
      announced in words, and every estimated value announced as "about …, estimated".
- [ ] The `ƒ` badge, both chart alternatives, the one-handed Save and full keyboard/switch
      traversal — every row of the §17 accessibility gate — is a named passing test.
- [ ] Contrast is asserted over a declared foreground/background table in both themes, and
      `design/calm/ACCESSIBILITY-FINDING.md` carries a dated resolution or a named
      acceptance. It is not carried past this epic.
- [ ] Every interactive target clears 48×48 dp, including the odometer stepper and the chart
      tap targets.
- [ ] No state is carried by colour alone; the six marks are geometrically distinct in
      grayscale.
- [ ] Traversal is authored from priority and is identical in LTR and RTL.
- [ ] The `a11y` CI job is required and has been observed to fail on a deleted label.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-17.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
