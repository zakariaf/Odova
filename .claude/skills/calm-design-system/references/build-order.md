# Build order — how to assemble a Calm screen, in order

Build in this order and the screen is Calm by construction. Build components first and you get a Material screen wearing Calm colours: correct hexes, wrong system.

## 1. Write the one sentence

Every screen answers exactly one question. Home's is *what does my car need next?* Write yours down before opening an editor. If it takes two sentences, it is two screens, or one screen and a push. `SPEC.md` §7 already assigns one question to every screen in the app — check there before inventing one.

## 2. Choose the primary surface and oversize it

The one sentence gets the biggest thing on the screen. In practice that is one of four:

| Surface | Token shape | Used for |
|---|---|---|
| `CalmDueCard` at `primary` density | `--radius-3xl` 36px, `--space-6` 24px padding, 148pt tall, `--elev-2` | the answer is an item that needs doing |
| `CalmAllClear` | `--radius-3xl`, radial `--color-ok-tint` wash, 92px mark, `--fs-title-lg` 27px | the answer is "nothing" |
| `CalmCard` (large) | `--radius-3xl`, `--space-7` | the answer is a number or a document |
| `CalmEmptyState` | `--space-8` 40px block | the user has not created the thing yet |

Title at `--fs-title-lg` 27px / `--lh-title-lg` 1.18 / `--fw-semi` 600 / `--tracking-tight` -0.02em, or larger — `--fs-hero` 34px, `--fs-display` 46px for a single figure. Everything else on the screen is smaller and quieter than this, without exception.

## 3. Add at most two secondaries, then cap and link

`CalmDueCard` at `secondary` density is 72pt: an 8px dot, a `--fs-body` 15px `--fw-medium` title, a `--fs-caption` 13px end-aligned status line, a chevron. Two of them, maximum. Then one `CalmListRow` at 48–64px carrying the overflow as a count and a chevron: `See all reminders (14) ›`. When the overflow is urgent, the row carries the tone instead of adding cards: `See all — 9 more due or overdue ›`.

Never a fourth card. Never a shorter card to fit a fourth.

## 4. Enumerate every state before styling one

Write the list first; a state discovered after layout is a state that gets bolted on badly.

- **Loaded, typical** — the one you were going to build anyway.
- **Nothing due / all-clear** — the *most common* state (`SPEC.md` §9) and the best-looking one. `CalmAllClear`, next item with its date, plus a since-last-service line. Not `CalmEmptyState`.
- **First run / no history** — real values where they exist (an entered odometer, not a projected one), `—` everywhere else. No fake numbers, no zeroes.
- **Single item** — one primary, no secondaries, see-all row still present. No layout special-casing.
- **Over cap** — hard cap at three cards; the link carries the rest.
- **Unknown anchor** — items anchored on the `purchase` or `first_reading` rung collapse into one card at the foot of the stack, whatever the due engine returned. Presentation only; the engine is untouched.
- **Stale odometer** — the strip reads `~187,400 km`; past 180 days it stops projecting entirely and shows the entered figure with its date.
- **Error** — one full-width message and one button. A single bad row renders as one grey card, never a blank screen.

## 5. Lay it out with the space scale, then check the fold

Screen inline padding is `--screen-pad` 22px, always. Vertical stack gap `--space-5` 20px, `--space-4` 16px in a tight stack. Card padding `--space-6` 24px default, `--space-7` 32px large, `--space-5` 20px small. Inside a row, `--space-3` 12px.

Then do the fold arithmetic on the floor screen (375 × 667 pt, default text scale): `--appbar-h` 56 + your strips + your cards + your link row must clear a `--tabbar-h` 62 tab bar. Home's budget is 56 + 64 + 148 + 2 × 72 + 48 = 460. Conditional strips are capped at two and push the *tiles* below the fold, never the primary card.

## 6. Reach for components — only from `lib/ui/calm/`

Now, and not before. `CalmScaffold`, `CalmAppBar`, `CalmTabBar`, `CalmCard`, `CalmRowGroup`, `CalmListRow`, `CalmButton`, `CalmChip`, `CalmBadge`, `CalmStatusDot`, `CalmField`, `CalmStepper`, `CalmSwitch`, `CalmSegmented`, `CalmSheet`, `CalmDialog`, `CalmNumberPad`, `CalmTile`, `CalmSnackbar`. If the thing you need is not in that list, it is a change to `lib/ui/calm/` reviewed against `design/calm/system.html` — not a bespoke `Container` in a feature file. `calm-components` owns each widget's states.

Touch floor check as you go: buttons ≥ `--touch-min` 52px (`CalmButton.lg` is 60px), rows 64px, number-pad keys 68px, and the primary action full-width at the bottom of the thumb's reach.

## 7. Status pass — three signals, resolved once

Every due status renders dot shape **and** wording **and** tone, resolved through `CalmStatusStyle` from a `DueState`, never by reading a colour. Overdue always uses a positive phrase (`Overdue by 1,400 km`), never a negative countdown. Distance phrasing wins when both axes are overdue — a kilometre figure is checkable against the dash and a date is not. Every estimate carries its `~` or its "about" inside the visible string, plus the accessibility label `about 187,400 kilometres, estimated`. Detail: `calm-due-state-and-status`.

## 8. RTL and locale pass

Re-read every offset you wrote: `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`. Flip only directional glyphs (back chevron, disclosure chevron, backspace, swap, undo, prev/next); a car, a pump, a wrench, a clock and a check keep one asset. Codes (VIN, plate) are force-LTR and isolated even on an RTL screen. Under `fa`, Vazirmatn leads for *everything* with looser leading and zero tracking — never a mixed Latin/Arabic pairing at different optical sizes. Then render the screen at German length: nothing may truncate a status line. Detail: `calm-typography-and-rtl`.

## 9. Motion pass

Pick durations from `--dur-instant` 90ms (press), `--dur-quick` 160ms (tint/colour), `--dur-base` 240ms (surface change), `--dur-slow` 360ms, `--dur-sheet` 420ms (sheet/modal). Curves are `--ease-standard` `Cubic(0.32, 0.72, 0, 1)`, `--ease-out` `Cubic(0.2, 0.8, 0.2, 1)`, `--ease-in` `Cubic(0.4, 0, 1, 1)`, `--ease-settle` `Cubic(0.34, 1.24, 0.64, 1)` for a thing landing. Under `MediaQuery.disableAnimationsOf(context)` every one of them collapses to `Duration.zero` — not a shorter duration. Detail: `calm-layout-and-motion`.

## 10. Gates

Run `scripts/check_calm_layering.sh`, `scripts/check_calm_rejects.sh`, and the general `design-system-structure/scripts/check_raw_values.sh`. Then goldens: every state from step 4, in both themes and both directions. A state without a golden is a state that will regress.
