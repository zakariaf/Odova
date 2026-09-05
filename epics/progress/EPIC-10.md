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

---

## Task 10.1 — `buildHomeStack` ✅

`DueAnchor` gained `AnchorRung` per axis (`record`, `baseline`, `purchase`,
`firstReading`) and `DueAssessment` carries the anchor out with it, so §9's
"Home renders any item anchored on the `purchase` or `first_reading` rung as
`unknown`" is a presentation predicate over what the engine concluded rather
than a second walk of the same ladder that could disagree with it. Additive to
EPIC-07's engine, no behaviour change.

`buildHomeStack` is pure Dart: the single sort key is the projected due date,
overdue items float on it because their dates are past, ties break by severity
then label, `needs_odometer` is demoted out of the primary slot while a
supported time-driven item exists, a deep-linked item is pinned, and the
unknown-anchored ones collapse into one card at the foot.

**One test did not discriminate.** The severity tiebreak passed with the
comparison deleted, because the fixture's labels happened to sort the same way
severity did. Fixed to `Zzz due` / `Aaa soon`, which only the severity rule
orders correctly.

## Task 10.2 — Home's copy ✅

Every sentence is an ICU message in six locales; `home_copy.dart` maps a
`DueCardModel` to a key and its arguments and builds no strings.

**`_daysSince`'s clamp was unobservable.** `bucketDaysAgo` already maps `<= 0`
to today, so the line defended nothing. Removed rather than kept behind a
comment that was not true.

**The status-encoding gate had to widen.** `DOMAIN_RE` now exempts
`/domain/` and `*_copy.dart` as well as `lib/core/`: a copy mapper's whole job
is to switch on a `DueState` and return a key, and the gate's contract is that
a WIDGET may not. Two arms added to `tools/check_gates_selftest.sh` — a slot
read planted in a `domain/` file and in a `*_copy.dart` — so the widened
allow-list is one that has been seen to fail.

## Task 10.3 — the odometer strip and the estimate popover ✅ (corrected in 10.4)

`EstimatedValueText` marks a projection and only a projection: rounded to
100 km / 50 mi, `~` on the visible string, `about … estimated` in the
accessibility label, and nothing at all once `estimateOdometer` has stopped
projecting.

**Three defects found by running the gates after the fact rather than after the
task.** All three are fixed in `1cd1aaf`:

- **The `~` was outside the isolate.** `formatWithUnit` returns
  `FSI … PDI` and the strip prefixed the mark to that, so in Arabic it lands at
  the far end of the line. It reads correctly in English, which is why it
  survived. `withUnitUnisolated` + `commonEstimatedValue` put it inside.
- **`check_status_encoding.sh`'s tilde rule had no self-test arm** — and it was
  the rule actually being broken. Two arms now plant it, single- and
  double-quoted.
- **The strip was the wrong shape.** `.odostrip` is an icon tile, a stacked
  value and meta, and a chevron at `min-height: 72px` on `surface-2`; the widget
  drew value and freshness side by side and overflowed by 17pt on the floor
  screen in English. The height floor also sat inside the padding, making the
  strip 104 — 25pt off the bottom due card.

**Carried forward:** a task's Verify block is not done until its gates have been
run. Three of these would have been caught the day they were written.

## Task 10.4 — compose `home` ✅ (parity blocked, and named)

15 screen tests, 5 glance-tile tests, 1 grayscale test, 8 anchor-line tests.
Everything §9's *Interactions* table lists is asserted by route name and
arguments, because EPIC-11 owns the destinations.

**The anchor line was not drawn at all.** `due_stack.dart` printed
`assessment.dueOn`, which a distance-driven card does not have — so §9's one
checkable fact was missing from exactly the cards that most need it.
`homeAnchorLine` now covers all seven rows of §9's card table. Task 10.2's title
promises the anchor messages and its test list names none; that is why it
shipped.

