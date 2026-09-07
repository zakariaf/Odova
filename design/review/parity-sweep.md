# The 112-comparison parity sweep — EPIC-18

Generated from `design/review/parity-raw.txt`, which is the tool's own output
kept verbatim beside it. `test/parity/sweep_report_test.dart` fails if a row is
missing or a verdict is blank.

The differing-pixel percentages the tool prints are deliberately NOT in this
table. They are informational by the skill's own rule — the reference is Chrome
rendering HTML and the app is Skia, so 25–45% of pixels differ on a correct
screen — and a number in a triage table is a number somebody sorts by.

## Where the run stands

| | First run (18.4) | After 18.5–18.7 |
|---|---|---|
| Comparisons | 112 | 112 |
| Passing all three checks | 6 | 6 |
| Failing the band profile | 106 | 106 |
| Painting an untokenised surface | 17 | 11 |
| Built in the wrong theme | 2 | 0 |

## What was fixed, and what it did

**The capture drew no phone chrome (18.5).** Every artboard has an iOS status
bar — `9:41` and two icons — and a home indicator; the harness reserved 54pt and
34pt for them and painted nothing. That was three band edges absent from all 112
comparisons, at y=66, 84 and 88. The capture now draws both, matched to
`.statusbar` and `.homebar::after`. Two bugs found while doing it, both the
harness's: the strip measured 54+6 because the height sat inside the padding,
and `9:41` rendered as a black box because a `Text` with no `Material` ancestor
gets Flutter's missing-style treatment — the same defect this harness already
documents for the tab bar, made again. Median band miss went 59% → 53%, max
74% → 66%.

**The colour census could not see a scrim (18.6).** `--scrim` is an `rgba()`,
and the checker reads `#RRGGBB`, so a modal screen's whole backdrop was reported
as an untokenised surface — 17 comparisons, all on the five screens that draw
one, and `dialog.discard` in light additionally failed the THEME check because a
light ground under a 44% brown scrim lands nearer a dark token. The scrim is now
composited over every token of its own theme and the results join the map.
`--token-tolerance` is untouched. 17 → 11 colour failures, 2 → 0
theme failures.

**No RTL class exists (18.7), and looking for one found a real defect.** RTL is
not systematically worse: median band miss 53.5% against LTR's 53.0%. The
mirror is broadly right. What the RTL sheets showed instead — `vehicles` passes
in LTR and fails in RTL, so the sheet was worth opening — is that
**`vehicles` has no back arrow and its artboard does.** Counting
`.appbar__lead` in `screens.html`: **twelve artboards draw one and, before this
epic, no screen in the app drew any.** Every one of those screens passed its own
per-screen parity test, because a missing element is a band edge nobody was
comparing. Ten screens now use `CalmAppBar.pushed`; `settings.import` is a sheet
and `dialog.confirmDelete` inherits the bar behind it.

That fix moves the band numbers barely at all — an arrow shares a row with the
title it sits beside — which is the honest measure of what the band profile can
and cannot see, and the reason §7 says to open the sheet and look.

## What is NOT fixed

**The band class is still open on 106 of 112, median 53%.** The remaining
difference is vertical rhythm, and it is real: on `settings` the app's first
card starts 16px lower than the reference's and every band below inherits it.
Establishing the cause needs the side-by-side read that Task 18.8 is, and it was
not completed — see `design/review/findings.md` and the sign-off.

**One narrow colour finding survives.** Dark modal screens paint `#000000` over
0.6–3.2% of the frame where the scrim composite is `#0F0C0A`. The scrim slot
itself is correct in both themes; something under it is painting pure black.
Graded FIX and not chased.

## Every comparison

`verdict` is `pass`, `fixed`, `design-change` or `deferred-NOTE`.

| screen | theme | dir | verdict | class | the tool's own words |
|---|---|---|---|---|---|
| `costs` | dark | ltr | deferred-NOTE | bands | 50% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | dark | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | ltr | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | ltr | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | ltr | deferred-NOTE | colour+bands | #040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>60% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>55% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | rtl | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | ltr | deferred-NOTE | colour+bands | #050403 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>30% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 0.7% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>34% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | ltr | deferred-NOTE | bands | 33% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | rtl | deferred-NOTE | bands | 38% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | ltr | deferred-NOTE | colour+bands | #050403 covers 0.8% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>30% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | rtl | deferred-NOTE | colour+bands | #050403 covers 1.0% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>33% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | ltr | deferred-NOTE | bands | 33% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | rtl | deferred-NOTE | bands | 31% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.language` | dark | ltr | pass | — | all three checks ok |
| `firstrun.language` | dark | rtl | pass | — | all three checks ok |
| `firstrun.language` | light | ltr | pass | — | all three checks ok |
| `firstrun.language` | light | rtl | pass | — | all three checks ok |
| `firstrun.vehicle` | dark | ltr | deferred-NOTE | bands | 40% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | dark | rtl | deferred-NOTE | bands | 36% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | ltr | deferred-NOTE | bands | 39% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | rtl | deferred-NOTE | bands | 35% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | rtl | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | ltr | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | ltr | deferred-NOTE | bands | 34% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | rtl | deferred-NOTE | bands | 41% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | ltr | deferred-NOTE | bands | 34% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | rtl | deferred-NOTE | bands | 37% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | ltr | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | ltr | deferred-NOTE | bands | 50% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | ltr | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | rtl | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | rtl | deferred-NOTE | bands | 42% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | ltr | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | rtl | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | rtl | deferred-NOTE | bands | 46% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | ltr | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | rtl | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | rtl | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | rtl | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | ltr | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | ltr | deferred-NOTE | bands | 43% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | ltr | deferred-NOTE | bands | 47% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | rtl | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | ltr | deferred-NOTE | bands | 47% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | ltr | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | rtl | deferred-NOTE | bands | 50% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | rtl | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | ltr | deferred-NOTE | colour+bands | #000000 covers 3.2% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ37)<br>59% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | rtl | deferred-NOTE | colour+bands | #000000 covers 0.6% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ37)<br>60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | ltr | deferred-NOTE | colour+bands | #000000 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ37)<br>60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | rtl | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | ltr | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | rtl | deferred-NOTE | bands | 40% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | ltr | deferred-NOTE | bands | 46% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | rtl | deferred-NOTE | bands | 41% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | rtl | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | rtl | deferred-NOTE | bands | 43% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | ltr | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | rtl | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | ltr | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | rtl | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | ltr | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | rtl | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | ltr | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | ltr | deferred-NOTE | colour+bands | #040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>29% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>63% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | ltr | deferred-NOTE | bands | 28% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | dark | ltr | pass | — | all three checks ok |
| `vehicles` | dark | rtl | deferred-NOTE | bands | 35% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | light | ltr | pass | — | all three checks ok |
| `vehicles` | light | rtl | deferred-NOTE | bands | 34% of the reference's band edges are absent — something is a different height or in a different place<br>a screen does not match the design reference. |
