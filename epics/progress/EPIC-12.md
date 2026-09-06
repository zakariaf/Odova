
- **Gate repair (Task 12.6 fallout).** `check_gates_selftest.sh` had been red
  since 12.6 and I had not run it. One line — `Duration(milliseconds:
  kSearchDebounceMs)` in the notifier — failed seven of its arms across
  `check_raw_values` and `check_touch_targets`. `CalmMotion` gains
  `searchDebounce`, joining `undoWindow` and `skeletonDelay`, which are not
  animations either; `kSearchDebounceMs` is retired from core rather than kept
  as a second copy. Lesson for the rest of the epic: run the self-test per
  task, not per epic.
- **Task 12.8 (part 1 of 2).** `runRecompute` pins §11's ordering — snapshot
  before the write, invalidate between the write and the after-snapshot — and
  both orderings are mutation-verified. `takeRecomputeSnapshot` composes
  EPIC-06's `buildFuelSegmentsByKind` and EPIC-07's `recomputeVehicle` rather
  than growing a third pipeline. **Departure from the task text:** no recording
  fake for the dependency order — the stages are pure top-level functions and a
  fake would assert my composition order against itself. The order is pinned by
  consequence, with both arms. **Measured:** 5,000 rows recompute in **3.6 ms**
  against §11's 150 ms budget, so the "invalidate the whole vehicle" decision
  costs nothing and the >16 ms off-thread path is never entered on realistic
  data. Remaining in 12.8: Undo's six-second life and the next-navigation
  cancel.
- **Task 12.8 (complete).** `UndoWindow` owns §11's "6 seconds, or the next
  navigation" — the second clause is the one that gets dropped, so its test
  asserts at one second, before the window could expire on its own. Three
  guards mutation-verified. `fake_async` promoted to a declared dev dependency
  (pure Dart, audit clean); without it a six-second and a ten-second window
  cost sixteen real seconds of every suite run, so the tests get deleted and
  nothing asserts the window closes.
- **Task 12.9 (complete).** `checkEdit` is two-sided and its two directions get
  DIFFERENT answers — down-against-earlier on the newest reading opens §11's
  three-way dialogue, down-against-earlier mid-history is refused, and
  up-past-later is refused naming the nearest collision. Four mutations caught.
  `_softWarnings` published as `softOdometerWarnings` rather than copied.
  Thirteen ARB keys × six locales for the five delete bodies and the two
  blocks; `listSeparator`/`listPairJoin` added because §2 forbids joining
  "Oil and filter" to "Inspection" with a Dart `' and '`. `sweepDeletedOnStartup`
  wired unawaited into `bootstrap()` — the gap §3 had, since every soft-delete
  was purged only by a timer that dies with the process.
- **Task 12.10 (model).** `buildServiceReport` is pure and Flutter-free — the
  preview IS the document, so one model feeds the screen, the PDF and the
  clipboard. §12's exclusion list is enforced by CONSTRUCTION (no parameter a
  fine could arrive through), not by a filter. Header reads `ReadingSeries`
  directly so a stale vehicle prints June's entered figure, never a projection.
  Five mutations checked; one initially SURVIVED because my fixture used
  single-line records, so "count services" and "count lines" agreed — fixed.
- **Task 12.11 (pure half).** Paper (four regions, not a continent), the ASCII
  filename with the positional fallback every RTL name needs, pagination pinned
  to §12's own 34→3 and 200→12 figures, and the clipboard renderer.
  `check_status_encoding.sh` caught me concatenating `~` in Dart again — the
  estimated flag now goes into the injected formatter. A `trimRight` no test
  could distinguish was deleted rather than kept.
- **Deferred to a follow-up within this epic:** 12.10's `report_service_screen`
  and its four-way parity run; 12.11's `PdfCanvas` port, platform
  implementation, share service and the `report_share_test` widget cases. The
  pure logic all three rest on is built and gated.
- **Task 12.10 (screen).** `report.service` built against the REFERENCE, not
  §12's ASCII sketch — the toggles are chips and the header is the inverse
  card. The parity pass found four defects no unit test would have: a tofu box
  where `→` should be (not in the bundled fonts; moved into an ARB so
  `font_coverage_test` could refuse it, now an en dash), a divider one pixel
  wide inside a start-aligned Column, all three header rows at headline size
  when `.kv__v` is body-semibold, and a preview building all 400 rows.
  **Parity: theme and Calm-token surfaces PASS all four; band profile 55/107,
  52/107, 39/101, 39/99 — ~51% against a 75% floor.** Nothing widened, no
  reference regenerated. The remaining gap is the preview's height model: the
  reference's card runs off the bottom of the screen, a virtualised list needs
  a bound.
- **Open for EPIC-17/18:** the bundled Vazirmatn/Inter carry no U+2192/U+2190,
  so §12's reference arrow cannot be drawn and §2 forbids fetching a font.
  Either the face gains the glyph or the reference set loses the arrow.
- **Standing finding:** `check_parity.sh` is not in CI and passes 0/45 at
  `main` — EPIC-08, 09 and 10 all merged with §7 unenforced. EPIC-18's problem
  is much larger than a sweep.
