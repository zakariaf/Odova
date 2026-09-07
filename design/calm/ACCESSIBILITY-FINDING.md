# Calm: two WCAG failures in the light theme — CLOSED 2026-09-07

> **RESOLVED. See `## Resolution — 2026-09-07` at the foot of this file.**
> Everything above that section describes the state BEFORE the fix and is kept
> as the record of what was found and why. The ratios in the tables below are
> the OLD ones; they no longer describe the palette.
>
> It was also worse than this document says. Two of the failures it calls
> light-theme-only fail in DARK as well, and a fourth failure — the focus ring
> — is not mentioned here at all. Both were found by
> `test/theme/calm/calm_contrast_test.dart` in EPIC-02 and are closed by the
> same change.

Found by reading the system closely while writing the skills, and confirmed by
independent contrast computation. Both are **light-theme only**; dark is fine.

## 1. `--color-ink-3` is not a legal text colour

`#8B7B6C`, used as `color:` in **47 rules** in `design/calm/odova.css`, 25 of them at
`--fs-caption` 13px or `--fs-label` 14px. WCAG 1.4.3 needs 4.5:1 below 18.66px.

| on | ratio | verdict |
|---|---|---|
| `--color-bg` #F8F2E9 | 3.67 | FAIL |
| `--color-surface` #FFFCF7 | 3.99 | FAIL |
| `--color-surface-2` #F3EADC | 3.42 | FAIL |
| `--color-surface-3` #E9DCC9 | 3.02 | FAIL |

Affected: `.odostrip__meta`, `.duecard__anchor`, `.allclear__meta`, `.timeline__meta`,
`.barrow__share`, `.chart__axis-label`, `.row__sub`, `.section__hint` and others.

### Candidates (hue 29°, saturation held)

| candidate | bg | surface | surface-2 | surface-3 | clears AA |
|---|---|---|---|---|---|
| `#8B7B6C` | 3.67 | 3.99 | 3.42 | 3.02 | no |
| `#7E6E5F` | 4.41 | 4.79 | 4.11 | 3.63 | no |
| `#776758` | 4.88 | 5.31 | 4.56 | 4.02 | 3 of 4 |
| `#6B5F53` | 5.57 | 6.06 | 5.20 | 4.59 | all four |

**`#6B5F53` is the only one that clears all four surfaces.** `#7E6E5F` — the value the
skill originally proposed — clears three and fails `--color-surface-3` at 3.63.

## 2. `--color-ink-4` is used for placeholder text

`#AC9C8B` is 2.60:1 on `--color-surface` and 2.39:1 on `--color-bg` —
below even the 3:1 non-text floor. `odova.css:1694-1695` applies it to
`.input::placeholder` / `.textarea::placeholder`. Placeholders are not exempt from
1.4.3 the way disabled controls are.

Its other uses — `.row__chev`, `.is-disabled` — are defensible. Only the placeholder
use is a failure. Fix: point placeholders at the corrected `--color-ink-3`.

## What it costs to fix

Two token values in `design/calm/odova.css`, one line each. Then `screens.html` is
regenerated and all **336 reference PNGs re-shot** (about 4 minutes).

## The tradeoff, stated honestly

Darkening tertiary text reduces the softness that is part of why Calm reads as calm.
`#6B5F53` on the airiest surfaces is noticeably more present than `#8B7B6C`. That is a
design judgement, not an engineering one — which is why this is a finding and not a
commit. The alternative is to keep the value and never place tertiary text on
`--color-surface-3`, which fixes three of the four cases and needs `#776758`.


---

## Decision — 2026-09-03

**Taken by:** the engineer building EPIC-02 (Calm tokens and theme), as
`epics/EPIC-02-calm-tokens-and-theme.md` task 2.8 requires one of its two paths
to be complete before the epic is.

**The decision: ship knowingly, and hand the design judgement to EPIC-17.**

`CLAUDE.md` §9 already assigns this finding's closure to EPIC-17, and this
document says in its own words that the remedy "is a design judgement, not an
engineering one — which is why this is a finding and not a commit". Nobody
building the token layer is in a position to trade Calm's softness for contrast
on the designer's behalf. So the values are unchanged and the failures are
recorded as **dated, executable exceptions** in
`test/theme/calm/calm_contrast_test.dart` rather than left implicit.

That test does three things a note in a document cannot:

1. It asserts every other declared pair still clears its threshold, so this
   finding cannot grow quietly.
2. It asserts each exception **still fails, at the exact ratio it was written
   against**. The day `--color-ink-3` is darkened, the test goes red with
   *"light ink3 on bg measures 5.57:1, not the 3.67:1 this exception was
   written against — delete the exception"*. An exception that silently goes
   stale is how a fixed bug gets recorded as permanent.
3. It refuses `--color-ink-4` to anything outside the token layer, which is the
   only enforcement available until EPIC-03 builds the field whose placeholder
   is the non-exempt use.

### Two things this document does not say, found by writing the test

