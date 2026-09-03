# EPIC-12 — History, entry detail and the service report

| | |
|---|---|
| **Epic** | EPIC-12 — History, entry detail and the service report |
| **Depends on** | EPIC-08, EPIC-11 |
| **Estimate** | **12 h (CC) · ~12 weeks (human)** over 11 tasks |
| **Spec sections** | §11 History, timeline, entry detail and search · §12 (`report.service` only) |
| **Screens** | `history`, `report.service` |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end of the epic, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

Two things make this epic harder than "a list screen". First: **history is the only place a
past record can be corrected, and correcting the past silently changes the future** (§11). A
2019 odometer typo moves two fuel segments, every cost-per-distance figure since, the daily
distance rate, the projected odometer, every reminder's projected due date, and therefore what
the OS has scheduled. Every edit path in this epic ends in the recompute contract, and the
snackbar names the consequence rather than saying "Saved". Second: `report.service` is a
document handed to a stranger at the moment of highest stakes. It contains no projections, no
fines, and no private notes unless the seller ticked the box.

---

## Where we are now

The repo today holds `SPEC.md`, the design systems under `design/`, the 112-image Calm
reference set under `design/reference/calm/`, the repo gates in `tools/`, and 47 skills under
`.claude/skills/`. **EPIC-01 created the Flutter app** — before it there was no `pubspec.yaml`
and no `lib/`, and `analysis_options.yaml` and `l10n.yaml` sat inert in the root.

By the time this epic starts, its predecessors have left behind:

| From | What this epic consumes |
|---|---|
| EPIC-01 | `pubspec.yaml` with `very_good_analysis` pinned, a committed `pubspec.lock`, `lib/`, `test/`, a green `flutter analyze --fatal-infos --fatal-warnings`, CI's Flutter lane armed. |
| The Calm design-system epic | `lib/theme/calm/**` (`CalmColors`, `CalmType`, `CalmSpace`, `CalmShapes`, `CalmMotion` as `ThemeExtension`s) and `lib/ui/calm/**` (`CalmScaffold`, `CalmAppBar`, `CalmCard`, `CalmRowGroup`, `CalmListRow`, `CalmChip`, `CalmBadge`, `CalmSwitch`, `CalmButton`, `CalmSheet`, `CalmDialog`, `CalmSnackbar`). Feature code composes these and constructs no `BoxDecoration`. |
| The localisation epic | Six ARB files, `gen_l10n` wired, the numeral and calendar display transforms, the Jalali converter, the FSI/PDI isolate helper, and ICU plural messages. |
| The persistence epic | The Drift store, every table in §3 with `deleted_at`, ULID ids, and DAO `.watch` streams. |
| The domain epic | The pure core in `lib/core/`: `cumulative`, `estimateOdometer`, `dailyDistance`, `buildFuelSegments`, `segmentConsumption`, `averageConsumption`, `consumptionTrend`, `unitPrice`, `resolveAnchor`, `computeDueState`, `projectDueDate`, and the `Money` / unit value objects. All total, all clock-injected. |
| **EPIC-08** | The four-tab shell with a docked **+**, per-tab stacks, the tab-stack reset on vehicle switch and import, and `activeVehicleId`. Tab 2's root is a placeholder today. It also built the three global dialogs of §7 — `dialog.discard`, `dialog.confirmDelete` and `dialog.snooze` — once, in `lib/ui/dialogs/`: §7 makes them global, belonging to no feature, and building one twice is how two copies drift apart. This epic calls them and builds none. |
| **EPIC-11** | The five entry modals — `log.fillup`, `log.service`, `log.expense`, `log.odometer`, `trips.edit` — each with its create path, its validation, its single write path through a repository, and the notification rebuild that follows a save. |

> If those epics landed under different titles, what this epic needs is the *artefact* named in
> the table, not the title. Read `epics/progress/EPIC-11.md` first; anything named here that is
> missing is a gap in an earlier epic, not a licence to build a second copy of it here.

**Deliberately still missing when this epic starts.** Tab 2 shows a placeholder — there is no
timeline, no month index, no filter chips, no search. The `log.*` modals open in **create**
mode only: EPIC-11 built the forms, not the edit path, so nothing in the app can yet open a
record that already exists. There is no `report.service` route, no PDF writer, no share port,
and no vehicle-wide recompute — EPIC-11 recomputes a vehicle's due states after its own saves,
but nothing yet recomputes after an *edit to the past*, because until this epic there was no
way to edit the past. `costs` and `costs.fuel` do not exist; EPIC-13 builds them and pushes a
filtered instance of *this* screen into its own stack, so the filter API this epic writes is a
public contract, not an internal detail.

---

## What we will have when this is done

