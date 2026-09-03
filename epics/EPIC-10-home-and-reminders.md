# EPIC-10 — Home and the reminder screens

| | |
|---|---|
| **Epic** | EPIC-10 — Home and the reminder screens |
| **Depends on** | EPIC-07, EPIC-08, EPIC-09 |
| **Estimate** | **11.5 h (CC) · ~3 months (human)** |
| **Spec sections** | §9 *Home — what does my car need next* (`home`, `reminders.list`, `reminders.edit`) |
| **Screens** | `home`, `reminders.list`, `reminders.edit` |

Home is opened 2–6 times a month and ~70% of those opens never leave it. It is the screen the
product is judged on, and the parity bar here is the highest in the app. Everything in this
epic is presentation over facts the earlier epics already compute — this epic adds no
arithmetic to the due engine and persists nothing derived.

The rules every epic inherits (TDD, per-task test runs, `/simplify` then `/code-review`, a
screen is not done until it matches its reference, `SPEC.md` wins) are stated once in
`epics/README.md` and are binding here.

## Where we are now

The repo before EPIC-01 held the specification, the design systems, the 112 Calm reference
screenshots, the tooling and the skills, and **no Flutter app at all** — no `pubspec.yaml`, no
`lib/`. EPIC-01 created it; everything since inherits it.

At the moment this epic starts:

- `pubspec.yaml`, `lib/`, `test/` and a green `flutter analyze --fatal-infos
  --fatal-warnings` / `flutter test` exist (EPIC-01).
- The Calm theme lives in `lib/theme/calm/` — `CalmColors`, `CalmType`, `CalmSpace`,
  `CalmShapes`, `CalmMotion`, and **`lib/theme/calm/calm_status.dart` with the one and only
  `enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }`, `DueDriver`,
  `CalmStatusStyle.resolve` and `CalmStatusMark`**. The Calm widget library lives in
  `lib/ui/calm/` — `CalmScaffold`, `CalmAppBar`, `CalmCard`, `CalmRowGroup`, `CalmListRow`,
  `CalmDueCard`, `CalmAllClear`, `CalmEmptyState`, `CalmChip`, `CalmBadge`, `CalmStatusDot`,
  `CalmSegmented`, `CalmSwitch`, `CalmField`, `CalmSheet`, `CalmDialog`, `CalmSnackbar`,
  `CalmNumberPad`, `CalmTile`, `CalmTabBar`.
- The domain model of §3 (`Vehicle`, `ServiceItem`, `ServiceRecord` + `ServiceLine`, `FillUp`,
  `Expense`, `OdometerReading`, `OdometerCorrection`, `Trip`, `Settings`) is modelled and
  persisted behind repositories that are the single write path, and the pure engines are
  callable: `cumulative`, `estimateOdometer`, `dailyDistance`, `resolveAnchor`,
  `computeDueState`, `projectDueDate`, `nextDue`, `dueSummary`, `averageConsumption`,
  `costPerDistance`, `monthlyCost`, `unitPrice`.
- The six-locale ARB pipeline (`l10n.yaml`, `gen_l10n`) is live and every existing string
  ships in `en`, `de`, `fr`, `fa`, `ar`, `ckb`.
- **EPIC-08** delivered the single `go_router`, the four tab roots plus the docked central
  `+`, the modal/push/sheet/dialog kinds of §7, the tab-stack reset rules and the deep-link
  synthesis. `home` is registered as the first tab root and currently renders whatever
  placeholder EPIC-08 left in it.
- **EPIC-09** delivered first run, `vehicle.edit`, `vehicles` and `vehicle.switcher`, the
  seeded catalogue of `ServiceItem`s, and `Settings.active_vehicle_id`. Reaching Home always
  means a vehicle exists — §9 says the "no vehicle" state cannot happen.

Deliberately still missing when this epic starts:

- **The four `log.*` screens do not exist** — EPIC-11 builds them. Home's **Log it**, **Update
  odometer** and odometer-strip taps push the `log.service` / `log.odometer` routes *by name*
  with their prefill arguments; until EPIC-11 lands they resolve to EPIC-08's placeholder.
  Every test in this epic therefore asserts the **navigation intent** — route name plus
  arguments — never the destination screen's contents.
- `history`, `costs`, `costs.fuel`, `trips.*`, `report.*` and the `settings.*` children are
  later epics. Home's at-a-glance tiles read `averageConsumption`, `costPerDistance` and
  `monthlyCost` directly; they are read-outs, not links, so nothing here blocks on the Costs
  tab existing.
