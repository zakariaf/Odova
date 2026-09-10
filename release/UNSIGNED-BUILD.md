# Building 1.0.0+1 over an unsigned design review

| | |
|---|---|
| **Date** | 2026-09-10 |
| **Decided by** | Zakaria Fatahi, owner |
| **Overrides** | `design/review/SIGNOFF-2026-09-08.md`, which reads **NOT SIGNED** |
| **Scope** | Build and upload 1.0.0+1. **Not** submission for review. |

## Why this exists rather than a signature

`tools/release.sh` refused to build while the design review was unsigned, and
the sign-off could not be earned without a build. Item 4 of its own *What must
happen before this can be signed* is:

> Run `design-review-workflow`'s four lenses **on a release build** at the
> largest text scale, and produce `design/review/shots/`.

and its **Build flavour** row reads *"none — debug widget captures only. No
release build was made and none was looked at."* Neither side could move first.

The gate was therefore re-aimed rather than removed, and rather than cleared by
editing `NOT SIGNED` to `SIGNED OFF` — which would have taken one `sed`, cost
nothing, and put a false statement in the only record of what was actually
reviewed. An unsigned review still refuses to build. It refuses **unless this
file exists**, so the decision is a tracked diff somebody can read rather than a
flag somebody passed.

## What is knowingly unfinished

Carried verbatim from the sign-off, so this file is not a summary that drifts:

1. **108 of the 112 parity sheets have never been read by a person.** The four
   that were read produced two BLOCKERs, nine FIXes and five NOTEs, and not one
   of the sixteen was found by the three automated checks.
2. **The band profile fails 106 of 112 comparisons, median 53%**, cause not
   established.
3. **`costs.fuel` is an unfinished screen.** The unit label, tank-count line,
   This-tank/Best/Worst figures, range chip, both axis labels, the legend and
   the whole price trio are absent — the widget has no code for any of it.
   It is one of the ten store screenshots.
4. **Dark modal screens paint `#000000` under the scrim** where the composite
   should be `#0F0C0A` (F-8).
5. **`design/calm/A11Y-SIGNOFF.md` lists eight human passes, all not done** —
   VoiceOver, Switch Access, three native RTL reads, colour-vision simulation
   and 200% on a real device. **Sorani remains the largest single risk to the
   RTL launch**, with EPIC-15's 103 unreviewed strings behind it.

## What this decision does not authorise

Uploading a build is not shipping one. The version is `releaseType: MANUAL`, it
sits in `PREPARE_FOR_SUBMISSION`, and nothing here submits it for review — that
is a separate act, and the sign-off is the gate on it. The build exists so that
items 3 and 4 above can finally be done against the artifact users would get.

**Build number 1 is spent either way.** A published build number can never be
reused, which is the one irreversible thing in this file.
