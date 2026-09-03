# EPIC-11 — Logging: fill-up, service, expense, odometer

| | |
|---|---|
| **Epic** | EPIC-11 — Logging: fill-up, service, expense, odometer |
| **Depends on** | EPIC-06, EPIC-10 |
| **Estimate** | **13 h (CC) · ~3 months (human)** |
| **Spec sections** | §10 *Logging — fill-up, service, expense, odometer, trip* (everything except `trips.edit`) |
| **Screens** | `log.fillup`, `log.service`, `log.expense`, `log.odometer` |

These four forms write everything the rest of the app computes over. The design target is
§10's opening sentence: **a fill-up logged one-handed at a pump, in the rain — four taps and
two numbers, under fifteen seconds.** Every decision below is downstream of that.

`trips.edit` is specified in §10 and is **not** in this epic — it belongs with the Costs and
Trips work. It reuses this epic's modal shell and odometer field, so build both as shared
components, not as fill-up-specific ones.

The rules every epic inherits (TDD, per-task test runs, `/simplify` then `/code-review`, a
screen is not done until it matches its reference, `SPEC.md` wins) are stated once in
`epics/README.md` and are binding here.

## Where we are now

The repo before EPIC-01 held the specification, the design systems, the 108 Calm reference
screenshots, the tooling and the skills, and **no Flutter app at all**. EPIC-01 created it.

At the moment this epic starts:

- The domain model of §3 is modelled and persisted: `FillUp`, `ServiceRecord` + `ServiceLine`,
  `Expense`, `OdometerReading`, `OdometerCorrection`, `ServiceItem`, `Vehicle`, `Settings`.
  Storage is canonical — metres, millilitres, grams, watt-hours, minor units + ISO 4217 — and
  every write goes through a repository that persists first and republishes, never through a
  DAO in a widget.
- The pure engines are callable: `cumulative`, `estimateOdometer`, `dailyDistance`,
  `resolveAnchor`, `computeDueState`, `projectDueDate`, `buildFuelSegments`,
  `segmentConsumption`, `averageConsumption`, `unitPrice`.
- The Calm theme (`lib/theme/calm/`) and widget library (`lib/ui/calm/`) exist, including
  `CalmField`, `CalmSegmented`, `CalmSwitch`, `CalmChip`, `CalmSheet`, `CalmDialog`,
  `CalmSnackbar`, `CalmButton`, `CalmButtonExplain` and **`CalmNumberPad`**.
- The six-locale ARB pipeline is live; the money and unit value objects and their locale
  formatters exist.
- **EPIC-06** delivered the backup file of §6 — the export writer, the import-replace path and
  the round-trip test suite. That matters here for one reason: the rows these four forms write
  are the rows that file carries, so every new field lands in the writer, the reader and the
  round-trip fixtures in the same commit as the form that writes it.
- **EPIC-10** delivered `home`, `reminders.list` and `reminders.edit`. Their **Log it**,
  **Update odometer**, **Done today** and odometer-strip actions already push `log.service` and
  `log.odometer` **by name with their prefill arguments**, and EPIC-10's tests assert the
  navigation intent only. This epic supplies the destinations and turns those assertions into
  end-to-end ones.
- The central **+** in EPIC-07's tab bar is wired and opens the log modal route.

Deliberately still missing when this epic starts:

- `history`, `costs`, `costs.fuel` and `trips.*` do not exist. Every §10 edit-mode entry point
  from those screens is built here as a mode of the form (`log.fillup` in edit mode over a
  given id) and is reached by route in a test; the calling screens arrive later.
- `trips.edit` and the `Trip` picker's *screen* are later. The **Trip** field on `log.fillup`
  and `log.expense` is built and writes `trip_id`, but its picker lists only what the trip
  repository already holds.
- There are no photos and no receipt scans anywhere in v1 — no attach button on any form.

## What we will have when this is done

- The central **+** opens one modal on **Fill-up** from anywhere in the app, with four
  segments whose chrome is identical enough that it reads as one component.
