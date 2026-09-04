# EPIC-07 — The due engine and projection

| | |
|---|---|
| **Epic** | EPIC-07 — The due engine and projection |
| **Depends on** | EPIC-06 |
| **Estimate** | **8 h (CC) · ~8 weeks (human)** over 9 tasks |
| **Spec sections** | §3 Domain model and rules — *The due engine*, *Derived values*, *Invariants and validation* · §4 Reminders and notifications — *§4.1 Projecting distance into a date*, *§4.2 Re-projection* |
| **Screens** | none |

This epic writes no UI. It decides what every card in the app says, which is why its fixture
suite is the specification made executable rather than a smoke test: every combination of
`{distance-only, time-only, both} × {ok, due_soon, due, overdue, unknown, needs_odometer,
paused}` is a committed vector, and a change to any threshold in §3 or §4.1 fails a named
row rather than a screenshot three epics later.

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end, `SPEC.md` wins — are stated once in `epics/README.md`. They apply
here in full, and rule 1 applies hardest: this is pure arithmetic with an injected clock, so
there is no excuse anywhere in this epic for writing code before the test that fails without
it.

---

## Where we are now

The repo before EPIC-01 held `SPEC.md`, the three design systems, the 108 Calm reference
PNGs, `tools/` and `.claude/skills/`, and **no Flutter app** — no `pubspec.yaml`, no `lib/`.
EPIC-01 created it; everything since inherits it.

At the moment this epic starts:

- `pubspec.yaml`, `lib/`, `test/` exist, `very_good_analysis` is resolvable and real, and
  `flutter analyze --fatal-infos --fatal-warnings` plus `flutter test` are green (EPIC-01).
- The Calm theme is in `lib/theme/calm/`, and with it the one and only
  `enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }` and
  `enum DueDriver { distance, time, both, none }` (EPIC-02, per `calm-due-state-and-status`).
  **This epic does not define those enums. It returns them.**
- The Calm widget library is in `lib/ui/calm/` (EPIC-03) and the six-locale ARB pipeline is
  live (EPIC-04). Neither is touched here.
- The §3 entities are modelled and persisted behind repositories that are the single write
  path (EPIC-05): `Vehicle`, `ServiceItem`, `ServiceRecord` + `ServiceLine`, `FillUp`,
  `Expense`, `OdometerReading`, `OdometerCorrection`, `Trip`, `Settings`.
- **EPIC-06 delivered most of the pure core this epic stands on**: canonical integer
  units in `lib/core/units/` (`Distance`, `Volume`, `Mass`, `Energy`, the sealed
  `FuelQuantity`), `Money`/`Currency`/`MoneyTotal`, the `Result`/`Failure` spine, and
  `cumulativeByReading` with `OdometerCorrection` offsets applied. The injected `Clock`
  from `package:clock` is there too — EPIC-05 built it (`lib/app/providers.dart`'s
  `clockProvider`), not EPIC-06.
- **`CivilDate` is NOT there, and this line used to say it was.** EPIC-06's ten tasks
  never named it and it was never built; the claim was corrected in this epic's first
  commit, and `epics/progress/EPIC-06.md`'s handover section says what is needed. It is
  **task 7.0 below**, before anything else, because `OdometerPoint`, `DueAnchor`,
  `dailyDistance` and `DueStatus` all take one.
- `lib/core/time/` exists and holds `completed_months.dart` (`MonthRange`,
  `completedMonthsBefore`), which EPIC-06 moved there out of `lib/core/money/` precisely
  so this epic's month arithmetic would have somewhere obvious to live. It is already a
  named subject in `test/policy/core_is_pure_test.dart`'s allowlist.

Deliberately still missing when this epic starts, and still missing when it ends:

- **No notification scheduling.** §4.2's *triggers* are here as a pure recompute; §4.2.2's
  hysteresis, the `scheduled_notifications` key→id table, quiet hours and the weekly cap are
  a later epic's. This epic gives that epic a function to call and nothing else.
- **No UI.** No widget, no `Notifier`, no provider that a screen reads. `lib/core/due/` may
  not import `package:flutter`, and the epic's own tests run under `package:test`, not
  `flutter_test`, so a stray `Widget` is a compile error rather than a review comment.
- **No `buildFuelSegments`.** Fuel maths is §3's other half and a different epic.

## What we will have when this is done

- `dart test test/core/due/` runs in under two seconds with no widget binding and pins every
  threshold in §3's due engine and §4.1's projection.
- One command answers "what is due on this car, and why" for any fixture:
  `dart run tool/due_report.dart test/core/due/fixtures/passat.json` prints the §4.1.3 worked
  example verbatim — rate 41 km/day *measured*, `odo_now` 116,583 km, threshold 118,200 km,
  projected due **2026-10-12**, driver `distance`, time axis 2027-02-10 — and any change to a
  clamp, a band or a rung moves that line.
- `test/core/due/fixtures/due_matrix.json` holds 21 committed vectors, one per
  `{axis} × {status}` combination, each asserting the whole `DueAssessment` and not only its
  status. A reviewer can read the file and check it against §3 without opening a `.dart` file.
- `grep -rn "package:flutter" lib/core/due/` returns nothing, and
  `grep -rn "DateTime.now()" lib/core/` returns nothing.
