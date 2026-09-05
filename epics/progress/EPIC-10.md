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

## Task 10.5 — the conditional strips and the inline odometer save ✅

`home_strips.dart` in `domain/` decides which of the three §9 shows, in §9's
priority order, capped at two; `CalmNotice` is `.notice` in `lib/ui/calm/`;
three widgets compose them. 10 domain tests, 9 widget tests.

**The store is a FILE, not a table.** §9 says the dismissal keys live in a
key-value store "not in the backup file". Every backup and every migration
safety copy reads the DATABASE table by table from a declared list, so putting
this outside the database makes that structural rather than a list somebody
maintains — and it needs no schema version, no migration rung and no
dependency. It is deliberately forgiving: a missing, corrupt or wrongly-shaped
file is an empty store, because losing it costs a dismissed banner and refusing
to launch over it costs the app.

### F-10.2 — a snackbar shown from a tab root was under the tab bar

`CalmSnackbarHost` reads `CalmChromeScope` for its bottom inset, and **no tab
root passes `tabBar:` to `CalmScaffold`** — the bar belongs to `AppShell`. So
every screen inside a branch answered "there is nothing below me", the snackbar
floated 62pt too low, and its Undo sat under the 62pt `+`, which swallowed the
tap. **Two Undos were affected and both had already shipped**: the strip's Save
and the card overflow's "Turn this off".

`AppShell` now publishes `CalmChromeScope(hasTabBar: true)` around the branch,
and `CalmScaffold` no longer writes `false` over it — a scaffold declares the
bar it DRAWS, not the one it sits on. The callbacks also capture their context
from a `Builder` inside the scaffold, because a `State.context` is above the
frame.

Found by asserting the ROW in the database rather than the tap, then noticing
the tap had only warned. That is the second time in this epic — the first was
the sheet under the same bar — and the lesson is the same one: **`tester.tap`
warns where it should fail**, so a test whose only assertion is downstream of a
tap can pass without pressing anything.

### F-10.3 — the shared odometer input is 216pt

`CalmOdometerInput` is a stacked label, a field, a helper line and a "Use it
anyway" button. Inside §9's two-line strip it pushed the PRIMARY CARD below the
fold — under the one rule §9 states about strips. The strip uses `CalmField`
directly with `showLabel: false`, which is a new `CalmField` capability and a
visual decision only: the label is still announced, because a field with no
accessible name would not have been.

### Deferred, deliberately

- **Two of the three strips cannot fire.** The confirmation reports on a record
  a notification ACTION writes; the digest needs the notification permission
  state and a last-opened timestamp. All three are **EPIC-16's**. Their widgets
  are built and asserted directly; inventing a trigger here would mean a strip
  that fires on a fact nothing records.
- **`home.digest_shown_at` and `home.first_run_hint_dismissed` are declared and
  unused**, for the same reason. The store, the keys and the round trip are
  tested.

## Task 10.6 — Home's other states ✅

12 tests. All-clear, first run, the unknown-anchor card, the sold panel, the
error panel, the broken-row card and the 150 ms skeleton.

**`buildHomeStack` was putting untracked items in the unknown card.** §9: "Only
tracked items appear; untracked catalogue rows live on `reminders.list`." The
engine only assesses eligible items, so one should never arrive — but the guard
is what makes that a property of the function rather than a promise the engine
keeps on its behalf.

**The see-all row survives the all-clear.** §9's zone table keeps it "whenever
the vehicle has ≥ 1 tracked item" and its *Nothing due* drawing puts it under
the card, so `DueStack` gained `showCards: false` rather than the screen growing
a second copy of the row.

**The 150 ms is a `CalmMotion` slot.** `check_touch_targets.sh` refuses a raw
`Duration` outside `theme/`, and it is right to: "it is not really motion" is
not a distinction a grep can make. `undoWindow` set the precedent — SPEC.md
§10's six seconds is a product decision living on the motion extension for
exactly this reason — so `skeletonDelay` joins it, with the same note that it is
NOT collapsed by reduced motion. Collapsing a threshold to zero would make the
skeleton flash on the common path, which is what the delay exists to prevent.

**A `Timer`, not `Future.delayed`, for the skeleton.** A future cannot be
cancelled, so a screen that resolved in 5 ms left one pending for the remaining
145 — and `testWidgets` asserts on a timer outliving the tree, which turned
**eighteen** unrelated tests into teardown failures. What `initState` starts,
`dispose` stops.