- **`--color-ink-3` also fails in dark.** This document calls the finding
  "light-theme only; dark is fine". It is not: `ink3` on `--color-surface-2` is
  **4.39:1** and on `--color-surface-3` is **3.84:1**, both under 4.5. The
  light/dark asymmetry is smaller than stated, which strengthens the case for
  changing the value rather than avoiding `surface-3`.
- **`--color-focus` is 2.82:1 on `--color-surface-3`**, below SC 1.4.11's 3:1
  for a focus indicator. A control inside a `surface-3` container gets a focus
  ring the user cannot see. EPIC-17 has to take this one alongside `ink-3`, or
  fixing the text colour leaves the keyboard-only user no better off.

### What it costs to decide, over time

| When | Cost |
|---|---|
| Now (EPIC-02) | Two hex values, `node tools/build_screens.mjs && node tools/shoot_design.mjs && node tools/optimise_png.mjs`, ~4 minutes. **No app code changes — no screen exists yet.** |
| After EPIC-15 | The same, plus re-running `calm-visual-parity` over all 28 built screens × 4 combinations. |

The curve is steep and it points at deciding early. Filed as `SPEC.md` §18
question 25.


---

## Resolution — 2026-09-07

**Taken by:** the repository owner, asked directly during EPIC-17 task 17.2 and
answered with the option below. The 2026-09-03 decision handed this judgement
forward on the grounds that "nobody building the token layer is in a position
to trade Calm's softness for contrast on the designer's behalf". That is still
true, so it was put to the person who is.

**The decision: fix the tokens, and re-shoot the reference set in the same PR.**

Seven values moved. Four of them are failures this document does not describe.

| token | theme | from | to | worst ratio | needs |
|---|---|---|---|---|---|
| `--color-ink-3` | light | `#8B7B6C` | `#6B5F53` | 3.02 → **4.59** | 4.5 (text) |
| `--color-ink-3` | dark | `#9C8B79` | `#B0A18F` | 3.84 → **5.02** | 4.5 (text) |
| `--color-ink-4` | light | `#AC9C8B` | `#7D6C5A` | 1.97 → **3.73** | 3.0 (graphic) |
| `--color-ink-4` | dark | `#7B6C5C` | `#968776` | 2.49 → **3.63** | 3.0 (graphic) |
| `--color-focus` | light | `#A8794F` | `#8A5F3A` | 2.82 → **4.11** | 3.0 (SC 1.4.11) |
| `--chart-axis-ink` | light | `#8B7B6C` | `#6B5F53` | follows ink-3 | 4.5 (13px text) |
| `--chart-axis-ink` | dark | `#9C8B79` | `#B0A18F` | follows ink-3 | 4.5 (13px text) |

`--color-focus` in dark (`#D6A874`, worst 5.85) already cleared and did not move.
Placeholders now point at the corrected `--color-ink-3`, per §2 above — in the
CSS **and** in `CalmField`. That sentence was true of the stylesheet alone for a
day: `odova.css`, `calm_palette.dart` and 116 re-shot reference PNGs all agreed,
and the widget that draws the pixel went on passing `colors.ink4` to `hintStyle`
at 4.23:1 light and 4.14:1 dark. No token test could see it, because the token
was right. `test/a11y/rendered_text_contrast_test.dart` reads the colour off the
`RenderParagraph` instead, so the claim above is now measured where it is drawn.

### What this document did not say

- **`--color-ink-3` fails in DARK too**, at 4.39:1 on `--color-surface-2` and
  3.84:1 on `--color-surface-3`. This file calls the finding "light-theme only;
  dark is fine". It is not.
- **`--color-ink-4` fails in dark** as a graphic, at 2.85 and 2.49.
- **`--color-focus` fails SC 1.4.11 in light**, at 2.82:1 on `--color-surface-3`
  — a control inside a warm container had a focus ring the user could not see.
  This document does not mention the focus ring at all.

All three were found by `test/theme/calm/calm_contrast_test.dart`, which EPIC-02
wrote to hold the failures as dated exceptions that assert they **still fail**.
That is what made this closure mechanical: fixing the values turned eleven
exceptions red at once and forced their removal. The exception list is now
empty and is meant to stay that way.

### What is NOT closed

Dark `--color-ink-3` now measures **50.2 Lc** under APCA, up from 39.1. That
clears APCA's 45 non-text floor and WCAG AA comfortably, and is still under the
60 APCA asks for body text. Closing that gap means lightening tertiary text
past the point where it reads as tertiary — a further design judgement nobody
has been asked for, and not the WCAG failure §17 makes a release blocker. It is
pinned at the measured value in `calm_contrast_test.dart` so the next palette
change re-opens the question.

### What moved with it

`design/calm/odova.css`, `design/calm/screens.html`, `lib/theme/calm/` (the
ramp entries are renamed as well as revalued, because the names track lightness
and a name that lies is worse than none), the 38 component goldens under
`test/ui/calm/goldens/`, and all 112 images of `design/reference/calm/` —
`calm-visual-parity` rule 7: a reference set that lags the design is worse than
having none.
