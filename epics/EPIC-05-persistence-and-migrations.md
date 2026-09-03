# EPIC-05 — Persistence, schema and migrations

| | |
|---|---|
| **Epic** | EPIC-05 — Persistence, schema and migrations |
| **Depends on** | EPIC-01 |
| **Estimate** | **19 h (CC) · ~4–5 months (human)** across 11 tasks |
| **Spec sections** | §3 Domain model and rules (Canonical units; Identity, timestamps, deletion; Entities; Enums; The odometer: continuity and corrections; Invariants and validation; Durability), §6.3 Versioning and migration (§6.3.3 Surviving app updates), §6.4.4 The automatic safety copy, §14 Edge cases (Odometer and data integrity; Storage and scale), §17 Definition of done (Data-safety gate) |
| **Screens** | none |

This epic builds the floor the whole app stands on. Losing eight years of service
history outranks every feature in this product (SPEC §2, `CLAUDE.md` rule 3), and
every way that can happen — a wrong column type, a mutation that publishes before it
persists, a delete that takes rows nobody asked for, a migration that copies zero
rows and reports success — is decided here. That is why the migration tasks at the
end are the heaviest in the repo and why their estimate is not padding.

## Where we are now

EPIC-01 has created the Flutter app. Before it, the repo held only the specification,
the design systems, the reference screenshots, the tooling and the skills — no
`pubspec.yaml`, no `lib/`.

What you inherit at the start of this epic:

- `pubspec.yaml`, `pubspec.lock`, and a `lib/` tree laid out feature-first with the
  layer split from `flutter-architecture` — `lib/core/`, `lib/data/`, `lib/features/`.
- The composition root: `lib/main.dart` and a `ProviderScope` with the `Clock` seam
  overridden once, per `app-startup-and-bootstrap` and rule 8 of
  `flutter-conventions-index`. Domain code reads `clock.now()`; nothing calls
  `DateTime.now()`.
- The `Result`/`Failure` spine from `error-handling-typed-results` in a Flutter-free
  layer, with at least one sealed `Failure` family already in use.
- `analysis_options.yaml` armed — `very_good_analysis` is a real dev_dependency, so
  the pinned `include:` resolves — plus `build_runner` wired and `flutter analyze
  --fatal-infos --fatal-warnings` green on the skeleton.
- CI's Flutter lane live, because `pubspec.yaml` now exists, and
  `tools/check_gates_selftest.sh` running the repo gates with its
  every-gate-seen-to-fail discipline.

What is deliberately still missing, and stays missing after this epic:

- **No database of any kind yet.** No `lib/data/db/`, no Drift dependency, no tables.
  This epic writes all of it.
- **No value objects.** `Money`, `Distance`, `Volume`, `Energy` and the unit
  conversions arrive in EPIC-06. Until then the domain models this epic maps rows
  into carry **canonical integers with the unit in the name** — `odometerM`,
  `quantityMl`, `energyWh`, `totalCostMinor` + `currencyCode`. That is deliberate,
  not an oversight: EPIC-06 Tasks 6.2 and 6.3 swap those fields for value objects at
  the repository boundary in one pass, and the repository is the only place that ever
  has to change.
- **No due engine, no fuel engine, no screens.** Nothing in this epic renders
  anything. There is no widget test in it and no parity check in its definition of
  done, because it builds no screen.
- **No export, no import, no backup file.** `data-export-and-restore` and SPEC §6.1,
  §6.2, §6.4 and §6.5 belong to the backup epic. This epic touches §6 only where §6.3.3
  and §6.4.4 bind an *on-device schema migration*: the safety copy written by the old
  schema's writer before new code touches anything.

## What we will have when this is done

- A SQLite database on the device holding all ten entities from SPEC §3, where a
  corrupt row cannot be written: every table is `STRICT`, every enum is a `CHECK`, and
  the nine id prefixes are enforced in the schema, not in a comment.
- `flutter test test/data/` green, including a test that opens a real in-memory
  database, writes a vehicle with a fill-up, a service record with three lines, an
  expense, a trip, an odometer reading and a correction, closes it, reopens it, and
  reads everything back byte-identical.
- One write path: every mutation in the app goes through a repository method that
  persists inside a single transaction and then lets the watched stream re-emit.
  `bash tools/check_drift_confinement.sh` proves no `package:drift` symbol exists
  outside `lib/data/`, and `tools/check_gates_selftest.sh` proves that gate can fail.
- Delete behaves the way SPEC §3 says it does: a delete is invisible everywhere
  immediately, Undo brings it back for the length of the snackbar, and after that the
  row is purged — so a fresh database has `deleted_at IS NULL` on every row that
  exists.
- `drift_schemas/odova.v1.json` and `lib/data/schema_versions.dart` committed, a
  migration test file that loops every `from → to` pair, and a CI gate that goes red
  if `schemaVersion` changes without a new committed snapshot.
- A migration that fails leaves the user's data intact: the byte snapshot restores,
  the JSON safety copy `odova-safety-migration-<version>.json` written by the **old**
  schema's writer sits in app-private storage, and the app comes up read-only with the
  banner from SPEC §6.3.3 instead of a crash loop. There is a test that forces the
  throw and proves all three.

## Skills to load

