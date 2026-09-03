# EPIC-15 — Backup, export and import

| | |
|---|---|
| **Epic** | EPIC-15 — Backup, export and import |
| **Depends on** | EPIC-05, EPIC-14 |
| **Estimate** | **12.5 h (CC) · ~3 months (human)** over 9 tasks |
| **Spec sections** | §6 Backup, export and import (all ten subsections); §13 → `settings.backup`, `settings.import` |
| **Screens** | `settings.backup`, `settings.import` |

One file stands between a user and eight years of history. This epic builds that file, the
screen that produces it, the screen that reads it back, and the atomic swap that means a crash
mid-import leaves the old data intact.

Two sentences govern everything below. **Import replaces everything; there is no merge in v1.**
And **the backup is plain, unencrypted JSON with English `snake_case` keys regardless of app
language**, because a backup that only opens on a Persian-locale device is not a backup.

After EPIC-05's migrations, this epic carries the heaviest test suite in the repo. That is not
an accident of scope — it is the point. Losing eight years of service history outranks every
feature in the app.

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end, a screen is not done until it matches its reference, and `SPEC.md`
wins over any skill — are stated once in `epics/README.md`. They apply here in full.

---

## Where we are now

The repo began as specification only: `SPEC.md`, `design/`, `tools/`, `.claude/skills/`, and
**no Flutter app at all** — no `pubspec.yaml`, no `lib/`. EPIC-01 created it; everything since
inherits from that commit.

By the time this epic starts:

| From | What this epic consumes |
|---|---|
| EPIC-01 | The Flutter app, `very_good_analysis` pinned, `pubspec.lock` committed, the composition root with the `Clock` seam, the `Result`/`Failure` spine, and CI's Flutter lane armed. |
| **EPIC-05** | The Drift store: every table in §3 (`Vehicle`, `ServiceItem`, `ServiceRecord`, `ServiceLine`, `Fillup`, `Expense`, `Trip`, `OdometerReading`, `OdometerCorrection`, `Settings`), the ULID id minting with the nine `veh_`/`rem_`/`srv_`/`lin_`/`fil_`/`exp_`/`trp_`/`odo_`/`cor_` prefixes, the internal `schema_version`, the forward-only migration runner, and the WAL-safe snapshot primitive. Canonical integer storage — `odometer_m`, `quantity_ml`/`quantity_g`/`energy_wh`, `amount_minor` + ISO 4217 — is already the only way data is stored. **EPIC-05 also already ships §6.3.3's and §6.4.4's on-device half**: the safety copy written by the old schema's writer before a schema migration. Task 15.3 extends that store; it does not invent it. |
| EPIC-06 | `Money`, `Distance`, `Volume`, `Energy` and the exact conversions (1 mi = 1.609344 km, 1 US gal = 3.785411784 L). The CSV in Task 15.8 converts to the user's units through these; the backup JSON never converts at all. |
| EPIC-12 | `report.service` and its on-device PDF renderer, and `dialog.confirmDelete` (built in EPIC-12 Task 12.9). Task 15.9 hands that renderer a vehicle; Task 15.6 uses that dialog in its typed variant. Neither builds a second one. |
| **EPIC-14** | The settings tree with **Backup & restore as its first row**, the `SettingsRepository` single write path, the `ShareGateway` seam proven by the `.ics` export, and `settings.about` already rendering `Backup format 1` from `SUPPORTED_FORMAT_VERSION` — a constant **this epic takes ownership of** in Task 15.1. |
| EPIC-16 | `ReminderScheduler` and the notification gateway. §6 §4.1 requires that after the swap all local notifications are cancelled wholesale and rescheduled, because the ids the OS holds belong to the old data. This epic *triggers* that; EPIC-16 Task 16.9 owns the rebuild itself. |
| The due engine (EPIC-07) | `resolveAnchor`, `DueState`, `estimateOdometer`, and the cumulative-distance rule `odometer_m + Σ(previous_m − new_m)` — all pure, all recomputed on read. This epic calls them after an import; it never reimplements them. |

> Read `epics/progress/EPIC-05.md` and `epics/progress/EPIC-14.md` before Task 15.1. EPIC-05's
> progress file names the exact domain model field names this epic's mapping layer projects
> from, and EPIC-14's says whether `SUPPORTED_FORMAT_VERSION` was declared there provisionally.

**Deliberately still missing when this epic starts:** there is no way to get data out of the
app and no way to get it back in. `settings.backup` and `settings.import` are routes EPIC-07
declared and nothing satisfies — EPIC-10's all-clear card and EPIC-16's `backup.nudge` deep
link both push `settings.backup`, and both currently land on a placeholder. There is no backup
writer, no reader, no `format_version` migration chain, no test corpus, no import-time
safety-copy kind, and no CSV. The app is, today, a place where data goes to be lost with the
phone.

---

## What we will have when this is done

- Settings → Backup & restore → **Back up now** produces
  `odova-backup-2026-09-02-1841.json` in the OS share sheet: UTF-8, no BOM, real UTF-8
  characters rather than `\uXXXX` escapes, pretty-printed at 2-space indent, English
  `snake_case` keys, ASCII digits, canonical integers.
- Exporting the same unchanged data twice produces two files that are **byte-identical below
  `settings`** — `diff` past the envelope is a real answer to "did anything change?".
- Settings → Backup & restore → **Restore from a backup** opens the OS document picker, and a
  file identified **by its `format` key, never by MIME type or extension**, opens the preview.
- The preview shows the file name and export date in the user's own format, the vehicles by
  name with their record counts, a NOW → AFTER column for every record type, every warning in
  plain language, and the sentence **"Everything now in Odova will be replaced by this file."**
  Nothing has been written to the device to reach that screen.
