# EPIC-09 — First run, the garage and vehicles

| | |
|---|---|
| **Epic** | EPIC-09 — First run, the garage and vehicles |
| **Depends on** | EPIC-03, EPIC-04, EPIC-05, EPIC-08 |
| **Estimate** | **11 h (CC) · ~11 weeks (human)** over 8 tasks |
| **Spec sections** | §8 *First run, the garage, and vehicles* · §4.8 *The seeded default set* (the catalogue a new vehicle is created with) · §14 *Vehicle lifecycle* |
| **Screens** | `firstrun.language`, `firstrun.vehicle`, `vehicles`, `vehicle.edit`, `vehicle.switcher` |

Five screens, so this epic is parity-heavy: 20 reference images in
`design/reference/calm/` are gates on it, and `calm-visual-parity` is loaded before the first
widget is written, not after the first review comment. It also owns the highest drop-off
screen in the product — `firstrun.vehicle` asks for **one** number, and every field added to
it loses users who never reach Home.

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end, a screen is not done until it matches its reference, `SPEC.md`
wins — are stated once in `epics/README.md` and are binding here.

---

## Where we are now

The repo before EPIC-01 held `SPEC.md`, the design systems, the 112 Calm reference PNGs,
`tools/` and `.claude/skills/`, and **no Flutter app at all** — no `pubspec.yaml`, no `lib/`.
EPIC-01 created it; everything since inherits it.

At the moment this epic starts:

- `pubspec.yaml`, `lib/`, `test/` exist; `flutter analyze --fatal-infos --fatal-warnings` and
  `flutter test` are green.
- **EPIC-08 delivered the app shell**: the single `go_router`, the four tab roots and the
  docked central **+**, with the modal / push / sheet / dialog kinds of §7 already
  distinguished, and the three global dialogs of §7 — `dialog.discard`,
  `dialog.confirmDelete` and `dialog.snooze` — built once in `lib/ui/dialogs/`. **§7 makes
  those three global, belonging to no feature; building one twice is how two of them drift
  apart, so this epic wires EPIC-08's widgets and builds none of its own.** Their parity
  gates are EPIC-08's too.
- The Calm theme is in `lib/theme/calm/` (EPIC-02) — `CalmColors`, `CalmType`, `CalmSpace`,
  `CalmShapes`, `CalmMotion`, and `DueState` / `DueDriver` / `CalmStatusStyle`.
- **EPIC-03 delivered `lib/ui/calm/`**: `CalmScaffold`, `CalmAppBar`, `CalmCard`,
  `CalmRowGroup`, `CalmListRow`, `CalmChip`, `CalmBadge`, `CalmStatusDot`, `CalmSwitch`,
  `CalmSegmented`, `CalmField`, `CalmButton`, `CalmSheet`, `CalmDialog`, `CalmNumberPad`,
  `CalmTile`. This epic **composes** those and styles nothing itself — a `BoxDecoration` in
  `lib/features/vehicles/` is a review failure.
- **EPIC-04 delivered the six-locale pipeline**: `l10n.yaml`, `gen_l10n`, ARB files for
  `en de fr fa ar ckb`, Vazirmatn bundled with its `LicenseRegistry` entry, the numeral and
  calendar resolution from device **region**, and the digit-normalising input formatter every
  numeric field in this epic uses.
- **EPIC-05 delivered persistence**: the §3 entities as Drift tables, forward-only migrations,
  and repositories that are the single write path with `.watch` streams. `SettingsRepository`
  exists; `VehicleRepository` does **not** — task 9.1 writes it.
- **EPIC-07 delivered the due engine** — `estimateOdometer`, `computeDueState`, `nextDue`,
  `dueSummary`. It is not in this epic's declared dependency list because none of these five
  screens *writes* a due state, but three of them *read* one, and in the recommended order
  EPIC-07 lands first. If it has not, `vehicles` and `vehicle.switcher` render the fallback
  §8 already specifies — a hollow dot and "Couldn't work out what's due" — and the row still
  appears. That fallback is a required test in task 9.6 either way.

Deliberately still missing when this epic starts:

- **`home` does not exist.** EPIC-10 builds it. Every route out of first run and out of the
  switcher targets the `home` route *by name*; the tests in this epic assert the navigation
  intent — route name plus arguments — never the destination's contents.
- **`log.odometer` does not exist.** EPIC-11 builds it. `vehicle.edit`'s read-only odometer
  row pushes it by name.
- **`settings.import` does not exist.** EPIC-15 builds it. Both first-run screens carry the
  "Restore a backup" escape, which opens the OS document picker through an injected
  `FilePickerService` seam and then pushes `settings.import` by name. This epic builds the
  seam and the link; the import screen behind it is stubbed and its own epic replaces the stub.
- **`settings.language` in normal mode** belongs to EPIC-14. This epic builds the `firstRun`
  variant against the `firstrun.language` reference and extracts the seven-row list as a
  shared widget so EPIC-14 composes it rather than copying it.
- No notification scheduling. `notifications_muted` is a stored field here and nothing reads
  it yet.

## What we will have when this is done

- A fresh install opens on the language screen, and tapping **فارسی** flips the whole app to
  RTL before the finger lifts — the only proof of RTL support a user will ever need.
- Continue, then one screen with one number to type, then Start, and the app is on Home with
  a vehicle, a first odometer reading, a seeded set of reminders and an active vehicle. Nine
  interactions on a realistic path.
- A new phone can restore a backup **without inventing a fake vehicle first**, from either
  first-run screen.
- Settings → Vehicles lists the garage: add, rename, reorder by long-press, mark sold,
  archive, delete. Deleting a vehicle with entries requires typing its name and says exactly
  what dies; Undo lives for 10 seconds.
- With two or more vehicles the Home title becomes tappable and opens the switcher sheet;
  with one vehicle the title is plain text with no chevron and the sheet does not exist.