**`vehicleStoreUnreadableProvider` short-circuits on a snapshot.** Its first
version watched the same six streams the snapshot composes, so every widget
test and every parity capture that supplied the snapshot outright got the drift
streams back through the side door — the hang-then-fail-the-next-test failure
the whole harness is shaped to avoid. A snapshot is proof the store was read, so
it answers before touching any of them.

### F-10.4 — §9's all-clear cannot keep the tiles above the fold

The task asks for `all-clear keeps the glance tiles above the fold at
375 × 667`. It does not hold, and the reason is Calm's own `.allclear`:
`padding: space-8 / space-6 / space-7` around a 92pt mark with a 12pt ring, a
title, a line, a meta line and a `since` block — **289pt without the receipt and
~380 with it**, against the ~148 §9's ASCII budget assumes. Add the see-all row
§9's own drawing puts under it and the first tile starts below the bar.

The test asserts what is true and what §9 states as its one hard rule: **the
answer is above the fold** — the all-clear card is fully visible — and the tiles
are reachable. Not fixed by shrinking a component the stylesheet specifies; it
goes to the design sweep with F-10.1.

### Deferred, deliberately

- **The broken-row card has no trigger.** `recomputeVehicle` returns one
  `DueAssessment` per eligible item and cannot report that one of them threw; a
  per-item failure is a change to **EPIC-07's** engine. The card is built and
  asserted directly so the drawing exists the day the engine can say so.
- **The sold panel carries no "Total spent".** §9 shows one; `monthlyCost` and
  `costPerDistance` are **EPIC-13's**, like the two cost tiles. The panel prints
  the ownership line only when BOTH its halves are known — "Owned 6 years · —
  driven" is a sentence with a hole in it.

## Task 10.7 — `reminders.list` ✅ (parity blocked, and named)

`reminders_groups.dart` in `domain/` partitions and sorts; the screen composes
`CalmRowGroup`s of `CalmListRow`s with `CalmSwipeActions` around each. 6 domain
tests, 2 provider tests, 14 screen tests, 4 parity captures.

**`due_copy.dart` moved to `lib/l10n/`.** §9 says this screen speaks "the same
dot/colour/wording vocabulary" as Home and "reuses Home's ICU keys", and
`structure_test.dart` refuses one feature importing another. Two copies of that
mapper would be two vocabularies for one set of states — which is exactly the
legend §9 says the screen must not need. `homeStatusLine` → `dueStatusLine`, and
the same for the anchor line and the action key.

**The ORDER moved to `lib/core/due/due_order.dart`** for the same reason: §9
says this screen sorts "exactly as Home sorts", and two comparators would be two
orders — the second one always being the one a user notices.

### F-10.5 — the artboard groups by DUE STATE; §9's prose groups by tracking

The reference draws five groups with counts — `Overdue 1`, `Due soon 2`,
`On track 1`, `Never recorded 1`, `Not tracked 8 of 14` — each its own card.
§9's *Groups, in order* names three: tracked-and-active sorted by date, then
**Paused**, then **Not tracked**. They are different screens, not different
paint: the artboard's grouping is by STATUS and would put a paused item nowhere,
while §9's is by TRACKING and puts every `ok` item in one long first group.

§9's prose is what this epic built, because it is the product decision stated in
words and it accounts for every row. The artboard's version has something the
prose does not — a count per group — and it goes to the design sweep with F-10.1
and F-10.4 rather than being chosen here by whoever typed last.

Bands: 46/96, 42/98, 46/97, 40/94 against a 75% floor. Colour and theme pass in
all four.

### F-10.6 — a swipe row was 16pt taller than its design

`CalmSwipeActions` stretches its action tiles to the ROW's height, so a row
shorter than a tile overflows it — which a 64pt reminder row did against a
two-line Persian "امروز انجام شد", by 4pt. The fix is a minimum height on the
row derived from the tokens; the FIRST version of it added `s2` above and below
"for breathing room" and made every swipeable row 16pt taller than its design,
visible immediately against this screen's reference. It is now exactly the
content, with each caption line CEILED — a line box is laid out in whole logical
pixels, and the 0.8 two of them gain is the whole overflow.

### Deferred, deliberately

- **Sticky group separators.** §9's "26 items" state pins the headers as the
  list scrolls. The list renders all 26 and scrolls; the pinning is a
  `SliverPersistentHeader` inside `CalmScaffold`'s `ListView`, which is a change
  to the frame every screen shares and is not worth making for one screen's
  polish in this epic.
- **The swipe tiles are all `caution`.** §9 assigns no tones, Calm has exactly
  two, and `danger` is reserved for "destructive, and behind a confirmation of
  its own" — none of these three is. A third, quieter tone is a design question.
