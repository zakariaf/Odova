---
name: calm-components
description: >-
  Enforces Odova's Calm widget library in lib/ui/calm/ — CalmButton, CalmCard, CalmListRow,
  CalmRowGroup, CalmChip, CalmBadge, CalmStatusDot, CalmSwitch, CalmSegmented, CalmField,
  CalmSheet, CalmDialog, CalmScaffold, CalmAppBar, CalmTabBar, CalmNumberPad, CalmDueCard,
  CalmAllClear, CalmTile — with every value read through
  CalmColors/CalmType/CalmSpace/CalmShapes/CalmMotion.of(context). Presses are a 90ms scale-and-
  tint with NoSplash, never a Material ripple; cards are radius-2xl warm layered shadow and NEVER
  a border; rows exist only inside a CalmRowGroup; the field ring is the system's only border;
  52pt is a hit-area floor even where the painted control is smaller. Use when building or
  reviewing an Odova screen widget, adding a variant or state (rest/pressed/disabled/focus/error),
  reaching for ElevatedButton/FilledButton/TextButton/IconButton/ListTile/Card/Chip/Switch/Segment
  edButton/AppBar/NavigationBar/AlertDialog/SnackBar/showModalBottomSheet, writing a Container
  with a BoxDecoration in lib/ui/, wiring InkWell or splashColor, or asking what a Calm widget
  looks like pressed, focused, disabled or in error.---

# calm-components

Calm is a widget library before it is a palette. Nothing in Odova is a Material component with its colours patched: `ElevatedButton` is a 40pt ripple-driven rectangle with an M3 tonal elevation model, and every one of those facts is wrong for a system whose buttons are 52pt pills on warm clay, whose surfaces carry a two-layer warm shadow and no border, and which gets used one-handed at a fuel pump in the rain. This skill owns **what each Calm widget is, what states it has, and which token each state reads** — the biggest surface in the design system and the one where drift is cheapest to introduce and most expensive to find.

Read the reference for the task at hand:
- `references/component-inventory.md` — all 22 widgets plus their sub-parts: variants, states, the exact tokens each state reads, minimum touch size, what mirrors under RTL, and the **constructor parameter list**, which is the contract a composing screen must call.
- `references/interaction-and-press.md` — the scale-and-tint press, why Material's ripple is wrong here, the focus ring, disabled, loading, hover, and the reduced-motion collapse.
- `references/forms-and-fields.md` — `CalmField`, `CalmStepper`, `CalmSegmented`, `CalmSwitch`: the four visual states of an input and the ring that carries them. General form mechanics defer to `forms-and-input`.
- `references/overlays-and-chrome.md` — `CalmScaffold`, `CalmAppBar`, `CalmTabBar`, `CalmSheet`, `CalmDialog`, `CalmSnackbar`, `CalmNumberPad`: the chrome, the scrim, and the entry/exit motion.

Run `scripts/check_component_hygiene.sh` before a PR.

## Non-negotiable rules