- Two defects in `SPEC.md` are fixed in this epic's PR rather than shipped: the `from_due`
  rollover walk (F-7.1) and §14's 60-day expiry line (F-7.2). Both are listed under
  *Spec findings* below and neither is worked around in code.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Rules 6, 7 and 8 are the whole shape of this epic: derive don't store, pure functions are **total** and return uncertainty rather than throwing, and "now" comes from an injected clock. |
| `flutter-architecture` | Fixes where this code lives. `lib/core/` is the pure foundation with no Flutter import; nothing in this epic may sit in a feature folder, because five screens read it. |
| `calm-due-state-and-status` | Owns the six-member `DueState` enum and `DueDriver`. It also decides that `paused` and `snoozed` are **not** members — paused is a filter applied before the engine runs, snoozed keeps its real state — which is a rule this epic implements rather than the theme. |
| `value-objects-money-and-units` | Metres, calendar months and zoneless dates in a pure core; the `Clock` seam; why `addMonths` clamps to the last day of the month rather than adding 30.44 days. |
| `dart3-idioms-and-coding-standards` | Sealed types, records, exhaustive `switch`, and the complexity limits — the axis functions want to grow past 30 lines and must not. |
| `error-handling-typed-results` | Every function here is total: an empty reading series returns a `default` rate, not an exception; an item with no anchor returns `unknown`, not null. |
| `testing-strategy` | The pure-core test tier: fast `package:test`, injected clock, property invariants, fakes for nothing because there is nothing to fake. |
| `seeded-determinism-and-golden-vectors` | The 21-row matrix is a golden **vector** table, not a golden image: a committed fingerprint file, regenerated only by a reviewed command that CI verifies and never blesses. That rule is what stops task 7.8 degrading into "re-record whatever the code now does". |

---

## Tasks

### Task 7.0 — `CivilDate`: a date with no time and no zone

- **Goal** — the type every other task in this epic takes, so that "what day is it" is
  never a `DateTime` and never depends on where the phone is.
- **Why it is here and not in EPIC-06** — it was not in EPIC-06's task list and was not
  built; this epic's *Where we are now* claimed otherwise and has been corrected. The
  tests that justify its shape are all here.
- **Spec** — §3 *Entities* (`occurred_on` is `YYYY-MM-DD` text, not a timestamp); §4.1
  *Projecting distance into a date*; §18 q. 7 (the Jalali calendar question, which this
  type must not foreclose).
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`.
- **Write these tests first** — `test/core/time/civil_date_test.dart`:
  - `parses and re-renders YYYY-MM-DD exactly` — round-trip, including a leap day.
  - `refuses anything that is not a calendar date` — `2026-13-01`, `2026-02-30`,
    `2026-2-3`, `26-02-03`, an empty string: `tryParse` returns null, never a guess.
  - `has no time and no zone` — the type holds three ints; there is no `DateTime` field
    and no `toLocal`.
  - `daysUntil counts CIVIL days across a daylight-saving boundary` — the bug this type
    exists to prevent. `DateTime.parse('2026-03-29')` is a LOCAL time and two dates two
    calendar days apart differ by 47 hours across a European spring-forward, which
    `inDays` truncates to 1. Asserted at a real transition, in both hemispheres.
  - `addDays crosses a month and a year boundary`.
  - `addMonths clamps to the last day of the target month` — 31 January + 1 month is
    28 February in 2026 and 29 February in 2028, never 3 March. This is SPEC.md §3's
    `interval_months` rule and the reason `addMonths` is not "add 30.44 days".
  - `addMonths is not reversible, and the test says so` — 31 Jan + 1 month − 1 month is
    28 Feb, not 31 Jan. A caller who assumes otherwise gets a drifting service date.
  - `compares and sorts by calendar order` — `Comparable`, with `==` and `hashCode`.
- **Then build** — `lib/core/time/civil_date.dart`, beside `completed_months.dart`.
  Three `int` fields, `tryParse`, `toString()`, `daysUntil`, `addDays`, `addMonths`,
  `Comparable<CivilDate>`, value equality. Gregorian only: §18 q. 7 is open, and a
  Jalali rendering is a PRESENTATION concern that reads this type rather than replacing
  it — `lib/core/l10n/jalali.dart` already converts.
- **Verify** — `dart test test/core/time/`; `bash tools/check_core_purity.sh`.
- **Done when**
  - [ ] No `DateTime` field on the type; `dart test test/core` still green on the plain VM.
  - [ ] `addMonths` clamps, with the February cases pinned in both a leap and a common year.
  - [ ] `daysUntil` is asserted across a real DST transition and disagrees with a naive
        `DateTime` difference there.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

### Task 7.1 — Normalise the reading series into rate endpoints

- **Goal** — every source of odometer truth on a vehicle becomes one ordered, correction-adjusted series, with the subset that may be used as a rate endpoint marked.
- **Spec** — §4.1.1 *The reading series*; §3 *The odometer: continuity and corrections*.
- **Skills** — `flutter-architecture`, `value-objects-money-and-units`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/core/due/reading_series_test.dart`:
  - `collapses two readings on the same date to the highest odometer` — two readings on 2026-08-20 at 116,000 km and 116,050 km give one point at 116,050 km; fails if both survive.
  - `sorts ascending by date and breaks ties on created_at` — the ULID tiebreak of §3.
  - `restarts the series at a reading below its predecessor` — 116,050 then 4,000 with no correction row: the 4,000 point exists but is not a rate endpoint, and the endpoint set restarts from it. Fails if the pair is used as a slope.
  - `applies a cluster-replacement correction so cumulative metres stay non-decreasing` — `previous_m` 187,412 km, `new_m` 0, offset +187,412 km on every reading at or after `from_reading_id`.
  - `excludes a same-day pair from the endpoint set` — endpoints must be ≥1 day apart; two readings 6 hours apart on the same date yield one endpoint, not a 400 km/day slope.
  - `a trip with only manual_distance_m contributes no point` — §4.1.1's table, the double-count rule.
  - `a trip with an end odometer contributes one point`, `a service record contributes one point`, `an expense contributes none`.
  - `an imported fill-up with a null odometer contributes no point` — nullable only from import.
  - `an empty vehicle returns an empty series and does not throw`.
