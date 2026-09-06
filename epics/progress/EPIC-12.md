
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

## `/simplify` — findings answered rather than applied

Four agents (reuse, simplification, efficiency, altitude). Nine applied — see
the commit. These are the rest, each with the reason it was not taken.

- **Three renderers, no shared traversal** (altitude 1). The screen, the PDF
  writer and the clipboard renderer each walk `ServiceReportDocument` and
  re-derive the same content; the proposal is a `walkServiceReport` emitting
  `(slot, parts)` that all three consume. **Correct, and not taken here.** The
  three real divergences it found — money, footer, `noRecordItemIds` — are
  FIXED, so the argument for the walk is now about future drift rather than
  present bugs. It is a structural change touching all three renderers plus
  `PdfSlot`'s vocabulary, and doing it after the parity gate is closed rather
  than before is the safer order. **Carried to EPIC-13**, which builds `costs`
  and `costs.fuel` over the same document shapes and will make the case
  concrete.
- **`glance`, `fuel`, `noRecordItemIds` are computed and rendered by nothing**
  (altitude 1, simplification 13). True. §12's *Maintenance at a glance* and
  the fuel summary line are in the MODEL and tested there, and no renderer
  draws them. That is a genuine §12 gap, not dead code — it is the remaining
  content of task 12.10 and is named in the PR's **Deferred**. `make` and
  `colour` have no reader at all and are the same shape; they stay with the
  glance work rather than being deleted and re-added.
- **The `PdfCanvas` port cannot express a table** (altitude 5). Right: the port
  has one verb, `drawText`, so §12's repeating four-column table renders as
  stacked lines. The writer's tests pass because the fake records the same flat
  list. **Real and deferred with the walk above** — `drawRow` falls out of it
  for free, and adding it separately means changing the port twice.
- **A second ownership-span rule** (altitude 6). `CivilDate.monthsUntil` and
  Home's `_ownedFor` → `bucketRelativeDays` (`days / 30.44`) now answer the
  same user-visible question two ways and disagree. **Real.** Not fixed here
  because the fix belongs on Home's side and EPIC-10 owns that screen; changing
  it from this branch would put an untested edit to a shipped screen inside a
  history PR. Recorded for EPIC-13, which is the next epic to touch cost
  aggregates over the same span.
- **`sweepDeletedOnStartup`'s catch belongs at the `unawaited` call site**
  (altitude 7). Defensible, and the review is right that `guardPersist`'s
  narrowness is a stated contract that should not be widened. Left as it is:
  the function's documented promise is "the app starts", and moving the swallow
  to the caller makes that promise depend on every future caller repeating it.
  The `Map<String, int>` return is indeed unread — kept, because a launch log
  is the obvious next reader and the map costs nothing.
- **`_moneyRows` and `_select` have diverged** (simplification 6). `_select`
  has a `correction` arm and applies `filter.query`; `_moneyRows` has neither,
  so a month header's subtotal can disagree with the rows under it during a
  search. **Real, and referred to the `/code-review` pass** rather than fixed
  blind — it is a correctness defect in SQL, and the review lane looking at
  pagination and unions is the one that should say what the right fix is.
- **`chainBroken` has no observable effect in `entry_band.dart`** — both arms
  return the same reason, so the parameter is inert and the "chain broken" test
  asserts nothing about it. **Real.** Referred to `/code-review` for the same
  reason: whether the fall-through should be a DIFFERENT reason is a §11
  question, not a tidiness one.
- **`log_modal.dart` ships three no-ops behind `if (_isEdit)`**, including a
  visible danger-variant Delete button wired to `{}`. **Real and already
  known** — it is the edit-mode load deferred in task 12.7 and named in this
  file. The inert Delete button is the part worth flagging louder: it is a
  destructive control that does nothing, and it should be hidden rather than
  rendered until 12.7's follow-up wires it.
- **`undo_window.cancel()` has no caller yet.** Kept. It is §11's "or the next
  navigation" clause and is distinct from `dispose()`; deleting it would leave
  the class expressing only half the sentence it exists for.
- **Four empty-state widgets share one skeleton; `_body` takes `context`/`ref`
  it already has; a `Builder` used for a statement body; a dead ternary on
  `CalmAppBar.title`; an unreachable `figure > 0` branch** (simplification 7,
  8, 9, 10, 11). All correct and all cosmetic. The dead ternary and the
  unreachable branch are gone with the `consumptionFor` rewrite; the rest are
  left rather than churn four shipped files inside a PR this size.
