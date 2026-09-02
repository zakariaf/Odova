# Rendering "we do not know"

`SPEC.md` §1: *the app never guesses in a way that looks like fact… it would rather show a dash than a plausible lie.* Two `DueState` members and one sentence carry that rule. Everything here is product copy with a colour attached, which is why it lives in the design-system skill and not in a feature.

## `unknown` ≠ `needsOdometer`

| | `unknown` | `needsOdometer` |
|---|---|---|
| means | there was never an anchor | there was an anchor; the reading went stale |
| produced by | `resolveAnchor` falling through, **or** Home downgrading an item anchored on the `purchase` / `first_reading` rung | `stale_days > 60`, the **distance** axis is the driver, and its status would be `due` or `overdue` |
| fix | tell Odova when it was last done | tell Odova what the dash says |
| label | Never recorded | Needs a reading |
| status line | `Never recorded` | `Needs an odometer reading` |
| anchor line | — | `Last entered 12 July` |
| action | **Update odometer** (via `reminders.edit`) | **Update odometer** |
| on Home | collapses into one collector card, always last | a normal card, never the primary slot below a time-driven `due` |
| colours | `--color-unknown-*` | `--color-needs-odometer-*` |

They are separate because the *repair* is different, and the repair is the only reason to show the state at all. Conflating them tells a user with eleven seeded items to go read their odometer, which will not help any of them.

Neither may borrow `overdue`'s or `ok`'s four colours. Green asserts "you are fine"; terracotta asserts "you are late". Both are claims about a history the app does not have, and one of them accuses a second-hand buyer of a previous owner's neglect on the day they installed the app.

The time axis is never downgraded to `needsOdometer`. A calendar does not need an odometer — if the time axis independently reaches `due` or `overdue`, that wins and shows as itself.

## The sentence

```
Odova needs a reading to say when
```

One ICU message, key `home.dueSoonNoConfidence`, **no placeholders**. It is not assembled, not suffixed with a vehicle name, and never appears as a Dart string literal — `scripts/check_status_encoding.sh` greps `lib/` for it. It renders identically in all four theme × direction combinations because it contains no digits, no date and no unit; the Persian string (`اودووا به عدد کیلومتر نیاز دارد`) is a straight translation with nothing to isolate.

It appears in exactly three places: the `needsOdometer` card's anchor line, a `dueSoon` card whose distance axis is at `confidence = default`, and the corresponding early notification. One message, so a card and its notification can never disagree.

## The precision ladder

| `confidence` | date allowed | odometer allowed |
|---|---|---|
| `measured` | `around 22 October`; `around mid-October` beyond 8 weeks | `~118,200 km` |
| `assumed` | `around mid-October` — month granularity only | `~118,000 km` |
| `default` | **none** | **none — no figure at all, in the app or in a notification** |

`default` is a Dart keyword, so the enum member is `DueConfidence.defaulted`. Name it once, in `calm_status.dart`, and never write a local alias.

Binding on every surface:

- A date from the **time** axis is exact and plain: `10 October`. It is calendar arithmetic, not a guess, and hedging it would teach the user to distrust the one number that is certain.
- A date from the **distance** axis is always fuzzy — `around` at `measured`, `around mid-October` at `assumed`. Never a weekday, never a time of day.
- A projected odometer is prefixed `~` and rounded to the nearest 100 km / 50 mi. `~187,400 km`, never `187,412`.
- Remaining-distance figures (`in about 1,800 km`) are rounded the same way and hedged by the surrounding ICU message, not by a `~`.
- An **expired** estimate (last reading > 180 days) carries no `~` and no projection at all: `187,412 km · last entered 12 Jul 2025`. Ten thousand kilometres of invented number is worse than a blank.
- Never a percentage, never a bar, never the word `measured` in the UI. Under the no-analytics rule the real error will never be measured, so it must not be implied by a number.

## The tilde, in both directions

The `~` is part of the visible string and sits **inside** the isolate that wraps the numeric run, so it hugs the digits in RTL instead of drifting to the far edge of the line:

```dart
// The ICU message owns the tilde AND the isolate. Never '~$value' in Dart.
// odometer.estimated: "{value}"  ->  rendered as ⁨~187,400 km⁩
Text(l10n.odometerEstimated(formatter.format(metres)),
     style: CalmType.of(context).caption.copyWith(color: CalmColors.of(context).ink2));
```

Bidi control characters are inserted at render time and never stored (`SPEC.md` §2). `calm-typography-and-rtl` owns the isolate mechanics and the per-locale numerals; `i18n-rtl-l10n` owns the general rule.

Every estimated value also carries an explicit semantics label — `about 187,400 kilometres, estimated` — because the `~` is a glyph a screen reader will skip. The distinction has to survive colour and weight being stripped *and* being read aloud.

## Tapping an estimate

Any estimated value or `—` opens a transient popover: one sentence, one action.

- `Estimated from about 41 km a day since 12 July.` → **Update odometer**
- `Your last reading is too old, so Odova has stopped guessing. Enter what the dash says now.` → **Update odometer**
- `Your first consumption figure arrives at your next full fill-up.` → dismissal only

The tilde and the word "about" are the entire vocabulary of uncertainty in this product. Adding a third — a bar, a badge, a "low confidence" chip — puts a number on an error the app has no way to measure.