- **Then build** — `lib/core/due/reading_series.dart`. A `ReadingSeries` value type over
  `OdometerPoint({required CivilDate date, required int cumulativeMetres, required bool isRateEndpoint})`,
  built by `ReadingSeries.from(readings, corrections)`. Normalisation runs in §4.1.1's stated
  order — sort, collapse same-date, restart at a decrease, mark endpoints ≥1 day apart —
  because the order changes the answer. Immutable, value equality, no Flutter import.
- **Verify** — `dart test test/core/due/reading_series_test.dart`; `dart analyze --fatal-infos lib/core/due/`. A pass is 11 green tests and a clean analyzer.
- **Done when**
  - [ ] Every §4.1.1 source row has a test asserting whether it contributes a point.
  - [ ] The three normalisation steps are applied in the spec's order and a test would fail if they were reordered.
  - [ ] `grep -rn "package:flutter" lib/core/due/` is empty.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

### Task 7.2 — `dailyDistance`: one rate, four rungs, one clamp

- **Goal** — the single number the whole projection consumes, with an honest confidence attached to it.
- **Spec** — §2 *One projection engine, one lead-time formula*; §4.1.2 *Rate estimation*; §3 *The due engine* (first paragraph).
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/core/due/daily_distance_test.dart`:
  - `measures the two-endpoint slope over the 180-day window` — the §4.1.3 Passat series returns 41,000 m/day with confidence `measured`.
  - `takes the slope, never the mean of per-segment rates` — a series of nine readings whose per-segment mean is 96 km/day but whose two-endpoint slope is 41 km/day returns 41. This is the bug §4.1.2 exists to prevent; the test names it.
  - `pairs the earliest endpoint inside the window with the latest endpoint overall` — a reading 200 days old is not the `a` endpoint even though it is the earliest.
  - `falls back to all history when the 180-day window holds one endpoint` — still `measured`.
  - `falls back to expected_annual_m when the span is under 14 days` — 13 days of readings and `expected_annual_m = 18,000,000` returns 49,315 m/day, `assumed`.
  - `falls back to expected_annual_m when the endpoints differ by under 100 km` — 99 km over 30 days is not a measurement.
  - `returns 12,000 km per year with confidence default when there is one reading and no expected_annual_m` — 32,876 m/day.
  - `clamps a 900 km per day slope down to 500 km per day and keeps confidence measured` — the clamp bounds the number, never the confidence.
  - `clamps a 2 km per day slope up to 5 km per day`.
  - `clamps an expected_annual_m of 300,000 km per year down to 500 km per day`.
  - `is total: an empty series with no expected_annual_m returns the default rate and does not throw`.
- **Then build** — `lib/core/due/daily_distance.dart`:
  `DailyDistance dailyDistance(ReadingSeries series, {required int? expectedAnnualMetres, required CivilDate today})`
  returning `DailyDistance({required int metresPerDay, required RateConfidence confidence})`.
  The enum is `enum RateConfidence { measured, assumed, defaulted }` — `default` is a Dart
  reserved word, so the third member is `defaulted` and its `///` doc says it is §4.1's
  `default` and serialises as `"default"` in any payload. Thresholds as named `const`s
  (`kRateWindowDays = 180`, `kRateMinSpanDays = 14`, `kRateMinDistanceMetres = 100000`,
  `kRateFloorMetresPerDay = 5000`, `kRateCeilingMetresPerDay = 500000`,
  `kDefaultAnnualMetres = 12000000`) so a threshold appears once in `lib/` and once per test.
  §3 writes the signature as `dailyDistance(readings, today)` and §4.1.2 as
  `dailyDistance(vehicle)`; the pure core cannot hold a `Vehicle` row, so the readings form
  wins and `expected_annual_m` is passed in (finding F-7.4).
- **Verify** — `dart test test/core/due/daily_distance_test.dart`. A pass is 11 green tests. Then `grep -rn "180\|500000\|12000000" lib/core/due/ | grep -v const` — a raw threshold outside the const block is a finding.
- **Done when**
  - [ ] All four rungs of §4.1.2 have a test, in order, and each asserts its confidence.
  - [ ] The clamp is applied on every rung and never alters the reported confidence.
  - [ ] No threshold literal appears outside the named `const` block.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 7.3 — `estimateOdometer`: extrapolate, then stop

