# EPIC-18 — The visual parity and design review sweep

| | |
|---|---|
| **Epic** | EPIC-18 — The visual parity and design review sweep |
| **Depends on** | EPIC-09, EPIC-10, EPIC-11, EPIC-12, EPIC-13, EPIC-14, EPIC-15 |
| **Estimate** | **8.5 h (CC) · ~8.5 weeks (human)** total |
| **Spec sections** | §17 Definition of done for v1 (per-locale gate, accessibility gate, offline gate) |
| **Screens** | all 28: `firstrun.language`, `firstrun.vehicle`, `home`, `vehicle.switcher`, `reminders.list`, `reminders.edit`, `log.fillup`, `log.service`, `log.expense`, `log.odometer`, `history`, `report.service`, `costs`, `costs.fuel`, `trips.list`, `trips.edit`, `settings`, `vehicles`, `vehicle.edit`, `settings.language`, `settings.units`, `settings.notifications`, `settings.backup`, `settings.import`, `settings.about`, `dialog.discard`, `dialog.confirmDelete`, `dialog.snooze` |

Every feature epic already parity-checked its own screens. This epic exists because that
catches **per-screen** drift and nothing else. The drift that matters at the end is the kind
that only shows up when you put twenty-eight screens next to each other: a gap that is `s4` on
six screens and `s5` on the seventh, a section heading that stepped a size somewhere in the
Costs stack, a chevron that mirrors on `settings` and does not on `vehicles`. No per-screen
check can see any of that, because each of those screens passes on its own.

Then the human half. `calm-visual-parity` gates three things — theme, token colour, and the
horizontal band profile — and is explicit that it cannot see type weight, letter-spacing, icon
shape or optical alignment. Those are most of what the design actually is, so this epic ends
with `design-review-workflow`'s structured pass on the **release** build, findings graded
BLOCKER / FIX / NOTE, exactly one scoped fix round, and a dated sign-off artifact that
EPIC-19 depends on.

**The rule that governs every fix in this epic:** the reference is the authority and the app
is the thing under test. If a screen genuinely cannot match its reference, the remedy is a
deliberate design change that edits `design/calm/odova.css`, regenerates `screens.html`,
re-shoots all 112 images and says in the PR what changed and why — in the same PR. Never a
widened tolerance. `--token-tolerance` is not touched in this epic at all.

## Where we are now

The repo has a Flutter app. EPIC-01 created it (`pubspec.yaml`, `lib/`, `.flutter-version`
pinned at 3.44.6); the foundation epics laid down the domain core, Drift persistence, the
Calm theme under `lib/theme/calm/`, l10n for all six locales, routing and the notification
scheduler; EPIC-09 … EPIC-15 built all 28 screens. Concretely, at the moment this epic
starts:

- Every screen exists as a route and each one has its own parity test under `test/parity/`,
  written by the epic that built it, covering that screen's four combinations.
- `design/reference/calm/` holds the 112 committed reference PNGs (28 screens × light/dark ×
  ltr/rtl) at 780×1688. They have not been regenerated since they were shot; they are still
  the authority.
- `tools/compare_to_reference.mjs`, `tools/shoot_design.mjs`, `tools/build_screens.mjs`,
  `tools/optimise_png.mjs` and `.claude/skills/calm-visual-parity/scripts/check_parity.sh`
  all exist and work; `node_modules/` under `tools/` is already installed.
- `design/calm/ACCESSIBILITY-FINDING.md` records two **unfixed** WCAG failures in Calm's
  light theme: `--color-ink-3` `#8B7B6C` fails 4.5:1 on all four light surfaces, and
  `--color-ink-4` `#AC9C8B` is used for input placeholders at 2.60:1. Nobody has decided
  them yet. Under `design-review-workflow` rule 5 a contrast miss is a mandatory BLOCKER, so
  they cannot survive this epic undecided.
- CI is green: `flutter analyze --fatal-infos --fatal-warnings` clean, `flutter test` green.

What is deliberately still missing: there is no sweep harness (the parity tests are 28
separate files with 28 hand-written fixtures), no cross-screen fixture, no review folder, no
sign-off artifact, and no release build has ever been looked at by a human. `dialog.snooze`
has a route, a widget and a reference image — see the note at the end of Task 18.1.

## What we will have when this is done

- One command, `flutter test test/parity/ && bash .claude/skills/calm-visual-parity/scripts/check_parity.sh`,
  captures 112 PNGs into `build/parity/` and reports all 28 screens green.
- `test/parity/parity_screens.dart` — one registry naming all 28 screen ids and the fixture
  each is captured over. Adding a screen to the app without adding it here fails a test.
- `design/review/parity-sweep.md` — the triage table: every one of the 112 comparisons, its
  verdict, and for each failure which of the three checks failed and what was done about it.
