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

