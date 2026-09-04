# EPIC-16 — Reminders and local notifications

| | |
|---|---|
| **Epic** | EPIC-16 — Reminders and local notifications |
| **Depends on** | EPIC-07, EPIC-08, EPIC-10 |
| **Estimate** | **13 h (CC) · ~3 months (human)** over 10 tasks |
| **Spec sections** | §4 Reminders and notifications · §14 Edge cases (Notifications; Time and dates) · §17 Definition of done (functional and offline gates) |
| **Screens** | none — this epic computes, schedules, delivers and routes. Every deep-link target is a screen an earlier epic already built, and this epic changes none of their pixels. |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

This is the hardest engineering problem in Odova, and it is one sentence long: schedule a
**date**-based OS notification for a **distance**-based threshold that the phone cannot
observe. The phone has no odometer. It has readings a person typed in and a guess about
what has happened since. So the entire engine is one move — estimate metres per day,
project the crossing date, schedule against that — wrapped in the machinery that keeps the
projection from going stale and keeps the app from going loud.

---

## Where we are now

EPIC-01 created the Flutter app; before it there was no `pubspec.yaml` and no `lib/`. By
the time this epic starts, the app runs, is themed with Calm, persists to Drift, and shows
real screens. Nothing about reminders reaches the operating system yet: the app has never
asked for notification permission, `flutter_local_notifications` is not in `pubspec.yaml`,
and `tz.local` is never set.

What this epic requires from its predecessors, stated as capability rather than as a file
list, because the epic that delivered each is less important than the fact that it is
there:

| From | What must exist before Task 16.1 |
|---|---|
| EPIC-07 | The due engine: `DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }` and `DueDriver` in `lib/theme/calm/calm_status.dart`, whichever-comes-first combination over the two axes, and the `notice` window `clamp(10% of interval, 200 km, 1000 km)` / `clamp(10% of interval in days, 7, 30)` that drives both the card colour and the `early` stage. `ServiceItem` with `interval_distance_m`, `interval_months`, `notice_distance_m`, `notice_days`, `is_tracked`, `is_active`, `notify`, `priority`, `rollover`, `repeats`, `snoozed_until`, `snooze_until_odometer_m`, `snooze_count`. `resolveAnchor(R, serviceRecords)`. |
| EPIC-08 | The app shell: the single `go_router` graph with `home`, `log.odometer`, `settings.backup` and the four tab roots addressable, the four page kinds of §7, `activeVehicleId` persisted and restored, and `locationFor` / `handleDeepLink` in `lib/app/routing/deep_link.dart`. It also built the three global dialogs of §7 in `lib/ui/dialogs/` — `dialog.discard`, `dialog.confirmDelete` and `dialog.snooze`. |
| EPIC-10 | `home` as a working tab root with due cards, the odometer strip and `CalmAllClear`. |
| Earlier still | Drift, the repository single write path, `clockProvider`, the typed `Result`/`Failure` spine, the six ARB files, and the Calm component library. |

**One overlap to check before you write a line.** EPIC-07 claims §4.1 *Projecting distance
into a date* and §4.2 *Re-projection* in its own spec-sections row. If it shipped
`estimateDailyDistance`, `estimateOdometer` or the reprojection trigger table, Tasks 16.1,
16.2 and 16.6 **extend and gate** that code rather than writing a second copy — read
`epics/progress/EPIC-07.md` first. Two projections in one app is the failure mode this whole
epic exists to avoid, and the tests below are worth keeping either way: they are the §4
fixtures, and a function that already exists should still pass them.

Deliberately still missing when this epic starts, and still missing when it ends:

- **The in-app staleness card.** §4.3.2 puts one line at the top of the vehicle screen —
  *"Odometer last updated 8 weeks ago. The estimates below are getting rough. [Update]"* —
  and calls it "the whole feature". That card is rendered by the epic that owns `home`.
  This epic ships the decision behind it (`stalenessNudgeProvider`) and the notification
  backstop; it does not paint on `home`, and it carries no parity gate for that reason.
- **`settings.notifications`.** The screen, its five states and its rows belong to the
  Settings epic. This epic ships the pre-prompt sheet the screen presents, and the
  scheduler the screen's writes rebuild.
- **The `.ics` calendar export.** SPEC §18 decision 13 has not been closed; it is not in
  this epic and not assumed by it.

## What we will have when this is done

- Add a car, log two readings a fortnight apart, and Home says *"Oil and filter — due
  around 12 October, at about 118,200 km"*. Delete the readings and the same card says
  *"Odova needs a reading to say when"* with an **Update odometer** action — no date, no
  figure, no invented number anywhere.
- With five cars and twelve reminders each — 240 stage-and-item combinations — the OS is
  holding **at most 46 pending notifications**, and no seven-day window in the next four
  months contains more than two of them. You can read that off
  `scheduled_notifications` and confirm it against the OS pending list.
- Tapping a reminder notification opens Home on the right car with its card highlighted,
  and Back exits to Home rather than out of the app. Tapping a nudge opens
  `log.odometer` prefilled. Tapping one for a car that was deleted last week opens plain
  Home and says nothing.
