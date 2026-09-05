# EPIC-09 — first run, the garage and vehicles

## Task 9.2 — the seeded catalogue ✅ (taken before 9.1)

`lib/core/reminders/service_item_catalogue.dart`,
`test/core/reminders/service_item_catalogue_test.dart` (23 tests, 6 mutations).

- **Order swapped deliberately**: `VehicleRepository.create` seeds from the
  catalogue, so the catalogue is built first. The epic lists 9.1 before 9.2.
- **`liquidCooled` is a parameter, not an inference.** §4.8.3 seeds `coolant` on
  a liquid-cooled motorcycle and never on an air-cooled one, and Odova stores no
  cooling field. **`firstrun.vehicle` (task 9.4) must ask** when the type is
  `motorcycle`, or every motorcycle gets the air-cooled set by default.
- **Two things the tables imply and the prose does not state**, both now tests:
  spark plugs are seeded on petrol, LPG, CNG and hybrid only (so a diesel gets
  15 rows, not 16), and the 28-value accounting is §4.8.5's stated invariant.
- The table is `const` and copied at creation. Changing a number changes what
  the NEXT vehicle gets and never touches one that exists.

## Task 9.1 — `VehicleRepository` and the garage data layer ✅

Added to EPIC-05's repository: `watchGarage`, `create(VehicleDraft)`,
`entryCounts`, `reorder`, `markSold`, `archive`. Soft delete, undo and purge
already existed as `lib/data/repositories/deletion.dart`'s free functions and
are NOT duplicated — task 9.6 calls them.

- **`VehicleRepository` now takes a `UlidFactory`.** Every existing test call
  site was updated; `testUlids()` in `test/support/values.dart` is the shared
  fixed-clock, seeded-`Random` factory.
- **A diesel seeds 15 items, a petrol car 16.** Asserted from both sides.
- **`reorder`'s all-or-nothing test needs a non-zero starting `sort_order`**, or
  a half-applied reorder is indistinguishable from an aborted one — the first
  version passed against the mutation.
- **I committed this task with the suite red.** Two policy gates were failing:
  `lib/core/reminders/` was an unnamed subject, and `draft.odometer.metres`
  unwrapped a value object outside the mapper. Both were right. Fixed forward in
  the following commit rather than amended, because a commit that knowingly
  leaves the suite red makes `git bisect` useless and the mistake is worth
  leaving visible.

## Spec findings — F-9.1 settled, F-9.2/3/4/6 corrected ✅ (`bc401f2`)

Taken before task 9.3 because **F-9.1 blocks task 9.4** and settling it late
would mean building `firstrun.vehicle` around a number nobody had decided.

- **F-9.1 — the four bands.** `SPEC.md` §8 now carries the table. Nothing was
  invented: the chip labels follow §4.8's own "per unit system, not converted"
  rule at the 0.6 ratio its seeded-interval table already uses throughout, and a
  closed band writes its **midpoint**. The one judgement call is the open `30k+`
  band, which writes a third above its floor — the damage is asymmetric, since
  an assumed rate that is too low lands the reminder *after* the service was
  needed while one too high only brings it forward. All eight values sit inside
  the engine's 5–500 km/day clamp (13.2 → 109.6), verified rather than assumed.
- **F-9.2 — §14 was the outlier, not §8.** It claimed a vehicle delete is
  recoverable for 30 days. §8, §4.4, §2 *and §14's own* "only four things
  destroy data" paragraph all disagree. Corrected, with the reason a vehicle
  delete is not a fourth safety-copy kind written down so it does not get
  re-litigated.
- **F-9.3** — §8's string wins; §14 now points at it rather than carrying a
  second copy that would drift again.
- **F-9.4** — §7 now states both halves: route ids follow §7's table, parity
  capture filenames follow the reference set. Task 9.3 and 9.4 capture as
  `firstrun.language` / `firstrun.vehicle` and route as `settings.language` /
  `vehicle.edit` in `firstRun` mode.
- **F-9.6 — the finding undercounted.** It said to add EPIC-07. EPIC-08 was
  missing from the same row too (tasks 9.5 and 9.6 call its dialogs into its
  router), and the ASCII graph three sections below already drew both edges. Row
  now reads `03, 04, 05, 07, 08`.
- **F-9.5 and F-9.7 need no spec edit here.** F-9.5 is EPIC-07's `worst` /
  `worstItem`, already delivered; F-9.7's `unit_mixup` is not written by any
  screen in this epic and stays open for EPIC-11.

**Deliberately not changed:** §12's worked backup example still carries
`expected_annual_m: 18000000`, which is not a band value. That is correct and
now says so in §8 — the four bands are what the *control* writes, the *field* is
a nullable integer, and import must accept a file written by a hand or a future
version rather than lose a vehicle over a fallback number.

## Task 9.3 — `firstrun.language` ✅

All four reference combinations pass `calm-visual-parity`. 11 screen tests, 4
notifier tests, 8 for the format defaults; every claim mutated and seen to fail.

**Three things had to exist before the screen could.**

- `CalmScaffold` could not express it: `appBar` was required and non-nullable,
  there was no `.screen__body--tight` (which **21 of the 28 artboards** use —
  the seven that do not are all forms), and no `.screen--brand` wash. The wash
  is the one the parity gate could never have caught: its colour census only
  inspects what the app paints, and a flat `bg` is a perfectly good Calm token.
- `CalmListRow` applied a fixed `s4` padding to all three sizes where the CSS
  has three values, so a compact row was 57.5pt in Latin and 61.2 in Arabic
  against a design that is 56 in both.