- A full fill-up — odometer, quantity, and either price or total — is enterable in four taps
  and two numbers, and Save is never greyed out anywhere in it.
- The price/total/price-per-unit trio computes the third value from the other two, marks it
  `ƒ`, and stores the *displayed rounded* figures, so the app's own price per litre agrees with
  the receipt.
- Ticking an item on `log.service` writes a `ServiceRecord` line and re-anchors that reminder
  **from the odometer actually entered**, not from the due odometer, and the confirmation panel
  shows the resulting next-due pair.
- `log.odometer` is two fields over `CalmNumberPad` and clears a stale-odometer state on Home
  immediately.
- An odometer below the last reading is never a bare error: it is the three-way sheet, and a
  cluster replacement writes an `OdometerCorrection`.
- `flutter test test/features/logging/` and `test/parity/` are green, and
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over `log.fillup`,
  `log.service`, `log.expense` and `log.odometer` in all four combinations.

## Skills to load

Open `flutter-conventions-index` first — it is the front door and it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules: dumb widgets, one Notifier per screen, the single write path these forms all end in, injected `Clock`, awaited async. |
| `forms-and-input` | **Owns the general mechanics**: controller/focus disposal, pure sync validators, localized validator messages, `AutovalidateMode`, per-field rebuilds, keyboard types and input formatters. |
| `calm-components` | `CalmField`, `CalmSegmented`, `CalmSwitch`, `CalmChip`, `CalmSheet`, `CalmSnackbar`, `CalmButton` and `CalmNumberPad` — the skin these forms wear, and the "no `log.*` form disables Save" rule. |
| `calm-visual-parity` | Required: this epic builds four referenced screens. It also states what the check proves and what it cannot, so nobody chases a pixel diff to zero. |
| `value-objects-money-and-units` | Metres, millilitres, grams, watt-hours and `Money` with an ISO 4217 exponent; conversion on read; the per-entry unit override. |
| `i18n-rtl-l10n` | Every error string is one ICU message in six locales; decimal separators and digit shapes across `en/de/fr/fa/ar/ckb`; isolate-wrapped number+unit atoms; directional geometry. |
| `error-handling-typed-results` | Save returns a `Result`; the disk-full path keeps the user's input and shows one sentence. Never a swallowed `catch`. |
| `state-management-riverpod` | One notifier per segment over an immutable draft, the in-memory per-segment drafts, and the single transactional save through the repository. |
| `calm-due-state-and-status` | The mark-done path: re-anchoring, the confirmation panel's fuzzy projection, and the estimate chip's `~` and uncertainty copy. |

## Tasks

### Task 11.1 — Build the log modal shell

- **Goal** — Four forms behave as one component: same chrome, same Save, same cancel, same
  transaction.
- **Spec** — §10 *The log modal shell* — the rule table, *Cancel*, *Save*, *Delete*, *Dates and
  a suspect clock*.
- **Skills** — `calm-components`, `forms-and-input`, `state-management-riverpod`,
  `error-handling-typed-results`.
- **Write these tests first** — `test/features/logging/log_modal_shell_test.dart`:
  - `opens on Fill-up from the + whatever the caller` — from `home`, `history` and `costs`.
  - `the segment bar shows in create mode and is absent in edit mode`.
  - `switching segments keeps each segment's draft in memory` — type into Fill-up, switch to
    Expense, switch back: the text is still there.
  - `no draft reaches the database before Save` — after three segment switches the store is
    untouched.
  - `Save appears twice` — in the app bar and as a full-width primary button pinned above the
    keyboard.
  - `Save is never disabled on any of the four segments` — with an empty form the control is
    enabled.
  - `tapping Save on an invalid form scrolls to the first failing field, focuses it and shows
    one inline error` — and shows no dialog.
  - `validation runs on tap-Save and on blur, never on keystroke` — typing `1` into an odometer
    field mid-entry produces no error.
  - `the first field is autofocused, except when opened prefilled` — a mark-done or deep-link
    open focuses nothing.
  - `Return advances and the last field's key is Done`.
  - `a clean dismiss is silent; a dirty dismiss opens dialog.discard` — for ✕, swipe-down and
    system back alike, and Discard drops **every** segment's draft.
  - `Save is one transaction` — the record and its `OdometerReading` commit together, then a
    due-state recompute and a notification reschedule run; a fake repository asserts the order.
  - `Save dismisses to the caller's scroll position with a six-second Undo snackbar`.
  - `Undo soft-deletes the record and its reading`.
  - `a write failure keeps the modal open with every field intact` — snackbar `Couldn't save.
    Your phone may be out of space.`
  - `in clock-suspect mode every date field defaults to the newest occurred_on and Save is
    blocked with the reason inline`.
  - `a date more than a day after both today and the newest occurred_on warns without
    blocking` — `That's 412 days after anything else you've logged. Is the date right?`
  - `edit mode renders the Delete row last, in the destructive colour` — opening
    `dialog.confirmDelete` naming what dies, then dismissing with Undo.