Open `flutter-conventions-index` first — it is the front door and it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules every task inherits: the downward-only layer DAG, the single write path, derive-don't-store, typed errors, injected side effects. |
| `persistence-drift` | Owns every table, DAO, index, `CHECK`, pragma and repository transaction in this epic, plus the WAL-safe backup primitive the migration guard uses. |
| `run-migration` | Owns the ladder: the pre-open snapshot, the append-only `stepByStep` step, the committed schema artefacts, and the test suite that proves a migration did not silently copy zero rows. |
| `run-codegen` | Drift is codegen; every table change is followed by a deterministic `build_runner` pass before analyze. |
| `error-handling-typed-results` | Every repository method returns `Result<T, PersistFailure>`; the never-lose-data rules (one transaction per mutation, soft-delete + Undo) are its territory. |
| `value-objects-money-and-units` | Defines what "canonical storage" means for the columns here — integer minor units keyed to the real ISO-4217 exponent, SI integers, no float money — before EPIC-06 wraps them. |
| `state-management-riverpod` | The repository providers and scoped `.watch()` stream providers this epic exposes upward, and the persist-then-republish rule. |
| `testing-strategy` | The data layer is tested against `NativeDatabase.memory()`, never a mocked DAO; fakes are bare-`implements`, not mocks. |
| `dependency-hygiene` | `drift`, `sqlite3_flutter_libs` and `path_provider` are new dependencies in an app whose store listing claims zero network calls — the transitive tree is audited before they land. |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, and `SPEC.md` wins over any skill — are stated once in
`epics/README.md` and are not repeated per task.

## Tasks

### Task 5.1 — Wire Drift into the app and lock it inside `lib/data/`

- **Goal** The app opens a real SQLite database with the right pragmas on every open,
  and no code outside `lib/data/` can import Drift.
- **Spec** §3 Durability; §14 Storage and scale.
- **Skills** `persistence-drift`, `dependency-hygiene`, `run-codegen`,
  `state-management-riverpod`.
- **Write these tests first**
  - `test/data/db/connection_test.dart`
    - `sets journal_mode = wal on a freshly created database` — asserts
      `PRAGMA journal_mode` returns `wal`; fails if the pragma is only set once at
      creation rather than idempotently in `setup`.
    - `sets foreign_keys = ON on every open` — opens, closes, reopens the same file
      and asserts `PRAGMA foreign_keys` is `1` on the second open. Fails if anyone
      assumes the pragma persists in the file; it does not.
    - `sets synchronous = FULL` — asserts `2`. This store holds non-regenerable
      hand-entered data; WAL + NORMAL may roll back after power loss.
    - `sets a busy_timeout` — asserts non-zero.
  - `tools/check_gates_selftest.sh` gains a case: planting
    `import 'package:drift/drift.dart';` in a scratch file under `lib/features/`
    makes `tools/check_drift_confinement.sh` exit non-zero, and removing it makes it
    exit zero. Per `CLAUDE.md`, a gate that has not been seen to fail is a comment
    that runs.
- **Then build**
  - `pubspec.yaml`: `drift`, `sqlite3_flutter_libs`, `path_provider`; dev:
    `drift_dev`, `build_runner`. Commit `pubspec.lock` in the same change — CI runs
    `pub get --enforce-lockfile`. Audit each for a transitive network path before
    adding it.
  - `lib/data/db/connection.dart` — `openConnection()` returning a `LazyDatabase`
    over `NativeDatabase.createInBackground`, with `journal_mode = WAL`,
    `synchronous = FULL`, `foreign_keys = ON`, `busy_timeout = 5000` in `setup`. The
    file lives in the application **support** directory, not Documents.
  - `lib/data/db/app_database.dart` — `@DriftDatabase(tables: [])` for now,
    `schemaVersion => 1`, `MigrationStrategy` with `onCreate: m.createAll()` and a
    `beforeOpen` that re-asserts `foreign_keys = ON`.
    `eraseDatabaseOnSchemaChange` is not referenced anywhere.
  - `lib/data/db/database_provider.dart` — `appDatabaseProvider` with
    `ref.onDispose(db.close)`.
  - `tools/check_drift_confinement.sh` — a thin wrapper over
    `.claude/skills/persistence-drift/scripts/check-drift-confinement.sh` so CI and
    the self-test call one path.
- **Verify**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter analyze --fatal-infos --fatal-warnings
  flutter test test/data/db/connection_test.dart
  bash tools/check_drift_confinement.sh
  bash tools/check_gates_selftest.sh
  ```
  A pass is: four pragma tests green, the confinement gate green on the real tree and
  red on the planted violation.
- **Done when**
  - [ ] The four pragmas are asserted on a *reopened* database, not just a new one.
  - [ ] `package:drift` and `package:sqlite3` appear only under `lib/data/`.
  - [ ] The confinement gate has been seen to fail and its self-test is committed.
  - [ ] `pubspec.lock` is committed and no new dependency opens a socket.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 5.2 — `RecordId`: the nine prefixes and the ULID

- **Goal** Every row gets an id that is the same string in the database, in the export
  file and in a notification payload, and a wrong-prefix id is a compile error rather
  than a runtime surprise.
- **Spec** §3 Identity, timestamps, deletion.
- **Skills** `value-objects-money-and-units` (the pure-core boundary and the injected
  `Clock`), `dart3-idioms-and-coding-standards`, `testing-strategy`,
  `seeded-determinism-and-golden-vectors` (the entropy rule).
- **Write these tests first** — `test/core/ids/record_id_test.dart`
  - `mints one id per entity with the right prefix` — nine cases,
    `veh_ rem_ srv_ lin_ fil_ exp_ trp_ odo_ cor_`, one per type. Fails if
    `ServiceItemId` mints `svc_`; the reminder table's prefix is `rem_`, and the
    service *record*'s is `srv_`.
  - `body is 26 Crockford base-32 characters` — asserts length 26 and rejects
    `I`, `L`, `O`, `U`.
  - `parse rejects a 25- and a 27-character body` — two cases.
  - `parse rejects an id whose prefix belongs to another entity` —
    `VehicleId.parse('fil_…')` returns a typed failure, not a `VehicleId`.
  - `ids minted in the same millisecond sort in mint order` — mint 1,000 with a fixed
    `Clock` and assert the list is already sorted. This is the free deterministic
    tiebreak history pagination depends on.
  - `ids are time-sortable across milliseconds` — two ids one second apart compare in
    order as plain strings.
  - `the same clock and the same seed reproduce the same id` — the randomness comes
    from one injected seeded generator, never an ambient `Random()`.
  - `toString round-trips through parse` for all nine types.
- **Then build**
  - `lib/core/ids/record_id.dart` — a sealed `RecordId` with `VehicleId`,
    `ServiceItemId`, `ServiceRecordId`, `ServiceLineId`, `FillUpId`, `ExpenseId`,
    `TripId`, `OdometerReadingId`, `OdometerCorrectionId`; each knows its prefix,
    each has `parse` returning `Result<T, IdFailure>` and a `tryParse`.
  - `lib/core/ids/ulid.dart` — `UlidFactory(Clock clock, Random random)` producing the
    48-bit timestamp + 80-bit randomness Crockford encoding, with the
    monotonic-within-a-millisecond increment.
  - `lib/core/ids/id_provider.dart` — the factory behind a provider, overridden once
    at the composition root.
- **Verify**
  ```bash
  flutter test test/core/ids/
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] All nine prefixes are covered by a test naming the entity.
  - [ ] No ambient `Random()` or `DateTime.now()` on the minting path.
  - [ ] `parse` returns a typed failure; nothing throws for bad input.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 5.3 — The column contract: audit columns, canonical integers, dates, money

