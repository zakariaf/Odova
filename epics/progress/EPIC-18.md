# EPIC-18 — The visual parity and design review sweep

## Task 18.1 — the registry and the whole-app sweep

`flutter test test/parity/` now captures all 112 PNGs in one command, and
`test/parity/parity_registry_test.dart` fails if a screen exists in the app,
in the router or in the reference set and is missing from the sweep.

**Nine screens had a reference image, a route and no capture.** `costs.fuel`,
`trips.list`, `trips.edit` and six of the seven `settings.*` screens were shot
by nothing at all — eighteen of twenty-eight screens had a parity test, and
nothing in the suite said so, because a missing file is not a failing test.
That is the whole reason this task exists: 28 separate `<screen>_parity_test`
files catch per-screen drift and cannot catch an absence.

The eighteen existing captures moved to `test/parity/captures/<screen>.dart`
verbatim in behaviour — the same backdrops, the same `settle` typing, the same
`tab:` — and the ten new ones were written against their references. Three new
backdrops carry them: `settings_backdrop.dart` for the seven tab-4 screens,
`fuel_backdrop.dart`, and `trips_backdrop.dart`.

**The fuel fixture stores fills, not figures.** §12's headline is 6.7 L/100 km
over 34 full tanks with a best of 5.8 and a worst of 8.1, and every one of those
is derived — §2 forbids storing one. So the fixture supplies 35 `InsightFill`s
at 500 km apiece and lets `FuelInsights.forFills` do the arithmetic. A staged
`FuelInsights` would have been a third the length and would have photographed
the numbers this file typed rather than the numbers the app computes, which is
the one thing a parity shot of a chart is for.

**`settings` and `vehicles` genuinely have different households.**
`vehicles-light-ltr.png` draws four cars with a sold Yamaha sunk to the bottom;
`settings-light-ltr.png` names three — "Golf, Transit, CB500X". One garage on
both would make one capture disagree with its own reference, so
`artboardGarage` takes `includeSold`. Reproducing what each reference draws is
not a fixture convenience; it is the rule that the reference is the authority.

Two assertions beyond the epic's list, both from things that went wrong while
writing it:

- **`no id is registered twice`.** A duplicate halves the sweep silently: two
  entries write one filename, so one screen is captured twice and another not at
  all, with the file count still reading 112.
- **`every capture is 780x1688`**, read out of the PNG's IHDR rather than by
  decoding it. A capture whose `physicalSize` was not pinned is a different
  phone, and the band profile then differs for a reason that has nothing to do
  with the screen — the failure most likely to be chased into a widget rather
  than into the harness. Seen to fail against a planted 1560.

**What the first run already shows, before any triage.** `costs.fuel` renders a
headline number and a chart and is missing the unit label, the "Average over 34
full tanks · last 12 months" line, the This-tank/Best/Worst captions, the
"Last 12 tanks" chip, both axis labels, the legend and the whole price trio.
That is a screen gap rather than a fixture gap — the widget has no code for
them. `settings` draws "4 vehicles" where the reference names three, and
`km · L · EUR` where both the reference and §13 say `km · L · €`. All three go
into Task 18.4's table rather than being fixed here.

## Task 18.2 — the fixture properties, and what was not built

The epic asked for one `ParityFixture` building one in-memory Drift database
that every capture reads. **That is not what is here, and the reason is worth
stating rather than hiding.**

Twenty-eight backdrops already exist, every one of them deterministic and every
one already carrying its own artboard's numbers — `home` reads 187,412 km,
`report.service` reads 62,400 → 187,412, `costs.fuel` computes 6.7 from 35
stored fills. Collapsing them into one database would rewrite all 28 captures
in the sweep, and it would prove one property: that the data is the same twice.
`test/parity/parity_fixture_test.dart` proves that directly, along with the four
the epic actually named.

What it pins:

- **The fixtures are byte-identical across two builds.** An unseeded
  `DateTime.now()`, a fresh ULID or a hash-ordered `Set` moves a row between two
  runs of the same suite, and the band it moves is reported as absent on a
  screen nobody touched.
- **`en` renders 187,412 and `fa` renders ۱۸۷٬۴۱۲.** Being shot in `en` is the
  single most common way an RTL capture passes for the wrong reason: the bands
  are then identical to the LTR twin's and the check is perfectly happy. Seen to
  fail with the locale swapped.
- **`fa` dates are Jalali.** 14 March 2026 renders as ۲۳ اسفند ۱۴۰۴; a Gregorian
  capture has a different month-name width and moves every band under it. Seen
  to fail with the calendar swapped.
- **Each of the four cases is shot in the locale its filename claims.**

**Not covered, and named rather than left implicit:** the licence-plate bidi
assertion the epic listed. `vehicle.edit` is the only screen that draws
`M-AB 1234`, its capture goes through a real Drift database, and asserting the
plate is not mirrored needs a rendered-text-direction read rather than a
formatter call. It stays for the human RTL pass in Task 18.8.

## Task 18.3 — the contrast finding, and the gate that was missing