- **Replace my data** writes a safety copy, builds a fresh database beside the old one, swaps
  it with one atomic rename, applies corrections, rebuilds every derived value, and cancels and
  reschedules every notification. Kill the process at any instant and the device holds either
  the old data or the new data, never a mixture.
- Every error message in §6 §5.2 is on screen in all six languages, written for someone who has
  never heard the word JSON — no "rows", "entities", "schema" or "parse" anywhere.
- **Undo last import** and **Undo delete all data** appear only when their safety copy exists,
  each showing its expiry, beside one line saying the copies go when Odova is uninstalled.
- **Delete all data** is behind a type-to-confirm dialog in the localised imperative, writes
  its safety copy first, and routes to `vehicle.edit` (firstRun) with language — and only
  language — surviving.
- Fill-ups CSV and all-costs CSV export with a UTF-8 BOM, CRLF, RFC 4180 quoting and
  formula-injection escaping, in the user's own units with the derived columns computed.
- `flutter test test/corpus/` imports every checked-in file in the corpus, and a red corpus
  blocks the release.
- `flutter test test/parity/` plus `check_parity.sh` are clean over `settings.backup` and
  `settings.import` in all four combinations.

---

## Skills to load

Open `flutter-conventions-index` first; it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules: layers, dumb widgets, typed results, injected side effects, the single write path. |
| `data-export-and-restore` | **The governing skill.** Backup vs export as two different features, the header-first envelope, stage-and-swap restore, canonical values in machine formats, RFC 4180 plus formula-injection escaping, stream-to-temp-then-rename, the injected share gateway, and the round-trip test on a hostile fixture. |
| `persistence-drift` | The staging database, the WAL-safe snapshot primitive (never `File.copy` on an open database), and the DAO layer the importer writes through. |
| `run-migration` | The forward-only path an older payload is migrated through, and the discipline the `json → json` chain in §6 §3.1 mirrors. |
| `error-handling-typed-results` | `Result<T, F>` with one sealed failure per refusal reason. "Restore failed" with no reason is indistinguishable from data loss to the person reading it. |
| `calm-visual-parity` | Two referenced screens × four combinations = 8 gates, and the honest account of what those gates prove. |
| `calm-components` | `settings.backup` and `settings.import` are `CalmRowGroup`/`CalmListRow`/`CalmButton`/`CalmDialog` compositions; `settings.import` is a blocking modal with a non-cancellable progress state. |
| `i18n-rtl-l10n` | Filenames forced LTR inside an RTL layout, counts digit-shaped per `numerals`, dates per `calendar`, and the two most heavily reviewed strings in the app as single ICU messages. |
| `service-boundary-and-native` | `ShareGateway`, `DocumentPickerGateway`, `FileSystemGateway` and `StorageSpaceGateway` — every one of them faked, because none of the failure paths can be tested otherwise. |
| `testing-strategy` | Hostile fixtures, property and round-trip tests, the injected `Clock`, and why the corpus only ever grows. |
| `seeded-determinism-and-golden-vectors` | The export must be byte-reproducible below the envelope, and the corpus files are golden vectors checked into the repo. |

---

## Tasks

### Task 15.1 — Build the envelope, the writer and byte-determinism

- **Goal** — The app can serialise its whole store to one plain JSON document that matches §6's
  worked example field for field, and two exports of unchanged data differ only in the envelope.
- **Spec** — §6 §1 *Canonical model and the export mapping*, §2 *The file format* (2.1–2.6), §7
  *What is deliberately not in the backup*, §9 *Size and performance*.
- **Skills** — `data-export-and-restore`, `persistence-drift`,
  `seeded-determinism-and-golden-vectors`, `value-objects-money-and-units`, `dartdoc-conventions`.
- **Write these tests first** — `test/backup/backup_writer_test.dart`:
  - `the envelope carries format, format_version, app_version, app_build, platform,
    exported_at, exported_at_local, units, derived_fields, record_counts and content_hash, in
    that key order` — order is asserted because §6 §2.6 makes a streaming reader's one-pass
    resolution depend on it.
  - `format is exactly "odova.backup" and format_version is 1`.
  - `exported_at is RFC 3339 UTC with Z and exported_at_local carries the writer's offset for
    the same instant` — from an injected `Clock` with a pinned zone.
  - `arrays are written settings, vehicles, reminders, odometer_readings,
    odometer_corrections, fillups, services, expenses, trips` — parents before children.
  - `records within an array are sorted by id` — which for ULIDs is creation order.
  - `two exports of unchanged data are byte-identical below settings` — export, export again,
    strip the envelope, compare bytes. This is the CI corpus assertion from §6 §2.6.
  - `content_hash is sha256 over the document with the hash field set to 64 zeros, overwritten
    in place` — assert the length is unchanged so no offsets shift, and assert a verifier
    recomputes the same value.
  - `the file is UTF-8 with no BOM and contains real UTF-8 characters, not \uXXXX escapes` —
    the fixture carries `Zahnriemen laut Werkstatt`, a Persian note and an emoji.
  - `every digit in the file is ASCII 0-9 even when numerals = extended_arabic_indic` — export
    from a `fa` fixture with Jalali display and assert no U+06F0–U+06F9 anywhere.
  - `no bidi control character reaches the file` — a `⁨` in a backup breaks search, sorting and
    the read-it-in-a-text-editor property.
  - `money is always {amount_minor, currency} and never a decimal string`.
  - `Iranian amounts export as IRR and IRT appears nowhere` — even with
    `currency_display = toman`.
  - `vehicles[].distance_unit, volume_unit, consumption_unit and currency are null when
    inherited and are never materialised` — otherwise a round trip pins every vehicle to
    whatever the defaults happened to be.
  - `vehicles[].status is active|archived|sold and the old archived boolean is not written`.
  - `reminders write last_done_date, last_done_odometer_m and last_done_service_id and list all
    three in derived_fields`.
  - `there is no rule field, no mode field and no stored next-due`.
  - `services carry no total_cost, parts_cost or labour_cost` — the cost is the sum of lines.
  - `odometer_readings holds standalone readings only and omits source_id`.
  - `deleted rows are not exported and deleted_at is null on every record`.
  - `photo_id, attachment_ids and last_backup_reminder_at are absent`.
  - `record_counts matches the arrays and includes total`.
  - `the §6 §2.5 worked example round-trips` — parse the exact JSON block from `SPEC.md`, write
    it back, assert equality. `tools/check_spec_examples.py` already asserts it parses; this
    asserts we agree with it.
  - `5,000 records serialise, hash and write in under 3 s on the test host` — a soft
    performance floor, not the device target.
