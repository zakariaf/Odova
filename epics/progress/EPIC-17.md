# EPIC-17 — Accessibility, text scale and screen readers

## Task 17.1 — the accessibility lane

The harness is tested before anything is tested with it, and every assertion is
about it FAILING. A harness that silently swallows is worse than none: it turns
a release blocker into a green suite, which is the one outcome nobody recovers
from by reading the code.

**Two things I got wrong writing the self-test, and both are worth keeping:**

- **A `SizedBox` around a `Text` clips silently.** It reports nothing at all. It
  is `RenderFlex` that shouts, so the overflow fixture is a `Column` in a fixed
  height. Worth knowing before writing a test that depends on the shout.
- **A bare `Icon` produces NO semantics node.** There is nothing in the
  semantics tree to find — the icon is announced as silence, which is exactly
  the defect, and only the widget tree knows it is there. So
  `expectEverythingLabelled` walks BOTH: the semantics tree for a button or
  tappable row with no label (what TalkBack actually reads, and where a widget
  whose ancestor excludes it is invisible), and the widget tree for an `Icon`
  with no `semanticLabel` and no `ExcludeSemantics` around it.

`ExcludeSemantics` is the honest way to have an unlabelled icon: it is a claim a
reviewer can check, where a missing label cannot be told from an oversight.

**The matrix is enumerated and named, not counted** — 6 locales × 100%/200% ×
bold on/off = 24 — and built from `odovaSupportedLocales` rather than a literal,
so a locale added to the app cannot be missed here. A dropped locale hides
perfectly well inside an integer and not at all inside a test name.

`accessibleNavigation` follows `boldText` deliberately: both are on when a user
has turned the OS settings up, and a 200% bold screen tested with screen-reader
navigation off is a combination nobody has.

**`test/policy/a11y_bans_test.dart`** refuses the one-line escapes —
`withClampedTextScaling`, `textScaleFactor`, `ignoreOverflowErrors`, and
`FittedBox` outside an allowlist whose single entry (the PDF writer) carries its
reason. All three plantable bans were proven red before being trusted.

## Task 17.2 — the contrast finding, closed

**The owner was asked and chose to fix the tokens**, with the re-shoot in the
same PR. The 2026-09-03 decision deferred this on the grounds that "nobody
building the token layer is in a position to trade Calm's softness for contrast
on the designer's behalf" — still true, so it went to the person who is.

**Seven values moved, and four are failures the finding document does not
describe.** It calls the problem "light-theme only; dark is fine". It is not:

| token | theme | from | to | worst | needs |
|---|---|---|---|---|---|
| `ink-3` | light | `#8B7B6C` | `#6B5F53` | 3.02 → **4.59** | 4.5 |
| `ink-3` | dark | `#9C8B79` | `#B0A18F` | 3.84 → **5.02** | 4.5 |
| `ink-4` | light | `#AC9C8B` | `#7D6C5A` | 1.97 → **3.73** | 3.0 |
| `ink-4` | dark | `#7B6C5C` | `#968776` | 2.49 → **3.63** | 3.0 |
| `focus` | light | `#A8794F` | `#8A5F3A` | 2.82 → **4.11** | 3.0 |
| `chart-axis-ink` | both | followed `ink-3` | followed `ink-3` | — | 4.5 |

Dark `focus` already cleared at 5.85 and did not move.

**EPIC-02's mechanism did the work.** It held the failures as dated exceptions
that assert the pair **still fails**, so changing the values turned eleven
exceptions red at once and forced their removal. The list is empty now and the
comment says to keep it that way — a new entry needs a named person and a date.

**The ramp entries were renamed as well as revalued.** `bark59` → `bark48`,
`bark70` → `bark55`, `bark65` → `bark71`, `bark54` → `bark63`, `amber61` →
`amber51`. The names track lightness, and a name that lies is worse than none.

**The goldens were verified by colour delta, not by eye.** 38 component goldens
moved. Rather than eyeball 38 PNGs I compared every changed pixel against the
old and new token values: all four old tokens vanished, all four new ones
appeared, no image changed size. The ~1,600 other distinct colours are
anti-aliasing on text edges. For a pure colour change that is a stronger check
than looking; it would NOT catch a layout shift, and the unchanged image
dimensions are what rules that out.

