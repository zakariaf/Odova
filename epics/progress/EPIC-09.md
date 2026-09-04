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

### Still to do in this epic
Tasks 9.4–9.8: `firstrun.vehicle`, `vehicle.edit`, `vehicles`,
`vehicle.switcher`, and the launch-state wiring. Four screens, 16 reference
images.
