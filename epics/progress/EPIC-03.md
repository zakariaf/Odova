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
