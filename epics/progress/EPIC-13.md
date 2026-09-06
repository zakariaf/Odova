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
