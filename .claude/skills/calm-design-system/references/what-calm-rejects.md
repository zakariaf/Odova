# What Calm rejects, and what to do instead

The specimen sheet states the anti-brief in one paragraph: *dense tables, hairline rules, monospace figures, dark chrome and instrument-panel metaphors, tick marks, gauges and dyno charts, siren red, all-caps labels, text below 13px, pastel-fintech weightlessness — and the most common mistake of all, treating "nothing is due" as an empty screen.* Each rejection below is a habit with a replacement. None of it is taste; each traces to `SPEC.md` or to a token that exists (or deliberately does not).

## Density and structure

| Rejected | Why | Instead |
|---|---|---|
| Dense tables — eight rows of small text with column rules | The user opens the app 2–6 times a month and wants one answer; density is a power-user affordance for a non-power user | One primary card, ≤2 secondaries, then a cap-and-link row |
| A fourth card "because it's urgent too" | Nine red cards say less than three plus a number | Hard cap at 3; the see-all row carries the rest, and its tone when the overflow is urgent |
| Shrinking padding to fit one more row | Air *is* the design | `--space-6` 24px stays; the answer to "it doesn't fit" is always a cap and a link |
| Two equally large things above the fold | Then there is no primary | Cover the screen and ask what the largest type is. If it is not the one sentence the screen exists to say, resize until it is |

**One primary thing means one.** A screen with two `--radius-3xl` surfaces, or a primary card *and* a full-width accent button above the fold, has no primary. The primary is `--fs-title-lg` 27px or larger; everything else is smaller and quieter, without exception.

## Surface and shape

| Rejected | Why | Instead |
|---|---|---|
| Hairline rules, 1px borders around cards | Spreadsheet vocabulary. Calm has **no** border-width token at all — the omission is deliberate | `--elev-1` (`0 1px 2px` + `0 2px 8px` of `rgba(76, 50, 32, 0.05)`) plus `--elev-sheen`, on `--color-surface` `#FFFCF7` |
| `--color-divider` as an outline | It is a *grouping* device | `#E6D9C6` between rows inside a `CalmRowGroup`, never around a card |
| Small radii (4–8px), square cards | Calm is the round one; the scale runs to 36px for a reason | `--radius-2xl` 28px default card, `--radius-3xl` 36px hero/primary/all-clear, `--radius-xl` 24px inline strip, `--radius-pill` every button and chip. `--radius-xs` 8px and `--radius-sm` 12px are for badges and inline tags only |
| Pastel-fintech weightlessness — mint/lilac gradients, floating glass | This is earth, not candy; weightless reads as unserious next to an eight-year service history | Warm opaque surfaces, layered low-opacity warm shadow, and exactly one radial wash in the system (`--color-ok-tint` on the all-clear card) |
| Dark chrome, carbon fibre, brushed metal, a blue-black dark theme | `SPEC.md` §1: *nobody here wants a dyno chart* | `--color-bg` `#F8F2E9` in light, `#1D1815` in dark — a charcoal-brown dusk. Dark is hand-authored, never an inversion |
| Gauges, dials, tick marks, needles, dyno charts | They dramatise a log into a diagnostic tool and imply precision the data lacks | A 4px `CalmDueCard` progress line on `--color-surface-3`, or a bar chart on `--chart-1`…`--chart-5`. Nothing shaped like an instrument |

## Type

| Rejected | Why | Instead |
|---|---|---|
| Monospace figures | The instrument-panel metaphor — and there is no mono sibling for Vazirmatn under `fa`/`ar`/`ckb` | The humanist face with `FontFeature.tabularFigures()` + `FontFeature.liningFigures()`; the CSS does exactly this on `.num`, `.odostrip__value` and the number-pad display |
| All-caps labels, letter-spaced eyebrows | Unreadable in Arabic and Persian script, and shouting in a system built to reassure | Sentence case everywhere, `--fs-label` 14px / `--fw-medium` 500. Emphasis is size and weight, never case |
| Text below 13px | Read at a pump, in the rain, by someone over forty | `--fs-caption` 13px is the floor and a real size — `--lh-caption` 1.45 gives it room. Below that, cut words |
| Jargon, abbreviations the dashboard does not use | The user is not an enthusiast | The words on the car's own dial |

