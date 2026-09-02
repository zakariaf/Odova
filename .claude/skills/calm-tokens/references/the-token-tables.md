# The Calm colour tokens — every value, both themes

Source of truth: `design/calm/odova.css` (`:root` and `[data-theme="dark"]`), extracted to
`tokens.json`. **56 colour roles, every one of which has a dark override** — Calm has no
"light-only" colour, so a missing dark value in Dart is a bug, not a design gap.

Reading the columns: *Dart slot* is the field on `CalmColors` (contract naming: `--color-ink-2`
→ `ink2`). *Tier-1* is the `CalmPalette` constant, named `<family><L>` where `L` is measured
OKLCH lightness × 100 — a fact about the pixel, so the name cannot lie in either theme.
Families are Calm's own hue families: `sand` (paper), `bark` (ink), `clay` (brand),
`terracotta` (overdue), `ochre` (due), `slate` (due-soon), `sage` (ok), `stone` (unknown),
`pebble` (needs-odometer), `plum` (business), `ember` (danger), `amber` (focus).

The four-rung shape repeats for every stateful family: **base** (the graphic — dot, bar, rule),
**ink** (text on the tint), **tint** (the fill), **edge** (the 1px boundary of the fill). Only
`ink`-on-`tint` is a text pair; `base` is a non-text graphic held to 3:1. Widgets never read
these seven families directly — they go through `CalmStatusStyle` (`calm-due-state-and-status`).

### Surface ramp

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-bg` | `bg` | `#F8F2E9` | `#1D1815` | `sand96` / `sand21` |
| `--color-bg-sunk` | `bgSunk` | `#EFE6D9` | `#151110` | `sand93` / `sand18` |
| `--color-surface` | `surface` | `#FFFCF7` | `#272019` | `sand99` / `sand25` |
| `--color-surface-2` | `surface2` | `#F3EADC` | `#31281F` | `sand94` / `sand28` |
| `--color-surface-3` | `surface3` | `#E9DCC9` | `#3C3127` | `sand90` / `sand32` |
| `--color-surface-inverse` | `surfaceInverse` | `#2C241E` | `#F2E8DB` | `bark27` / `bark94b` |
| `--color-divider` | `divider` | `#E6D9C6` | `#3A3028` | `bark89` / `bark32` |

### Ink ramp

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-ink` | `ink` | `#2C241E` | `#F3EADE` | `bark27` / `bark94` |
| `--color-ink-2` | `ink2` | `#5C4E43` | `#C6B6A4` | `bark43` / `bark78` |
| `--color-ink-3` | `ink3` | `#8B7B6C` | `#9C8B79` | `bark59` / `bark65` |
| `--color-ink-4` | `ink4` | `#AC9C8B` | `#7B6C5C` | `bark70` / `bark54` |
| `--color-ink-inverse` | `inkInverse` | `#FFFBF4` | `#241D17` | `bark99` / `bark24` |

### Brand

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-brand` | `brand` | `#7A5340` | `#D3A480` | `clay48` / `clay75` |
| `--color-brand-strong` | `brandStrong` | `#5F3E2E` | `#E7BE9D` | `clay40` / `clay83` |
| `--color-brand-soft` | `brandSoft` | `#EDE0D3` | `#3C2E23` | `clay91` / `clay31` |
| `--color-brand-soft-ink` | `brandSoftInk` | `#6A452F` | `#E0B694` | `clay43` / `clay81` |
| `--color-on-brand` | `onBrand` | `#FFF9F1` | `#2A1E15` | `clay98` / `clay25` |

### overdue

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-overdue` | `overdue` | `#B4573E` | `#E39172` | `terracotta57` / `terracotta73` |
| `--color-overdue-ink` | `overdueInk` | `#8C3E28` | `#F0B79B` | `terracotta46` / `terracotta82` |
| `--color-overdue-tint` | `overdueTint` | `#F7E2D8` | `#402720` | `terracotta93` / `terracotta30` |
| `--color-overdue-edge` | `overdueEdge` | `#E9C7B7` | `#55372B` | `terracotta85` / `terracotta37` |

### due

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-due` | `due` | `#B0802C` | `#DDB45F` | `ochre63` / `ochre79` |
| `--color-due-ink` | `dueInk` | `#7F5A15` | `#EBCB8B` | `ochre49` / `ochre85` |
| `--color-due-tint` | `dueTint` | `#F8ECD1` | `#3B2F1B` | `ochre95` / `ochre31` |
| `--color-due-edge` | `dueEdge` | `#EAD5AB` | `#4E3F24` | `ochre88` / `ochre38` |

### dueSoon

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-due-soon` | `dueSoon` | `#5B7C8A` | `#93B6C3` | `slate57` / `slate75` |
| `--color-due-soon-ink` | `dueSoonInk` | `#3F5D6A` | `#B4D0DA` | `slate46` / `slate84` |
| `--color-due-soon-tint` | `dueSoonTint` | `#E2ECF0` | `#24313A` | `slate94` / `slate31` |
| `--color-due-soon-edge` | `dueSoonEdge` | `#C4D8DF` | `#33454F` | `slate87` / `slate38` |

### ok

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-ok` | `ok` | `#5D7B60` | `#9CBF9E` | `sage55` / `sage77` |
| `--color-ok-ink` | `okInk` | `#435C46` | `#BBD5BC` | `sage45` / `sage85` |
| `--color-ok-tint` | `okTint` | `#E4EDE1` | `#25311F` | `sage94` / `sage30` |
| `--color-ok-edge` | `okEdge` | `#C7DAC4` | `#35452D` | `sage87` / `sage37` |

