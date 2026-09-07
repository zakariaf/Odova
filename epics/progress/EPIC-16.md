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