- **Goal** — the current odometer as a value that knows whether it was entered, projected or has expired.
- **Spec** — §3 *The due engine → Current odometer*; §4.1.3 *The projection expires*; §14 *Odometer not updated for months*.
- **Skills** — `value-objects-money-and-units`, `error-handling-typed-results`, `dart3-idioms-and-coding-standards`, `testing-strategy`.
- **Write these tests first** — `test/core/due/estimate_odometer_test.dart`:
  - `returns the entered reading unprojected on the day it was entered` — `staleDays == 0`, `projection == entered`, `asOf == the reading's date`.
  - `extrapolates at the measured rate for a thirteen-day-old reading` — 116,050 km + 41 × 13 = 116,583 km, `asOf == today`, `projection == projected`.
  - `still projects at exactly 180 stale days` — the boundary is `> 180`, not `>= 180`.
  - `expires at 181 stale days and returns the entered figure with the reading's own date` — 187,412 km `asOf` 2025-07-12, `projection == expired`, and the metre value is **not** extrapolated.
  - `an expired estimate carries no projected metre value anywhere in the record` — guards the "10,000 km of invention" failure §14 names.
  - `a vehicle with no readings returns null rather than zero metres` — zero is a real odometer value on a new car and must never stand in for "unknown".
  - `staleDays is a whole-day count on zoneless civil dates, not an instant difference`.
- **Then build** — `lib/core/due/estimate_odometer.dart`:
  ```dart
  enum OdometerProjection { entered, projected, expired }

  final class OdometerEstimate {
    final int metres;
    final CivilDate asOf;
    final OdometerProjection projection;
    final int staleDays;
  }

  OdometerEstimate? estimateOdometer(ReadingSeries series, DailyDistance rate,
      {required CivilDate today});
  ```
  §3's pseudocode assigns `is_projected = expired`, which is a bool holding an enum value;
  the three-member `OdometerProjection` is the honest type and every caller in tasks 7.6 and
  7.7 switches on it exhaustively (finding F-7.3).
- **Verify** — `dart test test/core/due/estimate_odometer_test.dart`. A pass is 7 green tests, including both sides of the 180/181 boundary.
- **Done when**
  - [ ] The 180-day expiry is a boundary test on both sides, not a single case.
  - [ ] `expired` never returns an extrapolated metre value.
  - [ ] `null` is returned for "no readings", and no test accepts `0` for it.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

### Task 7.4 — `resolveAnchor`: four rungs, and the `from_due` walk

- **Goal** — the date and odometer a reminder's next cycle is measured from, chosen by the first rung that can supply it.
- **Spec** — §3 *The due engine → Due state per item* (the `resolveAnchor` ladder and the `from_due` paragraph); §14 *Second-hand car with a service book*.
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`, `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/core/due/resolve_anchor_test.dart`:
  - `takes the newest ServiceRecord line referencing this item, with the record's cumulative odometer` — two records, the newer wins; the odometer is cumulative, not the dash number.
  - `ignores a service record whose lines reference a different item`.
  - `falls through to the item's baseline_date and baseline_odometer_m when no record references it`.
  - `falls through to the vehicle's purchase_date and purchase_odometer_m`.
  - `falls through to the earliest odometer reading and its date`.
  - `returns none when there is no record, no baseline, no purchase fact and no reading` — the caller turns this into `unknown`, and §14 requires it never becomes `overdue`.
  - `resolves the two axes independently when a rung supplies only one half` — `baseline_date` set with `baseline_odometer_m` null: the time axis anchors on the baseline date, the distance axis falls to the next rung that carries an odometer. Fails if a null odometer collapses the whole item to `unknown` (finding F-7.5).
  - `from_due anchors on the cycle date the completing record satisfied, not the record's own date` — inspection, 12 months, `baseline_date` 2024-06-01, done 2026-07-14 → `anchor.date` 2026-06-01, so `due_on` is 2027-06-01. **This is the corrected rule**; the literal §3 walk returns 2027-06-01 as the anchor and 2028-06-01 as the due date, a full cycle late. See F-7.1.
  - `from_due does not skip a cycle when the job was done early` — done 2026-05-20 → anchor 2025-06-01, `due_on` 2026-06-01.
  - `from_due keeps the record's odometer as the anchor odometer` — only the date is walked.
  - `from_actual anchors on the record's own date and odometer`.
- **Then build** — `lib/core/due/resolve_anchor.dart`:
  `DueAnchor resolveAnchor(ServiceItem item, List<ServiceRecord> records, Vehicle vehicle, ReadingSeries series)`
  returning `DueAnchor({CivilDate? date, int? odometerMetres})` with both halves resolved
  down the same four rungs independently. `from_due` computes
  `anchor.date = addMonths(base.date, interval_months × k)` for the **largest** `k ≥ 0` whose
  result is on or before the completing record's `occurred_on`, where `base` is
  `baseline_date`, else `purchase_date`, else the earliest reading's date. Amend the §3
  paragraph in `SPEC.md` in the same PR, with the 2026-07-14 counter-example in the commit
  message — this is a deliberate spec change, not a workaround.
