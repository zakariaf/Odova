# EPIC-13 — Costs, fuel insights and trips

- **Task 13.1 (complete).** `CostRange` and the accrual allocator. Every range
  ends on the last day of the previous calendar month — §12's reason is that
  "an average including a two-day-old month halves itself on the 2nd", and a
  user watching that does not conclude the range is inclusive, they conclude
  the app is wrong. `thisYear` returns NULL in January rather than an empty
  range, because a chip that yields a dash punishes the tap.
  `completedMonths` returns 0, not 1, when the vehicle was owned for none of
  the range: zero is a real answer and the caller must show a dash rather than
  invent a monthly cost for a car nobody had.
  `allocateByWeight` is largest-remainder in minor units — three mutations
  checked, including the one that produces §12's named failure, 1,199.99. The
  tie-break has a second sort key on the INDEX: Dart's `sort` is not
  documented as stable, so equal remainders could otherwise allocate a cent
  differently between runs, which is a flaking golden and two users who cannot
  reconcile the same report.
- **Carried in from EPIC-12's review**, to be taken with the tasks that touch
  the same code rather than twice:
  - The shared document traversal (`walkServiceReport`) — this epic builds
    `costs` and `costs.fuel` over the same shapes and makes the case concrete.
  - `PdfCanvas` cannot express a table; `drawRow` falls out of that walk.
  - `_moneyRows` and `_select` diverge on the `correction` arm and on
    `filter.query`, so a month header can disagree with the rows under it
    during a search. One union builder with a projection flag.
  - `HistoryFilter.categories` / `needsAttention` are applied by neither SQL
    builder. This epic's cost drill-down is their first consumer, so applying
    them is a task here rather than a discovery.
  - `cancelShare` does not cancel, and `PlatformShareService` assigns
    `_written` after the write.
  - Home's `_ownedFor` answers "how long has this owner had the car" a second
    way, through `bucketRelativeDays`' `days / 30.44`, and disagrees with
    `CivilDate.monthsUntil`. One ownership-span function over `monthsUntil`.
- **Task 13.2 (complete).** The cost aggregates. `CostFigure` is sealed with
  three variants because §12's three treatments are three SCREENS — exact
  prints a number, estimated prints one with the soft treatment and a tap
  explanation, absent prints a dash. Collapsing estimated into absent hides a
  usable figure; collapsing it into exact states a shaky one as fact.
  `costPerDistance` takes readings and corrections and deliberately does NOT
  import the estimate engine: §12's reason is that a projection grows while
  the app sits unopened, so the same records would give a different cost per
  kilometre tomorrow. The test advances the clock 30 days and asserts the
  figure does not move. Four refusals mutation-checked: the 100 km floor, the
  45-day boundary tolerance, the correction fold, and the sub-month dash.
  Category shares reuse `allocateByWeight`, so the two places this app splits
  a whole into parts cannot disagree about how — and "the largest row absorbs
  the remainder" falls out of the sort order rather than needing its own rule.
  `rowForCategory` is an exhaustive switch with NO default, so an
  `ExpenseCategory` added later is a compile error rather than a silent
  arrival in Other.
- **Task 13.3 (screen built; parity partial).** `costs` built against the
  REFERENCE rather than §12's ASCII sketch: chips above a single headline
  card, a share bar under every category row, two nav rows at the foot.
  Money drops a zero minor part (`€273`, not `€273.00`) because the screen is
  read at a glance — a non-zero minor part is always kept, since `€0.29 per
  kilometre` rounded is meaningless. Both figures carry their unit: `€0.29 ·
  €2,184` is two amounts with nothing saying what either measures.
  `arb_template_test.dart` refused the range chips' baked digits — a Latin "3"
  does not shape to Persian numerals — so the count is a plural placeholder.
  **Parity: theme and Calm-token surfaces PASS all four; band profile 58/117,
  59/117, 42/112, 41/108.** Nothing widened, no reference regenerated. The
  dominant missing band group is the monthly chart inside the headline card,
  which is task 13.4 — chasing the profile before it lands would be measuring
  a card that is about to change height.