- **Goal** Fix, once, how every table stores an id, a timestamp, an event date, a
  quantity and an amount — so the nine table tasks that follow have nothing left to
  decide.
- **Spec** §3 Canonical units; §3 Identity, timestamps, deletion; §3 Currency; §3
  Invariants and validation (`updated_at ≥ created_at`).
- **Skills** `persistence-drift`, `value-objects-money-and-units`,
  `naming-conventions`.
- **Write these tests first** — `test/data/db/column_contract_test.dart`
  - `no column in any table has type REAL` — reads `PRAGMA table_info` for every table
    in `AppDatabase.allTables` and asserts no `REAL`. This is the float-money guard and
    it must keep working for tables written after this task.
  - `every table is STRICT` — asserts `sql` in `sqlite_schema` ends in `STRICT` for
    each table. Fails if someone forgets `isStrict => true` on a new table.
  - `every table has id, created_at, updated_at, deleted_at` — except
    `service_lines`, which is a child row with an `id` only, and `settings`, whose id
    is the literal `settings`.
  - `an event date must be YYYY-MM-DD` — inserting `occurred_on = '2026-9-3'` or
    `'03/09/2026'` is rejected by the `CHECK`; `'2026-09-03'` is accepted.
  - `an event date column never stores a time or a zone` — inserting
    `'2026-09-03T00:00:00Z'` is rejected.
  - `updated_at earlier than created_at is repaired on read` — writes a row with a
    skewed pair through raw SQL and asserts the mapper returns
    `updatedAt == createdAt`. SPEC §3 says repair on read, not block on write.
  - `a currency code is exactly three characters` — `'EU'` and `'EURO'` rejected.
  - `money is stored as minor units and a code, never a decimal string` — a fixture
    with `amount_minor = 4599, currency = 'EUR'` round-trips as `4599`.
- **Then build**
  - `lib/data/db/tables/audit_columns.dart` — `mixin AuditColumns on Table`: `id`
    (`text()`, primary key), `createdAtUtcMs`, `updatedAtUtcMs` (`integer()`, UTC
    epoch millis), `deletedAtUtcMs` (`integer().nullable()`).
  - `lib/data/db/tables/column_types.dart` — the shared helpers: `civilDate()` (a
    `TextColumn` with `CHECK (col GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')`),
    `moneyMinor()` + `currencyCode()` (`text().withLength(min: 3, max: 3)`), and the
    canonical integer helpers `metres()`, `millilitres()`, `grams()`, `wattHours()`.
  - `lib/data/db/mappers/audit_mapper.dart` — the one place `updated_at` is clamped
    to `>= created_at` on read, and the one write wrapper that stamps `updated_at`.
  - **Decision to record in the PR:** SPEC §3 stores an event date as a zoneless
    `YYYY-MM-DD` string and `persistence-drift` rule 5 asks for a serial-day integer.
    Both exist to keep an instant out of a day boundary; the spec wins, because the
    same string is the export's date format and its lexical order is its chronological
    order. No `DateTime` is stored for an event date either way.
- **Verify**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/data/db/column_contract_test.dart
  ```
  The no-`REAL` and every-table-`STRICT` tests are schema-wide reflections: they must
  stay green as Tasks 5.4–5.6 add tables, without being edited.
- **Done when**
  - [ ] The schema-wide reflection tests pass and need no edit when a table is added.
  - [ ] Event dates are `YYYY-MM-DD` `CHECK`ed text; bookkeeping times are UTC millis.
  - [ ] Money is `(int minor, char(3) code)` everywhere; no `REAL` column exists.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 5.4 — `Vehicles`, `ServiceItems` and the `Settings` singleton

- **Goal** The three tables the whole app is scoped by exist, with their enums and
  null-means-inherit overrides enforced in the schema.
- **Spec** §3 Entities (`Vehicle`, `ServiceItem`, `Settings`); §3 Enums; §3 Scope:
  global vs per vehicle; §3 Notice window.
- **Skills** `persistence-drift`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/data/db/tables/vehicles_test.dart`,
  `service_items_test.dart`, `settings_test.dart`
  - `rejects a vehicle_type outside the five` — `'boat'` fails the
    `CHECK (vehicle_type IN ('car','van','motorcycle','truck','other'))`.
  - `rejects a status outside active|archived|sold`.
  - `accepts null on every per-vehicle override` — `currency`, `distance_unit`,
    `volume_unit`, `consumption_unit`, `notice_distance_m`, `notice_days` all null on
    a minimal vehicle; null means inherit and must not be defaulted at the storage
    layer.
  - `rejects a tank_capacity_ml of zero or less`.
  - `a service item with no interval and no target is rejected` — asserts the
    `CHECK (interval_distance_m IS NOT NULL OR interval_months IS NOT NULL OR
    target_odometer_m IS NOT NULL OR target_date IS NOT NULL)` from SPEC §3
    Invariants.
  - `rejects interval_distance_m = 0 and interval_months = 0`.
  - `a custom item without a label is rejected` —
    `CHECK (kind <> 'custom' OR label IS NOT NULL)`.
  - `rejects a priority or rollover outside its enum` — `safety|normal|low`,
    `from_actual|from_due`.
  - `there is exactly one settings row` — a second insert fails the
    `CHECK (id = 'settings')`.
  - `settings enums are checked` — `language`, `calendar`, `numerals`, `theme`,
    `currency_display`, `distance_unit`, `volume_unit`, `consumption_unit`, each with
    one accepted and one rejected value; `consumption_unit` covers all six including
    `kwh_100km` and `mi_kwh`.
  - `a service item belongs to a live vehicle` — inserting with an unknown
    `vehicle_id` fails the foreign key. Requires `foreign_keys = ON` from Task 5.1.