1. **Every Calm widget lives in `lib/ui/calm/` and every aesthetic value it renders is a `*.of(context)` slot read.** `CalmColors`, `CalmType`, `CalmSpace`, `CalmShapes`, `CalmMotion` — never a literal, never `Theme.of(context).colorScheme` or `.textTheme` inside `lib/ui/`. **WHY:** `ColorScheme` exists so Material's own widgets theme themselves; a Calm widget that reads it inherits Material's role semantics (`primary` means "the tonal seed", not "clay") and quietly drifts from `odova.css`. `scripts/check_component_hygiene.sh` fails on both.
2. **Feature code never builds a `BoxDecoration`.** A surface in `lib/features/**` is a `CalmCard`, `CalmRowGroup`, `CalmTile` or `CalmSheet`, never a `Container` with a hand-rolled decoration. **WHY:** the two-layer warm shadow (`elev1` + the `sheen` hairline) is four values that will be reproduced wrong the first time someone types them by hand, and a card without the sheen reads flat against `--color-bg`.
3. **Press is a scale-and-tint, never a ripple.** `CalmPressable` is an explicit `AnimatedScale` over `CalmMotion.of(c).instant` (90ms) with `easeOut`, plus a background step to the next surface up — and `buildCalmTheme` sets `splashFactory: NoSplash.splashFactory` + `highlightColor: Colors.transparent` app-wide so any Material widget that slips through is silent too. Any surviving `InkWell`/`InkResponse` must carry `NoSplash.splashFactory` or the script fails. **WHY:** an ink splash is a cool circular wash spreading from the touch point across a 28pt-radius warm card — wrong colour family, wrong shape, and it outlives the touch by ~400ms, so a fast tap at a pump leaves a trailing artefact on a screen the user has already left. `NoSplash` alone is not enough either: the pressed highlight is a separate `InkHighlight` fade, and `InkWell` still needs a `Material` ancestor to paint into, which means a `Material` under every card and a second elevation model fighting `elev1`. See `references/interaction-and-press.md`.
4. **A card never has a border.** `CalmCard` is `surface` + `radius2xl` + `elev1` + `sheen`. Depth is the two shadow layers; when depth is unwanted the variant is `flat`/`tinted`/`quiet`, never a hairline outline. **WHY:** Calm's whole elevation story is "few, large, rounded surfaces separated by warm shadow"; one 1px outline in the stack makes every unbordered card next to it look unfinished, and `--color-divider` against `--color-surface` is 1.36:1 — a border that is invisible on the phone and obvious in a screenshot.
5. **A lone `CalmListRow` is a bug.** Rows go inside `CalmRowGroup`: one outer `radius2xl`, `ClipRRect`, `elev1` + `sheen` on the group, and a 1px `divider` hairline between adjacent rows only — never above the first or below the last. A single row outside a group uses `CalmListRow.standalone` (`radiusXl` + `elev1`). **WHY:** per-row radius and per-row shadow produce a striped, rattling list; the group is the surface and the rows are its contents.
6. **Nothing tappable is under `CalmSpace.of(c).touchMin` (52) as a *hit area*.** `CalmChip` paints 40, `CalmSegmented` paints 46, `CalmSwitch` paints 34 tall, `CalmStepper`'s buttons paint 48: each one wraps its painted box so the gesture target is 52. **WHY:** the design's own rule says nothing tappable is under 52 and its CSS ships six controls below it — that gap is real and it lands on the user, in the rain, wearing a glove. Expand the target, not the paint; growing the paint breaks the specimen sheet.
7. **Buttons are pills, large, and never silently disabled.** `CalmButton` sizes are `sm` 42 / `md` 52 / `lg` 60, `radiusPill`, `bodyLg` semi, `s6` inline padding. A disabled `CalmButton` (`surface2` / `ink4`) must be accompanied by `CalmButtonExplain` naming what is missing. **WHY:** SPEC §10 — "a greyed-out Save tells the user nothing"; on the five `log.*` forms Save is never disabled at all, it validates on tap and focuses the first failing field.
8. **The field ring is the only border in Calm.** `CalmField`'s input is `surface2` + `radiusLg` with a transparent 1.5 ring at rest, a 2.0 `brand` ring on `surface` when focused, and a 2.0 `overdue.base` ring on `overdue.tint` in error. Exactly two files in the tree may construct a `Border`: `calm_field.dart` (this ring) and `calm_pressable.dart` (the focus ring of rule 9). **WHY:** one border in the system means the ring reads unambiguously as "this control has your input"; the hygiene script allowlists exactly those two filenames and fails on every other `Border.all`/`BorderSide`.
9. **Focus is a 3pt `focus` ring drawn 3pt outside the control, and it never replaces the rest style.** It is painted in a `Stack` with `clipBehavior: Clip.none`, so it costs no layout. **WHY:** Flutter has no CSS `outline`; the naive port is a `Border` inside the box, which resizes the control on focus and makes a keyboard user's cursor jump. Focus is additive.
10. **A widget that carries due state resolves its colours through `CalmStatusStyle`, never a named status slot.** `CalmDueCard`, `CalmStatusDot`, `CalmBadge`, `CalmButton.onState` take a `DueState`, call `CalmStatusStyle.of(context, state)` and ask for `base`/`ink`/`tint`/`edge` — there is no `.color`. (`CalmStatusStyle.resolve(CalmColors, DueState)` is the same switch for a caller that already holds the extension, and for tests.) **WHY:** `unknown` and `needsOdometer` must stay distinguishable from `ok` and from each other (SPEC §1, §9); a widget that reads `colors.overdue` directly cannot be re-pointed when the state mapping changes. Owned by `calm-due-state-and-status`.
11. **Directional geometry only, and exactly six glyphs mirror.** `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`/`.end`, `Row`. Only the back chevron, the disclosure chevron, backspace, swap, undo and prev/next flip — via `CalmDirectionalIcon`. A car, a pump, a wrench, a clock and a check keep one canonical asset. **WHY:** SPEC §2 fails CI on a hard-coded `left`/`right`; a mirrored wrench is a bug report from every Persian reviewer. Owned by `calm-typography-and-rtl`.
12. **Every interactive Calm widget declares its `Semantics` role and its enabled state at the widget boundary**, and a composite row (`CalmListRow` with a `CalmSwitch` in its `end` slot) is one `MergeSemantics` node with one label. **WHY:** a row that reads as "Reminders, switch, on" in one gesture is usable; four separate nodes is not. The floor itself is owned by `accessibility-as-code`.