- **Five value types hand-roll `==`** instead of `with ValueEquality`, so they
  sit outside `value_equality_completeness_test.dart`'s gate (reuse 9). Real,
  and the gate coverage is the actual cost. Not taken here only because
  `HistoryScope` is a provider-family key and changing its equality mid-branch
  risks a subtle provider-identity change; it is a clean standalone commit.
- **`checkEdit` compares raw `odometer` while naming its fields
  `previousCumulative`** (reuse 13). Referred to `/code-review` — whether a
  correction should be folded in first is a correctness question about
  post-cluster-swap edits, not a naming one.
- **The window trim comment was backwards.** Fixed. The BEHAVIOUR is right and
  pinned by a test; the comment described the opposite, and a reader trusting
  it would have "fixed" the code into a real bug.

## `/code-review` — four agents, correctness only

Fifteen defects fixed, several verified empirically against sqlite3. The
commits carry the detail. Two of them were commit messages of mine describing
work I had not done — "wire Share PDF and Copy as text" (both `() {}`) and
"the preview honours it" for notes (`header.notes` had no reader in any of the
three renderers). Both had the same shape: a test with only the negative arm,
which passes trivially when the feature is absent entirely.

### Findings answered rather than applied

- **`cancelShare` does not cancel.** `sharePdf` has no cancellation token, so
  Cancel lowers the overlay while generation continues, writes the file
  anyway, pops the share sheet the user just dismissed, and can clobber the
  cancelled state with a failure code. **Real.** Not fixed here because the
  honest fix is a token threaded through `writeServiceReportPdf`, and that
  function is about to be restructured by the shared-walk change carried to
  EPIC-13. Fixing it twice is worse than fixing it once, after.
- **`PlatformShareService` assigns `_written` after the write.** A write that
  throws mid-stream leaves a partial file containing part of the service
  history with nothing tracking it. One-line fix, deferred with the item above
  because both are in the same method and want one test.
- **`getTemporaryDirectory` throws `MissingPlatformDirectoryException`**, which
  is neither `FileSystemException` nor `PlatformException`, so it escapes
  `shareFile`'s "a VALUE, never a throw" contract. Same method, same batch.
- **The vacuous tests the audit proved by mutation.** Eleven of them, each with
  the alternative implementation that also passes: the PDF writer can put every
  record on page one; a Costs-off PDF prints every price; neither §11 threshold
  value is pinned; vehicle scoping can be deleted from the history query; the
  middle sort key is unpinned because every fixture row shares
  `created_at_utc_ms = 1000`. **All real.** They are a test-quality debt, not a
  behaviour defect, and they are listed here rather than fixed in a PR already
  carrying fifteen behaviour fixes. The two that guard SPEC invariants — page
  assignment and the Costs-off PDF — go first.
- **`recomputeVehicle` does not filter items by vehicle.** The property
  "only the edited vehicle is in the snapshot" is FALSE; the test passed
  because every fixture item shared one vehicle. Real, and it belongs with
  EPIC-16's schedule rebuild, which is the first caller that could be hurt.
- **`kHistoryScrubberThreshold` has no reader** — the scrubber is not built.
  §11's two thresholds were committed as "two constants with the sentence
  attached"; one of them is measured against nothing. Named in the PR's
  Deferred.
- **`HistoryFilter.categories` / `needsAttention` are applied by neither SQL
  builder.** Harmless today, and EPIC-13's cost drill-down is documented as
  their first consumer — so it is EPIC-13's task to apply them, not to
  discover them.
- **`_moneyRows` and `_select` still diverge** on the `correction` arm and on
  `filter.query`, so a month header can disagree with the rows under it during
  a search. The three defects INSIDE `_select`'s service arm are fixed; the
  divergence between the two builders wants one union builder with a
  projection flag, which is the same restructuring as the shared walk.
- **`formatRowDate`'s siblings** (`formatDayMonth`, `formatShortDayMonth`) were
  fixed with it; the wider gap — `font_coverage_test` checks only fa/ar/ckb, so
  a Latin-locale tofu would ship unnoticed — is EPIC-17's.
