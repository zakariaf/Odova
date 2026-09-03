# Design

Three candidate design systems for Odova, each covering the **whole app**, so the
choice can be made by looking at a finished product rather than at a mood board.

Same 28 screens, same demo data, same DOM contract in all three. Only the design
language differs.

| | [Garage Slip](garage-slip/system.html) | [Instrument](instrument/system.html) | [Calm](calm/system.html) |
|---|---|---|---|
| **The idea** | A service book, not an app | The car's own screen | Reassurance, in a few large things |
| **Reference** | Workshop docket, stamped service booklet, carbon-copy invoice | Instrument binnacle, head unit | A quiet morning |
| **Type** | Serif headings, monospace figures in columns | Condensed grotesk, huge tabular readouts | Humanist sans, generous |
| **Shape** | 0–2px radius, boxed borders | 4–8px, lit top edge | 20–28px, big soft cards |
| **Elevation** | Hairline rules and double rules. No shadows | Luminance and glow. No shadows | Layered warm diffuse shadow |
| **Colour** | Warm paper, one stamped red | Neutral chrome, colour only as signal | Clay, sand, sage, terracotta |
| **Dark theme** | Deep ink-blue paper, cream type | The real design; light is the adaptation | Warm charcoal-brown dusk |
| **Density** | High — ruled rows, aligned figures | Medium — instrument blocks | Low — three things and a next action |
| **Best if** | The driver keeps every receipt | The app should feel like part of the car | The driver would rather not think about it |

## Files

```
design/<system>/odova.css      the design system: tokens, primitives, components
design/<system>/system.html    the specimen sheet — every token, every component, every state
design/<system>/screens.html   the whole app, 28 screens, one page, with theme and language toggles
design/_fragments/            the artboard sources screens.html is assembled from
design/reference/              340 PNGs (see below)
design/_fonts/Vazirmatn.woff2  bundled, because half the locales are right-to-left
```

Open any `screens.html` in a browser: the bar at the top toggles light/dark and
English/فارسی, so you can compare all four states without regenerating anything.

## The reference images

```
design/reference/<system>/<screen>-<theme>-<dir>.png      28 × 2 × 2 = 112 per system
design/reference/<system>-contact-<theme>-<locale>.png    all 27 on one sheet
```

Every screen in **light and dark**, **LTR and RTL** — 324 screens plus 12 contact
sheets. The contact sheets are what a PR attaches for visual parity; the
per-screen files are what you diff.

The RTL images are real Persian, not mirrored English: Extended Arabic-Indic
digits (۱۸۷٬۴۱۲), the Jalali calendar (۲۴ اسفند for 14 March), toman rather than
euro, and the Latin plate `M-AB 1234` deliberately left unmirrored. That is the
point of shooting them — a design that only survives English is not a design for
this app.

## Regenerating

```bash
cd tools && npm install          # puppeteer-core + sharp, once
cd ..
node tools/build_screens.mjs              # assemble screens.html from design/_fragments/
node tools/shoot_design.mjs               # all systems, or pass slugs
node tools/optimise_png.mjs               # palette-quantise: ~58 MB → ~19 MB
```

`shoot_design.mjs` drives the installed Chrome through puppeteer-core — no browser
download, and no network request at any point.

## The rules these mockups had to obey

- **No `left` or `right` in any layout rule.** Logical properties only, so RTL
  mirrors for free. All three CSS files pass a grep for physical properties.
- **Icons are inline SVG**, from a per-system sprite. Only icons that indicate
  direction carry `.icon--directional` and mirror; a clock, a fuel pump and a
  wrench do not.
- **Never guess in a way that looks like fact** (`SPEC.md` §1). The timing-belt
  card reads `Odova needs a reading to say when` in all three systems and all four
  states, because the app has no history for it. No system was allowed to invent a
  plausible date to make its Home screen tidier.
- **Real data everywhere.** The Golf at 187,412 km, oil overdue by 900 km, 42.8 L
  for €74.20 at 6.4 L/100 km. No `Lorem`, no `Label`, no zero amounts.