- Tab 2 opens on **History**: one reverse-chronological list of every fill-up, service,
  expense, trip, manual odometer reading and odometer-correction divider for the active
  vehicle, grouped under sticky month headers that read `September 2026`, `septembre 2026` and
  `مهر ۱۴۰۴` — and break at ~23 September for a Jalali user, not on the 1st.
- Each header carries its entry count and a subtotal that is **grouped per currency**
  (`9 entries · € 412.80 · £ 30.00`), and the subtotal does not change as you scroll.
- The chip row filters by type, year, expense category and "needs attention"; the year
  scrubber appears above 150 rows and the `⌕` above 200. Scrolling 2,800 rows never holds more
  than 400 in memory, and jumping to 2019 discards the window rather than growing it.
- Tapping a row opens the record's own `log.*` modal, prefilled, segment selector hidden, with
  a read-only context band above the fields that says what the form cannot — *"6.1 L/100 km
  over 854 km since 18 Aug"*.
- Correcting a 2019 fill-up's odometer changes every consumption figure after it, on the next
  frame, and the snackbar says so: *"Fill-up updated · 14 later fuel figures recalculated"* ·
  **Undo**. Deleting a service says which reminders go back to being due.
- **Report** in the app bar pushes `report.service`: a header card, four include toggles, and
  a live preview that *is* the document. **Share PDF** hands a multi-page A4 (US Letter in
  US/CA/MX/PH) file to the OS share sheet, named
  `odova-service-history-golf-2026-09-02.pdf`; **Copy as text** puts the same content on the
  clipboard for a classifieds listing.
- `flutter test test/parity/history_parity_test.dart` and
  `test/parity/report_service_parity_test.dart` write eight PNGs, and
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over all eight.

