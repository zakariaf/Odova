---
name: calm-due-state-and-status
description: >-
  Enforces how Odova renders certainty — DueState { overdue, due, dueSoon, ok, unknown,
  needsOdometer } resolved once through CalmStatusStyle.of(context, state), never by a widget
  switching on a state to pick its own colour. Each state carries a CalmRamp (base/ink/tint/edge)
  plus a distinct dot shape, label and copy pattern, so colour is never the sole signal and the
  set stays legible in grayscale. The two we-do-not-know states are separate and neither may wear
  overdue's terracotta or ok's sage: SPEC §1 forbids guessing in a way that looks like fact, so a
  projected date renders fuzzily ('around mid-October'), an estimated odometer carries a visible
  ~, and an item with no history reads 'Odova needs a reading to say when'. Use when rendering or
  reviewing a due item, a status dot, badge or chip, adding a state, writing overdue/due-soon
  copy, choosing a colour for uncertainty, or reading a state colour slot directly in a widget.---

# calm-due-state-and-status

Home answers one question — *what does my car need next?* — and the answer is a **state**, not a colour. This skill owns the six members of `DueState`, the four colours Calm gives each of them, and the three non-colour signals that carry the meaning when the colour is gone. Most of it exists to enforce one product rule: `SPEC.md` §1 forbids the app from guessing in a way that looks like fact, so "we do not know" must render as its own thing, never as green and never as red. Get this wrong and a used-car owner opens Odova on day one to eleven red cards and turns off notifications on day two.

Read the reference for the task at hand:
- `references/the-six-states.md` — the enum, `DueDriver`, the four-colour set per state with real hexes for both themes, `CalmStatusStyle` as the single resolution point, what reaches Home and what does not, and where `paused` went.
- `references/redundant-encoding.md` — the signal table, the measured grayscale proof that colour cannot carry state in Calm, the AA figures for every ink-on-tint pair, and the two silhouette collisions the shipped CSS has.
- `references/uncertainty-copy.md` — `unknown` vs `needsOdometer`, the `Odova needs a reading to say when` message, fuzzy dates, the `~` prefix, and how all of it behaves across the four theme × direction combinations.

Run `scripts/check_status_encoding.sh` before a PR, plus `calm-tokens/scripts/check_raw_values.sh`.

## Non-negotiable rules