- `dialog.snooze` is built in **EPIC-08** (task 8.10), not here and not in the notifications
  epic: §7 makes the three global dialogs global, belonging to no feature, and building one
  twice is how two copies drift apart. This epic *calls* it from the card overflow and from a
  `reminders.list` swipe.

## What we will have when this is done

- Opening the app on a vehicle with work due lands on Home and answers "what does my car need
  next?" without scrolling: one primary card, up to two secondary cards, never more than
  three, on a 375 × 667 screen at text scale 1.0.
- A used car entered today opens on **one** calm `unknown` card — *When were these last done?*
  — and not on eleven red ones.
- With nothing due, Home shows the all-clear card with the next item, its date and the
  since-last-service line, and the glance tiles are still above the fold.
- Every card's state is carried by dot shape, word and colour together; a grayscale golden of
  the six states still tells them apart.
- No card ever shows a guessed figure it cannot support: at `confidence = default` it reads
  `Odova needs a reading to say when` and its button is **Update odometer**.
- `reminders.list` shows the whole catalogue grouped tracked → **Paused** → **Not tracked**,
  and `reminders.edit` sets intervals by distance and time, the notice override, the on/off,
  and refuses to save an item with nothing to remind you about.
- `flutter test test/features/home/`, `test/features/reminders/` and `test/parity/` are green,
  and `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over
  `home`, `reminders.list` and `reminders.edit` in all four combinations.
- `bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh` is clean:
  no `DueState` colour switch and no uncertainty sentence outside `lib/theme/calm/`.

## Skills to load

Open `flutter-conventions-index` first — it is the front door and it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules every task inherits: feature-first layering, dumb widgets, one Notifier per screen, single write path, injected `Clock`, typed failures. |
| `calm-due-state-and-status` | **The governing skill of this epic.** `DueState`, `CalmStatusStyle` as the single resolution point, the mark/label/copy triple, and the two "we do not know" states. |
| `calm-visual-parity` | Required: this epic builds three referenced screens. It also says what the check does *not* prove, which keeps nobody chasing a pixel diff to zero. |
| `calm-layout-and-motion` | The one-primary rule, the `CalmSpace` scale and 22pt gutter, Home's above-the-fold budget, and `CalmAllClear` as a designed good state. |
| `calm-components` | `CalmDueCard`, `CalmAllClear`, `CalmRowGroup`/`CalmListRow`, `CalmScaffold`, `CalmSheet`, `CalmChip` — Home composes these, it does not hand-roll surfaces. |
| `calm-typography-and-rtl` | The nine type roles used by both card densities, the `~` inside a bidi isolate, per-locale numerals and the Jalali display calendar, and the six glyphs that mirror. |
| `i18n-rtl-l10n` | Every string on these screens is an ARB message in six locales; ICU plurals with an explicit `=0`; directional geometry only. |
| `state-management-riverpod` | `HomeNotifier` and the reminders notifiers over immutable state, `family`/`autoDispose`, and the recompute-on-write path. |
| `ui-states-and-feedback` | Home's error state, the skeleton past 150 ms, snackbars with **Undo**, and choosing `CalmAllClear` over `CalmEmptyState`. |

## Tasks

### Task 10.1 — Build the Home presentation model

- **Goal** — Home's due stack is decided once, in a pure function, before any widget exists.
- **Spec** — §9 *Home* → *Ordering*, *The unknown-anchor card*, *The card*; §3 *Due state per
  item* for the `DueState` record this consumes.
- **Skills** — `flutter-conventions-index`, `calm-due-state-and-status`,
  `state-management-riverpod`.
- **Write these tests first** — `test/features/home/home_due_stack_test.dart`, over fixture
  vehicles built with an injected `Clock` fixed at 2026-09-02:
  - `sorts by projected_due_date ascending` — three items with projected dates 2026-08-12,
    2026-09-20, 2026-10-10 come back in that order. Fails if a special case floats overdue
    items instead of letting the past date do it.
  - `caps the stack at three cards however many are due` — nine overdue items yield exactly
    one primary and two secondaries, and `moreDueCount == 6`.
  - `downgrades a purchase-anchored item to unknown` — an item whose `resolveAnchor` rung is
    `purchase` returns `DueState.overdue` from the engine and `unknown` from the model. Fails
    if the model passes the engine's status through.
  - `downgrades a first_reading-anchored item to unknown` — same, on the earliest-reading rung.
  - `collapses unknown items into one card, always last` — five `unknown` items produce one
    `UnknownAnchorCard` carrying the first three labels and `moreCount == 2`, and no `unknown`
    item appears in the sorted stack.
  - `needsOdometer never takes the primary slot while a time-driven due item exists` — a
    `needsOdometer` item with an earlier projected date than a time-driven `due` item comes
    second. Fails if the sort key alone decides the primary.
  - `needsOdometer does take the primary slot when nothing else is due or overdue`.
  - `breaks ties by severity then by label under the locale collator` — two items with the same
    projected date, one `due` one `dueSoon`; then two `due` items labelled `Ölwechsel` and
    `Ölfilter` under `de`.
  - `excludes ok and paused from the stack` — an `is_active == false` item and an `ok` item are
    absent; `trackedCount` still counts both for the see-all row.
  - `pins a deep-linked item to the primary slot for one build` — the pinned item leads even
    with a later projected date, and a second build without the pin restores the natural order.
  - `snoozed keeps its state and gains a snoozed-until line` — a snoozed overdue item is still
    `overdue`, still in the stack, and carries `snoozedUntil`.
- **Then build** — `lib/features/home/domain/home_view_model.dart` (pure, no Flutter import):
  `HomeStack`, `DueCardModel`, `UnknownAnchorCard`, and `HomeStack buildHomeStack({required
  Vehicle vehicle, required List<ServiceItem> items, required DueStateResolver resolve,
  required DateTime today, String? pinnedItemId})`. The Home-only downgrade is a named
  predicate `isUnknownOnHome(AnchorRung rung)` with a `///` comment saying it is presentation
  only and the engine is untouched. Nothing in this file switches on `DueState` to pick a
  colour.
