---
name: calm-visual-parity
description: >-
  Gates the built Odova screen against the design reference in design/reference/calm/ — 27
  screens x light/dark x LTR/RTL — so the app matches what was designed rather than merely
  matching itself. A Flutter golden proves the app did not change; it cannot prove the app was
  ever right, and those are different failures. Because the reference is Chrome rendering
  HTML+CSS and the app is Skia, the two are never pixel-identical and a raw pixel diff is a
  heatmap for human eyes, never a gate; what IS decided mechanically is that the screen is in
  the requested theme, that every surface over 0.5% is a Calm token, and that the reference's
  horizontal band edges are all present. Use when building a screen that has a reference
  image, before opening a PR that changes any UI, when a screen looks close but not right,
  when adding or moving a widget on a referenced screen, when a design review says something
  drifted, or when regenerating the reference set after a deliberate design change.
---

# calm-visual-parity

`design/reference/calm/` holds a picture of every screen this app is supposed to have: 27
screens in light and dark, LTR and RTL, 112 images. They were produced from the design
system, not from the app, which makes them the only artefact in the repo that can answer
*"is the built screen right?"* rather than *"is the built screen the same as last week?"*

That distinction is the whole point of this skill. Flutter goldens compare a widget against
a PNG **generated from that widget**. They catch regression perfectly and design drift not
at all: a screen that was wrong on the day it was written has a golden that is wrong in
exactly the same way, and it stays green forever. `widget-golden-and-a11y-testing` owns
goldens and this skill does not duplicate it — the two answer different questions and you
need both.

Read the reference for the task at hand:
- `references/what-parity-can-prove.md` — why Chrome and Skia never agree pixel for pixel,
  which differences are physics and which are bugs, and the three things that *are*
  decidable.
- `references/the-reference-set.md` — the naming scheme, what each of the 28 screens is, the
  palette-quantisation caveat, and how to regenerate the set after a deliberate change.
- `references/capturing-the-app.md` — shooting the built screen at 390x844 @2x so it is
  comparable, in a widget test and on a device.

Run `scripts/check_parity.sh` before a PR that touches a referenced screen.

## Non-negotiable rules

1. **The reference is the authority; the app is the thing under test.** If they disagree, the
   app is wrong until someone deliberately changes the design and regenerates the set. WHY:
   the alternative is that "matches the design" quietly comes to mean "matches whatever we
   built", which is how a design system dies without anyone deciding to kill it.
2. **Never gate on a raw pixel diff.** The reference is Blink rendering HTML+CSS with
   Vazirmatn and Avenir Next; the app is Skia. Glyph rasterisation, subpixel positioning,
   shadow blur and gradient dithering all differ, permanently. `compare_to_reference.mjs`
   prints a differing-pixel percentage and it is **informational**. WHY: a gate that is red
   for reasons nobody can fix is a gate somebody switches off, and it takes the real checks
   with it.
3. **What is gated is theme, colour and bands.** The ground must be a token of the *requested*
   theme; every surface covering more than 0.5% must be within Δ24 of a Calm token; at least
   75% of the reference's horizontal band edges must have an app edge within 4px. WHY: each
   of the three is decidable without reference to how a glyph was rasterised, and together
   they catch the wrong theme, the wrong colour and the wrong geometry.
4. **Colour is compared app-versus-tokens, never app-versus-reference-pixels.** The committed
   references are palette-quantised (`tools/optimise_png.mjs`, 58 MB → 19 MB), so exact token
   hexes do not survive in them. WHY: comparing against a lossy PNG would fail honest code
   and pass dishonest code; the token list in `design/calm/odova.css` is lossless and is the
   real authority.
5. **Δ24 is for quantisation, not for taste.** The tolerance absorbs palette banding and
   gradient dithering. It is far tighter than the gap between any two Calm tokens, so a
   genuinely wrong colour still fails. Widening it to make a screen pass is falsifying the
   test. WHY: the tolerance exists because of a known lossy step, and any other use of it is
   an unrecorded design change.
6. **Both directions and both themes, or the screen is not done.** A screen has four
   reference images and all four are gates. WHY: half the shipped locales are right-to-left,
   and the mirror is where layout bugs actually live.
