# EPIC-15 — Backup, export and import

**Baseline at branch point** — `main` at `f16c158` (EPIC-14 merged), analyzer
clean, 4,347 tests green, every gate green.

**Carried in from EPIC-14**, both recorded there and repeated because this epic
is where one of them lands:

- **`kSupportedFormatVersion` now lives in `lib/backup/backup_format.dart`.**
  EPIC-14 declared it in `lib/app/app_version.dart` because this epic had not
  landed, with a doc saying task 15.1 takes ownership. It has.
- **The Numerals control is stored and read by one card** — 82 call sites pass
  `CalmNumerals.auto` literally. Recorded for EPIC-17; it matters here only as
  the reason §6's "every digit ASCII" rule needs its own test rather than
  relying on the app's numeral setting being off.

## Task 15.1 — the envelope, the hash and the value projections

Built `backup_format.dart`, `content_hash.dart` and
`mapping/backup_values.dart` — under **`lib/features/backup/domain/`**, not the
`lib/backup/` the epic's plan names.

`structure_test.dart` allows seven top-level directories and this would have
been an eighth. Two homes were considered and rejected: `lib/data/backup/`
fights two gates the moment the writer unwraps a value —
`no_conversion_on_write_test` reserves `.metres` and `.amountMinor` for
`lib/data/db/mappers/`, and `no_drift_in_signatures_test` reads every public
signature there — which is the same collision EPIC-13 hit with
`costs_source.dart`. And widening the seven-directory list is a decision the
gate exists to make visible, for a feature that already has two screens
(`settings.backup`, `settings.import`) and therefore a feature folder. This is
the third time an epic's plan has named a directory the repo's own rule
refuses; the pattern is recorded here rather than argued again next time.

**`crypto` added as a direct dependency**, with the audit run. It was already
present transitively through `drift_dev`; declaring it makes the use owned
rather than borrowed, which is what `depend_on_referenced_packages` is for.
Pure Dart, no plugin, no platform channel — `tools/audit_deps.sh` walks the
resolved tree and finds no socket.

**The hash trick is the placeholder's LENGTH.** Write `sha256:` and 64 zeros,
hash the document that contains them, overwrite in place. No byte offset
moves, so the digest describes exactly the file on disk rather than a shorter
one that never existed — and the verifier puts the placeholder back to check,
because that is the only way to hash the same bytes the writer hashed. An
assertion pins the two lengths together so the invariant cannot be broken
silently.

It is an INTEGRITY check and not a signature: §2 has no server and no key, so
anybody can recompute it after editing the file. What it catches is a
truncated download or a half-written file, which is the failure that actually
happens to a backup.

Timestamps drop Dart's `.000` sub-second suffix — three characters of nothing
in every row of a 12,000-record file, and a difference from §6 §2.5's worked
example that the byte-comparison test would report as a format mismatch.

**The vehicle projection is pinned against `SPEC.md` itself**, not a fixture.
The test parses §6 §2.5's worked example out of the document and asserts the
writer reproduces it — key ORDER included, because §6 §2.6 makes a streaming
reader's one-pass resolution depend on it and a set comparison would pass on a
document no reader could stream. A copied fixture would be a second document to
keep in step, which is how a spec and its code stop matching without either
changing.

Two mutations checked, both on rules that would be silent: materialising an
inherited unit instead of writing null (which pins every vehicle in the file to
today's settings, so a user who exports, changes their default currency and
imports gets a garage frozen at the old one), and writing the old `archived`
boolean instead of the three-valued status (which imports every sold car as
merely archived and starts reminding its former owner about it).

Then the nine projections — `mapping/vehicle_backup.dart`,
`mapping/record_backup.dart`, `mapping/settings_backup.dart` — each pinned by a
test that **parses `SPEC.md` §6 §2.5 at run time** rather than copying it. A
copy would be a second description of the format to keep in step, and two
descriptions of a backup format is the one thing it cannot afford.

The assertion is key ORDER, not membership: §6 §2.6 makes a streaming reader's
one-pass reference resolution depend on parents arriving before children, so a
set comparison would pass on a document no reader could stream.

