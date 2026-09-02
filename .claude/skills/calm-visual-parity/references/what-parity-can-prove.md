# What a parity check can and cannot prove

## The two renderers are different programs

The reference images are Chrome/Blink rasterising HTML and CSS. The app is Flutter
rasterising through Skia (or Impeller). They disagree, permanently and correctly, on:

| | Chrome | Flutter |
|---|---|---|
| Glyph rasterisation | CoreText/FreeType hinting, its own gamma | Skia's, different gamma |
| Subpixel text position | fractional advances, LCD filtering | grayscale AA in tests |
| `box-shadow` vs `BoxShadow` | a triple-Gaussian approximation | a true Gaussian, σ = blur/2 |
| Gradient banding | dithered | not dithered |
| Border radius antialiasing | its own coverage curve | its own |

On a **correct** screen, 25–45% of pixels differ by more than 30/255 — because that is
roughly how much of a screen is text and shadow. That number is a heatmap for a human, and
using it as a gate means the gate is red on day one and off by day three.

## What is actually decidable

Three things survive the renderer difference, and those are what
`tools/compare_to_reference.mjs` gates:

**1. Theme.** The single largest surface on a screen is its ground. Take its colour, and ask
which palette it belongs to. If a build shot as `--theme light` grounds on `#1D1815`, that is
`--color-bg` from the dark block and the build is in the wrong theme — no amount of glyph
difference explains a 36%-coverage surface from the wrong palette. This check exists because
without it a dark screenshot passes every other test against a light reference: the layout is
identical and dark colours are tokens too.

**2. Colour.** A token is an exact value. Every colour covering more than 0.5% of the screen
must be within Δ24 (summed channel distance) of some Calm token. The tolerance absorbs
palette quantisation and gradient dithering, and it is far tighter than the distance between
any two Calm tokens — the closest pair in the light palette is 34 apart, so a genuinely wrong
colour cannot hide inside it.

Note the direction: the comparison is **app against the token list in
`design/calm/odova.css`**, never app against the reference PNG's pixels. The committed
references are palette-quantised, so exact token hexes do not survive in them; comparing
against them would fail correct code.

**3. Bands.** Reduce each image to one mean-luminance value per row, then find the rows where
that value steps by more than 2/255. Those edges are where a card starts, a divider sits, a
tab bar begins. Text moves the mean by far less than a surface change does, so the profile is
substantially renderer-independent. At least 75% of the reference's edges must have an app
edge within 4px.

This is what catches a card that is 128pt instead of 148pt, a missing row group, or a screen
whose elements are in the wrong order.

## What is not decidable, and must be looked at

The tool is silent on all of this, and it is most of what a design is:

- type weight, letter-spacing, and whether a line wrapped where it should
- icon shape, stroke width, optical centring
- whether a shadow reads as soft or as a hard edge
- horizontal position (the band profile is vertical only — a card indented 8pt too far passes)
- anything inside a band that keeps the band's mean luminance
- whether the screen feels calm

Open the side-by-side sheet. The third panel is the difference heatmap: ignore the text
speckle and look for solid blocks, which mean a surface moved or changed size.

## Why not add a horizontal band check too

It was tried and it is noisy: RTL mirrors the column profile, and a single centred glyph run
shifts it enough to trip a tolerance loose enough to be useful. Vertical rhythm is where Calm
actually lives — one primary thing, then spacing — so the vertical profile earns its place
and the horizontal one did not.