What we deliberately will **not** have: a read-only entry-detail screen (§7 — "a detail page
you must tap Edit on is ceremony for zero information"), multi-select or bulk delete, a
deleted-items bin, fuzzy or ranked search, a persisted search index, highlighted match
substrings, pull-to-refresh, and an in-app PDF viewer.

---

## Skills to load

Open `flutter-conventions-index` first; it routes everything else.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door: feature-first layers, one `Notifier` per screen, the single write path, injected `Clock`. Every task inherits it. |
| `calm-visual-parity` | `history` and `report.service` each have four reference images and all four are gates. Read it before Task 12.5 — it says what the check proves and what it cannot. |
| `calm-components` | The timeline is `CalmRowGroup` + `CalmListRow`, the chips are `CalmChip`, the flag badges are `CalmBadge`, the report toggles are `CalmSwitch`. A lone row or a hand-rolled `BoxDecoration` is a bug. |
| `persistence-drift` | Keyset pagination, the month-index aggregate query, `LIKE` over a normalised expression, and `.watch` streams that re-emit after a write. |
| `flutter-performance` | 120 ms first page over 5,000 rows, a 400-row window, and a recompute that runs off the UI thread above 16 ms while holding previous values on screen. |
| `i18n-rtl-l10n` | Month grouping in the display calendar, ICU plurals for the entry count, the year scrubber on the **end** edge, `endActions` swipe, and search folding across Arabic-script forms and digit systems. |
| `calm-typography-and-rtl` | Amounts and consumption figures as atomic isolate-wrapped runs, first-strong direction on free-text vendor and station names, and the RTL rules the report document inherits. |
| `ui-states-and-feedback` | Nine documented states for `history` plus the snackbar-with-Undo that names the consequence, and the inline error under **Share PDF** rather than a dialog. |
| `service-boundary-and-native` | The PDF canvas and the OS share sheet are platform effects; both sit behind Dart interfaces overridden at the composition root and faked in tests. |

---

## Tasks

### Task 12.1 — The timeline query: five row types, keyset order, one page

- **Goal** — One repository call returns a page of the vehicle's timeline in the exact order
  §11 specifies, resuming without duplicating or skipping a row.
- **Spec** — §11 *History → Pagination*, *Data in / data out*; §3 *Identity, timestamps,
  deletion*.
- **Skills** — `persistence-drift`, `flutter-conventions-index`, `error-handling-typed-results`.
- **Write these tests first** — `test/data/history_repository_test.dart`, against an in-memory
  Drift store seeded from `test/support/history_fixture.dart`:
  - `orders by occurred_on then created_at then id, all descending` — two fills on the same
    day at the same station; asserts the ULID tiebreak puts the same one first on two
    successive calls.
  - `a 60-row page plus its cursor yields 130 distinct ids in order over three calls` — fails
    if anyone reaches for `LIMIT/OFFSET`, which renumbers the moment a backdated 2019 row is
    saved.
  - `derived odometer readings get no row` — a fill emits a `source: fillup` reading; the page
    contains the fill and no odometer row. A manual reading does get one.
  - `rows with deleted_at set are absent from every page`.
  - `OdometerCorrection rows appear as a divider entry at their from_reading position`.
  - `a page is scoped to one vehicle` — a second vehicle's rows never leak in.
  - `pageAnchoredAt(monthKey) returns rows from that month down and nothing newer`.
- **Then build** — `lib/core/history/history_entry.dart`: a sealed `HistoryEntry` with
  `FillUpEntry`, `ServiceEntry`, `ExpenseEntry`, `TripEntry`, `OdometerEntry`,
  `CorrectionDividerEntry`, each carrying its source row and `occurred_on`/`created_at`/`id`
  sort key. `lib/core/history/history_cursor.dart`: `HistoryCursor` as the
  `(occurredOn, createdAt, id)` triple. `lib/data/history_repository.dart`:
  `HistoryRepository.page({required String vehicleId, required HistoryFilter filter,
  HistoryCursor? after, int limit = 60})` and `pageAnchoredAt(...)`, both returning
  `Result<HistoryPage, StoreFailure>`. The union query lives in the DAO, not in Dart.
- **Verify** — `flutter test test/data/history_repository_test.dart`; then
  `flutter analyze --fatal-infos --fatal-warnings`. A pass is seven green tests and no
  `OFFSET` anywhere: `grep -rn "OFFSET" lib/` returns nothing.
- **Done when**
  - [ ] Every page is keyset-anchored; no offset query exists in `lib/`.
  - [ ] Deleted rows and derived odometer readings are excluded by the query, not by the UI.
  - [ ] The repository returns a typed `Result`, never throws.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.2 — The month index

- **Goal** — Month headers, the year scrubber and the "no entries in 2021" empty state are all
  driven by one aggregate query that never loads an entry row.
- **Spec** — §11 *Grouping and month headers*; §5 *Calendars and dates*.
- **Skills** — `persistence-drift`, `i18n-rtl-l10n`, `value-objects-money-and-units`.
- **Write these tests first** — `test/core/history/month_index_test.dart` and
  `test/data/history_repository_month_index_test.dart`:
  - `groups by the display calendar, not the Gregorian month` — with `calendar: persian`, a
    record on 2026-09-22 and one on 2026-09-24 land in **different** month keys (Shahrivar and
    Mehr); with `calendar: gregorian` they land in the same one.
  - `the index is keyed by (calendar, year, month) and rebuilt when the calendar setting
    changes` — asserts the cached index is discarded, not remapped.
  - `totals group per currency and are never summed across them` — a month with €412.80 and
    £30.00 returns a two-entry map, not 442.80.
  - `trips contribute no money to a month total` — their costs are the fills and expenses
    already counted.
  - `an expense is counted in the month it was paid` — history is cash, not accrual; the
    accrual spread belongs to EPIC-13 and must not leak here.
  - `months with no entries are absent from the index`.
  - `the subtotal for the bottom month is identical with 60 rows loaded and with 400` — the
    regression guard against folding totals out of the loaded window.
- **Then build** — `lib/core/history/month_index.dart`: `MonthKey(calendar, year, month)`,
  `MonthIndexEntry({monthKey, count, totals: Map<String,int>, firstKey, lastKey})`, and the
  filter-aware `HistoryRepository.monthIndex(vehicleId, filter)`. Memoise per
  `(vehicleId, filter, calendar)`; invalidate on any write to the vehicle.
- **Verify** — `flutter test test/core/history/month_index_test.dart
  test/data/history_repository_month_index_test.dart`. A pass is seven green tests; ~96 index
  rows for eight years, asserted by a fixture that seeds 2,800 entries and checks the index
  query touches no entry row.
- **Done when**
  - [ ] Headers, scrubber and empty state all read the index, and none of them reads the
        loaded window.
  - [ ] Jalali month boundaries are asserted by test, not by inspection.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.3 — The row model and its flag badges

- **Goal** — One row widget's data model for all six entry types, including the four flag
  badges, with a blank consumption slot where no figure exists — never `0.0`.
- **Spec** — §11 *Layout* (the type table and the badge table); §3 *Fuel maths*.
- **Skills** — `dart3-idioms-and-coding-standards`, `calm-due-state-and-status`,
  `value-objects-money-and-units`.
- **Write these tests first** — `test/core/history/history_row_test.dart`:
  - `a fill-up shows a consumption figure only where buildFuelSegments closed a segment at
    that fill` — a mid-chain full fill shows 6.1; the opening fill of the chain shows nothing.
  - `a partial fill shows the partial badge, the word partial, and no consumption figure`.
  - `never renders 0.0 in the consumption slot` — property test over a generated fixture of
    500 fills including discarded segments; the slot is null or a real figure.
  - `a chain-broken fill carries the chain-break badge`.
  - `a fill that discarded its segment carries the warning badge` — same odometer as its
    neighbour, negative distance, or implausible volume.
  - `an estimated odometer renders with a leading ~ and the projected badge`.
  - `a service row joins at most two line labels with · then +2 more`.
  - `an expense of category other falls back to its label; an expense with a coverage window
    shows 1 Jan – 31 Dec 2026 as its secondary line`.
  - `a duplicate is flagged at same date, odometer within 1 km, volume within 0.1 L` — and
    not at 1.1 km or 0.2 L.
  - `a trip with no title falls back to its date range`.
- **Then build** — `lib/core/history/history_row.dart`: `HistoryRow` with `icon`,
  `primaryLine`, `secondaryLine`, `amount: Money?`, `trailingFigure: String?`,
  `badges: Set<HistoryFlag>`; and `HistoryRowMapper` mapping a `HistoryEntry` plus the
  vehicle's segments to it. Pure, no widget, no `BuildContext`.
- **Verify** — `flutter test test/core/history/history_row_test.dart`. A pass is ten green
  tests including the property test at 500 cases.
- **Done when**
  - [ ] The mapper is pure and takes `today` from an injected clock.
  - [ ] Every badge in §11's table has a test that produces it and one that does not.
- **Estimate** — 0.5 h (CC) · ~half a week (human)

### Task 12.4 — The notifier: filters, the 400-row window, and the jump

- **Goal** — The screen's state: filter chips composing OR-within/AND-across, keyset prefetch,
  a memory window that stays flat, and a jump that discards it.
- **Spec** — §11 *Filters*, *Pagination*, *Interactions*; §7 *Tab bar* (stack resets).
- **Skills** — `state-management-riverpod`, `flutter-performance`, `async-safety`.
- **Write these tests first** — `test/features/history/history_notifier_test.dart`, with a fake
  `HistoryRepository` over `ProviderContainer.test()`:
  - `type values are OR within the chip and AND across chips` — Fuel + 2024 returns fills in
    2024 only.
  - `the category chip exists only while type is Expense` — switching type to Fuel clears the
    category selection rather than leaving it applied invisibly.
  - `the needs-attention chip is hidden when the flag count is zero, and carries the count
    otherwise`.
  - `filter state is per provider instance` — two containers, two filter states; this is what
    makes EPIC-13's pushed instance possible.
  - `switching the active vehicle resets the filter state; so does an import`.
  - `the window caps at 400 rows and drops from the far end` — page nine times, assert 400.
  - `jumping to a month discards the loaded window and reloads from that anchor` — assert the
    state holds one page, not 460 rows.
  - `prefetch fires once when the last rendered row is within 20 of the tail, and not twice
    for the same tail`.
  - `a page load longer than a frame keeps the previous rows in state` — never an empty list
    under a spinner.
- **Then build** — `lib/core/history/history_filter.dart`: immutable `HistoryFilter`
  (`type`, `year`, `categories`, `needsAttention`, `query`) with value equality and a
  `HistoryFilter.preset(...)` constructor EPIC-13 calls. `lib/features/history/
  history_notifier.dart`: `HistoryNotifier extends AsyncNotifier<HistoryState>` with
  `applyFilter`, `loadMore`, `jumpTo(MonthKey)`, `enterSearch`, `exitSearch`; the provider is
  a `family` on `HistoryScope` so the tab-2 instance and the Costs-stack instance are distinct.
- **Verify** — `flutter test test/features/history/history_notifier_test.dart`. A pass is nine
  green tests. Then `flutter analyze --fatal-infos --fatal-warnings`.
- **Done when**
  - [ ] Two instances of the provider hold independent filter state.
  - [ ] Memory is flat at 40 records or 4,000, asserted by the window test.
  - [ ] No fire-and-forget `Future`; every load is awaited or explicitly handled.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.5 — Build the `history` screen

- **Goal** — Tab 2 becomes the real timeline, matching its reference in all four combinations,
  with all nine of §11's states reachable.
- **Spec** — §11 *Layout*, *States*, *Interactions*, *RTL and localisation*.
- **Skills** — `calm-visual-parity`, `calm-components`, `calm-typography-and-rtl`,
  `ui-states-and-feedback`, `widget-composition`, `adaptive-layout`.
- **Write these tests first** — `test/features/history/history_screen_test.dart`:
  - `sticky month header shows the count and the per-currency subtotal` — asserts two currency
    runs, not a sum.
  - `the amount column is end-aligned and fixed width so digits stack` — asserts equal x for
    two amounts of different lengths, in both directions.
  - `the year scrubber sits on the end edge and appears only above 150 rows`.
  - `the search affordance appears only above 200 rows`.
  - `swipe reveals Delete as endActions and the physical direction flips under RTL`.
  - `tapping a month header collapses it, and the collapse does not survive a rebuild from a
    new page`.
  - `empty, new vehicle shows "Nothing logged yet." with a Log a fill-up button and no
    illustration`.
  - `filtered to nothing keeps the chip row visible and interactive` — the "never strand the
    user in a filter they can't see" rule.
  - `an unreadable row renders the warning row with Export a backup and is never hidden`.
  - `a store read failure shows the full-screen Go to Backup & restore state`.
  - `an archived vehicle is fully editable with the muted "Sold on 14 Mar 2026" line`.
  - `no row builds a BoxDecoration` — the hygiene assertion; rows are `CalmListRow` inside
    `CalmRowGroup`.
  - Then `test/parity/history_parity_test.dart`: four cases, `history-light-ltr`,
    `history-dark-ltr`, `history-light-rtl` (`Locale('fa')`, `TextDirection.rtl`),
    `history-dark-rtl`, each pinning `tester.view.physicalSize = Size(780, 1688)`,
    `devicePixelRatio = 2.0`, `ThemeMode` explicitly, `textScaler` 1.0, reduced motion on, and
    `addTearDown(tester.view.reset)`.
- **Then build** — `lib/features/history/presentation/history_screen.dart`
  (`HistoryScreen extends ConsumerWidget`), `history_row_tile.dart`
  (`HistoryRowTile`), `history_month_header.dart`, `history_filter_chips.dart`,
  `history_year_scrubber.dart`, `history_empty_states.dart`. All `const` widget classes; no
  `_buildX()` methods; every user string from the ARBs, including
  `history.monthEntryCount` as an ICU plural.
- **Verify**
  ```bash
  flutter test test/features/history/history_screen_test.dart
  flutter test test/parity/history_parity_test.dart      # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/history-light-ltr.png history \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/history-light-ltr.png    # look at the side-by-side
  ```
  A pass is: theme ok, every surface over 0.5% within Δ24 of a Calm token, and ≥75% of the
  reference band edges matched within 4px. The differing-pixel percentage the tool prints is
  **informational and will read 25–45% on a correct screen** — do not chase it, and do not
  widen `--token-tolerance` to make a combination pass.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] All nine states in §11's table are reachable in a widget test.
  - [ ] The RTL captures were reviewed by someone who reads the script, not only by the tool.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 12.6 — Search inside `history`

