---
name: calm-layout-and-motion
description: >-
  Enforces Calm's spatial and motion discipline: the ten-step CalmSpace scale plus a 22pt screen
  gutter, ONE primary element per screen sized far above everything else (two primaries means the
  screen has failed), a 52pt touch floor above Material's 48, CalmScaffold as the screen skeleton,
  and the all-clear state designed as the good state — a reassuring mark, the good news in plain
  words, the date it was last confirmed and exactly one quiet next action, never an empty-state
  shrug. Motion is five durations and four curves from CalmMotion
  (easeStandard/easeOut/easeIn/easeSettle); easeSettle's overshoot is for a thing arriving, never
  leaving; reduced motion means zero, not faster. Use when laying out or reviewing an Odova
  screen, choosing spacing or a gap, sizing a tap target, building an empty/nothing-due state,
  animating anything, or writing pumpAndSettle in a test.---

# calm-layout-and-motion

Calm's whole argument is restraint: a screen earns attention by having *one* thing worth attending to, and motion earns its cost by being short, few, and skippable. Both halves fail the same way — by accretion. A second "important" card and a second easing curve are each individually defensible and collectively fatal. This skill owns Calm's spatial and temporal budget: the spacing scale, the one-primary rule, the 52px touch floor, `CalmScaffold`, the all-clear state Odova lands on more often than any other, and the five durations and four curves that are the entire motion vocabulary.

Read the reference for the task at hand:
- `references/spacing-and-rhythm.md` — the ten-step scale and the 22px gutter with real values, the padding/gap table per surface, the one-primary test, the 52px floor vs the 44/48 floors below it, and Home's above-the-fold budget.
- `references/the-all-clear-state.md` — why "nothing is due" is the good state, the four things `CalmAllClear` contains, the four it must never contain, and how it differs from `CalmEmptyState`.
- `references/motion-tokens.md` — the five durations and four cubics with what each is for, the `ease-settle` arrival-only rule and the `Opacity` assertion it trips, and Calm's reduced-motion posture.

Run `scripts/check_touch_targets.sh` before a PR.

## Non-negotiable rules

