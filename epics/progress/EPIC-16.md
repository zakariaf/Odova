# EPIC-16 — Reminders and local notifications

## Before task 16.1 — a defect the epic walked into

Writing 16.1's one missing test found that **`syncDerivedReading` and
`eraseVehiclePermanently` write through `customStatement`, which drift does not
trace.** Drift is handed a raw string and cannot parse which tables it touched,
so it dispatches no update and every open `.watch()` keeps serving its cached
result. The row really is written — a fresh query finds it — and every live
subscriber sits on the old list.

**It is on the app's commonest path.** A fill-up's odometer is REQUIRED and its
reading is derived through the fan-out, and `vehicleReadingsProvider` is a
`StreamProvider` over exactly that query. The hard delete is worse in reach: one
untraced `DELETE FROM vehicles` cascades through six tables, so the vehicle was
gone from the database and still on screen with all of its history.

**Why 4,679 tests could not see it.** Every existing test writes and then reads
`.first`, which opens a NEW subscription and re-runs the query. Only a
subscriber that was already listening — which is what a screen is — can tell.
`derived_reading_stream_test.dart` subscribes first, and all four cases were
red before the fix.

It blocks this epic specifically: SPEC.md §4.2.1 triggers re-projection on
"new/edited/deleted odometer reading, fill-up, service record, trip with end
odometer" and reads through these streams. A stream that does not fire is a due
date that never recomputes — the exact failure EPIC-16 exists to prevent.

`tools/check_stream_notify.sh` gates it, with four planted arms in the gates
self-test and a step in the repo lane. The DELETE arm notifies **every** table
rather than the six this cascade names: the cascade is declared in the schema
and a future table hanging off `vehicles` inherits it silently, so a hand-kept
list would be right until the next migration and then quietly wrong.

## Tasks 16.1 and 16.2 — already built by EPIC-07

The epic's own "Where we are now" warns of this and it is the case. EPIC-07
shipped `lib/core/due/reading_series.dart`, `daily_distance.dart`,
`estimate_odometer.dart` and `project_due_date.dart`, and **every test case
these two tasks name is already a passing test** in `test/core/due/` — the
40.9 km/day slope-not-mean case, both 14-day/100-km thresholds, all three
confidence tiers, both clamp ends, the 180-day expiry from both sides, the
Passat worked example with its literal 2026-10-12, and the second-hand car
that reports `unknown` rather than `overdue`.

**So `lib/core/reminders/` was NOT created.** Building the epic's
`daily_distance.dart` there would be the second projection in one app, which is
the failure this epic's own preamble says it exists to avoid.

One row of §4.1.1's table was genuinely uncovered — a trip carrying only a
distance — and it is covered now. It could not live where the epic puts it:
the guarantee is not in `ReadingSeries` at all (a distance-only trip never
reaches it as a reading), so the test has to open a database, and
`structure_test` holds `test/core/` to the same no-Flutter rule as `lib/core/`.
It is in `test/data/repositories/` instead.

**Two corrections to the epic's text, for whoever reads it next:**

- Task 16.2 asks for `needsOdometer` on every distance axis of a vehicle whose
  reading is over **60** days old, "regardless of severity". SPEC.md §4.1.3
  attaches "regardless of severity" to the **180**-day expiry, not to the
  60-day staleness threshold, and EPIC-07 built it that way:
  `expired || (stale && accusing)`. A 61-day-old reading on a `due_soon` item
  still shows normally. The spec wins; the epic's sentence is the one that is
  wrong.
- Task 16.4 says to add `flutter_local_notifications` to "the dependency
  audit's allowlist". `tools/audit_deps.py` says in a comment that there is
  **deliberately no allowlist** — "an exception to the ban is a decision that
  has to be argued in a comment next to the BANNED entry it contradicts". The
  packages are not banned, so nothing needs adding, and adding the hatch would
  be building the thing that file refuses.
- The epic also names `DueConfidence`; the type is `RateConfidence` and it
  already exists. Not renamed.

## Task 16.3 — the payload, and one type instead of two

EPIC-08 had already built the routing half: all six kinds, `locationFor`, the
back-stack synthesis, the vehicle-before-route ordering and both "the thing is
gone" rows. What did not exist anywhere in `lib/` was the **codec** — nothing
encoded or decoded a payload, so the format the OS would hold for four months
was unwritten.

**One type, not two.** The task specifies a sealed `NotificationPayload` with six
subtypes. `DeepLinkRequest` already carries exactly §4.4.2's three fields, and
the six kinds differ only in whether `reminderId` is present — which
`DeepLinkKind.carriesReminder` already says. Six classes holding identical
fields would be a second name for one thing that the router maps straight back,
and the validation the hierarchy existed to enforce is enforced at the boundary
instead, which is the only place an invalid payload can enter.