1. **`DueState` has exactly six members and is declared once**, in `lib/theme/calm/calm_status.dart`: `enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }`. No feature module redeclares a subset, and no widget invents a seventh ("almostDue", "warning"). WHY: `SPEC.md` §17 requires a fixture suite over every combination of the state set; a second enum makes that suite a lie.
2. **`CalmStatusStyle.resolve` is the only `switch` over `DueState` that yields a colour.** A widget asks for `CalmStatusStyle.of(context, state)` and reads `.base` / `.ink` / `.tint` / `.edge` / `.mark`. `scripts/check_status_encoding.sh` fails a `case DueState.` or `DueState.x =>` arm anywhere outside `calm_status.dart`. WHY: six states × four colours × two themes is 48 values; the moment two widgets each own a switch, one of them is stale and nobody notices until a screenshot review.
3. **Never read a state colour slot directly.** Two exemptions, both because the state is fixed when the widget is written and is never resolved from a `DueState`: `CalmField` reads `overdue` for its error ring, `CalmSnackbar`'s destructive variant
reads `danger`, and `CalmAllClear` reads `ok`. All three are named in `scripts/check_status_encoding.sh`'s allowlist. Anything that switches on a `DueState` goes through `CalmStatusStyle`. Everywhere else `CalmColors.of(context).overdue.tint` is a gate failure — go through `CalmStatusStyle`. WHY: reading `overdue.ink` in a card is how `needsOdometer` ends up wearing overdue's terracotta, which is precisely the accusation SPEC §3 says the app cannot support.
4. **Three non-colour signals, always: mark, label, copy pattern.** Every surface that renders a state renders its dot **and** its word. A bare coloured dot with no adjacent label or group header is a bug. WHY: measured over `tokens.json`, no two of Calm's six state hues differ by more than **1.51:1** in light (**1.36:1** in dark). WCAG's floor for a meaningful non-text difference is 3:1. Colour here is a mood, not a signal (`references/redundant-encoding.md`).
5. **`unknown` and `needsOdometer` are different states and neither may borrow `overdue`'s or `ok`'s four colours.** `unknown` = we never had an anchor. `needsOdometer` = we had one and the reading went stale (>60 days, per `SPEC.md` §3). Both use their own warm-grey sets (`--color-unknown-*`, `--color-needs-odometer-*`). WHY: green says "you are fine" and terracotta says "you are late"; both are claims the data does not support, and one of them is an accusation aimed at a new owner for a previous owner's neglect.
6. **The not-knowing sentence is `Odova needs a reading to say when`**, one ICU message (`home.dueSoonNoConfidence`), no placeholders, no concatenation, and it never appears as a Dart string literal — the gate greps for it under `lib/`. WHY: `SPEC.md` §2 requires every user-visible sentence to be one translatable ICU message; this one ships in six languages and two directions and is the single most repeated sentence in the product.
7. **A projected date is rendered fuzzily and an estimated odometer carries a visible `~`.** `measured` → `around 22 October`; `assumed` → `around mid-October`; `default` (`DueConfidence.defaulted` in Dart — `default` is reserved) → **no date and no figure at all**, the card reads rule 6's sentence and its action becomes **Update odometer**. The `~` is part of the visible string, inside the number's bidi isolate. WHY: `SPEC.md` §1 — the app would rather show a dash than a plausible lie, and the tilde has to survive colour and weight being stripped.
8. **`ok` and `paused` never reach Home.** `ok` renders in `reminders.list` and in `CalmBadge`; Home shows `CalmAllClear` instead (`calm-layout-and-motion`). `paused` is not a `DueState` at all — it is `item.is_active == false` and the item is filtered before the engine runs. WHY: the "nothing is due" screen is designed as the good state; padding it with green rows makes the one real thing harder to find.
9. **Mark geometry lives in `calm_status.dart` and nowhere else.** The 12px / 8px diameters and the 3px / 2px ring strokes are normative (`odova.css` §12) but are **not in `tokens.json`** — they are declared as named `CalmStatusMark` constants inside the theme directory, which is the one place `design-system-structure` allows a literal. WHY: a status dot drawn with a local `12.0` in a feature widget is a silhouette that drifts the first time someone "tidies" it.
10. **Status text uses `ink`; the anchor line uses `ink2`, never `ink3`.** `--color-ink-3` at `--fs-caption` (13px) measures 3.02–3.99:1 in light and 3.97–4.42:1 on every state tint in dark — under AA for body text. `--color-ink-2` clears 6.37:1 (light) / 6.61:1 (dark) on every one of those grounds. WHY: `SPEC.md` §9 states the secondary/estimated treatment "still meets 4.5:1"; the shipped CSS does not, and the anchor line (`Was due at 186,512 km`) is signal 3, not decoration.
11. **Snoozed is a modifier, not a state.** A snoozed item keeps its `DueState`, keeps its colour, stays on Home, and gains a fourth line `Snoozed until 12 October` in `.ink`. WHY: `SPEC.md` §3 — snoozing suppresses the notification, not the truth.

## The enum and the one resolution point

```dart
// lib/theme/calm/calm_status.dart — the ONLY switch over DueState that picks colour.
enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }

/// Which axis produced the worst status. From the due engine's `DueState` record
/// (SPEC §3); it selects the copy pattern, never the colour.
enum DueDriver { distance, time, both, none }

@immutable
class CalmStatusStyle {
  const CalmStatusStyle({
    required this.state,
    required this.base,
    required this.ink,
    required this.tint,
    required this.edge,
    required this.mark,
  });

  final DueState state;
  final Color base, ink, tint, edge;
  final CalmStatusMark mark;

  /// True for the two states that mean "we do not know" — never styled as ok
  /// or overdue, and never allowed to carry a figure (SPEC §1).
  bool get isUncertain =>
      state == DueState.unknown || state == DueState.needsOdometer;

  static CalmStatusStyle of(BuildContext context, DueState state) =>
      resolve(CalmColors.of(context), state);
}
```

Full file — the four-colour resolution, `CalmStatusMark`, the label/copy-pattern getters, and the action key: `examples/calm_status.dart`.

## The four-colour set