- `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over the five
  screens in all four combinations, and the side-by-side sheets in
  `design/reference/_parity/` have been opened and looked at.
- `flutter test test/features/vehicles/ test/features/first_run/` is green, and no string in
  either feature is a Dart literal — `grep -rn "Text('" lib/features/vehicles/ lib/features/first_run/` returns nothing.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Rule 2 (widgets are dumb), rule 3 (one ViewModel per screen over immutable state) and rule 5 (single write path) are what keep a five-screen epic from becoming five god-widgets. |
| `calm-components` | Every control on these screens is a Calm widget — `CalmScaffold`, `CalmRowGroup`/`CalmListRow`, `CalmField`, `CalmSegmented`, `CalmChip`, `CalmSwitch`, `CalmButton`, `CalmSheet`, `CalmDialog`, `CalmStatusDot`. It also forbids the Material components a garage screen reaches for by reflex: `ListTile`, `Card`, `AlertDialog`, `showModalBottomSheet`. |
| `calm-visual-parity` | **Required.** Five screens × four combinations = 20 gates, and this skill is also the reason no task here tells anyone to chase a pixel diff to zero: the reference is Chrome and the app is Skia, 25–45% of pixels differ on a correct screen, and what is decided mechanically is theme, Calm-token colour and the horizontal band profile. |
| `calm-typography-and-rtl` | Plate and VIN forced LTR inside an RTL form; vehicle names and notes taking direction from their content; German's two-line reservations ("Als verkauft markieren", "Voraussichtliche Jahresfahrleistung"); the odometer and its unit as one atomic run. Defers ARB mechanics to `i18n-rtl-l10n`, opened per task where a new string lands. |
| `forms-and-input` | `vehicle.edit` is the largest form in the app and `firstrun.vehicle` is the most sensitive: sync validation, the disabled-Save exception, focus traversal, keyboard actions, and the digit normalisation every numeric field needs. |
| `state-management-riverpod` | One `Notifier` per screen over immutable state; `family` for the vehicle being edited; the single write path from the ViewModel through `VehicleRepository`. |
| `persistence-drift` | Task 9.1's create is one transaction across four tables, and delete is a cascade stamping one `deleted_at` across every child row. Both are `.watch`-republished, not hand-invalidated. |
| `navigation-and-routing` | The launch-state contract of §7: which screen a cold start opens, the swallowed system back on `firstrun.vehicle`, the tab-stack reset on a vehicle switch, and add-from-switcher dismissing two layers at once. |
| `ui-states-and-feedback` | The 10-second Undo snackbar, the typed-confirmation dialog, the discard dialog, the disk-full error with Retry, and the deliberate absence of an empty state on `vehicles`. |

---

## Tasks

### Task 9.1 — Build `VehicleRepository` and the garage data layer

- **Goal** — every write in this epic has one durable route, and the garage list is a stream that re-emits on commit.
- **Spec** — §3 *Identity, timestamps, deletion*; §8 *`vehicles` — the garage* (Data in / Data out); §14 *Vehicle lifecycle*.
- **Skills** — `persistence-drift`, `state-management-riverpod`, `flutter-conventions-index`.
- **Write these tests first** — `test/data/vehicle_repository_test.dart`, against an in-memory database:
  - `create persists the vehicle, its first odometer reading and the seeded items in one transaction`.
  - `a failed reading insert rolls the vehicle back` — §8's all-or-nothing rule; a vehicle with no reading is forbidden by §3, so the test asserts zero rows in both tables afterwards.
  - `softDelete stamps deleted_at on the vehicle and on every child row with the same instant` — fill-ups, service records and their lines, expenses, trips, odometer readings, corrections, service items.
  - `deleted rows are excluded from watchGarage and from entryCounts`.
  - `undoDelete clears deleted_at across the whole set`.
  - `purge removes the rows, and deleted_at is null on everything that remains` — §2: no trash, no bin, no tombstones.
  - `deleting the active vehicle promotes the next live vehicle in sort_order`.
  - `deleting the last vehicle leaves active_vehicle_id null`.
  - `reorder writes sort_order and keeps sold and archived at the bottom regardless`.
  - `entryCounts returns fill-ups, services, costs, trips and reminders separately` — the delete dialog's second line needs all five.
  - `markSold writes status, sold_on and sold_price and touches nothing else`.
  - `archive writes status and leaves sold_on null`.
  - `every write returns a typed Result and a disk failure returns Err(PersistFailure.write) rather than throwing`.
  - `watchGarage re-emits after every commit and not before` — persist first, then republish.
- **Then build** — `lib/data/vehicle_repository.dart`. `watchGarage()`, `watchActive()`,
  `create(VehicleDraft)`, `update(Vehicle)`, `reorder(List<String> ids)`, `markSold`,
  `archive`, `softDelete`, `undoDelete`, `purge`, `entryCounts(String vehicleId)` returning a
  record of the five counts. Ids are `veh_<ULID>` per §2. Every method returns
  `Result<T, PersistFailure>`; nothing throws across the boundary.
- **Verify** — `flutter test test/data/vehicle_repository_test.dart` — 14 green. Then `grep -rn "\.into(\|\.update(\|\.delete(" lib/features/` — a feature writing a DAO directly is a review failure and this grep is empty.
- **Done when**
  - [ ] Create is one transaction and its rollback is proven by a test.
  - [ ] The cascade stamps one instant, and Undo restores the whole set.
  - [ ] `entryCounts` returns the five numbers the delete dialog names.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 9.2 — Build the seeded reminder catalogue

- **Goal** — a new vehicle arrives with reminders that make sense for what it is, without an app update ever moving an existing vehicle's intervals.
- **Spec** — §4.8 *The seeded default set* (§8.1 on, §8.2 off, §8.3 variants, §8.4 heavy use, §8.5 never seeded); §3 *Enums* (the 28 `ServiceKind` values, and "the catalogue is a seed, not a live reference").
- **Skills** — `flutter-conventions-index`, `dart3-idioms-and-coding-standards` *(via the index's routing table)*, `testing-strategy` *(likewise)*, `persistence-drift`.
- **Write these tests first** — `test/core/reminders/service_item_catalogue_test.dart`:
  - `a petrol car seeds seven tracked items and nine untracked ones` — §4.8.1 and §4.8.2 by count and by kind.
  - `every seeded item leaves label null and carries a ServiceKind` — so a seeded vehicle reads correctly in all six languages with no migration.
  - `seeded-off items carry is_tracked false and are invisible to the due engine`.
  - `an electric car seeds no oil_and_filter, air_filter, spark_plugs, transmission_fluid, timing_belt or coolant`.
  - `an electric car seeds battery_12v and never battery, and never both`.
  - `an electric car seeds brake_fluid on at 24 months and cabin_filter on at 12 months`.
  - `a motorcycle seeds oil_and_filter at 6,000 km and chain_lube on at 800 km`.
  - `a motorcycle drops cabin_filter, tyre_rotate, wipers, transmission_fluid, timing_belt, battery and battery_12v entirely`.
  - `an air-cooled motorcycle seeds no coolant and a liquid-cooled one does`.
  - `a van seeds oil_and_filter at 15,000 km and tyre_replace at 40,000 km`.
  - `is_business moves oil_and_filter to 7,500 km and 6 months, air_filter to 15,000 km, and seeds tyre_rotate on`.
  - `an electric motorcycle takes the motorcycle deltas and then the electric ones` — the two filters compose, in that order.
  - `a miles vehicle seeds 6,000 mi, not 9,656 km rendered as 6,000` — defaults are per unit system, never converted.
  - `truck and other take the car set unchanged`.
  - `inspection, insurance_renewal and registration seed with rollover from_due; everything else from_actual`.
  - `the six never-seeded kinds appear on no vehicle type` — `fuel_filter`, `wheel_alignment`, `ac_service`, `brake_pads_front`, `brake_pads_rear`, `custom`.
  - `the catalogue accounts for all 28 ServiceKind values` — 7 on + 9 off + 6 variant-introduced + 6 never = 28. §4.8.5 states this as an invariant, so it is a test, not a comment.
- **Then build** — `lib/core/reminders/service_item_catalogue.dart`:
  `List<ServiceItemSeed> seedFor({required VehicleType type, required FuelKind fuel, required bool isBusiness, required DistanceUnit unit})`,
  a pure function over a `const` table transcribed from §4.8 with one row per kind and its
  seeded-on predicate. `VehicleRepository.create` copies the result into real `ServiceItem`
  rows. Pure, no Flutter import, so `dart test` runs it headlessly.
- **Verify** — `dart test test/core/reminders/service_item_catalogue_test.dart` — 17 green, including the 28-value accounting test.
- **Done when**
  - [ ] Every row of §4.8's four tables is transcribed and asserted.
  - [ ] The 28-value accounting invariant is a passing test.
  - [ ] The table is `const` and copied at creation; nothing reads it at runtime afterwards.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 9.3 — Build `firstrun.language`

- **Goal** — the app's first screen picks the language and the writing direction, and proves RTL works before the user has typed anything.
- **Spec** — §8 *`settings.language` — first-run mode*; §5 *Locale selection*; §7 *Launch and first run*.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `state-management-riverpod`, `navigation-and-routing`, `ui-states-and-feedback`.
- **Write these tests first** — `test/features/first_run/first_run_language_screen_test.dart`:
  - `the seven rows appear in the fixed order system, en, de, fr, fa, ar, ckb` — fails if the device match floats to the top.
  - `System names in its parenthesis whatever system resolves to right now` — a `de-DE` device reads "System (Deutsch)".
  - `a device language outside the six preselects System and shows the not-translated-yet line` — a `pt-BR` device gets the exact §8 sentence. It takes no placeholder: see F-9.8.
  - `each language name is rendered in its own script and is never translated`.
  - `tapping فارسی re-renders from the root: Directionality becomes rtl, the checkmark moves to the end edge, and Continue relabels to ادامه` — all three in one pump, before Continue is pressed.
  - `Continue commits language, calendar, numerals, first_day_of_week, distance_unit, volume_unit, consumption_unit and currency_default, taking everything but language from the device region`.
  - `Continue leaves onboarding_done false` — a kill between the two screens replays from here.
  - `there is no app bar, no back button and no skip`.
  - `Android system back exits the app rather than popping`.
  - `Restore a backup calls the FilePickerService seam and writes nothing on cancel`.
  - `the Continue button wraps to two lines rather than shrinking` — "بەردەوام بە" and "Weiter" at the same width budget.
  - `test/features/first_run/first_run_language_notifier_test.dart`: `selecting a language changes state without persisting`, `Continue persists exactly once`.
- **Then build** — `lib/features/first_run/presentation/first_run_language_screen.dart` and
  `lib/features/first_run/first_run_language_notifier.dart`. A `CalmScaffold` with no app bar,
  the wordmark, a `CalmRowGroup` of seven `CalmListRow`s (extracted as
  `LanguageRowList` so EPIC-14's pushed `settings.language` composes it), one `CalmButton`
  and one text link. Selection re-renders from the root by writing the in-memory locale that
  `MaterialApp.locale` watches.
  Then `test/parity/firstrun_language_parity_test.dart`, capturing all four combinations at
  390×844 @2x to `build/parity/firstrun.language-<theme>-<dir>.png`. The test file uses
  underscores; the **capture filename is the screen id**, dots included, or the comparison
  tool cannot find its reference.
- **Verify**
  ```bash
  flutter test test/features/first_run/
  flutter test test/parity/firstrun_language_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/firstrun.language-light-ltr.png firstrun.language \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/firstrun.language-light-ltr.png    # look at the side-by-side
  ```
  A pass is the three mechanical checks green — the ground is a token of the requested theme,
  every surface over 0.5% is within Δ24 of a Calm token, and ≥75% of the reference's band
  edges have an app edge within 4px. The differing-pixel percentage is informational and will
  read 25–45% on a correct screen; it is not a score and no tolerance is widened.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The RTL captures were reviewed by someone who reads the script, not only by the tool.
  - [ ] Every string is an ARB key present in all six locales.
  - [ ] The seven-row list is extracted for EPIC-14 to reuse.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 9.4 — Build `firstrun.vehicle` and the create transaction

- **Goal** — one vehicle and one odometer reading in the database in under thirty seconds, with one thing to type.
- **Spec** — §8 *`vehicle.edit` — first-run mode* (the field table, the four states, Data out, Restore a backup); §14 *Restore on a brand-new phone*.
- **Skills** — `forms-and-input`, `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `state-management-riverpod`, `persistence-drift`, `ui-states-and-feedback`.
- **Write these tests first** — `test/features/first_run/first_run_vehicle_screen_test.dart`:
  - `Start is visibly disabled until the odometer parses to a positive integer` — the deliberate exception to "Save is never disabled", and the hint is always visible.
  - `tapping a disabled Start flashes the odometer hint and writes nothing`.
  - `an empty odometer on Save reads "Enter the number on your dash."`
  - `an unparseable odometer reads "That doesn't look like a number. Digits only."`
  - `zero is accepted` — new cars exist.
  - `3,000,001 km warns "That's higher than any car has driven. Check the number." and still saves behind Use it anyway` — a warning, never a block.
  - `focus is not auto-placed in the odometer field` — §8 is explicit; a keyboard over two thirds of the screen reads as a form, not a question.
  - `choosing the van tile renames the field to "My van" and switches is_business on`.
  - `choosing the motorcycle tile renames the field to "My motorbike"`.
  - `the name field is pre-selected so the first keystroke replaces the prefill`.
  - `Extended Arabic-Indic digits in the odometer normalise to a canonical value on blur`.
  - `an ambiguous "1,234" is rejected inline rather than guessed`.
  - `each annual band writes the expected_annual_m value SPEC.md §8 assigns it` — F-9.1 is settled: §8 now carries the table, closed bands write their midpoint and the open band a third above its floor, per unit system and not converted.
  - `Save writes Vehicle, OdometerReading, the seeded items and Settings in one transaction`.
  - `the unit chip writes Settings.distance_unit and no per-vehicle override` — with exactly one vehicle, a global is the honest place for it.
  - `a disk failure keeps the screen and shows "Couldn't save. Your phone may be out of space." with Retry`.
  - `there is no Cancel, no back, no swipe-to-dismiss, and Android system back is swallowed`.
  - `Restore a backup opens the picker and, on a valid file, pushes settings.import in its empty-device variant`.
  - `cancelling the picker returns here with nothing written`.
  - `backgrounding mid-entry keeps the form in memory and writes no draft row`.
