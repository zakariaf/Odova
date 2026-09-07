# Accessibility sign-off

`SPEC.md` §17 calls accessibility "currently the weakest area of this spec and
treated as a release blocker, not a polish item". CI covers the part a machine
can check. This file is the part it cannot, and it is **not signed**.

Nothing below has been done. It is written now, before the release build, so the
work is scheduled rather than discovered — and so that a reader can tell the
difference between "checked and fine" and "never looked at".

---

## What CI proves

The `a11y` job runs `flutter test test/a11y/ test/policy/` on every pull
request. It proves, mechanically:

- Every declared colour pair meets WCAG AA in both themes, with an **empty**
  exception list (`test/theme/calm/calm_contrast_test.dart`).
- An estimated value is announced as words in all six locales, and the `~` is
  never read aloud.
- No confidence tier, percentage or bar reaches an announcement.
- Three screens do not overflow at 200% text scale in German and Arabic, with
  bold text on and off.
- Those screens' tap targets clear Flutter's own Android and iOS guidelines.
- No suppression helper — `withClampedTextScaling`, `textScaleFactor`,
  `ignoreOverflowErrors` — exists anywhere.

## What CI cannot prove, and nobody has checked

| Pass | Who | Status |
|---|---|---|
| TalkBack, Android, whole app | — | **not done** |
| VoiceOver, iOS, whole app | — | **not done** |
| Switch Access traversal of every form | — | **not done** |
| Native `fa` read of every screen | — | **not done** — and see below |
| Native `ar` read of every screen | — | **not done** |
| Native `ckb` read of every screen | — | **not done**, and the largest risk |
| Colour-vision-deficiency simulation, all three types | — | **not done** |
| 200% text scale on a real 375pt device | — | **not done** |

**Why a widget test does not substitute for any of these.** It renders with test
fonts unless told otherwise, it has no screen reader, it has no real focus ring,
and it cannot tell you that a sentence is grammatical — only that a string
arrived. The 200% matrix proves nothing overflows; it does not prove the result
is readable, and those are different questions.

**`ckb` is the largest single risk to the RTL launch.** `CLAUDE.md` §9 says so,
and EPIC-15 added 103 Sorani strings written without a native speaker. Nobody
has read them.

## What is deliberately not covered by CI

Six of §17's nine rules are only partly mechanised, and
`test/a11y/gate_coverage_test.dart` names the gap in each rather than claiming
the row. The three fully covered are contrast, the estimated-value announcement,
and the no-confidence-figure rule.

Outstanding, with the task that closes each:

- The `ƒ` computed badge has no accessible name — EPIC-17 task 17.4.
- Neither chart has a screen-reader summary or a data table — task 17.5.
- One-handed reach of Save is asserted nowhere — task 17.4.
- Traversal ORDER is untested, in either direction — task 17.8.
- 25 of the 28 screens are outside the sweep, because they need repository
  fakes — tasks 17.4 and 17.6.

## Residual, accepted with its reason

Dark `--color-ink-3` measures **50.2 Lc** under APCA — clearing APCA's 45
non-text floor and WCAG AA comfortably, still under the 60 APCA asks for body
text. Closing it means lightening tertiary text past the point where it reads as
tertiary. That is a design judgement nobody has been asked for, and it is **not**
the WCAG failure §17 makes a release blocker; the blocker itself was closed on
2026-09-07. Pinned at the measured value in `calm_contrast_test.dart` so the next
palette change reopens the question.
