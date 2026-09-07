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

## Task 16.7 — the nudge

**Two channels, and they are not the same decision.** The in-app card is free —
no permission, no interruption — and §4.3.2 calls it "the whole feature", so it
is warranted by the drift alone. The notification costs one of two slots a week
and can be revoked by a reflex, so it needs the card ignored first, is capped
per-vehicle AND across all vehicles, and gives up after three.

The card is by construction the WEAKER condition, and a test pins that a
notification is never warranted where a card is not — the inverse would be a
notification about a vehicle the app is not showing a line for.

**The give-up rule silences the notification and never the card.** That is the
most important line in §4.3.3: the card costs the user nothing, and the app
degrades to hedged language rather than going quiet about a stale estimate it is
still using.

**Two mutations survived because my own fixtures were degenerate**, which is the
more useful half of this task:

- "takes the largest drift" had one vehicle under threshold, so it was testing
  that the other was *filtered out*, not that the larger was *chosen*. A
  mutation returning the first warranting vehicle passed. Both fixtures warrant
  now, and the loser is listed first so "took the first" gives the wrong answer
  rather than the right one by luck.
- The tie-break test's map was written `{'veh_b', 'veh_a'}` — reverse-sorted —
  so a mutation that reversed the iteration order produced sorted order by
  coincidence. Insertion order is now already sorted, and the assertion runs
  both ways round.

Both are the same lesson: a fixture that makes the assertion true for the wrong
reason is worse than no fixture, and only a mutation finds it.

## Task 16.8 — the pre-prompt decision

**Both answers count as a show.** The 30-day and three-times rules are about the
SHEET having appeared, not about what was said — counting only declines would
let somebody who taps "Turn on reminders" and then dismisses the OS dialog see
the sheet forever.

**A later OS-level revoke does not restart it.** `permission != neverAsked` ends
it in both directions: the user turned it off on purpose, and asking again is
the app arguing with them.

**`NotificationPermission` moved to `lib/core/notifications/`**, same shape and
same reason as `DeepLinkKind` in 16.3: the pure decision needs it and cannot
import `lib/app/`. The port re-exports it, so no existing caller changed.

**Not built here: the sheet itself.** It is a `CalmSheet`, not an addressable
screen, `design/reference/calm/` holds no artboard for it, and the epic says so
explicitly. The three ARB keys and the widget belong with the settings screen
work; what is built is the decision they ask.

Three mutations reported "the `from` text was not found" because I wrote the
two-field deletion form with a trailing ` ::`, which the harness reads as part
of the `from`. That is the harness being right and the input being wrong — and
it is now written in the harness's own usage note rather than rediscovered.

## Task 16.9 — the rebuild triggers

Rebuilding is cheap and §6.2's advice is "when in doubt, rebuild", so the
decisions worth testing are the ones that say **no**:

- **A DST transition rebuilds nothing.** The zone comparison is by NAME, never
  by offset — DST changes the offset and not the name, and wall-clock storage
  already handles it. Comparing offsets would cancel and re-add the entire queue
  twice a year for no change at all.
- **A forward clock jump is not suspicious.** Time passing is the normal case;
  `.abs()` on the difference would rebuild on every launch.
- **A backwards jump under an hour is NTP, not a person.** A drifting phone
  clock is corrected by seconds several times a day.
- **The OEM card does not appear if the app was never foregrounded since.**
  Otherwise it fires for a phone that was simply switched off, which is not a
  battery-optimisation problem and has no fix in any settings screen.
- **And it is asked once, ever.** A card that returns weekly about a setting the
  user declined to change is what gets an app uninstalled.

`RebuildTrigger.forcesFullRebuild` returns true for every member and is spelled
out rather than assumed: the enum is the list of things that DO, a DST
transition is deliberately not a member, and the day somebody adds one this
getter is where they have to answer for it.