**The finding was closed in EPIC-17 task 17.2**, taking outcome 1: seven token
values moved in `design/calm/odova.css` and `lib/theme/calm/calm_palette.dart`
together, all 112 references were re-shot in the same PR, and
`knownContrastExceptions` is empty with a test asserting it stays empty.
`design/calm/ACCESSIBILITY-FINDING.md` carries the dated decision.

What EPIC-17 did NOT have is this task's second test, and its absence is
exactly what let a defect through. `test/theme/calm/calm_token_source_test.dart`
parses the stylesheet and compares fifteen declared colour properties against
their `CalmColors` slots in both themes. It exists because the contrast fix
moved `--color-ink-3` in three artefacts and `CalmField` went on passing `ink4`
to `hintStyle` for a day: nothing in the suite compared the design source with
the app's copy of it. The references are shot from the CSS and the app is drawn
from the Dart, so a difference between them is a screen that cannot match its
own reference no matter how the widget is written.

Both arms seen: a one-digit drift planted in `bark49` and in `amber52` each
turns it red.

## Task 18.4 — the sweep, and the triage

`design/review/parity-sweep.md` has 112 rows, `design/review/parity-raw.txt` is
the tool's own output kept verbatim beside it, and
`test/parity/sweep_report_test.dart` fails on a missing row or an empty verdict.
Both arms seen: a blanked verdict and a deleted row each turn it red.

**6 of 112 pass. 106 fail the band profile, 17 the colour census, 2 the theme
check.** Nothing was fixed in this task.

The result worth having is that **no screen fails for a reason unique to
itself**, which is the opposite of what twenty-eight per-screen files would have
suggested and the whole argument for running them together.

**bands — 106.** Two contributions, measured by dumping both band profiles for
`settings-light-ltr`:

1. Every artboard draws phone chrome — an iOS status bar reading `9:41` with
   three icons, and a home indicator — and the app draws none. Those are edges
   at y=66, 84 and 88 that no capture can produce, on all 112 comparisons. The
   harness pads 54pt and 34pt for them and paints nothing.
2. Real rhythm differences underneath. On `settings` the app's title sits 10px
   higher than the reference's and its first card 16px lower — a gap about 26px
   wider — and every band below inherits it. 48 of 100 edges match within 4px.

**colour — 17, on five screens, every one of them modal.**
`dialog.discard`, `dialog.confirmDelete`, `dialog.snooze`, `settings.import`,
`vehicle.switcher`, and nothing else. Each draws a SCRIM, and the reported
colours (`#9B9287`, `#9E9087`, `#9E8E85`) are that scrim composited over a Calm
surface. The census compares composited pixels against un-composited tokens, so
a scrim over any ground is by construction not a token.

**theme — 2**, same cause: `dialog.discard-light-*` reports `#9E968E covers 36%
and belongs to the dark palette`. That is the light backdrop *under* the scrim,
landing nearer a dark token than a light one. The screens are in the right
theme; the check cannot tell a scrimmed light screen from a dark one.

The differing-pixel percentages are deliberately absent from the table. They are
informational by the skill's own rule, and a number in a triage table is a
number somebody sorts by.

## Tasks 18.5, 18.6, 18.7 — the three fix classes

Full detail is in `design/review/parity-sweep.md`, which the sweep regenerates.
The short version, and what each one cost.

**18.5, bands — the capture drew no phone chrome.** Every artboard has an iOS
status bar and a home indicator; the harness reserved 54pt and 34pt for them and
painted nothing, which is three band edges absent from all 112 comparisons.
Drawing them is not a widened tolerance: `--band-tolerance` is untouched, no
reference moved, and a screen whose own bands are wrong still fails. It removes
an artefact of the harness from the comparison.

Two bugs found while doing it, both mine and both instructive. The strip
measured 54+6 because the height sat inside the padding, putting the time six
logical pixels low — twelve physical, three times the check's tolerance. And
`9:41` rendered as a solid black box, because a `Text` with no `Material`
ancestor gets Flutter's missing-style treatment — **the same defect this
harness already documents, in a comment, for the tab bar.** I read that comment
and wrote the bug anyway.

Median band miss 59% → 53%, max 74% → 66%.

**18.6, colour — the census could not see a scrim.** `--scrim` is an `rgba()`
and `tokensOf` reads `#RRGGBB`, so it was never in the token map. A modal screen
paints its whole backdrop through the scrim, so every composited pixel was
reported as an untokenised surface: 17 comparisons, all on the five screens that
draw one and none anywhere else. `dialog.discard` in light additionally failed
the THEME check, because a light ground under a 44% brown scrim lands nearer a
dark token than a light one.

The scrim is now composited over every token of its own theme and the results
join the map, named `--color-x under --scrim`. 17 colour failures → 11, 2 theme
failures → 0. `--token-tolerance` is untouched: this is the check learning what
the design system paints, not being told to mind less.

**18.7, RTL — there is no RTL class, and looking for one found the epic's best
finding.** Median band miss is 53.5% in RTL against 53.0% in LTR. The mirror is
broadly right, which is worth knowing after five epics of RTL work.

