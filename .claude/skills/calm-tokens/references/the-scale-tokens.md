# The Calm scale tokens — type, space, radius, elevation, metrics, motion

The 61 brightness-independent tokens, plus the 6 elevation tokens that *are* brightness-dependent
and therefore ride a second `CalmShapes` instance. Values from `tokens.json`; nothing here is
derived except the CSS-blur → Flutter-`blurRadius` conversion, which is stated in full.

## Type — `CalmType`, one `TextStyle` per role

`--fs-x` + `--lh-x` + the weight and tracking the CSS `.t-x` utility applies collapse into one
Dart field. Line height is a unitless CSS ratio, which is exactly Flutter's `TextStyle.height`.

| Role | `fs` | `lh` | Weight | Tracking | Dart |
|---|---|---|---|---|---|
| display | 46px | 1.04 | `--fw-semi` 600 | `--tracking-tight` | `CalmType.of(c).display` |
| hero | 34px | 1.12 | 600 | tight | `.hero` |
| titleLg | 27px | 1.18 | 600 | tight | `.titleLg` |
| title | 22px | 1.26 | 600 | tight | `.title` |
| headline | 19px | 1.32 | 600 | `--tracking-normal` | `.headline` |
| bodyLg | 17px | 1.50 | `--fw-regular` 400 | normal | `.bodyLg` |
| body | 15px | 1.55 | 400 | normal | `.body` |
| label | 14px | 1.40 | `--fw-medium` 500 | normal | `.label` |
| caption | 13px | 1.45 | 500 | normal | `.caption` |

Weights: `--fw-regular` 400, `--fw-medium` 500, `--fw-semi` 600, `--fw-bold` 700. The first
three are also slots on the extension — `CalmType.of(c).regular` / `.medium` / `.semi` — so a
component can step a role up in weight (`type.body.copyWith(fontWeight: type.semi)`) without
inventing a `fontSize`; never write a literal `FontWeight.w600` outside `lib/theme/calm/`.
`--fw-bold` is declared but no `.t-*` role uses it and it gets no slot: it exists for inline
emphasis only, and a slot nobody fills is a slot someone misuses.
Tracking: `--tracking-tight` −0.02em, `--tracking-normal` −0.005em, `--tracking-loose` 0.01em.
Flutter's `letterSpacing` is **logical pixels, not em**, so a token is `fontSize × em`:
display is `46 × -0.02 = -0.92`. Never paste `-0.02` into `letterSpacing` — at 46px it is a
46× error that reads as "the tracking token does nothing".

## Space — `CalmSpace`

| Token | Value | Dart | | Token | Value | Dart |
|---|---|---|---|---|---|---|
| `--space-1` | 4 | `s1` | | `--space-6` | 24 | `s6` |
| `--space-2` | 8 | `s2` | | `--space-7` | 32 | `s7` |
| `--space-3` | 12 | `s3` | | `--space-8` | 40 | `s8` |
| `--space-4` | 16 | `s4` | | `--space-9` | 56 | `s9` |
| `--space-5` | 20 | `s5` | | `--space-10` | 72 | `s10` |

The ramp is 4/8/12/16/20/24 then jumps to 32/40/56/72 — it is *not* a ×2 scale, so never compute
a step (`s4 * 2` is 32, which is `s7`, but `s5 * 2` is 40, which is `s8` — the arithmetic is a
coincidence that stops holding at `s9`). Read the slot.

**Metrics** ride `CalmSpace` too, because they are distances: `--screen-pad` 22 (`screenPad`,
deliberately off-ramp — it is the horizontal gutter, not a spacing step), `--appbar-h` 56
(`appbarH`), `--statusbar-h` 54 (`statusbarH`), `--tabbar-h` 62 (`tabbarH`), `--homebar-h` 34
(`homebarH`), `--touch-min` 52 (`touchMin`). `touchMin` is 52 and not Material's 48 on purpose —
§1 of `SPEC.md`: logging happens at a pump, in the rain, one-handed. `calm-layout-and-motion`
owns how it is enforced.

## Radius — `CalmShapes`

`--radius-xs` 8 → `radiusXs`, `sm` 12, `md` 16, `lg` 20, `xl` 24, `2xl` 28 (`radius2xl`),
`3xl` 36 (`radius3xl`), `--radius-pill` 999 (`radiusPill`). `radiusPill` is a sentinel, not a
measurement: use it only through `StadiumBorder()`, because `BorderRadius.circular(999)` on a
`ClipRRect` allocates a path Skia then has to clamp on every frame.

## Elevation — `CalmShapes`, per brightness

Warm-tinted in light (`rgb(76, 50, 32)`), pure black in dark, always two stacked shadows.

| Token | Light | Dark |
|---|---|---|
| `--elev-0` | `none` | `none` |
| `--elev-1` | `0 1px 2px /.05`, `0 2px 8px /.05` | `0 1px 2px /.32`, `0 2px 8px /.22` |
| `--elev-2` | `0 2px 4px /.05`, `0 10px 22px -6px /.10` | `0 2px 6px /.36`, `0 12px 24px -8px /.42` |
| `--elev-3` | `0 4px 10px /.06`, `0 20px 40px -10px /.14` | `0 6px 14px /.40`, `0 24px 44px -12px /.50` |
| `--elev-4` | `0 8px 18px /.08`, `0 36px 68px -14px /.20` | `0 10px 22px /.46`, `0 40px 76px -16px /.62` |

CSS `blur-radius` is **2σ**; Flutter converts `BoxShadow.blurRadius` with
`Shadow.convertRadiusToSigma(r) = r * 0.57735 + 0.5`. Pasting the CSS number into `blurRadius`
therefore ships a shadow 1.2-1.65× too soft — the ratio is `1.155 + 1/cssBlur`, so 1.65× on the
2px first layer and 1.17-1.28× on Calm's 8-68px ones. The one honest conversion is
`blurRadius = (cssBlur / 2 - 0.5) / 0.57735` — `examples/calm_shapes_and_motion.dart` has it as
`_blur()`.
The negative CSS spreads map straight to `spreadRadius`. Because Calm paints its own shadows,
`ThemeData` must zero Material's: `elevation: 0` and `shadowColor: Colors.transparent` on every
component theme, or a `Card` draws Calm's shadow *and* M3's.

## Motion — `CalmMotion`

| Token | Value | Dart | | Token | Value | Dart |
|---|---|---|---|---|---|---|
| `--dur-instant` | 90ms | `instant` | | `--ease-standard` | `cubic-bezier(0.32, 0.72, 0, 1)` | `easeStandard` |
| `--dur-quick` | 160ms | `quick` | | `--ease-out` | `cubic-bezier(0.2, 0.8, 0.2, 1)` | `easeOut` |
| `--dur-base` | 240ms | `base` | | `--ease-in` | `cubic-bezier(0.4, 0, 1, 1)` | `easeIn` |
| `--dur-slow` | 360ms | `slow` | | `--ease-settle` | `cubic-bezier(0.34, 1.24, 0.64, 1)` | `easeSettle` |
| `--dur-sheet` | 420ms | `sheet` | | | | |

CSS `cubic-bezier(a, b, c, d)` is Flutter `Cubic(a, b, c, d)` with identical semantics.
`easeSettle` has `y1 = 1.24`, i.e. it overshoots — legal in `Cubic`, but it means a widget
animating `Color` with `easeSettle` will interpolate *past* the target colour and clamp, which is
visible on a saturated status fill. Use `easeSettle` for transforms, `easeStandard` for colour.
Reduced motion and the moment catalogue are owned by `calm-layout-and-motion`.
