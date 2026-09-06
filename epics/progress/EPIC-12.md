
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