- **Then build** — `lib/features/first_run/presentation/first_run_vehicle_screen.dart` and
  `first_run_vehicle_notifier.dart`. **Five** controls: three type tiles (no overflow — F-9.11),
  a `CalmField` for the name, three fuel `CalmChip`s plus a More… sheet, the odometer
  `CalmField` with its end-edge unit chip, and four annual-band chips. **No `CalmSwitch`** —
  F-9.9: the artboard and all four references have none, and `vehicle_type = van` still turns
  `is_business` on. Save calls `VehicleRepository.create` once. The odometer and its unit are
  one atomic run in both directions.
  Then `test/parity/firstrun_vehicle_parity_test.dart`, capturing to
  `build/parity/firstrun.vehicle-<theme>-<dir>.png`.
- **Verify**
  ```bash
  flutter test test/features/first_run/
  flutter test test/parity/firstrun_vehicle_parity_test.dart      # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/firstrun.vehicle-light-ltr.png firstrun.vehicle \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/firstrun.vehicle-light-ltr.png    # look at the side-by-side
  ```
  Then run the German and Sorani locales at 200% text scale and confirm nothing clips — that
  is §14's text-scale rule and the parity tool shoots at scale 1, so it cannot see it. The
  band chips no longer need a truncation budget: F-9.12 moved the unit off the chips and into
  the label, so they read `under 10` / `10–20` / `20–30` / `over 30` in every locale.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The four inline odometer messages are asserted verbatim from ARB.
  - [ ] The create is one transaction, proven by the rollback test in task 9.1.
  - [ ] F-9.1 is settled in `SPEC.md` in this PR and the band test asserts the settled values.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