- **Open in 13.3, to be closed by later tasks in this epic:** the nav rows have
  no subtitles yet (`6.4 L/100 km · €1.734/L last paid` needs 13.6's fuel
  maths; `14 trips · 3,120 km · 62% business` needs 13.8's trip aggregates),
  the category rows do not yet push a filtered `history`, and the dash figures
  do not yet open their explanation sheet.
- **Task 13.4 (complete).** §12's stacked chart. All the deciding — bucketing,
  label thinning, scaling, segment order — is in `monthly_chart_model.dart`
  and asserted without a canvas; the widget turns a `MonthlyChart` into
  rectangles and chooses nothing. The RTL rule is the one the epic flags as
  easy to get wrong: the AXIS mirrors and the SERIES does not, so the column
  list is never reversed and Flutter's own start-edge layout does the
  mirroring. Both halves are pinned — the oldest month's x position flips, and
  the stack order is asserted identical in both directions. A stack is ordered
  by the ENUM rather than by amount, so a colour cannot move up and down the
  chart from month to month and stop meaning one thing.
  **Parity after the chart: 49/117, 49/117, 42/112, 41/108** — theme and
  Calm-token surfaces still pass all four.
- **Two layout defects the parity capture found, which no widget test had:**
  the bars were laid out and measured at 0 x 77 (a `ColoredBox` with no child
  collapses under a `Column`'s default centring, so the capture showed ticks
  under an empty band), and the chart's fixed outer height overflowed by 3 px
  at 1.0x and would have been far worse at 2.0x. A test asserting the boxes
  EXIST passed against both.
- **`structure_test.dart` caught costs importing `historyMonthTitle` from the
  history feature.** A shared helper belongs in `core` or `l10n`; reaching
  across features is how two screens stop being able to change independently.
  The tick uses `formatMonthYear` now.
- **Task 13.5 (complete).** `businessShare` divides by LOGGED TRIP distance,
  never vehicle distance — §12 says elsewhere that trip distances are never
  summed into vehicle distance because people log some trips and not all, so
  using the odometer would understate the share by whatever went unlogged. On
  a tax form that is not a rounding error, and the odometer is the tempting
  mistake precisely because it looks more complete. A commute is NOT business:
  rolling it in is the easiest way to overstate a deduction. No trips returns
  NULL rather than 0, because zero is a claim.
  `buildHousehold` groups per currency and sorts WITHIN a currency — comparing
  30,000 minor EUR against 30,000 minor GBP is the forbidden sum wearing a
  comparison instead of an addition. Ties break by name so the list does not
  flicker between builds.
  §7's one exception is asserted rather than asserted-in-a-comment: the test
  reads `activeVehicleIdProvider` across a toggle and expects it unchanged.
  Five mutations checked.
- **Task 13.6 (complete).** `FuelInsights` composes EPIC-06's engines and adds
  §12's money figures. Every average is TOTAL over TOTAL — the fixture is a
  40 km tank and a 900 km one, where the mean of means reads 13.0 L/100 km
  against a true 6.6, and the test names that number so the failure is
  legible rather than "close to". A segment whose contributing fills mix
  currencies contributes volume and distance but NO money, and is counted so
  the screen can say why a money figure is thinner than the consumption figure
  beside it — the exclusion lives in the core so a second screen cannot forget
  it. `costedFillIds` is exposed precisely so the segment-boundary off-by-one
  is visible: the epic calls it the most common bug in this category, and it
  is invisible in the resulting figure. Four mutations checked, including that
  one.
- **Task 13.7 (built; parity deferred).** `costs.fuel` — headline card, the
  consumption line chart with its dashed average and best/worst markers, and
  §3's "your first figure arrives at your next full fill" where a plot would
  otherwise be blank. The reference draws a LINE, not the columns §12's prose
  suggests; reference wins per rule 4. Consumption renders to ONE decimal
  everywhere: a second invites the reader to compare 6.42 with 6.47 as though
  the difference meant something, and it is noise from a hand-typed odometer
  and a pump that rounds. The chart mirrors its AXIS and not its series, with
  the direction applied in exactly one place — the painter's x mapping.
  **Parity capture deferred to EPIC-18 per CLAUDE.md §6a**, along with the
  fuel-kind selector, price chart, data-quality row and per-tank tooltip.

## Task 13.8 — `trips.list`

Built `lib/core/trips/trip_aggregates.dart`,
`lib/features/trips/application/trips_list_model.dart`, and
`lib/features/trips/presentation/trips_list_screen.dart` + `trip_labels.dart`.
Route wired: `TripsListScreen` replaces the `trips.list` placeholder, and the
`costs` screen's two nav rows — **both of which shipped as `onTap: () {}`** —
now push `costs.fuel` and `trips.list`. A regression test taps the Trips row
and asserts the screen arrives, because every test up to now only checked the
row was drawn.

Three deliberate divergences from §12's prose, all because epics/README.md
rule 4 makes the reference the authority:

1. **Purpose is a word in the meta line, not a chip.** §12 says chips and
   then worries about German ones wrapping; the reference draws
   `1–2 Aug · 145 km · business`, which carries the same information and has
   no wrapping problem to solve. The German case is still tested, on
   `Device.compact`.
2. **The trip count sits at the end edge of the `Earlier` header**, which is
   where the reference puts it (`See all 14`). It is a LABEL and not a link:
   this screen already lists every trip, and §7 forbids a third push in this
   tab for a link to lead to.
3. **`End this trip`, not `Finish`.** The reference and §10 both spell it that
   way; only §12's prose says Finish.

The date range is two short dates joined by an en dash (`Aug 1 – Aug 2`)
rather than the reference's `1–2 Aug` elision. Collapsing a same-month range
needs to know whether the day precedes the month, which `intl` will answer for
a whole date and not for half of one — the elision is right in English and
wrong in four of the six locales.

`tripsListProvider` is a derived `Provider.autoDispose.family`, not a
Notifier: every figure is a pure function of streams Riverpod already keeps
live, and a Notifier would add a load flag, a microtask seam and a second copy
of the data that then needs invalidating by hand on every write.

**Deferred.** The parity capture, per §6a. The Trips and Fuel nav-row
SUBTITLES (`14 trips · 3,120 km · 62% business`, `6.4 L/100 km · €1.734/L`) —
the costs feature cannot import the trips or fuel feature, `structure_test.dart`
enforces that, and the shared seam is a 13.10 decision rather than a fourth
thing to get wrong here.

**Still outstanding for 13.10, and worse than it looks.** Both
`costsRepositoryProvider` and `fuelRepositoryProvider` still throw
`UnimplementedError` in the real app — `costs` and `costs.fuel` are wired to
routes that crash on open outside a test. `trips.list` reads the real stream
providers and does not have this problem. Wiring those two is 13.10's first
job, before any of its own scope.

## Task 13.9 — `trips.edit`

Built `lib/core/trips/trip_draft.dart`, `lib/features/trips/application/
trip_save.dart`, `lib/features/trips/presentation/trips_edit_screen.dart` +
`trip_purpose_control.dart`, and `TripRepository.delete`/`undelete`. The route
now renders the real screen; `trips.edit` was the LAST `PlaceholderScreen` in
the app.

Three things this touched outside the feature, each because the alternative
was a special case:

1. **`stampLogRowDeleted` takes `sources` (a Set), not `source`.** A trip
   emits two readings — `trip_start` and `trip_end` — that differ by source
   alone. Calling the helper twice works for the readings and then reports
   `NotFound` on the second call, because the row itself is already stamped;
   the caller would have to know to ignore that. One `IN (...)` removes the
   case. All four existing call sites pass a one-element set.
2. **`date_field.dart` moved from `features/logging/domain/` to
   `core/time/`.** `trips.edit` is its fifth caller and its first outside the
   logging feature; `structure_test.dart` refuses one feature importing
   another, correctly. The file was already pure Dart with no picker and no
   `BuildContext`, so the lift is a path change and nothing else.
3. **`route_table_test.dart`'s "an id-bearing route reads its id from
   pathParameters" was rewritten.** It read the id back off a
   `PlaceholderScreen`, and there is no placeholder left. It now asserts the
   INVENTORY of id-bearing routes instead, and the id-reading claim is made
   against each real screen — `trips_edit_test.dart` opens the route by a
   concrete id and asserts the trip arrived.

Two decisions worth recording:

- **Add expense is disabled in create mode, with a `CalmButtonExplain`
  underneath.** §10 draws the affordance there, but an expense carries a
  `trip_id` and there is no trip yet. Dropping the button would hide a control
  §10 names; leaving it enabled would open a form that cannot attach what it
  collects. A greyed-out button that says nothing is what `CalmButton` asserts
  against, so it says why.
- **The purpose control's 2×2 grid is keyed on the text scale**, not on the
  locale. §10 names German as the case, but the rule is about width and any
  locale can hit it; keying on `de` would leave Sorani to shrink its text,
  which is the answer §10 rejects.

**Deferred.** The parity capture, per §6a. The `See all 34` cap on the
expenses list (§10's dozens-of-expenses state) — the section shows the
per-currency total and the Add button, and the row list itself is 13.10's
`log.expense`/`log.fillup` edit-mode wiring. The `dialog.confirmDelete`
confirmation before Delete (the row deletes directly today) and the
`dialog.discard` guard on a dirty form; both dialogs exist from EPIC-08 and
need wiring, not building. `End this trip` on `trips.list` opens the editor
rather than revealing the end fields and focusing the odometer.

## Task 13.10 — the estimate sheet and the navigation edges

**First, the bug this task found.** `costsRepositoryProvider` and
`fuelRepositoryProvider` were declared with their notifiers in tasks 13.1 and
13.6 and BOTH threw `UnimplementedError`. `costs` and `costs.fuel` were routes
that crashed on open outside a test, for two tasks, with a full green suite
the whole time — every screen test overrode the provider with a fake. Fixed by
`CostsSource` and `FuelSource`, and by `costs_source_test.dart`, which is the
only test in the tree that puts a real implementation behind a real interface.
The lesson generalises: **a fake behind an interface proves nothing about
whether the interface has an implementation**, and neither the analyzer nor a
widget test can tell.

Built `estimate_explain_sheet.dart` — §12's one sentence and one action, with
a different sentence for each of `CostReason`'s four cases (the table names
three; the engine has always had a fourth, `noReadings`, which is a new
vehicle rather than a stale one). `noCompletedMonth` gets no action, because
updating the odometer does not make the month end sooner and an action that
cannot help is worse than none. The tap target is the whole per-distance LINE,
not the dash: a dash is about 8pt wide.

`costs_navigation_test.dart` asserts the two edges that were dead taps, §7's
two-push depth rule over the route table, and both estimate-sheet rules.

**Deferred to EPIC-15, deliberately.** The overflow **Export costs (CSV)**.
The task's own instruction is "No new export code: this is a second door to
the generator the backup/export epic owns" — and EPIC-15 has not run, so there
is no generator to open a second door to. Building one here is exactly the
fifth export the task forbids. EPIC-15 adds the overflow entry when it builds
the generator; the three tests §12's Interactions table implies
(`costs_export_test.dart`) belong with it.

**Also deferred:** the filtered-history edges (`costs` category row →
filtered `history` in-stack, `costs.fuel` → `log.fillup` in edit mode and →
filtered history) — the history filter API exists but the category rows have
no `onTap` yet, and the stack-reset-on-vehicle-switch rule already has a test
in `stack_reset_test.dart`.
