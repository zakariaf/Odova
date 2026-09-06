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