- **Done** on a notification writes a service record without launching the app, and the
  next time Odova opens there is an editable confirmation strip saying what it recorded.
- Deny notifications forever and every one of the above still works except delivery: the
  due list, the badge count and the away digest are unaffected, and the app never nags.
- `flutter test test/core/reminders/ test/core/notifications/ test/services/notifications/`
  is green, and the four gate scripts in
  `.claude/skills/local-notifications-scheduler/scripts/` pass.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Feature-first layering, the single write path, injected side effects, and the routing table to everything below. |
| `local-notifications-scheduler` | Governs this epic end to end: the one `syncNotifications()` reconcile, the gateway port, pure Clock-injected scheduling math, wall-clock storage, deterministic ids, the iOS budget, boot re-arm, and the four gate scripts. |
| `service-boundary-and-native` | The permission API, the OEM settings intent and the OS pending list are platform effects; each is a throws-until-overridden provider with a hand-written fake. |
| `value-objects-money-and-units` | `metres_per_day`, canonical metres, and the `Clock` discipline the whole projection depends on. |
| `error-handling-typed-results` | Scheduling fails for reasons the app must survive: permission revoked mid-write, an OS cap rejection, a full disk on the bookkeeping table. Each is a `Failure`, not a throw. |
| `calm-due-state-and-status` | This epic produces the `DueState`, `DueConfidence` and copy patterns that skill governs; the uncertainty rules bind notification bodies exactly as they bind a card. |
| `app-startup-and-bootstrap` | `tz.local`, the channel creation and the away-digest rebuild all sit in a fixed cold-launch order, before the first frame. |
| `persistence-drift` | `scheduled_notifications` is a real table with a real uniqueness constraint, and reprojection reads through scoped `.watch` streams. |
| `navigation-and-routing` | The six payload kinds map to `go_router` locations, with a synthesised `[home]` back stack and a serializable payload — never `state.extra`. |
| `state-management-riverpod` | The reprojection debounce, the nudge decision and the pre-prompt trigger are providers, not ambient singletons. |
| `i18n-rtl-l10n` | Bodies are baked into the OS at schedule time in one of six languages, three of them right-to-left, with ICU plurals and numeral normalisation. A locale change is a full rebuild. |
| `testing-strategy` | Everything above is testable off-device precisely because the math is pure and the gateway is faked. This skill owns the fakes-over-mocks rule the whole epic leans on. |

---

## Tasks

### Task 16.1 — The reading series and the daily-distance rate

- **Goal** — the app can say how far a given car travels per day, and how sure it is.
- **Spec** — §4.1.1 The reading series; §4.1.2 Rate estimation; §14 Edge cases → Odometer
  and data integrity.
- **Skills** — `local-notifications-scheduler` (purity, injected `Clock`),
  `value-objects-money-and-units`, `testing-strategy`.
- **Write these tests first** — `test/core/reminders/daily_distance_test.dart`:
  - `collapses two readings on the same date to the highest odometer` — two rows at
    2026-08-20 (116,000 and 116,050); the series holds one endpoint at 116,050.
  - `excludes a trip that carries only a distance` — a 340 km trip with no end odometer
    changes neither the series length nor the rate. Fails if trip distance is merged.
  - `includes a trip with an end odometer, a fill-up, a service record and a manual entry` —
    four sources, four endpoints, in date order.
  - `restarts the series at a correction instead of taking a negative slope` — 116,050 then
    12 after a cluster replacement; the rate is computed from the post-correction segment
    only and is positive. Fails if the slope goes negative or the pair is averaged.
  - `rejects a pair less than one day apart as a rate endpoint` — two readings 6 hours
    apart contribute no rate; with nothing else in history the result is `defaulted`.
  - `takes the two-endpoint slope, not the mean of segment rates` — three segments of
    1 day/80 km, 60 days/2,400 km and 30 days/1,200 km. Mean of rates ≈ 53.3 km/day; the
    slope is 40.9 km/day. Assert 40.9. This one test is the reason the function exists.
  - `requires 14 days and 100 km before it calls a rate measured` — 10 days / 400 km and
    20 days / 60 km both fall through to the next tier.
  - `falls back to all history when the 180-day window has fewer than two endpoints`
  - `returns assumed from expected_annual_m when history is too thin` — 15,000,000 m/year
    → 41,095 m/day, `DueConfidence.assumed`.
  - `returns defaulted at 12,000 km over 365 days when there is no expected_annual_m` —
    32,876 m/day, `DueConfidence.defaulted`.
  - `clamps 900 km/day down to 500 and 2 km/day up to 5, keeping the confidence it had`
  - `is pure: two calls with the same series and the same Clock return identical values`
- **Then build** — `lib/core/reminders/reading_series.dart` (`OdometerReading`,
  `ReadingSeries.normalise`) and `lib/core/reminders/daily_distance.dart`
  (`DailyDistance { int metresPerDay; DueConfidence confidence }`,
  `DailyDistance estimateDailyDistance(ReadingSeries series, {required DateTime now})`).
  No Flutter import, no `DateTime.now()`, no IO. `DueConfidence` is `{ measured, assumed,
  defaulted }` — `default` is reserved in Dart, which is why the third member is spelled
  out (`calm-due-state-and-status` rule 7).