- **Goal** — The `⌕` turns the app bar into a field that finds "that garage in Ingolstadt",
  composing with the chips, with no index and no ranking.
- **Spec** — §11 *Search inside `history`*.
- **Skills** — `persistence-drift`, `i18n-rtl-l10n`, `calm-typography-and-rtl`.
- **Write these tests first** — `test/core/history/search_normalise_test.dart`:
  - `NFKC, case folding and combining-mark stripping make Süd match sud`.
  - `Arabic-script folding unifies أ إ آ ٱ to ا, ى to ي, ة to ه, ک/ك and ی/ي/ے, and removes
    tatweel and harakat`.
  - `digit folding maps ۱۲۳ and ١٢٣ to 123, so a Persian query finds a Latin invoice ref`.
  - `normalisation is applied to both sides` — the stored column expression and the query.
  Then `test/data/history_repository_search_test.dart`:
  - `matches across every field in the §11 list and no others` — notably not a category enum
    name and not a vehicle name.
  - `search composes with the chips as AND` — Fuel · 2024 · shell.
  - `under two characters returns the unfiltered list`.
  - `results keep reverse-chronological order and month grouping` — no ranking.
  And `test/features/history/history_search_test.dart`:
  - `entering search replaces the app bar title in place, with no route change` — assert the
    navigator stack depth is unchanged.
  - `system back and ✕ exit search and restore the previous filter state`.
  - `no match shows Nothing matches "shell" with a Clear search button`.
  - `matched substrings are not highlighted` — highlighting inside bidi isolates mangles
    exactly the locales we care about.