### unknown

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-unknown` | `unknown` | `#8A7C6D` | `#B7A794` | `stone59` / `stone74` |
| `--color-unknown-ink` | `unknownInk` | `#6B5D4F` | `#CFC1B0` | `stone49` / `stone82` |
| `--color-unknown-tint` | `unknownTint` | `#EEE7DB` | `#332A21` | `stone93` / `stone29` |
| `--color-unknown-edge` | `unknownEdge` | `#DCD1BE` | `#453A2E` | `stone86` / `stone36` |

### needsOdometer

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-needs-odometer` | `needsOdometer` | `#736A5F` | `#A99D8F` | `pebble53` / `pebble70` |
| `--color-needs-odometer-ink` | `needsOdometerInk` | `#574F46` | `#C3B8AB` | `pebble43` / `pebble79` |
| `--color-needs-odometer-tint` | `needsOdometerTint` | `#EAE5DC` | `#2F2820` | `pebble92` / `pebble28` |
| `--color-needs-odometer-edge` | `needsOdometerEdge` | `#D5CDC0` | `#40382E` | `pebble85` / `pebble35` |

### business

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-business` | `business` | `#7C5E74` | `#C6A2C0` | `plum52` / `plum75` |
| `--color-business-ink` | `businessInk` | `#5F4459` | `#D9BDD4` | `plum42` / `plum83` |
| `--color-business-tint` | `businessTint` | `#F0E6EE` | `#332530` | `plum94` / `plum29` |
| `--color-business-edge` | `businessEdge` | `#DCC9D8` | `#463442` | `plum86` / `plum35` |

### Alarm + focus

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--color-danger` | `danger` | `#A5402B` | `#E68C72` | `ember51` / `ember73` |
| `--color-danger-tint` | `dangerTint` | `#F7DED6` | `#422520` | `ember92` / `ember30` |
| `--color-focus` | `focus` | `#A8794F` | `#D6A874` | `amber61` / `amber76` |

### Chart

| CSS token | Dart slot | Light | Dark | Tier-1 light / dark |
|---|---|---|---|---|
| `--chart-1` | `chart1` | `#7A5340` | `#D3A480` | `(alias)` / `(alias)` |
| `--chart-2` | `chart2` | `#5D7B60` | `#9CBF9E` | `(alias)` / `(alias)` |
| `--chart-3` | `chart3` | `#B0802C` | `#DDB45F` | `(alias)` / `(alias)` |
| `--chart-4` | `chart4` | `#5B7C8A` | `#93B6C3` | `(alias)` / `(alias)` |
| `--chart-5` | `chart5` | `#7C5E74` | `#C6A2C0` | `(alias)` / `(alias)` |
| `--chart-grid` | `chartGrid` | `#E4D7C4` | `#3A3028` | `bark88` / `bark32` |
| `--chart-axis-ink` | `chartAxisInk` | `#8B7B6C` | `#9C8B79` | `bark59` / `bark65` |
| `--chart-plot` | `chartPlot` | `#FFFCF7` | `#272019` | `sand99` / `sand25` |
`chart1`–`chart5` are exact aliases of `brand` / `ok` / `due` / `dueSoon` / `business` in both
themes — the series palette *is* the semantic palette, which is why a chart legend and a status
dot never disagree. Keep them as separate slots anyway: the day a sixth series appears, the
alias is where it breaks, not the status colour. `chartAxisInk` aliases `ink3`; `chartPlot`
aliases `surface`. `chartGrid` does **not** alias `divider` in light (`#E4D7C4` vs `#E6D9C6`)
but does in dark — see `references/contrast-audit.md`, finding 6.

## The two non-slot colours

| CSS token | Dart slot | Light | Dark |
|---|---|---|---|
| `--scrim` | `scrim` | `rgba(44, 34, 26, 0.44)` | `rgba(12, 9, 7, 0.62)` |
| `--elev-sheen` | `sheen` | `inset 0 1px 0 rgba(255, 255, 255, 0.7)` | `inset 0 1px 0 rgba(255, 236, 214, 0.05)` |

Write both with `const Color.fromRGBO(44, 34, 26, 0.44)` — a const constructor that keeps the
token's own channel numbers legible in the diff, instead of an `0x70`-style alpha nobody can
check against the CSS. `sheen` is an **inset** shadow and Flutter has no inset `BoxShadow`; it
is carried as a `Color` and painted as a 1px top highlight (`calm-components`, `CalmCard`).

## Fonts (values only; the rules live elsewhere)

| CSS token | Light value |
|---|---|
| `--font-latin` | `'Avenir Next', 'Avenir', 'Optima', system-ui, -apple-system, 'Helvetica Neue', sans-serif` |
| `--font-arabic` | `'Vazirmatn', 'Geeza Pro', sans-serif` |
| `--font-ui` | `var(--font-latin)`, and `var(--font-arabic)` under `[lang="fa"|"ar"|"ckb"]` |

`CalmType` carries `fontFamily` / `fontFamilyFallback`; which face is bundled, the Vazirmatn
licence, the per-locale leading bump and the 13px floor are owned by `calm-typography-and-rtl`.
Note that every name in `--font-latin` is a system or proprietary face — none is bundleable, and
the design does not name a substitute. That is a reported finding, not a value to invent.