- **Verify**
  ```bash
  flutter test test/core/reminders/daily_distance_test.dart
  bash .claude/skills/local-notifications-scheduler/scripts/check-scheduler-purity.sh
  ```
  Green tests, and the purity script finds no `DateTime.now()` and no plugin import under
  `lib/core/`.
- **Done when**
  - [ ] Every source in the §4.1.1 table contributes, or does not, exactly as the table says.
  - [ ] The slope-not-mean test passes with the literal 40.9 km/day.
  - [ ] All three confidence tiers are reachable and the clamp holds at both ends.
  - [ ] `lib/core/reminders/` imports nothing from `package:flutter`.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 16.2 — Project the rate into a date, and know when to stop

- **Goal** — every distance-driven reminder has a projected due date, and the app refuses
  to invent one when the reading is too old.
- **Spec** — §4.1.3 From a rate to a projected date; §4.1.4 Showing an estimate as an
  estimate; §14 Edge cases → "Odometer not updated for months" and "Distance axis due, but
  the odometer is stale".
- **Skills** — `local-notifications-scheduler`, `calm-due-state-and-status` (the
  uncertainty contract this feeds), `value-objects-money-and-units`.
- **Write these tests first** — `test/core/reminders/odometer_projection_test.dart`:
  - `reproduces the Passat worked example` — rate 41 km/day, last reading 2026-08-20 at
    116,050 km, today 2026-09-02, last done 2026-02-10 at 108,200 km, interval 10,000 km.
    Asserts `odo_now = 116,583`, `threshold = 118,200`, `remaining = 1,617 km`,
    `projected_due = 2026-10-12`. Every number is from §4.1.3; if one of them moves, this
    test says so.
  - `takes the earlier of the two axes` — the same fixture with a time axis at 2027-02-10
    resolves to the distance axis; flip the interval to 3 months and it resolves to time.
  - `stops projecting past 180 days and returns the last entered reading` — last reading 181
    days old; `estimateOdometer` returns the entered value with `asOf = last.date` and no
    projection. Fails if a `~` figure comes back. 180 is the **expiry**, per EPIC-07's F-7.2.
  - `reports needsOdometer on every distance axis of a vehicle whose reading is over 60 days
    old, regardless of severity` — 60 is the separate **staleness** threshold, and a reading
    between 61 and 180 days old is still projected, still marked `~`, and already
    `needsOdometer`. The two constants are different numbers for different things.
  - `never downgrades a time axis to needsOdometer` — a date-only insurance item on the
    same stale car still reports `dueSoon`.
  - `rounds a projected odometer to the nearest 100 km and to the nearest 50 mi`
  - `emits no date and no figure at DueConfidence.defaulted` — the projection returns a
    value whose date and odometer are both absent, so the caller cannot render a number
    even by accident.
  - `a purchase-anchored item with no history reports unknown, never overdue` — §14,
    second-hand car with a service book.
- **Then build** — `lib/core/reminders/odometer_projection.dart`:
  `OdometerEstimate { int metres; DateTime asOf; bool isProjected }`,
  `estimateOdometer(...)`, and `ProjectedDue { DateTime? date; int? metres; DueConfidence
  confidence; DueDriver driver }` with `projectDue(...)`. **Two** named constants live in
  this file, each with its SPEC reference in its dartdoc: the projection expiry at **180
  days** and the `needs_odometer` staleness threshold at **60 days** — see the note below.
- **Verify**
  ```bash
  flutter test test/core/reminders/
  bash .claude/skills/calm-due-state-and-status/scripts/check_status_encoding.sh
  ```
  All green. The status script must stay clean: this task returns a `DueState` and must not
  introduce a second `switch` over it.
- **Done when**
  - [ ] The worked example passes with the literal 2026-10-12.
  - [ ] Expiry (180 days) and staleness (60 days) are two named constants, each cited to
        `SPEC.md`, each used everywhere its own meaning applies.
  - [ ] `DueConfidence.defaulted` cannot produce a date or a figure through any code path.
  - [ ] A reading 61–180 days old is proven to be both projected and `needsOdometer`.
- **Estimate** — 1 h (CC) · ~1 week (human)

> **Settled — two constants, not one contradiction.** EPIC-07's finding **F-7.2** corrects
> §14 and closes this: §4.1.3's **180 days** is the *projection expiry* — past it
> `estimateOdometer` stops projecting and returns the last entered reading with no `~` — and
> §14's **60 days** is the separate *`needs_odometer` staleness threshold*, which flips a
> distance axis to `needsOdometer` while the projection is still running. They are different
> numbers for different things and neither replaces the other; §14's "extrapolates for at
> most 60 days" is the sentence F-7.2 corrects. Build **both**, cite F-7.2 in each dartdoc,
> and do not collapse them into one constant to make a fixture pass.

### Task 16.3 — The payload and the six deep links

- **Goal** — every notification carries the same three-field object, and tapping any of the
  six kinds lands somewhere sensible, including when the thing it names is gone.