---

### Task 9.5 — Build `vehicle.edit` in normal mode, and wire the discard dialog

- **Goal** — every fact about one vehicle, edited safely, with a dirty dismiss that cannot lose work silently.
- **Spec** — §8 *`vehicle.edit` — normal mode*; §7 *Navigation graph* (the two rules that hold everywhere); §3 *Invariants and validation*.
- **Skills** — `forms-and-input`, `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `state-management-riverpod`, `navigation-and-routing`, `ui-states-and-feedback`.
- **Write these tests first** — `test/features/vehicles/vehicle_edit_screen_test.dart`:
  - `the odometer is a read-only row showing the latest reading and its age, and tapping it pushes log.odometer` — a facts form must never stamp today's date on a number last checked in March.
  - `a year outside 1900–2027 reads "Enter a year between 1900 and 2027."`
  - `a VIN of 16 characters reads "A VIN is usually 17 characters." and still saves`.
  - `plate and VIN are forced LTR and start-aligned inside a Persian form, and are never digit-shaped`.
  - `name and notes take direction from their content` — "The Golf" reads LTR inside a Persian form.
  - `a duplicate name saves, with the note "You already have a vehicle called Van"`.
  - `changing currency shows the permanent "Only new entries use this. Nothing already saved changes." line and rewrites no money row`.
  - `changing fuel_kind_default touches no ServiceItem row and offers the one-time snackbar` — the reminders it would silently delete are someone's history.
  - `each of the six unit and currency overrides writes null when set to Automatic`.
  - `purchase_odometer_m above the earliest reading shows the "—" warning and still saves`.
  - `purchase_odometer_m emits no OdometerReading` — a vehicle fact, not an observation.
  - `Mark as sold opens the sale form with today's date defaulted and ≤ today enforced`.
  - `a dirty dismiss opens dialog.discard and a clean one dismisses silently` — ✕, swipe-down and system back are one event, asserted three times. Run against EPIC-08's real `showDiscardDialog`, not a local copy.
  - `Discard drops the draft and returns to the caller; Keep editing returns to the modal with focus restored`.
  - `add-from-switcher dismisses both the modal and the sheet on Save, makes the new vehicle active, and resets all four tab stacks`.
  - `add from the vehicles + appends the vehicle, does not make it active, and offers "Switch to it" in a snackbar`.