- Nothing supplied `distance_unit`, `volume_unit`, `consumption_unit` or
  `currency_default` by region. `lib/core/l10n/format_defaults.dart` now does,
  calling the three resolvers that already existed rather than re-deciding.

**Two defects the capture found, and the first is user-facing.** فارسی,
العربية and کوردیی ناوەندی rendered as **empty boxes** under an English UI:
SPEC §5 gives the Latin type no font family, so a Latin face was drawing them.
On a device the platform fallback fills them, so it would have shipped silently
— as a list drawn in whatever Arabic face the phone carries, beside the bundled
Vazirmatn the user gets the moment they tap one, and the hardest row to read
would be the one a person stuck in the wrong language is hunting for. Fixed the
way the artboard says: each row carries `lang="…"`, so `nativeTitle: bool`
became `nativeTitleLanguage: String?`. Second, `CalmRowGroup`'s dividers were
laid out (1px each) where the CSS paints an outset shadow taking zero height —
six pixels of drift over seven rows against a band tolerance of four. Bands went
49/76 → 64/76 and the pixel diff 5.6% → 4.5%.

**Deferred, deliberately.**

- **The file picker is a port with no implementation.** `filePickerProvider` in
  `lib/app/` is unwired and throws by name. EPIC-15 owns `settings.import` and
  brings the package that opens a real dialog; task 9.3 only needs the seam and
  "writes nothing on cancel".
- **`settings.language`'s artboard says `پیش‌فرض دستگاه (فارسی)` where
  `firstrun.language` says `سیستم (فارسی)`.** One ARB key serves both modes, so
  one has to lose; §5 and §8 write it only in English and supply no tiebreak.
  `سیستم` ships, matching the screen this task built. **EPIC-14 must settle it**
  when it composes `LanguageRowList` in the other mode.

**Two things for the next screen task.**

- Feature widget tests pump at **390×844**, not `flutter_test`'s 800×600. These
  screens scroll: at the default size the not-translated note falls outside the
  viewport and is never built, and `find.text` then reports it missing on a
  screen a real phone shows.
- The compact-row fix moved `dialog.snooze`'s band score from 34/72 to 45/72 —
  a real improvement to EPIC-08's deferred parity debt, still short of the 75%
  floor. The three dialogs remain the open item; `check_parity.sh` walks the
  whole of `build/parity`, so task 9.8's "ok 20 screens" has to reckon with them.

**Spec findings settled here.** F-9.8 (new): the not-translated line stopped
naming a language nothing in the dependency set can name. See the entry above
for F-9.1 through F-9.6.

## Task 9.4 — `firstrun.vehicle` and the create transaction ✅ (parity blocked)

Five controls, one required entry. 13 screen tests, 14 notifier tests, 5 for the
annual bands, 4 for the settings write. **Parity does NOT pass — see F-9.16.**

**Six design questions had to be settled before a line could be written**, all
in `SPEC.md` rather than in code: the work switch dropped (F-9.9), Start
disabled *and* tappable (F-9.10), three type tiles and no overflow (F-9.11), the
band `maxChars` made moot by moving the unit into the label (F-9.12), More… as a
sheet (F-9.13), and the artboard's filled form accepted as the parity state
(F-9.14). Two more surfaced while building: no liquid-cooled question (F-9.15)
and the odometer affix is not a control (F-9.17).

**Two defects in code that already existed.**

- **`VehicleRepository.create` never wrote `Settings`.** SPEC §8's Data out
  lists four writes and it did three, so first run would have created a car and
  then bounced the user back to the first-run screen forever — nothing else in
  the app sets `onboarding_done`. Now inside the same transaction, behind
  `asFirstVehicle:` so the garage's + never steals the active slot.
- **One German string addressed the user as *du*** where ten used *Sie*.
  `SPEC.md` §5 now decides the register and `test/l10n/register_test.dart`
  catches the next one.

**F-9.16 — parity fails in all four combinations, and the cause is exactly one
thing.** 50/89, 46/86, 50/89, 48/84 against a 75% floor, with colour and theme
green and a 7–14% pixel diff. Measured, not guessed: the app tracks the
reference to within 3px down to the Fuel label, gains ~25px across the chipbar,
and holds it. `.chip` paints 40 and `.segmented__opt` 46, while
`RenderCalmTapTarget` meets the 52pt floor by growing the LAYOUT box — so a
chipbar the artboard draws at 48 comes out 60. `calm_touch_targets_test.dart`'s
own comment already says the intent is "paint smaller than they hit". **This
blocks every screen with a chipbar or a flat segmented control** — `log.fillup`,
`reminders.edit`, `history`, `costs` — and the fix is a design decision with
three defensible answers, so EPIC-17 owns it. **No tolerance widened, no
reference re-shot.**

**Deferred, deliberately.** `Restore a backup ... pushes settings.import` — the
picker seam is called and cancel is proven to write nothing; EPIC-15 owns the
import screen and the package that opens a real dialog.

**Three things for the next task.**

- **Assert that a mutation applied.** Three mutations in this epic reported
  green because `str.replace` silently matched nothing after `dart format`
  reflowed the source. A mutation that does not check itself is indistinguishable
  from a passing gate.
- **A drift future never completes under `testWidgets`** — the symptom is a
  ten-minute hang with no output. Database assertions go in a plain `test`.
- **A new `ProviderScope` is a cold start, not a return from the background.**
  To test state restoration, change the widget's KEY so the State is rebuilt
  under the same container.

