# Calm: two WCAG failures in the light theme

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
