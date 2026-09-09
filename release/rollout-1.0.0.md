# Rollout plan — 1.0.0

Written **before** the rollout starts, which is the only time it can be written
honestly. A halt criterion invented while watching a crash graph is a criterion
that moves.

| | |
|---|---|
| **Version** | 1.0.0+1 |
| **Method** | App Store **phased release** — 7 days, automatic |
| **Watcher** | Zakaria Fatahi |
| **Written** | 2026-09-09 |

## The criterion

**Pause the phased release if crash-free sessions fall below 99.0%** over any
rolling 24 hours with at least 50 sessions, or on any single confirmed report of
data loss — a user whose service history is missing or whose backup will not
import.

The session floor matters. Day one of a phased release is 1% of users, which on
a new listing is a handful of people; one crash out of three sessions is 67%
crash-free and means nothing.

**Data loss is a halt on n=1.** SPEC.md §1: "Losing eight years of service
history is the worst bug this app can have." There is no threshold at which one
of those is acceptable, and unlike a crash it does not show up in a crash graph
at all — it arrives as an email.

## The halt is a pause, not a rollback

This is the difference the platform decision made, and it changes what the plan
has to contain.

A staged Play rollout can be halted at 1% and the previous build stays live. **An
approved iOS build cannot be un-shipped** — pausing the phased release stops it
reaching *more* users, but everyone who already has it keeps it, and the only
way back is a new build that must itself pass review.

So the lever is: **pause, then expedite.**

1. Pause the phased release in App Store Connect. This is immediate and needs no
   review.
2. Fix, on a branch, with a test that fails on the reported defect first.
3. Submit 1.0.1 with an **expedited review request**, citing the user-facing
   defect. Expedited review is a limited favour — Apple grants few per year —
   and this is what it is for.
4. Resume or supersede once 1.0.1 is approved.

Step 3 is named here rather than discovered under pressure, because the request
form asks for a justification and the honest one is easier to write before the
incident than during it.

## Where the numbers come from

App Store Connect's own crash reporting, which is opt-in per user and therefore
**incomplete by construction**. Odova ships no crash reporter of its own — §2
refuses one, and that is not being revisited for a rollout. The plan accounts
for that by treating the email as the primary signal for data loss and the graph
as secondary.

Symbols for `1.0.0+1` are in `build/symbols/1.0.0+1/`, archived off-machine
before upload. Without them an obfuscated crash report is unreadable, for the
life of the build.