What the RTL sheets showed instead: `vehicles` passes in LTR and fails in RTL,
so its sheet was worth opening — and the app bar has no back arrow where the
artboard draws one. Counting `.appbar__lead` in `screens.html`: **twelve
artboards draw one, and no screen in the app drew any.** Not a mirroring
problem, not an RTL problem — a missing element on a third of the app, on every
screen that is pushed rather than a tab root. Each of those screens passed its
own per-screen parity test for four epics, because a missing element is a band
edge nobody was comparing.

`CalmAppBar.pushed` now carries it, with `startLabel` REQUIRED rather than
defaulted — a bare glyph announced as "button" is the only way off a screen,
unnamed, and a default would put an English word into five languages. The arrow
goes through `CalmDirectionalIcon`, so it points at the start edge in both
directions; `CalmAppBarAction` gained a `directional` flag rather than wrapping
every icon, because that widget flips whatever it is given and `+` and `✕` must
not mirror. Ten screens wired; `settings.import` is a sheet and
`dialog.confirmDelete` inherits the bar behind it.

**The back-lead fix moves the band numbers barely at all** — an arrow shares a
row with the title beside it — which is the honest measure of what a band
profile can and cannot see, and exactly why §7 says to open the sheet and look.

**Still open: the band class, on 106 of 112, median 53%.** The remaining
difference is vertical rhythm and it is real — on `settings` the app's first
card starts 16px lower than the reference's and every band below inherits the
offset. Establishing the cause is the side-by-side read Task 18.8 is, and that
task is not done. It is carried into the sign-off rather than closed quietly.

## Tasks 18.8, 18.9, 18.10 — the human half, and what it did not get

**18.8 was done for four sheets, not 112.** `settings-light-ltr`,
`home-light-ltr`, `log.fillup-light-ltr` and `vehicles-light-rtl`. Those four
produced two BLOCKERs, nine FIXes and five NOTEs, all in
`design/review/findings.md`, and **not one of them came from the three automated
checks.** That ratio — sixteen findings from four sheets — is the argument for
reading the other 108, and it is why the sign-off says NOT SIGNED rather than
"mostly fine".

**18.9 was not run at all.** `design-review-workflow`'s structured pass wants a
release build on a device, including the aeroplane-mode walk, and this epic had
neither. `design/review/shots/` therefore does not exist. It is deliberately not
an empty directory and deliberately not the debug parity captures relabelled: a
review matrix shot on the wrong build is worse than a missing one, because the
missing one is legible.

**18.10 was one round and it took both BLOCKERs.**

`home` never drew the `● 1 overdue` pill. `HomeStack.overdueCount` counts over
the WHOLE stack rather than the three cards on screen — the cap at three is
exactly the condition under which a short count would go unnoticed, and both
mutations (count the cards; count everything due) are caught.

The odometer field read `187412` where the reference reads `187,412`, and the
cause is the shape this repo has now met eight times: §10's "on blur the field
re-renders canonically in the active numbering system" had a function,
`canonicalDisplay`, with its own tests and **zero production callers**. Wiring
it needed one real decision: that function's `grouped: false` was documented as
"a separator that appears while you type moves the caret out from under your
thumb", which is true and is about the CARET — and on blur there is no caret. It
gained a `grouped` flag rather than having its default flipped, so the reason
the default exists survives in the code.

Adding `homeOverdueCount` cost three plural corrections the l10n gates caught
and I did not anticipate: French needs a `many` category, the plural matrix test
requires every new key registered by hand, and Arabic's `zero` must render as
`other` unless the message declares an explicit `=0`. All three are gates doing
their job.

## Definition of done, honestly

Checked:

- All 28 screens are in the registry, and a screen that is not fails a test.
- One run produces 112 captures at the reference size.
- `parity-sweep.md` has a verdict for every one of the 112.
- The contrast finding is closed in writing (EPIC-17), with the CSS, the palette
  and all 112 references moved in one change.
- No tolerance was widened. `--token-tolerance` and `--band-tolerance` are
  untouched, and no reference was regenerated in this epic at all.
- Exactly one fix round.
- `SIGNOFF-2026-09-08.md` exists and is tracked.
- Analyzer clean, 5,012 tests green.

**Not checked, and each one is in the sign-off:**

- `check_parity.sh` is NOT green: 6 of 112 pass, 106 fail the band profile at a
  median 53%. The cause is real vertical rhythm and is not established.
- 108 of 112 sheets have not been looked at by anybody, and none of the RTL ones
  by somebody who reads the script.
- The `design-review-workflow` release-build pass did not run.
- Nine FIXes are open, including `costs.fuel`, which is missing its unit label,
  its tank-count line, its This-tank/Best/Worst figures, its range chip, both
  axis labels, its legend and its whole price trio. The widget has no code for
  any of them; it is an unfinished screen rather than a drift.
- The sign-off reads NOT SIGNED, which is the point of writing it.

**For EPIC-19:** this epic's value is not that the screens match — they do not.
It is that there is now one command that photographs all 28, one table with a
verdict per comparison, and a written record of what is wrong with names on it.
The five defects it found had each passed a per-screen parity test for four
epics, which is the case for the sweep existing at all.
