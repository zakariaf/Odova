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

## Task 11.1 — the log modal shell ✅

7 tests. `/log/:type` rendered `PlaceholderScreen`; it renders `LogModalShell`
now, and four routing tests that asserted the placeholder were re-pointed at the
real screen. `route_table_test`'s id-bearing map drops the log route, following
the precedent that file set when EPIC-09 and EPIC-10 gave `vehicle.edit` and
`reminders.edit` real screens — the path-reading assertion moved to the shell's
own test rather than disappearing.

**Almost none of the chrome needed inventing.** `CalmAppBar.modal` is documented
as "the modal head: Cancel, title, Save (SPEC.md §10)"; `CalmScaffold.tight`'s
doc already names "the five `log.*`" forms as the ones that leave it false; and
`DirtyModalGuard.onDiscard` is one callback "so that EPIC-11's four-segment log
modal inherits that rule instead of deciding it again four times". EPIC-03 and
EPIC-08 built this for a screen that did not exist yet, and it fits.

### F-11.1 — the segment label and the form title are two strings

**The artboard proves it and the English hides it.** `design/calm/screens.html`
renders `modal-head__title` as سوخت‌گیری and the segment bar as سوخت; and
کیلومترشمار against کیلومتر. English has one word for both, so a single
`logSegment*` key looked correct in review and would have forced every RTL
locale to pick which of the two to be wrong about. There are `logTitle*` keys
now, and Persian's values come from the artboard, which CLAUDE.md §7 makes the
authority.

### F-11.2 — German's odometer segment cannot fit and cannot wrap

Measured, not guessed: `CalmSegmented` at 390pt is 390 − 2×22 screen padding −
2×8 track padding, ÷ 4 = **84.5pt per option**, and "Kilometerstand" needs ~98 at
`type.label`. It is one compound with no space and no hyphen, so Flutter cannot
soft-wrap it — it clips, and the two-line reserve `calm-typography-and-rtl`
describes does not save it. The segment reads "Km-Stand"; the full word stays
everywhere it fits. "Tacho" was rejected because the file already uses it for the
dash instrument.

Also flagged and **not** acted on, because both are copy decisions rather than
bugs: English says "expense" here and "cost" in `confirmDeleteBody` for one
entity, and `logDeleteService` says "service record" where its three siblings say
just the noun.

## Task 11.2 — a typed decimal on its way to an integer column ✅

17 tests. **The epic asked for a parser that already existed.** Task 11.2's brief
is `parseDecimalInput` returning Ok/Ambiguous/Empty; EPIC-04's
`normalizeNumericInput` is exactly that, handles every separator and digit set
§10's Field kit lists, and takes its grouping separator as a required argument
because "a default of `,` means every caller that forgets silently gets English
disambiguation, which in `de` or `fa` reads `1,5` as fifteen hundred". A second
parser would have been a second set of rules about `1,234`.

What was genuinely missing is the CONVERSION, and it had the same bug money had
already been fixed for: `(litres * 1000).round()` on 8.7 — which is
8.699999999999999 in binary — loses a millilitre per fill-up. `minorUnitsFrom`
scales by string precisely because its predecessor took half a cent off every
amount ending `.005`; volume, mass and energy borrow that arithmetic rather than
re-deriving it.

The decimal cap is a KEYSTROKE rule, not a Save rule: a field that accepts a
third decimal on a euro amount and rounds it at Save is the app quietly
disagreeing with the receipt in the user's other hand.

## Task 11.3 — the odometer field's rules ✅ (the widget is next)

10 tests. The monotonicity arithmetic did not need writing — `checkReading`
already compares against the neighbours that EXIST rather than a global floor,
which is what lets a used-car buyer type "96,000 km, May 2019" out of a service
book without recording a correction. This adds the four states a form branches
on, plus the one thing the engine has no opinion about: whether the reading is
becoming the vehicle's earliest, which decides whether a delta can be drawn.