Three rules here fail silently when broken, so each was mutation-checked and
each mutation was seen to go red: `wallClock` writing minutes instead of
`"09:00"` (2 red), a service line's FLAT `amount_minor`/`currency` nested like
every other money field (1 red), and a reminder carrying a stored
`next_due_date` (16 red). The flat shape differs from the rest of the format
and is followed rather than normalised — a reader written against the spec
would refuse a document that "improved" on it.

Two omissions that look like bugs and are not. `odometerReadingBackupJson`
writes no `source_id`: a reading a fill-up emitted is re-derived on import, so
exporting the link would duplicate every fill's reading on the next round trip,
the record count growing on each export/import cycle. `settingsBackupJson`
writes neither `last_backup_reminder_at` (device-local nagging state) nor
`schema_version` (the DATABASE's number; the file's own is `format_version` in
the envelope, and one file carrying both invites a reader to check the wrong
one).

Finally `backup_writer.dart` and a new `lib/core/domain/models/store_snapshot.dart`.

`StoreSnapshot` is in `core` because a backup is the only operation in the app
that reads the **whole** store — every other read is per-vehicle and streamed,
and composing nine of those over N vehicles is both slower and wrong at the
edges: a vehicle deleted between the fourth stream and the fifth leaves orphan
children in the file.

The writer streams record by record (high-water mark is one record, not a
12,000-record String), sorts every array by id **inside the writer** so a
caller cannot lose byte-determinism, and feeds its sha256 the same bytes it
feeds the sink. Four mutations, all seen red: no bidi stripping (1), arrays
unsorted (1), hash offset moved one byte (11), `exported_at_local` losing its
sign (1).

Bidi controls are stripped once at the encode boundary rather than in each
projection — thirty string fields across nine projections is thirty chances to
forget, and the forgotten one would be the free-text note. Digits are
deliberately **not** folded: a note typed in Persian numerals is the user's
text, and §6's ASCII-digit rule is about the numbers the writer emits, which
are JSON integers.

**Deferred from 15.1, deliberately:**

- **"the §6 §2.5 worked example round-trips"** — the loop needs a reader to
  rebuild a `StoreSnapshot` from the parsed document, and the reader is task
  15.2. `spec_key_order_test` already pins every array's keys against that same
  block, so what is outstanding is the loop, not the agreement.
- **Nothing reads the database into a `StoreSnapshot` yet.** The writer's only
  callers are tests. Task 15.5 owns export delivery and is where the store
  reader belongs; it is named here because "a port with no production caller"
  is the exact defect EPIC-13 and EPIC-14 each shipped once, and this one is
  not to be discovered by a user.

**A gate collision worth naming.** `no_currency_conversion_test` greps the
whole tree for the toman code and counted this task's own test assertion as the
violation — the second time a policy grep has fired on a test that asserts the
policy. The assertion was rewritten to pin the SET of currency codes in the
file instead, which is the stronger check anyway: it catches any wrong code
rather than the one we thought of.

## Task 15.2 — the reader, the ladder, and the messages

`BackupReader.read(File)` walks §6 §5.1's thirteen rungs in order and returns an
`ImportPlan` or a typed `ImportFailure`, having written nothing. Twelve failure
variants and thirteen warning variants, each carrying typed parameters and no
user-facing string.

Every refusal path asserts the picked file is **byte-unchanged**. That is the
assertion behind §5.2's "Nothing on your phone has changed", and it is only true
because the reader writes nothing to reach its verdict.

Six mutations, each seen red: truncated collapsed into not-valid (1),
last-duplicate-wins (1), an unmatched correction applied anyway (1), orphans
dropped rather than adopted (2), the blast radius using `>=` (1), and watt-hours
read back as millilitres (1). Three more over the messages: a German string
carrying "JSON" (1), Arabic's dual filled with a copy of the plural (1), and a
failure falling through to an empty string (1).

**A defect in task 15.1, found by writing the reader.** `fillUpBackupJson` wrote
`fill.quantity?.amount` into `quantity_ml` whatever the fuel was, because
`amount` is the canonical integer for all three forms — so an EV's 41,500
watt-hours would round-trip as 41.5 litres of diesel with nothing to say so.
§6 §2.5 wants exactly one of `quantity_ml`, `quantity_g` and `energy_wh`, named
for what it counts. Fixed, and pinned by a round trip over all three forms.