- **Then build** — `lib/backup/backup_format.dart` — `const SUPPORTED_FORMAT_VERSION = 1`
  (this epic takes ownership; `settings.about` reads it). `lib/backup/backup_document.dart` —
  the `BackupDocument` value type and its `toJson`. `lib/backup/backup_writer.dart` —
  `BackupWriter.write(IOSink)` streaming array by array so a 12,000-record store never assembles
  in a `String`. `lib/backup/content_hash.dart` — the zeros-then-overwrite hash.
  `lib/backup/mapping/*.dart` — one projection per entity, each a pure function from the domain
  type, so §2.4 is a mapping and never a second model.
- **Verify**
  ```bash
  flutter test test/backup/backup_writer_test.dart
  python3 tools/check_spec_examples.py
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] The writer reproduces §6 §2.5 field for field.
  - [ ] Two exports of unchanged data are byte-identical below `settings`.
  - [ ] ASCII digits and no bidi controls, from every locale.
  - [ ] Nothing derived, deleted or device-local reaches the file.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 15.2 — Build the reader: the validation ladder, typed failures and plain-language messages

- **Goal** — Any file a user picks is classified — accepted, accepted with warnings, or refused
  with a message a non-technical person can act on — and nothing is written to reach that verdict.
- **Spec** — §6 §5 *Validation and errors* (5.1 order of checks, 5.2 the messages, 5.3 orphans,
  5.4 memory and hostile input); §6 §6 *Import delivery*.
- **Skills** — `data-export-and-restore`, `error-handling-typed-results`, `i18n-rtl-l10n`,
  `testing-strategy`, `async-safety`.
- **Write these tests first** — `test/backup/backup_reader_test.dart`, one case per rung of the
  §6 §5.1 ladder, each asserting the **typed failure** and that the picked file is byte-unchanged:
  - `a 203 MB file is refused before opening` — size is checked first, at rung 1.
  - `gzip magic and zip magic yield CompressedFile` → "This file is compressed."
  - `invalid UTF-8 yields NotUtf8`; `a leading BOM is stripped silently and the file imports`.
  - `a parse error at EOF yields Truncated`; `a parse error mid-file yields NotValidJson` —
    two different messages, and the distinction is the whole point of rung 3.
  - `a PDF yields NotOdova` → "That file isn't an Odova backup."
  - `valid JSON with no format key yields NotMadeByOdova` — a different message from the above.
  - `format_version 2 with SUPPORTED_FORMAT_VERSION 1 yields TooNew` — and asserts the file is
    not modified, moved or deleted. Downgrade is not supported and never will be.
  - `format_version missing or non-integer yields CorruptVersion`.
  - `a top-level array that is a string is a document-level failure`; `a missing array is
    treated as empty and warned about`.
  - `content_hash mismatch is a warning, not a refusal` — and `record_counts mismatch is a
    warning` carrying both numbers.
  - `an unknown enum value keeps the record and coerces to other/custom with a warning` — the
    €612 insurance row survives an unknown category.
  - `a quantity_ml of "forty" skips the record; a 312-litre fill in a 50-litre tank imports` —
    type errors reject a record, odd values do not.
  - `a record dated 1974, and one dated three years after exported_at, both import with a
    warning`.
  - `an unresolvable vehicle_id routes the record to the Recovered records vehicle` — never
    dropped, and the name is `import.recoveredVehicleName`, localised.
  - `an unresolvable trip_id or service_item_id is nulled with a warning`.
  - `a correction whose from_reading_id does not resolve is skipped and warned about, never
    applied to an arbitrary reading`.
  - `duplicate ids within the file: the first wins, the rest are counted and warned about`.
  - `more than 5% or more than 50 unreadable records refuses the whole import as too damaged` —
    both thresholds, and the boundary either side of each.
  - `a 6 MB file parses incrementally with peak memory under 3× the file size`.
  - `nesting deeper than 32 is refused`; `a string longer than 1 MB is truncated with a warning`.
  - `unknown keys at every level are ignored and not preserved` — a v1.4 file opens in a v1.2
    reader with nothing worse than a missing column.
- and `test/backup/import_messages_test.dart`:
  - `every ImportFailure and every ImportWarning has a message key in all six ARB files`.
  - `no import message contains the words JSON, schema, parse, row, entity or record id` — a
    string-scan over all six ARBs. The skipped-entry list says "Fill-up, 14 August 2026 — the
    amount of fuel was missing", and never an identifier.
  - `the size, count and record-count messages interpolate their numbers through ICU plurals
    with all six Arabic categories authored`.
- **Then build** — `lib/backup/backup_reader.dart` — `BackupReader.read(File)` returning
  `Future<Result<ImportPlan, ImportFailure>>`, running the thirteen rungs in the §6 §5.1 order
  and short-circuiting on the first document-level failure. `lib/backup/import_failure.dart` —
  the sealed `ImportFailure`; `lib/backup/import_warning.dart` — the sealed `ImportWarning`,
  each carrying its count and its affected-record list. `lib/backup/incremental_parser.dart`
  for files over 4 MB. Identification is by the `format` key; the picker filter is loose (JSON
  plus all files) because providers routinely hand back `.json` as `application/octet-stream`,
  and **Odova does not register as a system handler for `.json`**.
- **Verify**
  ```bash
  flutter test test/backup/backup_reader_test.dart test/backup/import_messages_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is every rung green and every message present in six languages.
