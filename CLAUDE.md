# Odova

**This file is non-negotiable.** Everything in it is a decision that has already been made.
If you think one of these rules is wrong, say so and change it deliberately — do not work
around it quietly, and do not ask permission to follow it.

Odova is an offline, account-free log for car maintenance, fuel and running costs.
Episode 6 of a 50-app challenge.

---

## 1. The app

Most people look after their car by remembering, and remembering fails. They remember the oil
was changed "sometime last spring", they keep a fuel receipt in the door pocket, and they find
out the timing belt was overdue when it breaks.

Odova replaces remembering with a phone that already knows. You add your car and its odometer
reading. It tracks what has been done and works out what is due next — **by distance and by
date, whichever comes first** — and tells you before it becomes a repair bill instead of a
service.

The home screen answers one question: **what does my car need next?** Everything else exists
to make that answer correct.

**What it does:** service reminders due by distance *and* date · fuel tracking with real
consumption · odometer log · trips and trip expenses · running cost of ownership · full
service history · multiple vehicles.

**Who it is for:** a commuter, a family, a used-car owner, a rideshare driver, a plumber with
two vans. They keep a vehicle five years or more, they do not enjoy this task, and they are
not enthusiasts. They want under a minute a month, and they want to be told, not asked.

Four facts about that person drive every decision (`SPEC.md` §1):

1. **They will not maintain a database.** So the app persists facts and derives everything
   else. The user enters what happened; they never enter a due date, a consumption figure or a
   monthly total.
2. **They log in bad conditions** — at a pump, in the rain, one-handed, in a basement with no
   signal. So the form is short, the odometer is required, and Save is never disabled without
   an explanation.
3. **They forget.** Most of what the app knows will be incomplete. So the app never guesses in
   a way that looks like fact.
4. **Their history is worth money and no server holds a copy.** So data survives every update,
   and the backup is a plain file they can read.

## 2. The rules that outrank everything else

These come from `SPEC.md` §2. Nothing in the codebase may contradict them.

| Rule | What it means in practice |
|---|---|
| **No network, by construction** | No HTTP client, no analytics, no crash reporter, no font CDN, no dependency that transitively opens a socket. Refused permanently: `google_fonts`, `firebase_*`, `sentry_flutter`, `http`, `dio`, any analytics SDK. Fonts are bundled assets. The store listing claims zero network calls and that must be true by construction, not by policy. |
| **No account, no server, no sync** | Backup is a plain, unencrypted JSON file the user keeps. Import **replaces**; there is no merge in v1. |
| **Data survives** | Losing eight years of service history is the worst bug this app can have. Every migration writes a safety copy first, using the *old* schema's writer. |
| **Storage is canonical** | Integer metres, millilitres, watt-hours, grams, and minor currency units plus an ISO 4217 code. Convert on read, never on write. |
| **Derived values are never persisted** | Consumption, cost per km, monthly totals, next-due dates and due status are pure functions computed at read time. A stored due date survives an import and is then wrong forever. |
| **Six locales or none** | `en`, `de`, `fr`, `fa`, `ar`, `ckb` — three right-to-left. Every user-visible string lands in all six ARB files in the same commit. No layout code uses `left`/`right`; it is `start`/`end`. |
| **Never guess in a way that looks like fact** | An estimated odometer is prefixed `~`, a projected date is fuzzy ("around mid-October"), a broken fuel segment is discarded rather than averaged, and an item with no history says `unknown`, never `overdue`. This is the rule most easily broken by accident. |

## 3. How the work is organised

```
SPEC.md          what the app does — 18 sections, the source of truth
  ↓
epics/           19 executable epics, EPIC-01 … EPIC-19, 182 tasks
  ↓
one epic  =  one branch  =  one pull request
  ↓
one task  =  one or more granular commits (tests, then the code that passes them)
```