**Deferred, and named so the next reader does not assume otherwise:** the
platform halves. The Android `WorkManager` job, the `BOOT_COMPLETED` receiver's
re-arm and the iOS `BGAppRefreshTask` are wiring rather than decisions — the
manifest already declares the receiver and the permission (task 16.4), and what
is missing is the Dart side that responds to them.

**Also outstanding and not testable here:** §6.4's 7-day background-delivery
soak on a real Xiaomi or Huawei device. An emulator run is not evidence and none
was taken.

Twelve mutations, twelve caught, first pass.

## Task 16.10 — the rollover rule

The worked example from §4.7.4 with its literal numbers — due at 115,000, done
at 118,400, next at **128,400** — plus its own assertion that the answer is
`isNot(125000000)`, so a failure names the permanent-debt bug rather than a
number.

**Rolling from the due value is the worst kind of wrong this app can be.** The
user stays "3,400 km behind" forever, every later reminder fires while the oil
is still fresh, and nothing on screen shows it: the due figure looks entirely
plausible. It is the kind of wrong that ships.

**`from_due` is about the CALENDAR anchor only.** The distance half always rolls
from actual, including on an anchored kind — a registration that somehow carries
a distance interval still wears at the rate the car is driven, and there is no
anchor for a distance to be tied to. Mutation-checked in both directions.

**A back-dated completion returns a date already in the past, deliberately.** A
"don't go backwards" clamp is the obvious defensive move and it invents a
service that never happened; §4.7.4 says reprojection may immediately mark the
item due again and the confirmation says so. Worth noting the function takes no
clock, so the clamp is not even expressible without changing the signature —
that is structural rather than lucky.

The anchored set is asserted as a SET over `ServiceKind.values`, so adding a
fourth kind and quietly anchoring it fails a test rather than passing one.

**Not built here:** `complete()`'s four-step transaction, the notification action
handler and the confirmation strip. Those are the data-layer and UI halves —
`dialog.snooze` already exists from EPIC-08 and this task wires to it. What is
built is the arithmetic they call, which is the part where being wrong is
silent.

Eleven mutations after one of my own turned out to be a no-op — I wrote
identical `from` and `to`, and the harness reported it as SURVIVED, which is the
correct reading of "the tests do not distinguish these two identical programs".

## The gap this epic nearly shipped with

Every task above was green, every gate passed, and **none of it ran in the app.**

- `notificationGatewayProvider` threw and `bootstrap()` never overrode it.
- `syncNotifications()` — the entrypoint the skill calls "the reliability
  backbone" — did not exist.
- Nothing consumed `PlannedNotification`, so the render step from plan to
  `ScheduledNotification` was missing.

This repo has documented that exact shape five times: `CalmDialog`'s two-action
constructor (EPIC-08), the odometer field's range (EPIC-11), `quantityFormsSet`
(EPIC-11), `CostRange.thisMonthSoFar` (EPIC-14), and `openMigratedDatabase`,
which EPIC-15's `/simplify` pass caught with the note that "a port with no
production caller" is the named problem. A sixth — and this time the whole
epic's worth of logic — is not a defensible thing to merge.

`syncNotifications()` is built and tested against the fake gateway, including
the assertion the whole design exists for: **zero calls on the second run over
unchanged input.** It is deliberately pure of the database — it takes what the
caller read and returns the rows the caller should write, so the transaction
belongs to the caller and the one function that proves §4.2.2 does not sit
behind a drift dependency.

It also refuses to lie about what happened: a row is written only for a schedule
call that RETURNED. A row claiming `pending` for a call that threw makes §6.1's
"truth for why" a record of what the app intended rather than of what it did.

## `/simplify` — four agents, and the deepest finding was about a gate I wrote

**The stream-notification fix was at the wrong altitude, and the gate compensated
for it.** `deletion.dart` already used `db.customUpdate(..., updates: {...})` —
drift's API where the write and the announcement are ONE CALL — with a comment
saying the same failure "was already fixed once, in the two places that were not
this one". I added a third and fourth `customStatement` write plus a follow-up
`notifyUpdates`, and then ~150 lines of shell gate and self-test arms to catch
people forgetting the follow-up.