1. **Every spatial value is a `CalmSpace` slot; the scale is exactly ten steps plus one gutter.** `s1 4 · s2 8 · s3 12 · s4 16 · s5 20 · s6 24 · s7 32 · s8 40 · s9 56 · s10 72`, and `screenPad = 22`. A widget that writes `16` fails `check_raw_values.sh`; a widget that wants `18` is asking for a step that does not exist. WHY: the scale is non-linear on purpose — 4px steps while the eye reads them as distinct, then 8/16 jumps once it cannot. Inserting between steps destroys the only thing a scale buys you, which is that two unrelated screens land on the same rhythm.
2. **`screenPad` (22) is the horizontal gutter and nothing else.** It is not a card padding, not a gap, not a vertical inset. Card interiors use `s5`/`s6`; the screen body's vertical inset is `s5` top, `s6` bottom. WHY: 22 is deliberately off-scale so that a gutter can never be confused with a gap — if it were `s5`, a card at `s5` padding would optically merge with the screen edge.
3. **One primary element per screen, sized far above everything else.** On Home that is the 148pt `CalmDueCard` at `primary` density (title `headline` 19, status `titleLg` 27) against 72pt secondaries (title `body` 15, status `caption` 13) — a ~2× area ratio and a 2-step type gap. If two elements on a screen are within one type step and one radius step of each other, the screen has no primary and has failed. WHY: SPEC §9 says Home answers *one* question. Two primaries mean the user has to choose what to read first, which is the work the app exists to do for them.
4. **The touch floor is 52 logical pixels on the *hit target*, not the ink.** `--touch-min: 52`. The pill you can see may be shorter (a chip's ink is 40); the region that responds must be ≥ 52 in both axes, via an explicit `SizedBox`/`ConstrainedBox` around the gesture, never `MaterialTapTargetSize.shrinkWrap`. `scripts/check_touch_targets.sh` fails on a control-sizing literal below 52. WHY: `accessibility-as-code` sets 44 and Material sets 48 for a person sitting still indoors. SPEC §1 says this app is used at a fuel pump, one-handed, in the rain, in a basement — 52 is the number that survives that, and it is what the shipped `.btn` already is.
5. **`CalmScaffold` is the only screen skeleton.** A bare `Scaffold` in `lib/ui/` is a bug. It owns the 56pt app bar, the scrolling body at `screenPad` with `s5` between children, the optional non-scrolling foot, and the 62pt tab bar. WHY: the gutter, the body gap, the bottom safe inset and the snackbar offset are one composition; four screens re-deriving them is four chances to be 2px off.
6. **Bottom chrome comes from `MediaQuery.paddingOf`, never from a token.** `--statusbar-h: 54` and `--homebar-h: 34` are specimen-sheet chrome for `system.html`. On device the home indicator is `MediaQuery.paddingOf(context).bottom`, which is 0 on a Pixel 4a and 34 on an iPhone 15. WHY: hardcoding 34 puts a 34px dead band under the tab bar on every Android device in the fleet.
7. **All-clear is a designed state, not an absent one.** When nothing is due, `CalmAllClear` renders at the primary card's height and weight with the sage `ok.tint` wash, and carries exactly four things: the mark, the good news, the next item with its date, and the since-last-service line (SPEC §9). It never renders a shrug illustration, a "nothing here yet", a grey box, or a nag. WHY: SPEC §9 calls it "the most common state, and the one most apps waste" — ~70% of Home opens never leave Home, and most of those find nothing due. This is the screen the product is judged on.
8. **`CalmEmptyState` is for a list a user has not filled yet; `CalmAllClear` is for work that is done.** They are different widgets and are never substituted. Empty gets `.empty`'s neutral `surface2` art disc and one primary action; all-clear gets the sage wash and one *quiet* action. WHY: rendering "you are up to date" in the vocabulary of "you have nothing here" reads as a failure to load.
9. **Durations and curves come from `CalmMotion`; the vocabulary is five and four, closed.** `instant 90 · quick 160 · base 240 · slow 360 · sheet 420`, and `easeStandard · easeOut · easeIn · easeSettle`. A raw `Duration(...)` or `Curves.*` outside `lib/theme/calm/` fails both `check_raw_values.sh` and `check_touch_targets.sh`. WHY: five durations is already more than most screens use; a sixth is how an app stops feeling like one system.
10. **`easeSettle` is for a thing arriving and never for a thing leaving.** `Cubic(0.34, 1.24, 0.64, 1)` overshoots past 1.0 — it is the dialog's pop-in, the FAB releasing back to scale 1, a row settling into a list. Exits use `easeIn`; travel uses `easeStandard`. Never drive an `Opacity`/`FadeTransition`/`AnimatedOpacity` with it. WHY: an overshoot on the way out reads as the UI flinching away from the user, and `Opacity` asserts `0.0 <= opacity <= 1.0`, so an overshoot curve on opacity is a debug-mode crash, not a style nit.
11. **Reduced motion means zero, not "faster".** Route through the one `resolveMotion(context, …)` helper owned by `design-system-structure`, set `themeAnimationStyle: AnimationStyle.noAnimation` on `MaterialApp`, and never write `pumpAndSettle()` in a test that asserts the collapsed path. WHY: a test that settles an animation it just proved does not exist is asserting nothing; the general mechanics (the three animations Material mounts, `NoSplash` not covering `InkHighlight`) belong to `design-system-structure` — see `design-system-structure/references/motion-and-reduced-motion.md`.
12. **No `left`/`right` in any inset, alignment or offset.** `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `start`/`end`. WHY: SPEC §2 makes this a CI gate — three of Odova's six locales are RTL and the rule is what keeps that true as the app grows. `calm-typography-and-rtl` owns what mirrors and what does not.

## The scale, as Dart

```dart
// Read, never write. `--space-4` -> `s4`; `--screen-pad` -> `screenPad`.
final space = CalmSpace.of(context);

Padding(
  padding: EdgeInsetsDirectional.symmetric(horizontal: space.screenPad), // 22
  child: Column(
    spacing: space.s5,                                                   // 20 between cards
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: const [OdometerStrip(), PrimaryDueCard(), SecondaryDueCard()],
  ),
);
```

The four gaps that cover ~every Calm surface, straight off `odova.css`:

| Where | Value | Slot |
|---|---|---|
| Between screen-body children | 20 | `s5` |
| Between a section header and its content, and inside a card | 12 | `s3` |
| Inside a `CalmRowGroup` header/footer pad | 8 / 16 | `s2` / `s4` |
| Card padding — plain / primary due card / all-clear | 24 / 24 / 40·24·32 | `s6` / `s6` / `s8 s6 s7` |

Full table including every radius pairing: `references/spacing-and-rhythm.md`.

## `CalmScaffold` — the screen skeleton

```dart
CalmScaffold(
  appBar: const CalmAppBar(title: 'Der Golf', showVehicleChevron: true), // 56pt
  tabBar: CalmTabBar(                                                    // 62pt
    index: 0,
    onChanged: onTab,
    onAdd: openLogSheet,
    addLabel: l10n.addEntry,
    labels: [l10n.home, l10n.history, l10n.costs, l10n.settings],
  ),
  children: const [                                          // gap s5, gutter 22
    OdometerStrip(),
    PrimaryDueCard(),
    SecondaryDueCard(),
    SeeAllRemindersRow(),
    GlanceTiles(),
  ],
);
```

`children` go into a scrolling body so text scale and six languages cannot clip anything; SPEC §9's above-the-fold budget (56 + 64 + 148 + 2×72 + 48 = 460 on a 375×667 floor screen) is a *layout* obligation verified by a golden, not a reason to make the body non-scrolling. Full widget with the app bar, the overflowing tab-bar FAB and the snackbar offset: `examples/calm_scaffold.dart` (its token slots come from `examples/calm_tokens_min.dart`, which stands in for `lib/theme/calm/`).

## The 52px floor, in practice

```dart
// The chip's ink is 40 tall (Calm's `.chip`); its TARGET is 52. Both are true.
Semantics(
  button: true,
  selected: selected,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque, // the whole 52 responds, not just the pill
    onTap: onTap,
    child: SizedBox(
      height: CalmSpace.of(context).touchMin, // 52 — the gate reads this line
      child: Center(child: _ChipInk(selected: selected, label: label)),
    ),
  ),
);
```

`MaterialTapTargetSize.shrinkWrap` is banned outright: it removes Material's own 48 padding and leaves whatever the ink happens to be. Calm's `.chip` (40), `.btn--sm` (42), `.due-card__more` (44) and `.segmented__opt` (46) are all *ink* heights — every one of them needs this wrapper.

## Motion, as Dart

```dart
final motion = CalmMotion.of(context);