### F-11.3 — I argued myself into a duplicate enum and a gate refused it

`OdometerFieldWarning` re-declared `OdometerWarning`'s exact three members, on
the reasoning that a form should not have to know the engine's vocabulary. That
is the kind of argument that sounds principled and produces a second thing to
keep in sync. `one_money_type_test` refuses two enums with one member set, and
it was right.

### F-11.4 — a plural I got wrong in English, caught by a translator

`logOdometerLastEnteredStale` took its count as a plain String and read "1 days
ago" **in English**, before any translation existed. It forced German and French
into a form wrong at 1, and Arabic into one wrong at four of its six categories —
Arabic needs five distinct noun shapes there. `homeStripStale` already solves
this exactly right with an int selector plus a separately formatted figure, and
I had departed from that precedent for no reason.

This is the second consecutive epic in which a translator found a real English
defect (EPIC-09 recorded the first). The pattern is worth naming: the bug is
invisible in English at the counts a developer types by hand, and only becomes
visible when someone has to render it in a language with more than two shapes.

Arabic legitimately drops the number placeholder in `one` and `two` — `يوم واحد`
and the dual `يومين` encode the count lexically, and splicing a numeral in gives
ungrammatical output. That matches `homeStripStale`'s own Arabic, and the rule it
does not break is the one that matters: every digit a user reads still comes from
the formatter.

### F-11.5 — a gate whose stated reason is wrong, and which is still right

`plural_matrix.dart` requires `one` and `other` for Persian and Sorani even
though neither language changes the noun after a numeral, and its header
justifies this with "ICU does not fall back — it throws at format time". The
translator checked: **`Intl.pluralLogic` does not throw when only `other` is
supplied.** The gate's rationale is false as written.

The gate is kept anyway, and not out of inertia: every existing fa/ckb plural in
the repo declares both branches with identical bodies, so the convention is
already universal, costs nothing, and protects against a future translator
editing one branch and not the other. **The header sentence should be corrected
to say that** rather than to claim a throw that does not happen — a gate
justified by something untrue is a gate the next person is entitled to delete.
Recorded for the `/simplify` pass rather than changed mid-task.

### Open, and needing a native speaker

The Sorani terms this task introduced or inherited, flagged by the translator
rather than presented as settled — SPEC.md §18 names Sorani quality as the
largest single risk to the RTL launch, and this is the first concrete evidence:

- **`گەڕاوەتەوە سەرەتا`** for "rolled over" (and Persian's `دور کامل زده است`)
  are literal constructions, not attested automotive idiom.
- **The ckb file spells the odometer three ways** — `ژمارەی کیلۆمێتر` on vehicle
  screens, `کیلۆمەتر` in the log, `کیلۆمەترپێو` in reminders. Pre-existing; one
  term should be chosen and applied everywhere at once.
- **`خزمەتگوزاری` for "service"** is the public-utility sense; speakers say
  `سەرڤیس` for a car service. It appears in five places and changes everywhere
  or nowhere.
- **`لە {date}ەوە`** suffixes `ەوە` onto a formatted date's output. It matches
  `homeEstimatedFrom`, but it assumes the rendered date always ends in a form
  that takes the suffix — which may not hold for Extended Arabic-Indic numerals
  or a Jalali date under `ckb-IR`.

## Tasks 11.4 – 11.8 — partially built, and the parity gate says so

The domain layer and the four bodies exist; the forms behind them do not. What
is on the branch:

- **11.4** `price_trio.dart` and `log_fillup_body.dart`. **No**
  `fillup_draft_notifier.dart`, no `test/features/logging/log_fillup_test.dart`,
  and none of the twenty-one assertions that task lists.
- **11.5** `service_cost_model.dart` and `log_service_body.dart`, called with
  `items: const []` — the chip bar has nothing to draw.
- **11.6** `mark_done.dart` and `service_confirmation_panel.dart`, pure and
  tested, wired to nothing.
- **11.7** `expense_draft.dart` and `log_expense_body.dart`, with
  `categoryLabel: (c) => c.wire` — the category chips render enum wire names.
- **11.8** `log_odometer_body.dart` over `CalmNumberPad`, with no monotonicity
  check, no warnings and no unit-mix-up detection. §10 says the odometer field
  "behaves identically on `log.fillup`, `log.service` and `log.odometer`", and
  on the third one it does not.

**The save path is a stub.** `_PendingSteps implements LogSaveSteps` and writes
nothing, and `_save()` treats its `Ok(null)` as a successful write: it pops the
route and shows the Saved snackbar with an Undo wired to an empty `_undo()`.
Definition-of-done item 3 — "every save is one transaction ending in a due-state
recompute and a notification" — is not met, and the four forms currently
announce a save that did not happen.

**Parity is red on all four screens.** Theme and Calm-token surfaces pass;
60–80% of the reference's band edges are absent against a threshold of 25%.
That is the missing form content, not a tolerance question, and it will not
move until the fields above exist. No tolerance was widened and no reference
was regenerated.

The date picker is also still `void _pickDate() {}` — `date_field.dart` built
its range and default in task 11.3's seam and has no production caller yet.

## The `/simplify` pass

Run over the branch with four review agents (reuse, simplification, efficiency,
altitude). Thirty-one findings, deduplicated to eighteen distinct ones. It was
run early — the epic is not at close-out — but the findings are in the domain
code the remaining tasks build on top of, so they were applied now rather than
on top of four more forms.

**Four were live bugs, each reproduced as a failing test before the fix:**

1. **Money scaled through a double**, in `ExpenseDraft.signedMinorUnits` and
   `ServiceCostModel.sum`, both under comments claiming the arithmetic was done
   by string. `minorUnitsFrom` had already been fixed for this once; its
   reasoning is about scaling a typed decimal to an integer column and is not
   about money, so it is now `scaleByPowerOfTen` and four callers share it.
   `decimal_input._scaled` took a `places` argument and ignored it.
2. **`ExpenseDraft._yearFrom` returned a coverage window ending before it
   started**, two different ways: a 1 January purchase prefilled
   `2026-01-01 → 2025-12-31`, and a 29 February purchase prefilled
   `2028-02-29 → 2028-02-28`. Both made `problems()` report `periodBackwards`
   on a window the user never touched. `CivilDate.addMonths` already did this
   correctly, as it did for `_plusMonths` and `_shiftYears`.
3. **Undo never reached the screen showing the Undo.** Both new soft-delete
   helpers passed `updates: {}` to `customUpdate`, which tells drift no table
   changed. A watching stream saw `[1]` where it should have seen `[1, 0, 1]`.
   §10 makes that snackbar the only confirmation logging gets.
4. **The discard guard could not fire.** `_isDirty()` read a notifier field
   nothing in `lib/` ever wrote, so a user who typed and tapped ✕ lost it
   silently — the exact failure §10's cancel rule exists to prevent, and the
   one EPIC-10 handed to this epic by name.

Plus **the odometer field dropped `OdometerEntry`'s overflow guard**: it
re-derived the parse, and `18446744073709551` came back as 384 metres and was
announced to the user as the vehicle's earliest reading.

**Applied without a behaviour change:** the two soft-delete helpers merged into
`stampLogRowDeleted`; `checkOdometerField` reading the neighbour from the
verdict instead of re-sorting the history; `groupingSeparatorFor` and
`_lastBefore` hoisted out of per-frame recomputation; `problems()` called once
per build instead of three times; the shared `odometerDeltaLine`; the
`dateRow` slot on `log.odometer`; `CalmLabelled` on two chip groups;
`kExpenseCoverageMonths` given its caller; `showSegment` deleted.

**Answered rather than applied:**

- **`PriceTrio.computedField` recomputes to null-check.** The cheap fix reads
  the target field's emptiness, which is only equivalent for a trio produced by
  `edited()` and silently wrong for a directly-constructed one. The correct fix
  stores the value and costs `const` construction across the tests. Task 11.4.
- **`quantityFormsSet` has no production caller.** It is a named seam for
  11.4's "exactly one of `quantity_ml` / `quantity_g` / `energy_wh`" assertion,
  like `PriceTrio.persisted` and `tickedItemIds`. Kept.
- **`log_odometer_body._digits` shapes ten glyphs per build.** A static memo
  would fix it and would also be a never-evicted cache for a marginal gain on a
  six-locale set. Not worth the state.
- **`no_drift_in_signatures_test` does not see `stampLogRowDeleted`'s
  `TableInfo` parameter**, because it only scans members of public classes. That
  matches `softDeleteVehicle` beside it, which takes `AppDatabase`: the rule is
  about the repository API features consume, not about helpers internal to
  `lib/data/repositories/`. Left as-is rather than widened without a decision.
- **The altitude review's largest finding — move all seven pieces of form state
  out of the widget and into the notifier** — is the right shape and is task
  11.4's work, not a cleanup. The half that mattered (the dirty flag being
  unreachable) is fixed; the rest lands when the four draft notifiers are built.

