# EPIC-14 — Settings, units, language and about

**Baseline at branch point** — `main` at `1fc47ef` (EPIC-13 merged), analyzer
clean at `--fatal-infos --fatal-warnings`, 4,249 tests green, every gate green.

**Carried in from EPIC-13's `/code-review` and `/simplify`**, to be taken with
the tasks that touch the same code rather than as a separate sweep:

- **`core/time/completed_months.dart` is dead** and duplicates `CostRange`'s
  window rule. This epic is the next one to open `core/time/`; delete it or
  make `CostRange` delegate.
- **`CalmScaffold` takes an eager `List<Widget>`**, so `ListView.separated`
  cannot virtualise what it is handed and `trips.list` materialises every row.
  A builder API on the scaffold is the fix and every screen inherits it —
  recorded for EPIC-17, but this epic adds five screens to the pile.
- **`CostRange.thisMonthSoFar` still has no production caller.** The "this
  month so far" line now renders, but from `CostsInputs.thisMonthAmounts`
  rather than through that API.
- **`TripDraft.isDirty` and `TripRepository.undelete` have no callers.** Both
  pair with `trips.edit` work EPIC-13 deferred: the `dialog.discard` guard and
  the save Undo. §13 says Settings has no Save button and therefore never
  fires `dialog.discard`, so the guard work does not land here — but the trip
  form's does, and it is small.
- **`fuel_insights` re-derives EPIC-06's `consumption_stats` engine.** Belongs
  with the deferred fuel-kind selector, which is where a bi-fuel or electric
  car chooses its unit.

**Two ports this epic declares and EPIC-16 implements** (§13 and EPIC-16 agree
on the split from both ends): `ScheduleRebuilder` for the reschedule that any
text-affecting write triggers, and the notification-permission gateway behind
`settings.notifications`' five states. If EPIC-16 lands first, override its
implementations rather than declaring a second seam.
