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

