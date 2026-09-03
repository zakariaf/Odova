# EPIC-13 — Costs, fuel insights and trips

| | |
|---|---|
| **Epic** | EPIC-13 — Costs, fuel insights and trips |
| **Depends on** | EPIC-11 |
| **Estimate** | **13 h (CC) · ~13 weeks (human)** over 10 tasks |
| **Spec sections** | §12 Fuel insights, costs and reports (excluding `report.service`, which EPIC-12 owns) |
| **Screens** | `costs`, `costs.fuel`, `trips.list`, `trips.edit` |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end of the epic, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

Three of these screens are read-only. They write nothing but per-stack UI state — range, fuel
kind — which dies with the tab-stack reset. Every figure on them is a pure function of the
record tables plus an injected `today`, so fixing a 2019 odometer typo changes every number
here on the next frame. That property is the whole architecture of this epic: **no cost figure
is ever persisted**, and any task that caches one has introduced the bug EPIC-12 exists to
prevent.

Be ruthless about which numbers earn their place. §12 has a long "not shown, deliberately"
list — depreciation, cost per day, "12% more than last month", projected annual cost, pie
charts, CO₂ estimates, money saved, per-station price comparison — and every one of them is a
decision already made. A statistic nobody acts on is clutter, and a confident wrong one is
worse.

---

## Where we are now

The repo today holds `SPEC.md`, the design systems under `design/`, the 108-image Calm
reference set under `design/reference/calm/`, the repo gates in `tools/`, and 47 skills under
`.claude/skills/`. **EPIC-01 created the Flutter app** — before it there was no `pubspec.yaml`
and no `lib/`, and `analysis_options.yaml` and `l10n.yaml` sat inert in the root.

By the time this epic starts, its predecessors have left behind:

| From | What this epic consumes |
|---|---|
| EPIC-01 | `pubspec.yaml` with `very_good_analysis` pinned, a committed `pubspec.lock`, `lib/`, `test/`, a green `flutter analyze --fatal-infos --fatal-warnings`, CI's Flutter lane armed. |
| The Calm design-system epic | `lib/theme/calm/**` (`CalmColors`, `CalmType`, `CalmSpace`, `CalmShapes`, `CalmMotion`) and `lib/ui/calm/**` (`CalmScaffold`, `CalmAppBar`, `CalmCard`, `CalmRowGroup`, `CalmListRow`, `CalmChip`, `CalmSegmented`, `CalmSwitch`, `CalmField`, `CalmButton`, `CalmSheet`). Feature code composes these and constructs no `BoxDecoration`. |
| The localisation epic | Six ARB files, `gen_l10n` wired, the numeral and calendar transforms, the FSI/PDI isolate helper, ICU plurals, and the unit labels that come from **our** ARBs — CLDR short units are wrong for `L/100 km` in fa and ckb. |
| The persistence epic | The Drift store, every §3 table, and DAO `.watch` streams. |
| The domain epic | The pure core: `cumulative`, `distanceBetween`, `estimateOdometer`, `dailyDistance`, `buildFuelSegments`, `segmentConsumption`, `averageConsumption`, `consumptionTrend`, `unitPrice`, `tripDistance`, `tripCost`, and the `Money` / unit value objects with their conversion and rounding table. |
| The shell epic | The four-tab shell, per-tab stacks, the reset on vehicle switch and import, and `activeVehicleId`. Tab 3's root is a placeholder today. |
| **EPIC-11** | The five entry modals in create mode, their validation, and the single write path. `trips.edit` is *specified* in §10 and its create path exists; this epic builds it against its reference and adds its live expenses list and edit-mode semantics. |
| EPIC-12 | `history` with a `HistoryFilter` that supports presets, and a provider `family` on `HistoryScope` so a second, independently-filtered instance can be pushed into the Costs stack. This epic pushes it; it does not reimplement it. |

> If those epics landed under different titles, what this epic needs is the *artefact* named in
> the table, not the title. Read `epics/progress/EPIC-11.md` and `epics/progress/EPIC-12.md`
> first; anything named here that is missing is a gap in an earlier epic, not a licence to
> build a second copy of it here.

**Deliberately still missing when this epic starts.** Tab 3 shows a placeholder — no range
chips, no headline figures, no category rows, no chart. Nothing in the app draws a chart at
all: there is no painter, no axis, no tooltip, no accessible chart summary. `trips.list` has
no route, so the only way to reach a trip today is a history row. There is no accrual
allocator — `monthlyShare` is defined in §3's derived-values table and in §12's ground rules
but nothing implements it, so an annual insurance premium currently lands entirely in the
month it was paid, which is right for `history` and wrong for `costs`. And there is no CSV
generator: §12's overflow **Export costs (CSV)** is explicitly *"the same output the Export
screen owns; this overflow entry is a second door to it, not a fifth export"*, so Task 13.10
consumes the backup/export epic's generator rather than writing a second one.