**`SPEC.md` wins.** If the code and the spec disagree, the spec is right until a deliberate PR
changes it. If a skill and the spec disagree, the spec is this product's decision and the
skill is a general default. Changing the spec is normal and welcome; drifting from it silently
is not.

Read `epics/README.md` before starting anything. It carries the dependency graph and the
execution order.

## 4. TDD — the loop, without exception

Every task in every epic lists its tests **before** its build step, because that is the order
they happen in.

```
1. Read the epic task. It names the tests.
2. Write the failing test.
3. RUN IT AND WATCH IT FAIL.  ← the step people skip
4. Write the smallest code that makes it pass.
5. Run the test. Green.
6. Run the whole suite. Still green.
7. Commit — the test and the code together.
```

**Step 3 is not optional.** A test you never saw fail is a test that may assert nothing; a
typo'd matcher, a wrong import, an `expect` on the wrong variable all pass silently against
working code. If you cannot make it fail, you have not written a test.

**Run the tests for every task, not once at the end of the epic.** A task is not done while
its tests are red, and an epic is a bad place to discover that four tasks ago something broke.

Domain logic — the due engine, the fuel maths, unit conversion, the projection — is **pure
Dart with no Flutter import**, so it tests in milliseconds without a widget harness. If you
need a `BuildContext` in domain code, the layering is wrong.

**Every gate must have been seen to fail.** `tools/check_gates_selftest.sh` plants a real
violation for each gate and asserts both arms. New gate, new self-test — otherwise it is a
comment that runs.

## 5. Branch, commit, PR and merge

One epic, one branch, one pull request, one squash merge. That mapping is not negotiable, and everything below follows from it.

### Branch protection: there is none

```bash
gh repo view zakariaf/Odova --json defaultBranchRef,squashMergeAllowed,deleteBranchOnMerge,mergeCommitAllowed,rebaseMergeAllowed
# {"defaultBranchRef":{"name":"main"},"deleteBranchOnMerge":true,
#  "mergeCommitAllowed":false,"rebaseMergeAllowed":false,"squashMergeAllowed":true}

gh api repos/zakariaf/Odova/rulesets            # []
gh api repos/zakariaf/Odova/branches/main/protection   # 404 Branch not protected
```

`main` has no rulesets and no protection. Nothing on the server stops a push straight to `main`, and nothing stops a merge over a red pipeline. **This discipline is therefore a rule people keep, not one the server enforces.** Every commit in the repo's history so far landed directly on `main`; that stops here — from EPIC-01 onwards the work goes through a branch and a PR, because the review pass and the green pipeline are the only checks there are.

What the repo settings do decide: **squash is the only merge method** (merge commits and rebase merges are both disabled), and **`deleteBranchOnMerge` is true**, so GitHub deletes the remote branch for you.

### One branch per epic, named from the epic id

The branch name is the epic's filename slug — lowercase, no `.md`:

```bash
git switch main && git pull --ff-only
git switch -c epic/05-persistence-and-migrations   # from epics/EPIC-05-persistence-and-migrations.md
```

`epic/NN-<slug>`. One branch per epic, cut fresh from an up-to-date `main`. Never carry two epics on one branch and never open a second branch for the same epic.

### Granular commits inside it — one per task, or finer

A commit is **a task's tests plus the code that makes them pass**. EPIC-05 has nineteen hours of tasks in it; it produces on the order of a dozen or more commits, not one. Never one commit per epic.

That granularity is what the epic model already assumes: each task lists *Write these tests first* then *Then build*, and carries its own **Verify** commands. Commit when a task's Verify is green — analyzer clean, its tests green, and for a screen task its four parity combinations checked. If a task is large enough to have a natural seam inside it (the value object, then the formatter that reads it), commit at the seam. Finer than a task is fine. Coarser than a task is not.

Commit only work that is green at that commit. A commit that knowingly leaves the suite red is a commit that makes `git bisect` useless.

### Commit message convention

The repo already has one; match it. Subject in the imperative, optionally scoped with a `<area>: ` prefix, no trailing period, and short enough to read in a log:

```
epics: 19 executable build epics from SPEC.md, and the screen they were missing
calm-visual-parity: gate the built screen against the design reference
Fix two vendored skills whose frontmatter never parsed
```

Then a blank line and a body that explains **why** — the decision, the failure it prevents, what was considered and rejected. The bodies in this repo are long on purpose: *"The theme check exists because the first version did not have it and a DARK screenshot passed against a LIGHT reference."* That sentence is the value of the commit. "Add theme check" is not. If the why is genuinely self-evident, the body can be one line; it is rarely self-evident.

Reference `EPIC-NN` and the task number where one applies, and cite the `SPEC.md` section when the commit implements one.

Every commit ends with both trailers:

```
Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_<id>
```

Write the message from a file rather than a pile of `-m` flags, so the body keeps its paragraphs:

```bash
git commit -F .git/COMMIT_MSG   # or: git commit  (and write it in the editor)
```

### `/simplify` and `/code-review` run before the PR is opened

Not after. Over that epic's changes, in that order — `/simplify` removes what should never have been reviewed, then `/code-review` looks at what is left. Findings are **applied or answered in writing** in `epics/progress/EPIC-NN.md`; "answered" means a sentence saying why the finding is wrong or why the cost is not worth paying. Silently dropping a finding is not an option, and neither is skipping the pass because the epic felt small.

Fixes from those passes are ordinary commits on the same branch, before the PR exists. A reviewer should never be the first reader of code `/simplify` would have deleted.

### Open the PR when the epic's tasks are done

Push, run the gates locally first so CI is a confirmation and not a discovery:

```bash
bash tools/check_gates_selftest.sh
bash tools/check_release_hygiene.sh
python3 tools/check_spec_examples.py
python3 tools/check_skill_frontmatter.py
git push -u origin epic/05-persistence-and-migrations
gh pr create --base main --title "EPIC-05: persistence, schema and migrations" --body-file .git/PR_BODY
```

Fill in `.github/pull_request_template.md` completely. Every heading is answered, and each one has a reason to exist:

- **What and why** — the change and the problem it solves.
- **Closes** — `EPIC-NN tasks 1–N`. The exact task range this PR closes.
- **Spec** — the `SPEC.md` section implemented. If the spec changed, what was decided and why; `SPEC.md` is the source of truth, not the code.
- **Localisation** — for any user-visible string: all six ARB files, CLDR plural categories, checked in one LTR and one RTL locale.
- **Visual parity** — UI only: light + dark, LTR + RTL, at 200% text scale, with the contact sheet attached.
- **Tests** — what was added, and what the property and golden tests now pin.
- **Deferred** — anything deliberately not done, and why. "Deferred" is a real answer and a good one; it is also what the next epic's handover reads.

An empty heading is an unanswered question, not a formality. If a heading does not apply, say so and say why in one line.

### Wait for every pipeline to finish and be green

`.github/workflows/ci.yml` runs on every pull request, with `concurrency: ci-${{ github.ref }}` and `cancel-in-progress: true` — a new push cancels the run in flight. **A cancelled run is not a green run.** Watch the run for the commit you actually intend to merge.

Three jobs:

| Job | Name in checks | When it runs | What it proves |
|---|---|---|---|
| `repo` | `repo gates` | always | the repo lane, below |
| `app` | `flutter` | only `if pubspec.yaml exists` | format, analyze `--fatal-infos --fatal-warnings`, `pub get --enforce-lockfile`, regenerated `lib/l10n/gen/` matches the ARBs, `flutter test --coverage` with randomized ordering |
| `build` | `android build` | only `if pubspec.yaml exists`, after `app` | `flutter build apk --debug` — the app still compiles for a real target, unsigned on purpose |

The gating is honest and deliberate: the `repo` job emits `has_app` from a `pubspec.yaml` check, and the two Flutter jobs are `if: needs.repo.outputs.has_app == 'true'`. Until EPIC-01 creates the app they **skip**, and skipped is not green — the pipeline says which lane is not yet armed rather than grepping for nothing and reporting success.