- **Then build** — `lib/features/logging/ui/log_modal.dart` (`LogModalShell`, `LogSegment`
  enum), `lib/features/logging/application/log_modal_notifier.dart` holding the four immutable
  drafts for the life of the modal, and `lib/features/logging/application/log_save_service.dart`
  wrapping the repository call, the recompute and the reschedule in one `Result`-returning
  method. The shell owns the app bar, the segment bar, the pinned Save, the discard guard and
  the snackbar; a segment body knows nothing about any of it.
- **Verify** — `flutter test test/features/logging/log_modal_shell_test.dart`; then
  `flutter analyze --fatal-infos --fatal-warnings`.
- **Done when**
  - [ ] Save is enabled on every segment at all times and validates on tap.
  - [ ] Drafts live in memory only, and Discard drops all four.
  - [ ] A save failure loses nothing.
  - [ ] The save path is one transaction ending in recompute + reschedule.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 11.2 — Parse and normalise numeric input across six locales

- **Goal** — A number typed at a pump in any of the six locales becomes one canonical value, or
  is rejected with one sentence — never guessed at.
- **Spec** — §10 *Field kit*; §5 for numerals and separators; §3 *Canonical units* for what is
  stored.
- **Skills** — `value-objects-money-and-units`, `i18n-rtl-l10n`, `forms-and-input`.
- **Write these tests first** — `test/features/logging/decimal_input_test.dart` (pure, no
  widgets):
  - `accepts every separator §10 lists` — `.`, `,`, a space, `U+066B`, `U+066C`, `U+060C`,
    parsed to the same canonical value.
  - `accepts Latin, Arabic-Indic and Extended Arabic-Indic digits` — `42.61`, `٤٢٫٦١`,
    `۴۲٫۶۱` all give 42.61.
  - `rejects ambiguous input with the exact sentence` — `1,234,5` → `That number isn't clear.
    Try 42.61.`
  - `re-renders canonically on blur in the active numbering system` — 42.61 shows as `۴۲٫۶۱`
    under `fa` with `numerals: extended_arabic_indic`.
  - `money rounds to the ISO 4217 exponent` — 2 for EUR, 0 for JPY, 3 for KWD; a third decimal
    on a EUR amount is rejected, not silently truncated.
  - `volume converts to integer millilitres` and `mass to grams` and `energy to watt-hours`,
    with no float stored.
  - `the odometer field takes no decimal at all`.
  - `a negative sign is never produced by the keypad` — the refund switch owns the sign.
  - `an empty string is empty, not zero`.
- **Then build** — `lib/features/logging/domain/decimal_input.dart`:
  `DecimalInputResult parseDecimalInput(String raw, {required NumberFormatContext ctx})`
  returning a sealed `Ok`/`Ambiguous`/`Empty`, plus the `TextInputFormatter`s the fields
  install. The error text is an ARB key, never a literal. This file is pure Dart — no
  `BuildContext`, no widgets — so the whole matrix is cheap to test.
- **Verify** — `flutter test test/features/logging/decimal_input_test.dart`; then
  `bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh` for the ARB
  baked-digit grep.