**A sheet opened from a tab root rendered under the tab bar.** `CalmSheet.show`
used the nearest navigator, which inside `AppShell` is the tab's branch — and
the bar is a later sibling of the branch in a `Stack`. The overflow's last item,
"Turn this off", sat exactly under the 62pt `+`. `find.text` found it and
`tester.tap` only warned; the test caught it because it asserts the ROW in the
database rather than the tap. `vehicles`' mark-as-sold sheet had the same latent
bug. Fixed once, in `CalmSheet.show`.

### F-10.1 — `home` parity fails the band profile, and the cause is three design decisions

70/112, 59/111, 65/107, 52/107 against a 75% floor. Colour and theme pass in all
four; the pixel diff is 23% and informational. The app tracks the reference
exactly down to the primary card's action row and then diverges, in three ways
that are all `SPEC.md` §9 disagreeing with the `home` artboard:

1. **The artboard draws FOUR due items; §9 caps the stack at three.** "1 primary
   + up to 2 secondary. Never more." is stated twice in §9 and is the rule the
   *Hundreds of items* state exists to protect. The app shows three and a red
   see-all row carrying the remainder.
2. **The artboard draws the secondaries as one `.rowgroup` of `.row--compact`
   (56pt);** §9's *The card* table and `odova.css`'s own
   `.due-card--secondary { min-height: 72px }` define a card at a second
   density, with its own type scale and chevron. The design system has the
   component; the artboard composed a different thing out of rows.
3. **The artboard has no see-all row and no glance-tile row.** §9's *Anatomy*
   diagram and its zone table require both, and *Nothing due* says the tiles
   exist so that "whoever finds nothing due should still leave knowing what the
   car costs and what it drinks".

Every difference is content the spec asks for and the drawing omits, or a
component the stylesheet defines and the drawing did not use. Making the screen
match would mean deleting three things §9 specifies; re-shooting the reference
would decide the same question the other way with no record. **Neither is an
engineering call**, so both are refused here and the question goes to EPIC-17's
design sweep alongside F-9.16. No tolerance widened, no reference regenerated.

Two smaller divergences in the same set, listed so the sweep has them:

- The artboard's app bar carries a `badge badge--overdue` reading `1 overdue`.
  §9's zone table describes the bar as "Vehicle name. Chevron and tap target
  only when ≥ 2 vehicles exist… No overflow menu, no gear" and does not mention
  a badge. Not built; it needs two more plural keys and a product decision.
- The artboard's dates omit the year (`Entered 2 September`, `12 August`) while
  `vehicles`' artboard keeps it for a past year (`12 March 2024`).
  `formatLongDate` always writes the year. §5 states no rule either way, so this
  is a formatting decision nobody has made.

### Deferred, deliberately

- **All three glance tiles show `—`.** `costPerDistance` and `monthlyCost` are
  **EPIC-13's** — that engine holds the per-currency grouping and the
  amortisation, and a second implementation here would be a second answer.
  EPIC-10's *Where we are now* lists both as already callable; they are not.
  The consumption tile is deferred with them rather than alone: its figure needs
  fill-ups joined to correction-aware cumulative readings, which is the same
  composition EPIC-13 builds for `costs.fuel`. The tile ROW, its two-line
  labels, its no-zero rule and the `—` popover are all built and tested.
- **The two cost tiles are not tappable.** §9 says a `—` opens a popover
  explaining why. The only sentence this epic could write is "not built yet",
  and a popover that cannot say why is worse than none.
- **`around mid-October`.** §9 gives a distance-projected date at `assumed`
  confidence a month-precision phrase. Nothing formats one, and inventing a day
  is the substitution the uncertainty ladder exists to refuse — so `assumed`
  gets no anchor line at all rather than a false one.
- **The card overflow's Snooze does nothing yet.** `dialog.snooze` is EPIC-08's
  global dialog and the snooze WRITE arrives in task 10.7. The case is named in
  the switch rather than left to a default, so it is a compile-time list of four
  and not three plus a silence.