---

## What we will have when this is done

- Tab 3 opens on **Costs** with the headline pair — cost per month and cost per distance —
  over a range that defaults to the last 12 **completed** calendar months, with the current
  month reported separately as `This month so far: 64 €` so a two-day-old month cannot halve
  the average on the 2nd.
- Yearly costs are spread over the months they cover, in minor units with largest-remainder
  distribution, so 1,200.00 EUR over 365 days never becomes 1,199.99 — and one line under the
  headline says the app is doing it.
- Six category rows at most, zero rows hidden, shares at 0 dp summing to exactly 100%, each row
  tapping through to a filtered `history` instance **inside the Costs stack**.
- A stacked monthly column chart that buckets to one column per year past 36 months, mirrors
  in fa/ar/ckb — oldest month at the **right**, value axis on the right, columns still growing
  upward, stack order unchanged — and exposes an accessible summary reading the same figures
  as the list. No figure exists only inside a chart.
- An **All vehicles** toggle (≥2 vehicles) showing the household per month and per distance,
  sorted by cost per month, with **Include sold and archived** off by default and the hidden
  count named. Rows are not tappable; vehicle selection lives only in `vehicle.switcher`.
- **Fuel & consumption** with average consumption as the largest thing on the screen, last /
  best / worst tanks, the trend line with both figures in the copy so the claim is checkable,
  a per-tank column chart with a dashed average, a price line whose y axis starts at the range
  minimum minus 5%, and a data-quality row that pushes to the flagged fills.
- **Trips** with `14 trips · 3,120 km · 62% business · 486 €` over the header, an open trip
  pinned with a **Finish** action, and the trip editor with its computed-distance rule, its
  live expenses list, and a delete that keeps the expenses.
- `flutter test test/parity/` writes sixteen PNGs for these four screens and
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over all sixteen.

What we deliberately will **not** have: depreciation or market value, cost per day/year/trip,
budgets, month-on-month comparisons, projected annual cost, a pie or donut, average distance
per tank, CO₂ estimates, remaining range, "money saved", per-station price comparison, or any
currency conversion — there is no network and a made-up rate rewrites the resale value of
someone's service history.

---

## Skills to load

Open `flutter-conventions-index` first; it routes everything else.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door: feature-first layers, dumb widgets, derived-not-stored, injected clock. Every task inherits it. |
| `calm-visual-parity` | Four screens × four combinations = sixteen gates. Read it before Task 13.3 — it says what the check proves and, more importantly, what it does not. |
| `calm-components` | Category rows are `CalmListRow` in a `CalmRowGroup`, range chips are `CalmChip`, the fuel-kind control is `CalmSegmented`, the trip form is `CalmField` + `CalmSegmented`. |
| `custom-canvas-and-gestures` | Three charts are drawn inline with a `CustomPainter` and hit-tested by hand: the stacked monthly columns, the per-tank columns, and the price line with points. |
| `dataviz` *(the global skill, not in `.claude/skills/`)* | The chart conventions the brief binds this epic to: form heuristic, categorical colour, axis and tooltip rules. Its palette guidance is subordinate to `calm-tokens` — every chart colour is a Calm token or the parity check fails. |
| `value-objects-money-and-units` | `Map<currency, minor>` everywhere, largest-remainder allocation, 3 dp unit prices and cost-per-distance, 1 dp consumption, and conversion at render only. |
| `i18n-rtl-l10n` | The RTL time axis, real-text ticks so Persian digits appear in the chart, and `mpg (US)` / `mpg (imp)` as distinct strings and distinct units. |
| `accessibility-as-code` | Every chart exposes a summary node reading the same figures as the text around it, and each column or point exposes `{value} on {date}`. |
| `forms-and-input` | `trips.edit`: the computed-distance field, the *Still going* checkbox that clears two fields, per-field inline errors, and Save that is never disabled. |

---

## Tasks

### Task 13.1 — Ranges and the accrual allocator

- **Goal** — Every number on these screens agrees on what "the last 12 months" means, and an
  annual premium is spread across the months it covers without losing a cent.
- **Spec** — §12 *Ground rules for every number on these screens*; §3 *Derived values*
  (`monthlyShare`).
- **Skills** — `value-objects-money-and-units`, `dart3-idioms-and-coding-standards`,
  `seeded-determinism-and-golden-vectors`.