- `design/review/shots/` — the design-review sweep matrix, one sortable file per cell,
  `NN--<screen>--<theme>--<dir>.png`, shot on the release build at the largest text scale.
- `design/review/findings.md` — every finding graded BLOCKER / FIX / NOTE with its
  resolution, deduped into one table.
- `design/review/SIGNOFF-<date>.md` — dated, named reviewer, commit sha, build flavour, the
  matrix inventory, the findings table, and a verdict line. EPIC-19 will not start without it.
- The Calm contrast finding is closed one way or the other, in writing, and if it was fixed
  the 112 references were re-shot in the same change.
- A person can open any file in `design/reference/_parity/` and see the reference, the app and
  the heatmap side by side for that screen.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Every fix in this epic still obeys the house rules — dumb widgets, no raw values, `start`/`end` geometry. |
| `calm-visual-parity` | Owns the whole first half: what the three checks decide, why a pixel diff is never a gate, the four captures a screen needs, and the regenerate-the-set ritual. |
| `calm-tokens` | The colour failures resolve here. A surface that is not within Δ24 of a Calm token means a raw colour or the wrong semantic slot; `scripts/check_raw_values.sh` finds it. |
| `calm-layout-and-motion` | The band-edge failures are spacing and geometry failures. This skill owns the spacing scale the band check is really testing, and the motion the captures freeze. |
| `calm-typography-and-rtl` | The RTL half of the sweep: what must mirror, what must not (the Latin plate `M-AB 1234`), and why the RTL references are real Persian rather than mirrored English. |
| `design-review-workflow` | Owns the second half: the sweep matrix, the four lenses, the BLOCKER/FIX/NOTE rubric, the one fix round and the dated sign-off. |
| `widget-golden-and-a11y-testing` | Owns the `pumpApp` harness the parity captures reuse, and the goldens that must be re-baselined by any accepted visual FIX. |
| `run-goldens-rebaseline` | The runbook for that re-baselining. A fix round that moves pixels moves goldens. |
| `accessibility-as-code` | The floor every BLOCKER enforces — contrast, 48×48 dp targets, never clamp the text scaler, colour never alone. Also what closes the Calm contrast finding. |
| `i18n-rtl-l10n` | The RTL cells of the review matrix: bidi, numerals, glyph coverage, no hard-coded `left`/`right`. |

Not loaded on purpose: `release-and-store-shipping`. Everything about the artifact belongs to
EPIC-19; this epic's only output for it is the sign-off.

## Tasks

### Task 18.1 — Build the parity screen registry and the whole-app sweep harness

- **Goal** — one parametrised suite captures all 28 screens × 4 combinations in a single run,
  and a screen that exists in the app but not in the sweep fails a test.
- **Spec** — §7 Screen map and navigation (the screen table and the `data-screen` ids);
  §17 per-locale gate.
- **Skills** — `calm-visual-parity` (`references/capturing-the-app.md`,
  `examples/parity_golden_test.dart`), `widget-golden-and-a11y-testing`,
  `flutter-conventions-index`.
- **Write these tests first**
  - `test/parity/parity_registry_test.dart`:
    - `registry names exactly the 28 referenced screens` — the id set in
      `kParityScreens` equals the set derived from the filenames in `design/reference/calm/`.
      Fails if a screen was added to the app and not to the registry, or a reference exists
      that nothing captures.
    - `every registry entry has four reference images` — for each id, all of
      `<id>-light-ltr.png`, `<id>-dark-ltr.png`, `<id>-light-rtl.png`, `<id>-dark-rtl.png`
      exist under `design/reference/calm/`. Fails on a half-shot screen.
    - `every route in the app router appears in the registry` — the `data-screen` ids the
      router can reach are a subset
      of the registry. Fails when EPIC-19 or a later change adds a screen with no reference.
  - `test/parity/sweep_test.dart`:
    - `captures 112 PNGs into build/parity` — after the suite runs,
      `Directory('build/parity').listSync()` has 112 entries named
      `<screen>-<theme>-<dir>.png`. Fails if a capture silently threw and the file was never
      written, which is otherwise invisible until `check_parity.sh` reports a missing file.
    - `every capture is 780x1688` — decode each PNG and assert the dimensions. Fails on a
      capture whose `tester.view.physicalSize` was not pinned, which distorts the band check
      for a reason that is not the screen's fault.