- **Done when**
  - [ ] Every separator and digit set in §10's *Field kit* row parses.
  - [ ] Ambiguous input is rejected inline with the exact sentence, never coerced.
  - [ ] Nothing is stored as a float, and the money exponent comes from the ISO 4217 table.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 11.3 — Build the shared odometer field

- **Goal** — One field feeds the due engine, so it behaves identically on all three forms that
  carry it.
- **Spec** — §10 *The odometer field, everywhere it appears*; §3 *Current odometer* and
  `OdometerCorrection`.
- **Skills** — `calm-components`, `value-objects-money-and-units`, `calm-due-state-and-status`,
  `forms-and-input`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/logging/odometer_field_test.dart`:
  - `is never prefilled from an estimate` — the field is empty and the projection is offered as
    a chip.
  - `the helper line shows the last entered reading and its date` — `Last entered 186,980 km on
    12 Mar`.
  - `tapping the estimate chip fills the field` — `~187,700 now` writes 187,700 and the field
    is then an entered value.
  - `no estimate chip when the last reading is over 60 days old on log.odometer` — and the
    helper line names the age instead: `Last entered 186,980 km on 12 Mar — 174 days ago`.
  - `the live delta appears above the last reading` — `+432 km since 12 Mar`, one
    isolate-wrapped atom, updating as the value changes.
  - `the unit chip changes the unit for this entry only` — writes `odometer_unit`, leaves
    `Vehicle.distance_unit` untouched, and the delta and warnings are computed after conversion.
  - `empty is blocked on fill-ups and service records` — `Enter the odometer reading.`
  - `a value below the last reading opens the three-way sheet, not an error` — with the exact
    three options and Cancel.
  - `Typo returns focus with the text selected`.
  - `Replaced or rolled over opens the correction sheet and writes an OdometerCorrection` —
    old and new reading each with its own unit chip, and a reason of `cluster_replaced`,
    `rollover` or `unit_mixup`.
  - `a unit change offers the follow-up` — `Show all your readings in kilometres from now on?`
  - `Older entry appears only when the date is in the past` — and the save proceeds silently
    when the value fits between its date-neighbours.
  - `a reading dated before the earliest is allowed` — the helper line becomes `Older than
    anything logged. This becomes your earliest reading.` and the delta is suppressed.
  - `a too-high backdated reading is blocked with the exact sentence` — `Your earliest reading
    is 140,000 km on 2 September. A reading from May 2019 has to be lower than that.`
  - `soft warnings warn in amber and still save` — over 2,000 km/day (`That's about 2,900 km a
    day since 12 March. Is that right?`), a jump over 100,000 km, and 1.5–1.7× the last value
    on a miles vehicle (`Did you mean 116,400 mi? This looks like kilometres.`).
  - `no prior reading renders no helper line, no chip and no delta`.
- **Then build** — `lib/features/logging/ui/odometer_field.dart` (`OdometerField`), its pure
  rule set in `lib/features/logging/domain/odometer_rules.dart` (`OdometerCheck` returning a
  sealed `Ok` / `SoftWarning` / `BelowLast` / `AboveEarliest` / `Missing`), and
  `lib/features/logging/ui/odometer_correction_sheet.dart`. The unit chip sits at the `end` and
  mirrors; the `~` and the `+432 km` delta are each one isolate-wrapped atom.
- **Verify** — `flutter test test/features/logging/odometer_field_test.dart`;
  `bash .claude/skills/calm-layout-and-motion/scripts/check_touch_targets.sh`.
- **Done when**
  - [ ] The field is never prefilled from an estimate on any of the three forms.
  - [ ] A below-last value gets the sheet, never a bare error.
  - [ ] Soft warnings warn and still save; hard ones block.
  - [ ] The per-entry unit override writes `odometer_unit` and leaves the vehicle alone.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 11.4 — Build `log.fillup`

- **Goal** — The fill-up form, including the price trio, in four taps and two numbers.
- **Spec** — §10 `log.fillup` — the field table, *The price trio*, *Full versus part fill*, the
  state table, *After saving*, *RTL*.
- **Skills** — `calm-components`, `forms-and-input`, `value-objects-money-and-units`,
  `calm-visual-parity`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/logging/log_fillup_test.dart`:
  - `renders the twelve fields of the table, with More collapsed` — and More is collapsed again
    on the next open.
  - `the price trio computes the untouched field` — enter quantity and total → price per unit
    appears with the `ƒ` badge; enter quantity and price → total appears.
  - `an edited field is never recomputed` — editing the computed field clears its badge and the
    least-recently-touched of the other two becomes computed; no cursor jump.
  - `the ƒ badge's accessible name is calculated from the other two`.
  - `the displayed rounded value is what gets stored` — 76.66 € ÷ 1.799 stores 42 610 mL, not
    42 613.
  - `only quantity and total persist` — no price-per-unit column is written.
  - `two of the three are required` — one alone → `Enter how much fuel you put in, and either
    the price per litre or the total.`
  - `quantity at or below zero is rejected` — `Fuel must be more than zero.`
  - `a negative price is rejected` — `Price can't be negative.`; a negative total →
    `Total can't be negative. A free fill-up is 0.`
  - `over tank capacity × 1.15 warns and still saves` — `That's more than your tank holds.
    Saving it as entered.`
  - `a future date is rejected` — `Pick today or a day in the past.`
  - `full versus part is a two-option segmented control, defaulting to Filled it up` — and part
    fill explains itself: `Part fills don't produce a figure on their own. This one gets added
    to your next full tank.`
  - `the chain-broken checkbox lives under More and explains itself` — `Your consumption
    figures start fresh from this fill-up.`
  - `electric relabels the trio` — `kWh`, `Price/kWh`, `Total`, and `Station` becomes
    `Charge point`; CNG/LPG by mass gives `kg` and `Price/kg`.
  - `fuel kind is shown only for hybrid/other vehicles or mixed history`, otherwise inherited
    silently.
  - `station and grade chips offer up to five recents and never auto-fill`.
  - `the first fill-up for a vehicle shows one line above the form` — `Your first consumption
    figure arrives at your next full fill-up.`
  - `a suspected duplicate asks once on Save` — same vehicle and date, odometer within 1 km,
    volume within 0.1 L → `You logged a fill-up on 2 September at 187,412 km for 42.61 L. Add
    this one too?` with *Add it* / *Cancel*.
  - `saving writes one FillUp plus one OdometerReading with source fillup` — exactly one of
    `quantity_ml` / `quantity_g` / `energy_wh` is non-null, by fuel kind.
  - `the snackbar reports the closed segment` — `Fill-up saved — 7.2 L/100 km since 12 March`;
    a part fill or broken chain gives `Fill-up saved`; a zero-distance segment gives
    `Fill-up saved. No figure this time — the odometer didn't move.`
  - `edit mode` — title `Edit fill-up`, no segment bar, a Delete row, and monotonicity checked
    against both neighbours.