- **Spec** — §4.4.2 The payload; §7 Screen map and navigation → Notification deep links.
- **Skills** — `navigation-and-routing`, `local-notifications-scheduler` (serializable
  payload → location, never a non-serializable `extra`), `error-handling-typed-results`.
- **Write these tests first** — `test/core/notifications/notification_payload_test.dart`:
  - `round-trips all six kinds through JSON` — `reminder.due`, `reminder.overdue`,
    `reminder.grouped`, `odometer.nudge`, `keeper`, `backup.nudge`.
  - `rejects a reminder.due payload with no reminderId` and the same for `reminder.overdue`
  - `rejects a grouped, nudge, keeper or backup payload that carries a reminderId`
  - `rejects a payload with no vehicleId on any kind`
  - `rejects an unknown kind rather than defaulting to reminder.due` — an app-update-stale
    payload is refused, not guessed at.

  `test/app/routing/notification_deep_link_test.dart`:
  - `reminder.due sets activeVehicleId, selects the Home tab and pins the card for ~2s`
  - `reminder.overdue resolves to the same location as reminder.due`
  - `reminder.grouped sets activeVehicleId and pins no card`
  - `odometer.nudge sets the vehicle first, then opens log.odometer prefilled` — asserts
    the order; setting the vehicle after the modal opens prefills the wrong car.
  - `odometer.nudge never opens vehicle.switcher`
  - `keeper leaves activeVehicleId untouched`
  - `backup.nudge synthesises [home, settings, settings.backup] so Back walks out through
    Settings`
  - `every other kind synthesises a [home] back stack`
  - `a payload naming a deleted vehicle lands on plain home with no error surface`
  - `a payload naming a deleted reminder lands on plain home with no error surface`
  - `a cold start from a notification never shows onboarding`
- **Then build** — `lib/core/notifications/notification_payload.dart` (a `sealed class
  NotificationPayload` with the six subtypes, `toJson`/`fromJson` returning
  `Result<NotificationPayload, PayloadFailure>`) and
  `lib/app/routing/notification_deep_link.dart` — the PAYLOAD half only. **EPIC-08 task 8.7 already built `lib/app/routing/deep_link.dart`**, which owns `locationFor`, the back-stack synthesis, the two "the thing is gone" rows and the vehicle-before-route ordering (finding F-8.3). This file owns the sealed `NotificationPayload`, its JSON round-trip and its per-kind `reminderId` validation, and maps onto `DeepLinkRequest` at the boundary. The tests below are kept and run against `locationFor` as it already exists — a function that is already right should still pass them. What was originally specified here was (`String locationFor(NotificationPayload)`
  plus the back-stack synthesis). Routing reads three fields and nothing else.
- **Verify**
  ```bash
  flutter test test/core/notifications/ test/app/routing/
  bash .claude/skills/navigation-and-routing/scripts/check_routing.sh
  ```
- **Done when**
  - [ ] All six kinds round-trip; every `reminderId` rule in the §4.4.2 table is a test.
  - [ ] A stale or unknown payload is a typed failure, never a default route.
  - [ ] Back from any deep-linked modal reaches Home, never the launcher.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 16.4 — The gateway port, the adapter and the fake

- **Goal** — exactly one file in the app knows that `flutter_local_notifications` exists.
- **Spec** — §4.6.1 The pending-notification cap; §4.6.3 Android alarm policy; §17 Offline
  gate.
- **Skills** — `local-notifications-scheduler` (the port is its central artefact),
  `service-boundary-and-native`, `app-startup-and-bootstrap`.
- **Write these tests first** —
  `test/services/notifications/notification_gateway_contract_test.dart`, a contract suite
  run against `FakeNotificationGateway`:
  - `schedule then getPending returns exactly that notification`
  - `cancel removes one id and leaves the rest`
  - `cancelAll empties the pending set`
  - `getPending exposes ids only, never fire times` — the fake must not expose `when`,
    because the real OS does not, and code that reads it will work in tests and fail on
    device.
  - `scheduling the same id twice replaces rather than duplicates`

  `test/policy/notifications_import_policy_test.dart`:
  - `flutter_local_notifications is imported in exactly one file` — a source grep over
    `lib/`, failing with the offending paths.
  - `no feature or ViewModel calls gateway.schedule or gateway.cancel directly`
  - `the Android manifest declares SCHEDULE_EXACT_ALARM and never USE_EXACT_ALARM`
- **Then build** — `lib/services/notifications/notification_gateway.dart` (the four-method
  port), `fln_notification_gateway.dart` (the only importer; sets `tz.local` from
  `flutter_timezone` at startup, uses `AndroidScheduleMode.inexactAllowWhileIdle`, three
  channels matching the three category switches on `settings.notifications`),
  `fake_notification_gateway.dart`, and the `notificationGatewayProvider` that throws until
  the composition root overrides it. Add the packages to `pubspec.yaml` and to the
  dependency audit's allowlist.