- **Then build** — `lib/core/history/search_normalise.dart` (`normaliseForSearch`), the
  normalised `LIKE` expression in the DAO, and search mode in `HistoryNotifier` +
  `history_screen.dart` with a 200 ms debounce and a 2-character minimum.
- **Verify** — `flutter test test/core/history/search_normalise_test.dart
  test/data/history_repository_search_test.dart test/features/history/history_search_test.dart`.
  A pass is twelve green tests and `grep -rn "search_blob" lib/` returning nothing — search is
  a query, and a stale index surviving a Replace import would be a nasty bug.
- **Done when**
  - [ ] No persisted index, no fuzzy matching, no saved searches.
  - [ ] The field takes first-strong direction from its content.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.7 — Entry detail: `log.*` in edit mode and the context band

- **Goal** — Tapping a row opens the form that created it, prefilled, segment selector hidden,
  with the three read-only lines that were the reason the user opened the row.
- **Spec** — §11 *Entry detail — `log.*` in edit mode*; §10 (the forms themselves, unchanged).
- **Skills** — `widget-composition`, `navigation-and-routing`, `calm-components`.
- **Write these tests first** — `test/features/log/entry_context_band_test.dart`:
  - `a fill-up band shows the segment figure with its distance and dates, and the unit price
    to 3 decimals`.
  - `a fill-up with no figure shows the reason, one sentence` — the three cases: first fill,
    chain broken, partial fill. Asserts the exact ARB keys, not English literals.
  - `a service band names the reminders this record resets and their resulting next-due`.
  - `a service band with an estimated odometer puts "Odometer estimated from your driving —
    tap to correct" first`.
  - `an expense band shows the coverage window and the monthly share` — € 480.00 over 12
    months = € 40.00 a month.
  - `an odometer band shows distance, days and the implied rate`.
  - `a trip band groups attached costs per currency with a count`.
  And `test/features/log/log_edit_mode_test.dart`:
  - `opening a row hides the segment selector` — an entry cannot change type.
  - `Delete sits at the bottom of the form, destructive-styled, and never in the app bar
    beside Save`.
  - `dismissing a dirty edit opens dialog.discard; dismissing a clean one is silent`.
