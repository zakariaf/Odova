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