- **Then build** — `lib/features/logging/ui/log_fillup_body.dart`,
  `lib/features/logging/domain/price_trio.dart` (the `touched` queue and `compute` exactly as
  §10 pseudocodes it — quantity 2 dp, price 3 dp, total at the currency exponent), and
  `lib/features/logging/application/fillup_draft_notifier.dart`. The money row is a
  `start → end` sequence that mirrors as a whole; labels stack above fields and wrap rather
  than truncate.
- **Verify**
  ```bash
  flutter test test/features/logging/log_fillup_test.dart
  flutter test test/parity/log_fillup_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/log.fillup-light-ltr.png log.fillup \
       --theme light --dir ltr
  node tools/compare_to_reference.mjs build/parity/log.fillup-dark-ltr.png log.fillup \
       --theme dark --dir ltr
  node tools/compare_to_reference.mjs build/parity/log.fillup-light-rtl.png log.fillup \
       --theme light --dir rtl
  node tools/compare_to_reference.mjs build/parity/log.fillup-dark-rtl.png log.fillup \
       --theme dark --dir rtl
  # or, once all four captures exist:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.fillup-light-ltr.png    # look at the side-by-side
  ```
  A pass is theme ok, every surface over 0.5% within Δ24 of a Calm token, and ≥75% of the
  reference's band edges matched within 4px. The differing-pixel percentage is informational.