Worse, that gate could not see the bug it was written for: it checked
file-scoped that `notifyUpdates` appears somewhere, and `odometer_fan_out.dart`
had TWO raw writes. Delete one announcement and the gate stays green and the
defect ships again, in the same file, in the same shape.

Both sites now use `customUpdate`, and the gate checks the rule with no reason
to break it — **no raw write at all in `lib/data/repositories/`**. It strips
comments first, because otherwise it fires on the paragraph explaining itself.

**A functional gap, not just duplication.** `delivery_slot.dart` declared its
own `const` copies of the delivery time and both quiet-hours bounds. Those three
already exist on `AppSettings` and are **user-editable** — the settings screen
writes them — so a user who moved quiet hours to 22:00 got 21:00 behaviour and
nothing anywhere would have gone red. `SchedulePreferences.from(AppSettings)` is
the one place they meet now, and `isQuietWindow` is one definition of the
predicate: the hand-rolled copy handled only a WRAPPING window, so a
13:00–14:00 window a user can set was quiet all day.

**`rollover.dart` was deleted entirely.** `resolveAnchor` and
`due_engine._distanceAxis` already implement §4.7.4, and my version was the
naive reading of §3 that `_anchorDate` documents CORRECTING — so the two
disagreed on exactly the class of item where being wrong is a legal deadline.
The worked example (128,400, not 125,000) now runs against the real one, in
`resolve_anchor_test.dart`.

**`wallClockOfMinutes` was a fourth copy**, and the one without the clamp —
that helper's own doc records three copies landing in one epic and one writing
`25:00` for a stored 1500. `FlnNotificationGateway` parses that string.