**Two ids in `SPEC.md` that no Odova build could ever write.** The §2.5 worked
example carried `odo_…J0L3…` and `trp_…H2L5…`; a ULID is Crockford base32, which
omits I, L, O and U so a human reading an id aloud cannot turn a 1 into an l.
`RecordId.tryParse` refuses them, so the round-trip test found the spec
describing a file the app would decline to import. Two characters changed in
`SPEC.md`, and `tools/check_spec_examples.py` now walks every id in every
example against the alphabet — both arms planted in
`tools/check_gates_selftest.sh`, so the new gate has been seen to fail.

**`active_vehicle_id` is not restored into the settings row.**
`test/app/active_vehicle_test.dart` asserts exactly one place in the app selects
a vehicle, because selecting one resets the tab stack. The file's value rides on
`ImportPlan.preferredActiveVehicleId` and **task 15.4 must apply it through
`setActiveVehicle`** — if it does not, an imported phone keeps whatever vehicle
was active before. The gate caught this and was right to.

**Skip reasons collapsed to six.** `missing_interval_distance_m` and
`missing_notice_distance_m` are the same sentence to a person. The six that
remain are the ones that change what a user would do: the date, the amount of
fuel, the amount of money, an unrecognised currency, an unmatched correction,
and everything else.

**Three existing gates caught real defects**, which is the argument for having
them. `font_coverage_test` found `←` in the three RTL messages — the mirrored
"Settings → Export" arrow, with no glyph in any bundled face — and a stray `Ʃ`
surviving in four Sorani strings. `plurals_test` refused ten new plural keys
missing from its render matrix. `pseudo_locales_test` refused a template that
had grown without a rebuild.

**Rung 13's threshold is a PROPORTION, and it bites on small files.** One
unreadable row in a three-record document is a third of it, so the import is
refused. That follows §5.1 literally and is defensible — a third of a history is
not a successful import — but it means a hand-made two-record file with one
defect cannot be imported at all. Recorded rather than softened; §18 can decide
whether a small-file floor is wanted.

**Deferred from 15.2:** `incremental_parser.dart` for files over 4 MB. The
reader decodes in one pass and the 6 MB case is pinned for time rather than for
peak memory, which is not something a unit test can measure honestly. §5.4's
real protection today is the 64 MB size cap, the depth cap and the string cap,
all three of which are tested. Named here so the next reader of §5.4 does not
assume it shipped.

**Sorani remains the largest translation risk in the app** (`CLAUDE.md` §9). The
forty-three import strings were written without a native speaker and need one
before release.

## Task 15.3 — the chain, the corpus, and a safety copy that can be restored

The chain is §6 §3.1's loop verbatim: pure `json → json`, in memory, before
anything touches the database. Purity is asserted **structurally** — the two
migration files import no `dart:io`, no drift and no Flutter — rather than with
a fake filesystem, because a file with no filesystem to reach cannot reach one
whatever a future author intends.

`kMigrations` is empty at v1 and declared anyway, and a test asserts every step
up to `kSupportedFormatVersion` exists. **Bumping that constant without writing
the migration is now a red test.**

`whichever_last` keeps both intervals and is counted; the other two retired
rules clear an interval that was already ignored. Clearing one of
`whichever_last`'s would delete a value the user entered, which §3.1 rule 1
forbids.

**The corpus is thirteen files with sidecars**, walked rather than enumerated,
and wired into CI as its own step (`the backup corpus imports`). All synthetic.
The trades file is 11,883 records over three vans and ten years, 4.5 MB.

**The pre-migration safety copy was not restorable, and now is.** EPIC-05 wrote
it as a raw table dump — every byte of the user's history in a shape nothing in
the app could read back. §6.4.4 calls that file the escape route. It passed
review twice because the file plainly exists and plainly has the data in it.

`lib/data/db/schema_readers/schema_v1_backup.dart` now projects v1's raw rows
into §6's document, and `safety_copy_imports_test` runs the whole loop — a real
v1 database, the numbered reader, the v1 projection, `BackupReader` — because
each half passing separately is exactly what let the gap exist.

