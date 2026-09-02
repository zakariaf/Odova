# Chrome, overlays and the number pad

`CalmScaffold`, `CalmAppBar`, `CalmTabBar`, `CalmSheet`, `CalmDialog`, `CalmSnackbar`, `CalmNumberPad`. Screen composition and the spacing rhythm belong to `calm-layout-and-motion`; routing belongs to `navigation-and-routing`. This file is what these widgets *are*.

## `CalmScaffold`

`Scaffold` with `backgroundColor: colors.bg`, `extendBody: false`, and body padding of `space.screenPad` (22) inline. It does **not** use `Scaffold.appBar` — `CalmAppBar` is an ordinary widget in a `Column`, because the `large` and `vehicle` variants are two lines tall and `PreferredSizeWidget` makes that a constant nobody updates. Fixed metrics: `space.appbarH` 56, `space.tabbarH` 62, `space.homebarH` 34, `space.statusbarH` 54.

Never wrap the body in `SafeArea` *and* pad it: the tab bar already accounts for `homebarH`. Use `MediaQuery.viewInsetsOf(context)` for the keyboard, not `viewInsets` from `.of` — see `adaptive-layout`.

## `CalmAppBar`

Four shapes, one widget:

- **default** — 56 tall, a 52pt leading button, a `start`-aligned `type.title` semi title with `s2` of start inset, and trailing actions with `s1` between them. Background is `colors.bg`, never `surface`: the app bar is part of the page, not a card, and it draws no shadow and no bottom hairline.
- **`large`** — a `Column` at `screenPad`, `type.titleLg` title plus an optional `type.caption` `ink3` subtitle. The screen name is the first big thing you read.
- **`vehicle`** — title and chevron are **one** 52pt pill target with a negative `s3` start margin so the text still aligns to `screenPad`. SPEC §9: the chevron and the target exist only when ≥2 vehicles exist; with one vehicle it is plain text and the garage is invisible until it is real.
- **`modal`** — a three-column grid (`1fr auto 1fr`): Cancel at the start, a centred `type.headline` semi title, the confirming action at the end in `brand` semi. Disabled actions go `ink4`. This is the header on all five `log.*` screens.

Buttons are `radiusPill`, `ink2` at rest, `surface2` + `ink` on hover/press, over `motion.quick` with `easeOut`.

## `CalmTabBar`

62 tall, five equal slots, `colors.bg`, a single `divider` hairline along the top edge, no shadow. Items are an icon over a `type.caption` medium label, `ink3` at rest and `brand` + semi when active — colour *and* weight, so the active tab survives grayscale. The centre slot is the `+`: a 62pt `brand`/`onBrand` circle on `elev2`, pulled 18pt above the bar, pressing to scale 0.94. It is the biggest, warmest thing in the chrome because logging is the app's only frequent write.

## `CalmSheet`

The default modal surface. `surface`, `elev4`, and `radius3xl` on the **top two corners only** — expressed as `BorderRadiusDirectional.only(topStart:, topEnd:)`, which is identical in both directions but keeps the file free of `topLeft`/`topRight` for the RTL gate. A 44×5 grip at 18% `ink`, centred, then a `sheet__head` (title `type.title` semi, optional `type.caption` `ink3` sub), a scrollable body, and stacked full-width actions.

Entry is a 24pt rise plus a fade from 0.6 over `motion.sheet` (420ms) with `easeStandard` — the slowest motion in the system, because a sheet is the one thing that takes over the screen. Max height 88%; `full` goes edge to edge with no radius. The scrim is `colors.scrim` fading in over `motion.base`.

Use `CalmSheet.show<T>()` rather than `showModalBottomSheet` at call sites: it pins `isScrollControlled`, `backgroundColor: Colors.transparent`, the barrier colour, and `useSafeArea`, none of which is a decision a feature should re-make.

## `CalmDialog`

Reserved. SPEC §10: confirmation is a snackbar with Undo, not a dialog — a dialog is paid for on every *correct* entry. Dialogs exist for exactly three things: discarding a dirty form, confirming a delete that names what dies, and deleting a vehicle.