The repo lane, which runs on every PR from today:

- `tools/check_gates_selftest.sh` — every gate has been *seen to fail*. It plants a real violation for each gate, asserts red, removes it, asserts green. A gate that has only ever been green is a comment.
- `tools/check_release_hygiene.sh` — no signing material in the working tree **or anywhere in `git log --all`** (which is why checkout is `fetch-depth: 0`). A credential committed and later deleted is in every clone forever.
- `tools/check_spec_examples.py` — the worked examples in `SPEC.md` parse and agree with themselves.
- `tools/check_skill_frontmatter.py` — every skill's frontmatter parses, so it can actually be auto-invoked.
- `python3 -m compileall tools/` and `bash -n tools/*.sh`.

The repo lane finishes in **well under a minute** — recent runs are 13–21 seconds end to end. Once the Flutter lane is armed, `flutter` and then `android build` add minutes, each capped at a 25-minute timeout. There is never a reason to merge without waiting.

Watch it, then check the conclusion:

```bash
gh pr checks --watch                       # blocks until every check settles
gh run watch $(gh run list --branch epic/05-persistence-and-migrations \
                 --limit 1 --json databaseId --jq '.[0].databaseId')
```

```bash
gh pr checks                               # per-check state and conclusion
gh run list --branch epic/05-persistence-and-migrations --limit 1 \
  --json status,conclusion,headSha,url
# want: {"status":"completed","conclusion":"success", …}
gh run view <run-id> --json conclusion --jq .conclusion   # exactly one word: success
```

**A red pipeline is never merged past. A pending pipeline is never merged past.** Not "it's only the formatter", not "the flake will pass on retry", not "I'll fix it in the next PR". `conclusion` must read `success`, on the head commit of the branch, before the merge command is typed. `cancelled`, `failure`, `timed_out`, `action_required` and an empty conclusion are all the same answer: not yet.

### When CI is red: fix forward on the same branch

Read the failure, reproduce it locally, and push the fix as a **new commit on the same branch**. Never merge and fix afterwards, and never disable, loosen or `continue-on-error` a gate to get green — every gate here has a stated contract and has been seen to fail, and a tolerance widened to pass a build falsifies the test.

```bash
gh run view <run-id> --log-failed          # just the failing steps
gh run view <run-id> --job <job-id> --log  # one job in full
```

If the fix is small and belongs to a commit you just made, `git commit --amend` and force-push with lease is acceptable **while the PR has no review comments on it**:

```bash
git push --force-with-lease
```

Once someone has reviewed, append a fix commit instead — never rewrite history under a reviewer.

If CI is red because the *gate* is wrong rather than the code, that is a real and separate change: fix the gate, extend `tools/check_gates_selftest.sh` to plant the violation the gate now catches, and say so in the PR's **Spec** or **What and why** section. New gate, new self-test.

### Merge: squash, delete, pull

Squash is the only method the repo allows, and it is the right one — the branch's granular commits did their job during the work and during review; `main` gets one commit per epic.

```bash
gh pr merge --squash --delete-branch
```

The squash commit's subject and body are the epic's story, written to the same convention as every other commit — imperative subject, a body explaining why, and both trailers. Do not let GitHub concatenate the branch's commit subjects into a bullet list and call it a message.

`deleteBranchOnMerge` deletes the remote branch automatically; `--delete-branch` also removes your local copy. Then return to a clean `main`:

```bash
git switch main
git pull --ff-only
git branch --list 'epic/*'     # should be empty
```

### Only then start the next epic

An epic starts when the one before it is merged to `main` — tests green, `/simplify` and `/code-review` closed out, progress file written, PR squashed, branch gone. Half a finished epic is not a starting point for the next one, and a branch cut from a `main` that is missing its predecessor is a merge conflict being scheduled for later.