- **Then build** — `lib/features/vehicles/presentation/vehicle_edit_screen.dart` and
  `vehicle_edit_notifier.dart`. Labels sit above their controls so German wraps freely; the
  two disclosure groups (**Purchase and sale**, **This vehicle's units & currency**) are
  collapsed by default.
  The dirty dismiss calls **EPIC-08 task 8.8's `showDiscardDialog`** from
  `lib/ui/dialogs/discard_dialog.dart`, through EPIC-08's `DirtyModalGuard` — this task
  supplies the `subject` and `summary` and owns the draft it drops, and writes no dialog of
  its own.
  Then `test/parity/vehicle_edit_parity_test.dart`.
- **Verify**
  ```bash
  flutter test test/features/vehicles/
  flutter test test/parity/vehicle_edit_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/vehicle.edit-light-ltr.png vehicle.edit \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/vehicle.edit-light-ltr.png        # look at the side-by-side
  ```
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity` for `vehicle.edit`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The odometer row is read-only in edit mode and an input only in create mode, proven by two tests.
  - [ ] The dirty dismiss calls EPIC-08's shared `showDiscardDialog`, and `lib/features/vehicles/` contains no discard dialog of its own.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

---

### Task 9.6 — Build `vehicles`, and wire the confirm-delete dialog

- **Goal** — the garage: list, reorder, sell, archive and delete, with a confirmation that names exactly what dies.
- **Spec** — §8 *`vehicles` — the garage* (the status-dot table, the six states, the interaction table, Sold and archived, Delete); §14 *Vehicle lifecycle*; §3 *Identity, timestamps, deletion*.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `ui-states-and-feedback`, `state-management-riverpod`, `navigation-and-routing`, `persistence-drift`.
- **Write these tests first** — `test/features/vehicles/vehicles_screen_test.dart`:
  - `the third line spells out the status for each dueSummary case` — five tests, one per §8 row: "Oil and filter overdue", "Oil due in 3 days", "All good", "Odometer needs updating", "No reminders yet". Colour is never the only signal.
  - `the status dot shape differs per state` — filled red, filled amber, small grey, hollow ring — so the set reads in greyscale.
  - `the active vehicle carries no mark` — marking it invites the tap this screen refuses.
  - `tapping a row opens vehicle.edit and never switches the active vehicle`.
  - `a reading 61–180 days old renders ~187,400 km in the estimated treatment, rounded to the nearest 100 km, with "Odometer last updated 4 months ago"`.
  - `a reading over 180 days old renders 187,412 km · last entered 12 Jul 2025, with no ~ and a hollow dot`.
  - `a sold vehicle computes no reminders and its card shows —`.
  - `an archived vehicle still computes reminders and shows them in-app`.
  - `a dueSummary that throws still renders the row with a hollow dot and "Couldn't work out what's due"` — the row never disappears.
  - `one vehicle hides drag handles and the section header, and the delete dialog adds "This is your only vehicle. Deleting it starts Odova over."`
  - `sold and archived sort to the bottom regardless of sort_order, and collapse to a counted header above five`.
  - `swipe end actions are Mark as sold then Delete, declared as endActions, and the physical direction flips in RTL`.
  - `entry counts use an explicit =0 plural case`.
  - `test/features/vehicles/confirm_delete_dialog_test.dart` — the garage's own behavioural tests, run against EPIC-08's `showConfirmDeleteDialog` as this screen calls it:
  - `zero entries gives a one-tap Delete with no typed confirmation`.
  - `one or more entries requires typing the vehicle name, and Delete stays disabled until it matches`.
  - `a mismatch reads "That doesn't match The Golf."`
  - `the dialog names the total and the five per-type counts` — "Delete The Golf and its 412 entries?" then "96 fill-ups, 14 services, 22 costs, 8 trips and 16 reminders will be removed permanently."
  - `Keep it — mark it sold opens the sale form and deletes nothing` — offered before Delete because it is what people usually mean.
  - `the Undo snackbar lives 10 seconds, not the usual 6`.
  - `deleting the active vehicle promotes the next live vehicle in sort_order and resets all four tab stacks`.
  - `deleting the last vehicle routes to firstrun.vehicle with the Undo snackbar above the modal, and Undo returns to vehicles`.
  - `there is no empty state, because the screen is unreachable without a vehicle` — a test that asserts no empty-state widget exists in the tree for any reachable input.
- **Then build** — `lib/features/vehicles/presentation/vehicles_screen.dart`,
  `vehicles_notifier.dart`, and the row widget as a `const` `CalmListRow` composition with the
  silhouette avatar on the vehicle's colour. Long-press drag writes `sort_order` through the
  repository. Delete calls **EPIC-08 task 8.9's `showConfirmDeleteDialog`** from
  `lib/ui/dialogs/confirm_delete_dialog.dart`, handing it the subject name, the five
  `entryCounts` and the "Keep it — mark it sold" alternative; the dialog returns a decision
  and this screen performs the delete.
  Then `test/parity/vehicles_parity_test.dart`.
- **Verify**
  ```bash
  flutter test test/features/vehicles/
  flutter test test/parity/vehicles_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/vehicles-light-ltr.png vehicles \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/vehicles-light-ltr.png            # look at the side-by-side
  ```
  If a status colour fails the token check, read it against `calm-due-state-and-status` before
  touching anything — the usual cause is a state resolving to `unknown` where the reference
  shows `overdue`, which is a fixture problem in the parity harness, not a palette problem.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity` for `vehicles`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] Delete calls EPIC-08's shared `showConfirmDeleteDialog`, and `lib/features/vehicles/` contains no confirm-delete dialog of its own.
  - [ ] All five status rows spell the state out in words as well as colour.
  - [ ] Both the stale (>60 d) and expired (>180 d) odometer treatments are asserted.
  - [ ] The typed confirmation is required exactly when the entry count is non-zero.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

---

### Task 9.7 — Build `vehicle.switcher`

- **Goal** — change the active vehicle in one tap, from a sheet that does not exist for the majority of users who own one car.
- **Spec** — §8 *`vehicle.switcher`*; §7 *Navigation graph* (`vehicle.switcher` edges); §3 *Scope: global vs per vehicle*.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`, `navigation-and-routing`, `state-management-riverpod`.
- **Write these tests first** — `test/features/vehicles/vehicle_switcher_test.dart`:
  - `the sheet does not exist with one vehicle, and the Home title is plain non-tappable text with no chevron and no "1 of 1"`.
  - `live vehicles list in sort_order with the active one marked by a checkmark on the end edge and nothing else`.
  - `each vehicle's odometer renders in that vehicle's own distance_unit, not the active one's` — a household with a van in miles and a bike in km.
  - `tapping a vehicle writes Settings.active_vehicle_id, dismisses, and resets all four tab stacks`.
  - `switching also resets the history filters and the Costs range`.
  - `tap-out and back change nothing`.
  - `sold and archived sit behind a collapsed disclosure with a count`.
  - `above eight vehicles the list scrolls and the two footer actions stay pinned to the bottom`.
  - `Add vehicle stacks vehicle.edit over the sheet; on Save the new vehicle becomes active and both dismiss`.
  - `Manage vehicles dismisses and pushes vehicles into the current tab's stack, not into Settings`.
  - `the stale and expired odometer treatments match the vehicles screen` — one shared widget, asserted by using it.
  - `the checkmark and the + never mirror; the sheet content does`.