- **Verify** — `dart test test/core/due/resolve_anchor_test.dart`. A pass is 11 green tests. Confirm the SPEC.md diff is in the same commit: `git show --stat | grep SPEC.md`.
- **Done when**
  - [ ] Each of the four rungs has a test that reaches it and one that skips past it.
  - [ ] The two `from_due` cases — done late and done early — both land in June.
  - [ ] `SPEC.md` §3's `from_due` paragraph is corrected in this PR and the PR body says why.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 7.5 — The notice window and the grace window

- **Goal** — how much warning an item gets before it is due, and how much forgiveness it gets after.
- **Spec** — §3 *Enums → Notice window*; §3 *The due engine* (`grace_m`, `grace_days`); §2 *One projection engine, one lead-time formula*.
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`, `testing-strategy`.
- **Write these tests first** — `test/core/due/notice_window_test.dart`:
  - `computes ten per cent of a 20,000 km interval and clamps it to 1,000 km` — 2,000 km hits the ceiling.
  - `clamps an 800 km chain-lube interval up to 200 km` — 80 km hits the floor.
  - `leaves a 5,000 km interval at its computed 500 km` — inside the clamp, untouched.
  - `clamps a twelve-month interval to 30 days` — 0.10 × 12 × 30.44 = 36.5 → 30.
  - `computes an 18-day window for a six-month interval` — 18.264 → 18, rounded half away from zero (§3's rounding rule).
  - `gives a one-off target_odometer_m the ceiling: 1,000 km` and `gives a one-off target_date the ceiling: 30 days` — there is no percentage to take.
  - `uses an explicit 2,000 km item override as written, without clamping it` — the clamp defines the computed default only, which is why `settings.notifications` may offer 2,000 km.
  - `prefers the item override, then the vehicle override, then Settings, then the computed default` — four-level resolution, one test per level reached.
  - `grace stays the computed default even when the notice window is overridden` — a user who asks for 2,000 km of warning has not asked for 2,000 km of forgiveness after the due point (finding F-7.6).
- **Then build** — `lib/core/due/notice_window.dart`:
  `NoticeWindow noticeWindow({required ServiceItem item, required Vehicle vehicle, required Settings settings})`
  returning `NoticeWindow({required int noticeDistanceMetres, required int noticeDays, required int graceDistanceMetres, required int graceDays})`.
  Constants: `kNoticeDistanceFloorMetres = 200000`, `kNoticeDistanceCeilingMetres = 1000000`,
  `kNoticeDaysFloor = 7`, `kNoticeDaysCeiling = 30`, `kDaysPerMonth = 30.44`,
  `kNoticeFraction = 0.10`.
- **Verify** — `dart test test/core/due/notice_window_test.dart`. A pass is 12 green tests covering both clamp edges on both axes and all four override levels.
- **Done when**
  - [ ] Floor and ceiling are each hit by a test on both axes.
  - [ ] An explicit override is proven not to be clamped.
  - [ ] Grace is proven independent of the override.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

### Task 7.6 — The two axes, and `computeDueState`

- **Goal** — one reminder plus one vehicle plus today becomes a `DueState`, a `DueDriver` and the numbers behind them.
- **Spec** — §3 *The due engine → Due state per item*, the `DISTANCE AXIS` / `TIME AXIS` / `COMBINE` blocks, *Grace exists on purpose*, *Stale odometer*, and the `DueState` record; §2 *`whichever_first` is the only combining rule*.
- **Skills** — `calm-due-state-and-status`, `dart3-idioms-and-coding-standards`, `error-handling-typed-results`, `testing-strategy`, `value-objects-money-and-units`.
- **Write these tests first** — `test/core/due/due_engine_test.dart`. Each band is a named case, not a loop:
  - `distance axis is ok while remaining is above the notice window` / `is due_soon inside the notice window` / `is due at zero remaining and within grace` / `is overdue past grace` — four tests, and one boundary test per edge (`remaining == notice` is `due_soon`, `remaining == 0` is `due`, `remaining == -grace` is `due`, `remaining == -grace - 1` is `overdue`).
  - The same four bands and four boundaries on the time axis, against `notice_days` and `grace_days`.
  - `an item with only interval_months has no distance axis and reports driver time` — mode is derived from which interval fields are non-null; there is no `mode` field to set.
  - `an item with only interval_distance_m has no time axis and reports driver distance`.
  - `whichever comes first: a due distance axis beside an ok time axis reports due, driver distance`.
  - `driver is both when the two axes reach the same severity`.
  - `severity ordering is ok < due_soon < due < overdue and the worse axis wins` — a property test over the 16 pairs.
  - `a distance-driven due with a 61-day-old reading becomes needs_odometer`.
  - `a distance-driven due_soon with a 61-day-old reading stays due_soon` — §3 downgrades `due` and `overdue` only.
  - `a time axis that independently reaches overdue outranks needs_odometer and reports overdue` — time never needs an odometer.
  - `an expired estimate reports needs_odometer on the distance axis at every severity, including ok` — the §4.1.3 rule, which is stronger than the 60-day one.
  - `an item with no anchor on either axis reports unknown, never overdue` — §14's second-hand-car rule.
  - `a snoozed item keeps its real state and its real driver` — snooze suppresses the notification, not the truth.
  - `a paused item is filtered out before the engine runs and produces no assessment` — `is_active == false` has no `DueState`; `assessEligible` returns false and `computeDueState` is never called.
  - `an untracked item is filtered out the same way` — `is_tracked == false` is invisible to the engine.
  - `progress is the greater of the two axes' fractions and is not capped at 1`.
