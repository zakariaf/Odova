# Spacing, rhythm, and the 52px floor

Calm has a lot of air and very few surfaces. That only reads as calm if the air is measured in
the same units everywhere; one screen at 20 and its neighbour at 22 reads as a rendering bug
nobody can name.

## The scale

Ten steps, non-linear, plus one gutter that is deliberately not on the scale.

| Token | Dart | px | What it is for |
|---|---|---|---|
| `--space-1` | `s1` | 4 | Hairline separation: dot-to-label, a stacked caption under a value. |
| `--space-2` | `s2` | 8 | Icon-to-label, chip-to-chip, app-bar action gap, row-group header bottom. |
| `--space-3` | `s3` | 12 | The inside of a card; section head to content; row internals. |
| `--space-4` | `s4` | 16 | App-bar side inset, row vertical padding, `u-stack` default gap. |
| `--space-5` | `s5` | 20 | Between screen-body children; row horizontal padding; sheet side inset. |
| `--space-6` | `s6` | 24 | Card padding; dialog side inset; screen-body bottom inset. |
| `--space-7` | `s7` | 32 | Dialog top padding; the all-clear card's bottom. |
| `--space-8` | `s8` | 40 | The all-clear and empty-state top padding — the "this is a destination" inset. |
| `--space-9` | `s9` | 56 | Full-page hero blocks. |
| `--space-10` | `s10` | 72 | Page-bottom breathing room. |
| `--screen-pad` | `screenPad` | 22 | The horizontal screen gutter. Nothing else. |

Steps 1–6 are 4px apart because at that size the eye resolves the difference. From `s6` up the
jumps widen (24 → 32 → 40 → 56 → 72) because past ~24px a 4px change is invisible and a scale
with invisible steps is a scale people stop obeying.

**22 is off-scale on purpose.** A gutter and a gap must never be the same number: if `screenPad`
were `s5`, a card padded at `s5` would put its content 40px from the screen edge and its
neighbour text 20px, and the two would optically fight. Being 22 makes "is this a gutter?"
answerable by reading the number.

## Padding and radius per surface

Every pairing below is what `odova.css` ships. Radius rises with the surface's importance —
the primary card and the sheet are the only `radius3xl` (36) surfaces on Home.

| Surface | Padding | Radius | Internal gap |
|---|---|---|---|
| Screen body | `screenPad` inline, `s5` top / `s6` bottom | — | `s5` |
| Screen foot (non-scrolling) | `screenPad` inline, `s4` top / `s5` bottom | — | `s3` |
| `CalmCard` | `s6` | `radius2xl` 28 | `s3` |
| `CalmDueCard` secondary | `s4` block, `s5` inline, min-height 72 | `radiusXl` 24 | `s3` |
| `CalmDueCard` primary | `s6` | `radius3xl` 36 | `s3` |
| `CalmRowGroup` | 0 (rows own it) | `radius2xl` 28 | 1px divider |
| `CalmListRow` | `s4` block, `s5` inline, min-height 64 | — | `s4` |
| `CalmSheet` | `s3` top, `s5` inline, `s5` bottom | `radius3xl` 36, top corners | `s4` |
| `CalmDialog` | `s7` top, `s6` inline, `s6` bottom, inset `s6` | `radius3xl` 36 | `s3` |
| `CalmAllClear` | `s8` top, `s6` inline, `s7` bottom | `radius3xl` 36 | `s4` |
| `CalmEmptyState` | `s8` block, `s6` inline | — | `s4` |
| `CalmSnackbar` | `s4` block, `s5`/`s4` inline, inset `s5` | `radiusXl` 24 | `s4` |

The snackbar's *bottom* offset is `tabbarH + MediaQuery.paddingOf(context).bottom + s3`, not the
`--homebar-h` the CSS composes — see rule 6 in `SKILL.md`.

## One primary thing per screen

The primary is not "the first card". It is the element that is unmistakably larger, and the test
is mechanical:

1. **Two type steps.** The primary's headline sits ≥ 2 steps above the next element's
   (`titleLg` 27 over `body` 15 on Home; `headline` 19 over `caption` 13 for the sub-line).
2. **A radius step.** The primary is `radius3xl` 36; everything below it is `radius2xl` 28 or
   `radiusXl` 24.
3. **An elevation step.** The primary carries `elev-2`; secondaries carry `elev-1`.
4. **Roughly double the area.** 148pt against 72pt on Home.

If any two elements on a screen match on three of those four, the screen has two primaries and
has failed. The fastest check in review is a 12px Gaussian blur on the golden: exactly one shape
should still be legible.

Odova's application of this is fixed by SPEC §9 — 1 primary + at most 2 secondary due cards, and
**three cards total however many items are overdue**. Past three, the see-all row carries the
count instead (`See all — 9 more due or overdue ›`). Nine red cards say less than three plus a
number.

## The fold budget

SPEC §9 makes one hard layout promise: on a 375 × 667 floor screen at text scale 1.0, the primary
card and both secondaries are fully visible without scrolling.

```
56 app bar + 64 odometer strip + 148 primary + 72 + 72 secondary + 48 see-all = 460
```

That leaves the first glance-tile row visible above a 62pt tab bar. A conditional strip (max 2)
pushes the *tiles* below the fold, never a card. Verify it as a golden at 375 × 667 in all six
locales — German and Persian are the ones that grow. This is the reason the all-clear card is
allowed to be shorter than the stack it replaces: the height it gives back is what pulls the
tiles above the fold.

## The 52px floor

`--touch-min: 52`. Three floors exist and only the largest one matters here:

| Floor | Source | Applies to |
|---|---|---|
| 44 | WCAG 2.5.8 / `accessibility-as-code` | Any app |
| 48 | Material, and SPEC §17's own checklist line | Any Material app |
| **52** | **Calm `--touch-min`** | **Every tappable in Odova** |

The number comes from the user in SPEC §1: one-handed, at a pump, in the rain, in a basement,
2–6 times a month. Gloved and wet-screen taps land with a larger and noisier centroid than a dry
indoor thumb, and a missed tap here is a re-entered odometer reading, not a re-tapped menu.

**The floor is on the hit rect, not the ink.** Calm ships several controls whose visible pill is
shorter — `.chip` 40, `.btn--sm` 42, `.due-card__more` and `.modal-head__action` 44,
`.segmented__opt` 46. Every one of those is a *drawn* height; each needs an explicit
`SizedBox(height: touchMin)` (or `ConstrainedBox(minHeight: touchMin)`) around a
`HitTestBehavior.opaque` gesture. `MaterialTapTargetSize.shrinkWrap` does the opposite and is
banned. `CalmButton` at `min-height: 52` and `CalmListRow` at 64 already clear the floor on their
own; a number-pad key is 68 because it is tapped in sequence and under time pressure.

Test it on the gesture node, not the ink:

```dart
final size = tester.getSize(find.byType(GestureDetector).first);
expect(size.height, greaterThanOrEqualTo(52));
expect(size.width, greaterThanOrEqualTo(52));
```
