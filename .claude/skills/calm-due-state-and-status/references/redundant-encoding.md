# Redundant encoding — why colour is the weakest signal Calm has

`accessibility-as-code` owns the rule (≥3 non-colour signals per stateful meaning). This file owns the *evidence* for Calm specifically, because in this palette the rule is not a precaution — it is the only thing keeping the states apart.

## The proof: Calm's six state hues are indistinguishable in grayscale

Relative luminance of each `base`, and the worst-case contrast ratio between any two of them:

| state | light `base` | L | dark `base` | L |
|---|---|---|---|---|
| `overdue` | `#B4573E` | 0.169 | `#E39172` | 0.378 |
| `due` | `#B0802C` | 0.249 | `#DDB45F` | 0.488 |
| `dueSoon` | `#5B7C8A` | 0.185 | `#93B6C3` | 0.436 |
| `ok` | `#5D7B60` | 0.173 | `#9CBF9E` | 0.468 |
| `unknown` | `#8A7C6D` | 0.209 | `#B7A794` | 0.398 |
| `needsOdometer` | `#736A5F` | 0.148 | `#A99D8F` | 0.345 |

The **largest** separation between any pair is 1.51:1 in light (`due` vs `needsOdometer`) and 1.36:1 in dark. The most dangerous pair is `overdue` vs `ok` at **1.02:1** in light — "you are late" and "you are fine" are the same grey. WCAG's floor for a difference that *means* something in non-text UI is 3:1. Calm clears it against the background (below) and misses it against every sibling state, by a factor of two.

This is not a Calm bug. It is what a warm, low-saturation, one-family palette costs, and it is bought back with shape and words. It does mean the never-colour-alone rule is load-bearing here in a way it is not in a system with a red/green/blue triad.

## Signal 1 — the mark

Geometry from `odova.css` §12, declared as `CalmStatusMark` constants in `calm_status.dart` (they are not in `tokens.json`):

| state | diameter | ring stroke | opacity | reads as |
|---|---|---|---|---|
| `overdue` | 12 | filled | 1.0 | ● solid, largest |
| `due` | 12 | 3 | 1.0 | ◉ thick ring, small hole |
| `dueSoon` | 8 | filled | 1.0 | ● solid, small |
| `ok` | 12 | filled | 1.0 | ● solid, largest |
| `unknown` | 12 | 2 | 0.7 | ◌ thin ring, faded |
| `needsOdometer` | 12 | 2 | 1.0 | ◌ thin ring |

**Two collisions ship today.** `ok` is geometrically identical to `overdue`, and `unknown` differs from `needsOdometer` only by 0.7 opacity — a difference that survives grayscale but not a low-contrast display or a screenshot at 1× on a sunny forecourt. On Home the collisions are harmless (`ok` never renders there, `unknown` collapses into its own card). On `reminders.list` and the vehicle switcher they are live: `design/calm/screens.html` renders `overdue`, `ok` and `needsOdometer` dots in one rowgroup.

Until the design assigns two more silhouettes, the discipline is: **assert on the (mark, label) pair, never on the mark alone**, and never render a dot without its word. `examples/status_grayscale_test.dart` pins the two known collisions with an explicit expectation, so the day a designer fixes them the test fails and tells you to tighten it.

## Signal 2 — the label, and Signal 3 — the copy pattern

The label is the noun ("Overdue", "On track", "Never recorded"). The copy pattern is the *shape of the sentence*, and it differs even when two states could plausibly share a template:

- `overdue` — positive overshoot: `Overdue by 900 km`. Never `in −21 days`.
- `due` — imperative with no number: `Due now`. A figure here invites arithmetic; the answer is "today".
- `dueSoon` — hedged forward look: `in about 1,800 km`, `in about 3 weeks`.
- `ok` — plain forward look, no hedge: `in 8,600 km`.
- `unknown` — an absence: `Never recorded`.
- `needsOdometer` — a request: `Needs an odometer reading`.

"about" appears in `dueSoon` and never in `ok`; the hedge itself is a signal. `references/uncertainty-copy.md` owns the rest.

The **action** is a fourth signal and is not decoration: `unknown` and `needsOdometer` get **Update odometer**, everything else gets **Log it**.

## AA — `ink` on `tint`, computed from `tokens.json`

| state | light ink/tint | light ink/surface | dark ink/tint | dark ink/surface |
|---|---|---|---|---|
| `overdue` | 5.94 | 7.24 | 7.82 | 9.15 |
| `due` | 5.31 | 6.08 | 8.36 | 10.29 |
| `dueSoon` | 5.86 | 6.87 | 8.24 | 9.93 |
| `ok` | 6.12 | 7.18 | 8.69 | 10.22 |
| `unknown` | 5.17 | 6.21 | 7.97 | 9.11 |
| `needsOdometer` | 6.41 | 7.86 | 7.45 | 8.24 |

Every pair clears 4.5:1 with headroom. Two things do not:

- **`base` on its own `tint`**, which is where the dot sits on a primary card: light `due` measures **2.9999...:1**, i.e. exactly at the 3:1 non-text floor with zero headroom. On `--color-surface` it is 3.44:1, so the secondary card is fine and the primary card's tinted top stop is the risk. Do not darken the tint or lighten the base without re-running the gate.
- **`--color-ink-3` at `--fs-caption` (13px)** — 3.02–3.99:1 across light grounds, 3.97–4.42:1 on the dark tints. That is the shipped `.due-card__anchor` colour and it is under AA. Use `--color-ink-2` (≥ 6.37:1 light, ≥ 6.61:1 dark on every one of those grounds); `SPEC.md` §9 already requires the secondary treatment to meet 4.5:1.

`edge` against its own `tint` is 1.23–1.34:1 in both themes. It is a hairline. If you find yourself distinguishing two states by their `edge`, you have not encoded anything.

## The acceptance test

A pure-grayscale golden of all six states, side by side, must still answer "which state is this?" — and, because the hues are within 1.51:1, it can only answer from mark + label. Render it under `ColorFiltered` with a saturation-zero matrix rather than desaturating the tokens, so the test exercises the same widget tree the user sees. See `examples/status_grayscale_test.dart`, and `widget-golden-and-a11y-testing` for the golden lane it belongs in.