- **Then build** — `lib/core/due/due_engine.dart`:
  ```dart
  final class DueAssessment {
    final DueState state;            // from lib/theme/calm/, six members, EPIC-02
    final DueDriver driver;
    final int? remainingMetres;
    final int? remainingDays;
    final int? dueAtOdometerMetres;
    final CivilDate? dueOn;
    final CivilDate? projectedDueDate;   // task 7.7 fills this
    final RateConfidence confidence;
    final double progress;
  }

  bool isEligible(ServiceItem item);   // is_tracked && is_active
  DueAssessment computeDueState(ServiceItem item, DueAnchor anchor,
      OdometerEstimate? estimate, NoticeWindow window, {required CivilDate today});
  ```
  Two private axis functions, each under 30 lines, each returning `(DueState, int? remaining)`;
  the combine is one `switch` over the pair. `progress` is the greater of
  `(estimate.metres − anchor.odometer) / (dueAtOdo − anchor.odometer)` and
  `(today − anchor.date) / (dueOn − anchor.date)`, floored at 0 and uncapped above — §3 says
  "the max of the two axes' fractions" and defines neither fraction (finding F-7.7); the
  definition goes in the `///` doc and in `SPEC.md` in the same PR.
- **Verify** — `dart test test/core/due/due_engine_test.dart`. A pass is 30+ green tests with every band boundary asserted from both sides. Then `dart analyze --fatal-infos lib/core/due/due_engine.dart` — a `switch` that is not exhaustive over `DueState` is a compile error and must stay one.
- **Done when**
  - [ ] Every band edge on both axes is asserted from both sides.
  - [ ] `paused` and `snoozed` are handled as a filter and a passthrough respectively, per `calm-due-state-and-status`, and neither appears in any enum.
  - [ ] Both `needs_odometer` triggers — 60-day stale and 180-day expired — have their own tests, and the time-axis override has one.
  - [ ] No widget, no provider, no Flutter import.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

---

### Task 7.7 — `projectDueDate`, `nextDue` and `dueSummary`