- **Write these tests first** — `test/core/costs/cost_range_test.dart`:
  - `on 2 September 2026 the 12-month range is 1 Sep 2025 to 31 Aug 2026` — the current month
    is out of numerator and denominator alike.
  - `the 3-month range is the last three completed calendar months`.
  - `This year runs 1 Jan to the end of the last completed month, and is hidden during
    January`.
  - `All starts at the month of the vehicle's first record`.
  - `completedMonths counts only whole months during which the vehicle was owned` — clipped by
    `purchase_date` and `sold_on` when set.
  - `thisMonthSoFar is reported separately and never enters an average`.
  And `test/core/costs/monthly_share_test.dart`:
  - `an expense with no coverage window is charged in full to its occurred_on month`.
  - `an expense with covers_from and covers_to is spread by overlapping days`.
  - `1,200.00 EUR over 365 days sums back to exactly 120000 minor units` — largest-remainder
    distribution; the property test runs 200 random windows and asserts the sum is exact every
    time. This is the test that catches 1,199.99.
  - `a coverage window where covers_to is before covers_from falls back to the point charge`.
  - `allocation runs in minor units and never touches a double`.
- **Then build** — `lib/core/costs/cost_range.dart` (`CostRange` with the four named
  constructors, `completedMonths`, `thisMonthSoFar`, all taking `today` from the injected
  clock) and `lib/core/costs/monthly_share.dart` (`monthlyShare(Expense, MonthKey)` plus
  `allocate(Money, List<MonthKey>)` doing the largest-remainder pass).
- **Verify** — `flutter test test/core/costs/`. A pass is eleven green tests including the
  200-case allocation property. Then `grep -rn "double" lib/core/costs/` shows no money value
  typed as a double.
- **Done when**
  - [ ] Ranges are computed from an injected `today`; no `DateTime.now()` in `lib/core/`.
  - [ ] Allocation is exact for every window the property test generates.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.2 — The cost aggregates, per currency

- **Goal** — `totalCost`, `costByCategory`, `costPerDistance` and `monthlyCost` return grouped
  currency maps and refuse rather than guess when the odometer cannot support them.
- **Spec** — §12 *The numbers, exactly*, *Category groups*, *Money never mixes*, *Estimated
  values look estimated*; §3 *Currency*.
- **Skills** — `value-objects-money-and-units`, `calm-due-state-and-status`,
  `error-handling-typed-results`.
- **Write these tests first** — `test/core/costs/cost_aggregates_test.dart`:
  - `totalCost sums fills, service lines and amortised expense shares, live rows only`.
  - `two currencies in range return a two-entry map, and the dominant one is the one with the
    most rows` — never a sum, never a conversion.
  - `costPerDistance uses measured readings only, never the projected odometer` — a projection
    grows while the app sits unopened, so yesterday's figure would differ from today's with no
    new data. Asserts the figure is unchanged after advancing the clock 30 days.
  - `distanceBetween falls back to the earliest reading when none precedes the range start`.
  - `a boundary reading more than 45 days from its boundary date returns the estimated
    treatment with the "62 days apart" explanation`.
  - `distanceBetween under 100 km returns a dash with the "not enough distance" reason, not a
    number`.
  - `completedMonths under 1 returns a dash with the "come back after the end of the month"
    reason and no action`.
  And `test/core/costs/cost_by_category_test.dart`:
  - `the ten ExpenseCategory values plus fuel and service collapse to the six §12 rows` — a
    table test naming every mapping, so a new category cannot silently vanish into Other.
  - `zero rows are hidden, not shown as 0 €`.
  - `shares are 0 dp and the largest row absorbs the remainder so the column reads 100%` —
    including the 33.3/33.3/33.3 case.
- **Then build** — `lib/core/costs/cost_aggregates.dart`: `totalCost`, `costPerMonth`,
  `costPerDistance`, `monthlyCost`, `costByCategory`, each returning
  `Map<String, int>`-shaped results or a sealed `CostFigure` of `Exact | Estimated | Absent`
  carrying the reason. Memoise per `(vehicleId, range)`; the memo is dropped by EPIC-12's
  vehicle recompute, never by a timer.
- **Verify** — `flutter test test/core/costs/`. A pass is ten green tests, and
  `grep -rn "exchange\|convert.*currency" lib/` returns nothing.
- **Done when**
  - [ ] No figure mixes currencies anywhere, including shares and per-distance figures.
  - [ ] Every dash carries a one-sentence reason from the pure core, not the widget.
  - [ ] Nothing derived is written to storage.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.3 — Build the `costs` screen