- **Then build**
  - `test/parity/parity_screens.dart` — `const kParityScreens` : a list of records
    `({String id, ParityFixture fixture})`, one per screen id above — all 28, with
    `dialog.snooze` included like any other.
  - `test/parity/parity_harness.dart` — lift `captureParity()` from
    `.claude/skills/calm-visual-parity/examples/parity_golden_test.dart` verbatim in
    behaviour: pin `physicalSize` 780×1688, `devicePixelRatio` 2.0, `addTearDown(tester.view.reset)`,
    pin `ThemeMode` explicitly, pin the locale (`en` for ltr, `fa` for rtl), pin
    `textScaler` to 1.0, and set `disableAnimations: true` rather than calling
    `pumpAndSettle()`.
  - `test/parity/sweep_test.dart` — iterate `kParityScreens` × the four `ParityCase`s and
    write to `build/parity/`.
  - Delete the 28 per-screen `test/parity/<screen>_parity_test.dart` files **only** where the
    sweep reproduces them exactly; keep any that pin a fixture the sweep cannot express, and
    say which in the progress file.
- **Verify**
  ```bash
  flutter test test/parity/parity_registry_test.dart
  flutter test test/parity/                                # writes 112 PNGs to build/parity/
  ls build/parity/*.png | wc -l                            # 112
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  node tools/compare_to_reference.mjs build/parity/home-light-ltr.png home \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or just re-read the check_parity.sh output
  open design/reference/_parity/home-light-ltr.png          # look at the side-by-side
  ```
  A pass is 112 files, and `check_parity.sh` printing a line per capture with no `SKIP` and no
  `is missing from the registry`. Failures here are expected at this point — Task 18.4 triages them; what
  this task must prove is that the harness *runs* all 112.
- **Done when**
  - [ ] `kParityScreens` names all 28 ids and the registry test is green.
  - [ ] One `flutter test test/parity/` run produces 112 correctly named, correctly sized PNGs.
  - [ ] `check_parity.sh` reports on all 112 — no capture is skipped for a naming reason.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

> **`dialog.snooze` was the one screen without a reference, and now has one.** §7 lists it as
> one of the three global dialogs, and the design set was built without it. The artboard has
> since been added to `design/calm/screens.html` and the four images re-shot, which is why the
> set is 28 screens and 112 images rather than 27 and 108. It is an ordinary screen in this
> sweep with no exception and no carve-out — EPIC-08 builds it, and it is parity-checked like
> every other.

### Task 18.2 — Pin one sweep fixture that reproduces what the references depict

- **Goal** — every capture is generated from one deterministic dataset that shows the same
  numbers the reference images show, so a band difference means a layout difference and never
  a data difference.
- **Spec** — §3 Domain model and rules (canonical storage units, `<prefix>_<ULID>` ids); §5
  Languages, RTL and formats (numerals, Jalali, currency).
- **Skills** — `seeded-determinism-and-golden-vectors`, `calm-visual-parity`
  (`references/the-reference-set.md`), `value-objects-money-and-units`,
  `calm-typography-and-rtl`.
- **Write these tests first**
  - `test/parity/parity_fixture_test.dart`:
    - `the fixture is byte-identical across two builds` — build it twice with the same seeded
      clock and id generator and assert deep equality. Fails on any `DateTime.now()` or
      unseeded ULID leaking into the fixture, which would move a row's date and shift a band.
    - `the LTR fixture renders the reference's numbers` — the active vehicle's odometer
      formats as `187,412` under `en`. Fails if the fixture drifts from what
      `design/reference/calm/home-light-ltr.png` shows.
    - `the RTL fixture renders Extended Arabic-Indic digits and Jalali` — the same reading
      formats as `۱۸۷٬۴۱۲` under `fa`, and 14 March renders as `۲۴ اسفند`. Fails if the RTL
      captures are accidentally shot in `en` — the single most common way an RTL capture
      passes for the wrong reason.
    - `the licence plate is not mirrored` — `M-AB 1234` renders left-to-right inside the RTL
      capture. Fails if the plate was wrapped in the wrong bidi isolate.
  - `test/parity/parity_fixture_states_test.dart`:
    - `every DueState the references show is present` — the fixture contains at least one
      reminder in each of `ok`, `due_soon`, `due`, `overdue`, `unknown`. Fails if a status
      ramp is never painted and its token therefore never checked.
- **Then build**
  - `test/parity/parity_fixture.dart` — `ParityFixture` building an in-memory Drift database
    from one seed: one active vehicle at 187,412 km with plate `M-AB 1234`, the reminder set
    covering the five statuses, enough fill-ups for `costs.fuel` to draw both charts, and one
    trip. Money in EUR for the `en` captures and IRR displayed as toman for the `fa` captures,
    per §5.
  - Wire it into `parity_screens.dart` so each registry entry names the fixture slice it needs.
- **Verify**
  ```bash
  flutter test test/parity/parity_fixture_test.dart test/parity/parity_fixture_states_test.dart
  flutter test test/parity/ && bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  ```
  A pass is the fixture tests green and the band-edge counts in the `check_parity.sh` output
  moving *up* compared to Task 18.1's run — same layout, right data.