- **Verify**
  ```bash
  flutter test test/services/notifications/ test/policy/
  bash .claude/skills/local-notifications-scheduler/scripts/check-single-fln-import.sh
  bash .claude/skills/local-notifications-scheduler/scripts/check-adhoc-schedule-calls.sh
  bash .claude/skills/local-notifications-scheduler/scripts/check-manifest-permissions.sh
  bash tools/audit_deps.sh
  ```
  All four scripts silent, and the dependency audit still refuses every networking package.
- **Done when**
  - [ ] The port has exactly four methods; anything richer went into the pure scheduler.
  - [ ] `tz.local` is set in `bootstrap()` before any scheduling call can run.
  - [ ] `USE_EXACT_ALARM` appears nowhere in `android/`.
  - [ ] The new packages pull in no HTTP client — the offline gate still passes.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 16.5 — The slot builder: horizon, quiet hours, coalescing, the cap

- **Goal** — a pure function turns every reminder on every car into the ≤46 notifications
  the OS will actually hold, obeying the two-a-week promise absolutely.
- **Spec** — §4.4.1 Stages; §4.4.3 The cap; §4.5 Quiet hours and delivery time; §4.6.1 the
  build pseudocode; §14 Edge cases → "More is due than the cap allows".
- **Skills** — `local-notifications-scheduler`, `value-objects-money-and-units`,
  `i18n-rtl-l10n` (the locale supplies the weekend definition, never a hard-coded Sat+Sun),
  `testing-strategy`.
- **Write these tests first** — `test/core/notifications/reminder_scheduler_test.dart`:
  - `builds the four stages at due−notice, due, due+14 and due+45`
  - `builds nothing after overdue2` — a 90-days-overdue item produces no fifth stage.
  - `schedules nothing beyond the 120-day horizon`
  - `never schedules more than two notifications in any rolling seven days` — the fixture
    is five cars × twelve reminders, and the assertion walks every 7-day window across the
    whole 120 days. This is the epic's headline test.
  - `never schedules two on the same calendar day`
  - `coalesces two items in one slot into one grouped notification with no reminderId`
  - `titles a single-vehicle group with the vehicle name and a multi-vehicle group Odova`
  - `sets a multi-vehicle group's vehicleId to the first vehicle named in the body`
  - `prioritises overdue2 over overdue1 over due over nudge over early`
  - `breaks a tier tie safety, then normal, then low, then nearest projected due`
  - `defers a loser to the next free slot`
  - `drops an item deferred more than 21 days past its stage date` — asserts dropped, not
    queued, and that the item is still returned to the caller as due.
  - `reserves two of the next four weeks' slots for overdue and nudge` — twelve `early`
    candidates cannot take all four.
  - `gives a low-priority item one notification, at due, and never lets it take a safety
    item's slot`
  - `moves a 21:30 fire time to the next day's 09:00 slot` and
    `does not release a quiet-hours batch at 08:00`
  - `weekdays_only moves a Saturday fire date to Monday for de-DE and a Friday one to
    Sunday for fa-IR` — the weekend comes from the locale (`SPEC.md` §5, Weekend days), and
    a hard-coded Sat+Sun fails this.
  - `takes the first 46 candidates and marks the remainder scheduled = false`
  - `is deterministic: the same inputs produce the same list, in the same order, twice`
- **Then build** — `lib/core/notifications/reminder_scheduler.dart`:
  `ReminderScheduler.compute({required List<ReminderCandidate> candidates, required
  DateTime now, required SchedulePreferences prefs, int budget = 46})` returning
  `List<ScheduledNotification>`. Stage is `enum NotificationStage { early, due, overdue1,
  overdue2, nudge }`. Pure — no plugin, no IO, no clock read.
- **Verify**
  ```bash
  flutter test test/core/notifications/reminder_scheduler_test.dart
  bash .claude/skills/local-notifications-scheduler/scripts/check-scheduler-purity.sh
  ```
- **Done when**
  - [ ] The rolling-seven-day assertion runs over the five-car fixture and passes.
  - [ ] The weekend is asked for, never hard-coded.
  - [ ] The budget is 46 = 48 − 2 reserved, and the number appears once.
  - [ ] Nothing in this file can throw; every degenerate input returns a list.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 16.6 — Reconcile without churn

- **Goal** — buying fuel does not cancel and re-add thirty notifications.
- **Spec** — §4.2.1 Triggers; §4.2.2 Avoiding churn; §4.6.1 `scheduled_notifications`.
- **Skills** — `local-notifications-scheduler` (the one `syncNotifications()` entrypoint),
  `persistence-drift`, `state-management-riverpod`, `error-handling-typed-results`.