**The optimiser walked the whole reference tree** despite being given
`design/reference/calm`, re-quantising `garage-slip` and `instrument` images
that have nothing to do with this change. Reverted, per the rebaseline
runbook's rule 5. Worth fixing in `tools/optimise_png.mjs`, which currently
ignores its path argument.

### What is NOT closed, and is now a §18 question

Dark `ink-3` measures **50.2 Lc** under APCA, up from 39.1. That clears APCA's
45 non-text floor and WCAG AA comfortably, and is still under the 60 APCA asks
for body text. Closing it means lightening tertiary text past the point where it
reads as tertiary — a further design judgement nobody has been asked for, and
not the WCAG failure §17 makes a release blocker. Pinned at the measured value
so the next palette change re-opens it.

## Task 17.3 (partial) — the estimated value, and a warning no blind user got

**The uncertainty rule reached every sighted user and no screen-reader user at
all.** §1.4 puts a `~` in front of every projected figure so somebody can tell
at a glance which numbers the app knows and which it guessed. The odometer strip
built a `Semantics` label for that — `commonEstimatedA11y`, translated in all
six locales since EPIC-04 — and nested it on the figure, where **the label never
reached the semantics tree**. The strip merges into one button node and the
inner label was dropped on the way, so a reader announced "last entered
September 7, 2026" and nothing about the number being a guess.

Two things had to be true for that to hide: the ARB key existed and was called,
so a grep found it wired; and no test had ever read the strip's semantics.

The announcement is now built at the strip's root, as one sentence —
"estimated, about 187,400 km, last entered September 7, 2026". One node is also
what a reader wants: three nodes are three stops on a swipe path through one
row.

**And the label passed the figure WITH its mark**, so even where it did work it
would have said "estimated, about ~187,400 km" — reading the tilde aloud inside
the sentence that exists to replace it. The announcement now takes the plain
body.

`lib/ui/calm/estimated_value_semantics.dart` is the shared form for the next
screen that needs it, with the same rule: the value goes in without its mark,
and the sentence comes from ARB rather than being concatenated in Dart — five of
the six languages do not share English word order and three are right-to-left.

**Still to do in 17.3:** due-card, all-clear and vehicle-surface semantics, and
the "no state announced through colour" sweep. The helper and the strip are the
part where the rule was actually being broken.

## Task 17.3 (rest) — the due card, and a harness that swept an empty tree

The due card announces its item, state and anchor correctly, and every
`DueState` reaches the announcement in words. **I nearly reported the opposite.**

The sweep read `tester.binding.rootPipelineOwner.semanticsOwner`, which is
**null in a widget test even with a live semantics handle**. So the walk found
nothing, and the first run of the due-card test reported that the app's most
important surface "announced nothing at all". It announces perfectly well.

That false negative is worse than no sweep. It sends somebody to fix a screen
that was already right, and it would have reported every screen in the app as
broken — which is the fastest way to get an accessibility gate deleted.

**Worse, it meant half of `expectEverythingLabelled` had never run.** Its
semantics pass was sweeping an empty tree and passing everything; the widget
pass, which walks `Icon` widgets directly, was carrying every assertion in the
self-test on its own. Both halves looked green.

The self-test now has a case only the semantics pass can catch — a tappable node
with no label and no `Icon` in it — so the two halves cannot cover for each
other again. The correct root is the deprecated `pipelineOwner`; the replacement
`SemanticsBinding` has no whole-tree read, and that is written next to the
ignore.

**The lesson worth keeping:** a green harness self-test proved the harness
worked. It proved one of its two passes worked and said nothing about the other,
because every case exercised both and either could satisfy it. A self-test needs
a case that ONLY the mechanism under test can pass.

## Tasks 17.4, 17.6, 17.9 — one sweep, three rules

Three of the epic's tasks ask the same screens three different questions:
does it overflow at 200%, does it announce what it shows, is anything too small
to hit. They are one matrix rather than three near-identical harnesses — the
defects live in the same place, and pumping a screen three times to ask three
questions costs three times as much and finds the same screens.

One `testWidgets` per case, never a loop inside one test: an overflow is
reported once per `RenderObject`, so a loop hides every failure after the first
— which is exactly the shape that makes a sweep look clean.

### The tap-target check was wrong, and I nearly shipped the wrong answer