- **Verify** — `flutter test test/features/home/home_due_stack_test.dart`; then
  `flutter analyze --fatal-infos --fatal-warnings`. A pass is 11 green tests and a clean
  analyzer.
- **Done when**
  - [ ] All eleven cases above pass.
  - [ ] `buildHomeStack` is pure — no `DateTime.now()`, no repository, no `BuildContext`.
  - [ ] The unknown-on-Home downgrade lives in this file only, and the due engine is unchanged.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 10.2 — Write Home's copy: the status, anchor and uncertainty messages

- **Goal** — Every sentence Home and the reminder screens say is one ICU message in six
  locales, and no card can say something the data does not support.
- **Spec** — §9 *The card*, *Marking an estimate as an estimate*, *RTL and localisation*;
  §4.1.4 *Showing an estimate as an estimate*.
- **Skills** — `calm-due-state-and-status`, `i18n-rtl-l10n`, `calm-typography-and-rtl`.
- **Write these tests first** — `test/features/home/home_copy_test.dart`:
  - `overdue by distance reads a positive overshoot` — `Overdue by 1,400 km`, never a negative
    or an `in −21 days`.
  - `overdue on both axes uses the distance phrasing` — `Overdue by 1,400 km and 3 weeks` with
    distance leading.
  - `due reads Due now with no number`.
  - `dueSoon by time uses the bucketed relative formatter` — `home.dueSoonRelative` returns
    Today / Tomorrow / `in 5 days` (≤ 13) / `in about 3 weeks` (≤ 55 days) / `in about
    5 months`, asserted at each bucket boundary.
  - `dueSoon by distance at confidence default reads the not-knowing sentence` —
    `home.dueSoonNoConfidence` == `Odova needs a reading to say when`, with no placeholders,
    and the resolved action key is `action.updateOdometer`.
  - `dueSoon by distance at assumed carries no exact date` — `around mid-October`.
  - `dueSoon by distance at measured carries a fuzzy date` — `around 22 October`.
  - `needsOdometer reads a request, not an accusation` — `Needs an odometer reading` and
    **Update odometer**.
  - `every message resolves in all six locales` — a loop over `en, de, fr, fa, ar, ckb` asserts
    no key falls back to English for `home.dueSoonNoConfidence`, `home.dueSoonRelative`,
    `home.moreDue`, `home.unknownMore`, `reminders.seeAll`, `reminders.disclaimer`,
    `action.logIt`, `action.updateOdometer`.
  - `counts have an explicit =0 plural case` — `reminders.seeAll(0)`, `home.moreDue(0)` and
    `home.unknownMore(0)` render without a stray digit.
  - `no user sentence is a Dart literal` — a grep test over `lib/features/home/` and
    `lib/features/reminders/` fails on `Odova needs a reading`.
