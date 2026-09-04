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

### Still to do in this epic
Tasks 9.3–9.8: `firstrun.language`, `firstrun.vehicle`, `vehicle.edit`,
`vehicles`, `vehicle.switcher`, and the launch-state wiring. Five screens, 20
reference images.