## Task 9.5 — `vehicle.edit` 🟡 PART BUILT (create mode landed later; see the
`/code-review` section at the end)

**Not complete, and the parts that are missing are named below rather than
stubbed.** What exists is tested and green: 11 screen tests, 7 notifier tests,
11 draft tests, 4 for the disclosure, 4 for the swatches.

**Five design questions settled first** (F-9.18–F-9.22), one of them an
admission: brown leaves the swatch row because the eight paints are hand-tuned
against each other and a ninth hex is design work rather than engineering.
`other` ships as an outlined swatch that invents no colour, and the row scrolls
rather than wraps so the screen's height stops depending on the palette.

**Four component gaps closed.** A modal that closes with a glyph and keeps its
accessible name; a brand icon tile that cannot borrow a status colour; a field
that will not reorder an Iranian plate; and `CalmDisclosure`, composed from a
row because `odova.css` has no `.disclosure` to match.

**`VehicleEditDraft` exists because a `copyWith` cannot clear a field.** Passing
null means "leave it alone", so "delete what is in the box" and "do not touch
it" become the same call. Dirty is `Vehicle == Vehicle` rather than a field
list, so a twenty-first field is tracked the day it is added.

**The notifier reads its row ONCE.** A form that re-read itself would discard a
half-typed plate whenever anything else touched the vehicle — and its own Save
is one of those things.

### Still owed by task 9.5

- **The two disclosure groups' CONTENTS.** `Purchase and sale` and `This
  vehicle's units & currency` need a date picker, a money field and six override
  controls that do not exist. The groups are ABSENT from the screen rather than
  stubbed: a collapsed group that opens on nothing is a control that lies.
- ~~**The odometer read-only row**~~ — built, and its age now counts calendar
  days through `CivilDate` rather than a `Duration`.
- ~~**Mark as sold** and its sale form; **Delete**~~ — both wired, through
  `vehicle_actions.dart`, which the garage now shares.
- ~~**Create mode**~~ — built. It was not on this list when the list was
  written, which is how `Routes.vehicleNew` reached `/code-review` opening an
  empty modal.
- **The parity capture is taken and FAILS**, in all four combinations —
  30/94, 27/93, 24/90, 23/84 against a 75% floor, with colour and theme green.
  Two causes, both known and neither papered over. **F-9.16**: the swatches are
  26pt paint inside a 52pt tap target, so the row is laid out at 60 where the
  design draws 34 — the same defect as the chips, in a third place.
  **F-9.20 revised**: the artboard turned out to be the COMPLETE screen rather
  than a crop, and it has no VIN and no Notes field where §8's prose lists
  both. Content won: deleting a field a user's data already holds, to make a
  screenshot match, is not a trade this epic will make. They belong in a
  collapsed group and go there when F-9.23's disclosure contents arrive.

### Two findings worth carrying

- **Two translators reviewed my English before any test did.** I wrote
  `{countText} entries` and `{item} due in {countText} days` without plurals,
  which render "1 entries" and "in 1 days"; the German and French agents
  translated them faithfully and then said the source was wrong. Both are fixed
  and both now carry every category their locale needs.
- **A gate forbade the call this task mandates.** `discard_dialog_test.dart`
  banned `showDiscardDialog` from every file but its own, which was right while
  the caller count was zero and wrong the moment a modal called it. It is an
  allow-list now, with an outright ban on DECLARING a second dialog — and the
  declaration check matches a declaration rather than a mention.

### Still to do in this epic
Task 9.5's remainder (listed above), then 9.6 `vehicles`, 9.7
`vehicle.switcher` and 9.8's launch-state wiring. Plus F-9.16, which every
screen with a chipbar or a flat segmented control will hit.

## Task 9.6 — `vehicles`, the garage

Seven commits, because the artboard needed four things the app did not have.

- **`0de8610`** the screen and its ten tests. No database in the test: a drift
  stream never delivers under `testWidgets` and the symptom is a ten-minute hang
  with no output. That is the THIRD time this epic; `provider_harness.dart` and
  now this file both say so. One pump per test, too — Riverpod asserts the
  override count is constant across a rebuild, so a test that pumped one vehicle
  and then two died inside `updateOverrides` rather than in an expectation.
- **`e0fcf6a`** `CalmListRow.detail` — a second sub-line. `.row__main` carries
  two `.row__sub` spans on ten rows across six artboards, so it belongs on the
  row rather than being rebuilt by the garage, `home`, `vehicle.switcher` and
  `dialog.confirmDelete` in turn. It also found that **`.row__main { gap: 2px }`
  was never implemented**: every row with a subtitle has been 2pt short since the
  component was written. Four `rows-*` goldens re-baselined for it and four
  `tile-*` for the lining figures.
- **`8181287`** the past side of the relative-date bucketing. SPEC.md §5's rule
  has no tense in it, but only the forward half was built, so `vehicle.edit` told
  users a reading was "123 days ago". A 30-day month passed every case I first
  wrote; the divisor is now pinned against `bucketRelativeDays` itself.
- **`add5f12`** `roundEstimateForDisplay`. SPEC.md §1.4 is binding on every
  screen and nothing implemented it. The unit is an argument, not a constant:
  1024 mi and 1025 mi both land on 1025.3 if you round to 100 km first.