- **Then build** — the messages in `lib/l10n/app_en.arb` and its five siblings; the copy
  getters on `CalmStatusStyle`/`DueState` in `lib/theme/calm/calm_status.dart` if the earlier
  epic left them unimplemented; `lib/features/home/ui/home_copy.dart` mapping a `DueCardModel`
  to (message key, arguments) — a mapper, never a string builder. Number + unit pairs come
  from the existing formatter as one isolate-wrapped atom; the `~` lives inside the ICU
  message, never `'~$odometer'` in Dart.
- **Verify** — `flutter gen-l10n && flutter test test/features/home/home_copy_test.dart`;
  `bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh`. A pass is
  green tests and a clean encoding gate.
- **Done when**
  - [ ] Every message above exists in all six ARB files in this task's commit.
  - [ ] No figure and no date is produced at `confidence = default`.
  - [ ] The `~` and the minus sign sit inside the number's isolate, asserted in `fa`.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 10.3 — Build the odometer strip and the estimated-value popover

- **Goal** — Home shows the current odometer and how fresh it is, and marks an estimate as an
  estimate everywhere it appears.
- **Spec** — §9 *Anatomy* → *Odometer strip*, *Marking an estimate as an estimate*,
  *Interactions*; §3 *Current odometer*.
- **Skills** — `calm-due-state-and-status`, `calm-components`, `calm-typography-and-rtl`,
  `ui-states-and-feedback`.
- **Write these tests first** — `test/features/home/odometer_strip_test.dart`:
  - `renders an entered reading plainly` — `stale_days == 0` gives `187,412 km` with no tilde
    and `entered 12 Sept`.
  - `renders a live projection with a tilde, rounded` — `is_projected` true gives
    `~187,400 km` (nearest 100 km) and `last entered 12 Sept`.
  - `rounds to the nearest 50 mi on a miles vehicle`.
  - `renders an expired estimate with no tilde and no projection` — last reading 200 days old
    gives `187,412 km · last entered 12 Jul 2025`.
  - `carries the estimated accessibility label` — `about 187,400 kilometres, estimated` on the
    projected case, absent on the entered case.
  - `tapping the strip pushes log.odometer with the last reading and today` — asserts route
    name and arguments only.
  - `tapping the estimated value opens the popover with one sentence and one action` —
    `Estimated from about 41 km a day since 12 July.` + **Update odometer**.
  - `the expired popover says Odova has stopped guessing` — `Your last reading is too old, so
    Odova has stopped guessing. Enter what the dash says now.` + **Update odometer**.
  - `the popover for a dash on the consumption tile is dismissal only` — `Your first
    consumption figure arrives at your next full fill-up.` and no action button.
  - `the strip is at least 48dp tall and its whole width is the target`.
- **Then build** — `lib/features/home/ui/odometer_strip.dart` (`OdometerStrip`,
  `EstimatedValueText`) and `lib/features/home/ui/estimate_popover.dart`. `EstimatedValueText`
  is reused by the tiles and by the cards, so the tilde rule has one implementation. Geometry
  is directional (`EdgeInsetsDirectional`, `start`/`end`) only.
- **Verify** — `flutter test test/features/home/odometer_strip_test.dart`;
  `bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh`.
- **Done when**
  - [ ] Entered, projected and expired render as three visibly different things.
  - [ ] Every estimated value carries the `~` **and** the a11y label; the expired one carries
        neither the `~` nor a projection.
  - [ ] The strip's tap pushes `log.odometer` by name with its prefill arguments.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 10.4 — Compose the `home` screen

- **Goal** — Home renders, in one screen and above the fold, the answer to what the car needs
  next.
- **Spec** — §9 *Anatomy*, *The card*, *Ordering*, *Interactions*, *What is deliberately not on
  Home*.
- **Skills** — `calm-layout-and-motion`, `calm-components`, `calm-due-state-and-status`,
  `calm-visual-parity`, `state-management-riverpod`.
