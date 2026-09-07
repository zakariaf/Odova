# The 112-comparison parity sweep — EPIC-18

Generated from `design/review/parity-raw.txt`, the tool's own output kept
verbatim beside it. `test/parity/sweep_report_test.dart` fails if a row is
missing or a verdict is blank.

The differing-pixel percentages the tool prints are deliberately NOT in this
table. They are informational by the skill's own rule — the reference is Chrome
rendering HTML and the app is Skia, so 25–45% of pixels differ on a correct
screen — and a number in a triage table is a number somebody sorts by.

## Where the run stands

| | First run (18.4) | Now |
|---|---|---|
| Comparisons | 112 | 112 |
| Passing all three checks | 6 | 6 |
| Failing the band profile | 106 | 106 |
| Painting an untokenised surface | 17 | 11 |
| Built in the wrong theme | 2 | 0 |

**The band median moved 59% → 56%, and it moved the honest way.** An earlier
version of this fix DREW the phone chrome into the capture, which took the
median to 53% — and that six points was not screens getting better. `missRatio`
divides by the reference's edge count, so painting a matching clock converts
three permanently-unmatched edges into three permanently-matched ones: a
constant discount from edges that can never fail. The chrome strips are now
EXCLUDED from the row scan instead, which takes them out of the numerator and
the denominator both, so the ratio stays a statement about the screen. It also
keeps a copy of `.statusbar`'s typography out of the harness, where it had
already drifted from the stylesheet within an hour of being written.

## What was fixed

**The comparison could not see a scrim (18.6).** `--scrim` is an `rgba()` and
the token parser reads `#RRGGBB`, so a modal screen's whole composited backdrop
was reported as untokenised — and `dialog.discard` in light additionally failed
the THEME check, because a light ground under a 44% brown scrim lands nearer a
dark token. The scrim is now composited over the five GROUND tokens (not over
every token: a scrim is never painted over the brand or a due ramp, and forty
more accepted colours is forty more places a genuinely wrong surface could
hide). `--token-tolerance` is untouched.

**`settings.import` was shot over an empty box.** `child:` was a
`SizedBox.shrink()` with the sheet in `overlay:` — the file's own doc said it
stacked the sheet over `settings.backup` and the code did the opposite, so the
`#000000` that capture reported was the void behind the sheet and not an app
defect. It now stacks the two screens the way §4.3 opens them.

**No RTL class exists (18.7), and looking for one found the epic's best
finding.** Median band miss is within a point either way. What the RTL sheets
showed instead: `vehicles` passes in LTR and fails in RTL, so its sheet was
worth opening — and the app bar has no back arrow where the artboard draws one.
Counting `.appbar__lead` in `screens.html`: **twelve artboards draw one and no
screen in the app drew any.** Ten screens now use `CalmAppBar.pushed`.

## What is NOT fixed

**The band class is open on 106 of 112, median 56%.** The difference is
vertical rhythm and it is real — on `settings` the app's first card starts 16 px
lower than the reference's and every band below inherits it. The cause is not
established, and establishing it is the side-by-side read Task 18.8 is.

**11 colour failures survive**, all on dark modal captures plus two
single-screen outliers, and all just over the Δ24 line: the app paints
`#040302`–`#050403` where the dark scrim over `bg-sunk` composites to `#0F0C0A`.
Graded FIX and not chased.

## Every comparison

`verdict` is `pass`, `fixed`, `design-change` or `deferred-NOTE`.