- **Write these tests first** — `test/services/notifications/sync_notifications_test.dart`,
  driven through `FakeNotificationGateway`:
  - `is a no-op on unchanged input` — zero schedule calls, zero cancels, on the second run.
  - `leaves a pending notification alone when its recomputed time moves 6 days`
  - `reschedules when the recomputed time moves 8 days` — old id cancelled, new id added.
  - `sends a recomputed past time to the next delivery slot, never to now`
  - `never reschedules a stage that has already fired`
  - `moves only future stages when a reminder is reprojected`
  - `coalesces two reprojection requests inside 2 seconds into one build`
  - `suppresses every build during an import and runs exactly one after commit`
  - `re-bakes the body from current numbers on a reschedule`
  - `derives the id from the key plus the resolved fire instant` — editing the delivery
    time from 09:00 to 14:00 without moving the date produces a new id, so the old one is
    cancelled and the new one fires. The id ignoring the instant is the classic bug here.
  - `linear-probes on a 31-bit id collision and persists the key-to-id mapping`
  - `marks a row the OS no longer holds as dropped, not as dismissed` — the table is the
    truth for *why*, the OS for *whether*.
  - `returns a Failure rather than throwing when the gateway rejects a schedule`
- **Then build** — `lib/services/notifications/sync_notifications.dart` (the single
  reconcile), the Drift table `scheduled_notifications (key, os_id, vehicle_id,
  reminder_id, stage, fire_at_local, body_hash, state)` with a unique index on `key`,
  `lib/core/notifications/deterministic_id.dart`, and the debounced
  `reprojectionProvider` covering every row of the §4.2.1 trigger table.
- **Verify**
  ```bash
  flutter test test/services/notifications/
  bash .claude/skills/local-notifications-scheduler/scripts/check-adhoc-schedule-calls.sh
  bash .claude/skills/persistence-drift/scripts/check-drift-confinement.sh
  ```
- **Done when**
  - [ ] Every scheduling change in the app goes through `syncNotifications()`.
  - [ ] Hysteresis is 7 days, stated once, with the reason in its dartdoc.
  - [ ] `fire_at_local` is wall-clock; no UTC instant is persisted for a recurring stage.
  - [ ] Two consecutive reconciles over unchanged data issue zero OS calls.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 16.7 — The nudge that asks for a reading without nagging

- **Goal** — when the estimate has drifted far enough to matter, the app asks once, and
  stops asking when it has been answered three times with silence.
- **Spec** — §4.3 The nudge for a reading (all three subsections); §14 Edge cases →
  Vehicle lifecycle.
- **Skills** — `local-notifications-scheduler`, `state-management-riverpod`,
  `value-objects-money-and-units`, `testing-strategy`.
- **Write these tests first** — `test/core/reminders/staleness_nudge_test.dart`:
  - `warrants a nudge when drift exceeds 15% of the smallest active distance interval` —
    rate 41 km/day, 40 days since the last reading → drift 1,640 km; smallest interval
    10,000 km → threshold 1,500 km. Warranted.
  - `does not warrant one at 30 days on the same car` — drift 1,230 km, under threshold.
  - `does not warrant one without an active distance reminder due inside 120 days`
  - `escalates past the formula when an item is due within 21 days and the reading is over
    21 days old`
  - `never nudges within 14 days of the vehicle being created`
  - `never nudges an archived or sold vehicle` — `status = archived`, `status = sold`.
  - `never nudges a vehicle whose reminders are all date-driven`
  - `caps nudges at one per vehicle per 30 days`
  - `caps nudges at one per 14 days across all vehicles and picks the largest drift`
  - `counts a nudge against the weekly cap` — a nudge and two reminder stages in one week
    means one of the three is deferred.
  - `only sends the notification after the card was unactioned across two app opens`
  - `sends it anyway when the app has not been opened in 21 days`
  - `stops nudge notifications for that vehicle for 180 days after three ignored nudges` —
    "ignored" is no reading logged within 7 days of each.
  - `keeps the in-app card alive after the give-up rule fires`
- **Then build** — `lib/core/reminders/staleness_nudge.dart` (`NudgeDecision
  shouldNudge(...)`, pure) and `lib/features/reminders/staleness_nudge_provider.dart`
  exposing the decision plus the per-vehicle bookkeeping (`last_nudge_at`,
  `nudges_ignored`, `card_dismissed_until`, `card_seen_opens`). The **in-app card is not
  built here** — the `home` epic renders it from this provider. Dismissing it hides it for
  7 days; that timer lives in this bookkeeping so both channels read one source.
- **Verify**
  ```bash
  flutter test test/core/reminders/staleness_nudge_test.dart test/services/notifications/
  ```
  Green, and the five-car cap assertion from Task 16.5 still passes with nudges in the mix.
- **Done when**
  - [ ] Every row of the §4.3.3 cadence table is a named test.
  - [ ] The give-up rule silences the notification and never the card.
  - [ ] The nudge competes for slots under the same cap as everything else.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 16.8 — The pre-prompt, and being useful when the answer is no

- **Goal** — the one OS permission dialog is spent at a moment of intent, and a permanent
  refusal costs the user no functionality at all.
- **Spec** — §4.4.5 The permission pre-prompt; §4.6.4 Background restriction (the last
  paragraph); §14 Edge cases → "Permission never granted" and "Permission asked at the
  wrong moment"; §13 `settings.notifications` states.
- **Skills** — `service-boundary-and-native` (the permission API behind a port),
  `state-management-riverpod` (the trigger and the counters are providers), `i18n-rtl-l10n`
  (three ARB keys in six languages), `navigation-and-routing` (the sheet is presentable from
  anywhere and is not a route).