- **`Snooze` does nothing yet.** `dialog.snooze` is EPIC-08's global dialog and
  the snooze WRITE is task 10.8's. Named in the switch rather than defaulted.
- **`Done today` pushes `log.service` with the item.** EPIC-11 owns the
  destination; the assertion is the route name plus arguments, which is the
  whole navigation contract this epic can keep.

## Task 10.8 — `reminders.edit` ✅ (parity blocked, and named)

`reminder_draft.dart` in `domain/` holds the form and validates it as a pure
function; `reminders_edit_notifier.dart` loads, saves and deletes;
`reminders_edit_screen.dart` draws §9's field table in its order. 12 domain
tests, 12 screen tests, 4 parity captures.

**`ref.read(streamProvider.future)` hangs with no subscriber.** The notifier's
first version read `.value` in `build()` — null on the first frame, which it
turned into `Missing`: the editor reported that the reminder did not exist, on
every open, before anything had been read. Awaiting the future instead hung,
because a `StreamProvider` nobody listens to never delivers. It now `listen`s
and then awaits — for settings and the garage in `build`, and for the records
and readings once the vehicle id is known. **This is the drift-stream rule from
the other side**: EPIC-09's version was a stream that delivers and leaves a
timer; this one is a stream that never starts.

**The two notice fields shared one accessible name.** §9 asks the question once,
above the pair — but two fields with one name are two a screen-reader user
cannot tell apart, so the days half has `reminderNoticeAheadDays` and no visible
label. A shared visible label is a layout decision; a shared accessible name is
not.

Two changes taken straight from the reference, because both are content and not
just paint: the modal head carries the ITEM's name rather than the word
"Reminder", and the automatic notice window is ONE hint under the pair rather
than the same sentence inside two placeholders.

### F-10.7 — the artboard's form is paired and grouped; §9's prose is a stack