- **Then build** — `lib/features/log/presentation/entry_context_band.dart`
  (`EntryContextBand`, one `const` widget class per type behind a sealed `BandContent` the
  pure core computes), edit-mode wiring in the existing `log.*` routes from EPIC-11, and the
  bottom `Delete this fill-up` row.
- **Verify** — `flutter test test/features/log/`. A pass is ten green tests. The `log.*`
  reference images belong to EPIC-11; this task changes those screens, so re-run
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` over
  `build/parity/log.fillup-*.png` and confirm the band did not break the band profile of a
  screen someone else already gated.
- **Done when**
  - [ ] No read-only detail screen was created.
  - [ ] Every band line comes from the pure core; the widget formats nothing.
  - [ ] The four `log.*` parity gates are still green after the band lands.
- **Estimate** — 0.5 h (CC) · ~half a week (human)

### Task 12.8 — The recompute contract

- **Goal** — Every write, delete, restore and undo from history invalidates the whole vehicle
  and recomputes in dependency order, and the notification schedule follows.
- **Spec** — §11 *Editing the past: the recompute contract*; §3 *Derived values*; §4 (the
  schedule rebuild).
- **Skills** — `state-management-riverpod`, `flutter-performance`, `async-safety`,
  `error-handling-typed-results`.
- **Write these tests first** — `test/core/recompute/vehicle_recompute_test.dart`:
  - `correcting a 2019 fill-up from 89,204 to 98,204 km changes two segments and every
    cost-per-distance figure after it` — the worked example from §11, asserted end to end.
  - `recompute runs in dependency order` — a recording fake asserts the sequence: odometer
    series → cumulative → dailyDistance → estimateOdometer → buildFuelSegments per fuel_kind →
    resolveAnchor → computeDueState → projectDueDate → monthIndex and the cost aggregates.
  - `the whole vehicle's derived cache is dropped, not a subgraph` — asserts no partial
    invalidation path exists.
  - `only the edited vehicle is invalidated` — a second vehicle's memoised values survive.
  - `a due state whose status, due_on or due_at_odometer_m changed rebuilds that vehicle's
    notification schedule; an unchanged one does not`.
  - `5,000 rows recompute under 150 ms` — a budget test, skipped on CI only if it proves flaky,
    never deleted.
  - `above 16 ms the work runs off the UI thread and the previous values stay on screen` —
    asserts no spinner frame over existing rows.
  And `test/features/history/history_snackbar_test.dart`:
  - `each of the five §11 snackbar cases produces its exact message` — including "Saved" when
    nothing derived changed, and the plural count in "14 later fuel figures recalculated".
  - `Undo re-applies the pre-write snapshot and re-runs the same pipeline`.
  - `Undo dies at 6 seconds or on the next navigation, whichever comes first`.
- **Then build** — `lib/core/recompute/vehicle_recompute.dart`
  (`recomputeVehicle(VehicleId, {required RecomputeSnapshot before})` returning a
  `RecomputeDiff` naming what changed), the `onWrite | onDelete | onRestore` hook in the
  repositories, and `lib/features/history/presentation/recompute_snackbar.dart` mapping the
  diff to its message. The diff is what makes the snackbar honest — the message is derived
  from what actually changed, never from what was edited.
- **Verify** — `flutter test test/core/recompute/ test/features/history/history_snackbar_test.dart`.
  A pass is ten green tests including the 150 ms budget.