- **Done when**
  - [ ] Every rung of §6 §5.1 has a test and a distinct typed failure.
  - [ ] Document-level failures abort with nothing written; record-level problems never abort.
  - [ ] Every message in §6 §5.2 exists in six locales and uses no technical term.
  - [ ] The picked file is byte-unchanged on every refusal path.
- **Estimate** — `2 h (CC) · ~2 weeks (human)`

---

### Task 15.3 — Build the migration chain and check in the corpus

- **Goal** — A file written by any shipped version of Odova opens in this one, through one chain
  of pure `json → json` functions applied in memory before anything touches the database.
- **Spec** — §6 §3 *Versioning and migration* (3.1 reading an old file, 3.2 the refusal, 3.3
  surviving app updates).
- **Skills** — `run-migration`, `data-export-and-restore`, `seeded-determinism-and-golden-vectors`,
  `testing-strategy`, `ci-pipeline-and-gates`.
- **Write these tests first** — `test/backup/migration_chain_test.dart`:
  - `import runs the chain 1→2→…→SUPPORTED_FORMAT_VERSION and sets format_version at each step`
    — with two synthetic future migrations registered in the test so the loop itself is tested
    while v1 is the only real version.
  - `a migration is pure: it performs no I/O and does not touch the database` — assert against a
    fake filesystem that records zero opens.
  - `a migration never deletes a user value` — a property test over the whole corpus: for every
    file, every non-null user-entered string present before the chain is present after it, or
    has moved into that record's `notes`.
  - `a migration never fails on missing data` — every absent field in §6 §3.1's fill-in table
    gets its stated default: `vehicles[].status` from the old `archived` boolean;
    `vehicle_type` → `"car"`; `is_business` / `notifications_muted` → `false`;
    `reminders[].notify` / `repeats` / `is_active` / `is_tracked` → `true`;
    `priority` → `"normal"`; `rollover` → `"from_actual"`; `snooze_count` → `0`;
    `services[].odometer_estimated` / `cost_estimated` → `false`;
    `settings.quiet_hours_from` → `21:00`, `_to` → `08:00`; `weekdays_only` → `false`;
    `settings.notify_*` → `true`; `settings.currency_display` → `"toman"` when
    `language == "fa"`, else `"none"`. One case per row.
  - `reminders[].rule is dropped on read` — `distance_only` clears `interval_months`;
    `date_only` clears `interval_distance_m`; `whichever_last` becomes an ordinary
    whichever-comes-first item **and is counted in the warning** "{n} reminders used a setting
    Odova no longer has."
  - `format_version above SUPPORTED refuses outright with no partial read` — and the file is
    untouched.
- and `test/corpus/corpus_test.dart`:
  - `every file in test/corpus/ imports` — the directory is walked, not enumerated in code, so
    adding a file adds a case. **The corpus only grows.**
  - `each corpus file's expected outcome matches its sidecar` — every `foo.json` has a
    `foo.expected.json` naming the counts, the warnings and the failure, if any.
  - The corpus ships at minimum: the §6 §2.5 worked example; an empty-but-valid file; a
    single-vehicle file; a 4.5 MB trades file (three vans, ten years, ~12,000 records); a
    truncated file; a file with a flipped `content_hash` byte; a `record_counts` mismatch; a
    file with 3 orphan records; a file with an unmatched correction; a file with duplicate ids;
    a file with 6% unreadable records; a file with an unknown future key at three levels; a
    hostile-text file carrying apostrophes, quotes, commas, embedded newlines, emoji, RTL text
    with bidi marks, whitespace-only strings, the largest supported integer, and a
    null-vs-empty pair.
- **Then build** — `lib/backup/migrations/migrations.dart` — `const Map<int, JsonMigration>
  kMigrations` and the `runMigrations(Map<String, Object?>)` loop from §6 §3.1, exactly as
  written. `lib/backup/migrations/v0_defaults.dart` — the fill-in table as one pure function.
  `test/corpus/**` — the checked-in files and their sidecars. Wire the corpus test into CI so a
  red corpus blocks release.
  §6 §3.3's first bullet — **before any on-device schema migration runs, write a full JSON
  backup to app-private storage using the old schema's reader** — is **EPIC-05's**, already
  built. What this task adds is the *writer* that copy calls: until now EPIC-05 had no JSON
  format to write. Wire `odova-safety-migration-<version>.json` to the retained reader for that
  `schema_version`, never to current-schema readers, and assert it — exporting through the code
  that just failed is exporting through the crash. If EPIC-05's copy is currently written in
  some interim shape, converting it is part of this task and belongs in the progress file.
