# Mapping Calm onto `ColorScheme` — by hand, in both brightnesses

`design-system-structure` owns *why* you hand-author a `ColorScheme` (per-role overrides on
`fromSeed` do not propagate). This file owns the Calm-specific half: which slot fills which M3
role, and which roles Calm deliberately parks on a neutral.

## Why `fromSeed` cannot produce Calm — the measurable reason

`ColorScheme.fromSeed` builds every neutral from the seed's **hue**, at a chroma the M3 spec
pins to a constant (4 for the neutral palette, 8 for neutral-variant). Calm's paper ramp is not
built that way. Measured in OKLCH:

| Slot | Light hex | L | C | H |
|---|---|---|---|---|
| `surface` | `#FFFCF7` | .99 | **.007** | 81° |
| `bg` | `#F8F2E9` | .96 | **.014** | 78° |
| `surface2` | `#F3EADC` | .94 | **.021** | 79° |
| `surface3` | `#E9DCC9` | .90 | **.029** | 78° |
| `brand` (the only plausible seed) | `#7A5340` | .48 | .060 | **47°** |

Two things break at once. **Hue drifts 31°**: seeding on `brand` at 47° regenerates the paper at
a clay-pink hue, not Calm's ochre 78–81°, so the off-white goes rosy and the system stops reading
as sand. **The chroma ramp flattens**: Calm's surfaces get *warmer as they get darker* (.007 →
.029, a deliberate 4× rise), and a constant-chroma neutral palette cannot express a rise at all —
every surface lands on one chroma and the depth cue disappears. Dark is worse: dark `brand`
`#D3A480` sits at 59° while the dark surfaces sit at 63–71°, so a dark seed drifts the other way.

There is no seed that produces this ramp, so there is nothing to "seed plus override". State the
roles.

## The mapping — identical structure in both brightnesses

| M3 role | Calm slot | Light / dark contrast against its `on` pair |
|---|---|---|
| `primary` / `onPrimary` | `brand` / `onBrand` | 6.39 / 7.25 |
| `primaryContainer` / `onPrimaryContainer` | `brandSoft` / `brandSoftInk` | 6.47 / 7.02 |
| `secondary` / `onSecondary` | `brand` / `onBrand` | — Calm has one brand hue |
| `secondaryContainer` / `onSecondaryContainer` | `surface2` / `ink2` | 6.71 / 7.31 |
| `tertiary` / `onTertiary` | `ink` / `surface` | **deliberately neutral** |
| `tertiaryContainer` / `onTertiaryContainer` | `surface2` / `ink2` | **deliberately neutral** |
| `surface` / `onSurface` | `surface` / `ink` | 14.89 / 13.49 |
| `surfaceDim` | `bgSunk` | — |
| `surfaceBright` | `surface` | — |
| `surfaceContainerLowest` | `surface` | — |
| `surfaceContainerLow` | `bg` | — |
| `surfaceContainer` / `surfaceContainerHigh` | `surface2` | — |
| `surfaceContainerHighest` / `onSurfaceVariant` | `surface3` / `ink2` | 5.92 / 6.40 |
| `outline` / `outlineVariant` | `divider` | non-text, decorative |
| `error` / `onError` | `danger` / `inkInverse` | 6.04 / 6.62 |
| `errorContainer` / `onErrorContainer` | `dangerTint` / `danger` | 4.86 / 5.51 |
| `inverseSurface` / `onInverseSurface` | `surfaceInverse` / `inkInverse` | 14.77 / 13.73 |
| `inversePrimary` | `brandSoft` | 11.76 / 10.79 on `inverseSurface` |
| `scrim` | `scrim` | — |
| `shadow` | `Color(0xFF4C3220)` — the `--elev-*` tint, opaque | — |
| `surfaceTint` | `surface` | — a no-op overlay, on purpose |

Three of these are the whole point of writing the table down:

**`tertiary` is parked on `ink`.** Calm ships one brand hue and eight semantic hues, and none of
the eight is a decoration — `ochre` means *due*, `plum` means *business trip*. Leaving `tertiary`
at its `ColorScheme` default would let a stock Material widget pull an unrelated purple onto a
screen where purple already means something. Parking it on the ink/surface pair makes an
accidental `tertiary` read as plain text instead of a false status.

**`surfaceTint` is `surface`.** M3 tints elevated surfaces by compositing `surfaceTint` at an
elevation-dependent alpha. Calm's elevation is shadow, never tonal lift, and its surface ramp is
hand-tuned; a primary-tinted `Card` would put clay into `#FFFCF7`. Setting the tint equal to the
surface makes the composite a no-op without having to chase `surfaceTintColor` on nine component
themes. Do both anyway: also set `surfaceTintColor: Colors.transparent` on the component themes,
because `ThemeData` reads it from the widget theme first.

**`errorContainer`'s `on` colour is `danger` itself.** Calm has `--color-danger` and
`--color-danger-tint` but **no `--color-danger-ink`** — the only semantic family missing its ink
rung. `danger`-on-`dangerTint` measures 4.86:1 light / 5.51:1 dark, so it passes AA and is the
correct stopgap, but it is a hole in the palette and is reported as a finding.

## The roles you must not consume

`onPrimaryFixed`, `primaryFixedDim`, `onSecondaryFixedVariant` and the rest of the `*Fixed*`
family are left at `ColorScheme`'s defaults. They are M3's cross-theme-stable palette for
multi-surface products; Calm has no such surface, and stating them would be inventing eight
values the design does not have. **Nothing in `lib/ui/calm/**` may read a role this table does
not list** — a role that is not stated is a value nobody chose, and `check_raw_values.sh` cannot
see it.

Getting the names right is what buys the free theming: a Material `TextField` resolves
`surfaceContainerHighest`, `onSurfaceVariant`, `outline` and `error` unaided, so `CalmField`
needs no per-widget `InputDecoration` patching that would drift on the next palette change.