**Every constant in that file is pinned to v1 and must never track a moving
one.** A v5 binary writing a v1 database stamps `format_version: 1`. This is the
first thing to check when schema v2 lands: the v2 reader needs its own
projection beside it, and `backupDocumentForVersion` falls back to the raw dump
for a version that has none — not importable, but still every byte, which is the
better of two bad outcomes.

**A mutation that needed a new test before it could be caught.** Collapsing the
three quantity columns into `quantity_ml` passed the whole suite until an
electric and a gas fill existed as fixtures. Coverage would have called that
line covered.

**Not done in 15.3:** the epic's "assert against a fake filesystem that records
zero opens" was replaced by the import check described above, which is stronger
and cannot be fooled by a migration that opens a file through a different API.

## Task 15.4 — the safety copies and the atomic-swap importer

`importStore` is §6 §4.1's pipeline: safety copy → stage beside → verify counts
→ close every handle → one rename. Nothing is destructive until the rename, so
every failure path leaves the live database byte-identical — which the test
asserts by **reading the bytes**, at each stage in turn.

That test found two real defects on its first run: a throw from any stage past
`staging` escaped the function instead of returning a typed failure (§14's crash
loop, in the one place a user cannot afford one), and a count mismatch left the
`.importing` file behind for the next attempt to trip over.

Four mutations, all seen red: publishing without the count check, the safety
copy taken after staging, staging left behind on failure, cancellation ignored.

**Both gates that fired were right, and both changed the design.**
`value_equality_completeness_test` refused a `File` inside `RestoreReport`'s
props — a live handle with identity equality in a value type. And
`active_vehicle_id is written in exactly one place` fired for the **second time
in this epic**: `settleImportedSettings` now returns the snapshot and the chosen
vehicle separately, so the importer applies it through `setActiveVehicle` and
the tab stack resets. After an import that reset is not optional, because the
stack holds routes for a car that may no longer exist.

Twice in one epic is a pattern worth naming: **anything that sets the active
vehicle outside `setActiveVehicle` will be refused**, and the right move is to
return the choice rather than to write it.

**Not done in 15.4, and each needs a caller that does not exist yet:**

- **`SafetyCopyStore` is the filenames, the instant parsing and the 30-day
  expiry — not a directory scanner.** Listing copies, applying the
  re-import suppression rule (`content_hash` + `record_counts` match), and
  *Undo last import* all need `settings.backup`, which is task 15.6. The
  suppression rule is the one to be careful with: it exists because importing
  the same file twice would replace the user's real data with the file's own
  contents, and the three months they were trying to get back are gone.
- **The delete-all and undo copies have no writer.** *Delete all data* is
  EPIC-14's screen and does not take a copy today; §4.4 says "no exceptions".
  Recorded as a defect to close in 15.6, not as a decision.
- **The `5,000 records under 8 s / 4 s` floor is not asserted.** The importer's
  tests use small stores; the corpus covers 11,883 records through the READER.
  The write side needs a bench and belongs with the real wiring.

**The importer takes a `StoreSnapshot`, not an `ImportPlan`**, because
`ImportPlan` is in the backup feature and `lib/data` importing a feature would
invert the layering. `lib/data/repositories/store_writer.dart` is the new
whole-store write path — one batch per table, parents before children,
corrections last because each names a reading.

## Task 15.5 — export delivery, filenames and the nudge predicate

The four naming rules from §6 §6, each with its reason in the test. The one
worth repeating: a name written only in Arabic script falls back to
`vehicle-<position>` rather than being transliterated, because a transliteration
invents a spelling nobody asked for and an empty slug collides with every other
export.

**Two changes outside this task's own files, both because the export found
them.**

`ShareService` gained `shareWrittenFile`. The existing member takes a
`Uint8List`, so every caller assembles the whole file in memory — which is
precisely what the streaming writer exists to avoid, and the peak arrives when
the user is rescuing their data. The report's two fakes now `fail()` on the new
member: a fake that quietly answers a call the real subject never makes is a
fake that lies about the port it implements.