- **Then build**
  - `lib/data/db/tables/vehicles.dart` — every field in SPEC §3 `Vehicle`, including
    `is_business`, `expected_annual_m`, `sold_on`/`sold_price`, `sort_order`,
    `notifications_muted`, `colour` and the six nullable overrides. No `photo_id`.
  - `lib/data/db/tables/service_items.dart` — the reminder definition. **No `mode`
    column and no `rule` column**: which axes apply is derived from which interval
    fields are non-null. `notice_distance_m` / `notice_days` are the per-item lead
    overrides; there are no `lead_*` columns and no `notice_months`.
    `kind` is `CHECK`ed against the 28-value `ServiceKind` list in SPEC §3 Enums.
  - `lib/data/db/tables/settings.dart` — one row, `CHECK (id = 'settings')`,
    carrying `schema_version` as SPEC §3 specifies. Drift's own `user_version` stays
    authoritative for the migration ladder; `settings.schema_version` mirrors it on
    write and is what the export reads. Say so in a `///` comment so nobody later
    treats the two as independent.
  - Register all three in `@DriftDatabase(tables: [...])`.
- **Verify**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/data/db/tables/
  ```
  Each rejection test must fail with a SQLite constraint error, not a Dart assertion —
  the invariant is in the schema, not at the call site.
- **Done when**
  - [ ] Every enum in these three tables is a `CHECK`, listing the exact spec
        spellings.
  - [ ] Null-means-inherit is preserved: no override column has a default.
  - [ ] `service_items` has no `mode`, no `rule`, no `lead_*`, no `notice_months`.
  - [ ] A second settings row is impossible.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 5.5 — The event tables: services and lines, fill-ups, expenses, trips

- **Goal** The four things a driver actually logs are storable, and the invariants
  from SPEC §3 that a `CHECK` can express are in the schema.
- **Spec** §3 Entities (`ServiceRecord`, `ServiceLine`, `FillUp`, `Expense`, `Trip`);
  §3 Enums; §3 Invariants and validation.
- **Skills** `persistence-drift`, `value-objects-money-and-units`, `testing-strategy`.
- **Write these tests first** — `test/data/db/tables/service_records_test.dart`,
  `fill_ups_test.dart`, `expenses_test.dart`, `trips_test.dart`
  - `a service record with zero lines cannot be read back as valid` — the
    `>= 1 line` rule is a repository invariant, not a `CHECK` (SQLite cannot express
    it); this test asserts the repository refuses the insert with
    `PersistFailure.constraint(code: 'service_record_needs_a_line')` and that the
    transaction left no partial row.
  - `a service line amount below zero is rejected` — `CHECK (amount_minor >= 0)`. A
    warranty job is 0, never negative.
  - `deleting a service item rewrites its lines to service_item_id = null` — belongs
    to Task 5.8, but the FK is declared here as
    `ON DELETE SET NULL`; this test asserts the constraint exists.
  - `a fill-up must carry exactly one quantity` — four cases: only `quantity_ml`
    passes, only `quantity_g` passes, only `energy_wh` passes, two-of-three and
    none-of-three both fail
    `CHECK ((quantity_ml IS NOT NULL) + (quantity_g IS NOT NULL) + (energy_wh IS NOT NULL) = 1)`.
  - `the quantity matches the fuel kind` — `fuel_kind = 'electric'` with
    `quantity_ml` fails; `'electric'` with `energy_wh` passes; `'cng'` with
    `quantity_g` passes.
  - `a fill-up total_cost below zero is rejected; zero is accepted` — a free fill is 0.
  - `a fill-up quantity of zero is rejected` — `> 0`, per SPEC §3 Invariants.
  - `an expense amount may be negative` — a refund row inserts cleanly. This is the
    one money column with no `>= 0` check and the test exists so nobody "fixes" it.
  - `an expense of category other without a label is rejected`.
  - `covers_to before covers_from is rejected`.
  - `a trip ending before it started is rejected`, and
    `a trip whose end odometer is below its start is rejected`.
  - `a fill-up carries both trip_id and vehicle_id` — the denormalised `vehicle_id`
    is `NOT NULL` even when `trip_id` is set.
  - `every category and fuel kind spelling from SPEC §3 Enums is accepted` — a
    table-driven test over the ten `ExpenseCategory` and seven `FuelKind` values, so a
    typo in a `CHECK` list fails here rather than in the export two epics later.
- **Then build**
  - `lib/data/db/tables/service_records.dart` and `service_lines.dart` — no total
    column on the record; cost is always the sum of lines. `odometer_estimated` and
    `cost_estimated` default false. `service_lines.service_record_id` is
    `ON DELETE CASCADE`; `service_lines.service_item_id` is
    `ON DELETE SET NULL`.
  - `lib/data/db/tables/fill_ups.dart` — no unit-price column: the form computes the
    third of {total, quantity, price per unit} and only total and quantity persist.
    `is_full_tank` defaults true, `chain_broken` defaults false.
  - `lib/data/db/tables/expenses.dart`, `trips.dart`.
  - Every table carries `vehicle_id` directly, including rows that could infer it from
    a parent, so orphan detection on import is one pass.
- **Verify**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/data/db/tables/
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Exactly-one-quantity and quantity-matches-fuel-kind are both `CHECK`s.
  - [ ] `ServiceRecord` has no total column anywhere.
  - [ ] `Expense.amount` is the only money column without a `>= 0` check, and a test
        says why.
  - [ ] Every enum spelling is table-driven-tested against SPEC §3 Enums.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 5.6 — Odometer readings, corrections, the cumulative scale and the indexes

- **Goal** One table computes distance history for the whole app, corrections carry an
  offset forward, and the queries the app will actually run use an index.
- **Spec** §3 The odometer: continuity and corrections; §3 Invariants and validation;
  §14 Odometer and data integrity; §14 Storage and scale.
- **Skills** `persistence-drift`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/data/odometer/cumulative_test.dart`,
  `test/data/db/indexes_test.dart`
  - `cumulative equals the raw reading when there are no corrections`.
  - `a cluster replaced at 187,412 km reading zero adds a +187,412 km offset to every
    later reading` — the worked case from SPEC §3.
  - `a 999,999 rollover adds +1,000,000 km`.
  - `a correction applies to readings at or after its from_reading, never before` —
    the boundary reading itself is on the new scale.
  - `readings sort by (occurred_on, created_at)` — two readings on the same date order
    by creation, which is what makes the offset boundary deterministic.
  - `deleting a correction removes its offset and re-exposes the violation it covered`
    — asserts the repository returns the recomputed readings and reports the
    now-visible monotonicity break rather than silently keeping the old numbers.
  - `a reading below its predecessor in cumulative terms is refused` — the repository
    returns `PersistFailure.odometerWouldGoBackwards` carrying the previous reading and
    its date, so the UI can offer the three resolutions from SPEC §3. Nothing is
    written.
  - `a reading earlier than the earliest existing reading is accepted when its
    cumulative value is lower` — the used-car backfill case; it becomes the new
    earliest reading and no correction is required.
  - `a reading earlier than the earliest but higher is refused` with the same typed
    failure.
  - `an implied rate above 2,000 km/day warns and still writes` — a warning is
    returned alongside `Ok`, never a block.
  - `a single jump above 100,000 km warns and still writes`.
  - `a reading 1.5x to 1.7x its predecessor on a miles vehicle warns` — the probable
    km/mi mix-up, evaluated after the per-entry unit conversion.
  - `reason = 'unit_mixup' is rejected by the correction table` — see the decision
    below.
  - `the vehicle history query uses an index` — runs `EXPLAIN QUERY PLAN` on the
    keyset page query and asserts the plan contains
    `USING INDEX idx_readings_vehicle_order`, not `SCAN`.
  - `history pages by keyset, not OFFSET` — a 5,000-row fixture, page 50 fetched with
    `WHERE (occurred_on, id) < (:cursor_date, :cursor_id)`; the test asserts the query
    text contains no `OFFSET`.