**`DeepLinkKind` and `DeepLinkRequest` moved to `lib/core/notifications/`.** The
codec cannot live in `lib/app/` because the SCHEDULER writes payloads and would
then import the router to build a string; it cannot import from `lib/app/`
either. The types moved down, `deep_link.dart` re-exports them so every existing
caller is untouched, and `core_is_pure_test` gained the subject with its reason.

**Refusal, never a default,** in all four directions: an unknown kind (the
app-update case), a `reminder.due` with no `reminderId`, one of the other four
kinds carrying one, and a missing or empty id. `reminderId` is OMITTED rather
than nulled on the kinds that do not name one, because §4.4.2 says "absent" and
a null is a value a future reader has to make a decision about.

**A mutation check found a hole in my own tests.** Accepting an empty
`vehicleId` passed all twelve. The guard was there and untested, which is the
same as not being there; `""` is what a serialiser writes for a null id.
Thirteen now, and the mutation is red.

## Task 16.4 — the port, and the dependency that nearly failed the offline gate

**`flutter_local_notifications` 18, not 22, and the reason is SPEC.md §2.**
`timezone` added an `http` dependency in 0.10.0 — for its own tzdata-refresh
tool, which this app never runs — and every FLN from 19 upwards requires
timezone ≥ 0.10. So the current plugin puts a network client in the shipped
binary, and `tools/audit_deps.sh --require-graph` refused it by name:

```
BANNED  http  [TRANSITIVE]
        a network client — SPEC.md §2: the app ships with no networking code
```

18.0.1 accepts `timezone >=0.9.0 <0.11.0`, and 0.9.4 depends on `path` and
nothing else. The audit is clean on that pairing. **The cost is real:** the pin
holds the plugin back, and a security fix in 19+ would force the choice again.
Recorded in `pubspec.yaml` next to the constraint, with what would release it —
`timezone` moving `http` to a dev dependency, which is where it belongs.

There was no allowlist to add anything to, contrary to the task text.

**`lib/services/` does not exist and was not created.** The epic and the skill
both name it; `structure_test` allows seven top-level directories under `lib/`
and `services` is not one. EPIC-14 hit this first and put its ports in
`lib/app/notifications/`, which is where the gateway, the adapter and the fake
now sit beside `app/share/`, `app/pdf/` and `app/file_picker.dart`.

**The skill's manifest gate contradicts the spec, so Odova has its own.**
`check-manifest-permissions.sh` REQUIRES `SCHEDULE_EXACT_ALARM`; SPEC.md §4.6.3
says "do not request exact-alarm privileges" in as many words. CLAUDE.md §3
settles it — the skill is a general default, the spec is the product's
decision — so `tools/check_notification_manifest.sh` forbids **both**
exact-alarm permissions and requires the boot re-arm, with seven planted arms
in the gates self-test. Its `forbid` strips comments first, so the paragraph in
the manifest explaining why the permissions are absent does not trip the gate
that keeps them absent. It also treats a missing manifest as a failure rather
than a skip; the skill's version exits 0, which turns a typo'd path into a
passing gate.

**`PendingNotification` carries an id and nothing else,** and that is the
contract test worth reading. Neither platform returns a fire time from its
pending list, so a `when` field would be one the live adapter could only fill by
inventing a value — and code written against it passes every test and cannot be
implemented on a device. §6.1 states the same division from the other side: the
OS is the truth for "is it pending", the table for "why".

The fake ships in `lib/` rather than `test/support/` because the contract suite
IS the definition of the port, and a fake beside the port is one somebody
maintains when the port changes.

## Mid-epic — the iOS app had not compiled since EPIC-12

Found by running the app on a simulator, not by a test. `ios/Runner/AppDelegate.swift`
read `engineBridge.binaryMessenger`; the `FlutterImplicitEngineBridge` protocol
in Flutter 3.44.6 exposes exactly two properties, `pluginRegistry` and
`applicationRegistrar`, and the messenger hangs off the registrar. Three Swift
compiler errors, so **no iOS build has succeeded since the share channel landed
in EPIC-12** — three merged epics ago.

**Nothing could have caught it.** `.github/workflows/ci.yml` had one compile
lane and it was `flutter build apk --debug`. The Dart side is fully covered —
`flutter analyze` and 4,700 tests — and none of that touches a line of Swift.
Every PR since EPIC-12 was green.