`/code-review` has NOT been run. It runs after the epic's tasks are done, over
the finished code, per `epics/README.md`'s inherited rule 3.

## Tasks 11.4 – 11.8 — built

### The four write paths

Definition-of-done item 3 — "every save is one transaction ending in a due-state
recompute" — is met for all four segments. `FillUpSave`, `ExpenseSave`,
`ServiceSave` and `OdometerLogSave` are shaped like `StripOdometerSave`, which
EPIC-10 established: a `Notifier` with `save` and `undo`, returning a sealed
outcome rather than throwing.

Every one of them was verified by MUTATION and not by being green. Dropping the
quantity, the refund sign, the coverage window, the split lines or the odometer
each fails a specific test; so does inverting `from_due`/`from_actual`, treating
a zero total as negative, and writing CNG as a volume.

Notable decisions:

- **`recompute()` invalidates the due snapshot rather than writing anything.**
  SPEC.md §2 makes every derived value a pure function computed at read time, so
  there is nothing to write. `reschedule()` is empty and belongs to EPIC-16.
- **`OdometerLogSave` deliberately does not reuse `StripOdometerSave`.** That
  notifier carries §9's yield-to-modal outcome, which exists because the strip
  has somewhere to hand the user off TO. This form IS that somewhere, so the
  same outcome would be a loop.
- **The Undo is a callback, not a held row.** Four segments write four record
  types and the snackbar only needs to know how to take one back — and because
  the steps that did the writing set it, a segment that writes nothing cannot
  leave a stale Undo pointing at someone else's row.

### What the reference sheets found that the tests could not

CLAUDE.md §7 says to open the side-by-side and look. Doing so found six defects
no assertion was going to catch:

1. **The price trio was three stacked full-width fields.** §10's sketch and the
   artboard both draw one row of three. Stacked, they read as three unrelated
   money fields; they are one arithmetic, and the `ƒ` badge only means anything
   beside the two values it was worked out from.
2. **Date and More were two cards.** The artboard draws one, with a divider.
3. **The date row was labelled `reminderOnceOnDate`** — "Or once, on date",
   which is `reminders.edit`'s string about a schedule, not the day a thing
   happened.
4. **`log.odometer` had a Date row at all**, where §10 allows two fields and
   nothing else and the artboard puts the date on a pad key beside Save.
5. **`log.expense` had NO date row**, a regression from collapsing the two
   slots into one: that body had a `moreRow` and no `dateRow` to rename, so the
   delete landed and the rename did not.
6. **The category chips scrolled sideways** where §10 says in as many words
   that they "wrap to three rows in German at large text scales and must never
   truncate".