- **Verify**
  ```bash
  flutter test test/backup/migration_chain_test.dart test/corpus/
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is a green corpus. A red corpus is a release blocker, not a flaky test.
- **Done when**
  - [ ] The chain is pure, in-memory, and runs before anything touches the database.
  - [ ] Every fill-in row from §6 §3.1 has a test.
  - [ ] The corpus is checked in with sidecars and wired into CI.
  - [ ] A newer `format_version` is refused outright and the file is untouched.
- **Estimate** — `2 h (CC) · ~2 weeks (human)`

---

### Task 15.4 — Build the safety copies and the atomic-swap importer

- **Goal** — Confirming an import writes a safety copy first, builds a new database beside the
  old one, and swaps it in with one rename — so a process kill at any instant leaves either the
  old data or the new data, never a mixture.
- **Spec** — §6 §4 *Import semantics* (4.1 transactional write, 4.2 what the file does not get to
  decide, 4.4 the automatic safety copy); §14 → *Disk full mid-export or mid-import*,
  *Backup file imported twice*.
- **Skills** — `data-export-and-restore`, `persistence-drift`, `run-migration`,
  `error-handling-typed-results`, `async-safety`, `local-notifications-scheduler`.
- **Write these tests first** — `test/backup/importer_test.dart`:
  - `a kill before the rename leaves the old database byte-unchanged` — inject a failure at
    every stage of the pipeline in turn (staging open, insert, count verify, close, rename) and
    assert the live database's bytes are identical each time.
  - `the rename is the only publish step and it happens after every handle is closed`.
  - `counts are verified against record_counts before the swap`.
  - `after the swap, corrections are applied, then derived values are rebuilt, then all local
    notifications are cancelled wholesale and rescheduled` — assert the **order** on a
    recording fake. The OS holds notification ids belonging to the old data. The rebuild
    itself is EPIC-16 Task 16.9's; this asserts that the importer calls it, exactly once, and
    last.
  - `derived_fields are read for display and then discarded` — a file whose
    `last_done_odometer_m` disagrees with its own `services[].lines[].service_item_id` imports
    with the anchor from `resolveAnchor`, not from the file. A file that disagrees with its own
    inputs loses.
  - `service cost comes from the sum of lines, never from the file`.
  - `import is cancellable up to the swap and cancelling leaves the device exactly as it was`.
  - `not enough storage yields NotEnoughSpace and writes nothing` — with the required figure in
    the message.
  - `a safety copy is written before any destructive operation` — three cases: import,
    delete-all, schema migration. **No exceptions.**
  - `each kind is overwritten only by the next operation of the same kind` — an import never
    eats the copy a wipe left; assert all three filenames coexist.
  - `a re-import whose content_hash and record_counts match the currently-loaded import does not
    overwrite the safety copy` — this is the commonest recovery panic, and overwriting here is
    exactly how the three months the user was trying to get back disappear.
  - `undo is itself a replace and takes its own safety copy first` — so a user can bounce back
    and forth without reaching a state they cannot leave.
  - `a safety copy expires after 30 days and its row disappears rather than greying out`.
  - `safety copies live in app-private storage` — assert the path, because uninstalling must
    delete them and Settings says so.
  - `active_vehicle_id naming no vehicle in the file promotes the first by sort_order`.
  - `onboarding_done is set true by a successful import and is never read from the file`.
  - `preferences from the file are applied — language, direction, units, calendar, numerals,
    notification time` — restoring onto a new phone gives back the app you had, not a German one.
  - `5,000 records: write and swap under 8 s, recompute and reschedule under 4 s on the test
    host` — the §6 §9 hard limits, as a regression floor.
- **Then build** — `lib/backup/importer.dart` — `Importer.apply(ImportPlan)` returning
  `Future<Result<RestoreReport, ImportFailure>>`, following stage → validate → close → rename.
  `lib/backup/safety_copy_store.dart` — `SafetyCopyStore` over the three filenames
  `odova-safety-migration-<version>.json`, `odova-safety-import-<timestamp>.json`,
  `odova-safety-wipe-<timestamp>.json`, with the match-suppression rule and the 30-day expiry.
  `lib/backup/post_import_rebuild.dart` — the ordered corrections → derived → notifications
  sequence. All of it runs off the UI thread; a progress indicator appears only past 500 ms,
  because below that a spinner is flicker.
- **Verify**
  ```bash
  flutter test test/backup/importer_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] A failure at every stage leaves the live database byte-unchanged.
  - [ ] The publish is a single atomic rename after every handle is closed.
  - [ ] The post-swap order is corrections → derived → cancel-all-and-reschedule.
  - [ ] All three safety-copy kinds exist independently, with the re-import suppression rule.
- **Estimate** — `2 h (CC) · ~2 weeks (human)`

---

### Task 15.5 — Build export delivery: filenames, temp files, the share hand-off and the backup nudge

- **Goal** — Every file leaving the app is one the user tapped for, is named so it survives
  email, Windows, USB sticks and every cloud drive, and never publishes half-written.
- **Spec** — §6 §6 *File naming and delivery*; §6 §10 *Why there is no encryption*; §4 →
  `backup.nudge`.
- **Skills** — `data-export-and-restore`, `service-boundary-and-native`, `i18n-rtl-l10n`,
  `async-safety`, `local-notifications-scheduler`.
- **Write these tests first** — `test/backup/export_delivery_test.dart`:
  - `the backup filename is odova-backup-YYYY-MM-DD-HHmm.json from local time` — injected
    `Clock` and a pinned zone; assert `odova-backup-2026-09-02-1841.json`.
  - `filenames are ASCII lowercase with hyphens, no spaces, no translated app name and no
    vehicle names in the backup` — and sort chronologically.
  - `the vehicle part of a CSV/PDF filename transliterates to [a-z0-9-]` — `Golf` → `golf`;
    `VW Käfer` → `vw-kafer`.
  - `a vehicle name written only in Arabic script falls back to vehicle-2 by list position`.
  - `where Odova controls the destination a collision appends -2, then -3`.
  - `the file is written to the app's own temp directory and handed to ShareGateway` — the app
    chooses no destination, requests no storage permission and remembers nothing.
  - `temporary copies are deleted on the next launch`.
  - `nothing is exported automatically, on a schedule, or in the background` — assert no
    scheduled work item exists for any exporter.
  - `a failed write deletes the temp file and publishes nothing` — and returns
    `ExportFailure.write`, whose message is "Odova couldn't finish the backup. Nothing on this
    phone has changed. Try again in a moment." with **Try again · Cancel**.
  - `not enough free space yields the message naming the size needed, with OK only`.
  - `no share mechanism available yields the restart-your-phone message, with OK only`.
  - `last_backup_at is stamped on the share sheet's completion or dismissal` — on hand-off, not
    on confirmed save, because the OS never tells us what the user did with the file.
  - and the nudge: `at most one backup.nudge every 90 days`; `no nudge below 20 new records
    since the last export`; `never exported and fewer than 20 records is silence`;
    `last_backup_reminder_at is nudge bookkeeping, is not in the file, and a restored phone
    starts its 90-day clock fresh`.