Fixed, and CI gained an `ios build` job so the next one is caught at the PR that
causes it. It does **not** run on every PR: a cold iOS build is 20–30 minutes
against the Android lane's two, so it is conditioned on the iOS host sources,
the podfile or the dependency set having moved — `pubspec.yaml` is in that list
because adding a plugin regenerates `GeneratedPluginRegistrant` and changes what
the Swift links against, which is exactly how this break arrived. When there is
no base commit to diff against it runs anyway: a gate that cannot tell whether
it is needed and therefore skips is a gate that is off.

`macos-15` is free here because the repo is public. On a private repo it bills
at ten times the Linux rate and the trade would be worth re-reading.

## Task 16.5 — the cap, and two mutations that survived

The headline assertion runs: five vehicles, twelve reminders each, all four
stages — 240 candidates — and the test walks **every** rolling seven-day window
across the whole 120-day horizon rather than sampling. Never more than two in
any of them, never more than one on a calendar day, never more than the budget.

**§4.3's three steps are ordered and the order is the design.** Coalesce, then
prioritise, then defer. My first implementation prioritised first, and three of
my own tests were written to match it — both were wrong. Five items due on one
Tuesday must spend ONE slot; prioritising first spends five and throws three
away, which is how a household with two cars goes quiet.

**`compute` returns `PlannedNotification`, not `ScheduledNotification`.** The
remaining step — title, body, deterministic id — needs the locale, and this is
the one function that can prove §4.3. Pulling six languages of ICU into it to
satisfy the task's signature would make the hardest rule in the epic depend on a
string lookup. The render step is separate and thin.

### Two mutations survived, and both are findings

**Deleting the one-a-day guard leaves every test green.** `taken` is keyed by
date, so a second group landing on an occupied day OVERWRITES the first rather
than joining it — the rule is structural and the failure mode without the guard
is a notification that vanishes silently, which no assertion about the output
can see. The guard stays, with that written above it.

**Deleting §4.3 step 4's reserved slots also leaves every test green, because
the reserve is unreachable.** The queue is sorted by stage rank before anything
is placed, so every overdue and every nudge has taken its slot before the first
`early` is considered — there is no urgent item left to starve. Step 4 is the
fix for a scheduler that places in DATE order, and §4.2.1's "recompute
everything, always" means this one never does. Its only effect today is to leave
up to two slots of the next four weeks unused, which makes the app quieter and
never louder.

It is KEPT rather than deleted — `SPEC.md` wins until a deliberate PR changes it
— with the reason written in the file, and the assumption that makes it inert is
now pinned by its own test, so a change to date-ordered placement goes red.
**Raise as a §18 question: is step 4 wanted at all under §4.2.1's full-rebuild
model?**

### Two defects this task found in existing code

**`ValueEquality` compares props element-by-element with `==`, so a nested
collection makes every instance unequal to every other** — including an
identical one. `PlannedNotification` held a `List` and `SchedulePreferences` a
`Set`; both are spread now, the set sorted first because a `Set`'s iteration
order is not part of its value. Caught by "the same inputs produce the same
list": the scheduler was deterministic and its own output type could not say so.

**`value_equality_completeness_test`'s parser then reported a false positive.**
It read a props entry as `^\w+$` after stripping `...`, so it recognised
`...lines` and not `...(weekend.toList()..sort())` — and reported
`SchedulePreferences` as omitting a field it does not omit. A gate that cries
wolf is a gate somebody deletes, so the parser now reads the first identifier
inside a spread, with both arms tested directly.

## Task 16.6 — deterministic ids and the hysteresis

**The id folds in the resolved fire instant and the body, not just the key.**
`getPending()` returns ids and nothing else, so an id derived from the key alone
is unchanged when the delivery hour moves 09:00 → 14:00 on the same date — and
the reconcile's cancel loop and its schedule loop would BOTH skip it, leaving it
to fire at the old time forever. This is the classic bug in this design and it
is invisible to a suite that only checks the set of keys. Two mutations pin it.

**FNV-1a written out rather than `Object.hash`.** Dart seeds `Object.hash` per
isolate in some versions, which would give two devices — and two launches of the
same app — different ids for the same notification. The prime is written as
shifts so the multiply cannot overflow into arbitrary-precision integers on the
VM and behave differently from the web's doubles.

**The hysteresis is an ABSOLUTE difference.** The obvious `to - from >= 7`
silently never reschedules anything that moved EARLIER, and earlier is the
direction that matters: it is the one where not rescheduling means a late
notification and a missed service. Mutation-checked.

**An unreadable stored time reschedules rather than being skipped.** Failing
toward doing the work: a row whose time cannot be parsed is a row we know
nothing about, and leaving it pending is how a notification fires carrying a
body from four months ago.

The probe wraps inside 31 bits rather than growing past them — running off the
top is where an off-by-one becomes a platform exception on one user's phone and
nowhere in the suite — and is bounded by the size of the taken set so a pure
function on the cold-launch path cannot spin.