- **Then build**
  - `lib/data/db/tables/odometer_readings.dart` — `source` `CHECK`ed against
    `manual|fillup|service|expense|trip_start|trip_end|import`, `source_id` nullable,
    `notes` present (import and derived readings carry it).
  - `lib/data/db/tables/odometer_corrections.dart` —
    `CHECK (reason IN ('cluster_replaced','rollover','typo_fix'))`.
    **Decision to record in the PR and in SPEC §18:** SPEC §3 lists `unit_mixup` in the
    `OdometerCorrection.reason` enum, and SPEC §14 says *"`unit_mixup` is removed as a
    correction reason"* — because storage is canonical metres and the unit is a
    per-record fact, so a km cluster on a miles car needs no correction at all. §14 is
    the narrower, explicitly-decided statement, so the schema ships three reasons and
    the epic raises the §3 enum as a spec fix. Do not widen the `CHECK` to dodge the
    contradiction.
  - `lib/data/repositories/odometer_repository.dart` — `cumulativeM(reading)` as a
    pure fold over the corrections that sort at or before it, the monotonicity guard,
    and the three soft warnings as a `List<OdometerWarning>` returned beside `Ok`.
  - Indexes: `idx_readings_vehicle_order` on
    `(vehicle_id, occurred_on, created_at_utc_ms)` partial `WHERE deleted_at IS NULL`;
    `idx_fillups_vehicle_date` on `(vehicle_id, occurred_on DESC, id DESC)`, same
    partial clause; `idx_lines_record` on `service_record_id`; `idx_lines_item` on
    `service_item_id`.
