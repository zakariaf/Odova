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

### Still to do in this epic
Tasks 9.3–9.8: `firstrun.language`, `firstrun.vehicle`, `vehicle.edit`,
`vehicles`, `vehicle.switcher`, and the launch-state wiring. Five screens, 20
reference images.
