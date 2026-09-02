# Calm contrast audit — measured, not asserted

Every ratio below is WCAG 2.x relative luminance computed from the real hexes in `tokens.json`.
Thresholds: **4.5:1** text under 18.66px regular / 24px bold — which is *every* Calm role except
`display`, `hero`, `titleLg` and `title`; **3:1** large text and non-text graphics (status dots,
progress fills, focus rings, chart marks, control boundaries). `accessibility-as-code` owns the
never-colour-alone floor; this file owns the numbers.

Ship the audit as a unit test, not a spreadsheet: a `test/theme/calm_contrast_test.dart` that
walks a declared list of `(fg, bg, minRatio)` triples over **both** `CalmColors` instances and
fails the build. A palette change that drops a pair under threshold must break CI, because the
next person to touch `--color-ink-3` will not re-run this file by hand.

## The ink ramp on paper — where Calm is tight

| Pair | Light | Dark |
|---|---|---|
| `ink` on `surface` | 14.89 | 13.49 |
| `ink` on `bg` | 13.69 | 14.77 |
| `ink` on `surface2` / `surface3` | 12.78 / 11.28 | 12.13 / 10.62 |
| `ink2` on `surface` / `bg` | 7.81 / 7.19 | 8.13 / 8.90 |
| **`ink3` on `surface`** | **3.99 ✗** | 4.88 |
| **`ink3` on `bg`** | **3.67 ✗** | 5.35 |
| **`ink3` on `surface2`** | **3.42 ✗** | **4.39 ✗** |
| **`ink3` on `surface3`** | **3.02 ✗** | **3.84 ✗** |
| **`ink4` on `surface`** | **2.60 ✗** | **3.17 ✗** |
| **`ink4` on `bg`** | **2.39 ✗** | **3.47 ✗** |
| `inkInverse` on `surfaceInverse` | 14.77 | 13.73 |

**Finding 1 — `--color-ink-3` fails AA for body text on every light surface.** `#8B7B6C` on
`#FFFCF7` is 3.99:1 against a 4.5 requirement, and `odova.css` uses `color: var(--color-ink-3)`
in 47 places, almost all of them `--fs-caption` (13px) or `--fs-label` (14px) secondary text:
`.section__hint`, `.row__sub`, `.appbar__vehicle .icon`, the anchor line on `CalmDueCard`. This
is the single biggest a11y defect in the palette. It does not fail in dark on `surface`/`bg`
(4.88 / 5.35) — only light, and light is the default. Darkening `ink3` to `#7E6E5F` clears 4.5 on
`bg` (4.41 — still short), `surface` (4.79) and `surface-2` (4.11 — short); it does **not** clear
`surface-3`, at 3.63. Holding hue 29° and saturation, the first value that clears 4.5 on all
four light surfaces is **`#6B5F53`** (bg 5.57 / surface 6.06 / surface-2 5.20 / surface-3 4.59).
If tertiary text is never placed on `surface-3`, `#776758` covers the other three (4.88 / 5.31 /
4.56). None of these is in `tokens.json`, so this is a design decision, not an implementation
one — see the finding filed against `design/calm/odova.css`.

**Finding 2 — `--color-ink-4` is below 3:1 in light and cannot carry text or an affordance.**
`#AC9C8B` on `#FFFCF7` is 2.60:1. Disabled uses (`.btn:disabled`, `.stepper__btn.is-disabled`,
`.segmented__opt.is-disabled`, `.input:disabled`) are exempt under SC 1.4.3 and are fine. Two
uses are **not** exempt: `.row__chev` — the chevron is the only signal that a row navigates, a
non-text graphic requiring 3:1 — and `.mchart__label`, real 13px chart-axis content. Both must
move to `ink3` (itself finding 1) or `ink2`.

## Status families — `ink` on `tint` is the text pair, `base` is the graphic

`ink`-on-`tint` clears 4.5 everywhere, in both themes. That is the design working: the four-rung
shape exists so text never sits on its own base colour.

| Family | `ink` on `tint` L / D | `base` on `tint` L / D | `base` on `surface` L / D |
|---|---|---|---|
| overdue | 5.94 / 7.82 | 3.85 / 5.60 | 4.69 / 6.55 |
| due | 5.31 / 8.36 | **3.00 ⚠** / 6.69 | **3.44** / 8.24 |
| dueSoon | 5.86 / 8.24 | 3.73 / 6.17 | **4.37** / 7.44 |
| ok | 6.12 / 8.69 | 3.92 / 6.74 | 4.59 / 7.93 |
| unknown | 5.17 / 7.97 | 3.30 / 6.00 | **3.96** / 6.86 |
| needsOdometer | 6.41 / 7.45 | 4.23 / 5.47 | 5.19 / 6.05 |
| business | 7.02 / 8.41 | 4.65 / 6.44 | 5.53 / 7.14 |