- **Write these tests first** — `test/features/home/home_screen_test.dart`:
  - `renders the primary card at primary density and secondaries at secondary density` —
    primary title `headline`, status `titleLg`, height 148; secondary title `body`, status
    `caption`, height 72.
  - `shows at most three cards` — nine due items render three `CalmDueCard`s and a red see-all
    row reading `See all — 9 more due or overdue`.
  - `the see-all row counts tracked items, not due items` — 14 tracked, 3 due → `See all
    reminders (14)`.
  - `the app bar title is a tap target only with two or more vehicles` — one vehicle: plain
    text, no chevron, no gesture; two: opens `vehicle.switcher`.
  - `the other-vehicles row appears only when another vehicle has a due or overdue item` —
    `Van · 1 overdue` opening `vehicle.switcher`.
  - `the fold guarantee holds` — at 375 × 667, text scale 1.0, the primary and both secondary
    cards are fully inside the viewport with the tab bar laid out; asserted in `en`, `de` and
    `ckb`.
  - `at text scale 2.0 the screen scrolls in reading order and nothing is clipped` — no
    fixed-height card, primary first, no overflow.
  - `Log it pushes log.service prefilled with the item, today and the last known odometer` —
    route name and arguments.
  - `a needsOdometer card's button is Update odometer and pushes log.odometer`.
  - `the card overflow offers Log it, Snooze, Edit reminder and Turn this off` — Turn this off
    writes `is_active = false` through the repository and shows a `CalmSnackbar` with **Undo**.
  - `a tile with a value is not tappable` and `a tile showing — opens its popover`.
  - `re-tapping the Home tab scrolls to top`.
  - Grayscale: `test/features/home/home_grayscale_test.dart` — the six-state card set is still
    identifiable from mark + label with colour stripped.
- **Then build** — `lib/features/home/ui/home_screen.dart` (`HomeScreen`, a dumb
  `ConsumerWidget` over one notifier), `lib/features/home/ui/due_stack.dart`,
  `lib/features/home/ui/glance_tiles.dart`, `lib/features/home/ui/last_fillup_row.dart`,
  `lib/features/home/ui/other_vehicles_row.dart`, and
  `lib/features/home/application/home_notifier.dart` (a `StreamNotifier` over the repositories,
  exposing an immutable `HomeState`). Cards are `CalmDueCard` at its two densities; every state
  colour comes from `CalmStatusStyle.of(context, state)`. Tile labels reserve two lines always.
  No FAB, no chips, no charts, no banners — the *deliberately not on Home* table is a checklist.
- **Verify**
  ```bash
  flutter test test/features/home/
  flutter test test/parity/home_parity_test.dart      # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/home-light-ltr.png home \
       --theme light --dir ltr
  node tools/compare_to_reference.mjs build/parity/home-dark-ltr.png home \
       --theme dark --dir ltr
  node tools/compare_to_reference.mjs build/parity/home-light-rtl.png home \
       --theme light --dir rtl
  node tools/compare_to_reference.mjs build/parity/home-dark-rtl.png home \
       --theme dark --dir rtl
  # or, once all four captures exist:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-light-ltr.png    # look at the side-by-side
  ```
  A pass is: theme ok, every surface over 0.5% within Δ24 of a Calm token, and ≥75% of the
  reference's band edges matched within 4px. The differing-pixel percentage is informational
  and is 25–45% on a correct screen — do not chase it.
- **Done when**
  - [ ] The stack caps at three cards and the see-all row carries the overflow count.
  - [ ] The fold guarantee holds at 375 × 667 in `en`, `de` and `ckb`.
  - [ ] Every navigation edge in §9 *Interactions* is asserted by route name and arguments.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 10.5 — Add the conditional strips and the inline odometer save

- **Goal** — Home can tell the user the three things it sometimes needs to, without ever
  displacing the primary card.
- **Spec** — §9 *Anatomy* → *Conditional strips*, *Stale odometer*, *Done-from-notification
  confirmation*, *Away digest*; *Data in / data out* for the local UI keys.