- **`735af7b`** `formatLongDate`, and **a crash nobody had hit yet**. ICU carries
  no `ckb` date data at all — not sparse, absent — and `ckb-IQ` reads Gregorian,
  so `DateFormat.yMMMMd('ckb-IQ')` throws `Invalid locale`. A Sorani user in Iraq
  would have crashed on every screen with a date on it. `kurdishGregorianMonthNames`
  fixes it where `projectDate` already decides who supplies a month name.
- **`0b8d159`** the row the artboard draws, plus `CalmRowGroup.headerHint`.

### Two findings from this task

- **F-9.24 — SPEC's prose contradicted SPEC's own drawing.** §8 said a sold
  vehicle "shows `—`"; its own ASCII sketch and `screens.html` both show
  `Sold 12 March 2024 · 1,204 entries`, a compact row in a tinted group, and a
  chevron where the dot would be. `vehicleSoldSummary` — added earlier in this
  epic — had already assumed the drawing. SPEC.md is corrected; the em-dash test
  is deleted rather than left asserting a sentence nobody will see.
- **SPEC's `=0` rule collides with Arabic.** §8 requires an explicit `=0` plural
  case on entry counts. Adding one to Arabic made it render five distinct forms
  where it has six, because CLDR's Arabic `zero` category IS n = 0 and an `=0`
  clause shadows it. Arabic already owns the slot, so the date-only sentence
  lives in `zero` there and in `=0` in the other five. `plurals_test.dart` caught
  it; six ARB files do not show it to a reader.

### A golden that moves on its own
`--update-goldens` rewrote `segmented-light-ltr` and `segmented-dark-ltr` as
well. Stashing every lib change and re-running the flag showed those two move
with no code change at all: they are the cross-machine rasterisation noise
`test/flutter_test_config.dart` tolerates at 0.05%. They were NOT blessed —
doing so writes this host's rendering into the repo. Worth knowing before the
next person reaches for the flag and commits ten files.

### 9.6 continued — six more commits

- **`5051530`** the notifier: reorder, sell, delete, undo. `active_vehicle_test`'s
  "written in exactly one place" gate refused it, exactly as designed — the first
  version called `SettingsRepository.setActiveVehicle` directly and skipped the
  tab-stack reset SPEC.md §8 requires on promotion, leaving four stacks pointing
  at a deleted car. `setActiveVehicle` now takes a `ProviderReader` rather than a
  `ProviderContainer`, because a `Notifier` cannot produce one (Riverpod marks
  that accessor `@internal`) and the one sanctioned way to switch vehicles was
  locked out of the layer that decides to switch.
- **`55e4633`** `CalmSwipeActions`. `endActions`, never `rightActions` — half the
  locales are RTL. Custom semantics actions, because TalkBack and VoiceOver both
  spend horizontal swipes on navigation and Delete would be unreachable.
- **`114e14b`** the sale form and the delete flow. `confirm_delete_dialog_test`'s
  "one shared widget" gate refused this one, the same correction
  `discard_dialog_test` already carried in 9.5: an outright ban is right at zero
  callers and wrong at one.
- **`09c989c`** the parity capture.

### What the parity gate found
Four real defects, three of them invisible to every other test:

1. **`CalmRowGroup.header` drew the title inside the group's surface.** Nine
   artboards draw `.section__head` as a SIBLING and none draws a title inside a
   group. 48px of drift. It is `CalmSectionHead` now.
2. **`.row__main { gap: 2px }` is in the stylesheet and not in the drawing.** I
   added it on the CSS's word in `e0fcf6a`, with a golden re-baseline. The
   reference PNGs are the authority and a three-line row measures 103-106pt
   there, 104 flush, 108 with the gap. Removing it took LTR from 59/103 to
   81/103.
3. **The year rendered in Latin digits** beside a Persian odometer —
   `year.toString()` rather than `formatForDisplay`.
4. **Every silhouette was a car**, including the motorbikes.

Plus the harness now captures the tab bar, which every in-shell screen's
reference includes — and needs a transparent `Material` above it, or a `Text`
with no Material ancestor renders as a filled box with a yellow underline.

**Parity stands at: LTR ok (81%, 81%), RTL FAILING (55/100, 51/95).** The cause
is measured, not guessed: the row boundaries match within ±2pt, so the heights
are right, and the misses are intra-row Persian glyph edges where Skia and
Chrome distribute three tight 13.5pt line boxes differently.
`firstrun.language` reaches 84% in RTL with single-line rows, so the gate is
achievable — this is the first three-line RTL screen to meet it, and it does
not. No tolerance was widened and no reference regenerated.

### 9.6 closed
`2a50731` adds the long-press reorder — live vehicles only, because §8 sinks
sold ones regardless of `sort_order` and a drag there writes a number the
screen ignores. `onReorderItem` rather than the deprecated `onReorder`, which
reports a destination index computed before the removal.

The `+` and the row tap stay inert until 9.8 registers their routes.

## Task 9.7 — `vehicle.switcher`

- **`c75572d`** lifts the odometer-and-status line out of the garage row.
  Task 9.7 states the requirement before the screen exists: "the same widget
  `vehicles` uses, parameterised, not a second copy." A pure move — the garage's
  parity score was 81/103 before and after.
- **`111cec0`** a defect the switcher's tests found before the switcher: the
  shared line's unit fallback was a hard-coded `DistanceUnit.km`, so a miles
  user's vehicle with no override read in kilometres. On the garage that is one
  wrong row; on the switcher it is the screen's entire reason for existing.
- **`2593180`** the sheet. It writes ONE field and calls one function —
  `setActiveVehicle` — and tapping the vehicle that is already active writes
  nothing, because a no-op write still resets four tab stacks.
