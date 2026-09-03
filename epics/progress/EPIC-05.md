# EPIC-05 — Persistence, schema and migrations

Eleven tasks, all done. This file is the handover: what was built, what the epic
got wrong about the repo, and the three decisions that outlived the task that
raised them.

## Task by task

- **5.1** Drift wired. Four pragmas asserted on a REOPENED database, because
  three of them do not persist in the file — the way this goes wrong is a green
  test against a fresh database and an app whose second launch has no foreign
  keys. Confinement gate seen to fail both ways (a `package:drift` import under
  `lib/features/`, a `package:sqflite` import inside `lib/data/`). Dependencies
  audited: no socket path from drift, sqlite3, sqlite3_flutter_libs or
  path_provider. The only network-shaped packages in the tree arrive through
  `flutter_riverpod -> riverpod -> test`, which predates this epic.

- **5.2** `RecordId` (nine prefixes) and the ULID.
  **Epic correction:** the epic's *Where we are now* claims a `Result`/`Failure`
  spine is already in use. There was none — `lib/core/` held `money.dart`,
  `due/` and `l10n/` and nothing else. Built here, because 5.2's `parse` and
  5.7's repositories both return one and a second vocabulary would mean
  converting between them forever.

- **5.3** Column contract. `column_types.dart` was written and then deleted: the
  constraint-template helpers had no caller, because drift's generator needs a
  literal it can read statically.

- **5.4** `Vehicles`, `ServiceItems`, `Settings`. See *Two Drift APIs* below.

- **5.5** The four event tables. Six constraints mutated, each seen to turn the
  suite red. The tests were written after the tables here, and the mutation
  sweep stands in for the red I did not watch.

- **5.6** Odometer readings, corrections, the cumulative fold, the monotonicity
  guard, four indexes. See *SPEC.md edited* below.

- **5.7** Seven repositories, the typed-failure boundary, the domain models.
  See *Three findings* below.

- **5.8** Delete, Undo, purge. Undo restores by TIMESTAMP, not by vehicle: one
  stamp across the cascade, matched on the way back, so a fill-up deleted five
  minutes earlier stays deleted.

- **5.9** The odometer fan-out, keyed on `(source_id, source)`.

- **5.10** The migration ladder at v1, when it is empty. `build.yaml` did not
  exist, so `drift_dev make-migrations` had been failing with "No databases
  found" — discoverable on the day you need to migrate, not before.

- **5.11** The migration guard, the read-only mode, the 12,000-record oracle.

## The three decisions worth carrying forward

### SPEC.md was edited: `unit_mixup` is not a correction reason

§3's `OdometerCorrection.reason` enum listed four values including
`unit_mixup`; §14 *Edge cases* says in as many words "`unit_mixup` is removed as
a correction reason". §14 is right and is the narrower, explicitly-decided
statement — storage is canonical metres and the odometer unit is a per-record
fact, so a km cluster fitted to a miles car needs no offset at all.

The `CHECK` ships three reasons and **§3 was fixed in the same commit** rather
than the CHECK widened to admit both. Widening would have offered the user a
resolution that does nothing; leaving §3 alone would have left the next reader
to rediscover the contradiction. Recorded under the PR's **Spec** heading.

### Two Drift APIs look like schema constraints and are not

`.references(Vehicles, #id, onDelete: KeyAction.cascade)` compiled, generated,
analysed clean — and emitted **no `REFERENCES` clause at all**. `service_items`
came out with a bare `TEXT NOT NULL`, so an item pointing at a vehicle that does
not exist was accepted and the cascade Undo depends on did not exist.

`.withLength(min: 3, max: 3)` is a Dart-side validator on the generated
companion and emits nothing into `CREATE TABLE`. All four currency columns were
unchecked in the database.

Both are now gated by `test/data/db/schema_reality_test.dart`, which asks SQLite
what it actually has rather than trusting the Dart: no `withLength` in any table
file, every column whose name contains `currency` carries `length(col) = 3` in
its SQL, and every `*_id` column that names another table appears in
`PRAGMA foreign_key_list`. The last is derived rather than listed, so a foreign
key added later is covered without editing the test.

