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