- **`aaded57`** the parity capture, and four component defects only it could
  find.

### What the switcher's parity gate found
1. **`MediaQueryData()` carries `Size.zero`.** The harness never gave it one,
   because no screen before this read `MediaQuery.sizeOf`. `CalmSheet` caps its
   height at a fraction of the screen, so the first capture photographed a sheet
   measuring 390x0.
2. **`.sheet__head` is a flex row and Calm drew a centred column** — and the
   enclosing `Column` defaulted to `center`, so the head shrink-wrapped and
   floated in the middle of the sheet.
3. **A `Row` there clips at 200%.** `calm_overflow_matrix_test` caught the fix
   for (2) immediately. It is a `Wrap` with `spaceBetween` now, which is the
   same layout on one line and moves the subtitle to a second when it must.
4. **The capture composed the tab bar over the overlay.** No dialog capture
   moved by a single edge when that was corrected, which is the check that it
   was a fix and not a re-baseline.

**Parity stands at 63/105 LTR, 30/79 RTL — failing.** Part of that is not the
sheet: `HomeBackdrop` is EPIC-08's stand-in for `home` and its edges are half
the frame. F-8.2 anticipated exactly this — "if the parity result CHANGES when
[the real screens] replace them, this stand-in was lying" — and that re-run
belongs to EPIC-10. This number is the before.

## Task 9.8 — the router, and the controls that were waiting for it

- **`f36ce07`** wires all five screens into the router that had been rendering
  `PlaceholderScreen` for them. `vehicle.edit` takes a NULLABLE `VehicleId`:
  `/settings/vehicles/not-an-id` is a link somebody can send, and parsing
  straight into a non-nullable parameter would have thrown in the route
  builder — a crash on a URL. Null draws the shell a missing vehicle draws.
- **`669aac6`** points every inert control somewhere. The garage's row tap opens
  the editor and **switches nothing**, which is now asserted by reading
  `active_vehicle_id` out of the database after the tap.

Two tests moved rather than being deleted: `route_table_test`'s id-bearing loop
gave up `vehicle.edit` to `vehicle_edit_route_test.dart`, which asserts the same
property against the real screen plus the unparseable case the placeholder could
never have had.

## F-9.25 — the RTL reference is 6pt shorter than its own stylesheet predicts

**This is why EPIC-09 closes with `check_parity.sh` red on RTL, and it is a
measurement rather than a shrug.**

A three-line row's height is `fs × lh` summed over its lines plus
`padding-block × 2`. Measured against the tokens in `odova.css`:

| | app | tokens predict | reference measures |
|---|---|---|---|
| Latin | **104.0** | 103.20 | 103–106 ✓ |
| Arabic | **115.0** | 114.60 | **109** ✗ |

The app draws what the stylesheet declares, in both scripts. The Latin reference
agrees with it. The Arabic reference is ~6pt short — about 2pt per line — which
is what accumulates past the band check's 4px tolerance and takes `vehicles`
RTL from a passing profile to 55/100.

`odova.css` gives `[lang="fa"] .device` a `--lh-body-lg` of 1.72 and a
`--lh-caption` of 1.68 against Latin's 1.5 and 1.45. A row built with Latin
leading and Persian sizes computes 108.4 — within a point of what the reference
measures. So the likeliest reading is that the RTL reference set was shot
before those overrides existed, or under a selector that did not match.

**Nothing was changed to make this pass.** No tolerance widened, no reference
regenerated — CLAUDE.md §7 forbids regenerating to clear a failure that was not
intended, and this one was not. Settling it means either re-shooting the RTL
reference set from the current stylesheet, or deciding the Arabic leading
overrides are wrong; both are design decisions and both belong in a deliberate
PR. EPIC-17 already owns one design decision for this codebase and is the
natural home.

What the RTL captures DID prove: the colour census and the theme check pass in
all four combinations on both screens, and looking at the sheets found the year
rendering in Latin digits, every silhouette drawn as a car, and the section head
inside its group.

### Parity, screen by screen, at the close of EPIC-09
| screen | LTR light | LTR dark | RTL light | RTL dark |
|---|---|---|---|---|
| `firstrun.language` | ok 84% | ok | ok 84% | ok |
| `firstrun.vehicle` | F-9.16 | F-9.16 | F-9.16 | F-9.16 |
| `vehicle.edit` | F-9.16 | F-9.16 | F-9.16 | F-9.16 |
| `vehicles` | **ok 79%** | **ok 79%** | F-9.25 | F-9.25 |
| `vehicle.switcher` | F-8.2 | F-8.2 | F-8.2 + F-9.25 | F-8.2 + F-9.25 |

Three named causes, none of them hidden: **F-9.16** is Calm's 40/46/26pt
controls against its own 52pt `--touch-min`; **F-9.25** is the row above;
**F-8.2** is EPIC-08's stand-in `HomeBackdrop`, whose edges are half the
switcher's frame and which EPIC-10 replaces with the real `home`.

## `/simplify` — what it found, and what was done

Four agents over `lib/**`. **Three findings were defects, not tidiness**, and one
of them would have failed the pipeline.

### Applied

- **`check_raw_values.sh` was RED on committed code** — a required CI step. Two
  hits, both mine: a raw `Duration` in `lib/ui/calm/` and two raw hexes in the
  garage silhouette. Moved to `lib/theme/calm/` (`kCalmDestructiveUndoWindow`,
  `calmVehicleSwatchInk`). I ran every other gate before the PR and would still
  have pushed red, because I never ran this one.