7. **A deliberate design change regenerates the reference set in the same PR.** Edit
   `design/calm/odova.css`, rebuild `screens.html`, re-shoot, re-optimise, and say in the PR
   what changed and why. WHY: a reference set that lags the design is worse than none — it
   fails honest work and teaches people to ignore the check.
8. **The automated pass is a floor, not the review.** Open the side-by-side sheet and look at
   it. WHY: the three mechanical checks cannot see type weight, letter-spacing, icon shape,
   optical alignment or whether the screen feels calm, and those are most of what the design
   is.

## The loop

```bash
# 1. shoot the built screen at the reference's size (see references/capturing-the-app.md)
flutter test test/parity/home_parity_test.dart          # writes build/parity/home-light-ltr.png

# 2. compare
node tools/compare_to_reference.mjs build/parity/home-light-ltr.png home \
     --theme light --dir ltr

# 3. look at the sheet it wrote: reference | app | difference heatmap
open design/reference/_parity/home-light-ltr.png
```

A passing run says:

```
theme — the ground should be a light token
  ok    #F8F2E9 (36% of the screen) is a light surface
colour — every surface the app paints should be a Calm token
  ok    every surface over 0.5% is within Δ24 of a Calm token
layout — horizontal bands within 4px
  112/112 reference band edges have an app edge nearby
  ok    the vertical rhythm matches the reference
```

## What each failure means

| Message | What is actually wrong |
|---|---|
| `belongs to the dark palette — this build is in the wrong theme` | The harness did not apply the theme, or `ThemeMode` was not pinned in the test. Almost always the test, not the screen. |
| `#XXXXXX covers N% and is not a Calm token` | A raw colour reached a widget, or a token was read from the wrong slot — an `overdue` where the state resolves to `unknown`, say. Check against `calm-tokens` before adjusting anything. |
| `N% of the reference's band edges are absent` | Something is a different height, in a different order, or missing. Read the band count first: a small miss is usually one card's padding; a large one is usually a whole element that did not render. |
| Everything passes but the sheet looks wrong | The expected case for type weight, icon shape and optical alignment. That is what the human pass is for; file it as a finding, do not weaken the tolerances. |

## Anti-patterns

- **Making the reference match the app.** Regenerating the set to clear a failure, without a
  design decision behind it, deletes the only record of what was designed.
- **Raising `--token-tolerance` to pass.** See rule 5.
- **Treating the differing-pixel percentage as a score.** It is 25–45% on a perfectly correct
  screen, because that is how much of a screen is text.
- **Checking only light LTR.** Three of six shipped locales are RTL and dark is a real theme,
  not a filter.
- **Adding a parity check to a screen with no reference.** Add the screen to
  `design/calm/screens.html` and re-shoot first, or the check has nothing to compare against.
- **Running parity instead of goldens.** They catch different things. Goldens catch the
  regression you introduce next week; parity catches the drift you introduced today.

## Definition of done

- [ ] Every screen with a reference image has a parity test for all four combinations.
- [ ] `scripts/check_parity.sh` is clean over `build/parity/`.
- [ ] The side-by-side sheet for each changed screen has been opened and looked at by a human,
      and anything the tool cannot see is either fixed or filed.
- [ ] RTL was reviewed by someone who reads the script, not only by the tool.
- [ ] Any deliberate design change regenerated the reference set in the same PR, and the PR
      says what changed.
- [ ] No tolerance was widened to make a screen pass.

## Related skills

- `widget-golden-and-a11y-testing` — goldens, the `pumpApp` harness, overflow and a11y gates.
  Parity uses that harness to capture; it does not replace the goldens.
- `run-goldens-rebaseline` — the runbook for updating goldens after an intended change.
- `design-review-workflow` — the end-of-build human QA pass. Parity is the per-PR mechanical
  floor beneath it.
- `calm-tokens` — the token values the colour check is decided against.
- `calm-layout-and-motion` — the spacing and geometry the band check is really testing.
- `calm-typography-and-rtl` — why the RTL images are real Persian, and what must mirror.

## References

- `tools/compare_to_reference.mjs` — the comparison tool, and the source of truth for the
  tolerances quoted above.
- `tools/shoot_design.mjs`, `tools/build_screens.mjs`, `tools/optimise_png.mjs` — the pipeline
  that produces the reference set.
- `design/README.md` — the three candidate systems and how the set was made.