- **Write these tests first** — `test/features/notifications/permission_preprompt_test.dart`:
  - `never appears on first launch`
  - `never appears before a vehicle exists`
  - `never appears on the onboarding path`
  - `appears after the first ServiceRecord is saved`
  - `appears when the first item on any vehicle reaches due_soon`
  - `appears from the Turn on reminders row on settings.notifications`
  - `only Turn on reminders raises the OS dialog` — asserts the permission port received
    exactly zero calls on the "Not now" path.
  - `Not now writes the decline counter and nothing else`
  - `appears at most once per 30 days`
  - `never appears a fourth time, across all triggers and all vehicles`
  - `stops permanently once permission is granted`
  - `an OS-level revoke after granting does not restart it`
  - `the counter and last-shown date survive an import` — device state, not file state.
  - `a vehicle delete does not reset the counter`

  `test/features/notifications/denied_still_useful_test.dart`:
  - `the app-icon badge carries the due plus overdue count when permission is denied`
  - `the away digest appears once when the app is opened after seven or more days`
  - `no feature is gated on permission` — walks the route table and asserts every location
    renders with the permission port reporting `denied`.
  - `settings.notifications shows one dismissible line, never a persistent banner`
- **Then build** — `lib/services/notifications/notification_permission_port.dart` and its
  live implementation, `lib/features/notifications/permission_preprompt_sheet.dart`
  (`NotificationPrePromptSheet`), and the trigger provider. Copy is three ARB keys; the
  body states the cap as a fact — *"At most two notifications a week, never more than one a
  day. Everything stays on this phone."* — and must be regenerated if the cap in Task 16.5
  ever changes.
- **Verify**
  ```bash
  flutter test test/features/notifications/
  bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh
  ```
  Green, and no hard-coded user-visible literal in the sheet.
  **No parity gate:** the pre-prompt is a sheet, not an addressable screen, and
  `design/reference/calm/` holds no image for it. It inherits Calm through `CalmSheet`; if
  you want it gated, the fix is to add an artboard to `design/calm/screens.html` and
  re-shoot the set — never a hand-tuned widget nobody can check.
- **Done when**
  - [ ] The OS dialog is raised from exactly one call site.
  - [ ] All three triggers and the three-strikes cadence are tested.
  - [ ] Every screen renders with permission denied, and nothing is disabled.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 16.9 — Rebuilds: reboot, update, timezone, locale, import, and the keeper

- **Goal** — the queue survives everything the phone and the user can do to it, and can
  never run dry in silence.
- **Spec** — §4.6.2 Rebuild triggers; §4.6.4 Background restriction; §14 Edge cases →
  "Time-zone change or DST", "User does not open the app for eight months", "OEM background
  killers".
- **Skills** — `local-notifications-scheduler` (boot re-arm, background isolate),
  `app-startup-and-bootstrap` (`tz.local` and the rebuild sit in a fixed launch order),
  `service-boundary-and-native` (the OEM settings intent), `i18n-rtl-l10n`,
  `persistence-drift` (the import path cancels, imports in a transaction, then rebuilds).
- **Write these tests first** —
  `test/services/notifications/rebuild_triggers_test.dart`:
  - `rebuilds on Android boot-completed after unlock`
  - `rebuilds on the first launch after a version change` — a changed `last_build_version`
    triggers exactly one full rebuild, and stale payloads from the old schema are discarded.
  - `rebuilds on a timezone change and keeps 09:00 local` — Berlin → Tehran; the fire
    instant moves, the wall-clock does not.
  - `does nothing on a DST transition` — spring forward and fall back both leave the
    pending set untouched.
  - `rebuilds on a locale change and re-renders every body` — the fake gateway's bodies are
    German before and Arabic after, and no German body survives.
  - `cancels all, imports in a transaction, then rebuilds once after commit`
  - `honours imported fired states so an import does not re-fire history`
  - `rebuilds when permission is granted, and when it is revoked then granted`
  - `cancels a vehicle's keys on archive or delete, then rebuilds`
  - `detects a backwards clock move and suppresses anything inside the next hour`
  - `schedules a keeper at horizon minus 7 days with kind keeper and no reminderId`
  - `the keeper counts against the weekly cap`
  - `delivery of the keeper re-arms the queue on the next launch, the tap does not`
  - `performs a full rebuild before the first frame of home when the app has been away
    longer than the horizon, and shows the away digest regardless of permission state`
  - `flags OEM battery optimisation after three deliveries still pending 48 h past
    fire_at_local with the app foregrounded since` — one dismissible row on
    `settings.notifications`, never a modal, never on `home`, asked once.
- **Then build** — `lib/services/notifications/boot_rearm_android.dart`, the periodic
  `WorkManager` job (14 days, no network, no exact alarms) and the iOS
  `BGAppRefreshTask` request, the keeper scheduling inside `ReminderScheduler.compute`, the
  `last_build_version` / `last_seen_now` bookkeeping, and the delivery-confirmation
  reconciliation that raises the OEM row. Tap handling is
  `@pragma('vm:entry-point')` and writes nothing to the database.
