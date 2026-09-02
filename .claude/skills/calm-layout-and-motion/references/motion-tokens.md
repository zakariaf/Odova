# Motion tokens

Nine values, closed. Five durations, four cubics. The general mechanics of reduced motion — the
three animations Material mounts by default, `NoSplash` not covering `InkHighlight`, the
`pumpAndSettle` ban — belong to `design-system-structure`'s
`references/motion-and-reduced-motion.md`; this file is only Calm's content and the rules that
follow from these particular numbers.

## The five durations

| Token | Dart | ms | Spent on, in `odova.css` |
|---|---|---|---|
| `--dur-instant` | `instant` | 90 | Press feedback: `.btn` `scale(0.98)`, `.numpad__key` `scale(0.96)`, `.chip` `scale(0.97)`. Under ~100ms a press reads as *mechanical*, not animated. |
| `--dur-quick` | `quick` | 160 | Colour and background changes: row/app-bar hover tints, tab-bar label colour, the FAB releasing to `scale(1)`. |
| `--dur-base` | `base` | 240 | State transitions with travel: the scrim fade, the dialog pop, the segmented thumb, the switch knob. |
| `--dur-slow` | `slow` | 360 | The due-card progress line filling. The only thing the user is *meant* to watch. |
| `--dur-sheet` | `sheet` | 420 | `CalmSheet` rising. The only value over a third of a second, and the only place it is allowed. |

If a moment does not fit one of the five, it is the moment that is wrong. A sixth duration is how
an app stops feeling like one system.

## The four curves

Flutter has no `Curves.*` constant equal to any of these — every one is a literal `Cubic`, and
they live in `lib/theme/calm/calm_motion.dart` where the no-raw-values gate allows them.

| Token | Dart | `Cubic(...)` | Use |
|---|---|---|---|
| `--ease-standard` | `easeStandard` | `Cubic(0.32, 0.72, 0, 1)` | Travel across the screen: the sheet's rise, the segmented thumb, the progress fill. Slow tail, hard stop. |
| `--ease-out` | `easeOut` | `Cubic(0.2, 0.8, 0.2, 1)` | The workhorse. Colour, background, opacity, tint — anything that changes in place. |
| `--ease-in` | `easeIn` | `Cubic(0.4, 0, 1, 1)` | Leaving. Accelerates away and never comes back. |
| `--ease-settle` | `easeSettle` | `Cubic(0.34, 1.24, 0.64, 1)` | Arrival, and arrival only. The `1.24` control point overshoots past 1.0 and settles back. |

Note the naming break: durations drop their category prefix (`--dur-base` → `base`) but curves
keep theirs (`--ease-in` → `easeIn`). That is not a style choice — `in` is a reserved word in Dart
and cannot be an identifier, so the curves take the prefixed spelling as a set rather than one
inconsistent member.

## `easeSettle` arrives; it never leaves

An overshoot says *this thing landed here*. Run backwards it says *this thing recoiled from you*.

```dart
// RIGHT — the dialog pops in (odova.css: `calm-pop 240ms ease-settle`).
ScaleTransition(
  scale: CurvedAnimation(parent: controller, curve: motion.easeSettle),
  child: const CalmDialog(...),
);

// RIGHT — asymmetric: settle in, easeIn out.
CurvedAnimation(
  parent: controller,
  curve: motion.easeSettle,
  reverseCurve: motion.easeIn.flipped,
);

// WRONG — an overshoot on opacity. Opacity asserts 0.0 <= opacity <= 1.0, so this
// is a debug-mode crash the first time the curve passes 1.0, not a style nit.
FadeTransition(
  opacity: CurvedAnimation(parent: controller, curve: motion.easeSettle),
  child: child,
);
```

The same trap catches `AnimatedOpacity(curve: motion.easeSettle)`, `Opacity` driven by a
`Tween<double>` under an overshoot curve, and any `ColorTween` where you rely on the endpoint —
`Color.lerp` clamps past 1.0, so the overshoot silently does nothing there instead of crashing,
which is worse. Overshoot belongs on scale, offset and size.

Calm's three keyframed entrances, for reference: scrim `calm-fade` at `base`/`easeOut`, sheet
`calm-rise` (translateY 24 → 0, opacity 0.6 → 1) at `sheet`/`easeStandard`, dialog `calm-pop`
(scale 0.96 → 1, opacity 0 → 1) at `base`/`easeSettle` — and note the dialog splits its channels:
scale takes the settle, opacity does not.

## Reduced motion is zero

One helper, `design-system-structure`'s:

```dart
Duration resolveMotion(BuildContext context, Duration full) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : full;
```

Every `CalmMotion` read at a call site goes through it. Calm adds two obligations on top of the
general rule:

- **`themeAnimationStyle: AnimationStyle.noAnimation` on `MaterialApp`.** Without it, `MaterialApp`
  crossfades `ThemeData` over `kThemeAnimationDuration` on every light/dark switch, and Calm's
  light and dark grounds are far apart (`#F8F2E9` → `#1D1815`) — a 200ms crossfade between them is
  the largest luminance event in the app, on a surface the user did not ask to animate.
- **Never branch to a shorter duration.** `disableAnimationsOf(context) ? motion.instant :
  motion.base` is the rule violated in the shape of obedience. The user asked for stop.

Because the end state must carry the meaning on its own, nothing in Calm is *only* announced by
motion: the snackbar's arrival is redundant with its text, the sheet's rise is redundant with the
scrim, and the all-clear card does not animate at all.

## Tests

`pumpAndSettle()` in a test that asserts the collapsed path is asserting nothing — there is
nothing to settle, and it carries a 10-minute default timeout and truncates its stack trace when
it fires. `scripts/check_touch_targets.sh` fails any file under `test/` that mentions both
`disableAnimations` and `pumpAndSettle`.

```dart
testWidgets('sheet does not animate under reduce-motion', (tester) async {
  await tester.pumpWidget(const MediaQuery(
    data: MediaQueryData(disableAnimations: true),
    child: CalmSheetHost(),
  ));
  await tester.tap(find.byType(CalmButton));
  await tester.pump();                                  // one frame, not pumpAndSettle
  expect(tester.binding.hasScheduledFrame, isFalse,
      reason: 'Something is still animating with disableAnimations set.');
});
```

`pump()` does not advance the fake clock — a debounce, a `Timer` or the snackbar's own dismissal
delay still needs `pump(duration)` or `fakeAsync`.

## Honest limit

`MediaQuery.disableAnimationsOf` reflects the OS flag where the platform reports it. It does not
reach inside a third-party widget that animates unconditionally. Odova has no third-party UI
packages by policy (SPEC §2's no-network posture keeps the dependency list short), so if one
appears in a diff, its motion is your problem to audit.