Also: `ClockSuspicion` renamed `BackwardsClockJump` (the name was already taken
in `core/due/` for a different question); two `const bool`s that were spec
sentences dressed as declarations deleted, with the cap claim asserted where it
is actually enforced; unused parameters removed from `nextDistanceThreshold` and
`applyPrePromptAnswer`; `kNudgeHorizonDays` now references `kHorizonDays`; the
`deep_link.dart` re-export removed because it preserved ZERO production callers
while widening the surface (the permission port's stays — it has three).

**And the self-test destroyed a committed file.** `write_scratch` was pointed at
`drift_schema_v2.json` by an arm that hardcoded v2 — a safe name until EPIC-16
made it real — and the cleanup then deleted it. `write_scratch` now refuses to
clobber a file it did not create, and the schema-freshness arms read the current
version rather than assuming 1.

Which is the same bug as the migration guard's, in the file whose entire job is
to prove that gates fail.

## `/code-review` — four agents, and the app could never have notified anyone

Two findings would have shipped an epic that does nothing, and both were proven
by execution rather than argued.

**Android would never have delivered a single notification.**
`ScheduledNotificationReceiver` was missing from the manifest.
flutter_local_notifications builds every scheduled alarm as an explicit
broadcast to that class and ships **no receivers of its own** — it is app-side
setup. So `zonedSchedule` succeeded, `pendingNotificationRequests` reported it
pending, AlarmManager fired at the right minute, and the broadcast landed on an
unregistered component. Nothing posted, ever, on every Android device. My
manifest gate passed the whole time because it required the BOOT receiver and
not this one. Both are declared now, plus `ActionBroadcastReceiver` for §4.7's
Done and Snooze, and the gate requires all three.

**The wall-clock CHECK did not exist on any upgraded device.** I introduced a
named constant for the GLOB *specifically so its quoting could not get tidied* —
and that is what broke it: `drift_dev` reads `customConstraints` off the SYNTAX
TREE and cannot fold an interpolation, so it silently dropped that one element
while keeping the four plain literals. A fresh install resolves constraints
through the Dart getter and had the check; an upgrade resolves them through the
generated versioned table and did not, leaving only `length = 16`, which a UTC
instant and any 16-character garbage both satisfy. Inlined, regenerated, and
now asserted against a MIGRATED database.

**A killed process during the upgrade bricked the app into permanent read-only.**
`CREATE INDEX` had no `IF NOT EXISTS`. Drift writes `PRAGMA user_version = 2`
*after* the transaction commits, so a kill in that window leaves table and index
on disk at v1 — and every later launch migrates again, throws "index already
exists", rolls back, and comes up degraded. The safety copy restores the same
file, so the loop never breaks: read-only forever, no path out but reinstall.

### The rest, in the order they would have hurt

- **`_keyFor` collided for grouped notifications.** No date in the key, so two
  groups on one vehicle with the same leading stage were one identity — a
  primary-key conflict, permanent cancel/reschedule churn on every rebuild, and
  one of the user's two reminders never in the OS at all.
- **`fired` and `dropped` rows did not survive a sync.** The final loop kept only
  `pending` rows, so the caller wrote back a list with the fired row missing and
  the next run scheduled the stage AGAIN — §4.2.2 rule 4 broken across a
  persistence round trip, which is the user marking the oil change done and being
  told again that it is due. It also erased the evidence §6.4's OEM card is
  computed from.
- **A delivery-time change never reached the OS.** `shouldReschedule` compared
  only the DATE, so 09:00 → 14:00 was a zero-day move and the reconcile skipped
  it — while `deterministicId` dutifully computed the new id and threw it away.
  That is precisely the bug its own doc claims to prevent, defeated one layer up.
- **Past-dated stages were scheduled in the past.** §4.2.2 rule 3 was implemented
  nowhere, while `withinHorizon`'s comment asserted it was handled elsewhere.
  Android delivers a past-dated alarm immediately; iOS discards it and the row
  claims `pending` forever, which then accuses an innocent OEM.
- **Stale slots ate the four-week reserve** — `daysUntil(day) <= 28` is true of
  every date in history, so the mechanism written to stop `early` starving urgent
  items let STALE items starve everything.
- **A failed schedule left the old row claiming `pending`** on an id that had
  just been cancelled.
- **Quiet hours were applied once and the 09:00 fallback never re-checked**, so a
  user with a 08:00–12:00 window was scheduled inside it.
- **`encodePayload` silently omitted a required `reminderId`**, producing a
  payload its own decoder rejects — a tap four months later landing on plain Home.

### And four gates that could not fail

- `check_notification_manifest`'s `require()` read comments while `forbid()`
  stripped them, so a manifest with **every declaration commented out** passed
  green. Two of its five assertions had never been seen to fail; they have arms
  now.
- `check_stream_notify` missed `INSERT OR REPLACE`, a verb wrapped in a heredoc,
  and `UPDATE "quoted"`. Its central claim was also false: **`updates:` is
  optional on `customUpdate`**, so "the API that cannot be forgotten" can be.
  The gate now checks that too.
- Both gates' comment-strippers were `sed` ranges, which delete to end-of-file
  when a comment opens and closes on one line. Both had false positives on
  correct code.

### Answered, not applied

- **Eight CHECKs are missing from four other tables in BOTH snapshots**, by the
  same syntax-tree mechanism. Not fixed here: those CHECKs exist on every real
  device, because a v1 install ran `createAll` off the Dart getter, so the
  divergence is between the snapshots and reality — and correcting it means a
  migration step that REBUILDS four tables holding the user's history. That
  needs its own zero-record-loss proof and its own PR. **Remedy: inline the four
  tables' `customConstraints` and add a v3 step with `TableMigration` for each.**
- **`absoluteTime` is inert on every device this app supports** (FLN's own
  dartdoc scopes it to iOS < 10; the plugin's floor is 12). Left in place with
  the misleading justification corrected — and the Berlin → Tehran promise it
  was defending genuinely depends on a reschedule at the zone change, which is
  task 16.9's trigger and is deferred.
- **Undo can resurrect a reading the user deleted** (`deletion.dart`, missing a
  `deleted_at IS NULL` guard on the second UPDATE). Pre-existing, not this
  branch, and a real data defect — filed rather than fixed mid-review.