- **Done when**
  - [ ] The trio computes the third value, marks it `ƒ`, and stores what was displayed.
  - [ ] Every exact error string in the field table is asserted by a test.
  - [ ] The consumption result reaches the user in the snackbar.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 11.5 — Build `log.service`

- **Goal** — Work that was done is recorded, and the reminders it resets are named on the form
  that records it.
- **Spec** — §10 `log.service` — the field table, *Item chips*, *Cost model*, the state table,
  *RTL*; §3 `ServiceRecord` / `ServiceLine`.
- **Skills** — `calm-components`, `forms-and-input`, `calm-due-state-and-status`,
  `value-objects-money-and-units`, `calm-visual-parity`.
- **Write these tests first** — `test/features/logging/log_service_test.dart`:
  - `renders the eight fields of the table, with More collapsed`.
  - `item chips are the vehicle's active items, sorted overdue → due → due soon → ok` — paused
    items excluded, `+ Other` last.
  - `+ Other opens a one-field sheet and produces a line with no item link` — `What was done?`,
    and that line resets nothing.
  - `unticking a chip whose amount was typed keeps the money and states the consequence` —
    `Air filter won't be reset.`
  - `cost is always the sum of lines` — with the split off, the record still holds one line
    labelled with the ticked item, or the localised `Service` when several or none are ticked.
  - `turning the split on makes Total read-only and equal to the sum`.
  - `a negative amount is rejected` — `Cost can't be negative. A warranty job is 0.`; an empty
    total → `Enter what it cost, or 0.`
  - `a future date is rejected` — `Pick today or a day in the past.`
  - `the invoice number is forced LTR, start-aligned and not digit-shaped` — asserted under
    `fa`.
  - `saving writes one ServiceRecord with at least one line plus an OdometerReading with source
    service`.
  - `every ticked item is re-anchored, recomputed and rescheduled` — asserted against a fake
    reminder service.
  - `many items scroll` — 26 items give a two-line chip row, horizontal scroll and a *See all*
    chip opening a full-height sheet with a filter field.
  - `the estimated-record state renders the amber line` — `We estimated this. What did the
    odometer actually read, and what did it cost?`, and Save clears `odometer_estimated` and
    `cost_estimated`.
  - `edit mode unticking an item re-opens the previous anchor and recomputes that reminder`.
  - `backfilling before the earliest reading shows the older-than-anything helper line`.
- **Then build** — `lib/features/logging/ui/log_service_body.dart`,
  `lib/features/logging/ui/service_item_chips.dart`,
  `lib/features/logging/domain/service_cost_model.dart` (lines are the only cost; there is no
  second total field), and `lib/features/logging/application/service_draft_notifier.dart`.
  Chips size to content and wrap; split money is a column of atoms aligned to the `end` edge in
  both directions.
- **Verify**
  ```bash
  flutter test test/features/logging/log_service_test.dart
  flutter test test/parity/log_service_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/log.service-light-ltr.png log.service \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.service-light-ltr.png
  ```
- **Done when**
  - [ ] Record cost is Σ lines with no second cost field anywhere in the model.
  - [ ] Ticking and unticking an item visibly states what it does to that reminder.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 11.6 — Wire mark-done, and re-anchor from the actual odometer

- **Goal** — A reminder resets because work was recorded, from the reading the user actually
  entered — never from the odometer it was due at.
- **Spec** — §10 *Marking a reminder done → a service record*, *The confirmation panel*; §3
  *Due state per item* → `from_actual` / `from_due`; §4 for the rollover and reschedule.