Two more were found by wiring, not by looking: the shell read its vehicle with
`ref.read` on two STREAMS — so on the first frame it got null and never asked
again, and the form would have lived its whole life with no vehicle, no
history, no currency and a save path that wrote nothing — and the odometer field
was handed `existing: const []`, which made the entire rule engine inert on all
three forms that carry it.

### `todayProvider` moved to `lib/app/`

`structure_test` refused the cross-feature import and was right: "two features
share code by lifting it down to core/ or data/, or they meet via a route —
never by importing each other." It started under `features/home/` because Home
was its only reader; §10 dates every log form from the same day, so a clock the
whole app agrees about is app infrastructure.

`pumpShell` gained a `clock:` parameter as a consequence — every test that taps
the tab bar's `+` now mounts a screen that asks what day it is. It is NAMED for
the reason `facts` and `settings` already are: Riverpod refuses two overrides of
one provider, so a caller cannot add its own on top of a harness default. Six
call sites moved, keeping the specific dates their assertions turn on.

## The parity gate — measured, and not met

**`check_parity.sh` is not in CI and has never passed in this repository.**

Run against `main` at `0283d6d` in a scratch worktree, with EPIC-10 merged and
its CI green: **0 of 45 combinations pass.** Every screen from EPIC-08, EPIC-09
and EPIC-10 fails the band profile today, and `.github/workflows/ci.yml` does
not invoke the script. CLAUDE.md §7's "a screen is not done until it matches"
has been enforced by nothing but a person choosing to run it.

Part of the reason is now fixed and is not this epic's: **`parity_capture.dart`
pumped ONCE**, so every capture in the repo was photographed before its
providers delivered — a loading frame compared against a reference full of
content. It pumps three times now, which is shared by all 61 combinations and
took the set from **0/45 on `main` to 6/61 on this branch**: `firstrun.language`
in all four and `vehicles` in both LTR combinations now pass.

This epic's own four screens improved and do not pass:

| screen | before | after |
|---|---|---|
| `log.fillup` | 64–68% absent | 48–60% |
| `log.service` | 67–69% | 60–68% |
| `log.expense` | 71–72% | 55–64% |
| `log.odometer` | 77–80% | 67–72% |

against a threshold of 25%. **No tolerance was widened and no reference was
regenerated.** `captureParity` gained a test-side `settle` hook so a capture can
type the artboard's own values — four of these references draw a screen mid-use,
and an empty trio has no `ƒ` badge and no computed-field caption, so those bands
cannot exist. It is deliberately not a production prefill seam: reproducing the
reference's state is the harness's job, and a parameter added to the real widget
so a screenshot could be taken would be a feature nobody asked for.

**The decision taken, and it is a decision rather than an oversight:** EPIC-11
merges with the parity item deferred, exactly as EPIC-08, EPIC-09 and EPIC-10
did. Holding this epic behind a gate its four predecessors also fail would bury
an EPIC-08/09/10 debt inside an EPIC-11 pull request, and chasing only these
four screens to green would make them the only ones in the app that meet a rule
the app does not keep. The gate is the thing that needs fixing — either wire it
into CI and clear the 55-combination backlog as its own epic, or change what §7
claims. EPIC-18 is the parity sweep and is where that lands; this is written
here so it arrives there as a measured number rather than a surprise.

## Deferred, with reasons

- **Export/import round-trip** (Definition of done item 5) — carried to
  EPIC-15, which builds the writer. `lib/data/backup/` holds only
  `migration_safety_copy.dart`; the epic's preamble was wrong about EPIC-06
  having delivered it.
- **The notification half of item 3** — `reschedule()` is empty. EPIC-16 owns
  the scheduler.
- **Trip on the More sheet** — needs the trip picker and the "only open trips
  and trips whose range contains the fill date" filter. Trips are EPIC-13's.
- **The confirmation panel's five-second auto-dismiss** — it closes on Close
  today.
- **The fuzzy projection in the panel** — it accepts a pre-formatted string and
  the caller passes an exact date. §10 wants "around September 2027" when the
  projection is unmeasured.
