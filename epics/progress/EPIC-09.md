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

## Task 9.5 — `vehicle.edit` 🟡 PART BUILT

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
- **The odometer read-only row**, which needs the latest reading and its age
  wired through. `dateDaysAgo` is in the ARB and ready for it.
- **Mark as sold** and its sale form; **Delete**, which wants task 9.6's
  `showConfirmDeleteDialog`.
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

### Still open in 9.6
Long-press drag reorder. The `+` and the row tap are inert until 9.8 registers
the routes they need.