- **Skills** — `ui-states-and-feedback`, `calm-components`, `state-management-riverpod`,
  `calm-visual-parity`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/home/home_strips_test.dart`:
  - `at most two strips render, in priority order` — all three eligible → confirmation and
    digest render, the staleness strip queues to the next appearance.
  - `strips never displace the primary card` — with two strips at 375 × 667 the primary card is
    still fully visible and the tiles are the thing pushed below the fold.
  - `the staleness strip appears at stale_days >= 60`.
  - `the staleness strip appears at stale_days >= 30 with projected drift over 500 km` — and
    not at 30 days with 400 km of drift.
  - `strip Save writes an OdometerReading with source manual and shows Undo` — through the
    repository, never a DAO.
  - `a non-monotonic strip Save yields to the full log.odometer modal` — the strip does not own
    the typo/correction/backdate dialogue.
  - `strip ✕ hides it for seven days on that vehicle only` — writes
    `home.staleness_dismissed_until.<vehicle_id>`; a second vehicle still shows its strip.
  - `the confirmation strip is not dismissible and appears once` — carries the recorded
    odometer, the recorded absence of a cost and the next due pair; **Add the real numbers**
    pushes `log.service` in edit mode on that record, **That's right** clears
    `odometer_estimated` and `cost_estimated`.
  - `the away digest shows at most three lines, once per absence`.
  - `local UI state is not in the backup` — a test over the export writer asserts
    `home.staleness_dismissed_until.*`, `home.digest_shown_at` and
    `home.first_run_hint_dismissed` are absent from the file.
  - `distance-driven due and overdue items render as needsOdometer while stale` — and
    `dueSoon` still renders normally.
- **Then build** — `lib/features/home/ui/home_strips.dart` (`StalenessStrip`,
  `DoneConfirmationStrip`, `AwayDigestStrip`) plus a `HomeStripQueue` in
  `lib/features/home/domain/` that applies the priority and the cap of two. The dismissal keys
  live in the key-value store the earlier epics built, explicitly outside the backup writer.
  All three strips are ≥ 48 × 48 dp on every control including `✕`.
- **Verify**
  ```bash
  flutter test test/features/home/home_strips_test.dart
  flutter test test/parity/home_parity_test.dart
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-dark-rtl.png
  ```
  Parity is re-run because this task changes `home`; the reference is the strip-free default
  state, so the capture must render Home with no strip eligible.
- **Done when**
  - [ ] Two strips maximum, priority order enforced, the third queues.
  - [ ] The primary card is never displaced.
  - [ ] Dismissal state is per-vehicle and absent from the export file.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 10.6 — Build Home's other states: all-clear, first run, unknown anchors, error

- **Goal** — The most common state in the app — nothing due — is the best-designed screen in
  it, and a broken read never blanks Home.
- **Spec** — §9 *Every state*, *The unknown-anchor card*, *Error*.
- **Skills** — `calm-layout-and-motion`, `ui-states-and-feedback`, `calm-components`,
  `calm-due-state-and-status`, `calm-visual-parity`.
- **Write these tests first** — `test/features/home/home_states_test.dart`:
  - `nothing due renders CalmAllClear, never CalmEmptyState` — and it carries exactly four
    things: the mark, `Nothing due`, the next item with its date, and the since-last-service
    line (`3,120 km · 4 months`).
  - `all-clear keeps the glance tiles above the fold at 375 × 667`.
  - `service history but no fill-ups` — the consumption tile reads `—` and the reward line is
    the service line alone.
  - `first run renders the unknown-anchor card in the primary slot` — `Set up your reminders —
    tell me when things were last done`, tiles all `—`, and the line `Log a fill-up and your
    consumption starts here.` as text, not a button.
  - `no fake zeroes on first run` — no tile renders `0`.
  - `the unknown-anchor card names three items and a + n more` — tapping the card opens
    `reminders.list`; tapping a named item opens `reminders.edit` for it.
  - `only tracked items appear in the unknown card` — untracked catalogue rows are absent.
  - `one item renders one primary card and no layout special case`.
  - `a sold vehicle replaces the due stack` — `This vehicle is marked sold (14 June).`, the
    ownership summary, no reminders and no nudges; History and Costs edges still work.
  - `an unreadable store renders one message and one button` — `Odova can't read your data.` →
    **Open Backup & restore** pushing `settings.backup`, and no cards at all.
  - `one bad row never blanks the screen` — an item whose derived state throws renders a grey
    card `Something's wrong with this reminder` with a chevron to `reminders.edit`, and the
    other cards render normally.
  - `the skeleton appears only past 150 ms` — with `fakeAsync`, a 100 ms load never shows it.
- **Then build** — `lib/features/home/ui/home_states.dart` wiring `CalmAllClear`, the
  unknown-anchor card, the sold-vehicle panel, the error panel and the per-row failure card
  into the one `switch` over `HomeState` that `ui-states-and-feedback` prescribes.
  `CalmAllClear` is used as-is from `lib/ui/calm/` — no shrug art, no nag, no grey box.
- **Verify**
  ```bash
  flutter test test/features/home/home_states_test.dart
  flutter test test/parity/home_parity_test.dart
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/home-light-rtl.png
  ```