- **Done when**
  - [ ] Nothing derived is written to storage at any point.
  - [ ] The snackbar's count comes from the diff, not from a guess.
  - [ ] The notification rebuild is driven by the diff, not fired unconditionally.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.9 — Two-sided monotonicity, delete guards and wiring `dialog.confirmDelete`

- **Goal** — An edited reading is checked against neighbours on **both** sides, and every
  delete dialog names what dies and what it takes with it.
- **Spec** — §11 *Monotonicity on an edit*, *What a delete takes with it*, *Delete is
  immediate*; §3 *The odometer: continuity and corrections*, *Identity, timestamps, deletion*.
- **Skills** — `error-handling-typed-results`, `ui-states-and-feedback`, `forms-and-input`.
- **Write these tests first** — `test/core/odometer/edit_monotonicity_test.dart`:
  - `a reading that fits between both neighbours saves silently`.
  - `breaking against the earlier neighbour on the newest reading opens the three-way
    dialogue` — the same one new entries use, unchanged.
  - `breaking against a later neighbour offers only Fix the number and Cancel, with the exact
    error naming the later reading's date and value`.
  - `a reading that is from_reading_id of a correction blocks both delete and odometer edit,
    with the "Delete the correction first" message`.
  - `deleting a correction from its divider row re-runs the vehicle recompute and may re-expose
    a monotonicity violation` — asserts the violation surfaces rather than being swallowed.
  And `test/features/history/confirm_delete_test.dart` — this epic's own behavioural tests over
  EPIC-08's dialog as history calls it:
  - `each of the five §11 delete bodies renders for its case` — mid-chain fill, chain-opening
    fill, service that reset reminders, trip with attached costs, standalone reading.
  - `deleting the vehicle's only odometer reading is blocked outright` — "Every car needs one."
  - `deleting a trip does not delete its expenses` — they lose the trip link and stay.
  - `delete stamps deleted_at, Undo clears it, and the row is purged when the snackbar
    expires` (§3) — and a purge sweep on next launch catches a row whose snackbar never
    expired because the app was killed.
- **Then build** — `lib/core/odometer/edit_monotonicity.dart` (two-sided `checkEdit`
  returning a sealed `EditVerdict`), the delete guards in the repositories, the five §11
  delete bodies passed as ARB messages into **EPIC-08 task 8.9's `showConfirmDeleteDialog`**,
  and the startup purge sweep in `bootstrap()`. This task **wires** that dialog; it does not
  build one, and the widget's parity gates stay EPIC-08's.
- **Verify** — `flutter test test/core/odometer/edit_monotonicity_test.dart
  test/features/history/confirm_delete_test.dart`. A pass is twelve green tests. The
  `dialog.confirmDelete` widget and its four reference images belong to EPIC-08; nothing in
  this task may change its layout.
- **Done when**
  - [ ] A correction can only start at the newest reading; mid-history insertions are refused
        with the exact §11 message.
  - [ ] No screen lists deleted rows and there is no bin.
  - [ ] A killed app cannot leave a soft-deleted row behind.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 12.10 — `report.service`: the document model and the live preview

- **Goal** — The Report action pushes a screen whose preview *is* the document, with four
  toggles that change it live, matching its reference in all four combinations.
- **Spec** — §12 *`report.service` — Service report* (What the document contains, States, RTL
  and localisation).
- **Skills** — `calm-visual-parity`, `calm-components`, `calm-typography-and-rtl`,
  `ui-states-and-feedback`, `widget-composition`.
- **Write these tests first** — `test/core/report/service_report_test.dart`:
  - `the header uses the latest entered reading and its date, never a projection` — with a
    stale odometer, asserts `187,412 km (read 14 Jun 2026)` and no `~` on the header figure.
  - `ownership span ends at sold_on for a sold vehicle`.
  - `maintenance at a glance lists every ServiceItem with at least one completion, and lists
    the rest under "No record in this app"` — an absent row reads as a hidden row.
  - `full history groups by year with the year subtotal in the heading, and drops the subtotal
    when Costs is off`.
  - `a record with odometer_estimated carries ~ and produces exactly one footnote`.
  - `fines, parking, tolls, washes, fuel receipts, insurance premiums and trip logs never
    appear` — a property test over a fixture containing all of them.
  - `plate, VIN and notes appear only when their toggle is on; both default off`.
  - `the footer is present in every configuration` — it is unremovable.
  - `mixed currencies group and never sum`.
  And `test/features/report/report_service_screen_test.dart`:
  - `toggling Costs off removes the summary line and every year subtotal in the same frame`.
  - `with no service records the header card still renders, the preview is replaced by the
    "gets valuable the moment you start adding them" copy, and Share PDF is disabled with its
    reason under it, not in a toast`.
  - `over 200 records the preview is virtualised` — asserts the built row count.
  - `the Report action is absent from the filtered history instance` (§11) — a report from a
    slice would silently omit half the jobs.
  Then `test/parity/report_service_parity_test.dart`: the four combinations, same pinning as
  Task 12.5.