The hand-rolled version reported `firstrun.language` as having a **756x9** tap
target — the row's TITLE node, on a row whose `minHeight` is 56. The semantics
rect of a label is the height of its own text; what a finger hits is the
hit-test region. I refined it once (measure only the outermost tappable node)
and it STILL reported 756x9, because the title node genuinely is the outermost
node carrying the tap action.

A gate that calls a correct 56pt row a 9pt one gets deleted in a fortnight, and
whoever deletes it is right. So it delegates to Flutter's own
`androidTapTargetGuideline` and `iOSTapTargetGuideline` — both, because the app
ships to both and the floors differ (48 and 44). That is the canonical
implementation and it knows the difference my version did not.

**The lesson is the `/simplify` one again:** I wrote a measuring loop for a rule
the framework already implements, and the bug was in the part I wrote.

### Two real findings, both fixed

- **The language row's selection tick** and **`CalmListRow`'s disclosure
  chevron** were bare `Icon`s: announced as nothing, on every row of every list
  in the app. Both are now `ExcludeSemantics` rather than labelled — the row
  already announces `selected` and its own tap action, so a label would say the
  same fact twice, once as furniture.

### Scope, stated rather than implied

The sweep covers the screens that pump with the app's own defaults —
`firstrun.language`, `settings.about`, `settings.licences`. The rest need
repository fakes, and a sweep that pumps a screen through eight fakes is a sweep
that tests the fakes. **Not done: the remaining 25 screens.** That is the bulk
of 17.4 and 17.6 and it is named here rather than left to look finished.

## Task 17.10 — the gate, and what it refuses to claim

**`test/a11y/gate_coverage_test.dart` tests the SUITE, not the app.** Every rule
of §17's gate is declared with the test that covers it, so a rule nobody wrote a
test for fails — and, more usefully, a rule whose test was *deleted* fails too,
because the file paths are checked to exist.

**It corrected me while I wrote it.** I claimed four of nine rules fully covered;
the count assertion said three. That is exactly why it counts rather than
trusting the prose above it. Three are covered — contrast, the estimated-value
announcement, and the no-confidence-figure rule — and the other six each name
what is missing and which task closes it.

A gate claiming nine of nine while covering three is worse than one claiming
three, because the first stops anybody looking.

**Two assertions exist to stop this epic rotting:**

- The accessibility finding must carry a dated `## Resolution` or `## Decision`.
  A finding carried forward silently fails the build.
- The contrast exception list must be **empty**. EPIC-02 held the WCAG failures
  there as dated exceptions; EPIC-17 emptied it. This is what stops a future
  failure being parked there instead of fixed.

**The `a11y` job is wired into the flutter lane** and its CI comment says what it
cannot prove, at length: a widget test has no screen reader, no real focus ring,
no real device and no native reader — it proves a string arrived, not that it is
grammatical.

**Seen to fail**, per the epic's requirement, by planting both real exclusions:
removing `ExcludeSemantics` from the language row's tick and from
`CalmListRow`'s chevron each turns the sweep red.

**`design/calm/A11Y-SIGNOFF.md` exists and is NOT signed.** Eight human passes
are listed and every one says "not done" — TalkBack, VoiceOver, Switch Access,
three native RTL reads, colour-vision simulation, and 200% on a real device. It
is written now so the work is scheduled rather than discovered, and so a reader
can tell "checked and fine" from "never looked at". `ckb` is named as the
largest single risk, with EPIC-15's 103 unreviewed Sorani strings behind it.

## Tasks 17.7 and 17.8 — colour independence, and traversal order

**17.7 does not simulate a colour-vision deficiency, deliberately.** Simulation
asks "can these two hues be told apart", which is a judgement about a person's
eyes and varies by type and severity. The test asks the stronger and cheaper
question: **is there a second channel at all.** If every state ships words, the
hue question stops mattering — for deuteranopia, protanopia, tritanopia, a
monochrome screenshot, a photocopy, and a phone in bright sun. The CVD
simulation itself is a human pass, listed as not done in `A11Y-SIGNOFF.md`.