- **Done when**
  - [ ] All-clear carries its four elements and nothing else, and reads as the good state.
  - [ ] No state renders a fake zero or a guessed figure.
  - [ ] The error state offers exactly one action, and it is **Open Backup & restore**.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 10.7 — Build `reminders.list`

- **Goal** — The full catalogue for one vehicle, grouped so no legend is needed.
- **Spec** — §9 `reminders.list` — *Groups, in order*, *Interactions*, *States*, *Data*.
- **Skills** — `calm-components`, `calm-due-state-and-status`, `calm-visual-parity`,
  `i18n-rtl-l10n`, `ui-states-and-feedback`.
- **Write these tests first** — `test/features/reminders/reminders_list_test.dart`:
  - `groups render in order` — tracked-and-active (sorted by `projected_due_date` exactly as
    Home sorts), then **Paused**, then **Not tracked**.
  - `ok items appear here with their next due` — the difference between this screen and Home.
  - `paused rows are greyed and carry no status`.
  - `not-tracked rows carry + Track in place of a status`.
  - `the header is the same ICU message as the first-run catalogue` — asserts the
    `reminders.disclaimer` key, not the English text.
  - `+ Track sets is_tracked and opens reminders.edit` — one repository write, then the modal.
  - `a row tap opens reminders.edit for that item`.
  - `the app-bar + opens reminders.edit in create mode`.
  - `swipe from the end reveals Done today, Snooze and Turn off` — **Done today** pushes the
    mark-done path (route name plus arguments; EPIC-11 owns the destination), **Snooze** opens
    `dialog.snooze`, **Turn off** writes `is_active = false` with an **Undo** snackbar.
  - `swipe actions are start/end, never left/right` — asserted by running the test in `fa`.
  - `empty, single and 26-item states` — `No reminders yet.` plus the `+`; a one-row list with
    no group headers; sticky group separators when it scrolls.
  - `all paused renders the Paused group alone` under `Nothing is being tracked on this
    vehicle.`
- **Then build** — `lib/features/reminders/ui/reminders_list_screen.dart` and its
  `RemindersListNotifier`. Rows are `CalmListRow` inside `CalmRowGroup`, never bare. Status dot
  and word come from `CalmStatusStyle`; the group header carries the word for the states that
  do not print one.
- **Verify**
  ```bash
  flutter test test/features/reminders/reminders_list_test.dart
  flutter test test/parity/reminders_list_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/reminders.list-light-ltr.png reminders.list \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/reminders.list-light-ltr.png
  ```
- **Done when**
  - [ ] The three groups render in order with the right vocabulary and no legend.
  - [ ] Swipe actions are directional and work in `fa`.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 10.8 — Build `reminders.edit`

- **Goal** — One place sets a reminder's rules, and it never saves an item that cannot remind
  anybody of anything.
- **Spec** — §9 `reminders.edit` — the field table, *Validation*, *Last done*, *Delete*,
  *States*, *Data*; §3 `ServiceItem`; §4.1 for the automatic notice window.
- **Skills** — `calm-components`, `i18n-rtl-l10n`, `calm-visual-parity`,
  `state-management-riverpod`, `calm-due-state-and-status`.
- **Write these tests first** — `test/features/reminders/reminders_edit_test.dart`:
  - `renders every field of the table` — kind/label, every-distance, every-months,
    once-at-odometer, once-on-date, last-done date, last-done odometer, notify, the two notice
    overrides, priority, rollover, repeats, notes.
  - `save is never disabled` — with an empty form the Save control is enabled and tapping it
    surfaces the error.
  - `saving with no scheduling field set shows the inline message` — `Set an interval or a
    target date — otherwise there's nothing to remind you about.` under the interval block.
  - `a baseline odometer below the vehicle's first reading is rejected inline`.
  - `a baseline date in the future is rejected inline`.
  - `a future target date is allowed` — the one-off date field, unlike the baseline.
  - `blank notice fields show the automatic window as a placeholder` — for a 10,000 km /
    12-month item, `Automatic — 1,000 km / 30 days`, from `clamp(0.10 × interval, 200 km,
    1000 km)` and `clamp(0.10 × months × 30.44, 7, 30)`.
  - `an explicit notice override is stored unclamped` — 2,000 km round-trips.
  - `blank distance turns the distance axis off` and `blank months turns the time axis off` —
    asserted on the written `ServiceItem`, not on the widget.
  - `editing an interval or a baseline resets snooze_count to zero and reschedules`.
  - `last done lists the five newest ServiceRecords for this item` — date, odometer, cost, each
    a row into the history entry detail.
  - `an unreferenced item deletes outright with Undo`.
  - `a referenced item cannot be deleted` — the control becomes **Turn this reminder off** with
    `Two services are recorded against this. Turning it off keeps them.`
  - `the four states render` — create with the catalogue picker focused; edit tracked; edit
    untracked with `Not tracked — you won't be reminded` + **Start tracking**; edit paused with
    **Turn back on**.
  - `a dirty dismiss reaches dialog.discard` and a clean one dismisses silently.
  - `labels sit above inputs` — asserted in `de` at text scale 2.0 with no truncation.