- **Goal** — Tab 3 becomes the real cost-of-ownership screen, matching its reference in all
  four combinations, with all seven of §12's states reachable.
- **Spec** — §12 *`costs` — Costs*: layout, states, interactions, RTL and localisation.
- **Skills** — `calm-visual-parity`, `calm-components`, `ui-states-and-feedback`,
  `widget-composition`, `i18n-rtl-l10n`, `adaptive-layout`.
- **Write these tests first** — `test/features/costs/costs_screen_test.dart`:
  - `the headline pair is the largest type on the screen, with the range span, the total, this
    month so far, and the accrual sentence beneath it`.
  - `range chips scroll rather than shrink` — asserts `Letzte 12 Monate` at 200% text scale
    does not truncate and the row scrolls.
  - `category rows put the label at the start, amount and share at the end, and the share bar
    grows from the start` — asserted in both directions.
  - `German category labels wrap to two lines with the amount end-aligned on the first`.
  - `tapping a category row pushes a filtered history instance into the Costs stack with type
    and category preset, titled "Insurance · 2026"` — and clearing the preset reverts the
    title to History.
  - `the pushed instance has no Report action` (§11).
  - `an estimated or dash figure opens a sheet with one sentence and Update odometer`.
  - `first run shows "No costs yet." with Log something and the chips hidden`.
  - `one record shows the total with both headline figures dashed and no chart`.
  - `a range with no data shows 0 € per month, a dashed cost per distance, and keeps the chips
    usable`.
  - `re-tapping tab 3 pops to costs then scrolls to top`.
  Then `test/parity/costs_parity_test.dart`: four cases — `costs-light-ltr`, `costs-dark-ltr`,
  `costs-light-rtl` (`Locale('fa')`, `TextDirection.rtl`), `costs-dark-rtl` — each pinning
  `tester.view.physicalSize = Size(780, 1688)`, `devicePixelRatio = 2.0`, `ThemeMode`
  explicitly, `textScaler` 1.0, reduced motion on, and `addTearDown(tester.view.reset)`.
- **Then build** — `lib/features/costs/costs_notifier.dart` (range and all-vehicles state,
  per tab stack, dying with the tab-stack reset) and
  `lib/features/costs/presentation/costs_screen.dart`, `costs_headline.dart`,
  `cost_category_rows.dart`, `costs_range_chips.dart`, `costs_empty_states.dart`. All `const`
  widget classes; every string from the ARBs.
- **Verify**
  ```bash
  flutter test test/features/costs/costs_screen_test.dart
  flutter test test/parity/costs_parity_test.dart        # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/costs-light-ltr.png costs \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/costs-light-ltr.png      # look at the side-by-side
  ```
  A pass is: theme ok, every surface over 0.5% within Δ24 of a Calm token, ≥75% of the
  reference band edges matched within 4px. The differing-pixel percentage is **informational
  and reads 25–45% on a correct screen** — do not chase it to zero, and do not widen
  `--token-tolerance` to make a combination pass.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] Range and toggle state live for the tab stack and die with its reset.
  - [ ] The pushed `history` instance is EPIC-12's widget, not a second implementation.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 13.4 — The monthly stacked chart

- **Goal** — Columns for shape, list for figures — one stacked column per month, drawn inline,
  correct in RTL, and reachable by a screen reader.
- **Spec** — §12 *The monthly chart*, *RTL and localisation*.
- **Skills** — `custom-canvas-and-gestures`, `dataviz`, `accessibility-as-code`,
  `calm-tokens`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/costs/monthly_chart_test.dart`:
  - `0 months with cost renders no chart`.
  - `1–2 months render rows, not columns` — `Aug 2026 · 214 €`; two columns are not a shape.
  - `3–36 months render one column per month; x labels every month to 12, then every third`.
  - `over 36 months buckets to one column per year` — 96 columns on a phone is a texture.
  - `mixed currencies render the dominant currency only, with the caption "Chart shows € only."`.
  - `the tooltip reads Mar 2026 · 214 €`.
  - `the accessible summary node reads the same figures as the category list` — no figure
    exists only inside the chart.
  - `under RTL the time axis runs right to left: the oldest month is at the right edge, the
    ticks are on the right, columns still grow upward, and the stack order is unchanged` —
    this is the one people get wrong. The axis moves; the series does not reverse its meaning.
    Assert the *first* month's column centre is at the greater x in RTL and the lesser x in
    LTR, and that the stack segment order within a column is identical in both.
  - `ticks are real text, so a Persian locale renders Persian digits` — no digits baked into
    the painting.
  - `every colour the painter uses is a Calm token` — read through `CalmColors.of(context)`;
    a raw hex here fails the parity colour gate later, on a screen whose author has moved on.
  - `a tap outside any column dismisses the tooltip rather than selecting the nearest`.
- **Then build** — `lib/features/costs/presentation/monthly_cost_chart.dart`
  (`MonthlyCostChart` + `MonthlyCostChartPainter`), with bucketing and label thinning done in
  a pure function in `lib/core/costs/monthly_chart_model.dart` so the painter draws and
  decides nothing.
- **Verify** — `flutter test test/features/costs/monthly_chart_test.dart`; then re-run the
  `costs` parity captures from Task 13.3 — the chart changes the band profile, so
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` must be re-read after it
  lands. A pass is eleven green tests and four still-green parity combinations.