The assertion is DISTINCTNESS, not presence. Two states that both announce "Due"
are two states a colour-blind user reads as one — the failure 1.4.1 describes,
and it survives a per-state "has a label" check. All six `DueState` values
announce differently, and `unknown` and `needsOdometer` are asserted apart from
each other specifically: one means no anchor exists, the other means there is
one and the reading is stale, and only the second has a fix the user can perform
in ten seconds.

### 17.8 — I asserted a bug into the suite and caught it

I expected traversal to MIRROR under RTL: `Save` on the left, therefore read
first. It does not, and Flutter is right.

A `Row`'s children are laid out in **logical** order — the first child sits at
the START edge, which is the right under RTL. An Arabic reader going
right-to-left meets `Cancel` first, the same child a left-to-right reader meets
first. The visual positions mirror; the order does not.

Had I trusted the expectation I would have written a failing test against
correct framework behaviour and then "fixed" the app to match it. The wrong
expectation is kept as a comment because it is the intuitive one, and the claim
is now checked against GEOMETRY as well: the first traversed action really does
sit at the start edge — the left in LTR, the right in RTL.

Traversal reads `debugListChildrenInOrder(traversalOrder)` rather than
`visitChildren`, which walks construction order — what a developer wrote, not
what the platform reads.

## Task 17.5 — the chart summary, and the half that is not built

**A painted chart has no semantics at all.** A `CustomPainter` draws pixels, so
a screen reader walking the tree finds an empty box where twelve months of
spending is. There is no widget-level fix and no label to add — the summary has
to be authored, and then it has to be right.

**Computed from the plotted series, never written by hand.** The epic requires
it and the reason is one this project keeps meeting: a hand-written summary and
a painted chart are two representations that drift, and the drifted one is the
one nobody can see.

Two decisions inside it worth reading:

- **The trend is measured against the SPAN, not against the first value.** A 0.2
  change is the whole story on a series that moves by 0.3 and noise on one that
  moves by 4; a fraction of the first value says neither. Mutation-checked in
  both directions.
- **There is a noise floor at 5%.** Consumption wanders between tanks for
  reasons that have nothing to do with the car — a headwind, a cold morning, a
  pump cutting off early. Calling that "trending up" is the app guessing in a
  way that looks like fact, in the one channel a user cannot check against the
  picture.

`lowest` and `highest` are the EXTREMES, not the ends: a chart MARKS the best
and worst points and a mark is not announced, so a series peaking in the middle
would otherwise announce a range it never reached.

Fewer than two points returns null rather than a summary with an invented
direction — the chart renders nothing below two points for the same reason, so
the two agree.

### NOT built, and named in the gate rather than left to look finished

**The accessible data table behind one control, and the wiring.** §17 asks for a
summary *and* a table behind one control on each chart. The summary exists and
is tested; the table does not, and neither chart calls the summary yet.

That is a UI change on two REFERENCED screens — `costs` and `costs.fuel` — so it
moves the band profile and requires re-shooting the reference set, which is the
epic's own instruction. It is the right shape of work for a task that owns those
screens, and doing half of it now would leave a control on two artboards that
the reference set does not have.

`test/a11y/gate_coverage_test.dart` records the row as partly covered with the
gap named, which is the mechanism that stops this being forgotten.

## Task 17.5 (rest) — the table, and the design change I did NOT make

§17 asks for "an accessible data table behind one control". The obvious build is
a segmented Chart/Table control on `costs` and `costs.fuel` — and that is a
deliberate design change to two REFERENCED screens, moving the band profile and
requiring eight re-shot images.

**The chart is the control instead.** §17's first row names "chart tap targets"
alongside the odometer stepper, so a chart is meant to be tappable — and neither
of Odova's was. Making the chart the control satisfies both rows at once and
adds no visible element, so `design/reference/calm/` still describes the app.
Inventing a segmented control would have been adding UI to satisfy a rule that
did not ask for any, and then re-shooting the reference set to match the
invention.

The table opens as a sheet rather than replacing the chart in place: swapping in
place changes the height of a card on a referenced layout, and a taller table
overflows at 200% on the floor device — the exact failure §17's other row is
about.

Three decisions the mutations pin:

- **The painted chart is `ExcludeSemantics`.** §17 says two representations of
  the same data must not both be read. What leaks through an unexcluded chart is
  its axis labels — a bare run of numbers with no idea what they measure.