- **Then build** — `lib/backup/export_filename.dart` — the four naming rules and the
  transliterator. `lib/backup/backup_export_service.dart` — stream to temp, rename, hand to
  `ShareGateway`, stamp `last_backup_at`, delete temps on launch.
  `lib/features/settings/domain/backup_nudge.dart` — the 90-day / 20-record **predicate only**.
  EPIC-16 owns the scheduling: its slot builder places `backup.nudge` in the priority order
  `overdue2 > overdue1 > due > nudge > early` under the two-a-week cap, and its router
  synthesises `[home, settings, settings.backup]` so Back walks out through Settings. This task
  supplies the boolean and the counts EPIC-16 asks for, and schedules nothing itself.
- **Verify**
  ```bash
  flutter test test/backup/export_delivery_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Every export filename follows §6 §6 exactly, including the transliteration fallback.
  - [ ] Every failure path deletes the temp file and publishes nothing.
  - [ ] `last_backup_at` is stamped on hand-off.
  - [ ] Nothing exports automatically, ever.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 15.6 — Build `settings.backup`

- **Goal** — The most important screen after Home: get your data out, get it back in, and
  destroy it deliberately.
- **Spec** — §13 → `settings.backup` and its state table; §6 §10 (the unencrypted warning); §7 →
  the `settings.backup` edges and the migration-failure launch row.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-layout-and-motion`,
  `ui-states-and-feedback`, `i18n-rtl-l10n`, `accessibility-as-code`, `navigation-and-routing`.
- **Write these tests first** — `test/features/settings/backup_screen_test.dart`:
  - `"Back up now" is the only filled button on the screen` — Calm allows one primary element
    per screen, and two primaries means the screen has failed.
  - `the unencrypted warning sits directly beneath the button` — not in a footnote, not behind
    an info icon. Assert its position in the widget tree, not just its presence.
  - `never backed up: "You've never made a backup." plus "68 entries are only on this phone.",
    amber`.
  - `backed up 12 days ago: neutral, and the count line is hidden below 20 new entries`.
  - `backed up 4 months ago: amber, the ⚠ glyph, and the count line always shown`.
  - `zero entries: "Back up now" disabled with "Nothing to back up yet.", CSV and PDF rows
    hidden`.
  - `no safety copy of a kind: that Undo row is absent entirely, not greyed`.
  - `a wipe safety copy renders "Undo delete all data" with its 30-day expiry, beside "Undo last
    import" when both exist`.
  - `the safety-copies-go-on-uninstall line renders once, next to the buttons`.
  - `migration failed: the red banner renders above everything; only Back up now and the
    CSV/PDF rows are enabled; Restore and Delete are disabled` — and `export runs through the
    retained reader for the old schema_version` — assert the fake records the retained reader,
    never the current one.
  - `Back up now replaces itself with an inline "Preparing your backup…" progress state`.
  - `the app can launch directly onto this screen` — the one screen the app may open on instead
    of `home`, with the synthesised stack `[home, settings, settings.backup]`.
  - `Restore from a backup opens the document picker; a cancelled picker changes nothing`.
  - `Delete all data writes the wipe safety copy before the dialog opens` — assert the ordering,
    because a copy written after confirmation is a copy that does not exist when it is needed.
  - `the delete dialog names the vehicle count, the entry count and the earliest date`.
  - `Delete stays disabled until the typed word matches the localised imperative` — six cases:
    `DELETE`, `LÖSCHEN`, `SUPPRIMER`, `حذف`, `سڕینەوە`, and the Arabic one — matched
    case-insensitively after Unicode normalisation, and matching the word shown verbatim in the
    sentence above the field.
  - `on confirm the store is wiped, notifications are cancelled, and the app routes to
    vehicle.edit (firstRun)`.
  - `language, and only language, survives the wipe` — we are not asking someone who just wiped
    their data to find their alphabet again.
  - `the on-disk size line renders digit-shaped per numerals`.
  - `the filename is forced LTR and start-aligned inside an RTL layout` — assert direction, not
    appearance.
- **Then build** — `lib/features/settings/ui/backup_screen.dart` (`BackupScreen`,
  `BackupNotifier` over an immutable `BackupScreenState`), the delete-all flow through the
  **existing `dialog.confirmDelete` widget from EPIC-12 Task 12.9**, in its typed variant —
  reuse it, do not reimplement it. Its four reference images belong to EPIC-12, so if this task
  changes that widget's layout, re-run `check_parity.sh` over
  `build/parity/dialog.confirmDelete-*.png` as well.
- **Verify**
  ```bash
  flutter test test/features/settings/backup_screen_test.dart
  flutter test test/parity/settings_backup_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/settings.backup-light-ltr.png \
       settings.backup --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.backup-light-ltr.png    # look at the side-by-side
  ```
  The check gates theme, Calm-token colour and the vertical band profile. It does **not** gate a
  raw pixel diff — the reference is Chrome and the app is Skia, and 25–45% of pixels differ on a
  correct screen. Do not chase it to zero.
- **Done when**
  - [ ] All seven states in §13's table render correctly.
  - [ ] "Back up now" is the only filled button and clears the fold at 200% scale in German.
  - [ ] The unencrypted warning is directly beneath it.
  - [ ] Delete all data writes its safety copy first and survives only the language setting.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 15.7 — Build `settings.import`

- **Goal** — Show exactly what is in the chosen file and what it will do, then do it — with one
  unambiguous sentence, no technical term, and nothing written before Confirm.