- **Done when**
  - [ ] Bucketing, thinning and scaling are pure and unit-tested; the painter has no logic.
  - [ ] The RTL assertion above is in the test file, not in a comment.
  - [ ] The chart reads no colour that is not a Calm token.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.5 — All-vehicles comparison and the business split

- **Goal** — The household view for people with a second car, and the one row that goes on a
  tax form.
- **Spec** — §12 *All-vehicles comparison*, *Business split*; §7 *Active vehicle* (the
  exception).
- **Skills** — `value-objects-money-and-units`, `state-management-riverpod`,
  `calm-components`.
- **Write these tests first** — `test/features/costs/all_vehicles_test.dart`:
  - `the toggle appears only with two or more non-archived vehicles`.
  - `toggling never changes activeVehicleId` — the one exception to the app-wide scope is
    scoped to this tab.
  - `rows sort by cost per month, descending`.
  - `Include sold and archived is off by default and the trailing line names the hidden
    count`; on, those vehicles join the list and the household totals, each labelled with its
    status.
  - `a vehicle in another currency sits under its own subtotal and is not summed`.
  - `rows are not tappable` — vehicle selection lives only in `vehicle.switcher`.
  - `the category list and chart below aggregate across the included vehicles`.
  - `the range is preserved across the toggle`.
  And `test/core/costs/business_share_test.dart`:
  - `businessShare is business trip distance over all logged trip distance in range` — not
    over vehicle distance.
  - `the business row is hidden when the vehicle is not a business vehicle, and when no trips
    fall in the range`.
  - `the row carries the caption "Worked out from the trips you logged, not from all your
    driving."`.
- **Then build** — `businessShare` in `lib/core/costs/business_share.dart`, the household
  aggregation in `lib/core/costs/household_costs.dart`, and
  `lib/features/costs/presentation/all_vehicles_panel.dart` +
  `business_split_row.dart`.
- **Verify** — `flutter test test/features/costs/all_vehicles_test.dart
  test/core/costs/business_share_test.dart`. A pass is eleven green tests. Re-run the `costs`
  parity captures if the panel changes the default layout.
- **Done when**
  - [ ] `activeVehicleId` is provably untouched by anything in this task.
  - [ ] Cross-currency household totals group and never sum.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.6 — Fuel insight maths

- **Goal** — The numbers on `costs.fuel`: total-over-total averages, best and worst tanks, the
  price figures, and the per-currency exclusion that stops euros being divided by litres of
  pounds.
- **Spec** — §12 *`costs.fuel` → The numbers, exactly*, the `consumptionTrend` table, *Fuel
  kinds and electric*; §3 *Fuel maths*.
- **Skills** — `value-objects-money-and-units`, `seeded-determinism-and-golden-vectors`,
  `dart3-idioms-and-coding-standards`.
- **Write these tests first** — `test/core/fuel/fuel_insights_test.dart`:
  - `averageConsumption is total volume over total distance, never a mean of means` — the
    fixture is a 40 km segment and a 900 km segment; the mean of means is a few percent high
    and the test names that number so the failure is legible.
  - `avgPricePaid is total cost over total quantity, not the mean of unit prices`.
  - `lastTank is the newest segment's consumption; best and worst carry the closing fill's
    date`.
  - `fuelCostPerDistance sums exactly the fills whose volume built the segment` — those after
    the opening fill up to and including the closing one. Off by one fill here is the most
    common bug in this category, so the test asserts the exact set of fill ids used.
  - `a segment whose contributing fills mix currencies is excluded from every per-distance
    figure, contributes volume and distance only, and is counted for the data-quality row`.
  - `every money-bearing figure returns a currency map with the dominant currency first` —
    dominant is most fills in range.
  - `unit price is derived at display time to 3 dp and is never stored` — asserts no column
    holds it.
  - `consumption renders to 1 dp` — the measurement is not good enough for two.
  - `the trend copy carries both figures` — "Last 3 tanks 7.1, the 6 before 6.5"; `steady` and
    `insufficient_data` render nothing at all.
  - `no cause is ever suggested` — the copy set contains no explanatory string.
  - `electric uses energy_wh and shows kWh/100 km or mi/kWh; with no full charge in range the
    consumption block is replaced by cost figures plus the "mark a charge as full" line`.
  - `mass-sold gas displays in kg and kg/100 km`.
  - `series are per fuel_kind and never merged` — a bi-fuel LPG car has two averages.