- **`HitTestBehavior.opaque`.** A line chart is mostly empty space; without it a
  tap between two points falls through, giving a target that measures 300x120
  and behaves like a few thin strokes.
- **Every table cell announces its own column.** A reader landing on a row hears
  "Month: October, Consumption: 6.4 l/100 km" rather than a number whose meaning
  was two swipes ago. A table read as a flat run of values is not a table.

**Still not wired:** the two chart widgets do not call it. That is a change on
the screens EPIC-18 owns, and the gate test records it with the gap named.

---

## `/simplify` and `/code-review`, applied or answered

Both passes ran before the PR. Eight simplify findings and nine review findings;
three of the review's were real defects and are fixed with a test each. What
follows is every finding and its disposition.

### The three real defects

**1 — the placeholder fix never reached the widget.** `calm_field.dart` passed
`colors.ink4` to `hintStyle`: 4.23:1 in light, 4.14:1 in dark, on a field filled
with `surface-2`. Task 17.2 had moved `--color-ink-3` in `odova.css`, in
`calm_palette.dart` and across 116 re-shot reference PNGs, and
`ACCESSIBILITY-FINDING.md` said in as many words that placeholders now point at
the corrected token. Three artefacts agreed and the one that draws the pixel did
not.

`calm_contrast_test.dart` structurally could not catch it. It measures declared
PAIRS, `ink4` is deliberately excluded from `_inks` because its text uses are
SC 1.4.3-exempt disabled states, and at the 3:1 graphic floor where it *is*
declared, 4.23 passes. The palette was right; the widget was wrong; nothing
looked at the widget.

Fixed, and `test/a11y/rendered_text_contrast_test.dart` now reads the colour off
the `RenderParagraph` in both themes. It was seen to fail at exactly 4.23 and
4.14 before the fix. The four `field-*` goldens are re-baselined — the reference
set already rendered the darker placeholder, so the golden was catching up with
the design rather than changing it.

**2 — the one-utterance wrapper deleted §9's popover.** Task 17.3 put
`excludeSemantics: true` on `OdometerStrip`'s root so a reader hears one
sentence instead of three stops. It also collapsed away the inner
`CalmPressable` that opens the estimate popover, leaving a single node with a
single tap action: a TalkBack user who double-tapped the strip got the odometer
ENTRY modal, and §9's "tapping an estimated value opens a transient popover" —
the explanation for the guess — existed for sighted users only.

Restored as a `customSemanticsActions` entry, which keeps the one-utterance win
a second node would undo. `homeExplainEstimateA11y` lands in all six ARBs. Two
tests: the action opens the popover and not the entry modal, and an entered
reading offers no action at all.

**3 — an `unknown` row on `reminders.list` carried nothing but a dot.** Found by
the fix to review finding 5 rather than by the review itself.
`colour_independence_test.dart` hand-wrote six status lines and then asserted
they were distinct — it asserted its own fixture, so the 1.4.1 collision it
exists to catch could not reach it. Rewritten to source every line from
`due_copy.dart`, it went red: `dueStatusLine` returns `''` for `unknown`,
correctly, because Home collapses that state into its own card and never asks —
but `reminders.list` does render it, through `remindersStatusLine`. That row
announced its title and a coloured dot.

`remindersStatusLine` now gives `unknown` the same QUESTION `_endText` already
gives a row with no assessment at all: §9's drawing says a tracked item the app
cannot date gets the question rather than a blank. Seen to fail before the fix.

### Two gates that were themselves wrong

**`expectEverythingLabelled` fired on correct code.** Its icon pass searched for
an `ExcludeSemantics` ancestor by widget type, and `Semantics(excludeSemantics:
true)` is a FLAG on `RenderSemanticsAnnotations` — no such widget is inserted.
Run against the real `OdometerStrip` it reported a chevron that contributes no
semantics node at all. Nothing was red today only because no screen with that
shape is in the sweep yet; EPIC-18 adding `home` is when it would have gone red
on correct code, and the two cheapest ways out are both wrong — label a
decorative chevron so a reader says "chevron right" on every row, or delete the
pass. Both ancestor forms now count, with a self-test.