**The export writes under `.writing` and renames.** The first version wrote to
the published name and deleted on failure, and the mutation check would not go
red for removing that delete — because there is no honest way to make a write
fail halfway in a unit test. That is the argument, not an excuse:
delete-on-failure leaves a half-written backup under the right name for as long
as the catch takes, and for ever if the delete also fails on the full disk that
caused the problem. Under the rename the published name is only created after
the last byte is flushed. **The guarantee is structural and is not covered by a
test that could go red**; it is recorded here rather than claimed.

`last_backup_at` is stamped on the hand-off, because the OS never says what the
user did with the file.

**Deferred from 15.5, and each needs a caller:**

- **Nothing calls `BackupExportService` yet.** `settings.backup` is task 15.6.
  Named because "a port with no production caller" is the defect EPIC-13 and
  EPIC-14 each shipped once.
- **`deleteLeftoverExports` is not wired into launch.** It belongs in
  `bootstrap`, and 15.6 is where the temp directory is chosen.
- **The nudge predicate has no scheduler.** EPIC-16 task 16.x places
  `backup.nudge` in the slot builder. The predicate and its ninety-day
  bookkeeping are done and tested.

## Task 15.6 — `settings.backup`, and the delete-all flow

The seven states are `resolveBackupChrome`'s — a pure function with eleven
cases, including the pair the epic's table does not resolve: an empty store AND
a failed migration. Both apply; emptiness disables the export, the failure
disables everything else.

**The screen lives in `lib/features/backup/`, not `lib/features/settings/`**,
although §13 files it under Settings. `structure_test` refuses one feature
importing another, and it is right: this is the backup feature with a Settings
row pointing at it, and the settings screen reaches it by route constant. The
first version put the chrome under `settings/` and the gate caught it.

**Three defects found by tests written first:**

1. **At 200% text scale in German the card overflowed by 485 pixels.** §13
   promises the button clears the fold at that scale, which it cannot do if the
   card above it has already overflowed. Both rows are `Wrap`s now — the text
   moves rather than shrinking, per `accessibility-as-code`.
2. **`register_test` flagged a correct German string.** `dein\w*` matches
   `deinstallieren`, the verb "to uninstall". That file's own comment says what
   happens to a gate that cries wolf, so the gate was fixed — narrowed with a
   lookahead and given a case asserting both arms.
3. **`check_component_hygiene` caught a hand-built `BoxDecoration`** for the
   "3 months ago" pill. `CalmBadge` is that pill, and it gained an optional
   `icon` for the ⚠ the reference draws. The icon-less form keeps its exact old
   subtree: the first attempt shifted the label a fraction of a pixel and broke
   a committed golden by 495px on a badge that had not changed.

`showConfirmDeleteDialog` gained optional `title`/`body` overrides rather than a
second dialog. Delete-all's subject is the word the user TYPES, and "Delete
DELETE and 3,006 entries?" is not a sentence — but the typing lock, the bidi
isolation and the action order are all wanted unchanged.

**The wipe safety copy is written BEFORE the dialog opens**, and a copy that
could not be written stops the flow. A cancelled dialog leaves the copy in
place, which the next tap reuses.

**Five distinct delete words across six locales** — Arabic and Persian share
`حذف`, correctly. Each asserted three ways, including that it folds to something
a user can type: a word that folded to empty would leave the lock permanently
shut, the same class of bug the dialog already guards for an empty vehicle name.

**Deferred from 15.6, and each needs a real caller:**

- **`BackupActions` has no production implementation.** `NoBackupActions` is
  named rather than throwing, so a tap does nothing instead of crashing — but
  nothing is wired: not the export service from 15.5, not the picker, not the
  importer from 15.4, not `deleteLeftoverExports` on launch. **This is the
  single largest open item in the epic**, and it is what task 15.7 has to close
  along with its own screen.
- **`backupInitialStateProvider` returns an empty store.** The real counts, the
  on-disk size, the safety-copy listing and `migrationFailed` all need reading.
- **The CSV and PDF rows call actions that do nothing.** Tasks 15.8 and 15.9.
- **Parity captures**, per the §6a velocity decision.

## Task 15.7 — `settings.import`

Three preview variants over a sealed type, plus the progress and result states.
Nothing writes to reach the preview — asserted with a spy that counts calls, so
it is a fact about a counter rather than a hope about a widget.