- **Then build** — `lib/core/fuel/fuel_insights.dart`: `FuelInsights.forRange(...)` returning
  a value type holding the averages, best/worst with dates, price figures, spend and volume,
  the trend, and the data-quality counts — all per currency where money is involved. Pure,
  clock-injected, no widget.
- **Verify** — `flutter test test/core/fuel/fuel_insights_test.dart`. A pass is thirteen green
  tests including the exact-fill-set assertion.
- **Done when**
  - [ ] Every average is total-over-total.
  - [ ] The mixed-currency segment rule is enforced in the core, not in the screen.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.7 — Build `costs.fuel` with both charts

- **Goal** — The fuel screen, matching its reference in all four combinations, with the
  consumption columns, the price line, and the data-quality row.
- **Spec** — §12 *`costs.fuel`*: layout, charts, states, RTL and localisation.
- **Skills** — `calm-visual-parity`, `custom-canvas-and-gestures`, `dataviz`,
  `accessibility-as-code`, `calm-components`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/fuel/fuel_screen_test.dart`:
  - `average consumption is the largest thing on the screen`.
  - `the fuel-kind control appears only with fills of two or more kinds, and mirrors its order
    in RTL`.
  - `empty shows "No fill-ups yet." with Log a fill-up and the range selector hidden`.
  - `one fill shows price paid and total spend but no consumption block`.
  - `two fills, one segment shows a single figure as text — no chart, no trend, no
    best/worst`.
  - `a range empty of fills keeps the chips usable and says "No fill-ups between June and
    August."`; on first entry only, the default falls back to All when 12 months holds fewer
    than three segments.
  - `a stale odometer does not dim consumption` — it is measured between two real readings.
    Only the per-month and per-distance figures take the estimated treatment.
  - `hundreds of fills show five recent rows and defer to history`.
  - `the data-quality row appears under the app bar, is never red and never a modal, and
    pushes a filtered history instance with type fill-up and flagged rows only`.
  - `the "Last tank · Best · Worst" strip becomes a two-column grid below 380 dp or at 150%
    text scale, rather than shrinking type`.
  And `test/features/fuel/fuel_charts_test.dart`:
  - `0 segments hides the consumption chart with "Your first figure arrives at your next full
    fill."; the price chart hides below 2 fills`.
  - `2 segments render with no average line and no best/worst; 3–60 render with the dashed
    average and x labels at 3 evenly spaced dates`.
  - `over 60 segments the columns bucket to one per month using that month's volume over
    distance, and the price points thin to that month's avgPricePaid`.
  - `the price chart's y axis starts at the range minimum minus 5%` — a zero baseline flattens
    a few percent of variation to nothing.
  - `consumption is columns and price is a line` — segments are discrete measurements at
    irregular intervals, and a line asserts values on days that were never measured.
  - `both axes run right to left under RTL with the value axis on the right; the dashed
    average line is unchanged and the price line's slope reverses with the axis`.
  - `tapping a column shows 19 Aug · 6.1 L/100 km · 612 km · 37.3 L; a second tap on the
    tooltip opens log.fillup in edit mode for the closing fill`.
  - `each column and point exposes {value} on {date}, and both charts expose a summary node
    with the same figures as the text around them`.
  Then `test/parity/costs_fuel_parity_test.dart`: the four combinations, pinned as in Task
  12.3.
- **Then build** — `lib/features/fuel/fuel_notifier.dart` (range and fuel kind, per stack) and
  `lib/features/fuel/presentation/fuel_screen.dart`, `consumption_chart.dart`,
  `price_chart.dart`, `recent_fills_rows.dart`, `fuel_data_quality_row.dart`, with the chart
  models pure in `lib/core/fuel/fuel_chart_model.dart`.