- **Spec** — §13 → `settings.import`; §6 §4.3 *The preview*, §4.4, §5.2, §5.3.
- **Skills** — `calm-components`, `calm-visual-parity`, `ui-states-and-feedback`,
  `i18n-rtl-l10n`, `navigation-and-routing`, `accessibility-as-code`, `async-safety`.
- **Write these tests first** — `test/features/settings/import_screen_test.dart`:
  - `nothing is written to reach the preview` — a spy on every DAO asserts zero writes from
    picker to preview.
  - `the header shows the file name and the export date in the user's own format, plus the app
    version that wrote it` — "odova-backup-2026-09-02-1841.json, exported 2 September 2026 at
    18:41", and in `fa` with Jalali the date reads `۲۲ فروردین ۱۴۰۵`.
  - `WHAT'S IN THIS FILE lists the vehicles by name with their record counts and the entry date
    span` — names are what the user recognises; totals are not.
  - `NOW → AFTER carries every record type and the total`.
  - `a count that goes down renders amber` — losing 24 fill-ups must not look like the other rows.
  - `every warning renders in plain language with its record count`.
  - `the sentence "Everything now in Odova will be replaced by this file." is present, is one
    ICU message, and is not softened` — an explicit assertion, because it is the string a
    future PR will soften.
  - `the reassurance line "A copy of what you have now is saved first." is present and is true`
    — assert the safety copy is actually written on confirm.
  - `buttons are Replace my data / Cancel`.
  - `empty-device variant: the comparison collapses to one After column, the sentence becomes
    "Odova is empty, so nothing will be replaced." and the button reads Import`.
  - `already-restored variant: content_hash matches the last successful import and nothing has
    been written since — the comparison becomes "This is the backup you already restored.
    Nothing on this phone will change.", the primary button becomes Done, and Replace anyway
    sits beneath as a text button`.
  - `undo variant: header reads "The data you had before 2 September 2026, 14:12" with the same
    Replace/Cancel pair`.
  - `"See which" opens an inline disclosure listing each skipped entry as type, date and plain
    reason` — "Fill-up · 12 Jan 2021 · the date is missing" — and shows no identifier.
  - `no string on this screen contains JSON, schema, parse, row or entity` — a scan of the
    rendered tree in all six locales.
  - `Replace my data raises no second dialog` — the preview *is* the confirmation.
  - `the progress state is non-cancellable and disables swipe-down dismissal`.
  - `a crash mid-import leaves the old data and the next launch opens on home with the snackbar
    "Your last restore didn't finish. Nothing was changed."`.
  - `success with zero skipped entries dismisses the modal, resets every tab stack, selects
    Home, and shows "Restored. 3 vehicles, 3,006 entries."`.
  - `success with skipped entries holds on a result state with the list and a Done button` — a
    snackbar cannot carry a list, and a count that quietly dropped three things must be
    acknowledged by a tap.
  - `Cancel, back and swipe-down all return to the caller with nothing written, until the
    progress state begins`.
  - `the NOW → AFTER arrow mirrors to ← and the columns swap in RTL, while labels stay at the
    start edge`.
  - `"3 entries can't be read" is an ICU plural with all six Arabic categories authored and no
    =0 rendered here`.
  - `the sentence block has no fixed height and the buttons are pinned below a scrollable body`
    — German pushes it to three lines at 200% scale.
- **Then build** — `lib/features/settings/ui/import_screen.dart` (`ImportScreen`,
  `ImportNotifier` over a sealed `ImportScreenState { preview, progress, result }`), reachable
  as a blocking modal from `settings.backup` and from either firstRun screen via the OS picker.
  The three preview variants are one widget over a sealed `PreviewVariant`, not three screens.
- **Verify**
  ```bash
  flutter test test/features/settings/import_screen_test.dart
  flutter test test/parity/settings_import_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/settings.import-light-ltr.png \
       settings.import --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.import-light-rtl.png
  ```
  The reference is shot in the standard replace variant; capture that for parity and cover the
  other two variants and the progress and result states in the widget test. Look hardest at the
  RTL sheet: the mirrored NOW → AFTER arrow and the forced-LTR filename are exactly what the
  band check cannot see.
- **Done when**
  - [ ] Nothing is written before Confirm, proven by a spy on every DAO.
  - [ ] All three preview variants render, plus the progress and result states.
  - [ ] The replacement sentence is present, unsoftened, and one ICU message.
  - [ ] No technical term appears anywhere on the screen in any of the six locales.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `2 h (CC) · ~2 weeks (human)`

---

### Task 15.8 — Build the two CSV exports

- **Goal** — The spreadsheet people get their numbers, in their own units, with the derived
  columns already computed — and a cell nobody can turn into a formula.
- **Spec** — §6 §8.1 *CSV — for the spreadsheet people*; §6 §6 (naming and delivery).
- **Skills** — `data-export-and-restore`, `value-objects-money-and-units`, `i18n-rtl-l10n`,
  `testing-strategy`, `async-safety`.
