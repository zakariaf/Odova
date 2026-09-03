- 3.3 `CalmRowGroup` + `CalmListRow` — 15 tests, `6c2017c`. Two defects in the
  reference example fixed rather than copied: `IgnorePointer` on a disabled row
  let the tap fall through to the row underneath (now `AbsorbPointer`), and
  `semanticLabel: title` doubled the label on top of the merged `Text` children
  ("Reminders, Reminders, on"). Added `CalmListRow.switchRow` as the named
  variant the inventory lists; the unnamed constructor's signature is untouched.
  EPIC-02's `ink4` gate fired on the chevron as predicted: converted from a
  blanket ban to a one-entry allowlist, and the five failing light/dark pairs
  (2.60 / 2.23 / 1.97 light; 2.85 / 2.49 dark) are now dated exceptions that
  assert they still fail.
- 3.4 `CalmButton` + `CalmButtonExplain` — 10 tests. Three reference defects
  fixed: `maxLines: 1` (clips German), sizing inside the `AnimatedContainer`
  (cannot lerp bounded↔unbounded constraints), and the doubled semantic label.
  EPIC-02's `radiusPill` gate fired on the pill → `StadiumBorder`; the gate then
  matched its own explanatory comment, so it now strips comment lines (both arms
  re-verified). Closed the same hole in `CalmPressable`'s focus ring.
  `pumpApp` gained `textScaler`/`boldText`/`accessibleNavigation` (nullable — a
  non-null default broke EPIC-01's no-clamping test) and `settle: false`.
  Added `test/support/device.dart`; EPIC-03's front matter claims EPIC-01
  shipped `Device` and it did not.
- 3.5 `CalmChip`/`CalmChipBar`, `CalmBadge` (11 kinds), `CalmStatusDot` — 17
  tests. **Finding against the epic:** Done-when asks for "six visually distinct
  dot silhouettes"; odova.css §12 ships FIVE marks for six states (`ok` and
  `overdue` are the same 12px filled disc; `unknown` and `needsOdometer` differ
  only by 0.7 opacity). Not invented around — the reference is the authority.
  The (mark, label) pair is unique and that is what is asserted; the collision is
  pinned so a future design fix goes red. Third occurrence of the doubled
  `semanticLabel` defect.
- 3.6 input kit — `CalmField`, `CalmStepper`, `CalmSwitch`, `CalmSegmented`; 26
  tests. Reference example missing the `ƒ` badge, `onChanged`, the merged
  semantics node and `didUpdateWidget` for a changing `focusNode` (a real leak).
  Field height was 58 until the line-height came from `.input` (1.4) rather than
  the type role (1.5). `TextField` needs a transparent `Material`.
  **Gate limit noted:** `check_calm_rejects.sh`'s `min(Height|Width):` rule only
  matches bare literals, so every Calm widget's named size constant is invisible
  to it. The real floor is measured by `getSize` per widget, and task 3.11's
  matrix does it at five text scales — that is where the floor is actually
  enforced.
- 3.7 chrome — `CalmScaffold`, `CalmAppBar` (4 shapes), `CalmTabBar`; 14 tests.
  **Real defect found:** the +'s 18pt overhang was not hit-testable (44pt of a
  52pt floor). The bar now owns the band it overhangs into. The example's `elev2`
  on the tab bar contradicts `.tabbar`'s `box-shadow: 0 -1px 0 divider`; the CSS
  wins. `Container(alignment:)` made the app bar 600pt tall in a `Center`.
  Modal title was 5.1pt off centre until the Row's `mainAxisAlignment`.
- 3.8 overlays — `CalmSheet`(+`.show`), `CalmDialog`, `CalmSnackbar`; 11 tests.
  One shared `CalmOverlayTransition` reads the route animation so scrim and
  surface cannot drift. The scrim-timing test was wrong twice before it was
  right (animated barrier colour; tree presence vs. visibility). Added
  `CalmMotion.undoWindow` — the one duration with no `--dur-*` token — because
  two gates correctly refuse a bare `Duration(seconds: 6)` outside the theme.
  **Deferred:** `showModalBottomSheet` contributes its own full-height slide
  under Calm's 24pt rise. The rise, fade, durations and curves are all pinned;
  the composite entry is a slide-plus-settle rather than the pure 24pt rise
  odova.css describes. If the motion review rejects it, the fix is a custom
  PopupRoute — not a tolerance change.
