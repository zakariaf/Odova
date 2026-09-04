# Odova build epics

Nineteen executable epics that take this repo from a specification with no app to a signed
release a stranger can install. Each one is a document Claude Code executes against: numbered
tasks, the tests before the build, the exact commands that verify it, and a checkbox list that
says when it is finished.

**`SPEC.md` is the source of truth.** The epics are a plan for building what it describes;
they are not a second specification. Where an epic and `SPEC.md` disagree, `SPEC.md` is right.

**They are executed one at a time, in order.** An epic starts only when the one before it is
done — tests green, `/simplify` and `/code-review` closed out, progress file written. Half a
finished epic is not a starting point for the next one.

---

## The rules every epic inherits

Stated once, here, in full. Every epic references this section instead of repeating it, and
every epic is bound by all five.

### 1. TDD, without exception

Write the failing test first. **Run it and watch it fail.** Then write the code that makes it
pass. Every task in every epic lists **Write these tests first** before **Then build**, because
that is the order the work happens in — not because it reads well.

A test that has never been red proves nothing. If you wrote the code first and the test passed
on its first run, delete the code, run the test, see it fail, and write it again. This applies
to the ninth trivial formatter case as much as it does to the due engine.

### 2. Run the tests for every task, not once at the end

Each task carries its own **Verify** commands. Run them when that task is done. A task is not
done while its tests are red, and an epic that batches all its verification into a final sweep
has no idea which of its twelve tasks broke the suite.

`flutter analyze --fatal-infos --fatal-warnings` is part of that per-task loop, not a
pre-release ritual. An info-level lint is a failure here.

### 3. `/simplify`, then `/code-review`, at the end of every epic

Over that epic's changes, in that order — `/simplify` removes what should never have been
reviewed, then `/code-review` looks at what is left.

Findings are **applied or answered in writing**. "Answered" means a sentence in the progress
file saying why the finding is wrong or why the cost is not worth paying. Silently ignoring a
finding is not one of the options, and neither is skipping the pass because the epic felt
small.

### 4. A screen is not done until it matches its reference screenshot

`design/reference/calm/` holds 112 PNGs — 28 screens × light/dark × LTR/RTL — generated from
the design system. They are what the app must look like. **We want the built screen to be the
same as the screenshot, not close to it.**

Every task that builds or changes a screen verifies **all four combinations** with
`calm-visual-parity`:

```bash
flutter test test/parity/<screen>_parity_test.dart      # captures 4 PNGs to build/parity/
bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
open design/reference/_parity/<screen>-light-ltr.png    # look at the side-by-side
```

Be accurate about what that proves. The check gates theme, colour against the Calm tokens, and
the vertical band profile. It does **not** gate a raw pixel diff — the reference is Chrome and
the app is Skia, and 25–45% of pixels differ on a screen that is entirely correct. Nobody
chases a pixel diff to zero. Nobody widens a tolerance either: if a screen genuinely cannot
match its reference, that is a deliberate design change that regenerates the reference set in
the same PR.

And open the side-by-side sheet with your own eyes. The tool cannot see type weight, icon
shape or optical alignment.

### 5. `SPEC.md` wins

Over the code: if they disagree, the code is a bug until a deliberate PR changes the spec.

Over the skills: the 47 skills in `.claude/skills/` decide *how* to build; `SPEC.md` decides
*what*. Where a skill's default and the spec collide, the spec is the product decision and the
skill bends.

---

## The 19 epics