## What each Calm widget replaces

| Reach for | Use | Because |
|---|---|---|
| `ElevatedButton` / `FilledButton` / `TextButton` / `OutlinedButton` | `CalmButton` | M3 sizing (40pt), ripple, and tonal elevation are all wrong; Calm is 52pt, pill, scale-and-tint. |
| `IconButton` | `CalmButton.icon` | 48pt square with a ripple; Calm is a 52pt `surface2` pill. |
| `Card` | `CalmCard` | `Card` ships a `shape` with an optional `side` and Material's elevation shadow; Calm has no border and a two-layer warm shadow. |
| `ListTile` / `ListTileTheme` | `CalmListRow` inside `CalmRowGroup` | `ListTile` is 56pt with its own dense/three-line rules and no group radius. |
| `Chip` / `FilterChip` / `ActionChip` | `CalmChip` | Material chips are outlined and 32pt. |
| `Switch` / `SwitchListTile` | `CalmSwitch` in a `CalmListRow.switchRow` | Cupertino/Material track geometry differs from Calm's 56×34/28 thumb. |
| `SegmentedButton` | `CalmSegmented` | M3 segmented is outlined with a check-mark affordance; Calm is a tinted track with a raised active pill. |
| `TextField` / `TextFormField` bare | `CalmField` | Underline/outline decorations and 48pt heights; Calm is a filled 56pt field with an inset ring. |
| `AppBar` / `SliverAppBar` | `CalmAppBar` (`.large` variant) | Material's leading/title/centreTitle geometry and its scroll-tint overlay. |
| `NavigationBar` / `BottomNavigationBar` | `CalmTabBar` | Calm's tab bar is 62pt with a 62pt overhanging `+`. |
| `AlertDialog` / `showDialog` | `CalmDialog` | Dialog actions are stacked and full-width, not a trailing text-button row. |
| `showModalBottomSheet` | `CalmSheet` | Grip, `radius3xl` top corners, `elev4`, and the 420ms `easeStandard` rise. |
| `SnackBar` / `ScaffoldMessenger` | `CalmSnackbar` | Sits above the tab bar and home indicator, `surfaceInverse`, always carries Undo (SPEC §10). |
| The OS numeric keyboard for the odometer | `CalmNumberPad` | See below. |

## The press primitive

```dart
// lib/ui/calm/calm_pressable.dart — the ONE place a Calm press is defined.
final motion = CalmMotion.of(context);
final d = MediaQuery.disableAnimationsOf(context) ? Duration.zero : motion.instant;

AnimatedScale(
  scale: _pressed ? kCalmPressScaleButton : 1, // 0.98 — .btn:active in odova.css
  duration: d,                                   // --dur-instant, 90ms
  curve: motion.easeOut,                         // --ease-out
  child: AnimatedContainer(
    duration: d,
    curve: motion.easeOut,
    decoration: BoxDecoration(
      color: _pressed ? colors.surface3 : colors.surface2, // the tint step
      borderRadius: BorderRadius.circular(shapes.radiusXl),
    ),
    child: child,
  ),
);
```

Two things carry the press: **scale** and **one step up the surface ramp** (`surface` → `surface2` → `surface3`). The scale differs by widget mass — 0.98 for a button, 0.97 for a chip, 0.96 for a number-pad key, 0.94 for the tab-bar `+` — because a bigger surface needs a bigger displacement to read as the same amount of give. Under reduced motion the scale collapses to zero duration and the tint alone carries the press; it is never the only signal, because the tap's effect is. Full primitive — focus ring, `ActivateIntent`, the render object that expands a 40pt chip to a 52pt target, and `CalmDirectionalIcon`: `examples/calm_pressable.dart`. The button that consumes it: `examples/calm_button.dart`.

## The card and the row group

```dart
// A card is a surface, a radius, a padding and two shadow layers. Never a border.
Container(
  decoration: BoxDecoration(
    color: colors.surface,                                 // --color-surface
    borderRadius: BorderRadius.circular(shapes.radius2xl), // --radius-2xl, 28
    boxShadow: shapes.elev1,                               // --elev-1, both layers
  ),
  padding: EdgeInsets.all(space.s6),                       // --space-6, 24
  child: child, // the sheen hairline is painted over the top edge; see the example
);
```