**The replacement sentence is asserted verbatim**, and the test says why: it is
one of the two most heavily reviewed strings in the app and it is the one a
future PR will try to soften.

The already-restored variant needs both halves to be honest. A matching
`content_hash` alone would tell somebody who restored yesterday and logged four
fill-ups today that nothing will change, while four entries are about to
disappear. `writesSinceLastImport` is the clause that makes it true.

`PlaceholderScreen` left the router with this task — EPIC-15 was the last screen
epic and `settings.import` was the last placeholder. All 28 screens are real.

## Wiring — closing 15.6's largest open item

`backup_wiring_test` reads the export action out of a **bare
`ProviderContainer`** and runs it against a real seeded database, asserting the
vehicle name that was actually stored appears in the JSON on disk. That is the
assertion EPIC-13's and EPIC-14's shipped port defects would have failed, and
`bootstrap_wires_ports_test` now also asserts `bootstrap()` installs the wired
actions rather than the no-op.

Three things moved because a rule pointed at a better shape:
`shareServiceProvider` from the report feature to `lib/app/share/`; the
last-backup stamp straight to `SettingsRepository` rather than through
`SettingsWriter` (whose only added behaviour is a reschedule no notification
needs); and `kSupportedFormatVersion` to one declaration in `lib/app`, gated by
a test that walks `lib/`.

**Still unwired, and named in the code:** the document picker's NATIVE halves.
The Dart port exists, the share channel has Kotlin and Swift behind it, this one
does not. Restore, Undo and Delete all data are no-ops with a comment pointing
at the gap. **This is platform work, not Dart work**, and it is the last thing
between `settings.import` and a user reaching it.

## Task 15.8 — the two CSV exports

Both headers are §6 §8.1's, field for field, asserted as literal lists — a
header derived from the writer agrees with the writer by construction and with
the spec by luck.

**Formula injection** is the escape RFC 4180 has no opinion about. A cell
beginning `=`, `+`, `-`, `@`, tab or CR is executed by Excel, Google Sheets and
LibreOffice. The cell is PREFIXED with an apostrophe rather than altered: the
original is recoverable character for character, and dropping the character
would silently edit what the user typed.

**`package:csv` was added as a DEV dependency** for the assertions. Round-tripping
through the code that wrote the file proves the two halves agree with each other
and nothing about whether either is right. `tools/audit_deps.sh` is clean.

Four mutations, each seen red: the formula guard removed (3), the BOM dropped
(2), LF instead of CRLF (6), a two-currency service picking one (1).

**Both row builders compute locals and then write a flat literal.**
`prefer_if_elements_to_conditional_expressions` wanted `if` elements, and a
column built that way disappears when its condition is false — shifting every
cell after it into the wrong header for that one row, which a CSV cannot notice.
`writeCsvFile` throws on a length mismatch for the same reason.

## Task 15.9 — the picker, and one renderer

The picker asks once and only when there is more than one answer. "All vehicles"
is the costs CSV's alone. The choice carries the vehicle's one-based position,
because the filename falls back to `vehicle-2` for a name that transliterates to
nothing.

`one_renderer_test` walks `lib/` and asserts exactly one file calls
`canvas.beginPage`, and that it is in `lib/core/report/` rather than the report
feature — which is what makes it callable from here at all.

**The PDF row is DEFERRED, and it is the epic's own blocking note one level in.**
§6 §8.2 defers the document to §12's `report.service`. The RENDERER exists; what
does not is `reportRepositoryProvider`, whose own doc says "there is no default
implementation yet — the whole-vehicle read spans five tables and belongs with
the other repositories". Building that read here would be a second query to keep
in step with EPIC-12's. **To close this: implement EPIC-12's whole-vehicle read
in `lib/data/repositories/`, then point both the report screen and this row at
it.** The row stays visible, so the screen still matches its reference image.

**Also deferred:** the CSV rows are built and tested but not yet reachable from
the screen — `WiredBackupActions` returns without doing anything for all three
"also export" rows. The picker, the projections and the file writer all exist;
what is missing is the three lines that join them, and they belong with the
picker's `BuildContext`, which an action object does not have.