## Colour and state

| Rejected | Why | Instead |
|---|---|---|
| Siren red (`Colors.red`, `#D32F2F`, `#FF3B30`) | Alarm colour trains the user to dismiss the app; `SPEC.md` §9 gives `due` a grace band precisely so `overdue` still means something | `--color-overdue` `#B4573E` (dark `#E39172`) on `--color-overdue-tint` `#F7E2D8`, text in `--color-overdue-ink` `#8C3E28`. At most once per screen |
| A second red for a non-overdue state | Two reds mean neither is urgent | `--color-due` `#B0802C` amber, `--color-due-soon` `#5B7C8A` slate, `--color-ok` `#5D7B60` sage, `--color-unknown` `#8A7C6D` and `--color-needs-odometer` `#736A5F` warm stone |
| `--color-danger` `#A5402B` on a due card | It is reserved for destructive *actions* — delete | Keep it on Delete and nowhere else |
| Stacking red on red, or an exclamation glyph on a red card | Two alarms is not twice the signal | One tone, one dot shape, one sentence |
| Eleven red cards on a used car's first launch | `SPEC.md` §9: an app that shouts OVERDUE eleven times on day one gets its notifications turned off on day two | Items anchored on the `purchase` or `first_reading` rung render as `unknown` and collapse into one card, whatever the due engine returned |
| Rendering "we don't know" as "you're late" | `SPEC.md` §1: never guess in a way that looks like fact | `DueState.unknown` and `DueState.needsOdometer` — two states, two sentences, both non-alarming |
| A percentage, confidence bar or tier name beside an estimate | Precision theatre over a two-endpoint slope | The tilde and the word "about" are the whole vocabulary: `~187,400 km` in `--color-ink-2` `#5C4E43`, `around mid-October` |

## Framework habits

| Rejected | Why | Instead |
|---|---|---|
| `ElevatedButton`, `Card`, `ListTile`, `Scaffold`, `AppBar`, `TextField`, `Switch`, `Divider`, `SnackBar` in feature code | They bring Material's 4–12px radius, 48px density and ink ripple into a 52px, 28–36px-radius system, and will not follow the next token change | The `Calm*` widget of the same name from `lib/ui/calm/`. `scripts/check_calm_layering.sh` fails the raw Material widget outside that directory |
| `ColorScheme.fromSeed` / `dynamic_color` | A hand-tuned warm neutral ramp with separate `-ink`/`-tint`/`-edge` triples per state cannot come from one seed, and per-role overrides do not propagate | Hand-author both schemes from the tokens; `calm-tokens` owns the file, `design-system-structure` rule 4 owns the argument |
| `EdgeInsets.only(left:)`, `Alignment.centerRight` | Three of six shipping locales are RTL; it fails silently for half the users | `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start/end`, `PositionedDirectional`. CI failure per `SPEC.md` §2 |
| A disabled Save button with no explanation | The user is standing at a pump wondering what is wrong | Save stays visible with `.btn-explain` wording naming the missing field |
| A confirmation dialog for a destructive action | A dialog blocks a one-handed user | `CalmSnackbar` with Undo. The one exception `SPEC.md` grants a dialog is deleting a vehicle |
| A token added in Dart only | `odova.css` is what design review reads | Add it to `design/calm/odova.css` and the matching extension field in the same commit |

## The one everyone gets wrong

**"Nothing is due" is not an empty state.** It is the most common state in the app (`SPEC.md` §9) and it gets the best-looking card in the system: `CalmAllClear` — a `--radius-3xl` surface with a radial `--color-ok-tint` wash, a 92px mark, a `--fs-title-lg` 27px title, a real second sentence (`Next: Inspection, 14 March`) and a since-last-service line (`3,120 km · 4 months`). It is short enough to pull the cost tiles above the fold, so a user with nothing due still leaves knowing what the car costs and what it drinks.

`CalmEmptyState` is for a list the user has not filled yet — no trips, no expenses — and for nothing else. Using it for the all-clear turns the app's reward into a shrug.