- **Verify**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/data/odometer/ test/data/db/indexes_test.dart
  ```
  A pass includes the `EXPLAIN QUERY PLAN` assertion — an index nobody proved is used
  is an index that is not used.
- **Done when**
  - [ ] `cumulativeM` is a pure function over readings + corrections, stored nowhere.
  - [ ] Monotonicity returns a typed failure carrying the offending predecessor; the
        three soft warnings warn and write.
  - [ ] `unit_mixup` is rejected and the §3-vs-§14 contradiction is written into the
        PR and SPEC §18.
  - [ ] Every hot query has an index proven by `EXPLAIN QUERY PLAN`; no `OFFSET`.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 5.7 — Repositories: the single write path and the scoped watch streams

- **Goal** Everything above the data layer talks to seven repositories that persist
  first and republish second, and never sees a Drift symbol.
- **Spec** §3 Entities; §3 Derived values (nothing derived is written); §14 Storage
  and scale (four vehicles, one household).
- **Skills** `persistence-drift`, `state-management-riverpod`,
  `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/data/repositories/*_repository_test.dart`
  - `a save resolves only after the durable commit` — the returned `Future` completes
    after the row is readable from a second connection over the same file.
  - `the watched stream re-emits after a write, with no manual republish` — subscribes
    to `watchFillUps(vehicleId)`, writes one, expects exactly two emissions and no
    optimistic third.
  - `a failed write emits nothing` — a constraint violation returns
    `Err(PersistFailure.constraint(...))` and the watched stream does not emit.
  - `a multi-row write is one transaction` — saving a `ServiceRecord` with three lines
    where the third violates a `CHECK` leaves zero rows behind, record included.
  - `a stream is scoped to one vehicle` — writing to vehicle B does not wake vehicle
    A's subscription. An unscoped stream recomputes on every write in the app.
  - `no repository method returns a Drift row type` — a reflection/grep test over
    `lib/data/repositories/` asserting no `Companion`, `TableInfo` or generated row
    class appears in a public signature.
  - `every repository method returns Result and none of them throws` — a table-driven
    test invoking each method against a closed database and asserting an `Err`, never
    an exception.
  - `PersistFailure is switched exhaustively` — a compile-level guarantee; the test is
    a `switch` with no `default:` over every variant.
- **Then build**
  - `lib/data/daos/` — one `@DriftAccessor` per table, single-table queries only.
  - `lib/data/repositories/` — `VehicleRepository`, `ServiceRepository` (items,
    records and lines together, because a record and its lines are one transaction),
    `FillUpRepository`, `ExpenseRepository`, `TripRepository`, `OdometerRepository`,
    `SettingsRepository`. Each maps rows to the immutable domain models in
    `lib/domain/models/` — canonical integers with unit-bearing names until EPIC-06
    swaps them for value objects.
  - `lib/data/failures/persist_failure.dart` — sealed:
    `write`, `constraint`, `notFound`, `odometerWouldGoBackwards`,
    `derivedReadingNotEditable`, `orphanReference`. Each carries a stable `code` and
    typed params, never a localised string.
  - `lib/data/repositories/providers.dart` — one `Provider` per repository, plus
    `StreamProvider.autoDispose.family` for each scoped watch.
- **Verify**
  ```bash
  flutter test test/data/repositories/
  flutter analyze --fatal-infos --fatal-warnings
  bash tools/check_drift_confinement.sh
  ```
- **Done when**
  - [ ] Every mutation is exactly one `db.transaction` with every query awaited.
  - [ ] No optimistic update and no manual `state =` republish anywhere.
  - [ ] Watch streams are vehicle-scoped and `autoDispose`.
  - [ ] No Drift type appears in any repository signature.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 5.8 — Delete, Undo, purge, the vehicle cascade and the item detach

- **Goal** Delete behaves as SPEC §3 describes: gone immediately to the user, soft in
  storage only for the length of the snackbar, then actually gone.
- **Spec** §3 Identity, timestamps, deletion; §14 Storage and scale.
- **Skills** `error-handling-typed-results` (never-lose-data), `persistence-drift`,
  `testing-strategy`.
- **Write these tests first** — `test/data/repositories/deletion_test.dart`
  - `a deleted row is excluded from every query` — a table-driven test over every
    repository read method, asserting a soft-deleted row appears in none of them.
  - `undo clears deleted_at and the row reappears` — one write path, one stream
    re-emission.
  - `purge after the undo window removes the row permanently` — asserts the row is
    gone from `sqlite_schema`-level raw SQL, not merely filtered.
  - `after a purge, no live row carries a deleted_at` — the invariant SPEC §3 states:
    a settled database has `deleted_at IS NULL` everywhere.
  - `deleting a vehicle stamps every child row with the same deleted_at` — fill-ups,
    services, lines, expenses, trips, readings, corrections and items, all with the
    identical timestamp so Undo can restore the exact set.
  - `undo of a vehicle delete restores exactly the set that was stamped` — a row
    deleted before the vehicle stays deleted.
  - `erase vehicle permanently is a hard delete` — no `deleted_at`, nothing to undo,
    and the test asserts it is a separate method from `delete`.
  - `deleting a service item rewrites every referencing line to service_item_id = null`
    — and asserts the line keeps its `label` and its `amount`. History is never touched
    by deleting a reminder definition.
  - `a delete and its undo are each one transaction`.
- **Then build**
  - `lib/data/repositories/deletion.dart` — the shared soft-delete write wrapper and
    the single `WHERE deleted_at IS NULL` base-query helper every read goes through.
  - `VehicleRepository.delete` / `.undoDelete` / `.erasePermanently` — the cascade set
    computed and stamped in one transaction.
  - `ServiceRepository.deleteItem` — the `ON DELETE SET NULL` from Task 5.5 covers the
    hard delete; the soft delete rewrites the lines in the same transaction.
  - `lib/data/repositories/purge.dart` — the purge pass invoked when the undo window
    closes, driven by the injected `Clock`, never by a timer inside the data layer.
- **Verify**
  ```bash
  flutter test test/data/repositories/deletion_test.dart
  ```
- **Done when**
  - [ ] Every read filters soft-deletes through one shared helper.
  - [ ] The vehicle cascade stamps one timestamp and Undo restores exactly that set.
  - [ ] Deleting a `ServiceItem` never deletes or alters a `ServiceRecord`.
  - [ ] A purged row is unrecoverable and no `deleted_at` survives it.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 5.9 — The odometer fan-out: every record carrying a reading emits one

- **Goal** One table is the distance history, so a fill-up, a service, an expense and
  a trip each contribute their reading automatically and consistently.
- **Spec** §3 Entities (`OdometerReading`: *EVERY record carrying an odometer emits a
  reading*); §3 The odometer.
- **Skills** `persistence-drift`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/data/odometer/fan_out_test.dart`
  - `saving a fill-up with an odometer emits a reading with source = fillup and
    source_id = the fill-up id`.
  - `saving a service record emits source = service`, `an expense with an odometer
    emits source = expense`, `a trip emits trip_start and trip_end readings` — four
    cases, one per parent kind, and the trip case asserts two readings when both
    endpoints are set and one when only the start is.
  - `an expense without an odometer emits no reading` — `odometer_m` is nullable there.
  - `editing the parent's odometer updates its derived reading in the same
    transaction` — not a second write, and the reading's `occurred_on` follows the
    parent's date too.
  - `deleting the parent deletes its derived reading with the same deleted_at`, and
    `undo restores both`.
  - `a derived reading cannot be edited directly` — the repository returns
    `PersistFailure.derivedReadingNotEditable`; only `source = manual` and
    `source = import` readings are directly editable.
  - `the fan-out reading participates in monotonicity` — saving a fill-up whose
    odometer goes backwards is refused by the guard from Task 5.6 and leaves neither
    the fill-up nor a reading behind.
- **Then build**
  - `lib/data/repositories/odometer_fan_out.dart` — one function called inside each
    parent repository's transaction: upsert-or-delete the derived reading for a parent
    row. It is the only writer of non-manual readings.
  - Wire it into `FillUpRepository`, `ServiceRepository`, `ExpenseRepository` and
    `TripRepository` saves, edits and deletes.
- **Verify**
  ```bash
  flutter test test/data/odometer/
  ```
- **Done when**
  - [ ] All five sources emit correctly and a trip emits two readings when it has two
        endpoints.
  - [ ] Parent and derived reading are written, edited and deleted in one transaction.
  - [ ] Derived readings are not directly editable.
- **Estimate** 1 h (CC) · ~1 week (human)

### Task 5.10 — The migration ladder, its committed artefacts and the freshness gate

- **Goal** The machinery that makes every future schema change provable exists now,
  at v1, when it costs nothing — including the CI gate that makes forgetting it
  impossible.
- **Spec** §3 Durability; §6.3 Versioning and migration; §17 Data-safety gate.
- **Skills** `run-migration`, `persistence-drift`, `run-codegen`, `testing-strategy`.
- **Write these tests first** — `test/migration/schema_shape_test.dart`,
  `test/migration/freshness_test.dart`
  - `every from -> to pair migrates and validates` — the nested loop from
    `run-migration`, `for from in 1..kLatest-1 { for to in from+1..kLatest }`. At v1 it
    runs zero pairs and that is fine: the loop is written once so a future bump cannot
    forget the skip paths.
  - `the live schema matches the committed snapshot for the current version` — reads
    `drift_schemas/` and diffs against the running schema. Red the moment a table
    changes without `make-migrations` being re-run.
  - `kLatestSchemaVersion equals AppDatabase.schemaVersion` — the two drifting apart
    means no migration runs on a user's device.
  - `PRAGMA integrity_check returns ok on a freshly created database` and
    `PRAGMA foreign_key_check is empty` — the baseline both assertions will be made
    against after every future migration.
  - `tools/check_schema_freshness.sh` gains a self-test case in
    `tools/check_gates_selftest.sh`: bumping `schemaVersion` in a scratch copy without
    adding a snapshot makes the gate exit non-zero.
- **Then build**
  - `drift_schemas/` — the exported snapshot for schema v1, committed.
  - `lib/data/schema_versions.dart` — generated by
    `dart run drift_dev schema steps`, committed.
  - `test/drift/generated/` — era-correct classes from
    `dart run drift_dev schema generate --data-classes --companions`. The two flags are
    load-bearing: without them only shape tests are possible, and a shape test reads
    zero rows.
  - `lib/data/db/app_database.dart` — `MigrationStrategy.onUpgrade` in the exact shape
    from `run-migration`: `PRAGMA foreign_keys = OFF` **before** the transaction that
    wraps `stepByStep`, then `PRAGMA foreign_key_check` after the body, throwing if it
    finds orphans; `beforeOpen` re-asserts `foreign_keys = ON` unconditionally.
  - `tools/check_schema_freshness.sh` and its CI wiring.
  - `epics/progress/EPIC-05.md` records the exact three snapshot commands, so the next
    person bumping the version runs the ritual rather than reinventing it.
- **Verify**
  ```bash
  dart run drift_dev make-migrations
  dart run build_runner build --delete-conflicting-outputs
  flutter test test/migration/
  bash tools/check_schema_freshness.sh
  bash tools/check_gates_selftest.sh
  ```
- **Done when**
  - [ ] `drift_schemas/` and `schema_versions.dart` are committed for v1.
  - [ ] The every-pair loop exists and is written so a bump cannot skip a path.
  - [ ] The freshness gate has been seen to fail on a version bump with no snapshot.
  - [ ] FKs are off before the migration transaction and re-asserted in `beforeOpen`.
- **Estimate** 2 h (CC) · ~2 weeks (human)

### Task 5.11 — The migration guard: safety copy first, restore on failure, read-only after

- **Goal** A migration that fails cannot lose a row: the bytes are snapshotted before
  the database is opened, a JSON copy written by the **old** schema's writer sits in
  app-private storage, and the app comes up read-only with an honest banner instead of
  a crash loop.
- **Spec** §6.3.3 Surviving app updates; §6.4.4 The automatic safety copy; §14
  Odometer and data integrity (*Migration fails on launch*); §17 Data-safety gate;
  `CLAUDE.md` rule 3.
- **Skills** `run-migration`, `persistence-drift` (checkpoint + `VACUUM INTO` +
  verify-by-reopen), `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/migration/migration_guard_test.dart`,
  `test/migration/safety_copy_test.dart`
  - `the JSON safety copy is written before the database is opened` — asserts the file
    exists and that its bytes were produced by the reader registered for the **old**
    `schema_version`, not the current one. A copy taken through the code that is about
    to run is a copy taken through the crash.
  - `the safety copy is named odova-safety-migration-<version>.json` — exact name from
    SPEC §6.4.4, in app-private storage.
  - `a second migration overwrites only the migration copy` — an existing
    `odova-safety-import-*.json` and `odova-safety-wipe-*.json` are untouched. Three
    files at most, one per destructive operation kind.
  - `the byte snapshot includes the -wal and -shm sidecars` — asserts all three files
    are copied, after a `PRAGMA wal_checkpoint(TRUNCATE)`, while nothing holds the
    database open. A raw copy of a live WAL database is torn and unrestorable.
  - `a forced throw mid-migration restores the snapshot byte for byte` — injects a
    step that throws, opens through `openMigratedDatabase`, asserts the open rethrows,
    the connection was closed before any file was touched, and the schema and every row
    are identical to before the attempt.
  - `after a failed migration the app is read-only` — asserts
    `degradedModeProvider` reports `DegradedMode.migrationFailed`, that every
    repository write returns `PersistFailure.storeReadOnly`, and that reads still work.
  - `the read-only mode reads through the retained reader for the old schema_version`
    — a `SchemaReaderV1` is resolvable by version number and is what export would use;
    readers for every shipped version are kept forever, which is why they are numbered.
  - `a successful migration leaves no read-only state and keeps the safety copy` — the
    copy is not deleted on success; it is overwritten by the next migration.
  - `a 12,000-record database migrates with zero record loss` — the §17 gate's oracle:
    per-table counts and a content hash before and after are identical. At v1 the
    ladder is a no-op and the harness is what is being proven; from the first bump on,
    this test is the one that catches a step that copied nothing.
  - `the ladder harness reports its duration` — printed in the test output against
    the §17 budget of 3 seconds on the floor device, asserted only as a
    non-regression ceiling on CI hardware, because CI is not the floor device and a
    hard timing assertion there is a flaky test, not a gate.
- **Then build**
  - `lib/data/db/app_database_opener.dart` — `openMigratedDatabase(File dbFile)` in
    the exact shape from `run-migration`: snapshot the files, open, force the migration
    with `PRAGMA user_version`, and on a throw close the dead connection **first**,
    restore, then rethrow. Every file operation happens with nothing open.
  - `lib/data/backup/migration_safety_copy.dart` — writes the JSON copy through the
    numbered old-schema reader before the open.
  - `lib/data/db/schema_readers/` — one reader per shipped schema version,
    `SchemaReaderV1` today, resolvable by `schema_version`. A `///` comment states the
    rule: readers are never deleted.
  - `lib/data/db/degraded_mode.dart` — the sealed mode, its provider, and the
    write-refusal in the shared repository write wrapper. The banner copy itself is a
    UI epic's job; this epic exposes the state and the string key.
  - `test/migration/support/large_fixture.dart` — the seeded 12,000-record builder,
    deterministic from one seed so a failure is reproducible from the test name.
- **Verify**
  ```bash
  flutter test test/migration/
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is: the forced throw restores, the read-only mode engages, the safety copy is
  present and written by the old writer, and the 12,000-record count/hash oracle is
  identical either side of the ladder.
- **Done when**
  - [ ] The byte snapshot precedes the open and includes `-wal`/`-shm`.
  - [ ] The JSON safety copy is written by the old schema's writer, with the exact
        filename from SPEC §6.4.4, and does not disturb the import or wipe copies.
  - [ ] The forced-throw test restores prior schema and rows byte for byte.
  - [ ] A failed migration yields a read-only app, not a crash loop, and reads go
        through the retained numbered reader.
  - [ ] The zero-record-loss oracle runs over 12,000 records and is wired into CI.
- **Estimate** 4 h (CC) · ~1 month (human)

## Definition of done

- [ ] All ten SPEC §3 entities exist as `STRICT` tables with their enums as `CHECK`s and
      their relations as foreign keys with an explicit `onDelete`.
- [ ] Ids are `<prefix>_<ULID>` with the nine prefixes, minted from an injected clock
      and a seeded generator.
- [ ] Storage is canonical everywhere: metres, millilitres, watt-hours, grams, integer
      minor units + ISO 4217 code, `YYYY-MM-DD` event dates, RFC 3339 UTC bookkeeping
      times. No `REAL` column exists.
- [ ] Every mutation goes through a repository's single write path — one transaction,
      persist, then the watched stream re-emits.
- [ ] Delete is immediate to the user, undoable for the snackbar's life, then purged;
      the vehicle cascade and the `ServiceItem` detach both behave as SPEC §3 says.
- [ ] `cumulativeM`, monotonicity and the three soft warnings are implemented and
      tested; nothing derived is stored.
- [ ] The migration ladder, its committed snapshots, the every-pair loop, the schema
      freshness gate and the safety-copy guard are all in place and have each been seen
      to fail.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

This epic builds no screen, so it carries no `calm-visual-parity` line. Nothing in it
renders; if you find yourself opening a reference screenshot, you are in the wrong
epic.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-05.md`.** It
> starts empty. Append one line per task as it completes — what was built, what was
> deferred, and anything the next epic needs to know. It is the running log for this
> epic and the handover to the next one.

Two things EPIC-06 will look for in it specifically: the exact names of the domain
model fields carrying canonical integers (so the value-object swap knows what it is
replacing), and the three snapshot commands as they were actually run.