Before cutting the next branch, do what `epics/README.md` says to do before any epic: create the empty `epics/progress/EPIC-NN.md`, read the previous epic's progress file (it is the handover, and the only record of what was deferred), open `flutter-conventions-index`, confirm the epic's *Where we are now* against the repo, and confirm a green baseline — `flutter analyze --fatal-infos --fatal-warnings` clean and `flutter test` green — so that the first red you see is one you caused.

## 6. The epic loop, end to end

This is the whole cycle. Do not start the next epic until the current one is merged.

```
1.  git switch main && git pull --ff-only
2.  Read epics/EPIC-NN-*.md in full. Read epics/README.md's inherited rules.
3.  Create the empty progress file:  epics/progress/EPIC-NN.md
4.  Open flutter-conventions-index, then the epic's own "Skills to load".
5.  git switch -c epic/NN-<slug>
6.  For each task, in order:
      a. write the failing test, watch it fail
      b. write the code, watch it pass
      c. run the whole suite
      d. for a screen task: run the parity check, all four combinations, and LOOK at the sheet
      e. commit — granular, the test and its code together
      f. append one line to epics/progress/EPIC-NN.md
7.  /simplify      — over this epic's changes; apply or answer every finding
8.  /code-review   — same; apply or answer every finding
9.  Push. Open the PR. Fill in the template.
10. WAIT for every pipeline to finish green.
11. Squash-merge. The branch deletes itself.
12. git switch main && git pull --ff-only
13. Next epic.
```

Steps 7 and 8 happen **before** the PR is opened, not after. A reviewer's time is not the
place to find what a tool would have caught.

## 7. Visual parity — a screen is not done until it matches

`design/reference/calm/` holds **112 images: 28 screens × light/dark × LTR/RTL**, produced
from the design system rather than from the app. They are what the app must look like. **The
goal is the same, not close.**

Every task that builds or changes a screen ends with:

```bash
flutter test test/parity/<screen>_parity_test.dart      # captures 4 PNGs to build/parity/
bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
open design/reference/_parity/<screen>-light-ltr.png    # then LOOK at it
```

Understand what the check does and does not prove before you argue with it. The reference is
Chrome rendering HTML+CSS and the app is Skia, so **25–45% of pixels differ on a correct
screen** and the pixel diff is a heatmap for your eyes, never a gate. What is gated is the
theme, every surface against the Calm tokens, and the vertical band profile. Do not chase a
pixel diff to zero.

Three rules around it:

- **The reference is the authority.** If they disagree, the app is wrong.
- **Never widen a tolerance to pass.** The Δ24 exists because the committed PNGs are
  palette-quantised, and for no other reason.
- **A deliberate design change regenerates the reference set in the same PR**, and the PR says
  what changed and why. Regenerating to clear a failure you did not intend deletes the only
  record of what was designed.

Both directions and both themes, or the screen is not done. Half the shipped locales are
right-to-left and the mirror is where layout bugs live.

## 8. Do not

- Add a dependency without checking its transitive tree for a network path.
- Store a derived value, a converted unit, or a rounded number.
- Write a user-visible string in only one ARB file.
- Use `left`/`right` in layout.
- Merge a red or pending pipeline.
- Squash an epic into one commit, or split one task's test and code across two.
- Open a PR before `/simplify` and `/code-review` have run.
- Commit signing material. `tools/check_release_hygiene.sh` walks `git log --all`, because a
  credential committed and later deleted is in every clone forever.
- Commit a real backup file as a test fixture. Synthetic fixtures go in `test/fixtures/` named
  `*.fixture.json`.
- Add photos or attachments — withdrawn from v1 (`SPEC.md` §2).
- Reintroduce anything in `SPEC.md` §15 *Explicitly out of v1* without changing the spec first.
- Regenerate a reference screenshot to make a failing parity check pass.
- Widen a tolerance, skip a locale, or mark a task done with a red test.

## 9. Open questions you may hit