- **Goal** — one comparable sort key across both axes, and the two per-vehicle rollups every list in the app reads.
- **Spec** — §3 *The due engine* (`projected_due_date`); §3 *Derived values* (`nextDue`, `dueSummary`); §4.1.3 *From a rate to a projected date*; §8 *`vehicles` — the garage* (the status-dot table, which is `dueSummary`'s only consumer with a stated shape).
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`, `testing-strategy`, `calm-due-state-and-status`.
- **Write these tests first** — `test/core/due/project_due_date_test.dart`:
  - `takes the earlier of the time axis date and the distance projection` — both axes present.
  - `is the time date for a time-only item` and `is the distance projection for a distance-only item` — `min` is over the non-null axes only; a null `due_on` must not win the comparison.
  - `reproduces the SPEC §4.1.3 worked example` — Passat, oil 10,000 km / 12 months, last done 2026-02-10 at 108,200 km, last reading 2026-08-20 at 116,050 km, today 2026-09-02, rate 41 km/day → `projected_due_date` **2026-10-12**, `due_at_odometer_m` 118,200 km, time axis 2027-02-10, driver `distance`. This single test is the epic's anchor: if it moves, something in tasks 7.1–7.6 moved.
  - `rounds the day count up, never down` — 52.4 days is 53 days; a projection that lands the user at the garage after the threshold is the failure mode.
  - `returns a date in the past for an already-overdue distance axis` — it is a sort key, not a promise.
  - `still produces a sort key at confidence default` — §4.1.4 forbids *showing* the date, not computing it; the hedging is the UI's job.
  - `test/core/due/next_due_test.dart`:
  - `nextDue is the minimum projected_due_date over tracked, active items`.
  - `nextDue ignores untracked, paused and snoozed-into-the-future items` — snoozed items keep their state but §3 scopes `nextDue` to tracked and active.
  - `nextDue is null on a vehicle with no eligible items, and never a far-future sentinel date`.
  - `test/core/due/due_summary_test.dart`:
  - `counts each state once per eligible item` — a `Map<DueState,int>` over the six members.
  - `names the worst item so a caller can render "Oil and filter overdue"` — §8's third line needs the label, not only a count (finding F-7.8).
  - `orders equal severities by projected_due_date, then by priority safety before normal before low`.
  - `a needsOdometer item never takes the worst slot below a time-driven due or overdue` — the `calm-due-state-and-status` rule: an accusation the app can support beats one it cannot.
- **Then build** — `lib/core/due/project_due_date.dart` and `lib/core/due/due_summary.dart`.
  `projectDueDate` uses §3's formula — `min(due_on, last_reading.date + ceil((due_at_odo − cumulative(last_reading)) / rate))` — over the non-null axes; §4.1.3's `today`-based form is algebraically the same and is not implemented twice.
  `DueSummary({required Map<DueState,int> counts, DueAssessment? worst, ServiceItem? worstItem})`
  extends §3's "status counts" with the worst item because §8's garage row cannot be built
  from counts alone; the added field goes into `SPEC.md` §3 *Derived values* in the same PR.
- **Verify** — `dart test test/core/due/`. A pass is every test in the epic green, with the Passat example printing the §4.1.3 numbers when run through `dart run tool/due_report.dart test/core/due/fixtures/passat.json`.
- **Done when**
  - [ ] The §4.1.3 worked example passes with every one of its five published numbers.
  - [ ] `min` over a null axis is proven not to select the null.
  - [ ] `dueSummary` returns enough to render §8's five status-dot rows, and a test asserts each row's third line input.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 7.8 — The fixture matrix: 21 committed vectors

- **Goal** — the specification, executable: every axis-mode × status combination pinned as data a reviewer can read without opening Dart.
- **Spec** — §3 *The due engine* in full; §4.1 in full; §17 *Definition of done for v1*.
- **Skills** — `seeded-determinism-and-golden-vectors`, `testing-strategy`, `dart3-idioms-and-coding-standards`.
- **Write these tests first** — `test/core/due/due_matrix_test.dart` is one parameterised suite over `test/core/due/fixtures/due_matrix.json`. Each fixture carries `{name, vehicle, item, readings, records, today}` and a full `expect` block — `status`, `driver`, `remaining_m`, `remaining_days`, `due_at_odometer_m`, `due_on`, `projected_due_date`, `confidence`, `progress` — and the fixture's `name` **is** the test name. The 21 rows:

  | | `ok` | `due_soon` | `due` | `overdue` | `unknown` | `needs_odometer` | `paused` |
  |---|---|---|---|---|---|---|---|
  | **distance-only** | `distance-only × ok` | `distance-only × due_soon` | `distance-only × due` | `distance-only × overdue` | `distance-only × unknown` | `distance-only × needs_odometer` | `distance-only × paused` |
  | **time-only** | `time-only × ok` | `time-only × due_soon` | `time-only × due` | `time-only × overdue` | `time-only × unknown` | `time-only × needs_odometer` | `time-only × paused` |
  | **both** | `both × ok` | `both × due_soon` | `both × due` | `both × overdue` | `both × unknown` | `both × needs_odometer` | `both × paused` |

  Three of those rows are assertions about the *absence* of an assessment and must be written as such, not skipped: `time-only × needs_odometer` asserts the item reports its real time status because time never needs an odometer, and the three `paused` rows assert `isEligible == false` and that `computeDueState` was not called. Plus two fixed vectors outside the matrix: `passat — the SPEC §4.1.3 worked example` and `second-hand car with a service book reports unknown, never overdue` (§14).
- **Then build** — `test/core/due/fixtures/due_matrix.json`, hand-authored from `SPEC.md` §3 and §4.1 — **not** dumped from the implementation, which would pin whatever the code happens to do. `tool/regenerate_due_vectors.dart` exists to reformat and to diff the file against current behaviour, and it writes only under `--bless`; CI runs it without the flag and fails on a diff. `seeded-determinism-and-golden-vectors` rule: a gate never regenerates what it checks.
- **Verify** — `dart test test/core/due/due_matrix_test.dart` — 23 named cases green. Then `dart run tool/regenerate_due_vectors.dart` (no flag) exits 0 with no diff. Then break one threshold by hand — change `kNoticeDaysCeiling` to 31 — and confirm at least three named rows go red; restore it.
- **Done when**
  - [ ] All 21 matrix rows exist as named cases, including the three `paused` absence rows.
  - [ ] Every fixture asserts the whole assessment, not only `status`.
  - [ ] The fixture file was written from `SPEC.md`, and the PR body says so.
  - [ ] `--bless` is the only way to write the file, and CI does not pass the flag.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 7.9 — Clock-suspect mode, and the recompute entry point

- **Goal** — a phone whose date is wrong stops producing due states instead of producing confident wrong ones, and every §4.2 trigger has one function to call.
- **Spec** — §3 *Invariants and validation* (*The device clock is not trusted*); §14 *Device clock wrong*; §4.2.1 *Triggers*.
- **Skills** — `value-objects-money-and-units`, `error-handling-typed-results`, `dart3-idioms-and-coding-standards`, `testing-strategy`, `flutter-architecture`.
- **Write these tests first** — `test/core/due/clock_suspicion_test.dart`:
  - `a today before build_date is clock-suspect` — the 1970 phone.
  - `a today ten years and one day after build_date is clock-suspect`.
  - `a today inside the window is trusted` — both boundaries asserted.
  - `in clock-suspect mode every item reports unknown regardless of its intervals` — §3's consequence, applied uniformly.
  - `in clock-suspect mode no projected_due_date is produced` — nothing to schedule against.
  - `a today two days after the newest created_at is not clock-suspect` — refutes §14's second clause, which would make every user who opens the app on Wednesday having last opened it on Monday clock-suspect (finding F-7.9).
  - `test/core/due/vehicle_due_snapshot_test.dart`:
  - `recomputeVehicle returns one assessment per eligible item and nothing for the ineligible ones`.
  - `recomputeVehicle is pure: the same inputs give the same output and nothing is written` — call it twice, assert identical values and no repository interaction.
  - `recomputeVehicle on five vehicles with sixteen items each completes in under 50 ms` — §4.2.1's "80 rows of arithmetic; recompute everything, always". A performance assertion, so nobody builds incremental invalidation later.
- **Then build** — `lib/core/due/clock_suspicion.dart` with
  `ClockSuspicion assessClock({required CivilDate today, required CivilDate buildDate})`,
  implementing §3's `[build_date, build_date + 10 years]` window and §3's consequence (every
  due state renders `unknown`). §14 states a different trigger and a different consequence
  (`confidence` drops to `assumed`); the two cannot both hold, §3 owns the domain contract, and
  §14's clause is unusable as written — amend §14 in this PR (F-7.9).
  Then `lib/core/due/vehicle_due_snapshot.dart` with
  `VehicleDueSnapshot recomputeVehicle(Vehicle, List<ServiceItem>, List<ServiceRecord>, ReadingSeries, Settings, {required CivilDate today})`
  — the single pure entry point every §4.2.1 trigger calls. It computes the rate once and the
  estimate once for the whole vehicle, not once per item.
- **Verify** — `dart test test/core/due/`; the whole epic green. Then `dart test test/core/due/vehicle_due_snapshot_test.dart --reporter=expanded` and read the timing line — the 80-row recompute is well under 50 ms or the "recompute everything, always" decision is not affordable and that is a finding, not a licence to cache.
- **Done when**
  - [ ] Clock-suspect uses §3's window, and §14's contradictory clause is corrected in `SPEC.md` in this PR.
  - [ ] Every §4.2.1 trigger row has one function to call and a comment naming the row.
  - [ ] The purity test asserts no write and identical repeat output.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

## Spec findings raised by this epic

These are recorded here because the tasks above act on them. Each is either fixed in this
epic's PR or carried as a written answer.

| Id | Finding | Handling |
|---|---|---|
| F-7.1 | §3's `from_due` walk takes the smallest `k ≥ 1` giving a date **after** the completing record, then adds another interval — putting the next due a full cycle late. Worked counter-example: inspection, 12 mo, baseline 2024-06-01, done 2026-07-14 → spec gives 2028-06-01, intent is 2027-06-01. | Corrected in task 7.4 and amended in `SPEC.md` in the same PR. |
| F-7.2 | §14 *Odometer not updated for months* says extrapolation stops at **60 days**; §3 and §4.1.3 both say **180**, and 60 is the separate `needs_odometer` threshold. | §3 and §4.1 win (two statements against one, and §2 forbids the body contradicting itself). §14's line is corrected in this PR. |
| F-7.3 | §3's `estimateOdometer` pseudocode assigns `is_projected = expired` — a bool holding a third value. | Modelled as `enum OdometerProjection { entered, projected, expired }` in task 7.3. |
| F-7.4 | `dailyDistance(readings, today)` in §3 versus `dailyDistance(vehicle)` in §4.1.2. | The readings form is implemented; `expected_annual_m` is a parameter. Noted in the `///` doc. |
| F-7.5 | `resolveAnchor` returns one anchor, but a rung can supply a date without an odometer (`baseline_date` with `baseline_odometer_m` null, or a `ServiceRecord` with a null `odometer_m`). | Rungs resolve per axis in task 7.4; recorded in `SPEC.md` §3 in the same PR. |
| F-7.6 | §3 defines `grace_m` and `grace_days` as "the notice-window formula, same clamp" without saying whether a user override feeds the grace as well as the notice. | Grace is the computed default and ignores overrides; stated in the `///` doc and in the PR body. |
| F-7.7 | `DueState.progress` is "0..1+, the max of the two axes' fractions" and neither fraction is defined. | Defined as anchor-to-due elapsed fraction on each axis in task 7.6, and added to `SPEC.md`. |
| F-7.8 | §3 defines `dueSummary(vehicle)` as "status counts for Home", but §8's garage row needs the worst item's label ("Oil and filter overdue"). | `DueSummary` carries `worst` and `worstItem`; added to §3 *Derived values*. |
| F-7.9 | §3 and §14 give clock-suspect mode two different triggers and two different consequences, and §14's "more than 24 hours ahead of the newest `created_at`" fires for any user who skips a day. | §3's window and consequence implemented; §14 corrected in this PR. |

## Definition of done

- [ ] `lib/core/due/` contains `reading_series.dart`, `daily_distance.dart`, `estimate_odometer.dart`, `resolve_anchor.dart`, `notice_window.dart`, `due_engine.dart`, `project_due_date.dart`, `due_summary.dart`, `clock_suspicion.dart` and `vehicle_due_snapshot.dart`, and imports no Flutter.
- [ ] `test/` mirrors it 1:1, and `test/core/due/fixtures/due_matrix.json` holds 21 matrix rows plus the two fixed vectors.
- [ ] Every threshold in §2's projection rule and §3's due engine appears exactly once in `lib/` as a named `const`, and a test would fail if it changed.
- [ ] The §4.1.3 Passat worked example passes with all five of its published numbers.
- [ ] `grep -rn "DateTime.now()" lib/core/` is empty; every function takes `today`.
- [ ] All nine spec findings above are either fixed in `SPEC.md` in this PR or answered in writing in the PR body.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-07.md`.** It starts
empty. Append one line per task as it completes — what was built, what was deferred, and
anything the next epic needs to know. It is the running log for this epic and the handover to
the next one.