- **Then build** — `lib/core/report/service_report.dart`
  (`ServiceReportDocument`, `ServiceReportOptions`, `buildServiceReport(...)` — pure, taking
  `today` from the clock), `lib/features/report/presentation/report_service_screen.dart` and
  its row widgets, and the app-bar **Report** action on `history` (tab-2 stack only).
- **Verify**
  ```bash
  flutter test test/core/report/ test/features/report/
  flutter test test/parity/report_service_parity_test.dart   # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/report.service-light-ltr.png report.service \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/report.service-light-ltr.png   # look at the side-by-side
  ```
  Same reading of the output as Task 12.5: theme, tokens and band edges gate; the pixel
  percentage does not.
- **Done when**
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
  - [ ] The document model is pure and has no `BuildContext`; the screen renders it.
  - [ ] Nothing in §12's "Never in the document" list can reach the preview.
- **Estimate** — 2 h (CC) · ~2 weeks (human)

### Task 12.11 — PDF production, paper size, share and Copy as text

- **Goal** — **Share PDF** hands a multi-page, correctly-papered, font-embedded file to the OS
  share sheet, and **Copy as text** puts the same content on the clipboard.
- **Spec** — §12 *Production and sharing*, *States* (generation and share errors).
- **Skills** — `service-boundary-and-native`, `data-export-and-restore`,
  `error-handling-typed-results`, `calm-typography-and-rtl`.
- **Write these tests first** — `test/core/report/service_report_pdf_test.dart`, against a
  fake `PdfCanvas` port:
  - `paper is A4, and US Letter for regions US, CA, MX and PH` — from the resolved region, and
    the overflow override wins over both.
  - `the table header repeats on every page and the footer carries "Page 2 of 4"`.
  - `34 services produce 2–3 pages; 200 produce about 12`.
  - `an Arabic-script locale embeds the Vazirmatn subset rather than referencing it` — the
    file must render on a stranger's phone.
  - `the document mirrors in fa: page direction RTL, date column at the right edge`.
  - `VIN is forced LTR and start-aligned even on an RTL page, and a plate is never
    digit-shaped in either direction`.
  - `the footer generation date carries the ISO Gregorian date in brackets alongside the
    display date`.
  - `the filename is ASCII: odova-service-history-golf-2026-09-02.pdf` — plus the positional
    fallback `odova-service-history-vehicle-2-2026-09-02.pdf` when the name transliterates to
    nothing.
  And `test/features/report/report_share_test.dart`:
  - `the file is written to a temp path and handed to the share port; the app never picks a
    destination, asks for storage permission, or remembers where it went`.
  - `over 200 records generation shows a blocking "Building your report…" with a Cancel;
    under 200 it is synchronous`.
  - `Cancel abandons generation and deletes the temp file`.
  - `a generation or share failure renders inline under the button with Try again, never a
    dialog`.
  - `Copy as text puts the same content on the clipboard as plain text`.
- **Then build** — `lib/services/pdf/pdf_canvas.dart` (the port) with its platform
  implementation, `lib/core/report/service_report_pdf.dart` and `service_report_text.dart`
  (both pure over the port and the document), `lib/services/share/share_service.dart`, and the
  overflow menu with **Copy as text** and **Paper size** — nothing else.
- **Verify** — `flutter test test/core/report/service_report_pdf_test.dart
  test/features/report/report_share_test.dart`; then, on a device,
  `flutter run --release`, generate the report in `fa` and open the PDF in a viewer that has
  no Persian font installed to prove the subset embedded. A pass is thirteen green tests and a
  file that renders on a stranger's phone.
- **Done when**
  - [ ] The PDF canvas and the share sheet are behind injected interfaces, faked in tests.
  - [ ] No network dependency was added — check `bash tools/audit_deps.sh` is still green.
  - [ ] The temp file is cleaned up on cancel and on failure.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] Tab 2 shows the real timeline for the active vehicle, with month grouping in the display
      calendar and per-currency subtotals from the month index.
- [ ] Filters, the year scrubber and search behave as §11 specifies, and the filter API is
      usable by EPIC-13's pushed instance.
- [ ] A page never loads more than 400 rows into memory, and a jump discards the window.
- [ ] Tapping a row opens its own `log.*` modal in edit mode with the context band; there is no
      read-only detail screen.
- [ ] Editing or deleting a past record recomputes the whole vehicle in dependency order,
      rebuilds the notification schedule only where a due state changed, and shows a snackbar
      that names the consequence with a working Undo.
- [ ] `report.service` renders the document live, shares a correctly-papered PDF, and copies
      the same content as text.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

---

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-12.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