- **Skills** — `calm-due-state-and-status`, `state-management-riverpod`, `calm-components`,
  `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/logging/mark_done_test.dart`:
  - `all four entry points land on log.service prefilled` — the Home due card's **Log it**,
    a `reminders.list` row's **Done today**, `reminders.edit`'s **Mark as done**, and the
    notification action **Done**; the originating item is ticked and pinned first, the date is
    today, and the odometer is prefilled with the **last entered** reading and selected so
    typing replaces it, under `From your entry on 12 Mar. Correct it if you've driven since.`
  - `re-anchors from the actual odometer, not the due odometer` — an item due at 186,000 km,
    saved at 187,412 km with `rollover = from_actual`, next-dues at 197,412 km. **This is the
    test that fails if anyone anchors on the due value.**
  - `from_due anchors the date on the cycle, not the record` — the anniversary case of §3.
  - `the notification Done action writes without any UI` — one `ServiceRecord` with
    `odometer_estimated` and `cost_estimated` both true and one line at amount 0.
  - `mark-done Save replaces the body with the confirmation panel for five seconds or until
    Close` — showing the item, the date, the odometer, the cost, and the next-due pair
    `Next due at 197,412 km or September 2027 — whichever comes first`.
  - `a distance-only item names one axis` and `a time-only item names the other`.
  - `an unmeasured projection renders fuzzily in the panel` — `around September 2027`, in the
    estimate treatment, and never an exact date.
  - `a save from the + skips the panel` — nothing was reset.
  - `Mark as done from reminders.edit dismisses both modals to the original caller`.
  - `EPIC-10's navigation intents now resolve end to end` — the Home card's **Log it** opens a
    prefilled `log.service` and saving returns to Home with the card recomputed in place.
- **Then build** — `lib/features/logging/application/mark_done_service.dart` (the one path all
  four entry points use), `lib/features/logging/ui/service_confirmation_panel.dart`, and the
  prefill arguments on the `log.service` route. Re-anchoring calls the existing
  `resolveAnchor` over the newly written line — this task adds no arithmetic to the engine.
- **Verify** — `flutter test test/features/logging/mark_done_test.dart` and
  `flutter test test/features/home/` to confirm EPIC-10's assertions still hold end to end.
- **Done when**
  - [ ] One code path serves all four entry points.
  - [ ] The next cycle is anchored on the entered odometer, proven by a test that would pass
        with the due odometer only if it were wrong.
  - [ ] The confirmation panel shows both halves of the next-due pair, fuzzy when unmeasured.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 11.7 — Build `log.expense`

- **Goal** — Every non-fuel, non-service cost is one row with an optional coverage window, and
  no recurrence engine anywhere.