| # | Title | Depends on | Screens | Estimate |
|---|---|---|---|---|
| [01](EPIC-01-scaffold-and-ci.md) | Project scaffold, toolchain and CI | nothing | none | 5 h (CC) · ~5 weeks (human) |
| [02](EPIC-02-calm-tokens-and-theme.md) | Calm tokens and theme | 01 | none | 6 h · ~6 weeks |
| [03](EPIC-03-calm-component-library.md) | The Calm component library | 02 | none | 7 h · ~7 weeks |
| [04](EPIC-04-localisation-and-rtl.md) | Localisation, numerals and RTL | 02 | none | 8 h · ~8 weeks |
| [05](EPIC-05-persistence-and-migrations.md) | Persistence, schema and migrations | 01 | none | 19 h · ~4–5 months |
| [06](EPIC-06-units-money-and-fuel.md) | Units, money and the fuel engine | 05 | none | 14.5 h · ~3–4 months |
| [07](EPIC-07-the-due-engine.md) | The due engine and projection | 06 | none | 8 h · ~8 weeks |
| [08](EPIC-08-app-shell-and-navigation.md) | App shell, navigation and the global dialogs | 03, 04, 07 | 3 — `dialog.discard`, `dialog.confirmDelete`, `dialog.snooze`, the three that belong to no feature | 9 h · ~9 weeks |
| [09](EPIC-09-first-run-and-garage.md) | First run, the garage and vehicles | 03, 04, 05 | 5 — `firstrun.language`, `firstrun.vehicle`, `vehicles`, `vehicle.edit`, `vehicle.switcher` | 11 h · ~11 weeks |
| [10](EPIC-10-home-and-reminders.md) | Home and the reminder screens | 07, 09 | 3 — `home`, `reminders.list`, `reminders.edit` | 11.5 h · ~3 months |
| [11](EPIC-11-logging.md) | Logging: fill-up, service, expense, odometer | 06, 10 | 4 — `log.fillup`, `log.service`, `log.expense`, `log.odometer` | 13 h · ~3 months |
| [12](EPIC-12-history-and-report.md) | History, entry detail and the service report | 11 | 2 — `history`, `report.service` | 12 h · ~12 weeks |
| [13](EPIC-13-costs-fuel-and-trips.md) | Costs, fuel insights and trips | 11 | 4 — `costs`, `costs.fuel`, `trips.list`, `trips.edit` | 13 h · ~13 weeks |
| [14](EPIC-14-settings.md) | Settings, units, language and about | 04, 09 | 5 — `settings`, `settings.language`, `settings.units`, `settings.notifications`, `settings.about` | 7.5 h · ~7–8 weeks |
| [15](EPIC-15-backup-export-import.md) | Backup, export and import | 05, 14 | 2 — `settings.backup`, `settings.import` | 12.5 h · ~3 months |
| [16](EPIC-16-reminders-and-notifications.md) | Reminders and local notifications | 07, 10 | none — it schedules and routes; every deep-link target already exists | 13 h · ~3 months |
| [17](EPIC-17-accessibility-and-scale.md) | Accessibility, text scale and screen readers | 10, 11 | all 28, as a sweep | 14 h · ~3 months |
| [18](EPIC-18-visual-parity-sweep.md) | The visual parity and design review sweep | 09–15 | all 28, as a sweep | 8.5 h · ~8.5 weeks |
| [19](EPIC-19-release.md) | Release engineering and store shipping | 17, 18 | none | 8.5 h · ~8.5 weeks |

Eight epics build the 28 screens — 08 through 15 — and each screen is built exactly once.
Epics 17 and 18 revisit all 28 without owning any of them.

The three global dialogs sit in EPIC-08 because `SPEC.md` §7 groups them as global: they belong
to no feature, and four epics were each planning to build one. EPIC-08 builds all three, once,
in `lib/ui/dialogs/`. EPIC-09, EPIC-10, EPIC-12, EPIC-15 and EPIC-16 **call** them and keep
their own behavioural tests; none of them builds one.

---

## Execution order

**Run them in numeric order, 01 through 19.** The numbering is the dependency order; nothing
in the table above needs an epic that comes after it.

```
design track    01 ── 02 ──┬── 03 ──┐
                           └── 04 ──┤
                                    ├── 08 ── 09 ── 10 ── 11 ──┬── 12 ──┐
data track      01 ── 05 ── 06 ── 07┘                          └── 13 ──┤
                                                                        ├── 18 ── 19
                09 ── 14 ── 15 ─────────────────────────────────────────┤         │
                10 ── 16                                                          │
                11 ── 17 ─────────────────────────────────────────────────────────┘
```