**`expectTapTargets` has a blind spot, now asserted rather than described.**
Flutter's guideline measures the semantics rect of nodes carrying
`SemanticsAction.tap`. A `Semantics(excludeSemantics: true)` wrapper that does
NOT declare its own `onTap` deletes the undersized node and leaves nothing with
a tap action to measure, so a 12x12 control inside one passes. Both widgets in
this epic with that shape — `ChartAlternative` and `OdometerStrip` — do pass
`onTap`, so their rects are measured and nothing is hidden today. The gate still
cannot see the class of defect it exists for. A real fix needs a hit-test-region
walk and is EPIC-18's; the current behaviour is pinned by a test that will go
red the day that lands, so its removal is the record that the gap closed. The
harness doc claim that "only the framework's matcher knows the difference"
between a semantics rect and a hit-test region was wrong and is corrected.

### Applied without argument

- `ChartSummary.trend` is a getter, not a constructor argument. A stored
  direction is a second place it can be set, and a summary built by hand with
  `up` on a falling series announces the opposite of what the chart draws, to
  the one user who cannot check. Same rule as §2's "derived values are never
  persisted", one layer up.
- `ChartDataTable` asserts on a ragged row instead of clamping the loop to
  `columnHeaders.length`, which silently dropped cells — data missing from the
  only representation a screen-reader user has, with nothing to notice. In
  release, where the assert is compiled out, an unmatched header reads `?`
  rather than vanishing.
- `bark48` and `amber51` measure 49.3 and 52.3 in OKLCH. The file's premise is
  that a primitive's name is "a fact about the pixel, so the name cannot lie",
  and these were the only two of 96 more than 1.0 out. Renamed `bark49` and
  `amber52`.
- Four duplicated semantics walkers hoisted into `walkSemantics`,
  `spokenLabels` and `focusableLabels`; `performCustomAction` joins them, so the
  one deprecated `pipelineOwner` lookup stays in one place instead of a screen
  test growing its own ignore.
- `tap_target_selftest_test.dart` merged into `harness_selftest_test.dart` —
  one file for "does the harness work", not two.
- Three stale `gate_coverage_test.dart` rows corrected, and the
  fully-covered floor is now `kFullyCoveredRows` rather than a literal three
  lines into a test body.
- Stale prose in `calm_contrast_test.dart` (a chevron described as failing when
  it now passes; a hex that no longer exists), the stray `///.` above `amber52`,
  and `ACCESSIBILITY-FINDING.md`'s placeholder claim.
- `.claude/skills/calm-tokens/` documented the replaced palette. The seven
  `calm-*` skills are written for this repo, so this one was answering "what is
  Calm's value for this colour" with the values that failed WCAG. Regenerated
  from `calm_palette.dart`. `contrast-audit.md` keeps its findings verbatim —
  they are the reasoning the new values rest on — with a dated header saying
  which are closed and that no hex should be read out of it.

### Answered, not applied

**"Promote the a11y CI step to its own job or delete it."** Kept, as a
duplicated run. `test/a11y/` and `test/policy/` do run again inside the full
`flutter test` later in the same job — that is about two seconds, and it buys
"the §17 accessibility gate" appearing in the checks list as its own red X.
§17 calls this a release blocker, and a release blocker buried inside a
4,900-test run is one nobody reads the name of. The CI comment now says this
rather than leaving the duplication to look accidental.

**"The six due states should all be announced distinctly."** The original test
asserted this and it is not true of the app, deliberately. `ok` and `dueSoon`
share their wording because §9 puts `reminders.list` in "the same
dot/colour/wording vocabulary" as Home "so no legend is needed"; what separates
them there is the figure, not the phrase. The rewritten test asserts that every
state ships WORDS and that the one pair §2 names — `unknown` versus
`needsOdometer` — never collapses. A six-way distinctness check would pin a
fixture that made them differ and would fail the day the app matched the spec.

**"`ChartAlternative` has no production caller."** True, and it stays true.
Wiring it is a change to `costs` and `costs.fuel`, which are EPIC-18's screens.
The gate row now says so in the words the reviewer used, so §17's chart row is
recorded as satisfied by a component and not by a screen.

**"`traversal_order_test.dart` only pumps a synthetic form."** True. It pins
framework behaviour rather than any Odova screen, and the gate row now says
that instead of the older and wronger claim that traversal order is untested.
Pumping a real screen needs the repository fakes that keep 25 screens out of
the sweep, which is the same EPIC-18 dependency.
