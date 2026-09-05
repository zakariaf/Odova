# EPIC-10 — Home and the reminder screens

Started on a clean `main` at `2d72cf9` (EPIC-09 merged): analyzer clean at
`--fatal-infos --fatal-warnings`, 3,192 tests green, every repo and design gate
green.

## What EPIC-09 handed over that this epic has to act on

Read from `epics/progress/EPIC-09.md`, which is the handover:

- **`home` is still `PlaceholderScreen(screenId: 'home')`.** This epic replaces
  it, and doing so retires EPIC-08's `HomeBackdrop` stand-in — the one named in
  **F-8.2** as the reason `vehicle.switcher`, `dialog.discard`, `dialog.snooze`
  and `dialog.confirmDelete` all fail their band-profile check. Those four
  parity failures are EPIC-10's to close, not EPIC-09's, and closing them means
  re-pointing `test/parity/dialog_overlays.dart` and the switcher's capture at
  the real screen.
- **The sealed `VehicleEditTarget`.** Both /simplify passes named it and EPIC-09
  deferred it deliberately: `{mode, vehicleId}` plus `kUnsavedVehicleId` is one
  fact in three encodings. `reminders.edit` has the same create/edit pair, so
  this is the epic where the second copy would be written — the shape to adopt
  rather than repeat.
- **`RelativeDateBucket` already exists** (`lib/core/l10n/relative_date.dart`)
  with `inDays`/`inAboutWeeks`/`inAboutMonths` mirroring their ARB keys, and
  `bucketDaysAgo` for the past side. Task 10.2's `home.dueSoonRelative` buckets
  are the forward half of the same thing.
- **Seven ARB keys are already translated and waiting for this epic**:
  `homeDueSoonNoConfidence`, `commonEstimatedA11y`, `dateTomorrow`,
  `unitVolumeLitre`, `unitVolumeGallon`, `unitConsumptionPerDistance`,
  `unitConsumptionMpg`, `unitPerDistance`. They were written in six locales when
  their siblings were, because six locales in one commit is cheaper than six in
  six.
- **`vehicleFuelChangeNote` is waiting on `reminders.list`**, which this epic
  builds. SPEC §8 pairs a fuel change with a one-time snackbar offering that
  screen; EPIC-09 refused to ship a snackbar pointing at a route that did not
  exist. It exists after task 10.7.
- **Archive is unreachable from the UI**, because §8's row overflow was not
  built. Not this epic's screen — recorded so it is not mistaken for done.
- **The drift-stream rule, hit four times in EPIC-09**: a drift stream never
  delivers under `testWidgets`, and the symptom is a pending timer that fails
  the NEXT test rather than the one that opened it. Every widget harness here
  supplies `settingsProvider`, `vehiclesProvider` and any `watch*` provider the
  screen reads. `ScaffoldMessenger` also needs a real `Scaffold` in the harness
  or it swallows snackbars silently.

## What task 10.1 needs that does not exist yet

`buildHomeStack` must downgrade an item to `unknown` when its anchor came from
the `purchase` or `first_reading` rung — §9's rule that Home never shows a
figure it cannot stand behind. But `DueAnchor` (`lib/core/due/resolve_anchor
.dart`) carries only `date` and `odometerMetres`: the four rungs are walked and
the winner's PROVENANCE is discarded.

So task 10.1 starts by giving `DueAnchor` its rung, per axis, and that is a
change to the due engine EPIC-07 owns — additive, no behaviour change, and it
is what lets the Home-only downgrade be a presentation predicate rather than a
second opinion about due state.
