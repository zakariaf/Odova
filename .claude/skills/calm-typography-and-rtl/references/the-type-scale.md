# The Calm type scale

Nine steps, a 3.5× spread, and no monospace. Calm spends almost nothing on colour and borders, so size and weight carry the whole hierarchy — which is why the scale is wide at the top and stops hard at the bottom.

## The nine roles

Values are `--fs-*` / `--lh-*` / `--fw-*` from `tokens.json`; `height` in Flutter is the same unitless multiple CSS `line-height` uses.

| Role | Size | Height | Weight | Tracking | Used by |
|---|---|---|---|---|---|
| `display` | 46 | 1.04 | 600 | `--tracking-tight` | `CalmNumberPad` display, the odometer readout. Nothing else. |
| `hero` | 34 | 1.12 | 600 | tight | The single headline value above a chart (`6.4 L/100 km`) |
| `titleLg` | 27 | 1.18 | 600 | tight | `CalmDueCard` primary status line; large screen titles |
| `title` | 22 | 1.26 | 600 | tight | `CalmAppBar`, `CalmSheet` and `CalmDialog` titles |
| `headline` | 19 | 1.32 | 600 | `--tracking-normal` | `CalmCard` titles; the primary due-card title |
| `bodyLg` | 17 | 1.50 | 400 | normal | `CalmListRow` titles, `CalmButton` labels, `CalmField` values, dialog body |
| `body` | 15 | 1.55 | 400 | normal | Running text; secondary card status |
| `label` | 14 | 1.40 | 500 | normal | Field labels, `CalmChip`, section titles, `CalmTabBar` labels |
| `caption` | 13 | 1.45 | 500 | normal | Anchor lines (`Was due at 186,512 km · 12 August`), meta, hints |

The gaps are deliberate and uneven: 46→34→27 at the top (each a clear step down at arm's length), then 19→17→15→14→13 at the bottom where the differences are weight and colour as much as size. Do not fill a gap. If a component needs "something between `headline` and `bodyLg`", it needs a different weight or a different ink, not a tenth role.

## The 13px floor

`caption` is the smallest text in the product. There is no `micro`, no `overline`, no 11px axis label, no 12px legal line.

The reason is the reader. Odova is used one-handed, outdoors, at a pump or on a driveway, by someone checking whether they can put off a service — not by someone browsing. Every screen is glanced at, in bad light, often with the phone at arm's length because their hands are dirty. 11px is a size that assumes a seated, attentive, well-lit reader, and this app never has one.

Two consequences that catch people out:

- **Chart axis labels are `caption`.** If 13px ticks do not fit, reduce the tick count or widen the axis gutter — never shrink the type. (The shipped CSS uses 11px for `.chart__axis-label` and `.fuelchart__ytick`; that is a defect, not a licence.)
- **`textScaler` is never clamped.** The floor is a *minimum*, not a fixed size. At 200% scale `caption` is 26px and rows grow; that is the design working, not breaking. See `accessibility-as-code`.

## Three weights, no italics, no caps

`--fw-regular: 400`, `--fw-medium: 500`, `--fw-semi: 600`. `--fw-bold: 700` is declared in the token file and consumed by nothing — leave it that way.

All three are slots on `CalmType` beside the nine roles: `CalmType.of(c).regular` / `.medium` / `.semi`. A component that needs to step a role up in weight writes `t.bodyLg.copyWith(fontWeight: t.semi)` — never a literal `FontWeight.w600`, and never a new role with a bigger `fontSize`. `--fw-bold` gets no slot, because a slot nobody fills is a slot someone misuses.

- **No italics, no synthetic obliques.** Arabic script has no italic form; Flutter would synthesise a slant that shears the joins. Emphasise with weight (500→600) or with ink (`ink-2` → `ink`).
- **No all-caps, no `text-transform`, no small-caps.** Casing that matters belongs in the ARB string, never `toUpperCase()` at render — which will eventually mangle a proper noun or a user-entered workshop name, and means nothing in three of the six locales.
- **No underline for emphasis.** It collides with the descenders of `ج ح خ ر ز ی`.

## Tracking is em; Flutter is pixels

```dart
// --tracking-tight: -0.02em on a 46px step is -0.92 logical pixels.
letterSpacing: fontSize * -0.02,   // NOT letterSpacing: -0.02
```

Three tracking tokens exist: `--tracking-tight: -0.02em` (the four large steps), `--tracking-normal: -0.005em` (everything else, inherited from `body` in CSS), `--tracking-loose: 0.01em`. **`--tracking-loose` has no product consumer** — in the shipped CSS only the simulated device status bar uses it. Do not introduce one; a tracked-out label is an all-caps gesture in disguise.

Under `fa`, `ar` and `ckb` all three collapse to **0**. Tracking breaks cursive joins, and a joined script with positive letter-spacing reads as a rendering fault.

## Figures

Wherever a number is compared to another number — odometer, prices, totals, the number-pad display, chart values, key/value report rows — apply both features to the role you are already using:

```dart
style.copyWith(fontFeatures: const [
  FontFeature.tabularFigures(),  // 'tnum' — fixed advance width, no jitter on count-up
  FontFeature.liningFigures(),   // 'lnum' — no old-style descending digits
]);
```

That is the whole answer to "how do we align columns of numbers without a mono face". Verify the bundled face ships `tnum` for **both** digit blocks: a face with `tnum` for `0-9` and not for `۰-۹` gives a stable English odometer and a jittering Persian one.

## Codes are LTR, always

VIN, licence plate, and any string whose character order is significant:

```dart
Text(vin,
  style: CalmType.of(context).bodyLg.copyWith(letterSpacing: 17 * 0.02),
  textDirection: TextDirection.ltr,   // even on an RTL screen
  textAlign: TextAlign.start);        // resolves to left under the forced LTR
```

The shipped `.code` rule uses a literal `letter-spacing: 0.02em`, and there is no `--tracking-code` token behind it — the one place in Calm where a type value has no token. Until one exists, keep the multiplication visible at this single call site (`CalmCode` in `examples/numeral_formatting.dart`) rather than scattering `0.02`.

## Text expansion

German runs ~30% longer than English and French ~20%; Persian and Arabic are shorter in characters but taller in line box. Calm's large type multiplies the first problem: a `bodyLg` (17) button label inside a 52px pill has very little slack.

- **Buttons wrap to two lines. They never truncate, ellipsise or auto-shrink.** The pill grows; the row grows. The only shrink exception is a large numeric readout (odometer, cost).
- **Reserve two lines** in: `CalmButton` (all sizes), `CalmDueCard` status line, `CalmListRow` title, `CalmEmptyState` body, `CalmSnackbar` message, `CalmDialog` title.
- **`CalmTabBar` labels carry `maxChars: 12`** at the largest text scale. A locale that cannot fit gets a shorter translation, not an ellipsis.
- **Field labels sit above inputs**, never beside — side-by-side labels are the first thing expansion breaks.
- **Two-column label/value rows** give the label at most 60% and let it wrap.
- Every layout survives **200% text scale × the longest of the six translations** with no truncation and no overlap (`SPEC.md` §5 *Text expansion*).