### The models live in `lib/core/domain/models/`, not `lib/domain/`

The epic's text says `lib/domain/models/`.
`test/policy/structure_test.dart` sanctions seven top-level directories and
`core` is the one labelled "pure Dart domain — no Flutter, ever", which is
exactly what these are. The gate is an existing deliberate decision from EPIC-01
and it wins over the epic's prose.

## Three findings from the repository work

**Drift's stream invalidation is TABLE-level.** A write to vehicle A re-runs
every query over that table, including vehicle B's — the `WHERE` does not enter
into it. The epic asks that writing to B not wake A's subscription; with drift
the query re-runs either way. What can be controlled is whether the SUBSCRIBER
wakes, and that is what the models' value equality buys: `.distinct` on every
watch stream turns "the query ran again" into "nothing changed, do not rebuild".
The scope still earns its place — the re-run is an indexed lookup rather than a
scan — but it is not what stops the rebuild.

**Two of `guardPersist`'s three catch arms cannot be reached through a
repository.** The app opens with `NativeDatabase.createInBackground`, so on a
device every exception crosses an isolate boundary and arrives wrapped; a test
using a direct `NativeDatabase` never produces that shape. Without the third arm
a user's constraint failure arrives on a real phone as an unclassified write
error and reads as "something went wrong". `guard_test.dart` drives all three
directly.

**Four of the migration opener's defences cannot be proven on this platform.**
Closing the connection checkpoints the WAL into the main file, so by the time
the restore runs it is overwriting a file that is already complete — which masks
the close-before-restore ordering, the delete-before-copy pass, the checkpoint
and the sidecar copies all at once. Every one of those mutations stays green.
They stay in the code because each covers a case the test cannot produce: a
checkpoint that fails because a reader holds the WAL, a process killed between
the commit and the close, a platform where deleting an open file is not benign.
The test says so in place of claiming otherwise, and asserts the END STATE
instead: after a rolled-back migration the file is the old one and no sidecar
beside it holds the new one.

This one is worth reading twice, because the first version of that test was
worthless and did not look it. It asserted the file was byte-identical after a
throwing migration and passed with the restore deleted — because drift wraps
`onUpgrade` in a transaction, so a step that throws before committing is rolled
back by SQLite. The snapshot exists for the OTHER case, which is the shape of
`AppDatabase.onUpgrade` itself: run `stepByStep` in a transaction, then throw if
`PRAGMA foreign_key_check` finds orphans — after the commit.

## Tests that were written, passed, and proved nothing

Recorded because each is the shape the TDD rule exists to catch.

1. **The durability test used an in-memory database**, where "written" and
   "committed" cannot be told apart because both connections are the same one.
   It opens a real file now and reads through a second connection.
2. **The closed-database test closed an in-memory database** — which destroys it
   and makes drift open a fresh empty one, so the write succeeded. It points at
   a path that is a DIRECTORY now, which also proves the classification.
3. **The `ValueEquality` type test compared classes with different-length props
   lists**, so `_listEquals` returned false on the length alone and the
   `runtimeType` check could be deleted unnoticed.
4. **The odometer edit test only edited the LAST reading**, where the stale copy
   has nothing after it and the bug cannot show. It edits a middle reading now.
5. **The vehicle-cascade stamp test walked seven child tables and populated
   four.** `DISTINCT deleted_at_utc_ms` over an empty table is an empty set, so
   three tables were "checked" while holding nothing.
6. **`no_drift_in_signatures_test.dart` had two bugs of its own**, both found by
   its own guard tests: a line scanner read a wrapped private helper as public
   API, and `\b` before `$` never matches, so `$VehiclesTable` was unmatched.

## The ritual when `schemaVersion` changes

In order. `lib/data/db/schema_version.dart` carries the same list.

```bash
dart run drift_dev make-migrations
dart run drift_dev schema steps drift_schemas/odova/ lib/data/schema_versions.dart
dart run drift_dev schema generate --data-classes --companions \
    drift_schemas/odova/ test/drift/generated/
dart run build_runner build --delete-conflicting-outputs
```