- **Verify**
  ```bash
  flutter test test/features/fuel/
  flutter test test/parity/costs_fuel_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/costs.fuel-light-ltr.png costs.fuel \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/costs.fuel-light-ltr.png  # look at the side-by-side
  ```
  Read the output as in Task 13.3: theme, tokens and band edges gate; the pixel percentage
  does not. If a chart colour trips `#XXXXXX covers N% and is not a Calm token`, the fix is
  the token, never the tolerance.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] Both charts have an accessible summary and per-mark semantics.
  - [ ] Consumption units come from our ARBs, not the platform unit formatter.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 13.8 — Build `trips.list`

- **Goal** — The cost-attribution list, with the one aggregate worth computing at the top.
- **Spec** — §12 *`trips.list` — Trips*; §3 (`tripDistance`, `tripCost`).
- **Skills** — `calm-visual-parity`, `calm-components`, `ui-states-and-feedback`,
  `flutter-performance`.
- **Write these tests first** — `test/core/trips/trip_aggregates_test.dart`:
  - `tripDistance is cumulative end minus cumulative start, falling back to
    manual_distance_m`.
  - `tripCost is its fills plus its expenses, per currency, never summed across currencies`.
  - `businessShare is business distance over all logged trip distance`.
  - `trip distances are never summed into vehicle distance` — the header says "across logged
    trips" for exactly this reason, and the test asserts the vehicle's distance figure is
    untouched.
  And `test/features/trips/trips_list_test.dart`:
  - `the header strip reads 14 trips · 3,120 km · 62% business · 486 €`.
  - `an open trip with a null ended_on is pinned at the top with an Open chip and a Finish
    action`.
  - `empty shows "No trips yet. Log one to see what a journey costs." with Add trip`.
  - `hundreds of trips virtualise with a year separator every January`.
  - `a trip with no title falls back to its date range`.
  - `distance and cost sit at the end edge and the purpose chip follows the title; the open
    badge mirrors` — asserted in both directions.
  - `German purpose chips Geschäftlich, Arbeitsweg and Privat scroll rather than wrap`.
  - `tapping a row opens trips.edit as a modal; + opens it in create mode`.
  Then `test/parity/trips_list_parity_test.dart`: the four combinations, pinned as in Task
  12.3.
- **Then build** — `lib/core/trips/trip_aggregates.dart`,
  `lib/features/trips/trips_list_notifier.dart`, and
  `lib/features/trips/presentation/trips_list_screen.dart` + `trip_row.dart` +
  `trips_header_strip.dart`, with the route pushed from the `costs` Trips card.
- **Verify**
  ```bash
  flutter test test/core/trips/ test/features/trips/trips_list_test.dart
  flutter test test/parity/trips_list_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/trips.list-light-ltr.png trips.list \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/trips.list-light-ltr.png  # look at the side-by-side
  ```
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] The business percentage is the only aggregate this screen computes beyond the header
        strip's three facts.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 13.9 — Build `trips.edit`

- **Goal** — The trip editor: fast enough for a delivery driver logging several a day, with
  the distance rule that keeps the odometer the source of truth.
- **Spec** — §10 *`trips.edit` — Trip* (fields, states, distance rule, navigation, RTL); §11
  (the trip context band, already built in EPIC-12 Task 12.7).
- **Skills** — `calm-visual-parity`, `forms-and-input`, `calm-components`,
  `error-handling-typed-results`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/features/trips/trips_edit_test.dart`:
  - `purpose prefills to Business when the vehicle answered yes to driving for work, else
    Personal`.
  - `Starts defaults to today and refuses a future date with "Pick today or a day in the
    past."`.
  - `an end date before the start shows "The end date is before the start date."`.
  - `ticking Still going hides the end fields and clears the end date and end odometer`.
  - `an end odometer below the start shows "The end reading is lower than the start
    reading."`.
  - `distance is computed with the ƒ badge and is editable only when both odometer fields are
    empty`; a manual distance of zero shows "Distance must be more than zero."
  - `a manual distance writes manual_distance_m and emits no odometer readings` — a
    bare-distance trip contributes nothing to the odometer series.
  - `an odometer pair emits two readings with source trip_start and trip_end`.
  - `Save is never disabled; on tap it validates, scrolls to the first failing field, focuses
    it, and shows one inline error beneath it`.
  - `the expenses list is a live query, not a draft` — an expense added through Add expense
    appears without a save.
  - `Add expense opens log.expense with trip_id prefilled and locked`.
  - `mixed currencies group as "612.00 € · 80.00 £" and no rate is applied`.
  - `dozens of expenses cap at 8 rows with "See all 34", opening the filtered history instance
    in the Costs stack`.
  - `an open trip shows End this trip, which reveals the end fields and focuses the
    odometer`.
  - `deleting a trip keeps its expenses and fill-ups, and the dialog says "Its 3 entries stay
    in your history."`.
  - `the purpose control wraps to a 2×2 grid in German at large text scales rather than
    shrinking its text`.
  Then `test/parity/trips_edit_parity_test.dart`: the four combinations, pinned as in Task
  12.3.