The reference draws `Every 15,000 km` beside `Or every 12 months` under the hint
"Whichever comes first."; **Last done** as a two-row `CalmRowGroup` with a
calendar and an odometer glyph; the notice pair side by side; and both switches
carrying a subtitle ("Off still shows on Home", "Counting from the day it was
done"). §9's prose says only that "labels sit above inputs, never beside them",
which the app satisfies — as a single column.

The single column is what shipped: it is what the prose states, it survives
German at 200% on a 375pt screen, and pairing every field is a layout decision
across fourteen rows rather than a bug. Bands 34/99, 31/99, 37/101, 32/101; the
question goes to the design sweep with F-10.1, F-10.4 and F-10.5.

### Deferred, deliberately

- **`dialog.discard` on a dirty dismiss.** §9 requires it; the draft carries no
  dirty flag yet, and adding one means comparing the draft to the row on every
  keystroke or tracking edits — a real decision, and EPIC-08's dialog is already
  built and waiting. A dismiss closes and writes nothing either way.
- **The date pickers are read-only.** §10 owns the date control every logging
  form shares, and a second calendar built here would be the second in an app
  that ships three. The two date fields render what is stored and are wired to
  the draft.
- **The catalogue picker in create mode.** §9 opens create "with the catalogue
  picker focused"; the form opens with a free-text name and `kind: custom`,
  which is the case the `service_items` CHECK is strictest about. The picker is
  a list of the twenty-five catalogue kinds with their default intervals, and it
  belongs with the seeding EPIC-09 built rather than as a fourteenth control on
  this form.
- **The *Last done* rows do not open the history entry.** §9 makes each "a row
  into the history entry detail" — `history.detail` is EPIC-12's.

## Task 10.9 — recompute, deep links and the performance budget ✅

10 tests. §9 lists seven recompute triggers; **five arrive through the streams
the screen already watches** — a write, a switch, a settings change, an import
commit and the first read are all rows moving — and this task built the two that
do not.

**Local midnight and app resume move a VALUE, not a row.** `todayProvider` holds
the civil date; a timer set to the next local midnight advances it, and a resume
re-reads it, because a phone asleep across midnight gets no timer callback and
waking on yesterday's date is exactly the failure the trigger list exists to
prevent. A duration to the next midnight rather than a periodic day: a periodic
timer drifts across a daylight-saving change, and the one day of the year it is
wrong is the day an hour of it does not exist.

**Both schedulers are armed only in production**, behind `todayTicksProvider`,
the same way the UI-state store is injected. A timer set for up to 24 hours
outlives every widget test — `testWidgets` fails the NEXT test over one still
pending — and `WidgetsBinding.instance` does not exist in a plain `test`, so an
unguarded observer throws on dispose. The BEHAVIOUR is tested without either:
advance the injected clock, call `refresh`, watch the day move.

**A unit change does not churn the stack, and that is the finding.** §9 lists it
as a recompute trigger; it reaches the screen through `settingsProvider`, which
is what renders the unit — but the ORDER of due items does not depend on the
unit they are shown in, so the model does not re-sort. The test says so.

### Deferred, deliberately

- **The deep-link HANDLER.** The pin is built and asserted — a pinned item takes
  the primary slot ahead of an overdue one, and `clear` is a named call so the
  pin cannot outlive its appearance. What is missing is the code that reads a
  notification payload, sets `active_vehicle_id` from it and selects the Home
  tab: **EPIC-16** owns the payload and the tap, and there is nothing yet to
  parse. The three deep-link cases the task names — a reminder link, an odometer
  nudge, a payload naming a deleted vehicle — are assertions about a handler
  that has no input.
- **Memoising `buildHomeStack` on a write generation.** The budget is met
  without it: 26 items build in far under §9's 16 ms, measured over 100 runs in
  a plain test. A memo keyed on a generation counter is a cache with an
  invalidation rule, and §2's "nothing derived is persisted" is the reason this
  epic would rather recompute than hold one. Revisit if a profile ever says so.

## `/simplify` — what four agents found, and what was done

Four agents over this epic's `lib/` and `tools/` diff — reuse, simplification,
efficiency, altitude. **Two findings were defects rather than tidiness**, and one
of them had shipped.

### Applied

- **The last fill-up row was showing the FIRST fill-up.** `fillUpsProvider` is
  ordered `occurred_on DESC, id DESC` — its own doc says "newest first" — and
  Home took `fillUps.last`. On a car with eight years of history the row read
  out a tank of diesel bought in 2018, correctly formatted. Every fixture
  supplied one fill-up, and in a one-element list `first` and `last` are the
  same row. Fixed as `watchLatestForVehicle`, a `LIMIT 1` over the same index,
  so there is no end of a list to pick — and Home stops subscribing an unbounded
  history to draw a 56pt read-out. The ordering is asserted where the `ORDER BY`
  is, against a real database.
- **A snooze that had run out never stopped saying so.** `buildHomeStack` took
  `required CivilDate today` and its body never read it; the card's fourth line
  came from `snoozedUntil` unconditionally. Nothing clears `snoozed_until` when
  it passes — no row is written at midnight — so a card snoozed until 4
  September read "Snoozed until 4 September" for ever after. `until > today`
  now, the same clause `isSnoozed` reads from §3.
- **`ShapeDecoration` walked through the component-hygiene gate.**
  `estimate_popover.dart` assembled a Calm surface in the feature layer and lost
  the sheen doing it; the gate grepped for `BoxDecoration(` only. It greps for
  both now, with a self-test arm that plants the other spelling, and the popover
  is `CalmPopover` on `CalmSurface`.
- **The estimate mark was built two ways.** `odometer_strip` routes the `~`
  through `commonEstimatedValue`; `vehicle_status_line`, one tap away about the
  same reading, still concatenated `'${projected ? '~' : ''}'` in Dart.
  `check_status_encoding.sh` has a rule for exactly this and its pattern matched
  only the prefix spelling. One `formatDistanceFigure`; the pattern takes both;
  a new arm plants the conditional form.
- **F-10.2 was fixed and never asserted.** `home_screen_test` now reads the
  `SnackBar`'s bottom margin and requires it to clear `tabbarH`; deleting
  `AppShell`'s `CalmChromeScope` takes it from 62pt to 12pt. With that pinned,
  the two `Builder`s that existed only to reach the scope from lower down are
  gone.
- **`todayTicksProvider` had nothing asserting the production side.** Deleting
  one line in `bootstrap()` turned off two of §9's seven recompute triggers with
  the suite still green. Asserted from `bootstrap.dart`'s source.
- **The two lists in `due_snapshot_provider.dart`** — the six streams the
  snapshot composes and the six the unreadable check asks `hasError` — are
  gated by a source test rather than by adjacency. They cannot be collapsed:
  the short-circuit on a non-null snapshot is what stops a test that SUPPLIED
  the snapshot from subscribing six drift streams through the side door.
- **`SoldVehiclePanel.owned` and `driven` were required and always null**, so
  `homeSoldOwned` — translated into six locales — was unreachable. Both are
  computed from `purchase_date`/`purchase_odometer` now.
- **`_DateRow.onChanged` was required and never called**, and the row built a
  `TextEditingController` in `build` that was never disposed. **`_seeded`
  guarded nothing** that `putIfAbsent` did not already guarantee. **Three public
  helpers had no callers.** **`dueSeverity` was a third severity ladder** that
  disagreed with `attentionRank` about `ok` versus `unknown`. **`kStaleOdometerDays`
  was declared twice.** **`?? CivilDate.fromDateTime(DateTime(1970))!` was
  inlined three more times** — `CivilDate.epoch` names it once.
- **Four serialised reads in `reminders.edit`** now start together;
  `ReminderEditReady` carries the problems `save()` computed instead of the
  screen recomputing them against a second clock read; `CalmIconButton`,
  `CalmLabelled` and `_updateItem` each replace three or four copies.

### Answered, not applied

- **Home builds a due snapshot for every other vehicle to draw one row.**
  `_otherNeedingAttention` walks the garage, and the common case — nothing due
  elsewhere — is the worst case, because proving that requires checking all of
  them. §4.2.1 requires the row and the arithmetic; there is no cheaper way to
  know than to ask. The scan short-circuits on the first vehicle with work, a
  sold or archived vehicle is skipped outright, and every snapshot it builds is
  memoised and already warm the moment the user switches to that vehicle. The
  garage this app is written for is "a plumber with two vans" (§1), not fifty.
  **A large garage is the case to profile**, and if it costs anything the fix is
  to resolve the row after the first frame rather than to compute it differently.
- **`reminders.edit` reads the whole record and reading history** to show five
  rows and one minimum. A `LIMIT 5` join and a `SELECT MIN` would be cheaper on
  the cold deep-link path — but those two streams are the ones Home already has
  open, so on the common path the current code costs nothing and the targeted
  queries would open two NEW subscriptions beside two warm ones. The trade is
  real and it points the other way once EPIC-16's notification path exists to
  measure. Recorded there rather than guessed at here.
- **The form re-derives on every keystroke** — the automatic-notice window and
  the five last-done rows are rebuilt although neither can change while the form
  is open. Tens of microseconds, on a screen with thirteen controls. The
  reporting agent called it the lowest-value item in its own list and said it
  would take it only if the file were being touched anyway. It was, and it still
  is not worth a field on the State to cache a `Text`.
- **`homeDurationLine` has no years bucket**, so a six-year ownership reads
  "Owned 72 months". The ladder tops out at months because §9 built it for an
  overshoot and a service receipt — spans of weeks — and ownership is the first
  span this app measures in years. A years bucket is six ARB files with their
  plural categories, on a ladder that also words every due date and every
  overdue card. **That is a copy decision and a re-shoot, not a cleanup**, and it
  belongs with the other copy questions rather than in a `/simplify` commit.

### F-8.2 — closed. Both stand-ins were lying, one by a whole tab bar

EPIC-08 shot three dialogs and the vehicle switcher over screens that did not
exist yet, hand-built `HomeBackdrop` and `VehiclesBackdrop` for them, and wrote
the test that would settle it: *"EPIC-09 and EPIC-10 replace them with the real
screens and re-run the three captures. If the parity result CHANGES when they
do, this stand-in was lying — and that is a finding then, not a shrug."*
EPIC-09 did not do its half. This epic did both.

Band edges absent, stand-in → real screen:

| capture | light-ltr | light-rtl | dark-ltr | dark-rtl |
|---|---|---|---|---|
| `vehicle.switcher` | 40% → **30%** | 62% → **58%** | 42% → **30%** | 69% → **64%** |
| `dialog.confirmDelete` | 65% → **59%** | 61% → **53%** | 68% → **64%** | 65% → **60%** |
| `dialog.discard` | 32% → 36% | 37% → 41% | 35% → 34% | 43% → 40% |
| `dialog.snooze` | 36% → 38% | 34% → 38% | 35% → 35% | 36% → 38% |

Three readings, and the middle row is the one worth having done this for.

**`VehiclesBackdrop` drew no tab bar.** The `dialog.confirmDelete` artboard has
one with the fourth item active, and the capture passed no `tab:` — so ten icons
and ten labels' worth of band edges were absent from every confirm-delete
capture and were being attributed to the dialog. That is a stand-in inventing a
screen, and it is worth six points on every combination.

**`HomeBackdrop` was a good forgery of the top of the screen**, which is what
the two dialogs sit over, so they move four points either way — noise.
`vehicle.switcher` is the sheet at the BOTTOM, over the part the forgery got
wrong, and it improves by ten points in LTR.

None of the four passes. What is left is what the screens themselves fail on:
`home` is F-10.1's three design divergences, and RTL still carries F-9.25's
6pt-short reference. A dialog capture cannot be better than the wall behind it —
and now the wall is the real one, so those numbers measure one thing instead of
two.