- **Then build** — `lib/features/reminders/ui/reminders_edit_screen.dart`,
  `lib/features/reminders/application/reminders_edit_notifier.dart` over an immutable draft.
  Fields are `CalmField`/`CalmSegmented`/`CalmSwitch`; validation is a pure function over the
  draft so the same rules can be tested without a widget. Unit suffixes sit at the `end` inside
  the field's own ICU message, never concatenated.
- **Verify**
  ```bash
  flutter test test/features/reminders/reminders_edit_test.dart
  flutter test test/parity/reminders_edit_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/reminders.edit-light-ltr.png reminders.edit \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/reminders.edit-dark-ltr.png
  ```
- **Done when**
  - [ ] Save is never silently disabled and every rejection is one inline sentence.
  - [ ] The automatic notice window is a placeholder, not a stored value.
  - [ ] A referenced item offers **Turn this reminder off** and never a delete.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 10.9 — Wire recompute, deep links and the performance budget

- **Goal** — Home is always correct without the user doing anything, and it is fast enough that
  the skeleton is never seen on the common path.
- **Spec** — §9 *Interactions* → *Recompute triggers*, *Navigation edges*, *From a
  notification*.
- **Skills** — `state-management-riverpod`, `flutter-conventions-index`,
  `ui-states-and-feedback`.
- **Write these tests first** — `test/features/home/home_recompute_test.dart`:
  - `recomputes on every trigger` — one case each for screen focus, a write to the active
    vehicle, a vehicle switch, local midnight crossing (via the injected `Clock`), app resume,
    a locale/unit/calendar change, and an import commit.
  - `nothing derived is persisted` — after a full recompute the store holds no due date and no
    status column.
  - `a reminder deep link pins the card and does not open a modal` — sets
    `active_vehicle_id` from the payload, selects the Home tab, pins the target to the primary
    slot, and pushes nothing.
  - `an odometer nudge deep link opens log.odometer` — route name only.
  - `a payload naming a deleted vehicle lands on plain Home with no error message`.
  - `back from a deep-linked modal lands on Home` — the synthesised stack is `[home]`.
  - `the model builds under budget` — 2,000 rows across 26 items build the stack in under
    16 ms, asserted as a plain timing assertion in a pure test, not a widget test.
  - `the memo is invalidated by any write to the vehicle and by nothing else`.
- **Then build** — the recompute wiring in `home_notifier.dart` (an injected `Clock` for the
  midnight crossing, a lifecycle observer for resume), the deep-link handling registered
  against EPIC-08's router, and the memoisation of `buildHomeStack` keyed on the vehicle's
  write generation.
- **Verify** — `flutter test test/features/home/home_recompute_test.dart`; then
  `flutter analyze --fatal-infos --fatal-warnings` and `flutter test`.
- **Done when**
  - [ ] All seven recompute triggers are covered by a test.
  - [ ] A notification body tap never opens a prefilled form.
  - [ ] The build stays under 16 ms for 2,000 rows.
- **Estimate** — 0.5 h (CC) · ~half a week (human)

## Definition of done

- [ ] `home`, `reminders.list` and `reminders.edit` are reachable and behave as §9 specifies,
      including every navigation edge in the *Navigation edges* table.
- [ ] The due stack never exceeds three cards, and `ok` and `paused` never appear on Home.
- [ ] Every state resolves through `CalmStatusStyle`; `check_status_encoding.sh` is clean.
- [ ] No screen in this epic renders a figure or a date at `confidence = default`.
- [ ] Every string is an ICU message present in all six ARB files.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-10.md`.** It starts
empty. Append one line per task as it completes — what was built, what was deferred, and
anything the next epic needs to know. It is the running log for this epic and the handover to
the next one.
