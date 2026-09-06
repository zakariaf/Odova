# EPIC-11 — Logging: fill-up, service, expense, odometer

Started on a clean `main` at `0283d6d` (EPIC-10 merged): analyzer clean at
`--fatal-infos --fatal-warnings`, 3,460 tests green, every repo and design gate
green.

## What EPIC-10 handed over that this epic has to act on

Read from `epics/progress/EPIC-10.md`, which is the handover:

- **Four navigation intents now need destinations.** Home's due card *Log it*,
  `reminders.list`'s *Done today*, the odometer strip and the staleness strip's
  inline action all push `Routes.log(...)` with their prefill arguments today,
  and EPIC-10's tests assert the intent only. Task 11.6 turns those into
  end-to-end assertions.
- **`dialog.discard` was deferred to whoever needs a dirty flag first.** That is
  this epic: §10's cancel rule is "clean → dismiss silently, dirty → discard
  dialog", so the log modal is where the dirty-tracking finally gets built.
  EPIC-08's dialog is built and waiting.
- **The date pickers were deferred to §10**, which is this epic. `reminders.edit`
  renders two read-only date rows wired to its draft; the picker they open is
  built here and they get wired to it.
- **`CalmOdometerInput` is 216pt** (F-10.3) and Home's staleness strip therefore
  uses `CalmField` directly with a shared `odometerProblemMessage`. This epic's
  `OdometerField` is the third widget over the same model and should be the one
  the other two collapse into if it can carry both.
- **The estimate mark has one home**: `formatDistanceFigure` in
  `lib/l10n/vehicle_labels.dart`, and `check_status_encoding.sh` refuses a
  Dart-side `~` in either spelling.
- **`needs_odometer` items with no projected date can fall out of Home's three
  cards** — recorded as an answered `/code-review` finding. This epic makes the
  odometer enterable from more places, which reduces how often that state is
  reached, but does not settle the ordering question.

## What this epic's "Where we are now" gets wrong

**EPIC-06 did not deliver the backup file.** The epic's preamble says "EPIC-06
delivered the backup file of §6 — the export writer, the import-replace path and
the round-trip test suite", and it did not: `lib/data/backup/` holds
`migration_safety_copy.dart` and nothing else, and `epics/README.md` assigns
backup, export and import to **EPIC-15**. The Definition of done item "Every
field these forms write round-trips through EPIC-06's export and import" is
therefore not satisfiable in this epic and is carried to EPIC-15, where the
writer is built against the rows this epic creates.

Everything else in *Where we are now* checks out against the repo: the
repositories, the pure engines, the Calm library including `CalmNumberPad`, the
six-locale ARB pipeline, and the central `+` wired to `/log/:type` — which today
renders `PlaceholderScreen`.