- **Write these tests first** — `test/backup/csv_export_test.dart`:
  - `the fill-ups CSV header is exactly: date, vehicle, odometer, odometer_unit, quantity,
    quantity_unit, price_per_unit, total_cost, currency, is_full_tank, chain_broken, grade,
    distance_since_last, consumption, consumption_unit, station, notes`.
  - `the all-costs CSV header is exactly: date, vehicle, type, category, label, vendor,
    odometer, odometer_unit, amount, currency, notes` — with `type` ∈ `fuel | service | expense`.
  - `all-costs unions fuel, services and expenses, sorted by date, one row per cost event` —
    and asserts fuel and services appear **only** in their own rows, never also as expenses, or
    the file double-counts.
  - `numbers are in the user's own units, with the derived columns computed` — a miles+gallons
    user gets miles and MPG US, not a converted metre value.
  - `the file is UTF-8 with a BOM, CRLF line endings, comma separator and dot decimal` — assert
    the BOM bytes; Excel needs it to detect UTF-8 and half this audience opens CSVs in Excel.
  - `dates are ISO and digits are ASCII, whatever the numerals setting`.
  - `RFC 4180 quoting: a field containing a comma, a quote, a CR or an LF is quoted and embedded
    quotes are doubled` — the hostile cell is `a,b"c\nd`.
  - `formula injection is neutralised` — cells beginning `=`, `+`, `-`, `@`, tab or CR, e.g.
    `=cmd()`, survive a write→read round trip through a real parser as text.
  - `an RTL note round-trips through a real parser unchanged and carries no bidi controls`.
  - `per-vehicle and all-vehicles variants both produce correct filenames` —
    `odova-fillups-golf-2026-09-02.csv`, `odova-costs-all-2026-09-02.csv`.
  - `12,000 rows stream to a temp file without assembling in memory` — assert peak allocation,
    because a `StringBuffer` here is an OOM on the cheapest device we support.
  - `there is no CSV import path` — assert `BackupReader` refuses a CSV as `NotOdova`. An export
    artifact must never be a restore source.
- **Then build** — `lib/backup/csv/csv_writer.dart` — the RFC 4180 + injection-escape primitive;
  `lib/backup/csv/fillups_csv.dart` and `lib/backup/csv/costs_csv.dart` — the two row
  projections, streaming through an `IOSink` and published by rename. The Export screen carries
  one line telling German-locale Excel users to pick comma in the import dialog.
- **Verify**
  ```bash
  flutter test test/backup/csv_export_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Both headers match §6 §8.1 exactly.
  - [ ] BOM, CRLF, RFC 4180 quoting and formula-injection escaping all tested against a real parser.
  - [ ] Rows stream; nothing is assembled in a `String`.
  - [ ] CSV is refused as a restore source.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 15.9 — Wire the service-history PDF row and the vehicle picker sheet

- **Goal** — The Export screen's third "also export" row produces the same document
  `report.service` produces, through the same renderer, with the same footer.
- **Spec** — §6 §8.2 *Service history PDF*; §12 → `report.service` (contents, the identity
  toggle, page size); §13 → `settings.backup` export flow.
- **Skills** — `data-export-and-restore`, `service-boundary-and-native`, `i18n-rtl-l10n`,
  `calm-components`, `testing-strategy`.
- **Write these tests first** — `test/backup/service_history_pdf_test.dart`:
  - `the CSV and PDF rows each open a vehicle picker sheet when there is more than one vehicle`
    — and go straight through with one vehicle. The costs CSV picker additionally offers **All
    vehicles**; the fill-ups CSV and the PDF do not.
  - `the PDF is produced by the report.service renderer, not a second one` — assert the same
    entry point is called. No screen may reimplement a document another screen owns.
  - `plate and VIN are off by default`.
  - `the footer appears on every page and is not optional` — "Generated by Odova on 2 September
    2026 from records kept by the owner. Not verified by a third party." Assert it on page 1 and
    on the last page of a multi-page document.
  - `page size follows the resolved region: US Letter for US/CA/MX/PH, A4 elsewhere`.
  - `the document mirrors for RTL and uses the user's own numerals and calendar` — unlike the
    machine-readable exports.
  - `the Vazirmatn subset is embedded, not referenced` — it must render on a stranger's phone.
  - `the filename is odova-service-history-golf-2026-09-02.pdf with the transliteration
    fallback`.
  - `a record with cost_estimated prints its cost cell as — with the "cost not recorded"
    footnote`.
  - `the Export screen offers exactly four outputs` — backup JSON, fill-ups CSV, all-costs CSV,
    service-history PDF. The `.ics` is on `settings.notifications` and must not appear here.
- **Then build** — `lib/features/settings/ui/export_vehicle_picker_sheet.dart` over `CalmSheet`,
  and the wiring in `BackupScreen` from each row to `BackupExportService`, `FillupsCsvExport`,
  `CostsCsvExport` and the existing service-report renderer.
- **Verify**
  ```bash
  flutter test test/backup/service_history_pdf_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] All four export rows work end to end through the share sheet.
  - [ ] The PDF comes from `report.service`'s renderer; there is no second renderer.
  - [ ] The unremovable footer is on every page and plate/VIN are off by default.
- **Estimate** — `0.5 h (CC) · ~half a week (human)`

> **Blocking dependency.** §6 §8.2 defers the document's contents to §12 → `report.service`,
> and **EPIC-12 owns that screen and its PDF renderer**. EPIC-12 depends on EPIC-11, which is
> not in this epic's dependency set, so EPIC-12 may well land after this one. If it has not
> landed, this task has no renderer to call: do not build a second one — hide the PDF row,
> ship the two CSV rows, and take this task after EPIC-12. Note the deferral in the progress
> file, because the `settings.backup` reference image shows all three ALSO EXPORT rows and a
> screen shipped with two of them will not match it.

---

## Definition of done

- [ ] A backup exports, and importing it onto an empty device reproduces the phone it came from — vehicles, records, reminders and preferences, language and direction included.
- [ ] Two exports of unchanged data are byte-identical below `settings`.
- [ ] Import replaces, behind a mandatory preview, with nothing written before Confirm.
- [ ] The write is atomic: a kill at any stage leaves either the old data or the new data.
- [ ] Every destructive operation writes its safety copy first — import, delete-all, migration. No exceptions.
- [ ] Every message in §6 §5.2 is on screen in all six locales, with no technical term.
- [ ] The corpus is checked in, wired into CI, and green.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

---

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-15.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.

Record in particular: which corpus files were added and why, whether the migration-time safety
copy in Task 15.3 is genuinely written by the retained old-schema reader, and any §6 message
that could not be translated without a native reader — Sorani plural quality is named in §18 as
the single largest risk to the launch, and the import messages are where it bites hardest.