- **Spec** — §10 `log.expense` — the field table, the state table, *RTL*; §3 `Expense`.
- **Skills** — `calm-components`, `forms-and-input`, `value-objects-money-and-units`,
  `calm-visual-parity`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/logging/log_expense_test.dart`:
  - `category comes first and nothing is selected on open` — no keyboard until one is picked.
  - `no category is rejected` — `Pick what this was for.`
  - `Other reveals a name field that takes focus` — empty → `Give this expense a name.`
  - `an empty amount is rejected` — `Enter what you paid.`; `0` is allowed.
  - `Insurance and Road tax flip the period switch on` — a 12-month window prefilled From =
    date paid, To = From + 12 months − 1 day, with the explanatory line under it.
  - `To before From is rejected` — `The end date is before the start date.`
  - `future dates are allowed` — prepaid insurance is real.
  - `the refund switch flips the stored sign and previews it` — `−80.00 € will be subtracted
    from your costs.`, with the minus placed by the locale money formatter inside the isolate.
  - `no minus key exists on the amount pad`.
  - `an odometer is optional here` — no reading is written when it is empty, and an
    `OdometerReading` with `source: expense` is written when it is not.
  - `saving writes exactly one Expense row` — no generated rows, no repeat switch anywhere on
    the form.
  - `opened from trips.edit the trip is prefilled and locked` — and the snackbar reads
    `Added to Munich run`.
  - `category chips wrap to three rows in German at large text scale and never truncate` —
    `Reifeneinlagerung`, `Zulassung und Steuer`.
  - `edit mode` — title `Edit expense`, Delete row.
- **Then build** — `lib/features/logging/ui/log_expense_body.dart` and
  `lib/features/logging/application/expense_draft_notifier.dart`. The category chip set drives
  the rest of the form; the coverage window is two dates on one row, amortised later by the
  cost views — this form does no spreading itself.
- **Verify**
  ```bash
  flutter test test/features/logging/log_expense_test.dart
  flutter test test/parity/log_expense_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/log.expense-light-ltr.png log.expense \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.expense-dark-rtl.png
  ```
- **Done when**
  - [ ] One payment writes one row, with a coverage window and no recurrence.
  - [ ] The refund sign comes from the money formatter, never from a prefix in code.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 11.8 — Build `log.odometer` over `CalmNumberPad`

- **Goal** — The fastest entry in the app: two fields, the keypad up, and a stale-odometer
  state cleared the moment it saves.
- **Spec** — §10 `log.odometer` — the field table, the state table, *After saving*, *RTL*;
  §9 *Stale odometer* for what clears on Home.
- **Skills** — `calm-components`, `forms-and-input`, `calm-due-state-and-status`,
  `calm-visual-parity`.
- **Write these tests first** — `test/features/logging/log_odometer_test.dart`:
  - `renders two fields and nothing else` — no notes, no category, no More section.
  - `the value is entered on CalmNumberPad, not the OS keyboard` — the pad is a 3-column grid
    in the bottom third and the value stays visible above it at `display`.
  - `the field is autofocused with the pad up from the home odometer strip`.
  - `from an odometer nudge nothing is focused` — the date is today and the last reading is in
    the helper line.
  - `the estimate chip is offered only when the last reading is under 60 days old` — at 174
    days the helper line names the age and no chip appears.
  - `an empty value is rejected` — `Enter the odometer reading.`
  - `a future date is rejected` — `Pick today or a day in the past.`
  - `the first reading of a vehicle's life renders no helper line and no delta`.
  - `a below-last value opens the three-way sheet` — reusing task 11.3's sheet.
  - `saving writes one OdometerReading with source manual, then recomputes and reschedules`.
  - `the snackbar reports the consequence` — `Odometer updated — 2 reminders recalculated`, or
    `Odometer updated` when nothing changed status, each with **Undo**.
  - `the home staleness line disappears immediately and needsOdometer cards re-render with a
    real status` — an integration test over `home` plus this modal.
  - `edit mode is manual readings only` — a reading with `source: fillup` is not editable here;
    tapping it opens its parent record.
- **Then build** — `lib/features/logging/ui/log_odometer_body.dart` composing `OdometerField`
  with `CalmNumberPad` and one date row. Nothing optional is added to this screen — §10 says
  one more field would be a net loss.
- **Verify**
  ```bash
  flutter test test/features/logging/log_odometer_test.dart
  flutter test test/parity/log_odometer_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/log.odometer-light-ltr.png log.odometer \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/log.odometer-light-rtl.png
  ```
- **Done when**
  - [ ] Two fields, `CalmNumberPad`, and nothing optional.
  - [ ] The estimate chip's 60-day boundary is enforced and tested.
  - [ ] Saving clears Home's staleness state in the same frame budget as any other write.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — 1 h (CC) · ~1 week (human)

## Definition of done

- [ ] The central **+** opens the log modal on **Fill-up** from every screen, with four
      segments sharing identical chrome.
- [ ] Save is never disabled on any of the four segments; every rejection is one inline
      sentence under the field, in the exact wording §10 specifies.
- [ ] Every save is one transaction ending in a due-state recompute and a notification
      reschedule, with a six-second **Undo** snackbar, and nothing derived is persisted.
- [ ] A mark-done re-anchors from the odometer actually entered, and the confirmation panel
      shows the resulting next-due pair.
- [ ] Every field these forms write round-trips through EPIC-06's export and import.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-11.md`.** It starts
empty. Append one line per task as it completes — what was built, what was deferred, and
anything the next epic needs to know. It is the running log for this epic and the handover to
the next one.