`--elev-sheen` is `inset 0 1px 0 rgba(255,255,255,0.7)` and Flutter's `BoxShadow` cannot draw an inset shadow, so `CalmSurface` paints it as a 1px top-edge highlight inside a `ClipRRect`. Skipping it makes every card sit a shade flatter than the specimen sheet, most visibly on `numpad__key` where 12 keys lose their top light at once.

`CalmRowGroup` clips its children to one `radius2xl`, draws `elev1` + `sheen` once, and inserts a `divider` hairline **between** rows only. Full files — `CalmSurface` and `CalmCard` with its seven variants in `examples/calm_card.dart`; `CalmRowGroup` and `CalmListRow` with lead/main/end slots and its pressed, selected, danger, standalone and disabled states in `examples/calm_rows.dart`.

## The field

```dart
// Rest / focus / error are three (ring, fill) pairs. Nothing else changes.
final (Color ring, Color fill, double width) = switch ((focused, hasError)) {
  (_, true)     => (colors.overdue.base, colors.overdue.tint, 2), // --color-overdue on --color-overdue-tint
  (true, false) => (colors.brand, colors.surface, 2),         // --color-brand on --color-surface
  (false, false) => (Colors.transparent, colors.surface2, 1.5),
};
```

Error text is `overdue.ink` — Calm's error voice is the same confident terracotta as `overdue`, not a separate alarm red; `danger` is reserved for destructive *actions* (`btn--danger`, delete rows). The error line is `caption` medium with a leading glyph, one plain sentence, never a dialog (SPEC §10). Full file with `TextField`, a fully neutralised `InputDecoration`, the trailing unit affix and the computed-value state: `examples/calm_field.dart`. Validators, `FormState`, focus traversal and keyboard types belong to `forms-and-input` — do not restate them here.

## The number pad

`CalmNumberPad` exists because SPEC §10 targets "a fill-up logged one-handed at a pump, in the rain: four taps and two numbers, under fifteen seconds". The OS numeric keyboard puts ~40pt keys across the full width with the digits at the *top* of the keyboard — the far end of a thumb's arc on a large phone — and it renders whatever digit shapes the OS keyboard locale picks, which is not necessarily the user's active numbering system. Calm's pad is a 3-column grid of 68pt keys (`radiusXl`, `surface`, `elev1` + `sheen`) in the bottom third, with backspace and a `brand` confirm key spanning two columns, so the whole entry is inside one thumb sweep and the value stays visible above it at `--fs-display`. Keys use tabular lining figures. Full file: `examples/calm_number_pad.dart`.

## Anti-patterns

- **`InkWell` / `InkResponse` with the splash left on, or `splashFactory: InkRipple.splashFactory`** — the ripple is cool-toned, circular, and outlives the touch; it also drags a `Material` ancestor and a second elevation model into every card.
- **`Container(decoration: BoxDecoration(...))` in a feature directory** — the sheen and the second shadow layer will be missing and nobody will notice until the two cards sit side by side.
- **A `CalmCard` given a `border`, or a `Card(shape: RoundedRectangleBorder(side: BorderSide(...)))`** — Calm's only borders are the field ring and the focus ring; a surface never has one.
- **A `CalmListRow` used directly in a `Column`** — you get a row with no radius, no shadow, and dividers that run to the screen edge.
- **Growing a chip or a segment to 52pt to satisfy the touch floor** — the floor is a *hit area*; the paint stays at 40/46 or the specimen sheet is wrong.
- **A disabled `CalmButton` with no `CalmButtonExplain`** — SPEC §10 forbids it; the user is left guessing which of six fields is at fault.
- **Reading `colors.overdue` inside a widget to tint a due item** — go through `CalmStatusStyle(DueState)`, or `unknown` will one day render as `overdue` on a used car's first launch.
- **`EdgeInsets.only(left: …)`, `Alignment.centerLeft`, `TextAlign.left`** — fails the RTL gate in `i18n-rtl-l10n` and silently breaks fa/ar/ckb.
- **Mirroring an icon that is not one of the six directional glyphs** — a flipped wrench, pump or clock is the most-reported bug class in an RTL port.
- **A shorter press duration under reduced motion instead of `Duration.zero`** — the tint still fires, so nothing is lost; a "gentler" animation is still an animation.
- **Rebuilding a Material component's look inside a Calm widget (`ListTile` wrapped in a `Theme`)** — you inherit its density rules, its 56pt floor and its ripple, and you own the divergence forever.