`08` waits on `03` and `07`, and **every screen epic waits on `08`** — the router, the tab bar,
the active vehicle and the modal conventions are what a screen attaches to, and a screen built
before them is a screen built twice. `09` additionally waits on `04` and `05`. `18` waits on all
seven of the epics that follow the shell, `09`–`15`. `19` waits on `17` and `18` — the two
gates.

### What can go in parallel

Only relevant if you have a second executor. There are four genuinely independent pairs:

- **02+03+04 against 05+06+07.** The design track and the data track share nothing after
  EPIC-01. This is the widest fork in the build — roughly 21 h against 41.5 h — and it is
  the one worth taking.
- **03 against 04.** Both need only EPIC-02. The component library and the localisation layer
  touch different directories; EPIC-08 needs only the first of them, so they meet for the first
  time in EPIC-09.
- **12 against 13.** Both need only EPIC-11 and their screen sets are disjoint.
- **14, then 15, alongside the 11 → 12/13 chain.** EPIC-14 is unblocked the moment EPIC-09
  lands; EPIC-16 the moment EPIC-10 does.

### What cannot

- **01 → 02 → 03 is strictly serial.** Tokens are the theme the components read; there is no
  component library to write before `CalmTheme` exists.
- **05 → 06 → 07 is strictly serial.** The fuel engine reads the canonical units the schema
  stores, and the due engine reads the fuel engine's projections.
- **08 before every screen.** One router, one tab bar, one dirty-modal guard, one deep-link
  landing. Building a screen against a shell that does not exist yet means inventing a private
  one and throwing it away.
- **10 → 11.** Logging writes through the same recompute path Home reads. Building them in
  parallel means building that path twice.
- **18 is single-threaded and near-last.** It sweeps all 28 screens against 112 references and
  runs the one structured design review; splitting it defeats its purpose, which is to see the
  whole app at once.
- **19 is last.** Signing, store declarations and the installable artifact come after both
  gates — accessibility (17) and visual parity (18) — have closed.

---

## Before you start any epic

1. **Create the empty progress file** — `epics/progress/EPIC-NN.md`. It starts empty. Append
   one line per task as it completes: what was built, what was deferred, and anything the next
   epic needs to know.
2. **Read the previous epic's progress file.** It is the handover, and it is the only place
   that records what was deferred.
3. **Open `flutter-conventions-index` first.** It is the front door and it routes the rest —
   feature-first layering, dumb widgets, one Notifier per screen, single write path, injected
   `Clock`, typed failures. Then open the epic's own **Skills to load** table, in the order it
   lists them.
4. **Read the epic's `## Where we are now`** and confirm it against the repo. If the state on
   disk does not match, stop and reconcile before writing a line of code.
5. **Confirm a green baseline** — `flutter analyze --fatal-infos --fatal-warnings` clean and
   `flutter test` green — so that the first red you see is one you caused. (Not applicable to
   EPIC-01, which creates the app.)
6. **Re-read `SPEC.md`** for the sections named in the front matter. Not the summary of them
   in the epic — the sections.

---

## The estimate convention

Estimates are in **Claude Code time**, with the human equivalent in the same cell so a person
planning a week can read the number:

> `1 h (CC) · ~1 week (human)`

The calibration is simple: work a human developer would take **about a month** over is roughly
**a day** of Claude Code; **a week** of human work is roughly **an hour**. Values are drawn
from `0.5 h`, `1 h`, `2 h`, `4 h`, `1 d` — there is no more precision than that on offer, and
pretending otherwise helps nobody.

Every epic carries its own total in its front matter, and every task carries its own estimate.

---

## The whole build

**201 h (CC) · ~3.9 years (human)**

That is 25 working days of Claude Code, executed serially. Taking the widest fork — the design
track against the data track after EPIC-01 — brings the critical path to roughly **180 h**.

| Phase | Epics | CC time |
|---|---|---|
| Foundations | 01–07 | 67.5 h |
| The shell | 08 | 9 h |
| Screens | 09–15 | 80.5 h |
| Gates and release | 16–19 | 44 h |