Seven mutations, all caught, in one `tools/mutate.sh` pass.

## Task 16.6 — the reconcile diff

Three sources of truth meet in `reconcile()` and §6.1 says they are not
interchangeable: `desired` is what the scheduler recomputed from the database,
`pendingIds` is what the OS says it holds — the truth for WHETHER — and
`scheduled_notifications` is the truth for WHY. Without the third there is no
telling a notification the user dismissed from one iOS silently discarded for
cap, and only the second is a bug worth chasing.

Four behaviours are worth naming:

- **A row marked pending that the OS is not holding gets rescheduled.** That is
  the repair path for an iOS cap discard and the only way the app ever learns
  one happened.
- **A fired stage is never rescheduled** (§4.2.2 rule 4). Re-delivering history
  is the most confusing thing this app could do: the user marked the oil change
  done and is told again that it is due.
- **An id the OS holds that no row explains is cancelled.** A leftover from a
  previous install fires carrying a payload nothing can route.
- **`dropped` is not `cancelled`.** The distinction is the entire reason the
  table exists.

**A mutation removing the sorts survived the determinism test**, and the reason
is a lesson about that kind of test: two runs over the same input have the same
INSERTION order, so a stability check cannot see an unsorted result. What it
hides is a diff whose call order depends on how the caller built its list — two
devices with identical data issuing cancels in different orders. Now covered by
its own ordering test, and the mutation is red.

**The harness gained a two-field form.** Several mutations reported "the `from`
text was not found" rather than passing, which is the behaviour that matters:
the commonest mutation of all is a guard DELETED, and expressing it needed an
empty replacement that ` :: ` could not carry. Multi-line `from` is deliberately
still unsupported — it invites near-miss whitespace that silently fails to
apply, which is the failure the harness exists to refuse.

## Task 16.6 — `scheduled_notifications`, and five things the schema bump broke

The table is **deliberately not an entity**: no ULID, no `created_at`, no soft
delete. It is device bookkeeping, not history — it does not go in the backup
(§6 §7), does not survive an import, and §6.2 rebuilds it from scratch after
one. Giving it the entity shape would invite the next person writing an export
projection to include it, putting one phone's OS notification ids into a file
restored onto another, where cancelling them cancels whatever holds those ids
now.

`vehicle_id` and `reminder_id` carry **no foreign key on purpose**. The row is a
record of what the OS WAS TOLD and has to outlive the thing it names by exactly
long enough to cancel it; a cascade would delete the row holding the id that
still needs cancelling. §6.2 cancels a vehicle's keys explicitly, in code.

**The bump to v2 broke five things, and four of them were gates doing their
job.**

1. **Four migration-guard tests went green by not running.** Their fake
   databases claimed `schemaVersion => 2` to force an upgrade; once the real
   version WAS 2 no upgrade ran, and every guard reported `OpenedCleanly`. Four
   tests about data loss passed while testing nothing. The file's own comment
   had predicted this — "a bump would make this test the thing that breaks every
   time the ladder grows" — and a literal was written anyway. Now
   `kLatestSchemaVersion + 1`, along with every other version-pinned literal in
   that file.
2. **`withLength` emits no SQL.** `schema_reality_test` refuses it, correctly: it
   is a Dart-side validator, so a row written by a raw statement — which the
   fan-out and the migration both use — passes it unchecked. Replaced with
   `CHECK (length(fire_at_local) = 16)`.
3. **The audit-columns and `*_id`-REFERENCES gates** both fired. Exempted with
   the argument written next to the exemption, per the `*_id` gate's own rule
   that "every exception is named, with the reason, because 'it isn't a foreign
   key' is exactly what somebody says about a column that should have been one."
4. **`format_version` is not `schema_version`.** They had been the same number
   because there was one of each, and `safety_copy_imports_test` asserted the
   reader's schema version. Schema v2 projects the v1 DOCUMENT — the backup does
   not carry the new table — so the format version must stay 1. Bumping it would
   make every v2 build write files that older builds refuse as `TooNew`, over a
   table that is not in them. `SchemaReader` now declares
   `backupFormatVersion` per reader, as a literal.
5. The index list and its count, which is the gate working as designed.

**`make-migrations` could not run**: it reads `schemaVersion` from the source and
this app returns `kLatestSchemaVersion`, not a literal. The four commands from
`schema_version.dart`'s own ritual were run individually instead —
`schema dump`, `schema steps`, `schema generate --data-classes --companions`,
`build_runner build`. Worth correcting in that doc.

The migration test seeds a row in **every** table, migrates, and counts again.
An additive step that silently rebuilt `vehicles` and lost every row would pass
a shape check and `integrity_check` too.
