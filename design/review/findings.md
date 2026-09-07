# Design review findings — EPIC-18

Graded on `design-review-workflow`'s rubric.

- **BLOCKER** — ships wrong. A contrast miss, an unreachable control, a value
  the user would act on that is not what the design says.
- **FIX** — a real difference from the reference that a person will notice, with
  a known cause.
- **NOTE** — a difference worth recording that is not worth a change now, or one
  whose cause is not yet established.

**This is a TOOL-ASSISTED pass, not the human pass Task 18.8 describes.** The
sweep ran over all 112 comparisons and produced a sheet for each; a person read
**four** of them — `settings-light-ltr`, `home-light-ltr`,
`log.fillup-light-ltr` and `vehicles-light-rtl` — and every finding below comes
from those four. 108 sheets have not been looked at by anybody. Task 18.9's
structured pass on a RELEASE build has not been run at all: it needs a device,
and this epic had none. Both are recorded in the sign-off rather than implied to
be done.

Everything below was found by opening a sheet. None of it was found by the
three automated checks, which is the point §7 makes about what they cannot see.

---

## BLOCKER

Both are **FIXED** in Task 18.10's one scoped fix round. The finding text is
kept as written, with what was done under each.

### B-1 · `home` does not draw the overdue count pill
`home-light-ltr`. The artboard puts `● 1 overdue` beside the vehicle name in the
app bar; the app draws nothing there.

It is a blocker rather than a fix because SPEC.md §9 makes the home screen
answer one question — *what does my car need next?* — and this is the only
element on the screen that answers it before the user reads a card. A phone that
knows one item is overdue and says so nowhere in its header is the failure the
whole app exists to prevent.

**Fixed.** `HomeStack.overdueCount` and a `CalmBadge` in the app bar, with
`homeOverdueCount` in all six ARB files and Arabic's six CLDR categories. The
count is over the WHOLE stack rather than the three cards it shows: the stack
caps at three, so a garage with five overdue items would have read "3 overdue"
— a smaller number than the truth, and the cap is exactly the condition under
which nobody would notice. Both mutations caught.

### B-2 · The odometer field does not group its digits while typing
`log.fillup-light-ltr`. The reference reads `187,412`; the app reads `187412`.

SPEC.md §5 puts grouping under the region, and §1's second fact is that this
number is typed at a pump, one-handed, in the rain. An ungrouped six-digit
number is the one field in the app where a mistyped digit is both easiest to
make and hardest to see, and the grouping is what makes it visible. It is also
the field §10 makes mandatory on every form.

**Fixed, and the cause was a familiar one.** §10's sentence — "on blur the field
re-renders canonically in the active numbering system" — had a function,
`canonicalDisplay`, with its own tests and **zero production callers**. The
seam was shipped satisfied only by its own tests; this repo has now met that
shape eight times. `OdometerField` became stateful, owns a `FocusNode` and
re-renders on blur. `canonicalDisplay` gained a `grouped` flag: its default of
`false` was written to protect a caret that a separator would move, and on blur
there is no caret.

---

## FIX

### F-1 · The `home` secondary items are three cards, not one grouped card
The artboard draws Inspection / Brake pads / Timing belt in ONE card with
dividers between them. The app draws three separate cards with a gap between
each. This is a large share of `home`'s band-profile miss and it is visible at a
glance.

### F-2 · The due card's anchor line loses its date
Reference: `Was due at 186,512 km · 12 August`. App: `Was due at 186,512 km`.
§9's anchor line is the card's only checkable fact and the date is half of it —
distance leads, but both axes are stated.

### F-3 · The odometer strip's freshness line differs in case and in year
Reference: `Entered 2 September`. App: `entered 5 September 2026`. Two
differences: the leading capital, and the year, which the reference omits for
the current year.

### F-4 · The unit selector on `log.fillup` has no disclosure chevron
Reference: `km ⌄`. App: `km`. The control is a menu and reads as a label.

### F-5 · `log.*` dates render in US order under `en`
Reference: `Wed 2 September 2026`. App: `September 2, 2026`. The weekday is
missing and the order is `en-US` where the reference is `en-GB`. §5 puts both
under the region; the artboard's phone is a continental one.

### F-6 · The `More` disclosure puts its summary in the wrong slot
Reference: `More` with `Station · Grade · Trip ⌄` as the END value. App: `More`
with the same words as a SUBTITLE and a chevron-right. The app's version reads
as a navigation row rather than an expander.

### F-7 · `settings` prints the currency CODE where the design prints the symbol
Reference and SPEC.md §13 both read `km · L · €`; the app reads `km · L · EUR`.

### F-8 · Dark modal screens paint pure black under the scrim
`#000000` over 0.6–3.2% of the frame on the dark `dialog.*`, `settings.import`
and `vehicle.switcher` captures, where the scrim composited over the darkest
surface is `#0F0C0A`. The `scrim` slot is correct in both themes, so something
beneath it is painting black. Eleven comparisons.

### F-9 · `costs.fuel` is missing most of its reference content
The screen draws a headline figure and a chart. The reference additionally has:
the `L/100 km` unit label, the `Average over 34 full tanks · last 12 months`
line, the This-tank / Best / Worst captions with their figures, the
`Last 12 tanks` range chip, both axis labels, the best/worst/average legend, and
the three-up price trio (`€1.734 last per L`, `€1.684 12-month average`,
`€0.19 fuel per km`). The widget has no code for any of them — this is an
unfinished screen rather than a drift.

---

## NOTE

### N-1 · The band profile is still failing on 106 of 112, median 53%
The cause is vertical rhythm and it is real — on `settings` the app's first card
starts 16px lower than the reference's and every band below inherits the offset
— but the specific cause per screen is NOT established. Establishing it is the
side-by-side read Task 18.8 is, and only four sheets were read.

### N-2 · The capture's status-bar icons are the same on every screen
The artboards vary them: `home` draws a bell and a battery, `log.fillup` draws
signal, wifi and battery. The harness draws a bell and a battery everywhere.
Worth two band edges at most, and it is a harness detail, not a screen.

### N-3 · `home` shows a See-all row and three empty glance tiles the artboard does not
Both are fixture consequences: the capture's catalogue has one more due item
than the artboard's, and it has no cost history, so the tiles render §3's honest
`—`. Neither is a screen difference.

### N-4 · The `Date`/`More` group's divider is a torn-paper zigzag in the artboard
The app draws a plain hairline. A deliberate design detail in the artboard that
was never built.

### N-5 · The `settings` Vehicles row uses a different icon
Reference draws a garage; the app draws a car in a box.