- **The garage drew NO hairlines.** `CalmRowGroup(rows: [ReorderableListView…])`
  passes one child and the divider rule is `i > 0`. A 1px line is under the
  parity band detector's threshold, so only a reader could see it. Reordering is
  `CalmRowGroup.onReorder` now — the only layer that can keep the surface, the
  scope and the dividers true under a drag — and parity went 81/103 → 83/103.
- **Two Latin digit leaks into Persian.** `vehicle.edit`'s age formatter forced
  `'en'` + Latin numerals (one reading read "۴ ماه پیش" in the garage and
  "4 months ago" one tap away), and the due-in-days count went through
  `'${days ?? 0}'` on the same line as a Persian odometer.
- Label tables lifted to `lib/l10n/vehicle_labels.dart` (three fuel copies, two
  type copies, three `km`/`mi` ternaries); `vehicleSilhouette` to
  `vehicle_status_line.dart`; `CivilDate.fromDateTime` (five hand-rolled
  `YYYY-MM-DD` builders); `DeleteCounts` to `lib/core/vehicles/`; six smaller
  derivable-state and duplication fixes; two free perf wins.

**Three policy gates refused these fixes and all three were right.**
`structure_test` caught `first_run` importing `vehicles`; `dialogs_write_nothing`
caught the dialog importing the data layer, which is how "the dialog cannot
delete anything" is a property rather than a promise; `check_raw_values` caught
the hexes. Each pushed the fix one layer deeper than I had put it.

### Answered, not applied

- **`neverSeeded` and `ServiceItemSeed.label` are dead code.** They are not.
  `neverSeeded` is the catalogue's statement about which kinds ship in the picker
  but never seed themselves — EPIC-10's `reminders.list` reads it, and deleting a
  documented product decision because its consumer is one epic away is how the
  decision gets made again, differently. `label` returning a constant null is the
  invariant "a seed's name is rendered FROM its kind, so a vehicle seeded in
  English reads correctly in all six languages"; the test asserting it is null is
  the test that a future edit does not quietly add a stored English string.
- **`_ColourRow`/`_Swatch` belong in `lib/ui/calm/` as `CalmSwatch`.** Agreed in
  principle, deferred deliberately: the artboard names `.swatch` and
  `.swatchrow`, so it is drawn design, but promoting it now means a component,
  its four states, its goldens and its parity re-check on a branch that is
  already 70 commits. EPIC-17 touches every swatch anyway (F-9.16 covers the
  26pt target), and that is the PR where it should land.
- **`setActiveVehicle` should be an `ActiveVehicleController` notifier rather
  than take a `ProviderReader`.** A fair reading, and probably the better shape.
  Not now: it moves the one function every screen uses to switch vehicles, and
  `active_vehicle_test.dart`'s "written in exactly one place" gate is a grep that
  would need rewriting in the same commit. A branch that has already had three
  gates catch it is not where I want to rewrite a gate.
- **A `CalmDatePicker` seam for `showDatePicker`.** Right, and premature: EPIC-11
  and EPIC-13 need the same picker, and the seam should be designed against three
  callers rather than extrapolated from one.
- **`due_snapshot_provider` should `select` the single vehicle instead of
  watching the whole list.** Real, and left alone: `select` over a list that must
  then be searched for one id trades a rebuild for a linear scan on every emit,
  and the garage is a handful of rows. Worth doing when a fleet screen exists to
  measure it.
- **`entryCounts` should be one statement with five subselects.** Real. Deferred
  because the five-count breakdown has one consumer today and the row that needs
  only the total is the sold row, which is rare by construction. Recorded rather
  than done.
- **`formatForDisplay` should cache its `NumberFormat`.** Pre-existing, outside
  this diff's scope, and a cache keyed wrongly (`grouped` mutates the instance)
  is worse than none. Recorded for EPIC-16's performance pass.



---

## The `/code-review` pass, and what task 9.5 still owed

`/code-review` ran over the epic's changes before the PR, as CLAUDE.md §5
requires. Twenty-one findings. What follows is every one of them, applied or
answered — and four of them turned out not to be review findings at all but
tasks 9.5 and 9.6 reporting themselves unfinished.

### The two that could not be reached from the app at all

- **`firstrun.language`'s Continue navigated nowhere.** It committed the
  settings and stopped. With `onboarding_done` still false — deliberately, so a
  kill between the two steps replays from the language step — the launch gate's
  rule 3 pinned the user to the screen they had just finished. A fresh install
  could never create a vehicle. Fixed with the edge that did not exist, plus the
  save-failure surface the vehicle screen already had.
- **`Routes.vehicleNew` opened an empty modal.** The router's only reading of
  the path was `VehicleId.tryParse`, which answers null for the `new` sentinel
  exactly as it does for `not-an-id` — so BOTH doors marked "+" opened the
  bad-deep-link shell with a live Save wired to `() {}`. This was task 9.5's
  create mode, unbuilt. It is built now: the odometer becomes an input, Mark as
  sold and Delete disappear, and Save pops with the new `VehicleId` so the
  caller can decide what it means. §8 gives the two doors opposite answers and
  they now give them.

### The rest, applied

- **A `dueSoon` distance-only reminder was drawn as overdue, in red.**
  `DueAssessment.remainingDays` is null for the five distance-only kinds, and
  `garageStatusOf` collapsed a missing count into `overdue`. A chain lube 200 km
  away read "Chain lube overdue". New `GarageStatus.due` — named, amber, no
  number. The test that had asserted the bug carried a comment justifying it.