- 3.9 `CalmNumberPad` — 9 tests. **Defect in task 3.1's `CalmDirectionalIcon`:**
  Material's directional glyphs carry `matchTextDirection: true`, so every one
  of them was being flipped twice and rendered unflipped in RTL. Fixed at the
  source (forced-LTR glyph + one explicit flip), pinned with a two-arm test.
  The row chevron was affected too. Also: the grid mirrored (now forced LTR with
  the backspace glyph given the real direction), and `Expanded(flex: 2)` made
  the confirm key 4pt narrow. Added an optional `digits` parameter — EPIC-04's
  seam for `۰۱۲۳`.
- 3.10 answer surfaces — `CalmDueCard`/`CalmDueView`/`CalmProgressBar`,
  `CalmAllClear`, `CalmEmptyState`; 17 tests. Reference example used
  `FilledButton` (banned), `LinearProgressIndicator` (cannot animate width over
  `motion.slow`), a self-mirroring `Icon` and `BorderRadius.circular(radiusPill)`
  in a ClipRRect. First progress bar drew zero-width: `Align(widthFactor:)`
  scales the CHILD, not the track — `FractionallySizedBox` does what was meant.
- 3.11 gallery + goldens + matrices — `example/calm_gallery.dart`,
  `test/ui/calm/support/specimens.dart` (22 specimens, one list for both), 88
  committed goldens, and the touch-target / overflow / traversal matrices; plus
  APCA alongside WCAG in the contrast audit. **Six defects found by the
  matrices:** a 21pt overflow in the secondary due card at 200%, four
  `maxLines: 1` clips (tab labels, modal Cancel, odometer value, button label),
  and a negative EdgeInsets on the `ƒ` badge in the Arabic type variant.
  **New finding from APCA:** `ink3` on `surface` in DARK is 39.1 Lc — below the
  45 non-text floor — while WCAG 2.x passes it at 4.6:1. Same ink3 finding,
  new evidence that EPIC-17's fix is not light-theme-only.
  New gate `tools/check_golden_lane.sh` with both self-test arms.

  **Handover — what the automated checks cannot see.** EPIC-03's definition of
  done includes a human pass over the gallery against `design/calm/system.html`
  at both themes and both directions: type weight, icon shape and optical
  alignment. The goldens pin what the library IS, not what it should be. Run
  `flutter run -t example/calm_gallery.dart` and open the system sheet beside
  it. Not done here, and not doable by an automated pass.

### `/simplify` — four agents, all findings applied or answered

**Applied (17).**

*Correctness, found by the altitude pass and not by any test:*
- `CalmSwitch` hand-assembled `Semantics` + `CalmTapTarget` + `GestureDetector` —
  a strict subset of `CalmPressable` — so a standalone switch had **no Tab stop,
  no focus ring and no keyboard activation** (SPEC §17), and the traversal matrix
  could not see it because that matrix enumerates `CalmPressable`. It goes
  through the primitive now, which gained a `toggled` capability. Pinned by a
  test, and the switch specimen is enabled so the matrix actually reaches it.
- `CalmDueCard` wrapped the primitive in `Semantics` + `ExcludeSemantics`,
  discarding its `Semantics(button:, enabled:)` node — a button that could never
  report disabled. Now goes through `semanticLabel`/`semanticsValue`.
- `RenderCalmTapTarget` enforced the 52pt floor in **one of three sizing paths**:
  it inherited `RenderShiftedBox`'s intrinsics and never overrode
  `computeDryLayout`, so inside an `IntrinsicHeight` a 40pt chip reported 40.
  All three paths now, with a test.
- `expandTapTarget` deleted. Above the floor the wrapper is provably a no-op, so
  the flag could only ever be wrong; three widgets had already re-implemented it
  as a hand-rolled `ConstrainedBox`. The floor is unconditional and now holds for
  widgets nobody has written yet.
- `semanticLabel` now **replaces** the subtree's words. The doubled-label defect
  was found and fixed locally three times (3.3, 3.4, 3.5); the primitive makes it
  unrepresentable.
- `CalmDueCard` and `CalmAllClear` were missing `--elev-sheen`, which `.due-card`
  and `.allclear` both declare, because `CalmSurface` had no `gradient` and both
  went around it. A missing parameter, not a decision. Eight goldens regenerated.
