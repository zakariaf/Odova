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

## Task 14.1 — the settings write path and the reschedule gate

Built `lib/app/notifications/schedule_rebuilder.dart` (the port),
`lib/features/settings/data/settings_writer.dart` (the eighteen intent methods
and §13's rule-2 gate), and eighteen targeted UPDATEs on the data-layer
`SettingsRepository`.

**Two deviations from the epic's plan, both because the repo's rules outrank
it:**

1. **The port is in `lib/app/notifications/`, not `lib/services/`.**
   `structure_test.dart` allows seven top-level directories and `services` is
   not one; `lib/app/` is this repo's composition root and already holds
   `app/share/` and `app/pdf/` on the same footing.
2. **The writes are eighteen targeted UPDATEs, not a read-modify-write.**
   `SettingsRepository.setActiveVehicle` already argued this from EPIC-05: a
   round trip through the full companion makes every default on `AppSettings`
   a value the statement writes back, so a field added later and not yet read
   is reset on the next unrelated write. They go through one PRIVATE
   `_write(SettingsTableCompanion)` — private so
   `no_drift_in_signatures_test` keeps holding, since a companion in a public
   signature would make every caller need a database.

The rule-2 list lives in **one** `Set<SettingsKey>`, not at nineteen call
sites, so a setter added later is missing from a set rather than quietly
breaking a rule. Three mutations checked: adding `theme` to the set, dropping
`weekdaysOnly` from it, and letting the gate fire on a failed write.

`firstDayOfWeek` is REFUSED outside 1..7 rather than clamped — it is an
ISO-8601 weekday and a wrong value is a bug to see. `noticeDays` is written as
given: §3's 7..30 clamp defines the computed default only, and clamping a
number the user typed makes the field lie back at them.

**A note on the failure test.** The epic asked for "the fake DAO throws";
closing the database throws a `StateError`, and `guardPersist` deliberately
does not catch `Error` subtypes — an `Error` there means the schema and the
enums have drifted, which is a bug that must crash in debug rather than become
"something went wrong" in the UI. The test triggers an in-contract failure
instead: the settings row deleted, so the targeted UPDATE matches zero rows
and reports `NotFound`. It asserts on `setLanguage`, which is text-affecting —
the one arm where the gate could fire for a write that did not happen.
