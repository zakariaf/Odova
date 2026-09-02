# The six states, and the one place they resolve

`SPEC.md` §3 defines a `DueState` record with seven `status` values. The Dart enum has **six**:

```dart
enum DueState { overdue, due, dueSoon, ok, unknown, needsOdometer }
```

`paused` is the missing one, deliberately. `paused` is `item.is_active == false` — it "outranks everything and is silent", which is not a severity, it is a filter. Paused items are excluded before the engine runs, so a paused item has no `DueState` to render and no card to style. Putting it in the enum would force every `switch` to answer "what colour is silence?".

`snoozed` is likewise not a member. A snoozed item keeps its real state and its real colour, stays on Home, and gains a fourth line (`Snoozed until 12 October`) in `.ink`. Snoozing suppresses the notification, not the truth.

## Severity, and the axis that drove it

The engine computes a distance axis and a time axis separately and takes the worse — `ok < dueSoon < due < overdue`. Which axis won comes back as `DueDriver`:

```dart
enum DueDriver { distance, time, both, none }
```

The driver never changes a colour. It selects the **copy pattern** — `Overdue by 1,400 km` vs `Overdue by 3 weeks` vs both — and when both axes are overdue, distance wins the phrasing because a kilometre figure is checkable against the dash and a date is not.

`unknown` and `needsOdometer` sit outside the severity ladder. They are not "worse than ok" or "better than due"; they are the absence of a claim. `needsOdometer` sorts by its own projected date but never takes Home's primary slot while a `due` or `overdue` **time-driven** item exists — an accusation the app can support beats one it cannot.

## The four colours

Every state carries four slots and they are not interchangeable:

| slot | what it paints | contrast obligation |
|---|---|---|
| `base` | the status dot, the progress fill, `--due-color` | ≥ 3:1 on the ground it sits on (meaningful non-text) |
| `ink` | every character of the status line, the badge label, the snooze line | ≥ 4.5:1 on `tint` *and* on `surface` |
| `tint` | the badge ground, the primary card's gradient top stop, the unknown collector card | it is the ground; nothing sits behind it |
| `edge` | a hairline separator only | **none** — it measures 1.23–1.34:1 on its own tint and can never signify |

The primary due card is a gradient from `tint` at 0% to `--color-surface` at 78%, so the status line's `ink` must clear 4.5:1 on both ends. It does, everywhere: worst case is `unknown` at 5.17:1 (light) and `needsOdometer` at 7.45:1 (dark).

## Light values

| state | base | ink | tint | edge |
|---|---|---|---|---|
| `overdue` | `#B4573E` | `#8C3E28` | `#F7E2D8` | `#E9C7B7` |
| `due` | `#B0802C` | `#7F5A15` | `#F8ECD1` | `#EAD5AB` |
| `dueSoon` | `#5B7C8A` | `#3F5D6A` | `#E2ECF0` | `#C4D8DF` |
| `ok` | `#5D7B60` | `#435C46` | `#E4EDE1` | `#C7DAC4` |
| `unknown` | `#8A7C6D` | `#6B5D4F` | `#EEE7DB` | `#DCD1BE` |
| `needsOdometer` | `#736A5F` | `#574F46` | `#EAE5DC` | `#D5CDC0` |

## Dark values

| state | base | ink | tint | edge |
|---|---|---|---|---|
| `overdue` | `#E39172` | `#F0B79B` | `#402720` | `#55372B` |
| `due` | `#DDB45F` | `#EBCB8B` | `#3B2F1B` | `#4E3F24` |
| `dueSoon` | `#93B6C3` | `#B4D0DA` | `#24313A` | `#33454F` |
| `ok` | `#9CBF9E` | `#BBD5BC` | `#25311F` | `#35452D` |
| `unknown` | `#B7A794` | `#CFC1B0` | `#332A21` | `#453A2E` |
| `needsOdometer` | `#A99D8F` | `#C3B8AB` | `#2F2820` | `#40382E` |

Dark is hand-authored, not a flip: every `ink` gets *lighter* than its `base` in dark and *darker* in light, which is why a naive inversion of the light set fails AA on four of the six.

## The single resolution point

```dart
static CalmStatusStyle resolve(CalmColors c, DueState state) => switch (state) {
      DueState.overdue => CalmStatusStyle(
          state: state, base: c.overdue.base, ink: c.overdue.ink,
          tint: c.overdue.tint, edge: c.overdue.edge,
          mark: CalmStatusMark.filledLarge),
      // … five more, one per state; see examples/calm_status.dart
    };
```

Exhaustive over the enum, so adding a seventh state is a compile error in exactly one file rather than a silent grey card in nine. Widgets call `CalmStatusStyle.of(context, state)` and never see `CalmColors`' status slots at all — `scripts/check_status_encoding.sh` enforces that.

## What reaches Home

| state | Home due stack | `reminders.list` | `CalmBadge` | vehicle switcher dot |
|---|---|---|---|---|
| `overdue` | yes, sorts first | yes, "Overdue" group | yes | yes |
| `due` | yes | yes, "Due soon" group | yes | yes |
| `dueSoon` | yes | yes | yes | yes |
| `ok` | **no** — `CalmAllClear` instead | yes, "On track" group | yes | yes ("All good") |
| `unknown` | collapsed into one collector card, always last | yes, "Never recorded" group | yes | yes ("No reminders yet") |
| `needsOdometer` | yes, but never in the primary slot below a time-driven `due` | yes | yes | yes |

Home rendering `ok` would mean padding the one screen that has one job with rows the user cannot act on. The `ok` visual language exists anyway, because `reminders.list` shows the whole catalogue and "On track" is exactly what the user came to confirm.