| screen | theme | dir | verdict | class | the tool's own words |
|---|---|---|---|---|---|
| `costs` | dark | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | dark | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | ltr | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `costs` | light | rtl | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | ltr | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | dark | rtl | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `costs.fuel` | light | rtl | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | ltr | deferred-NOTE | colour+bands | #040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>62% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>56% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.confirmDelete` | light | rtl | deferred-NOTE | bands | 51% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | ltr | deferred-NOTE | colour+bands | #050403 covers 0.9% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>31% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 0.7% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>35% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | ltr | deferred-NOTE | bands | 32% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.discard` | light | rtl | deferred-NOTE | bands | 39% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | ltr | deferred-NOTE | colour+bands | #050403 covers 0.8% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>31% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | dark | rtl | deferred-NOTE | colour+bands | #050403 covers 1.0% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ25)<br>34% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | ltr | deferred-NOTE | bands | 31% of the reference's band edges are absent — something is a different height or in a different place |
| `dialog.snooze` | light | rtl | deferred-NOTE | bands | 32% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.language` | dark | ltr | pass | — | all three checks ok |
| `firstrun.language` | dark | rtl | pass | — | all three checks ok |
| `firstrun.language` | light | ltr | pass | — | all three checks ok |
| `firstrun.language` | light | rtl | pass | — | all three checks ok |
| `firstrun.vehicle` | dark | ltr | deferred-NOTE | bands | 42% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | dark | rtl | deferred-NOTE | bands | 39% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | ltr | deferred-NOTE | bands | 40% of the reference's band edges are absent — something is a different height or in a different place |
| `firstrun.vehicle` | light | rtl | deferred-NOTE | bands | 39% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | dark | rtl | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `history` | light | rtl | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | ltr | deferred-NOTE | bands | 34% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | dark | rtl | deferred-NOTE | bands | 42% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | ltr | deferred-NOTE | bands | 33% of the reference's band edges are absent — something is a different height or in a different place |
| `home` | light | rtl | deferred-NOTE | bands | 38% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | dark | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | ltr | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `log.expense` | light | rtl | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | dark | rtl | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `log.fillup` | light | rtl | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | ltr | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | dark | rtl | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `log.odometer` | light | rtl | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | dark | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `log.service` | light | rtl | deferred-NOTE | bands | 50% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | ltr | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | dark | rtl | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.edit` | light | rtl | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | ltr | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | dark | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | ltr | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `reminders.list` | light | rtl | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | ltr | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | dark | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | ltr | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `report.service` | light | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | ltr | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | dark | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | ltr | deferred-NOTE | bands | 49% of the reference's band edges are absent — something is a different height or in a different place |
| `settings` | light | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | dark | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | ltr | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.about` | light | rtl | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | ltr | deferred-NOTE | bands | 58% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | dark | rtl | deferred-NOTE | bands | 53% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | ltr | deferred-NOTE | bands | 55% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.backup` | light | rtl | deferred-NOTE | bands | 52% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | ltr | deferred-NOTE | colour+bands | #4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>58% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | dark | rtl | deferred-NOTE | colour+bands | #4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>60% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | ltr | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.import` | light | rtl | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | ltr | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | dark | rtl | deferred-NOTE | bands | 44% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | ltr | deferred-NOTE | bands | 48% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.language` | light | rtl | deferred-NOTE | bands | 45% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | ltr | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | dark | rtl | deferred-NOTE | bands | 47% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | ltr | deferred-NOTE | bands | 54% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.notifications` | light | rtl | deferred-NOTE | bands | 46% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | ltr | deferred-NOTE | bands | 66% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | dark | rtl | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | ltr | deferred-NOTE | bands | 64% of the reference's band edges are absent — something is a different height or in a different place |
| `settings.units` | light | rtl | deferred-NOTE | bands | 63% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | ltr | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | dark | rtl | deferred-NOTE | bands | 65% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | ltr | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.edit` | light | rtl | deferred-NOTE | bands | 62% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | ltr | deferred-NOTE | bands | 56% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | dark | rtl | deferred-NOTE | bands | 59% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | ltr | deferred-NOTE | bands | 57% of the reference's band edges are absent — something is a different height or in a different place |
| `trips.list` | light | rtl | deferred-NOTE | bands | 61% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | ltr | deferred-NOTE | bands | 69% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | dark | rtl | deferred-NOTE | bands | 71% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | ltr | deferred-NOTE | bands | 67% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.edit` | light | rtl | deferred-NOTE | bands | 72% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | ltr | deferred-NOTE | colour+bands | #040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>29% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | dark | rtl | deferred-NOTE | colour+bands | #040302 covers 1.1% and is not a Calm token — nearest is --color-bg-sunk under --scrim #0F0C0A (Δ28)<br>#4C443C covers 0.6% and is not a Calm token — nearest is --color-business-edge #463442 (Δ28)<br>63% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | ltr | deferred-NOTE | colour+bands | #623222 covers 0.6% and is not a Calm token — nearest is --color-brand-strong #5F3E2E (Δ27)<br>26% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicle.switcher` | light | rtl | deferred-NOTE | bands | 60% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | dark | ltr | pass | — | all three checks ok |
| `vehicles` | dark | rtl | deferred-NOTE | bands | 38% of the reference's band edges are absent — something is a different height or in a different place |
| `vehicles` | light | ltr | pass | — | all three checks ok |
| `vehicles` | light | rtl | deferred-NOTE | bands | 37% of the reference's band edges are absent — something is a different height or in a different place<br>a screen does not match the design reference. |