- The disclosure chevron was 18 in `CalmListRow` and `space.s5` (20) in
  `CalmDueCard` — same glyph, two sizes, one drawn from the *spacing* ramp. Added
  the icon scale (`.icon--sm` 18 / `.icon` 24 / `.icon--lg` 32 / `.icon--xl` 44)
  to `CalmSpace` and routed all nine literals through it.
- A test that asserted on the app bar's decoration passed **unconditionally** —
  the decoration was always null. It asserts there is no `DecoratedBox` at all.

*Efficiency:*
- `CalmPressable` rebuilt its `Actions` map on every press-down, press-up and
  focus change, so `Actions` re-ran its listener bookkeeping each time on the
  touch path of every tappable surface in the app. Built once.
- The touch-target matrix evaluated its finder in the loop condition: 2N+1 full
  tree walks per specimen instead of one.

*Structure:*
- `CalmOverlayTransition` moved out of `calm_sheet.dart` into its own file with
  every motion parameter required — its defaults were the sheet's constants, so
  the third overlay would have inherited sheet motion by accident.
- `CalmBadge`'s two switches over `kind` (whose `_` arms had to stay exact
  complements for a `status!` to be sound) collapsed into one.
- `CalmAppBar.showVehicleChevron` is derived from `shape` rather than stored in
  parallel across four constructors. Still public: the inventory declares it.
- The tab bar's `i < 2 ? i : i - 1` written four times, replaced by iterating the
  four tabs and inserting the empty middle slot.
- `calmSnackbarBottomInset` was dead **and** its body was copy-pasted into
  `CalmSnackbar.show`; the show method calls it now.
- `CalmProgressFill` was a public widget that existed to give one test a
  `find.byType`. Deleted.
- Two `Container`s that were a `ConstrainedBox` and a `DecoratedBox`.

*Test infrastructure* — 12 decoration helpers, 3 focus-ring scanners and 4
specimen sheets collapsed into `test/support/calm_finders.dart`,
`CalmSpecimenSheet` and `Device.specimenSheet`. Each copy had hard-coded *which
container widget the implementation happens to paint through*, so a widget that
later gains an `AnimatedContainer` wrapper fails with a cast error rather than a
colour mismatch.

**Answered, not applied (3).**

- *"`CalmPressable.enabled` says what `onTap: null` already says."* It does not:
  `enabled` drives `Semantics(enabled:)`, which is how a disabled button reports
  `isEnabled: false` — a test pins that. It is also in the declared signature.
- *"`CalmIconTile` could absorb the dialog icon, the all-clear mark and the
  empty-state art."* The reviewer flagged this as their weakest finding and I
  agree: each copy is four lines, the constants genuinely differ, and
  `calm_icon_tile.dart` carries a justification for its own fixed 44 that does
  not generalise.
- *"Scope the golden CI lane to its directory to save ~6s of test enumeration."*
  Not taken. A golden-tagged test added elsewhere would then be silently skipped,
  which is a worse failure than six seconds of a multi-minute job.

**Signature contract updated** in `.claude/skills/calm-components/` for the three
public API changes (`CalmPressable`, `CalmSurface`, `CalmSwitch`) — that file
says a change to a signature is a change to the widget and the table together.

### `/code-review` — 15 findings, all applied

Run after `/simplify`, per CLAUDE.md §5. Nothing was answered-not-applied: every
finding was real, and one of them was introduced by the simplify pass an hour
earlier.

**Accessibility (6).** These are the ones no test in this epic could see.

1. *The primary due card stripped its own action button out of the semantics
   tree.* `semanticLabel` replaces the subtree — the change `/simplify` had just
   made — and `CalmDueCard` passed one unconditionally, so `_PrimaryBody`,
   including the "Log it" button, was excluded. A screen-reader user on Home
   heard "Oil change, Due now, button" with no way to invoke the action. The
   label now goes through the primitive only at SECONDARY density, where nothing
   in the subtree is interactive.
2. *`Semantics(enabled:)` read `widget.enabled` instead of the resolved
   `active`.* A control built with `onTap: null` — `CalmVehicleTitle` with no
   `onTapVehicle`, a snackbar action with no callback — announced itself as an
   enabled button that draws no ring and does nothing, contradicting `onTap`'s
   own doc comment.