- **Then build** — `lib/features/vehicles/presentation/vehicle_switcher_sheet.dart` and its
  notifier. A `CalmSheet` at partial height, tap-out to dismiss. The odometer-with-status row
  is the same widget `vehicles` uses, parameterised, not a second copy. Writes exactly one
  field: `Settings.active_vehicle_id`.
  Then `test/parity/vehicle_switcher_parity_test.dart`.
- **Verify**
  ```bash
  flutter test test/features/vehicles/vehicle_switcher_test.dart
  flutter test test/parity/vehicle_switcher_parity_test.dart      # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/vehicle.switcher-light-ltr.png vehicle.switcher \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/vehicle.switcher-light-ltr.png    # look at the side-by-side
  ```
  The sheet is captured over its scrim at the reference's 390×844, so the band check runs
  against the whole frame the reference shot, not the sheet in isolation.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight, icon shape or optical alignment.
  - [ ] The one-vehicle case is proven to have no sheet and no tappable title.
  - [ ] Per-vehicle `distance_unit` is honoured per row.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 9.8 — Wire the launch-state contract and the first-run gate

- **Goal** — every way the app can open lands on the right screen, and no user ever sees the language step twice.
- **Spec** — §7 *Navigation graph → Launch and first run* (every row is a case); §8 *Navigation* on each screen; §14 *Last vehicle deleted*.
- **Skills** — `navigation-and-routing`, `state-management-riverpod`, `ui-states-and-feedback`, `calm-visual-parity`.
- **Write these tests first** — `test/app/routing/launch_state_test.dart`, one case per §7 row:
  - `no prior run opens firstrun.language`.
  - `zero vehicles with onboarding_done true opens firstrun.vehicle and never repeats the language step` — the user deleted their last vehicle.
  - `one or more vehicles opens Home on the Home tab, never the last-used tab`.
  - `modal state is never restored across a cold start`.
  - `a successful firstRun import routes to Home with onboarding_done set by the import, not read from the file`.
  - `a cancelled or rejected file returns to the firstRun screen it was opened from, with nothing written`.
  - `Android system back exits the app from firstrun.language and is swallowed on firstrun.vehicle`.
  - `switching the active vehicle resets all four tab stacks`.
  - `an import resets all four tab stacks` — the only other event that does.
  - `the vehicles route pushes into the current tab's stack from the switcher, and into the Settings stack from the Settings row`.
  - `a launch after a failed migration opens settings.backup instead of Home` — asserted as a route intent; EPIC-15 owns the screen.
- **Then build** — `lib/features/first_run/first_run_gate.dart` (a redirect over
  `Settings.onboarding_done` and the live vehicle count) and the `go_router` entries for the
  five screens in this epic, registered into the existing single router. Tab-stack reset is
  one function called by exactly two events, not a reset scattered per caller.
- **Verify**
  ```bash
  flutter test test/app/routing/
  flutter test test/parity/                                       # all four combinations, all 5 screens
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  ```
  The last command must report `ok 20 screen(s) match the design reference` before this epic
  closes — this is the run that catches a screen a later task in this epic broke.
- **Done when**
  - [ ] Every row of §7's launch table has a named test.
  - [ ] The tab-stack reset has one implementation and two callers.
  - [ ] `check_parity.sh` is clean over all 20 captures from this epic.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Spec findings raised by this epic