- **Done when**
  - [ ] One fixture, one seed, reproducible twice in a row.
  - [ ] The RTL captures are real Persian with extarab numerals and Jalali dates.
  - [ ] All five due statuses appear somewhere in the 112 captures.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

### Task 18.3 — Close the Calm contrast finding, and regenerate the reference set if it is fixed

- **Goal** — the two WCAG failures recorded in `design/calm/ACCESSIBILITY-FINDING.md` are
  decided before the sweep runs, rather than discovered as BLOCKERs after it.
- **Spec** — §17 accessibility gate ("treated as a release blocker, not a polish item");
  §13 (`settings.about` and the settings screens where tertiary text lives).
- **Skills** — `accessibility-as-code`, `calm-tokens` (`references/contrast-audit.md`),
  `calm-visual-parity` (rule 7, the regenerate ritual), `design-review-workflow` (rule 5).
- **Write these tests first**
  - `test/theme/calm_contrast_test.dart`:
    - `ink3 clears 4.5:1 on every light surface` — computed contrast of `CalmColors.ink3`
      against `bg`, `surface`, `surface2` and `surface3` in the light theme is ≥ 4.5. Fails
      today at 3.67 / 3.99 / 3.42 / 3.02, which is the point.
    - `placeholder ink clears 4.5:1 on surface and bg` — the colour the input placeholder
      resolves to is not `CalmColors.ink4`. Fails today at 2.60 and 2.39.
    - `ink3 and ink4 still clear 4.5:1 in dark` — a regression guard; dark is already fine and
      the fix must not touch it.
  - `test/theme/calm_token_source_test.dart`:
    - `every Dart token equals its CSS declaration` — parse `design/calm/odova.css` and assert
      each `CalmPalette` constant matches. Fails if the CSS is edited and the Dart is not, or
      the other way round, which is exactly the failure mode of a design change.
- **Then build** — this is a decision, and it has two legal outcomes. Take one, in writing:
  1. **Fix.** Set `--color-ink-3: #6B5F53` in `design/calm/odova.css` (the only candidate in
     the finding that clears all four surfaces) and point `.input::placeholder` /
     `.textarea::placeholder` at the corrected `--color-ink-3` instead of `--color-ink-4`.
     Mirror both into `lib/theme/calm/calm_palette.dart`. Then regenerate, in this PR:
     ```bash
     FRAG_DIR=<fragments> node tools/build_screens.mjs
     node tools/shoot_design.mjs calm
     node tools/optimise_png.mjs
     ```
     and say in the PR what changed and why. All 112 Calm references move; that is correct
     and it is the only sanctioned way a reference changes.
  2. **Accept.** Record in `design/review/findings.md` that the softness is worth the failure,
     with the name of whoever decided it — and then §17's accessibility gate does not pass, so
     EPIC-19 cannot sign off. Outcome 1 is strongly recommended; outcome 2 exists only so that
     the decision is made by a person and not by silence.
- **Verify**
  ```bash
  flutter test test/theme/calm_contrast_test.dart test/theme/calm_token_source_test.dart
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh
  git status --short design/reference/calm/     # 112 modified, if outcome 1
  flutter test test/parity/ && bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings-light-ltr.png
  ```
  A pass is the contrast tests green and, under outcome 1, exactly the Calm reference set
  modified — never one image, never a hand-edited PNG.
- **Done when**
  - [ ] Both findings are closed in writing, with a name and a date.
  - [ ] Under outcome 1, `odova.css`, `calm_palette.dart` and all 112 Calm references moved
        together in one change.
  - [ ] No tolerance was widened, and no reference was regenerated to clear an unrelated
        failure.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.4 — Run the 112-comparison sweep and triage every failure

- **Goal** — one authoritative table of what does not match, sorted into the three classes the
  tool can name, so the fix tasks are scoped rather than exploratory.
- **Spec** — §17 per-locale gate.
- **Skills** — `calm-visual-parity` (the failure table in the SKILL, and
  `references/what-parity-can-prove.md`), `calm-tokens`, `calm-layout-and-motion`.
- **Write these tests first**
  - `test/parity/sweep_report_test.dart`:
    - `the triage table covers all 112 comparisons` — parse `design/review/parity-sweep.md`
      and assert one row per `<screen>-<theme>-<dir>`. Fails if a screen was quietly dropped
      from the sweep, which is how a broken screen ships.
    - `no row is left unresolved` — every row's verdict is one of `pass`, `fixed`,
      `design-change`, `deferred-NOTE`. Fails on an empty cell, so "we'll come back to it"
      cannot be the state at sign-off.