- **Then build** — the `trips.edit` screen against its reference:
  `lib/features/trips/presentation/trips_edit_screen.dart`, `trip_purpose_control.dart`,
  `trip_expenses_section.dart`, plus `TripDraft` validation in
  `lib/core/trips/trip_draft.dart` and the write path in `lib/data/trip_repository.dart`
  (one `Trip`, plus up to two `OdometerReading` rows, in a single transaction, ending in the
  vehicle recompute and the notification rebuild).
- **Verify**
  ```bash
  flutter test test/features/trips/trips_edit_test.dart
  flutter test test/parity/trips_edit_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/trips.edit-light-ltr.png trips.edit \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/trips.edit-light-ltr.png  # look at the side-by-side
  ```
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] A trip is never the source of truth for vehicle distance.
  - [ ] The trip save ends in the recompute contract EPIC-12 built.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 13.10 — Costs CSV, the estimate sheet, and the navigation edges

- **Goal** — Close the section: the overflow CSV export, the bottom sheet behind every
  estimated or dashed figure, and every edge in §12's navigation tables actually wired.
- **Spec** — §12 *Interactions* (both screens), *Navigation edges*; §7 *Navigation graph*.
- **Skills** — `data-export-and-restore`, `navigation-and-routing`,
  `service-boundary-and-native`, `ui-states-and-feedback`.
- **Write these tests first** — `test/features/costs/costs_export_test.dart`:
  - `the overflow calls the shared CSV generator and adds no second implementation` — asserts
    the same function the Export screen uses; a fifth export is explicitly not what this is.
  - `the filename is odova-costs-golf-2026-09-02.csv, and odova-costs-all-2026-09-02.csv with
    the all-vehicles toggle on`.
  - `the file is handed to the OS share sheet through the share port` — the app picks no
    destination.
  - `a generation failure surfaces inline, not as a dialog`.
  And `test/features/costs/costs_navigation_test.dart`:
  - `every edge in §12 exists: costs → costs.fuel, costs → trips.list, costs → filtered
    history in-stack, costs → log.odometer from an estimate sheet, costs.fuel → log.fillup in
    edit mode, costs.fuel → filtered history via See all and the data-quality row,
    trips.list → trips.edit, trips.edit → log.expense`.
  - `report.service is not reachable from costs` — one door is enough for a screen opened
    twice a decade.
  - `no stack in this tab goes more than two pushes deep` (§7) — a test over the route table,
    so the rule is enforced rather than remembered.
  - `every stack in tab 3 resets to costs on a vehicle switch and on an import`.
  - `the estimate sheet shows one sentence and Update odometer, and its copy differs for the
    45-day, under-100 km and under-one-month cases`.
- **Then build** — the overflow menu on `costs`, `lib/features/costs/presentation/
  estimate_explain_sheet.dart`, and the route registrations in `lib/app/routing/`. No new export
  code: this is a second door to the generator the backup/export epic owns.
- **Verify** — `flutter test test/features/costs/costs_export_test.dart
  test/features/costs/costs_navigation_test.dart`; then `flutter test` in full and
  `flutter analyze --fatal-infos --fatal-warnings`. A pass is nine green tests, a full green
  suite, and `bash tools/audit_deps.sh` still refusing every networked dependency.
- **Done when**
  - [ ] Exactly one CSV generator exists in the tree.
  - [ ] The two-push depth rule is enforced by a test.
  - [ ] Every §12 navigation edge is exercised.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] Tab 3 shows real cost of ownership over completed months only, with the accrual spread
      applied and stated, per-currency totals that never sum, and six category rows at most.
- [ ] The monthly chart buckets, mirrors and reads correctly, and no figure exists only inside
      it.
- [ ] The all-vehicles toggle and the business split behave as §12 specifies, and neither
      touches `activeVehicleId`.
- [ ] `costs.fuel` shows total-over-total averages, best and worst tanks, a checkable trend, a
      column chart with a dashed average, a price line on a non-zero baseline, and a
      data-quality row that leads to the flagged fills.
- [ ] `trips.list` and `trips.edit` work end to end, and a trip never becomes the source of
      truth for vehicle distance.
- [ ] Nothing on these screens is persisted; every figure recomputes from the record tables on
      the next frame after an edit.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

---

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-13.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