- **Verify**
  ```bash
  flutter test test/services/notifications/
  bash .claude/skills/local-notifications-scheduler/scripts/check-manifest-permissions.sh
  ```
  Plus the one thing a test cannot prove, stated plainly in the progress file: a 7-day
  background-delivery soak on a real Xiaomi or Huawei device (§4.6.4). An emulator run is
  not evidence.
- **Done when**
  - [ ] Every row of the §4.6.2 table has a test named after it.
  - [ ] No fire time is stored as a UTC instant.
  - [ ] The tap isolate performs no database write.
  - [ ] The real-device soak is either done or recorded as outstanding in the progress file.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 16.10 — Done, Snooze, and the rollover rule

- **Goal** — a notification's two actions do the right thing without launching the app, and
  the next interval is measured from what actually happened.
- **Spec** — §4.7 Snooze, dismiss, and done (all four subsections); §14 Edge cases →
  "Done from a notification", "Snoozed forever", "Swiping a notification away".
- **Skills** — `local-notifications-scheduler` (background actions, re-anchoring),
  `error-handling-typed-results` (never-lose-data), `persistence-drift` (one transaction
  per mutation), `state-management-riverpod`, `calm-due-state-and-status` (the confirmation
  strip is an inline surface carrying an estimated figure, not a dialog).
- **Write these tests first** — `test/features/reminders/complete_reminder_test.dart`:
  - `Done from a notification writes a ServiceRecord dated today with odometer_estimated
    and cost_estimated both true`
  - `writes exactly one ServiceLine with the item's label, amount 0, in the vehicle's
    currency` — a record with no line cannot exist; zero is the only representable
    "not recorded".
  - `uses round(odo_now) for the odometer`
  - `does not launch the app`
  - `queues an editable confirmation strip for the next appearance of home`
  - `clears snoozed_until, snooze_until_odometer_m and sets snooze_count to 0`
  - `cancels every pending key for the reminder and reprojects the vehicle`
  - `writes nothing to the reminder except the snooze fields` — the anchor is the
    `ServiceLine`, recomputed by `resolveAnchor` on every read.
  - `rolls from_actual: due at 115,000, done at 118,400, next at 128,400` — not 125,000.
    The permanent-debt bug this prevents is the reason the test exists.
  - `rolls from_due for inspection, insurance_renewal and registration, and for nothing else`
  - `asks once when an anchored item is completed more than 60 days after its due date`
  - `never asks when an anchored item is completed inside 60 days`
  - `rolls only the distance dimension on a distance-only item`
  - `a back-dated completion may immediately re-mark the item due, and the confirmation
    says so`
  - `adding an old service record recomputes the anchor from the most recent record`
  - `snooze suppresses every stage and changes neither the due date nor the red treatment`
  - `a distance snooze converts to a date through the projection and reprojects like
    anything else`
  - `the fourth snooze offers Snooze again, Change the interval and Turn this reminder off`
  - `swiping a notification away writes nothing and leaves later stages scheduled`
- **Then build** — `lib/features/reminders/complete_reminder.dart` implementing the §4.7.4
  four-step `complete(...)` exactly, the snooze application, the background action handler
  that records intent for the next foreground reconcile, and the confirmation-strip queue.
  `dialog.snooze` already exists — **EPIC-08 task 8.10 builds it**, because §7 makes the three
  global dialogs global, belonging to no feature, and a dialog built twice is how two copies
  drift apart. This task wires its four options to the same code path the notification action
  uses; it builds no dialog and owns no parity gate for one.
- **Verify**
  ```bash
  flutter test test/features/reminders/ test/services/notifications/
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] The four steps of §4.7.4 happen in that order, in one transaction.
  - [ ] `from_due` applies to exactly three built-in kinds.
  - [ ] Both estimate flags reach the JSON export and the service history.
  - [ ] Dismissal is provably inert.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] `dailyDistance` returns `measured` / `assumed` / `defaulted` per §4.1.2 and clamps to
      5–500 km/day.
- [ ] The Passat worked example in §4.1.3 is a passing test with its literal numbers.
- [ ] No `~` figure and no projected date is ever produced at `DueConfidence.defaulted`,
      in the app or in a notification body.
- [ ] Across five cars and twelve reminders each, no rolling seven-day window holds more
      than two notifications and no calendar day holds more than one — asserted, not argued.
- [ ] At most 46 notifications are pending, and `scheduled_notifications` reconciles
      against the OS list on every rebuild.
- [ ] All six payload kinds route per §7, including for a deleted vehicle or reminder.
- [ ] The app is fully usable with notifications denied forever, and the pre-prompt appears
      at most three times, at most once per 30 days, never at launch.
- [ ] Reboot, app update, timezone change, locale change and import each produce exactly
      one full rebuild, and the keeper prevents a silent empty queue.
- [ ] `flutter_local_notifications` is imported in one file; all four
      `local-notifications-scheduler` scripts pass.
- [ ] The projection expiry (180 days) and the `needs_odometer` staleness threshold
      (60 days) are two separate named constants, built per EPIC-07's F-7.2 and cited to it.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-16.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