| Id | Finding | Handling |
|---|---|---|
| F-9.1 | §8's first-run screen offers four annual-distance bands — `<10k`, `10–20k`, `20–30k`, `30k+` — and never says what `expected_annual_m` each writes, nor what they read on a miles vehicle. The projection's `assumed` rung depends on the number. | **Blocks task 9.4's band test.** Settle the four values (and their mile equivalents, per §4.8's "defined per unit system, not converted") in `SPEC.md` §8 in the same PR. Nothing is invented in code. |
| F-9.2 | §8 says deleting a vehicle "writes no safety copy … after the snackbar expires the recovery path is the user's own exported backup". §14 says recovery is "Settings → Backup & restore → **Undo last change**, live for 30 days — one row that covers import, delete-all *and* vehicle delete". §2 says "no trash, no 30-day bin". | §8 and §2 agree against §14; task 9.6 implements the 10-second Undo and no safety copy. §14's clause is corrected in this PR. |
| F-9.3 | The first-run restore link is "Moving from another phone? Restore a backup" in §8 and "I already have an Odova backup" in §14. | **The finding mis-framed it as one string with two spellings; they are two strings on two screens.** `design/reference/calm/` draws the two-line form on `firstrun.language` and the one-line form on `firstrun.vehicle`, and §14 was describing the second. Task 9.3 first "corrected" §14 to §8's wording, which was wrong, and task 9.4 put it back with the reason the two differ: by the vehicle screen the user has already declined the offer once, so the second ask is the short one. §8's ASCII sketch for `firstrun.vehicle` was the stale part and now shows the single link. Both strings go into the ARB. |
| F-9.4 | §7's screen list has no `firstrun.language` or `firstrun.vehicle` — it calls both "`settings.language` (firstRun)" and "`vehicle.edit` (firstRun)", and §14 says "No new screen id". But `design/reference/calm/` ships `firstrun.language` and `firstrun.vehicle` as their own references. | Route ids follow §7; **capture filenames follow the reference set**, or the comparison tool has nothing to compare against. Stated in tasks 9.3 and 9.4 and added as a note to §7's screen list. |
| F-9.5 | §8's garage third line needs the worst item's label ("Oil and filter overdue"), but §3 defines `dueSummary(vehicle)` only as "status counts for Home". | Covered by EPIC-07's F-7.8, which adds `worst` and `worstItem` to `DueSummary`. Task 9.6 consumes it. |
| F-9.6 | This epic's declared dependencies are EPIC-03, 04 and 05, but `vehicles` and `vehicle.switcher` read `dueSummary` and `estimateOdometer`, which EPIC-07 delivers. | The recommended order puts EPIC-07 first, so this is a documentation gap rather than a build order problem. The §8 fallback — hollow dot, "Couldn't work out what's due" — is a required test in task 9.6 regardless, so the screens render either way. Add EPIC-07 to this epic's dependency row in `epics/README.md`. |
| F-9.8 | §8 and §5 both wrote the not-translated line as *"Odova isn't translated into {device_language} yet…"* — §5 spelling the placeholder `device_language` and §8 `deviceLanguage` — and called it "an ICU message with the language name in its own language". Nothing in the dependency set can fill it: `intl` carries no locale display names and `flutter_localizations` ships translations, not language names. | **Settled in `SPEC.md` §5 and §8 in this PR: the placeholder is removed** and the line reads "…into your device's language yet". A hand-written endonym table is unbounded — the line fires for any language that is not one of the six — and every row is a factual datum in a script its author cannot check, which §2 forbids. A misspelling of somebody's own language, in their own script, on the app's first screen is the most expensive place to be wrong, and the sentence does its whole job without the name. If a bundled CLDR endonym source is ever added deliberately, the placeholder returns with it. |
| F-9.9 | §8's field table lists `is_business` as a switch on the first-run screen and its ASCII sketch draws *Do you drive this for work?*. The artboard has no such control and neither do the four reference PNGs. | **The reference is the authority (CLAUDE.md §7), so the switch is dropped from first run** and §8's table and sketch are corrected in this PR. `is_business` is still SET here — `vehicle_type = van` turns it on, unchanged — and `vehicle.edit` carries the switch one screen later. The question is what goes: nine users in ten answer no to it, on the screen with the least room, and the van tile has already answered it for the tenth. Five controls, not six. |
| F-9.10 | §8 wants Start "visibly disabled" AND wants a tap on it to flash the odometer hint. `CalmButton` asserts that a disabled button has a `CalmButtonExplain` beneath it, and `CalmPressable` wraps a disabled button in an `IgnorePointer`, so neither half is buildable as the widgets stand. | Both halves are kept, because SPEC's reasoning holds — one required field, hint always visible. `CalmButton` gains a way to NAME the always-visible explanation that stands in for the printed one, so the assertion is satisfied by a sentence a reviewer reads rather than by an `// ignore:`; and the tap is caught by the region around the button, since a disabled control cannot receive one. Recorded in §8's *Save disabled* row. |
| F-9.11 | §8's field table says the type control is "3 icon tiles + Other in the overflow"; the artboard draws three options and no overflow, leaving `truck` and `other` unreachable at first run. | **Three tiles, and nothing is lost.** §4.8's seeded set has three distinct outcomes and `truck` and `other` both "take the car set unchanged" — so a truck owner tapping **Car** gets exactly the right rows and corrects the label in `vehicle.edit`. An overflow here would buy a more accurate word and not one different reminder. §8 corrected in this PR. |
| F-9.12 | §8's RTL paragraph says band chips "carry a `maxChars` budget and read '<10 Tsd.' rather than truncating", and supplies no budget. | Moot, and the artboard is why: the unit moved off the chips and into the label — "About how far a year? (thousand km)" over `under 10` / `10–20` / `20–30` / `over 30`. Two words at most, in every locale, with nothing to truncate. The `maxChars` sentence is replaced in this PR. |
| F-9.13 | §8 specifies the **More…** fuel overflow only by its contents (LPG, CNG, Hybrid, Other) — sheet, menu or dialog is undefined, and there is no artboard for it. | **A sheet.** Four values, picked one at a time, nothing to type — the same shape as every other pick-one list in the app, including `vehicle.switcher` and `settings.units`' currency picker. A menu would be a fourth overlay kind for four items. Stated in §8 in this PR. |
| F-9.14 | The `firstrun.vehicle` artboard draws a FILLED form — name "The Golf", Diesel selected, odometer 187,412 — where §8's Loaded state is prefilled "My car", petrol, and an EMPTY odometer. The reference therefore pins a state the app never opens in. | Not a contradiction to fix: an artboard shows a screen doing its job, and an empty form shows nothing. The parity harness seeds exactly the artboard's three values, so the capture is the shipped widget in a state it can really hold, and the screen test asserts the real Loaded state separately. |
| F-9.15 | Task 9.2's handover said `firstrun.vehicle` "must ask" whether a motorcycle is liquid-cooled, because §4.8.3 seeds `coolant` on a liquid-cooled bike and never on an air-cooled one, and Odova stores no cooling field. The artboard has no such control, and neither does `vehicle.edit`'s field table — so there is nowhere to ask it after creation either. | **First run does not ask; a motorcycle seeds air-cooled.** The two ways to be wrong are not equal. A MISSING coolant reminder is covered by §4.8's own header — "Starting points, not manufacturer advice. Your handbook wins — edit anything here" — and the rider adds it in `reminders.edit` in four taps. A coolant reminder on an air-cooled bike is the app inventing a job that does not exist on that machine, which is §2's rule about never guessing in a way that looks like fact. `liquidCooled` stays a parameter of the seeder, for a caller that has the answer; no screen supplies one today. |
| F-9.16 | **`firstrun.vehicle` fails its band check in all four combinations — 50/89, 46/86, 50/89, 48/84 against a 75% floor — and the cause is one thing.** Calm paints `.chip` at `min-height: 40px` and `.segmented__opt` at 46, while `RenderCalmTapTarget` meets SPEC.md §17's 52pt floor by growing the LAYOUT box. So every chip lays out 52 and every flat segmented option lays out 52, and the chipbar comes out 60 where the artboard is 48. Measured: the app tracks the reference to within 3px down to the Fuel label, gains ~25px across the chipbar, and the footer is pinned so the middle of the screen is stretched. Nothing else differs — colour and theme pass, and the pixel diff is 7–14%. | **Not fixed here, and not papered over.** `calm_touch_targets_test.dart`'s own comment already states the intent — "several Calm widgets paint smaller than they hit on purpose — a chip paints 40, a small button 42, a modal action 44" — which the implementation does not do. Three resolutions exist and choosing between them is a design decision, not an engineering one: **(a)** the target overflows the paint, which keeps both the drawing and the floor but only works where no ancestor clips — inside `CalmChipBar`'s scroll viewport the overflow is limited to the bar's own 4pt padding, giving 48 and not 52; **(b)** the bar grows to 52, which is +4 on the artboard and exactly at the band tolerance; **(c)** the floor drops to 48 for chips, which is a WCAG 2.5.5 decision and belongs beside `design/calm/ACCESSIBILITY-FINDING.md`. **EPIC-17 owns it**, it blocks parity on every screen with a chipbar or a flat segmented control — `log.fillup`, `reminders.edit`, `history`, `costs` — and no tolerance is widened and no reference re-shot to hide it in the meantime. |
| F-9.17 | §8's field table draws the odometer as "numeric keypad + unit chip" and its ASCII sketch shows `│ km ▾ │` with a caret. The artboard has a plain `.inputgroup__affix` span — no button, no caret — and neither do the four reference PNGs. | **The affix is not a control.** The reference is the authority, and the design is right for this screen: the unit already comes from the device region, which `firstrun.language`'s Continue seeded into `Settings.distance_unit` a moment earlier, so a switcher here offers to change a thing the app has just got right. §8's own sentence still holds and is what the test asserts — "The unit chip writes `Settings.distance_unit` rather than a per-vehicle override" — because the vehicle row's `distance_unit` is written as NULL and the global is the only place the unit lives. `vehicle.edit` carries the six per-vehicle overrides for anyone who needs them. |
| F-9.18 | §8 lists `colour` as "10 swatches — white, silver, grey, black, red, blue, green, yellow, brown, other". The artboard draws EIGHT, inline as raw hex, with no brown and no `other`; `.swatchrow` is `flex-wrap: wrap`, so a ninth or tenth would drop to a second line and make the screen taller than the reference. The eight hex values exist nowhere as tokens — not in `odova.css`, not in `lib/`. | **Nine, in a row that scrolls.** Wrapping means the screen changes height as the palette grows, which is exactly the instability §9's calm avoids, so the row scrolls like every other horizontal run of choices — and the reference stays matchable, because the first eight sit where they always did. **Brown goes**, and that is an admission rather than a decision: the eight paints are hand-tuned against each other and a ninth hex chosen to sit beside them is design work this epic cannot do; a brown that fights the other eight is worse than no brown. **`other` stays and is not a paint** — an outlined swatch with no fill, which is the honest drawing of "not one of these" and invents no colour. The eight hex values are design data and live in `lib/theme/calm/` beside the other palettes, never in `lib/features/`. §8 corrected in this PR. |
| F-9.19 | The artboard's modal close is an ✕ ICON with `aria-label="Close"`; `CalmAppBar.modal` takes a required `String startLabel` and renders it as a `Text`. There is no way to draw the reference's header. | `CalmAppBar.modal` gains an optional start ICON. The label stays required and becomes the semantic label, because a bare glyph with no accessible name is the defect the required parameter was there to prevent — the change is what the glyph looks like, not whether it has a name. |
| F-9.20 | §8's normal-mode sketch draws a VIN field, two disclosure groups (**Purchase and sale**, **This vehicle's units & currency**) and a plain `Delete vehicle`; the artboard has no VIN field, neither disclosure, and a delete row reading "Delete Golf and its 412 entries". §8's own prose then names notes, `expected_annual_m`, `is_business`, `notifications_muted`, purchase date and price — none of which the artboard draws either. | **The artboard is a crop, not a contradiction.** It shows the screen's top; §8's prose is the full field list and the disclosures are what keep it from being a wall. So the screen is built to §8's prose, and the PARITY CAPTURE is taken with the two disclosure groups COLLAPSED, which is their default state and what the artboard is drawing. The delete row's wording follows the artboard — it is a row, not a dialog title, so it takes no question mark and gets its own ARB key rather than reusing `confirmDeleteTitle`. |
| F-9.21 | §8 and `lib/core/domain/enums.dart` give `VehicleType` five values (`car\|van\|motorcycle\|truck\|other`); the artboard's `.segmented--four` draws Car / Van / Motorbike / Other, and §8's own sketch shows `[car][moto][van][…]` — an overflow ellipsis. There is no way to select `truck` on the drawn screen. | Four segments as drawn, and `truck` is reachable only through an import or a future overflow. That is the same shape as F-9.11's answer for first run and rests on the same fact: §4.8 gives `truck` the car set unchanged, so the choice costs the user nothing but a label. **Raised rather than closed** — unlike first run, this IS the screen where a truck owner would go to fix the label, and finding it absent is a dead end. EPIC-14 or a later PR adds the overflow; the enum keeps all five so an imported truck round-trips. |
| F-9.22 | On `vehicle.edit`, the vehicle-TYPE segment and the colour SWATCH are both called **Other** in English, and both are unlabelled controls that announce only that word. A screen reader on one screen hears "Other, button" twice, at opposite ends of the form. | German already distinguishes them and English cannot: `vehicleTypeOther` is *Sonstiges* (agreeing with Fahrzeug, neuter) and `colourOther` is *Sonstige* (agreeing with Farbe, feminine), so the collision is a fact about English rather than about the design. **Raised, not fixed.** The cheap repair is a distinguishing accessibility label on the swatch — a new ARB key in six languages — and it is worth pairing with a sweep for the other `Other`s the app will grow (expense categories, fuel kinds, which already ships one). The test scopes its search to the swatch row and says why. |
| F-9.7 | §8 says a `unit_mixup` correction is the arithmetic for a swapped cluster, and §3's `OdometerCorrection.reason` enum includes `unit_mixup`; §14 says "`unit_mixup` is removed as a correction reason". | Not blocking here — no screen in this epic writes a correction — but EPIC-05's enum and EPIC-11's `log.odometer` both depend on the answer. Raised for the reminders and logging epics. |

## Definition of done

- [ ] The five screens exist, are reachable by the §7 edges, and are built from `lib/ui/calm/` components with no `BoxDecoration` and no raw colour, duration, radius or font size in `lib/features/`.
- [ ] Every user-visible string in `lib/features/first_run/` and `lib/features/vehicles/` is an ARB key present in `en de fr fa ar ckb`, with an explicit `=0` case on every count.
- [ ] `VehicleRepository` is the single write path, and no feature file touches a DAO.
- [ ] The seeded catalogue accounts for all 28 `ServiceKind` values, proven by a test.
- [ ] Every row of §7's launch-and-first-run table has a passing test.
- [ ] The findings above are fixed in `SPEC.md` in this PR or answered in writing in the PR body; F-9.1 is settled before task 9.4 is called done.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-09.md`.** It starts
empty. Append one line per task as it completes — what was built, what was deferred, and
anything the next epic needs to know. It is the running log for this epic and the handover to
the next one.