## Definition of done

- [ ] `scripts/check_component_hygiene.sh` is clean over `lib/` (no `BoxDecoration` outside `lib/ui/calm/`, no live splash, no border outside `calm_field.dart`/`calm_pressable.dart`, no Material substitutes, no `colorScheme`/`textTheme` reads in `lib/ui/`).
- [ ] `calm-tokens/scripts/check_raw_values.sh` is clean — every colour, radius, duration and font size in `lib/ui/calm/` is a `Calm*.of(context)` read.
- [ ] Every widget in the inventory renders rest, pressed, disabled and — where it applies — focus and error, and each state is in the golden set for light **and** dark.
- [ ] Every tappable widget has a ≥52pt hit area, asserted by a `getSize`/`getRect` test, not by eye (`widget-golden-and-a11y-testing`).
- [ ] Presses go through `CalmPressable` (`AnimatedScale` + surface-ramp tint, duration collapsing to zero under `MediaQuery.disableAnimationsOf`); `buildCalmTheme` sets `NoSplash.splashFactory` app-wide.
- [ ] No `CalmCard`, `CalmRowGroup`, `CalmTile` or `CalmSheet` draws a border; the only `Border`s in the tree are the field ring and the focus ring.
- [ ] Rows appear only inside a `CalmRowGroup` or as `CalmListRow.standalone`; the group draws one radius and internal dividers only.
- [ ] Every disabled `CalmButton` on screen has a `CalmButtonExplain` beneath it; no `log.*` form disables Save at all.
- [ ] Every state-tinted widget resolves through `CalmStatusStyle`; a grayscale golden still tells `unknown` from `overdue`.
- [ ] RTL goldens exist for every screen that uses a row, a field or a chip; only the six directional glyphs differ between them.

## Related skills

- See `calm-design-system` for the front door and the routing table across the six Calm skills.
- See `calm-tokens` for `CalmColors`/`CalmType`/`CalmSpace`/`CalmShapes`/`CalmMotion`, the asserting `of()`, and the hand-authored `ColorScheme` these widgets sit on.
- See `calm-due-state-and-status` for `DueState`, `CalmStatusStyle`, and the dot-shape-is-normative rule that `CalmStatusDot` implements.
- See `calm-typography-and-rtl` for the type scale, the 13px floor, Vazirmatn's per-locale leading, and which glyphs mirror.
- See `calm-layout-and-motion` for the spacing rhythm, one-primary-thing-per-screen, the screen scaffold, and the motion/reduced-motion contract these widgets read.
- See `design-system-structure` for token *structure* — tiers, `ThemeExtension` mechanics, the no-raw-values gate this skill's script sits beside.
- See `forms-and-input` for `Form`/`GlobalKey<FormState>`, validators, focus traversal and keyboard types; `CalmField` is the skin, not the mechanics.
- See `ui-states-and-feedback` for loading/empty/error screen states that `CalmEmptyState` and `CalmAllClear` render.
- See `accessibility-as-code` for `Semantics` roles, the never-colour-alone floor and target sizes.
- See `widget-composition` for extracting these as named `const` widgets instead of `_buildRow()` methods.
- See `motion-and-haptics` for which of these presses also fire a haptic.
- See `widget-golden-and-a11y-testing` for the per-state, per-theme, per-direction golden matrix.

## References

- Flutter API — `NoSplash.splashFactory`: https://api.flutter.dev/flutter/material/NoSplash/splashFactory-constant.html
- Flutter API — `InkWell` (splash/highlight, required `Material` ancestor): https://api.flutter.dev/flutter/material/InkWell-class.html
- Flutter API — `AnimatedScale`: https://api.flutter.dev/flutter/widgets/AnimatedScale-class.html
- Flutter API — `FocusableActionDetector` (focus highlight, hover, `ActivateIntent`): https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html
- Flutter API — `BoxShadow` / `BoxDecoration` (no inset shadow): https://api.flutter.dev/flutter/painting/BoxShadow-class.html
- Flutter API — `MediaQueryData.disableAnimations`: https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
- Flutter API — `EdgeInsetsDirectional`: https://api.flutter.dev/flutter/painting/EdgeInsetsDirectional-class.html
- Flutter API — `MergeSemantics`: https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html
- Flutter API — `FontFeature.tabularFigures`: https://api.flutter.dev/flutter/dart-ui/FontFeature/FontFeature.tabularFigures.html
- W3C WAI — WCAG 2.2 SC 2.5.8 Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- W3C WAI — WCAG 2.2 SC 1.4.11 Non-text Contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