- **The duplicate-fill-up prompt** (§10's "You logged a fill-up on 2 September
  … Add this one too?").
- **The coverage-window UI on `log.expense`** — `ExpenseDraft` computes the
  window and `problems()` validates it; the From/To rows and the "Spread across
  12 months" caption are not built.
- **Odometer digit grouping** — the reference shows `187,412` and the field
  shows `187412`. No grouping input formatter exists anywhere in the app; adding
  one is a shared `CalmField` concern with cursor-position subtleties.
- **A weekday in the log date row** — reference "Wed 2 September 2026", app
  "September 2, 2026".

## The `/code-review` pass

Fifteen findings. **All fifteen applied; none answered.** Every one of them
passed 192 green logging tests, which is the point of running the pass at all.

They share a cause worth naming: **state written once and read many times,
where the write and the read disagree about which copy is current.** Nine of
the fifteen are that shape.

**Three made a form unusable:**

1. **An expense could never be saved.** `_expense` is built once with
   `occurredOn: ''` and nothing wrote a date into it. `problems()` does not
   check the date, so validation passed and `ExpenseSave` failed on
   `CivilDate.tryParse('')` — reported to the user as "your phone may be out of
   space", over a Date row showing the correct date the whole time.
2. **The odometer was parsed as km whatever the vehicle's unit.** `100000` on a
   miles vehicle stored 100,000,000 m instead of 160,934,400 — a 38% error into
   the series the due engine reads, under a helper line saying "mi".
3. **Save reported success over a write that never happened.**
   `_PendingSteps.persist()` returned `Ok(null)`, so the modal popped and showed
   "saved" with a dead Undo whenever the pad was empty or the vehicle had not
   loaded.

**Two switches only went one way.** `refunded()` and `split()` had no inverse,
so `on ? x.refunded() : x` made turning either off a no-op. The refund switch
stuck on and kept negating the amount — on the only money field allowed to be
negative. The split switch trapped the user in a record that could not cost
anything: Total read-only, no per-item input rendered, every line written at
zero.

**`_copy` could not clear a field.** `?? this.coversFrom` cannot express "clear
this", so leaving Insurance for Parking kept the old coverage window — which
`problems()` then reported as `periodBackwards` on a window the user never
touched, the exact failure `_yearFrom`'s doc says was fixed.

**`ServiceCostModel.sum` hardcoded two decimals** while `ServiceSave` scales by
the currency exponent. In KWD, lines of 1.234 and 2.345 store 3579 fils and the
sum displayed 3.58 — a total contradicting its own lines.

**The future-date rule could never fire** — `problems(today: _occurredOn)`
compared the entry's date against itself.

**The success snackbar showed the button's label** — "Save fill-up", an
imperative, beside an Undo, after the user had already saved.

**The More sheet discarded the first field edited.** Pushed as its own route, so
the shell's `setState` never rebuilds it; every handler derived from a
`widget.fillUp` frozen at open.

Plus: every persist failure reported as "out of space"; a stale typed Total
under a split; a unit chip that announced itself to a screen reader and did
nothing; `_itemChips()` mutating State during `build`; and a computed trio value
emitted as an ASCII dot and re-read against the locale's grouping separator —
latent only because `_formatsTag` is still hardcoded to `'en'`.

### What testing the More sheet taught

The frozen-draft fix took three attempts to test HONESTLY, and the two failures
are the useful part:

- A `StatefulBuilder` harness that feeds each change back in **rebuilds the
  sheet**, which is exactly what the real route does not do. It passed against
  the broken code.
- Driving it through the real route and reopening it **also** passed against the
  broken code.

The test that works holds `fillUp` constant — the actual production condition —
and asserts on what the sheet emits. Every fix in this pass was then verified by
mutating it back out and watching the test fail; a green test that has not been
seen red against the specific defect it names is not evidence.