- **The implausible-odometer warning BLOCKED Start**, against §8's "never a
  block" and the enum's own dartdoc. `canStart` is `odometerMetres != null` now:
  it asks whether the field holds a reading, not whether the app likes it.
- **Both switch rows on `vehicle.edit` passed `onChanged: (_) {}`**, making the
  switch a child recognizer that wins the gesture arena and does nothing. The
  row toggled everywhere except on the control. `CalmListRow.switchRow` now
  asserts it, in a non-const constructor so the assert can read the field.
- **`entryCounts` counted seeded reminders**, so §8's "Zero entries: one-tap
  Delete" had no reachable state — §4.8.3 seeds a set on every vehicle. See
  F-9.26 below.
- **A DST truncation in the odometer's age.** `DateUtils.dateOnly(a).difference
  (b).inDays` counts elapsed time, and two calendar days across a spring-forward
  are 47 hours. `CivilDate.daysUntil` documents the exact failure; a new gate,
  `test/policy/no_local_day_arithmetic_test.dart`, refuses the spelling, because
  a suite running in UTC — which CI does — cannot catch it.
- **Deleting the last ACTIVE vehicle left `active_vehicle_id` on a tombstone.**
  The promotion filter read `status == active`, which also excluded ARCHIVED
  ones — and §8's sentence starts "an archived vehicle can be active". Two
  orders of preference now, and delete and sale part company on a garage of
  nothing but sold cars.
- **Money conversion through a binary double.** 8,500.005 stored as 850000
  rather than 850001. `lib/core/money/minor_units.dart` does it with string
  arithmetic; replacing the body with the old double path fails three of its six
  tests.
- **A sold vehicle in the switcher reported its odometer's age** instead of §8's
  em dash. The sold check now comes first, as `garageStatusOf` already did it.
- **`vehicle.switcher` discarded `setActiveVehicle`'s `Result`**, closing the
  sheet on a write that had not happened.
- **`vehicle.edit`'s Mark as sold and Delete rows were inert**, with a comment
  saying task 9.6 owned them. This is task 9.6. The garage's flows moved to
  `vehicle_actions.dart` and both screens call them; the modal dismisses after a
  sale, because `VehicleEditDraft` copies `status` from the row it loaded and
  would write `active` back over the sale on the next Save.
- **Fourteen unused ARB keys.** Six of them were task 9.5's and 9.6's own
  unfinished work and are now rendered: `vehicleDuplicateNameNote`,
  `vehiclesOnlyOneWarning`, `vehicleSwitchToIt`, and the two new keys the create
  mode needed. The rest are named under "still deferred" below.

### F-9.26 — an entry is something the USER entered

SPEC.md §8 asks for two things that seeding puts in tension: "Zero entries:
one-tap Delete", and a dialog whose body names "16 reminders" among what dies.
Every vehicle is created with a seeded reminder set (§4.8.3), so a total that
counts them is never zero and the one-tap case has no reachable state — a car
added by mistake would demand its own name typed back twenty seconds later, to
protect eight reminders the next car gets for free.

**Decided:** `DeleteCountsTotal.total` counts the four LOGGED types. Reminders
are settings the app put there, not entries the user made; they stay in the
dialog's body, because the body says what is destroyed and they are destroyed.
The same definition governs the garage's sold row. Proved from a real
`create`: reminders > 0 and total == 0.

### Answered, not applied

- **`_asNew` lists twenty fields instead of using `copyWith`.** Deliberate, and
  the reason is why `VehicleEditDraft` exists at all: a `copyWith` over twenty
  nullable fields cannot say "clear this". A listed copy also makes the compiler
  name any column added to `Vehicle` later rather than dropping it silently.
- **`create` could take the extra facts on `VehicleDraft`.** Rejected: that is a
  second list of `Vehicle`'s columns kept in step by hand. `createVehicle` takes
  the row the form already knows how to build.
- **The odometer field could re-interpret its digits when the vehicle's unit
  override changes.** It does — and `OdometerEntry.copyWith` drops an accepted
  implausible warning with the unit, because 3,000,001 mi is not the number
  3,000,001 km was.

### Still deferred, with reasons

- **The two disclosure groups' contents** (`Purchase and sale`, `This vehicle's
  units & currency`) and with them `vehiclePurchaseDate`, `vehiclePurchasePrice`,
  `vehiclePurchaseOdometer`, `vehicleCurrencyChangeNote`, `commonAutomatic`.
  They need a date picker, a money field and six override controls. ABSENT
  rather than stubbed: a collapsed group that opens on nothing is a control that
  lies.
- **`vehicleFuelChangeNote`.** §8 pairs the fuel change with a one-time snackbar
  offering `reminders.list`, which EPIC-10 owns. A snackbar action pointing at a
  route that does not exist is worse than no snackbar.
- **`vehicleDeleteRow`** (the count-carrying label). §8's one-vehicle case spells
  the row "Delete The Golf", which is `vehicleDeleteRowEmpty`. The counted
  variant has no drawn home; it stays unused rather than being invented into
  one.
- **`dateTomorrow`, `unitVolume*`, `unitConsumption*`, `unitPerDistance`,
  `commonBack`, `commonEstimatedA11y`, `homeDueSoonNoConfidence`,
  `vehicleColourLabel`.** EPIC-10 and EPIC-11's, translated ahead of time on
  purpose — six locales in one commit is cheaper than six locales in six.
  (`vehicleColourLabel` is the one that is not a future epic's: the swatch row
  is drawn with no label in the artboard, and the key stays for the day a
  screen reader needs the group named — F-9.16's territory, EPIC-17.)

**Nineteen keys have no caller at the close of this epic**, down from
twenty-two. Each is accounted for above; none is an accident.


---

## The `/simplify` pass, second run — four angles over the create-mode work

`/simplify` ran again over everything after the code-review commits, because
create mode, `vehicle_actions.dart`, `minor_units.dart`, `OdometerEntry` and
the promotion fix all landed after the first pass. Four agents, nineteen
findings. Applied and answered below; none was dropped.

### Two were defects, not untidiness

- **`OdometerEntry.copyWith` dropped an accepted warning on any copy.** It read
  `warningAccepted: text == null && (…)`, so only a copy that restated the flag
  kept it — and `VehicleEditNotifier.edit` re-units the entry on every
  keystroke in every other field. Accepting "Use it anyway" and then typing one
  letter of the make brought the warning straight back. It now clears on a new
  text OR a new unit (3,000,001 mi is not the number 3,000,001 km was) and
  carries forward otherwise. Both arms tested.
- **The guard for that found a second one.** `_reunit`'s unit argument
  evaluated `_defaultUnit`, which reads `settingsProvider`, on the EDIT path
  too. The `?.` form it replaced short-circuited its own argument; a plain call
  does not. Edit mode had grown a drift subscription it never had, visible as a
  pending-timer failure in the test AFTER the one that opened it.

### Four things the repo already had, written again

`distanceUnitLabel` (this was the fourth and fifth copy; its own dartdoc says
it exists because the line "was written three times"), the epoch-fallback ISO
date (three copies, now `CivilDate.isoDateOf`), the switcher's
switch-and-dismiss (twice in one new file), and the name comparison — the
delete dialog and the duplicate-name note folded differently, so "Golf ۲۰۱۹"
was one vehicle to one of them and two to the other. `foldedName` is the one
answer now, and it folds case as well: a keyboard that auto-capitalises would
otherwise lock the owner of a van called `van` out of the delete gate for a
letter they did not type.

The odometer FIELD was the fifth: `OdometerEntry` shared the model and the
widget was copied. `CalmOdometerInput` shares it, with the one deliberate
difference — first run's empty message waits for a refused Start, create mode
has no refused press — as an argument rather than a second widget.

### `CalmListRow.switchRow` takes a bool

The assert added during the code-review pass policed a mistake the signature
could refuse. The row builds its own `CalmSwitch` with `onChanged: null`, so
there is no wrong thing left to pass: the assert, its five-line message, its
non-const constructor and the test whose only job was to watch it fire are all
gone. A test that exists to guard an API shape is the signal the shape was
wrong.

### Two claims corrected rather than kept

`_asNew`'s comment said listing 25 fields makes a newly added column a compile
error. `Vehicle`'s constructor is optional-named, so it does not — the comment
now says what the list actually buys. And `createVehicle`'s "the id is ignored"
is an assert now: a caller holding a real id was editing a vehicle, not
creating one, and a discard nobody sees is not a contract. The `.inDays` gate
says out loud that it refuses a spelling and not the class (`.inHours ~/ 24`
walks past it).

### Answered, not applied

- **A sealed `VehicleEditTarget` replacing `{mode, vehicleId}` and
  `kUnsavedVehicleId`.** The right shape, and both the altitude and
  simplification passes named it. Deferred deliberately, on the altitude
  agent's own reasoning: it touches the router, the screen, the notifier, the
  provider family's key type, `VehicleEditDraft.blank()` and about twenty test
  call sites, on a branch that is green with a parity capture already taken —
  and the failure it prevents is a confusing read, not lost data. **EPIC-10
  inherits it**: every screen after this one has the same create/edit pair, and
  the fourth copy of the pattern is the one that will hurt. The one-line slice
  was taken now (the sentinel comparison is `!state.creating`), so the sentinel
  is no longer load-bearing anywhere but the repository's assert.
- **`VehicleActionOutcome` could be a `bool`.** Only `none` is compared today.
  Kept: `confirmDeleteVehicle` returns `sold` when the user takes "Keep it —
  mark it sold" from the delete dialog, and a bool would erase which of the two
  things happened at the moment a caller most needs to know. The altitude pass
  independently defended it.
- **Renaming `RelativeDateBucket.inDays` to delete the gate's lookbehind.** The
  five members of that enum are named after the five ARB keys they select —
  `inDays`→`dateInDays`, `inAboutWeeks`→`dateInAboutWeeks`. Breaking that
  mirror for a regex is the worse trade; the carve-out is one documented line.
- **`vehiclesProvider.select` for the duplicate-name note.** Correct, and not
  worth spending: `vehicles` emits only when a vehicle row changes, which while
  an edit modal is open is essentially never. The `ref.watch` did move above the
  empty-name guard, so the screen's dependency set no longer flips as the field
  crosses empty.
- **Consolidating the three widget harnesses in `vehicle_edit_screen_test.dart`,
  and the sixth private `Vehicle` builder across the vehicle tests.** Both real.
  Left for the epic that next touches those files: a test-harness refactor on a
  green branch buys nothing a reader can see, and the cross-file builder is a
  five-file change for one helper.
- **Five `COUNT(*)`s awaited in sequence; `delete()` reading the garage twice.**
  Both pre-existing, both behind a confirm dialog, both over a handful of rows.
  The efficiency pass measured them and said not to. Recorded for EPIC-16.
