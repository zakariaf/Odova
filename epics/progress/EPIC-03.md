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