`SPEC.md` §18 lists 25 genuinely unsettled questions. Several need a native speaker rather
than an engineering decision — the Kurdish Sorani numeral set, whether `ckb-IR` defaults to
the Jalali calendar, and how a toman-labelled amount reads to an Iranian user. **Sorani
translation quality is the single largest risk to the RTL launch.**

There is also a live accessibility finding in `design/calm/ACCESSIBILITY-FINDING.md`: two of
Calm's light-theme text colours fail WCAG 1.4.3 (`--color-ink-3` at 3.02–3.99:1 across 47
rules, `--color-ink-4` at 2.39–2.60:1 as the placeholder colour). It is unresolved because the
remedy is a design decision, and EPIC-17 must close it rather than carry it further.

When you hit one of these, say so and decide deliberately. Do not pick quietly.

## 10. Skills — all 47, and when to open each

`flutter-conventions-index` is the front door: open it first for any non-trivial task, and follow its routing table from there. The seven `calm-*` skills own this product's design *content* — Calm's palette, type scale, components, due states, layout and parity gates — while `design-system-structure` owns token *structure* (tiers, `ThemeExtension` mechanics, the raw-values gate). Where a skill and `SPEC.md` disagree, the spec wins: the spec is the product decision, the skill is the general default.

**47 skills.** The seven marked **†** are written for this repo (`.claude/skills/calm-*`). The other 40 are vendored from [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) at pinned commit `d88a664` — see `.claude/README.md` for the update procedure.

### Start here — 3

| Skill | Open it when |
|---|---|
| `flutter-conventions-index` | You are starting anything non-trivial and need the house rules plus a pointer to the right deep-dive. |
| `calm-design-system` † | You are about to touch Odova UI and need to know which Calm skill owns the task — or you are tempted by a Material default. |
| `project-structure-and-packages` | You are creating a new file or directory and are unsure where it belongs, or adding a workspace member. |

### Architecture and state — 7

| Skill | Open it when |
|---|---|
| `flutter-architecture` | Deciding folder-vs-package, or which layer a new class belongs in. |
| `scaffold-feature-module` | Adding a whole new screen, tab or feature folder from nothing. |
| `state-management-riverpod` | Adding state to a screen, writing a controller, or chasing a rebuild/disposal leak. |
| `app-startup-and-bootstrap` | Editing `main.dart` / `bootstrap.dart`, reordering cold launch, or chasing first-frame jank. |
| `navigation-and-routing` | Adding a route, a redirect gate, a deep link, or mapping a notification payload to a location. |
| `service-boundary-and-native` | Introducing a side-effect port, injecting `Clock`, adding a platform channel, or wiring a fake in tests. |
| `async-safety` | Writing `await`, touching `BuildContext` after one, or adding a `Timer` / `initState` / `dispose`. |

### The Calm design system — 6

| Skill | Open it when |
|---|---|
| `calm-tokens` † | Adding or renaming a token, editing `ThemeData`/`ThemeExtension`, or asking what Calm's actual value for a colour, size, radius or curve is. |
| `calm-components` † | Building anything under `lib/ui/calm/`, or asking what a Calm widget looks like pressed, focused, disabled or in error. |
| `calm-due-state-and-status` † | Rendering a due item, status dot, badge or estimate — especially deciding how "we do not know" is drawn. |
| `calm-layout-and-motion` † | Laying out a screen, choosing a gap, sizing a tap target, building the all-clear state, or animating anything. |
| `calm-visual-parity` † | A screen looks close but not right, or you are about to open a PR that changes any UI. |
| `design-system-structure` | Deciding how tokens are *shaped* — tiers, `ThemeExtension` vs static class, asserting `of()`, why not `fromSeed`. |

### UI and screens — 8