- **Then build**
  - Run the full sweep, capture the raw output, and write `design/review/parity-sweep.md`:
    one row per comparison with the verdict, and for each failure the failing check
    (`theme` / `colour` / `bands`), the message verbatim, and the class it belongs to.
  - Classify each failure using the skill's own table: a wrong-theme red is almost always the
    harness; `#XXXXXX covers N% and is not a Calm token` is a raw colour or the wrong semantic
    slot; `N% of the reference's band edges are absent` is a height, an order or a missing
    element — read the band count before guessing, a small miss is one card's padding and a
    large one is a whole element that did not render.
  - Do **not** fix anything in this task. Triage only; fixes are 17.5 – 17.7.
- **Verify**
  ```bash
  flutter test test/parity/
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh | tee design/review/parity-raw.txt
  flutter test test/parity/sweep_report_test.dart
  ```
  A pass is a complete table. The sweep itself is expected to be red here — that is the input
  to the next three tasks, not a failure of this one.
- **Done when**
  - [ ] `design/review/parity-sweep.md` has 112 rows and no empty verdict.
  - [ ] Every failure is classified as theme, colour or bands, with the tool's own message
        quoted.
  - [ ] The differing-pixel percentages are recorded as information and used as a gate
        nowhere.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.5 — Fix the band class: the vertical rhythm that drifted across screens

- **Goal** — every screen's horizontal band profile matches its reference, which is the check
  that catches a gap, a card height or a section order that drifted between feature epics.
- **Spec** — §7 Screen map and navigation; §9 Home; §11 History; §12 Fuel insights, costs and
  reports; §13 Settings (the screens whose bands most commonly drift, because they are lists).
- **Skills** — `calm-layout-and-motion`, `calm-components`, `widget-composition`,
  `calm-visual-parity`.
- **Write these tests first**
  - `test/widget/calm_spacing_test.dart`:
    - `every section gap on a list screen comes from CalmSpace` — pump `settings`,
      `reminders.list`, `vehicles`, `trips.list` and assert the vertical gaps between section
      widgets are values present in `CalmSpace`. Fails on a hand-typed `SizedBox(height: 18)`,
      the exact construct that produces a 2px band offset on one screen out of seven.
    - `the four tab roots use one page scaffold` — `home`, `history`, `costs` and `settings`
      each render a `CalmScaffold` with the same outer padding. Fails if one screen re-invented
      its own frame.
  - `test/widget/calm_type_scale_test.dart`:
    - `no screen paints a fontSize outside CalmType` — walk the widget tree of each of the 28
      screens and assert every resolved `TextStyle.fontSize` is one of the nine role sizes.
      Fails on a heading that stepped a size, which is invisible per screen and obvious across
      28.
- **Then build**
  - Fix each band failure in `design/review/parity-sweep.md` at its source: replace raw
    spacing with `CalmSpace` slots, restore the section order §7 and the per-screen sections
    of the spec define, and extract the repeated frame into a shared component rather than
    patching each screen.
  - Where a band miss is genuinely the design's (the reference shows something the spec does
    not describe), stop and route it through Task 18.3's outcome-1 ritual instead of nudging
    a padding.
- **Verify**
  ```bash
  flutter test test/widget/calm_spacing_test.dart test/widget/calm_type_scale_test.dart
  flutter test test/parity/
  node tools/compare_to_reference.mjs build/parity/settings-light-ltr.png settings \
       --theme light --dir ltr
  node tools/compare_to_reference.mjs build/parity/costs.fuel-dark-ltr.png costs.fuel \
       --theme dark --dir ltr
  # repeat for light-rtl and dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings-light-ltr.png     # look at the side-by-side
  open design/reference/_parity/costs.fuel-dark-ltr.png
  ```
  A pass is `the vertical rhythm matches the reference` on every screen, with the band-edge
  count at or above the 75% floor and, on the screens that were fixed, near the full count.
- **Done when**
  - [ ] Every band-class row in the triage table is `fixed` or `design-change`.
  - [ ] No fix was a one-off padding on a single screen; each is a token or a shared component.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.6 — Fix the colour class: every surface back onto a Calm token

- **Goal** — no screen paints a surface that is not within Δ24 of a token in
  `design/calm/odova.css`, in either theme.
- **Spec** — §9 Home (the due-status colours); §17 accessibility gate (colour never alone).
- **Skills** — `calm-tokens`, `calm-due-state-and-status`, `calm-design-system`,
  `calm-visual-parity`.
