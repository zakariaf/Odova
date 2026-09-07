# The 112-comparison parity sweep — EPIC-18 task 18.4

Generated from `design/review/parity-raw.txt`, which is the tool's own
output kept verbatim. **Nothing here was fixed while writing it.** Triage
only: the fix tasks are 18.5 (bands), 18.6 (colour) and 18.7 (RTL).

The differing-pixel percentages the tool prints are NOT in this table. They
are informational by the skill's own rule — the reference is Chrome
rendering HTML and the app is Skia, so 25–45% of pixels differ on a correct
screen — and a number in a triage table is a number somebody will sort by.

## What the run says

| | Count |
|---|---|
| Comparisons | 112 |
| Passing all three checks | 6 |
| Failing the band profile | 106 |
| Painting an untokenised surface | 17 |
| Built in the wrong theme | 2 |

## The three classes, and what each one is

**bands — 106 of 112.** The dominant class by a distance, and it is not 106
separate defects. Two contributions, measured on `settings-light-ltr` by dumping
both band profiles:

1. **The references draw phone chrome the app never draws.** Every artboard has
   an iOS status bar — `9:41` and three icons — and a home indicator. Those are
   band edges at y=66, 84 and 88 that no capture can produce, on all 112. The
   harness pads 54pt at the top and 34pt at the bottom for them and paints
   nothing there.
2. **Real vertical rhythm differences.** On `settings` the app's title sits 10px
   HIGHER than the reference's and its first card 16px LOWER — a gap about 26px
   wider than the artboard's — and every band below it inherits the offset. 48
   of 100 reference edges have an app edge within 4px.

Both go to Task 18.5. (1) is fixed by drawing the chrome in the capture, which
is what the references depict and what a real phone shows; it is not a widened
tolerance and `--band-tolerance` is not touched.

**colour — 17 of 112, on five screens, all of them modal.**
`dialog.discard`, `dialog.confirmDelete`, `dialog.snooze`, `settings.import` and
`vehicle.switcher` — and nothing else. Every one draws a SCRIM over a backdrop,
and the colours reported (`#9B9287`, `#9E9087`, `#9E8E85`) are the scrim
composited over a Calm surface. The census compares composited pixels against
un-composited tokens, so a scrim over any ground is by construction not a token.
Task 18.6.

**theme — 2 of 112**, and the same cause: `dialog.discard-light-*` reports
`#9E968E covers 36% and belongs to the dark palette`. That is the light
backdrop under the scrim, which lands nearer a dark token than a light one. The
screens are in the right theme; the check cannot tell a scrimmed light screen
from a dark one. Task 18.6, with the colour class.

**No screen fails for a reason unique to itself.** That is the useful result of
running all 112 at once, and it is the opposite of what 28 per-screen files
would have suggested.

## Every comparison

`verdict` is one of `pass`, `fixed`, `design-change` or `deferred-NOTE`, and
`sweep_report_test.dart` fails on an empty one. Everything below reads
`deferred-NOTE` today because this task is triage and fixes nothing; the fix
tasks rewrite the rows they close.

