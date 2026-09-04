# EPIC-07 — the due engine and projection

Branch `epic/07-the-due-engine`. One line per task, then the spec findings and
the handover.

## Tasks

- **7.0 CivilDate** — zoneless date, integer `days_from_civil` arithmetic with no `DateTime` on the path. Built because EPIC-07's inherited-state list claimed EPIC-06 had built it and EPIC-06 never did. The first version used `DateTime.utc`; mutating the `.utc` away passed the whole file under `TZ=UTC`, which is CI's zone, so the design changed rather than the tests. Century-boundary cases added after a mutation survived the 12-year sweep.
- **7.1 ReadingSeries** — SPEC §4.1.1's three normalisation steps, reusing EPIC-06's `cumulativeByReading` for corrections. Two findings written into the code: an expense contributes to the odometer LOG but not the RATE series (the data layer's fan-out and §4.1.1's table are both right, and `rateSeriesSources` is where they meet), and step 3's ">= 1 day" rule is unreachable given step 1 — mutating it to `>= 0` passes the suite, which is stated at the line with an assert rather than left looking load-bearing.
- **7.2 dailyDistance** — four rungs, each with its confidence; the clamp bounds the number and never demotes the confidence. SPEC's worked Passat example is a test. SPEC's "earliest in window / latest overall" phrasing turned out to describe one list, not two — the window has no upper bound — so the parameter no input could distinguish was collapsed, with a note against restoring it.
- **7.3 estimateOdometer** — the projection STOPS past 180 days rather than decaying: it hands back the last figure the user typed and the day they typed it, and no field on the record holds what the projection would have said, because a screen that can find such a field will render it. Three members rather than SPEC's `is_projected = expired` bool. Null and not zero for a vehicle with no readings — zero is a real odometer on a car delivered yesterday.
- **7.4 resolveAnchor** — four rungs, resolved INDEPENDENTLY per axis so a baseline date with no baseline odometer does not collapse the item to `unknown` (§14's second-hand car). SPEC's `from_due` walk was corrected here — see the findings table below. A mutation found that a record dated before its own baseline anchored on a future date; the guard has a test now.
- **7.5 noticeWindow** — notice is warning, grace is forgiveness, and an override moves only the first. Four resolution levels per axis. The rounding is DEFENSIVE and the file says so with the sweep numbers: no realistic input distinguishes it from truncation on either axis, and the comment names the ceiling value at which the twelve-month case would start caring.
- **7.6 computeDueState** — the two axes, every band edge asserted from both sides, and both `needs_odometer` triggers (60-day stale, 180-day expired) with the time-axis override. `progress` was defined in SPEC here; it had been "the max of the two axes' fractions" with neither fraction defined.
- **7.7 projectDueDate / nextDue / dueSummary** — one sort key across two axes, `min` over the axes that EXIST so a null `due_on` cannot win, and the day count rounded UP. `dueSummary` carries the worst ITEM because §8's garage row reads "Oil and filter overdue" and counts cannot say "Oil and filter".
- **7.8 the fixture matrix** — 29 rows, hand-authored from SPEC via an independent Python implementation of §3 and §4.1 rather than dumped from the Dart, so agreement is evidence and not tautology. It reproduced §4.1.3's five published Passat numbers on the first run.
- **7.9 clock suspicion and recomputeVehicle** — one trigger, one consequence, and the single pure entry point every §4.2.1 trigger calls. §4.2.1's 80 rows recompute in **591 microseconds** against the 50 ms budget, so "recompute everything, always" is measured rather than assumed.

## The nine spec findings the epic raised

All nine are fixed in `SPEC.md` in this PR or answered at the call site. Four
were spec CHANGES, each in the same commit as the code that depends on it.

| Id | Finding | Handling |
|---|---|---|
| F-7.1 | §3's `from_due` walk took the smallest `k ≥ 1` giving a date AFTER the completing record, putting every renewal a full cycle late | **SPEC changed.** Inspection, 12 mo, baseline 2024-06-01, done 2026-07-14 gave anchor 2027-06-01 and due 2028-06-01, on the class of item whose whole purpose is a legal deadline. Corrected to the largest `k ≥ 0` on or before the record |
| F-7.2 | §14 said extrapolation stops at 60 days; §3 and §4.1.3 say 180 | **SPEC changed.** 60 is the separate `needs_odometer` threshold in the very next row — two thresholds, two jobs, one number written for both |
| F-7.3 | §3's pseudocode assigns `is_projected = expired`, a bool holding an enum | Modelled as `OdometerProjection { entered, projected, expired }` |
| F-7.4 | `dailyDistance(readings, today)` in §3 versus `dailyDistance(vehicle)` in §4.1.2 | The readings form; the pure core cannot hold a `Vehicle`. Noted in the doc |
| F-7.5 | A rung can supply a date without an odometer | Rungs resolve per axis; §14's second-hand car is a test |
| F-7.6 | §3 does not say whether a notice override feeds the grace | Grace is the computed default and ignores overrides — a user who asks to be told earlier has not asked to be forgiven longer |
| F-7.7 | `progress` is "the max of the two axes' fractions" with neither fraction defined | **SPEC changed.** Defined as anchor-to-due elapsed fraction per axis, floored at 0 and uncapped above |
| F-7.8 | §3's `dueSummary` is "status counts", but §8's garage row needs the worst item's label | **SPEC changed.** `DueSummary` carries `worst` and `worstItem` |
| F-7.9 | §3 and §14 gave clock-suspect mode two triggers and two consequences | **SPEC changed.** §14's trigger fired for anyone who opened the app on a Wednesday having last used it on a Monday |

## What the mutation sweeps found in my own work

Three times a test or a gate was green against the thing it was written to catch.

- **`CivilDate` went through `DateTime.utc`** — correct, and still the wrong
  design. Mutating the `.utc` away and running under `TZ=UTC`, which is CI's
  zone, passed every test in the file. The fix was to remove `DateTime` from the
  code path entirely rather than to write a better test.
- **The 12-year sweep contains no century boundary**, so deleting the
  `~/ 100` term from the epoch arithmetic passed all 4,383 days.
- **The 21-row matrix pinned states and not thresholds.** The epic's own
  verification step — change `kNoticeDaysCeiling` to 31 and confirm three rows go
  red — turned up zero. No row sat on an edge. Four boundary rows fixed it, and
  the first draft of the DISTANCE ones proved nothing either, because a 10,000 km
  interval computes exactly 1,000,000 m of notice and never touches the clamp.

## /simplify — every finding, applied or answered

Four agents over `git diff main...HEAD`. **Applied: 18. Answered without
applying: 3.** The passes found two real bugs and one gate that was checking a
different scenario from the test it backs.

### Bugs

| Finding | What was wrong |
|---|---|
| `VehicleDueSnapshot.props` encoded each assessment through `toString()`, which prints only state and driver | Two snapshots differing in every number compared EQUAL, and `valuesEqual` is the `distinct` predicate on the watch streams — the home screen would not have rebuilt when only the numbers it renders had changed |
| `computeDueState` hardcoded `confidence: measured` and left `projectedDueDate` null for one caller to patch | The golden file's confidence column was a transcript of two literals. It takes the rate and the series now, and a new fixture row — readings 13 days apart, one short of §4.1.2's minimum — is the first where readings EXIST and the confidence is still `default` |
| `nextDue`'s `today` was optional, and the default disabled the snooze filter | The unsafe direction on a function whose obvious second caller is EPIC-11's scheduler: omitting it fires reminders for items the user has deferred |

### Duplication — the fourth and fifth instances in three epics

`CivilDate` wrote `days_from_civil` and its inverse for a job
`lib/core/l10n/jalali.dart` had been doing since EPIC-04 with Fliegel-Van
Flandern. They agree over 100,000 consecutive days with zero mismatches, which is
the good outcome; the bad one is a repo where two day counts disagree somewhere
nobody looked. Unified into `lib/core/time/julian_day.dart`, and each suite's
tests now cover the other's path.

`wholeDaysBetween` was the third. Its one caller did
`DateTime.parse(fromDate)` on a `YYYY-MM-DD` string — the exact construction
`CivilDate` was written to remove, kept alive by the helper that worked around
it. Deleted.

**Neither was catchable by the one-type gate**, because they share no name, no
signature and no file. Nothing greps for "the same arithmetic spelled
differently", and that is worth knowing before the next epic assumes the gate
covers this class.

### The benchmark measured neither term that scales

The affordability test ran with an empty record list and two readings, so it
exercised neither `items x records` in `resolveAnchor` nor the sort in
`ReadingSeries`. Its own comment promised it could produce a finding; it could
not. It now runs a decade — 5 vehicles, 16 reminders, 200 records, 1,000 readings
— in **1 ms**, and removing the record index it prompted costs 3 ms.

### Two orderings of one enum

`axisSeverity` ("which axis is worse") and `attentionRank` ("which item do I name
first") are genuinely different questions and were two unnamed private functions,
only one of which explained itself. Named, documented in terms of each other, and
guarded by three tests: they disagree exactly where designed, they AGREE on the
strict ordering they share, and `attentionRank` is total. EPIC-11's notification
ranking and EPIC-12's home sort are the next consumers.

### The gate and the test computed the same row differently

`due_matrix_test.dart` and `tool/regenerate_due_vectors.dart` each decoded the
fixture into a scenario. **They had already drifted** — the test honoured
`is_active` and the tool did not, so the gate skipped every `paused` row. One
`test/support/due_case.dart` now serves both; the tool drops 176 lines to 89 and
the gate checks the absence rows for the first time.

### Answered, not applied

**`Distance` should replace the raw `int` metres on five of the epic's value
types.** `DueAnchor.odometerMetres`, `OdometerEstimate.metres`,
`DueAssessment.remainingMetres` / `dueAtOdometerMetres` and `NoticeWindow`'s two
windows are `int` while `OdometerPoint.cumulative` in the same epic is a
`Distance`. The finding is right and the cost is six public fields across five
files plus the fixture JSON boundary and most of the due tests, for no
behavioural change. **Deferred deliberately, and it is in the Deferred list
below** — the next epic that consumes these types inherits the convention, so it
should be decided rather than drifted into. `DailyDistance.metresPerDay` is a
RATE and correctly stays an `int`.

**`DueSummary.worst` and `worstItem` should be one `AssessedItem?`.** True: the
type admits a state `dueSummary` cannot produce. Skipped because the two fields
read better at every call site (`summary.worst?.state` against
`summary.worst?.$2.state`), the invariant is enforced by the only constructor,
and §8's garage row is the consumer — merging them makes the spec-facing shape
worse to buy an unreachable state's absence.

**Nine test files each declare `day()`, `reading()` and the ULID constant.** Real
duplication, and `test/support/due_case.dart` now covers the matrix half of it.
The rest is per-file fixture preamble whose shapes genuinely differ (nullable
dates in `resolve_anchor_test`, indexed suffixes in `vehicle_due_snapshot_test`),
and collapsing it would make each test read further from what it asserts. Left
as it is.

## /code-review — every finding, applied

Fifteen findings. **All fifteen applied; none answered-without-applying.** Four
were verified by running the code before anything changed. The pass paid for
itself on the first finding alone.

### Reachable defects

| # | Finding |
|---|---|
| 1 | `ReadingSeries.from` took `CivilDate.tryParse(date)!` on a value the SCHEMA permits — `occurred_on`'s only constraint is a GLOB on the shape, so `2026-02-30` passes it. One such row in a backup imports cleanly and then throws on every app foreground: **the home screen never renders again and the user cannot reach the data to fix it** |
| 2 | `_isSnoozed` implemented half of SPEC §3's definition, ignoring `snooze_until_odometer_m` — so an item snoozed "after another 500 km" stayed the next thing due, and EPIC-11's scheduler would fire the reminder the user had just deferred |
| 3 | An EXPIRED estimate still produced a firm `projectedDueDate`, extrapolated from the same reading §4.1.3 calls invention — and that date became `nextDueOn` |
| 4 | `worseOf` was not commutative on a tie and resolved it backwards: `needsOdometer` beat `dueSoon`, the exact opposite of the rule its own doc states |
| 5 | `_driver` compared severities rather than states, reporting "both axes agree" for a state only one axis had reached |
| 6 | The `unknown` branch hardcoded `confidence: defaulted` and discarded a knowable `dueAtOdometerMetres` — the same defect fixed one function away in the same branch |
| 7 | `CivilDate.tryParse` accepted `'+026-01-03'` and `'2026-+1-03'` as different valid dates, because `int.tryParse` takes a sign and whitespace |
| 8 | `addMonths` computed the wrong year below year 0: `~/` truncates toward zero while `%` floors |
| 9 | In clock-suspect mode the snapshot still published a rate and an estimate computed from the date it had just decided not to believe |

### Gates and tests

| # | Finding |
|---|---|
| 10 | **A self-test arm labelled "a planted violation" asserted the gate stays GREEN on it.** `state == DueState.overdue ? red : green` in a widget is what `check_status_encoding.sh` exists to prevent; its pattern matched `switch` and not `==`, and rather than closing the hole I wrote a permanent assertion that the bypass is allowed |
| 11 | The due-matrix CI gate shipped with **no self-test arm**, in the same branch that added one for the step directly above it |
| 12 | The affordability benchmark's 1,000 readings carried 900 distinct ids, so 100 overwrote each other and it measured a series whose values were not what it claimed |

### Structural

| # | Finding |
|---|---|
| 13 | `computeDueState` had gone back to building `DueAssessment` twice — the shape `vehicle_due_snapshot.dart` was changed to stop doing two commits earlier |
| 14 | `_distanceAxis`/`_timeAxis` re-derived `hasDistanceAxis`/`hasTimeAxis`, which the model declares for exactly this consumer and nothing else used |
| 15 | `_anchorDate`'s cycle walk was an unbounded `while (true)`; a corrupt baseline is ~24,000 calendar conversions per item per recompute. Also `--bless` skipped rows whose eligibility changed, and counted FIELDS as rows |

### What the two passes together say

`/simplify` found two bugs and `/code-review` found nine. Three of the fifteen
were in code written **during this branch to fix that same class of thing** —
the double construction, the `unknown` branch's hardcoded confidence, and the
self-test arm that blessed a hole while closing another. Fixing a defect is when
its neighbours are most likely to be introduced.

Finding 1 is the one to remember: a `!` on a parse of a value the database
permits. The schema constrains the SHAPE of `occurred_on` and nothing constrains
its meaning, so every `YYYY-MM-DD`-shaped string that is not a date is a row the
app must survive.

## Deferred

- **`Distance` on the due engine's public fields.** See the answered finding
  above. The next epic to consume `DueAnchor`, `OdometerEstimate`,
  `DueAssessment` or `NoticeWindow` inherits raw `int` metres, and should decide
  deliberately whether to keep them.
- **`lib/core/time/completed_months.dart` still has its own `_daysIn` and month
  arithmetic**, which `CivilDate.daysInMonth` and `addMonths` now duplicate. Its
  own header predicted this file would be the one the due engine reused, and the
  reuse went the other way. One small refactor, no behaviour change, and no
  caller of `completedMonthsBefore` exists yet — so it belongs to whichever epic
  first needs a monthly cost figure.
- **The domain models still store `occurredOn` as a `String`.** `CivilDate` is
  the type, and moving the models onto it touches EPIC-05's mappers, the backup
  writer and the import validator. The DB column stays `TEXT` either way, so
  nothing gets more expensive by waiting.
- **`SPEC.md` §18 question 25** (the Calm contrast failures) is untouched and
  still EPIC-17's. No screen was built here.