Each state carries exactly four slots. **`base`** paints the mark and the progress fill. **`ink`** is the only one text ever uses. **`tint`** is the card ground (and the top stop of the primary card's gradient). **`edge`** is a hairline that carries no meaning — it measures 1.23–1.34:1 against its own tint, so it may separate but never signify.

| state | light `base` / `ink` / `tint` / `edge` | dark `base` / `ink` / `tint` / `edge` |
|---|---|---|
| `overdue` | `#B4573E` `#8C3E28` `#F7E2D8` `#E9C7B7` | `#E39172` `#F0B79B` `#402720` `#55372B` |
| `due` | `#B0802C` `#7F5A15` `#F8ECD1` `#EAD5AB` | `#DDB45F` `#EBCB8B` `#3B2F1B` `#4E3F24` |
| `dueSoon` | `#5B7C8A` `#3F5D6A` `#E2ECF0` `#C4D8DF` | `#93B6C3` `#B4D0DA` `#24313A` `#33454F` |
| `ok` | `#5D7B60` `#435C46` `#E4EDE1` `#C7DAC4` | `#9CBF9E` `#BBD5BC` `#25311F` `#35452D` |
| `unknown` | `#8A7C6D` `#6B5D4F` `#EEE7DB` `#DCD1BE` | `#B7A794` `#CFC1B0` `#332A21` `#453A2E` |
| `needsOdometer` | `#736A5F` `#574F46` `#EAE5DC` `#D5CDC0` | `#A99D8F` `#C3B8AB` `#2F2820` `#40382E` |

Overdue is terracotta, not a siren red, and the two uncertain states are warm greys that sit *below* everything else in saturation — they read as "not filled in yet", which is what they mean. `ink` on `tint` clears AA in both themes at every state (worst case 5.17:1 light, 7.45:1 dark); the full grid is in `references/redundant-encoding.md`.

## Redundant encoding — the table is normative

```dart
// examples/calm_status.dart — signal 1 is geometry, and it is NOT a colour.
CalmStatusMark get mark => switch (this) {
      DueState.overdue => CalmStatusMark.filledLarge,   // ● 12
      DueState.due => CalmStatusMark.ringHeavy,         // ◉ 12 / 3
      DueState.dueSoon => CalmStatusMark.filledSmall,   // ● 8
      DueState.ok => CalmStatusMark.filledLarge,        // ● 12  (see the collision note)
      DueState.unknown => CalmStatusMark.ringLightFaded,// ◌ 12 / 2 @ .7
      DueState.needsOdometer => CalmStatusMark.ringLight, // ◌ 12 / 2
    };
```

| state | mark (`odova.css` §12) | label | copy pattern | rendered example |
|---|---|---|---|---|
| `overdue` | filled ● 12 | Overdue | positive overshoot, never a negative | `Overdue by 900 km` |
| `due` | ring ◉ 12 / 3 | Due now | imperative, no number | `Due now` |
| `dueSoon` | filled ● 8 | Due soon | hedged forward look | `in about 1,800 km` |
| `ok` | filled ● 12 | On track | plain forward look | `in 8,600 km` |
| `unknown` | ring ◌ 12 / 2 @ .7 | Never recorded | absence of history | `Never recorded` |
| `needsOdometer` | ring ◌ 12 / 2 | Needs a reading | a request, not an accusation | `Needs an odometer reading` |

Overdue always uses its own positive string — never `in −21 days` — and when both axes are overdue the **distance** phrasing wins, because a kilometre figure is checkable against the dash and a date is not (`SPEC.md` §9).

The card that renders all of this at both densities is `examples/calm_due_card.dart`; the dot itself, painted from a token snapshot, is `examples/calm_status_dot.dart`.

Two of those silhouettes collide: `ok` and `overdue` are both a 12px filled disc, and `unknown` and `needsOdometer` are both a 12px 2px ring differing only by 0.7 opacity. That is a defect in the shipped CSS, not a licence to lean on colour — `status_grayscale_test.dart` pins the collisions so the fix is caught when it lands, and asserts on the **(mark, label)** pair, which *is* unique.

## The two "we do not know" states

`unknown` is *we never had an anchor* — `resolveAnchor` fell all the way through, or the item is anchored on the `purchase` / `first_reading` rung and Home is downgrading it on purpose so a 2019 car does not open on a wall of red. Those items leave the sort entirely and collapse into one `unknown`-tinted card at the foot of the stack.

`needsOdometer` is *we had an anchor and the odometer went stale* — `stale_days > 60`, the distance axis is the driver, and its status would have been `due` or `overdue`. The time axis is never downgraded this way; a calendar does not need an odometer.

```dart
// The action differs, and that IS the fourth signal. Never "Log it" for these two.
String get actionKey => switch (this) {
      DueState.needsOdometer || DueState.unknown => 'action.updateOdometer',
      _ => 'action.logIt',
    };
```

Neither state ever carries a projected figure. At `confidence = default` the status line is `Odova needs a reading to say when` and nothing else — no date, no distance, no percentage, no bar, and the word `measured` never appears in the UI. `references/uncertainty-copy.md` has the full precision ladder and the RTL behaviour of the `~`.

## Anti-patterns

- **`switch (state) { … Color … }` inside a widget** — the gate fails it. Six states × four colours × two themes is not a thing two files can both own.
- **`CalmColors.of(context).ok.tint` in a card** — read `CalmStatusStyle.of(context, state).tint`; the direct slot read is how `needsOdometer` acquires a colour that accuses the user.
- **Rendering `unknown` with the `ok` set because "it isn't due"** — green is a claim. So is red. Neither is supported by an item with no anchor.
- **A coloured dot with no label and no group header** — invisible in grayscale, invisible to a deuteranope, and the only surface where Calm's six hues are within 1.51:1 of each other.
- **`'~${odometer}'` built in Dart** — the tilde belongs inside the ICU message and inside the number's first-strong isolate, or it lands on the wrong side of the digits in Arabic. The gate greps for it.
- **Showing `~187,412 km` when the estimate has expired** (last reading >180 days old) — the expired treatment has no tilde and no projection at all: `187,412 km · last entered 12 Jul 2025`.
- **A confidence percentage, a progress ring labelled "78% sure", or the literal word `measured`** — `SPEC.md` §1.4 bans all three; the hedging lives in the words.
- **Adding `paused` to `DueState`** — it is `is_active == false`, filtered before the engine runs, and it outranks everything precisely because it is not a severity.
- **`--color-ink-3` on a status line or an anchor line** — under AA at 13px on every ground Calm ships. Use `ink2`.
- **Treating `edge` as a signal** — 1.23–1.34:1 against its own tint. It is a hairline.
- **A `DueState` extension living in `lib/features/home/`** — the enum and everything derived from it belong to `lib/theme/calm/calm_status.dart` so one fixture suite covers the lot.

## Definition of done

- [ ] `scripts/check_status_encoding.sh` is clean: no `DueState` switch arm, no direct state-colour slot read, and no hardcoded uncertainty sentence outside `lib/theme/calm/calm_status.dart`.
- [ ] Every state resolves through `CalmStatusStyle`; `base`/`ink`/`tint`/`edge`/`mark` all come from it.
- [ ] Every surface that renders a state renders its dot **and** its word (or a group header carrying the word).
- [ ] `ink` on `tint` asserted ≥ 4.5:1 for all six states in **both** themes as a unit test (`examples/status_grayscale_test.dart`).
- [ ] `base` on `surface` asserted ≥ 3:1 for all six states in both themes (the dot is meaningful non-text).
- [ ] A grayscale golden of the six-state set answers "which state is this?" from mark + label alone.
- [ ] `unknown` and `needsOdometer` render distinct copy, distinct action keys, and neither uses the `ok` or `overdue` four-colour set.
- [ ] `Odova needs a reading to say when` is one ICU message with no placeholders, translated for all six locales.
- [ ] No figure and no date rendered at `confidence = default`; `measured` → `around 22 October`, `assumed` → `around mid-October`.
- [ ] Every projected odometer carries a visible `~` inside its bidi isolate and the a11y label `about 187,400 kilometres, estimated`; an expired estimate carries neither `~` nor a projection.
- [ ] `ok` and `paused` do not appear in Home's due stack.
- [ ] Anchor and status lines use `ink` / `ink2`; `ink3` appears on no line that carries state.

## Related skills

- See `calm-tokens` for `CalmColors` and the six `CalmRamp` status ramps (24 slots) this skill resolves through, the asserting `of()`, and the light/dark `ColorScheme`.
- See `calm-components` for `CalmStatusDot`, `CalmBadge`, `CalmChip` and `CalmListRow` — the widgets that consume `CalmStatusStyle`.
- See `calm-layout-and-motion` for the Home due stack, the one-primary-thing rule, and `CalmAllClear` (the `ok` case, rendered as the good state).
- See `calm-typography-and-rtl` for the ICU messages, per-locale numerals, the Jalali calendar behind `around mid-October`, and the isolate the `~` sits inside.
- See `design-system-structure` for the token structure this builds on: two tiers, `ThemeExtension`, the no-raw-values gate, and colour-derived-last.
- See `accessibility-as-code` for the ≥3-non-colour-signals floor itself and contrast against composited backgrounds.
- See `widget-golden-and-a11y-testing` for the grayscale golden lane and the pure-Dart WCAG helpers the tests here use.
- See `i18n-rtl-l10n` for first-strong isolates around interpolated numbers and RTL goldens.
- See `local-notifications-scheduler` for the notification copy that must agree with the card (one notice window drives both).
- See `value-objects-money-and-units` for the metres/millilitres value objects the status lines format.

## References

- W3C WAI — WCAG 2.2 SC 1.4.1 Use of Color: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html
- W3C WAI — WCAG 2.2 SC 1.4.11 Non-text Contrast (the 3:1 floor for the dot): https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- W3C WAI — WCAG 2.2 SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- Flutter API — `Color.computeLuminance`: https://api.flutter.dev/flutter/dart-ui/Color/computeLuminance.html
- Flutter API — `ThemeExtension`: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- Flutter API — `ColorFiltered` / `ColorFilter.matrix` (the grayscale test lane): https://api.flutter.dev/flutter/widgets/ColorFiltered-class.html
- Dart language tour — exhaustive switch expressions over enums: https://dart.dev/language/branches#exhaustiveness-checking
- Unicode TR9 — bidirectional algorithm, first-strong isolates: https://www.unicode.org/reports/tr9/