AnimatedContainer(
  duration: resolveMotion(context, motion.quick),   // 160ms — a colour change
  curve: motion.easeOut,                            // Cubic(0.2, 0.8, 0.2, 1)
  decoration: BoxDecoration(
    color: pressed ? colors.surface2 : colors.surface,
    borderRadius: CalmShapes.of(context).radius2xl,
  ),
  child: child,
);
```

| Token | ms | Spend it on |
|---|---|---|
| `instant` | 90 | Press feedback — the button's `scale(0.98)`, a number-pad key's `scale(0.96)`. |
| `quick` | 160 | Colour, background and tint changes; the tab-bar label swap; the FAB's release. |
| `base` | 240 | The scrim fade, the dialog pop, the segmented thumb, the switch. |
| `slow` | 360 | A progress line filling — the one thing the user is meant to watch. |
| `sheet` | 420 | The bottom sheet rising. The only duration over a third of a second. |

`examples/calm_motion.dart` has the `CalmMotion` extension with all five durations and four `Cubic`s, the arrival/exit pairing and the theme-root switches; `examples/calm_all_clear.dart` has `CalmAllClear` and `CalmEmptyState` side by side.

## Anti-patterns

- **A second card on Home styled to compete with the primary** — same radius, same weight, "just slightly smaller". The screen now asks a question instead of answering one; SPEC §9 caps the stack at 1 primary + 2 secondaries and 3 cards total *however many* are overdue.
- **`padding: EdgeInsets.all(20)` on a screen because 22 "looked too wide"** — the gutter is 22 and the card padding is `s6`; a 20 that is neither is a screen that will never line up with the one next to it.
- **`SizedBox(height: 44)` around an icon button** — 44 is `accessibility-as-code`'s floor for an app used indoors. Calm's is 52; the gate cannot see a bare `SizedBox`, so assert `tester.getSize()` on the gesture node instead.
- **`MaterialTapTargetSize.shrinkWrap`, or trusting `IconButton`'s default 48** — both land under the floor, and `shrinkWrap` lands wherever the icon does.
- **`SafeArea` omitted, or `--homebar-h`'s 34 hardcoded as a bottom inset** — one clips under the home indicator on iPhone, the other opens a 34px dead band on every Android device.
- **An `.empty` art disc and "Nothing here yet" when the user is simply up to date** — the most common state in the app rendered as a failure. Use `CalmAllClear`.
- **An all-clear card with a "Log a service" primary button** — nothing is due; a primary CTA turns the reward into a chore. One quiet action, at most.
- **`easeSettle` on a dismissal, a fade, or a `FadeTransition`** — an overshoot on exit reads as a flinch, and on opacity it trips `Opacity`'s `0.0 <= opacity <= 1.0` assert in debug.
- **`Duration(milliseconds: 300)` or `Curves.easeInOut` in a widget** — 300 and `easeInOut` are Material's defaults, not Calm's; both fail the gate.
- **`MediaQuery.disableAnimationsOf(context) ? motion.instant : motion.base`** — the user asked for stop, not for 90ms. Resolve to `Duration.zero`.
- **`await tester.pumpAndSettle()` in a reduced-motion test** — there is nothing to settle; it hides the frame you meant to assert on and carries a 10-minute timeout.
- **`Positioned(left: …)` or `EdgeInsets.only(left: …)` anywhere in `lib/ui/`** — fails SPEC §2's CI gate and silently breaks fa/ar/ckb.

## Definition of done

- [ ] `scripts/check_touch_targets.sh` is clean: no control-sizing literal under 52, no `MaterialTapTargetSize.shrinkWrap`, no raw `Duration`/`Curves` outside `lib/theme/calm/`, no `pumpAndSettle` in a reduced-motion test.
- [ ] `calm-tokens/scripts/check_raw_values.sh` is clean — every spacing, radius, duration and curve traces to `CalmSpace` / `CalmShapes` / `CalmMotion`.
- [ ] Every screen is a `CalmScaffold`; no bare `Scaffold` under `lib/ui/`.
- [ ] Each screen has exactly one primary element, ≥ 2 type steps above the next thing down; a squint test or a blurred golden still shows one focus.
- [ ] Every tappable's hit rect is ≥ 52 × 52, verified by a widget test on `tester.getSize()` of the gesture node — not of its ink.
- [ ] Home meets SPEC §9's budget: primary + both secondaries fully visible at 375 × 667, text scale 1.0, in all six locales.
- [ ] "Nothing due" renders `CalmAllClear` with all four elements, and the glance tiles are still above the fold.
- [ ] No `left`/`right` in any inset, alignment or `Positioned` under `lib/ui/`.
- [ ] Every animation reads a `CalmMotion` token and collapses to `Duration.zero` under `MediaQuery.disableAnimationsOf`; `themeAnimationStyle: AnimationStyle.noAnimation` is set on `MaterialApp`.
- [ ] `easeSettle` appears only on entrances; no opacity animation uses it.
- [ ] Bottom insets come from `MediaQuery.paddingOf(context).bottom`; `--statusbar-h` / `--homebar-h` appear nowhere in Dart.

## Related skills

- See `calm-design-system` for what Calm is and the routing table to the other five Calm skills.
- See `calm-tokens` for the `CalmSpace` / `CalmMotion` / `CalmShapes` extensions themselves, the asserting `of()`, and the light/dark `ColorScheme`.
- See `calm-components` for the widgets this skill lays out — `CalmButton`, `CalmCard`, `CalmRowGroup`, `CalmChip`, `CalmSheet`, `CalmTabBar`.
- See `calm-due-state-and-status` for what the primary slot actually renders and why `unknown` never takes it.
- See `calm-typography-and-rtl` for the type steps the one-primary rule counts in, and for what mirrors.
- See `design-system-structure` for the general reduced-motion mechanics — `resolveMotion`, the three animations Material mounts by default, `NoSplash` vs `InkHighlight`, and the `pumpAndSettle` ban.
- See `accessibility-as-code` for the 44px baseline Calm raises to 52, and for reading a11y flags from `MediaQuery`.
- See `adaptive-layout` for `LayoutBuilder`, `MediaQuery.sizeOf`, SafeArea and display cutouts.
- See `motion-and-haptics` for the moment catalog and the haptic paired with each of these durations.
- See `ui-states-and-feedback` for resolving loading/empty/error/content in one switch — the switch whose "empty" arm chooses between `CalmAllClear` and `CalmEmptyState`.
- See `widget-golden-and-a11y-testing` for the 375 × 667 golden that proves the fold budget.

## References

- Flutter API — `MediaQueryData.padding` / `paddingOf`: https://api.flutter.dev/flutter/widgets/MediaQuery/paddingOf.html
- Flutter API — `Cubic` (cubic Bézier curves; values may exceed [0,1]): https://api.flutter.dev/flutter/animation/Cubic-class.html
- Flutter API — `Opacity` (asserts `opacity >= 0.0 && opacity <= 1.0`): https://api.flutter.dev/flutter/widgets/Opacity-class.html
- Flutter API — `MaterialTapTargetSize`: https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html
- Flutter API — `AnimationStyle` (`noAnimation`): https://api.flutter.dev/flutter/material/AnimationStyle-class.html
- Flutter API — `EdgeInsetsDirectional`: https://api.flutter.dev/flutter/painting/EdgeInsetsDirectional-class.html
- Flutter API — `MediaQuery.disableAnimationsOf`: https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html
- Material Design 3 — accessibility, touch target sizes: https://m3.material.io/foundations/designing/structure
- W3C WAI — WCAG 2.2 SC 2.5.8 Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- W3C WAI — WCAG 2.2 SC 2.3.3 Animation from Interactions: https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html