| screen | theme | dir | verdict | class | the tool's own words |
|---|---|---|---|---|---|
| `costs` | dark | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | dark | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | rtl | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | ltr | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | rtl | deferred-NOTE | bands | 68% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | ltr | deferred-NOTE | colour+bands | #070605 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ36)<br>#040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ45)<br>64% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | rtl | deferred-NOTE | colour+bands | #070605 covers 1.2% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ36)<br>#040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ45)<br>59% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | ltr | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | ltr | deferred-NOTE | colour+bands | #080705 covers 1.2% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ34)<br>#050403 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ42)<br>33% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | rtl | deferred-NOTE | colour+bands | #080705 covers 1.2% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ34)<br>#040302 covers 0.7% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ45)<br>38% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | ltr | deferred-NOTE | colour+theme+bands | #9B9287 covers 12.1% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>#9E8F86 covers 0.9% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ32)<br>#9E8E85 covers 0.5% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ30)<br>#9E968E covers 36% and belongs to the dark palette — this build is in the wrong theme<br>36% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | rtl | deferred-NOTE | colour+theme+bands | #9B9287 covers 9.0% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>#9E968E covers 36% and belongs to the dark palette — this build is in the wrong theme<br>43% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | ltr | deferred-NOTE | colour+bands | #0A0806 covers 1.0% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ30)<br>#050403 covers 0.8% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ42)<br>34% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | rtl | deferred-NOTE | colour+bands | #050403 covers 1.0% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ42)<br>#070605 covers 0.7% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ36)<br>36% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | ltr | deferred-NOTE | colour+bands | #9B9287 covers 5.6% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>37% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | rtl | deferred-NOTE | colour+bands | #9B9287 covers 3.6% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>36% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.language` | dark | ltr | pass | — | all three checks ok |
| `firstrun.language` | dark | rtl | pass | — | all three checks ok |
| `firstrun.language` | light | ltr | pass | — | all three checks ok |
| `firstrun.language` | light | rtl | pass | — | all three checks ok |
| `firstrun.vehicle` | dark | ltr | deferred-NOTE | bands | 47% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | dark | rtl | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | ltr | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | rtl | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | ltr | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | rtl | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | ltr | deferred-NOTE | bands | 39% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | rtl | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | ltr | deferred-NOTE | bands | 38% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | rtl | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | ltr | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | rtl | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | ltr | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | ltr | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | ltr | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | rtl | deferred-NOTE | bands | 50% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | ltr | deferred-NOTE | bands | 68% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | ltr | deferred-NOTE | bands | 70% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | rtl | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | ltr | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | rtl | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | ltr | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | rtl | deferred-NOTE | bands | 69% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | ltr | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | rtl | deferred-NOTE | bands | 70% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | ltr | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | ltr | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | rtl | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | rtl | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | ltr | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | ltr | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | rtl | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | ltr | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | rtl | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | ltr | deferred-NOTE | colour+bands | #000000 covers 3.2% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ54)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>59% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | rtl | deferred-NOTE | colour+bands | #0B0908 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ26)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>#000000 covers 0.6% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ54)<br>61% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | ltr | deferred-NOTE | colour+bands | #000000 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ54)<br>61% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | rtl | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | ltr | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | rtl | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | rtl | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | ltr | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | rtl | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | ltr | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | rtl | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | ltr | deferred-NOTE | bands | 68% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | rtl | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | ltr | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | rtl | deferred-NOTE | bands | 68% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | ltr | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | rtl | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | ltr | deferred-NOTE | bands | 71% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | rtl | deferred-NOTE | bands | 74% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | ltr | deferred-NOTE | bands | 70% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | rtl | deferred-NOTE | bands | 74% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | ltr | deferred-NOTE | colour+bands | #070605 covers 1.5% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ36)<br>#040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ45)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>29% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | rtl | deferred-NOTE | colour+bands | #070605 covers 1.5% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ36)<br>#040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk #151110 (Δ45)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>63% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | ltr | deferred-NOTE | colour+bands | #9B9287 covers 7.1% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>#9E8F86 covers 0.9% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ32)<br>#9F9189 covers 0.8% and is not a Calm token — nearest is --color-needs-odometer #A99D8F (Δ28)<br>#9E9087 covers 0.7% and is not a Calm token — nearest is --color-needs-odometer #A99D8F (Δ32)<br>#9E8E85 covers 0.5% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ30)<br>29% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | rtl | deferred-NOTE | colour+bands | #9B9287 covers 7.9% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ33)<br>#9E8F86 covers 1.0% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ32)<br>#9F9189 covers 0.8% and is not a Calm token — nearest is --color-needs-odometer #A99D8F (Δ28)<br>#9E9087 covers 0.7% and is not a Calm token — nearest is --color-needs-odometer #A99D8F (Δ32)<br>#9E8E85 covers 0.5% and is not a Calm token — nearest is --color-ink-4 #968776 (Δ30)<br>62% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | dark | ltr | pass | — | all three checks ok |
| `vehicles` | dark | rtl | deferred-NOTE | bands | 43% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | light | ltr | pass | — | all three checks ok |
| `vehicles` | light | rtl | deferred-NOTE | bands | 42% of the reference's band edges are absent — something is a different height or in a different place<br>a screen does not match the design reference. |