3. *A row inside a `CalmRowGroup` had an invisible focus ring.* The ring is drawn
   6pt OUTSIDE the box; the group's `ClipRRect` clipped both side strokes
   entirely. `focusInset` draws it inside where the parent clips. No widget test
   can see this — the ring's `DecoratedBox` is in the tree either way; it is the
   pixels that are gone.
4. *A disabled `CalmListRow` carried no disabled semantics.* Opacity is not a
   channel a screen reader has. `CalmChip` already did this and the two
   disagreed.
5. *`CalmField` put the error in the semantic `value`.* `MergeSemantics` absorbs
   the `TextField`'s configuration and `SemanticsConfiguration.absorb`
   CONCATENATES value strings, so the error fused with the typed text and was
   re-announced on every keystroke. It rides the `hint` now.
6. *The traversal test proved nothing.* It counted rings, so a tree where Tab
   cycles between two controls and never reaches the other N−2 passed. It
   collects `primaryFocus` per stop and asserts N distinct nodes; verified by
   planting a missed stop.

**Design and correctness (5).**

7. *`loading` collapsed into the disabled palette.* `.btn.is-loading` sets
   `color: transparent` and nothing else — the fill stays the variant's. A
   loading primary Save rendered grey, lost its `elev1`, and drew the spinner in
   `ink4` on `surface2` at 2.60:1: an undeclared SC 1.4.11 failure that the ink4
   allowlist justifies only as exempt disabled TEXT. Split into `interactive`
   (taps) and `enabled` (palette).
8. *A switch inside a `CalmListRow.switchRow` rendered at 42%.* The sanctioned
   arrangement is `onChanged: null` — the row owns the tap — and that was mapped
   straight onto "disabled", so every settings row showed a greyed-out switch
   that toggled perfectly well. `enabled` is now its own parameter.
9. *`calmSnackbarBottomInset` always added the 62pt tab bar.* SPEC §10 puts Undo
   on the five `log.*` forms, which are modal and have none, so it floated 62pt
   above where the design puts it. `CalmChromeScope` publishes what is actually
   there; both cases are tested.
10. *Overlay entry was linear, and the dialog faded twice.* `ModalRoute.animation`
    is the raw controller value, so the rise, scale and fade never touched a
    curve — the durations were pinned by tests and the curves reached nothing.
    `RawDialogRoute`'s default `FadeTransition` also multiplied with the
    transition's own, making the dialog's opacity t². Curved now, with an
    identity transition builder; opacity is clamped because `easeSettle`
    overshoots by design.
11. *`CalmProgressBar` read the global `calmMotion` const* — the only place in
    `lib/ui/` that bypassed `CalmMotion.of(context)`, so a Theme that overrode
    the extension was silently ignored by one widget.

**Gates and matrices (4).** Each of these made a green check meaningless.

12. *The overflow matrix looped all 22 specimens inside one `testWidgets`* — the
    exact failure its own header warned against.
    `DebugOverflowIndicatorMixin` never resets `_overflowReportNeeded`, so a
    `RenderFlex` that overflowed on specimen 3 reported nothing on specimen 11.
    One test per specimen now: 1320 cases, 10s.
13. *The overflow and touch-target matrices ran LTR English only.* The Arabic
    type ramp is a different `CalmType` with a taller line box — the variant that
    produced the `ƒ` badge's negative-EdgeInsets bug — and it was never measured.
    Both directions now, and the first RTL run found a real clip:
    `CalmTile`'s label needs three lines at 300% in Persian.
14. *`check_touch_targets.sh` rule 4 ended a test case at the first line matching
    `});`* — the close of any nested closure. A realistic reduced-motion case
    with a `setState` or an `addTearDown` in it defeated the rule entirely, and
    the self-test's planted violation had no nested closure so both arms stayed
    green. It tracks brace depth now, with a second arm in that shape.
15. *`check_golden_lane.sh` scanned only `.github` and `tools`* while its own
    comment claimed "the whole automation surface" — missing `.claude/skills`,
    where five of the scripts CI invokes live, including the parity script. New
    arm plants a rebaselining skill script.

Twelve goldens regenerated for 7, 8 and the switch specimen. All deliberate.