`surface`, `radius3xl`, `elev4`, inset `s6` from the screen edges, padding `s7 s6 s6`. An optional 56pt icon disc (`brandSoft`/`brandSoftInk`, or `dangerTint`/`danger` for `danger`) sits above a `type.title` semi title and `type.bodyLg` `ink2` body. Text is `start`-aligned, not centred — centred body copy is unreadable at Sorani line lengths. Actions are **stacked and full-width**, destructive first, `Cancel` last, each ≥52. Entry is scale 0.96 → 1 with a fade over `motion.base` with `easeSettle`.

## `CalmSnackbar`

`surfaceInverse` / `inkInverse`, `radiusXl`, `elev3`, inset `s5` inline, sitting `tabbarH + homebarH + s3` above the bottom edge so it never covers the `+`. It carries an action — practically always **Undo**, for 6 seconds — because Undo is the only "are you sure" that logging gets (SPEC §10). Route it through `ScaffoldMessenger` so it survives a route change, and never show two at once.

The action label's colour is a known defect: `--color-brand` on `--color-surface-inverse` is 2.28:1 in light and 1.85:1 in dark. Until a `brand-on-inverse` slot exists, render the action in `inkInverse` semi — legible in both themes, and still distinguishable from the message by weight and by its `radiusPill` tap target.

## Exit motion

Entry curves are specified above; exits are not symmetric. A sheet leaves on `motion.base` with `easeIn` (accelerating away is what makes a dismissal feel like a dismissal rather than a rewind), a dialog fades on `motion.quick`, and the scrim always outlasts the surface by nothing — they end on the same frame, or the scrim flashes over an empty screen. `--ease-in` is currently declared and unused in `odova.css`; this is the slot it exists for.

All four collapse to `Duration.zero` under `MediaQuery.disableAnimationsOf` — the sheet appears, it does not slide. Never route a dismissal through a shorter animation instead.

## `CalmNumberPad`

The odometer is the one number that keeps every projection honest (SPEC §1), and it is typed at a pump, one-handed, in the rain. The OS numeric keyboard is the wrong tool for it: its digits sit at the *top* of a full-width keyboard, past the far end of a thumb's arc on a large phone; its keys are ~40pt; it renders whatever digit shapes the keyboard's own locale chose rather than the user's active numbering system; and it leaves no room for the unit chip or the live `+432 km since 12 Mar` delta that catches a dropped digit.

So Calm ships its own: a 3-column grid with `s3` gutters and 68pt keys — `surface`, `radiusXl`, `elev1` + `sheen`, `type.titleLg` medium with tabular lining figures. `action` keys (backspace, clear) are flat `surface2`/`ink2` at `type.bodyLg` semi; the `confirm` key is `brand`/`onBrand` on `elev1` and spans two columns. Press is `surface3` + scale 0.96 + shadow off over `motion.instant`.

Above it, the display is a `surface2` `radius2xl` block: the value at `type.display` (46/1.04) semi with tight tracking, the unit at `type.body` `ink3`, and a `type.caption` hint line. The whole pad plus display fits the bottom two-thirds of a 375×667 screen with the value still visible.

**The grid does not mirror.** Digit order is fixed left-to-right in every locale — a mirrored keypad is a wrong keypad. Only the backspace glyph flips (it is one of the six directional icons). The digits themselves render in the active numbering system; that mapping is owned by `calm-typography-and-rtl`.

## The keyboard

`CalmScaffold` pads its body by `MediaQuery.viewInsetsOf(context).bottom` so the pinned primary button rides above the keyboard rather than under it (SPEC §10 puts Save both in the modal head and as a full-width button above the keyboard, because the top-end corner is unreachable one-handed on a large phone). Use `viewInsetsOf`, not `MediaQuery.of(context).viewInsets`, so only the widgets that care rebuild on every keyboard frame; `adaptive-layout` owns that rule.

When `CalmNumberPad` is on screen the OS keyboard is not: the field is `readOnly: true` with `showCursor: true`, so the caret still blinks and selection still works while the pad owns input.