- **Write these tests first**
  - `test/theme/no_raw_values_test.dart`:
    - `no Color literal outside lib/theme/calm` — asserts `scripts/check_raw_values.sh` exits
      0. Fails on the `Color(0xFF…)` that a screen epic slipped in under deadline.
    - `no CalmPalette reference outside lib/theme/calm` — a Tier-1 primitive in a widget is a
      widget that has hardcoded light mode.
  - `test/widget/due_status_colour_test.dart`:
    - `each DueState resolves to its own ramp` — `ok`, `due_soon`, `due`, `overdue`,
      `unknown`, `needs_odometer` and `paused` each resolve to a distinct `CalmRamp`, and
      `unknown` never resolves to the `overdue` ramp. Fails on the exact bug
      `calm-visual-parity` names: a token read from the wrong slot, which passes a golden and
      fails parity.
    - `status is never carried by colour alone` — each status card also exposes an icon and a
      text label in its semantics. Fails a §17 accessibility-gate line.
- **Then build**
  - Fix each colour failure at its slot: a raw colour becomes a semantic slot; a wrong slot
    becomes the right one; a genuinely new need becomes a **new token in `odova.css` plus a
    regenerated reference set** (Task 18.3's ritual), never an `// ignore`.
  - Check every fix against `calm-tokens/references/the-token-tables.md` before adjusting
    anything — the closest pair in the light palette is 34 apart, so a Δ24 failure is a real
    colour error and not tolerance noise.
- **Verify**
  ```bash
  bash .claude/skills/calm-tokens/scripts/check_raw_values.sh
  bash .claude/skills/calm-tokens/scripts/check_extension_fields.sh
  flutter test test/theme/ test/widget/due_status_colour_test.dart
  flutter test test/parity/
  node tools/compare_to_reference.mjs build/parity/home-dark-ltr.png home \
       --theme dark --dir ltr
  node tools/compare_to_reference.mjs build/parity/reminders.list-light-rtl.png reminders.list \
       --theme light --dir rtl
  # repeat for the remaining combinations — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-dark-ltr.png          # look at the side-by-side
  ```
  A pass is `every surface over 0.5% is within Δ24 of a Calm token` on all 112, with
  `--token-tolerance` at its default.
- **Done when**
  - [ ] Every colour-class row in the triage table is `fixed` or `design-change`.
  - [ ] `check_raw_values.sh` is green.
  - [ ] `--token-tolerance` was never passed on the command line.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

### Task 18.7 — Fix the RTL class: mirroring that stopped being consistent

- **Goal** — the 56 RTL captures match their references, and the mirroring is consistent
  across all 28 screens rather than correct on the screens someone remembered.
- **Spec** — §2 Non-negotiables (no layout code uses left or right); §5 Languages, RTL and
  formats; §7 (tab order mirrors, the `+` stays centred, back-swipe edge mirrors).
- **Skills** — `calm-typography-and-rtl`, `i18n-rtl-l10n`, `adaptive-layout`,
  `calm-visual-parity`.
- **Write these tests first**
  - `test/policy/no_left_right_test.dart`:
    - `no hardcoded left or right outside the icon-asset layer` — grep `lib/` for
      `EdgeInsets.only(left:`, `.right`, `Alignment.centerLeft`, `TextAlign.left` and friends,
      excluding the icon-asset layer. Fails the §2 rule that CI is supposed to enforce; if
      EPIC-17 already landed this gate, assert the existing script instead of writing a
      second one.
  - `test/widget/rtl_mirroring_test.dart`:
    - `every list-row chevron mirrors` — pump `settings`, `vehicles`, `reminders.list`,
      `trips.list`, `costs` under `TextDirection.rtl` and assert the chevron points to the
      start edge. Fails on the one screen whose chevron is a raw asset rather than a
      directional icon — the drift a per-screen check cannot see.
    - `the tab bar mirrors and the plus stays centred` — under rtl, Settings is leftmost and
      the `+` is at the horizontal centre. Fails §7 directly.
    - `swipe-to-delete comes from the end edge` — on `history` and `vehicles` under rtl.
    - `a Latin run inside a Persian screen is isolated` — the plate `M-AB 1234` and the
      version string render LTR without reordering the surrounding Persian.
- **Then build**
  - Replace every non-directional geometry the tests found with `start`/`end` equivalents;
    replace mirrored-by-hand icons with directional ones; wrap Latin runs in first-strong
    isolates at render time, never in storage (§2).
- **Verify**
  ```bash
  flutter test test/policy/no_left_right_test.dart test/widget/rtl_mirroring_test.dart
  flutter test test/parity/
  node tools/compare_to_reference.mjs build/parity/settings-light-rtl.png settings \
       --theme light --dir rtl
  node tools/compare_to_reference.mjs build/parity/history-dark-rtl.png history \
       --theme dark --dir rtl
  # and the two ltr combinations, to prove nothing regressed — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings-light-rtl.png     # look at the side-by-side
  ```
  A pass is all 56 RTL captures green **and** all 56 LTR captures still green.
- **Done when**
  - [ ] Every RTL row in the triage table is `fixed` or `design-change`.
  - [ ] The RTL captures were reviewed by someone who reads the script, not only by the tool
        (`calm-visual-parity` definition of done). If nobody available reads Persian, record
        that in `design/review/findings.md` as an open item rather than claiming the check.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.8 — The human side-by-side pass over all 112 sheets

- **Goal** — the half of parity the tool is explicit that it cannot do: type weight,
  letter-spacing, icon shape, optical alignment, and whether the screen still reads calm.
- **Spec** — §17 per-locale gate (goldens "reviewed on every UI change").
- **Skills** — `calm-visual-parity` (rule 8), `calm-typography-and-rtl`, `calm-components`,
  `design-review-workflow` (the grading rubric, borrowed early).
- **Write these tests first**
  - `test/parity/sheet_inventory_test.dart`:
    - `a parity sheet exists for every comparison` — `design/reference/_parity/` holds 112
      files after a sweep run. Fails if the comparison tool silently skipped a screen, which
      would otherwise present as "we looked at everything".
  - `test/parity/findings_test.dart`:
    - `every finding has a grade` — each row in `design/review/findings.md` carries exactly
      one of BLOCKER / FIX / NOTE. Fails on an ungraded observation, which is how a floor
      violation gets shipped as a nice-to-have.
    - `no finding grades a floor violation below BLOCKER` — any finding whose category is
      contrast, tap target, text-scale reflow, colour-alone, RTL correctness or reduce-motion
      is graded BLOCKER. Encodes `design-review-workflow` rule 5 so it cannot be argued down.
- **Then build**
  - Open all 112 sheets in `design/reference/_parity/` — reference, app, heatmap — and record
    what the three mechanical checks cannot see. Look specifically for: a weight that is
    `medium` where the reference is `semi`; tracking on the display sizes; icon shape and
    stroke weight; optical alignment of a numeral against a label; and the shadow softness the
    Skia/Blink difference makes tempting to over-correct.
  - Write each observation into `design/review/findings.md` graded. Ignore the differing-pixel
    percentage entirely: it is 25–45% on a correct screen.
- **Verify**
  ```bash
  flutter test test/parity/sheet_inventory_test.dart test/parity/findings_test.dart
  ls design/reference/_parity/*.png | wc -l                # 112
  ```
  A pass is a graded findings table and a person who can say they looked at all 28 screens in
  four combinations.
- **Done when**
  - [ ] All 112 sheets opened and looked at.
  - [ ] Findings graded; every floor violation is a BLOCKER.
  - [ ] No tolerance was widened and no reference regenerated to make a sheet look better.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.9 — The `design-review-workflow` structured pass on the release build

- **Goal** — the one end-of-build design/QA pass this app gets, on the artifact a stranger
  would install, with the matrix and the on-device half that no screenshot can replace.
- **Spec** — §17 accessibility gate; §17 offline gate ("full manual pass of every screen in
  aeroplane mode on a device that has never been online"); §17 scale gate.
- **Skills** — `design-review-workflow`, `accessibility-as-code`, `i18n-rtl-l10n`,
  `flutter-performance`, `run-migration`.
- **Write these tests first**
  - `test/policy/review_matrix_test.dart`:
    - `the review folder holds one file per matrix cell` — `design/review/shots/` contains
      `NN--<screen>--<theme>--<dir>.png` for every screen (plus each dynamic screen's
      meaningful states: `history` empty and full, `costs` single-vehicle and all-vehicles,
      `settings.import` with and without a chosen file) × light/dark × ltr/rtl. Fails on a
      missed cell, which is how the one broken screen escapes.
    - `filenames sort into screen order` — the `NN` prefix follows §7's screen order. Fails on
      an ad-hoc name that makes the folder unreviewable.
  - `test/policy/signoff_test.dart` (written now, red until Task 18.10):
    - `a dated sign-off exists for the current commit` — `design/review/SIGNOFF-*.md` exists
      and names a date, a reviewer, a commit sha, a build flavour and a verdict line. Fails
      until the review is genuinely finished — this is the gate EPIC-19 depends on.
- **Then build**
  - Build the **release** build (no debug banner, standardised status bar: fixed clock, full
    battery) and shoot the matrix: every screen × {light, dark} × {LTR, RTL}, every still at
    the largest supported text scale with bold text on. Motion moments — the Save snackbar
    with Undo, the mark-done confirmation, the tab transitions — as short videos with
    reduce-motion off and on, never as stills.
  - The on-device pass on real cheap target-class hardware (§17's floor device: a 2019
    mid-range Android, 4 GB RAM), in real state: screen-reader and switch traversal of
    `log.fillup` and `reminders.edit` (text fields are the classic focus trap), largest system
    font on a 375×667 screen, and the estimated-value announcements §17 requires ("about
    187,400 kilometres, estimated") and the `ƒ` badge's accessible name.
  - Destructive steps **last**, in this order: install the previous build and upgrade in place;
    export → wipe → import; feed import a truncated and a hand-corrupted file; aeroplane mode
    from a clean install, walking every screen; then the deliberate crash and the symbol check.
  - Grade every finding into the same `design/review/findings.md`. Open no fixes yet.
- **Verify**
  ```bash
  flutter build apk --release
  flutter test test/policy/review_matrix_test.dart
  ls design/review/shots/*.png | wc -l
  ```
  A pass is a complete matrix folder, the motion videos, a device pass recorded with device,
  OS version and date at the top, and a deduped graded findings table.
- **Done when**
  - [ ] The review ran on the release build, once, at the end — not per screen.
  - [ ] Matrix complete: every screen and state × light/dark × LTR/RTL at largest text scale.
  - [ ] On-device pass done on real floor-device-class hardware, destructive steps last, with
        the aeroplane-mode walk of every screen included.
  - [ ] Every finding graded; every accessibility-floor miss is a BLOCKER.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 18.10 — One scoped fix round, then the dated sign-off

- **Goal** — the BLOCKERs and FIXes are closed as a single unit and the epic ends in a tracked
  artifact that EPIC-19 can depend on.
- **Spec** — §17 (all five gates).
- **Skills** — `design-review-workflow` (rules 6–9), `run-goldens-rebaseline`,
  `calm-visual-parity`, `testing-strategy`.
- **Write these tests first**
  - `test/policy/findings_resolution_test.dart`:
    - `no BLOCKER is unresolved` — every BLOCKER row in `design/review/findings.md` has a
      resolution and a verifying artifact (a re-shot cell or a test name). Fails while any
      floor violation survives — and a surviving BLOCKER means no sign-off and an escalation,
      never a second round.
    - `every FIX is resolved or explicitly downgraded to NOTE with a reason` — fails on a
      silent drop.
  - `test/policy/signoff_test.dart` — the file written in Task 18.9, now expected green.
  - Plus: for each BLOCKER/FIX being fixed, the regression test named in its row. A finding
    without a test name in its resolution is not resolved.
- **Then build**
  - Fix BLOCKERs and FIXes as one scoped unit. Re-run the gates and the tests. Re-shoot **only
    the affected cells**, overwriting — `design/review/shots/` stays one truth. Re-baseline any
    goldens an accepted visual fix moved, via `run-goldens-rebaseline`, and re-run the parity
    sweep so the two checks agree.
  - Open no new critique during verification; a new observation becomes a NOTE.
  - Write `design/review/SIGNOFF-<YYYY-MM-DD>.md`: date, reviewer, commit sha, build flavour,
    the matrix inventory, the findings table with resolutions, and the verdict line — either
    `SIGNED OFF` or `NOT SIGNED OFF` plus the escalated blocker. Move NOTEs to the backlog.
- **Verify**
  ```bash
  flutter analyze --fatal-infos --fatal-warnings
  flutter test
  flutter test test/parity/ && bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  flutter test test/policy/findings_resolution_test.dart test/policy/signoff_test.dart
  ```
  A pass is: analyzer clean, suite green, 112 parity comparisons green, and a sign-off file
  whose verdict line reads `SIGNED OFF`.
- **Done when**
  - [ ] Exactly one fix round happened.
  - [ ] Every BLOCKER and FIX is resolved with a named regression test; NOTEs are in the
        backlog.
  - [ ] Affected matrix cells re-shot and overwritten; goldens re-baselined where a fix moved
        them.
  - [ ] `design/review/SIGNOFF-<date>.md` exists, is tracked, and says `SIGNED OFF`.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

## Definition of done

- [ ] All 28 screens are in `test/parity/parity_screens.dart`, and a screen that is not fails
      a test.
- [ ] One sweep run produces 112 captures and `check_parity.sh` is green over all of them.
- [ ] `design/review/parity-sweep.md` has a verdict for every one of the 112 comparisons.
- [ ] The Calm contrast finding is closed in writing; if it was fixed, `odova.css`,
      `calm_palette.dart` and the 112 references moved in one change.
- [ ] No tolerance was widened, and no reference was regenerated except as a deliberate,
      documented design change.
- [ ] All 112 side-by-side sheets have been opened and looked at by a human, and the RTL ones
      by someone who reads the script — or the gap is recorded as an open item.
- [ ] The `design-review-workflow` pass ran once, on the release build, with the full matrix
      and the on-device half including the aeroplane-mode walk.
- [ ] Exactly one fix round; every BLOCKER and FIX resolved with a named regression test.
- [ ] `design/review/SIGNOFF-<date>.md` exists, is tracked, and reads `SIGNED OFF`.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-18.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