Bold entries are below 4.5 and are therefore **graphic-only**: `--color-due` at 3.44:1 on
`surface` is a legal 12pt status dot and an illegal status *line*. `odova.css` gets this right —
the due-card status line uses `--due-ink`, never `--due-color` — but nothing in Dart enforces it.
`CalmStatusStyle` must expose the base colour as a `dotColor`/`markColor` and the ink as
`textColor`, with no accessor that returns the base for a `TextStyle`
(`calm-due-state-and-status`).

**Finding 3 — `--color-due` on `--color-due-tint` is exactly 3.00:1 in light: zero margin.**
`#B0802C` on `#F8ECD1`. The `due` state's dot is a *ring* (`box-shadow: inset 0 0 0 3px`), so the
graphic is 3px of stroke sitting on the card's tint gradient at the SC 1.4.11 floor with nothing
to spare — any anti-aliasing at the ring edge puts it under. On `--color-surface-2` the same dot
measures **2.95:1 and fails outright**, which is the state it renders in inside a
`CalmRowGroup`. `due` is the amber rung; amber on cream is the hardest pair in any warm palette,
and Calm did not win this one.

**Finding 4 — `--color-focus` fails the focus-ring floor on `surface3` in light.** `#A8794F` on
`#E9DCC9` is **2.82:1** against SC 1.4.11's 3:1, and `odova.css` draws the ring as
`outline: 3px solid var(--color-focus)` globally. On `bg` (3.42) and `surface` (3.72) it passes,
tightly. Dark is comfortable at 5.85–8.14. A keyboard or switch-control user tabbing onto a
control inside a `surface3` container gets a ring they cannot see.

## Brand, danger, chart

| Pair | Light | Dark |
|---|---|---|
| `onBrand` on `brand` / `brandStrong` | 6.39 / 9.06 | 7.25 / 9.46 |
| `brandSoftInk` on `brandSoft` | 6.47 | 7.02 |
| `brand` on `surface` | 6.54 | 7.19 |
| `danger` on `surface` / `dangerTint` | 6.09 / 4.86 | 6.40 / 5.51 |
| `chart1..5` on `chartPlot` | 6.54 / 4.59 / **3.44** / **4.37** / 5.53 | 7.19 / 7.93 / 8.24 / 7.44 / 7.14 |
| `chartGrid` on `chartPlot` | 1.38 | 1.25 |

**Finding 5 — the chart series are not equally legible in light.** `chart3` (`#B0802C`, the due
ochre) is 3.44:1 and `chart4` (`#5B7C8A`) is 4.37:1 on the plot, while `chart1` is 6.54:1. As
2px sparkline strokes they clear the 3:1 non-text floor, but a 1.9× spread in legibility across
one series set means the ochre series visually recedes. Worse, `chart3` over `chartGrid`
(`#E4D7C4`) is **2.48:1** — a due-coloured bar crossing a grid line is below the floor. Dark is
uniform at 7.14–8.24 and has no such problem. `dataviz` owns series ordering; the fix here is to
draw grid lines *under* fills and never rely on a series edge against the grid.

**Finding 6 — `--chart-grid` and `--color-divider` are the same colour in dark and different in
light.** Dark: both `#3A3028`. Light: `#E4D7C4` vs `#E6D9C6` — a 2/2/2 RGB difference, ΔL of 1
in OKLCH, invisible on a screen. Either they are one token or they are two; shipping them as two
that agree in one theme and not the other guarantees they drift.

**Finding 7 — two more near-duplicate pairs.** Light `--color-unknown` `#8A7C6D` and
`--color-ink-3` `#8B7B6C` are 1/1/1 apart: the *unknown* status colour is the secondary ink
colour with a rounding error, so "we do not know" and "this is a caption" render identically.
Dark `--color-ink` `#F3EADE` and `--color-surface-inverse` `#F2E8DB` are 1/2/3 apart. In light,
`--color-ink` and `--color-surface-inverse` are deliberately identical (`#2C241E`) — that is the
inverse surface *being* the ink, which is correct; the dark pair looks like a failed attempt to
repeat that and should either match exactly or diverge visibly.

## Dividers

`divider` on `surface` is 1.36:1 light / 1.25:1 dark, and that is fine — SC 1.4.11 governs
components and states, not decorative separators, and Calm's contract is explicitly
"elevation is layered shadow, never a hard border". Do **not** darken the divider to chase a
ratio; if a boundary needs to be perceivable, it is an `edge` rung or a shadow, not a hairline.