The two flags on the third command are load-bearing: without them only shape
tests are possible, and a shape test reads zero rows — so it cannot tell a step
that copied everything from one that copied nothing.

## For EPIC-06: the canonical-integer fields to replace

The epic asks for these by name, so the value-object swap knows what it is
replacing. Every one is an `int` with the unit in the field name, and that name
is currently the ONLY thing preventing a metre being added to a mile.

**Distance — metres.** `Vehicle.purchaseOdometerM`, `Vehicle.expectedAnnualM`,
`Vehicle.noticeDistanceM`, `ServiceItem.intervalDistanceM`,
`ServiceItem.targetOdometerM`, `ServiceItem.baselineOdometerM`,
`ServiceItem.noticeDistanceM`, `ServiceItem.snoozeUntilOdometerM`,
`ServiceRecord.odometerM`, `FillUp.odometerM`, `Expense.odometerM`,
`Trip.startOdometerM`, `Trip.endOdometerM`, `Trip.manualDistanceM`,
`OdometerReading.odometerM`, `OdometerCorrection.previousM`,
`OdometerCorrection.newM`, `AppSettings.noticeDistanceM`, and
`OdometerCorrection.offsetM` (derived).

**Volume — millilitres.** `Vehicle.tankCapacityMl`, `FillUp.quantityMl`.

**Mass — grams.** `FillUp.quantityG`.

**Energy — watt-hours.** `FillUp.energyWh`.

**Money — minor units, always beside an ISO 4217 code.**
`Vehicle.purchasePriceMinor` + `purchasePriceCurrency`,
`Vehicle.soldPriceMinor` + `soldPriceCurrency`,
`ServiceLine.amountMinor` + `currency`,
`FillUp.totalCostMinor` + `currency`,
`Expense.amountMinor` + `currency`, and `ServiceRecord.totalMinor` (derived,
summed from the lines, and there is no column for it).

**Not a unit, do not wrap.** `createdAtUtcMs` / `updatedAtUtcMs` /
`deletedAtUtcMs` / `lastBackupAtUtcMs` / `lastBackupReminderAtUtcMs` are
INSTANTS in UTC epoch milliseconds. `notificationTimeMinutes`,
`quietHoursFromMinutes` and `quietHoursToMinutes` are LOCAL times of day in
minutes after midnight and are deliberately not instants — 09:00 stays 09:00
across a zone change, and storing them as instants would move them.
`ServiceItem.intervalMonths`, `noticeDays`, `snoozeCount`, `sortOrder`,
`firstDayOfWeek`, `schemaVersion` and `Vehicle.year` are counts, not
measurements.

`Expense.amountMinor` is the one money field that may be NEGATIVE — a refund, a
warranty reimbursement, an insurance payout — and it is the only money column in
the schema without a `>= 0` check. Whatever `Money` becomes has to represent
that, and there is a test whose whole job is to say so.

## Deferred

- **`test/migration/freshness_test.dart`'s every-pair loop runs zero pairs.**
  Written now so a future bump cannot forget the skip paths; its failure message
  names the fixtures directory and says what to assert.
- **No repository passes `refuseWith` yet.** `writable_store.dart` and
  `guardPersist`'s parameter are the seam; wiring it needs a composition root
  that knows the open outcome, which arrives with the app shell in EPIC-08.
  Recorded under the PR's **Deferred** heading.
- **`AppDatabase.forTesting` is used by the opener's default.** The app's real
  entry point still constructs `AppDatabase()` directly through
  `appDatabaseProvider`; routing bootstrap through `openMigratedDatabase` is
  EPIC-08's job, and until then the migration guard is tested but not wired.
- **Value objects.** `Money`, `Distance`, `Volume` and `Energy` arrive in
  EPIC-06 and swap the canonical integers at the repository boundary in one
  pass. Until then the unit is in the field NAME and that is the only thing
  stopping a metre being added to a mile.