| Skill | Open it when |
|---|---|
| `widget-composition` | A `build()` has grown too big, or you are splitting a screen into components. |
| `adaptive-layout` | Supporting tablet/foldable, picking a breakpoint, or fixing overflow at a large width. |
| `ui-states-and-feedback` | Writing loading/empty/error/offline UI, or adding a confirmation, Undo or retry. |
| `forms-and-input` | Building a form, wiring validation, or managing focus, keyboard type and controller disposal. |
| `motion-and-haptics` | Adding an animation, a haptic, a celebration or a screen transition — and its reduced-motion fallback. |
| `custom-canvas-and-gestures` | Hand-drawing with `CustomPainter`, or hit-testing gestures over drawn pixels. |
| `accessibility-as-code` | Adding a tap target or icon, encoding state with colour, or reaching for `FittedBox`/`ellipsis` to make text fit. |
| `flutter-performance` | Diagnosing jank, tuning a long list or images, or narrowing rebuild/repaint scope. |

### Data and persistence — 2

| Skill | Open it when |
|---|---|
| `persistence-drift` | Defining or altering a table, DAO, index or CHECK, or reviewing any data-layer diff. |
| `data-export-and-restore` | Touching export, backup, import or restore — including merge-vs-replace policy and validating a picked file. |

### Domain and correctness — 5

| Skill | Open it when |
|---|---|
| `dart3-idioms-and-coding-standards` | Choosing class vs enum vs record vs sealed, writing `copyWith`/`==`, or hitting a length or nesting limit. |
| `error-handling-typed-results` | Writing a `try`/`catch`, a `Failure` type, or a repository boundary that must not lose data. |
| `value-objects-money-and-units` | Storing or converting money, distance or volume — or fixing an off-by-a-cent or unit-drift bug. |
| `local-notifications-scheduler` | Scheduling, re-anchoring, snoozing or debugging a reminder that fired late, early or not at all. |
| `seeded-determinism-and-golden-vectors` | Generating output from a seed or date, or explaining why two devices produced different results. |

### Localisation — 2

| Skill | Open it when |
|---|---|
| `i18n-rtl-l10n` | Adding or translating an ARB key, wiring `l10n.yaml`, or a locale renders LTR or crashes. |
| `calm-typography-and-rtl` † | Adding a user-visible string, picking a text style, formatting a number or date, or checking an RTL screen. |

### Testing and quality — 4

| Skill | Open it when |
|---|---|
| `testing-strategy` | Deciding unit vs widget vs integration, adding a property test, or triaging a flaky suite. |
| `widget-golden-and-a11y-testing` | Writing a harness, adding `matchesGoldenFile`, or chasing an "overflowed by N pixels" failure. |
| `naming-conventions` | Naming a new file, class or role suffix, or ordering imports in a diff. |
| `dartdoc-conventions` | Adding a public API, a `Notifier`, a service interface or a sealed `Failure` that someone else will read. |

### Tooling, CI and release — 6

| Skill | Open it when |
|---|---|
| `lint-and-style-config` | Editing `analysis_options.yaml`, adding an `// ignore:`, or explaining why a lint fires. |
| `codegen-and-toolchain` | Editing `build.yaml`, scoping a builder, or deciding whether generated code is committed. |
| `dependency-hygiene` | Adding a package — including proving it opens no network path — or bumping the SDK. |
| `ci-pipeline-and-gates` | Editing a workflow, adding a gate script, or claiming CI proves something it cannot. |
| `release-and-store-shipping` | Cutting a tag, bumping a version, writing store or privacy copy, or an upload gets rejected. |
| `ads-and-iap-monetization` | Building a paywall, gating an entitlement, or wiring an in-app purchase. |

### Runbooks — 4

| Skill | Open it when |
|---|---|
| `run-codegen` | After a fresh clone, branch switch, or a "missing part file" / "conflicting outputs" error. |
| `run-migration` | Bumping `schemaVersion` or altering a table, and eight years of service history must survive. |
| `run-goldens-rebaseline` | A deliberate visual change broke a golden and someone reaches for `--update-goldens`. |
| `design-review-workflow` | The last build task is done and CI is green, and the feature needs its human design and QA sweep. |
