# Interaction: press, focus, disabled, loading

Calm's touch feedback is a **scale-and-tint**, and it is the single most-copied detail in the library. Get it once, in `CalmPressable`, and every widget inherits it.

## Why Material's ripple is wrong here

`InkWell` is not "a tap handler with a splash you can turn off". Four separate problems:

1. **It paints into a `Material` ancestor, not into itself.** An `InkWell` with no `Material` above it throws; putting one there gives that subtree a second surface with its own `elevation`, `shadowColor` and `surfaceTintColor`, fighting the `elev1` + `sheen` the `CalmCard` already drew. You end up with two elevation models on one card.
2. **The splash geometry is wrong.** It is a circle expanding from the touch point to cover the box. Calm's surfaces are 28–36pt-radius rectangles with a lot of air; a circle sweeping across one reads as a wet patch, not as a button depressing.
3. **The splash colour is not a Calm token.** It comes from `ThemeData.splashColor`/`highlightColor` — grey-blue by default and unrelated to the `surface → surface2 → surface3` ramp every other Calm press step uses.
4. **It outlives the touch.** The splash animates *out* over roughly 400ms after release. A fill-up is four taps in fifteen seconds; the artefact from tap two is still fading when tap four lands, and it keeps painting on a route the user has already left.

`NoSplash.splashFactory` fixes only the splash. The **pressed highlight** is a separate `InkHighlight` fade — kill it with `highlightColor: Colors.transparent` — and the hover/focus overlays are two more. Which is why Calm does not use `InkWell` at all: `CalmPressable` is a `FocusableActionDetector` over a `GestureDetector`, and it owns all four channels itself.

## The press, exactly

| Channel | Value | Token |
|---|---|---|
| Scale | 0.98 button · 0.97 chip · 0.96 number-pad key · 0.94 tab-bar `+` | *none — see findings* |
| Duration | 90ms | `motion.instant` (`--dur-instant`) |
| Curve | `easeOut` | `motion.easeOut` (`--ease-out`) |
| Tint | one step up the ramp: `surface`→`surface2`, `surface2`→`surface3` | `colors.surface2` / `colors.surface3` |
| Tint duration | 90ms on keys, 160ms elsewhere | `motion.instant` / `motion.quick` |
| Shadow | dropped to none while pressed on `primary`, `numpad__key` | `shapes.elev0` |

The scale differs by widget mass on purpose: 0.98 on a 52pt pill and 0.94 on a 62pt circle are roughly the same displacement in points, so they read as the same amount of give. Both scale and tint fire — the tint is what survives reduced motion.

`AnimatedScale` is the right primitive, not `Transform.scale` inside a `setState`: it interpolates on the compositor-friendly path and it needs no controller to dispose. Anchor it at `Alignment.center` (the default) so a wide `block` button squeezes symmetrically.

## Reduced motion

```dart
Duration calmDuration(BuildContext context, Duration full) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;
```

Collapse to **zero**, never to a shorter duration. The tint still applies instantly, so the press is still legible — motion was never the only signal. This helper is Calm's single motion gate; `calm-layout-and-motion` owns the rest of the moment catalogue, and `design-system-structure` owns the rule.

## Focus

CSS ships `outline: 3px solid var(--color-focus); outline-offset: 3px`. Flutter has no `outline`, and the naive port — a `Border` on the control's own decoration — grows the control by 6pt when it takes focus, so a keyboard user watches the layout jump row by row.

Draw it **outside the layout** instead:

```dart
Stack(
  clipBehavior: Clip.none, // the ring lives outside the child's box
  children: [
    child,
    if (focused)
      Positioned.fill(
        left: -kCalmFocusOutset, top: -kCalmFocusOutset,
        right: -kCalmFocusOutset, bottom: -kCalmFocusOutset, // 3 offset + 3 width
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + kCalmFocusOutset),
              border: Border.all(color: colors.focus, width: kCalmFocusWidth),
            ),
          ),
        ),
      ),
  ],
)
```

`--color-focus` is `#A8794F` light / `#D6A874` dark: 3.42:1 and 8.14:1 against `--color-bg`, so it clears the 3:1 non-text floor in both themes. Focus is **additive** — it never replaces the rest style, because a control that changes fill on focus is indistinguishable from one that changes fill on selection.

Use `FocusableActionDetector` rather than a raw `Focus`: it gives `onShowFocusHighlight` (which is *keyboard* focus, not any focus — a mouse tap should not draw the ring), `onShowHoverHighlight`, a `mouseCursor`, and an `actions` map so Enter and Space activate the control the same way a tap does. Without the `ActivateIntent` action a `GestureDetector`-based widget is focusable and unusable.

## The 52pt target on a 40pt control

`--touch-min` is 52, and `odova.css` ships six interactive controls below it: `.chip` 40, `.segmented__opt` 46, `.stepper__btn` 48, `.switch` 34 tall, `.due-card__more` and `.modal-head__action` 44, `.notice__close` 32. The design's own rule and the design's own CSS disagree; the code resolves it in favour of the rule, without repainting anything.

`CalmPressable(expandTapTarget: true)` wraps the control in `CalmTapTarget`, a `RenderShiftedBox` that lays the child out at its natural size, reports `max(child, 52)` as its own, centres the child in it, and hit-tests the whole padded box (the same trick Material's `_InputPadding` plays for `materialTapTargetSize: padded`). The chip still paints 40 and still matches the specimen sheet; the finger gets 52. Growing the paint instead would be a redesign, and a redesign nobody reviewed.

Assert it, do not eyeball it: `tester.getSize(find.byType(CalmChip))` in a widget test, per control, per text scale.

## Disabled

Disabled is a **colour swap, not an opacity fade**, on everything that has a token pair for it: `CalmButton` goes to `surface2`/`ink4`, `CalmField` to `bgSunk`/`ink4`, `CalmStepper`'s button drops its shadow and goes to `ink4`. The CSS fades `.row`, `.chip` and `.switch` with `opacity` (0.42 / 0.45 / 0.40) instead; reproduce that with `Opacity` only for those three, and never wrap a whole card — a faded card fades its shadow into a grey smear.

A disabled control still gets `Semantics(enabled: false)` and still absorbs the tap (`HitTestBehavior.opaque` with a null callback), so a mis-tap does not fall through to the row behind it. And a disabled `CalmButton` carries `CalmButtonExplain` beneath it, always.

## Loading

`.btn.is-loading` hides the label (`color: transparent`) and centres a 20pt two-thirds ring spinning at 900ms linear. Keep the button's width — swapping the label for a spinner mid-press reflows the row and moves whatever is next to it under the user's thumb. In Dart: keep the `Text` in the tree wrapped in `Opacity(opacity: 0)` so it still contributes its intrinsic width, and stack the indicator over it.

## Hover

Hover exists (desktop, and a stylus) and steps the same ramp as press without the scale. It is never the only affordance; there is no pointer at a fuel pump.
