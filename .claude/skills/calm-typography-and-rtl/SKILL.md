---
name: calm-typography-and-rtl
description: >-
  Enforces Calm's type and script rules: a nine-step scale with a hard 13px floor, humanist sans
  only and NO monospace anywhere (aligned figures come from FontFeature.tabularFigures, never a
  font change), Vazirmatn bundled as an asset with LicenseRegistry, and under [lang=fa] Vazirmatn
  leading for Latin runs inside Persian too. Six locales ship, three right-to-left: en, de, fr,
  fa, ar, ckb. Numerals and calendars resolve from device REGION not language — Extended Arabic-
  Indic for fa/ckb, Arabic-Indic for ar, Latin for ar-MA, Jalali for fa. Six glyphs mirror and no
  others. German runs ~30% longer and Calm's large type makes it worse, so named components
  reserve two lines. Defers gen-l10n mechanics to i18n-rtl-l10n. Use when adding a user-visible
  string, choosing a text style, formatting a number, date or currency, bundling a font, or
  checking an RTL layout.---

# calm-typography-and-rtl

Calm carries almost all of its hierarchy in *type* — few surfaces, little colour, one big thing per screen — so the type scale is not decoration, it is the layout. This skill owns Calm's typographic content: which nine steps exist, what each is for, the floor beneath them, the two font stacks and when each leads, and everything the six locales do to a line of text. The general mechanics of gen-l10n, ARB parity, directional geometry and input normalisation belong to `i18n-rtl-l10n`; the structure of a `ThemeExtension` belongs to `design-system-structure`. What is here is only what *Calm* decided.

Read the reference for the task at hand:
- `references/the-type-scale.md` — the nine steps with real sizes, heights, weights and the component that uses each; the 13px floor; the three weights in use; em-tracking → logical-pixel conversion; tabular figures; text expansion and the two-line reservations.
- `references/fonts-and-scripts.md` — bundling variable Vazirmatn, the `LicenseRegistry` obligation, the subset range, why `[lang=fa]` uses Vazirmatn for Latin runs too, the Arabic-script metric compensation table, and the coverage test that stops ransom-note text.
- `references/numerals-and-dates.md` — the six locales, the four stored numeral values, region-not-language resolution, the always-Latin fields, Jalali display, relative-date buckets, and money as one atomic isolate.

Run `scripts/check_type_floor.sh` before a PR.

## Non-negotiable rules

1. **Nine type roles, no tenth.** `display · hero · titleLg · title · headline · bodyLg · body · label · caption` — 46/34/27/22/19/17/15/14/13 px, and each one is a `TextStyle` on `CalmType` (`lib/theme/calm/calm_type.dart`). `--fs-title` and `--lh-title` collapse into `CalmType.of(c).title`; a widget never names a size. WHY: Calm's hierarchy is a wide spread with big gaps — 46 down to 13 in nine steps. Every role someone inserts in the middle erodes the contrast that is doing the work.
2. **Nothing below 13. `caption` is the floor and `caption` is not small.** No `fontSize:` under 13 anywhere, including inside `lib/theme/`, including chart axis labels, including a legal footnote. `scripts/check_type_floor.sh` fails the build. WHY: this app is read one-handed at a fuel pump in the rain by someone who is not enjoying the hobby of car maintenance. 11px axis labels are a design that assumes an audience sitting down.
3. **No monospace, anywhere, ever.** Not for the VIN, not for the odometer, not for a code. Columns of figures align with `FontFeature.tabularFigures()` + `FontFeature.liningFigures()` on the *same* humanist face. WHY: Calm's whole voice is one warm humanist sans; a mono face is a second voice that says "machine output", and `tnum` already gives you fixed advance widths without it. (`Instrument`, the sibling system, is where mono figures live.)
4. **Three weights: 400 regular, 500 medium, 600 semibold.** No 700, no italics, no synthetic obliques, no `text-transform`, no all-caps, no underline for emphasis. `--fw-bold: 700` exists in the token file and is used by nothing — do not be the first. The three weights are slots — `CalmType.of(c).regular` / `.medium` / `.semi` — never a literal `FontWeight.w600`. WHY: Arabic script has no italic and synthesised obliques mangle the joins; underlines collide with the descenders of `ج ح خ ر ز ی`; all-caps has no meaning in three of the six locales.
5. **`fa`, `ar` and `ckb` get Vazirmatn for the entire UI — Latin runs included.** One family for the whole tree in those locales, never a Latin-face/Arabic-face pairing. `en`/`de`/`fr` use the platform font (`SPEC.md` §5 *Fonts*). WHY: a mixed pairing makes "VW Golf TDI 2.0" jump baseline and weight inside a Persian sentence; Vazirmatn ships a weight-matched Latin precisely so it does not.
6. **Arabic-script locales take the compensated metrics, not the Latin ones.** Line heights rise across all nine steps (body 1.55 → 1.78, display 1.04 → 1.20), `caption` goes 13 → 13.5 and `label` 14 → 14.5, and **`letterSpacing` is 0**. `CalmType.forLocale()` picks the pair; there is no third variant. WHY: Arabic stacks dots above and drops tails far below the baseline, so a Latin-tuned line box clips them silently, and any tracking at all breaks the cursive joins.
7. **Tracking is stored in `em` and must be multiplied by the step's size.** `--tracking-tight: -0.02em` on `display` is `letterSpacing: 46 * -0.02 = -0.92`, not `-0.02`. WHY: CSS `letter-spacing` in `em` is relative; Flutter's is logical pixels. Porting the number verbatim gives you a 50×-too-tight body and a nearly-untracked display, and both look merely "slightly off" in review.
8. **Digit shaping is the last step of formatting, and it is 1:1 by codepoint.** Format the number (grouping, separators, decimals) through the locale's `NumberFormat`, then map the digit block. Numbers are stored as numbers, never as digit strings. WHY: `SPEC.md` §5 — shaping is a display transform; a 1:1 map means the string length never changes, so a live-echoing field needs no caret adjustment.
9. **VIN, plate, export JSON, filenames and version strings are always Latin digits — plate is verbatim as typed.** Force LTR paragraph direction and LTR isolation on codes, even on an RTL screen. WHY: a VIN is matched character by character against paperwork; RFC 8259 admits ASCII digits only, so a `۴` in a backup is not JSON; and an Iranian plate legitimately contains Persian digits and a Persian letter that we transcribe, never compute.
10. **Never bake a digit into a translated string.** "L/{n} km" with `n = 100`, not "L/100 km". No `label + ": " + value`. Punctuation (`،` `؛` `؟` `٪`) comes from the ARB, never appended in code. WHY: a literal `100` stays Latin on a Persian screen next to shaped digits — one screen, two digit sets, which `SPEC.md` §5 forbids outright. `scripts/check_type_floor.sh` greps the ARB files for it.
11. **Buttons and labels wrap to two lines; they never truncate, ellipsise or auto-shrink.** German runs ~30% longer, French ~20%, and Calm's button label is `bodyLg` (17) inside a 52px pill — the two costs compound. The only shrink exception is a large numeric readout (odometer, cost). Field labels sit **above** inputs, never beside. WHY: `SPEC.md` §5 *Text expansion*; a truncated verb is a button whose action is unknown, and side-by-side labels are where expansion breaks first.
12. **Exactly six glyphs mirror: the back chevron, the disclosure chevron, backspace, swap, undo and prev/next.** `Icons.adaptive`-style directional glyphs flip; the vehicle, pump, oil can, spanner, gauge, clock face, progress ring and every other object glyph has one canonical asset that never mirrors. WHY: `SPEC.md` §5 — a car silhouette is a picture of an object, and mirroring it makes an accidental claim about right-hand drive. Dials do not run backwards in Tehran.

## The scale as Dart

```dart
// lib/theme/calm/calm_type.dart — the ONLY file that may name a size or a family.
// --fs-title + --lh-title collapse into ONE style: CalmType.of(c).title
final t = CalmType.of(context);
Text(vehicle.name, style: t.title);          // 22 / 1.26 / w600 / -0.44px
Text(l10n.oilAndFilter, style: t.headline);  // 19 / 1.32 / w600
Text(l10n.wasDueAt(anchor), style: t.caption); // 13 / 1.45 / w500 — the floor
```

| Role | px / height / weight | Tracking | What uses it |
|---|---|---|---|
| `display` | 46 / 1.04 / 600 | tight | Number pad, odometer readout — nothing else |
| `hero` | 34 / 1.12 / 600 | tight | The one chart headline value |
| `titleLg` | 27 / 1.18 / 600 | tight | Primary due-card status line, large screen titles |
| `title` | 22 / 1.26 / 600 | tight | App-bar, sheet and dialog titles |
| `headline` | 19 / 1.32 / 600 | normal | Card titles, primary due-card title |
| `bodyLg` | 17 / 1.5 / 400 | normal | Row titles, button labels, input values |
| `body` | 15 / 1.55 / 400 | normal | Running text, secondary card status |
| `label` | 14 / 1.4 / 500 | normal | Field labels, chips, section titles, tab labels |
| `caption` | 13 / 1.45 / 500 | normal | Anchor lines, meta, hints. **Never smaller.** |

Full extension — nine styles, the three weight slots (`regular` / `medium` / `semi`), both metric variants, the `of()` assert, `copyWith`, an honest `lerp`, the tabular-figure helper and the strut: `examples/calm_type.dart`.

## Two stacks, one per script

```dart
// Latin locales take the platform font (fontFamily: null) — SPEC §5 Fonts.
// Arabic-script locales take bundled Vazirmatn for EVERYTHING, Latin runs included.
static const _arabicScript = {'fa', 'ar', 'ckb'};

static CalmType forLocale(Locale locale) =>
    _arabicScript.contains(locale.languageCode) ? arabicScript : latin;
```

`CalmType.arabicScript` is not `CalmType.latin` with a family swapped in: it carries the compensated line heights and `letterSpacing: 0` from rule 6. Attach the resolved instance to **both** `ThemeData`s and rebuild the tree from the root on a language change — `SPEC.md` §5 requires no restart, and a locale flip is a rebuild, not a theme animation.

```yaml
# pubspec.yaml — one variable file, wght 100–900. TTF: Flutter does not load woff2.
flutter:
  fonts:
    - family: Vazirmatn
      fonts:
        - asset: assets/fonts/Vazirmatn[wght].ttf
```

`FontWeight` drives the `wght` axis on its own — never add a `FontVariation('wght', …)` beside it. Ship `OFL.txt` and register it (`references/fonts-and-scripts.md`); `design-system-structure` rule 10 owns the general bundling contract.

## Figures: tabular, lining, and never mono

```dart
// The `.num` class as Dart. Applies wherever a figure is compared to another figure:
// odometer, prices, totals, the number pad display, chart values, key/value rows.
TextStyle tabular(TextStyle base) => base.copyWith(
      fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
    );

Text(odometerText, style: tabular(CalmType.of(context).display)); // 46/1.04, digits aligned
```

Verify the bundled face actually ships `tnum` and `lnum` for **both** digit blocks in use — Latin and Arabic-Indic. A face that has `tnum` for `0-9` and not for `۰-۹` gives you a jittering Persian odometer and a stable English one, which is exactly the bug nobody on the team will see.

## What the six locales do to a line of text

| Locale | Dir | Digits | Calendar | Type variant |
|---|---|---|---|---|
| `en` `de` `fr` | LTR | `0-9` | Gregorian | `CalmType.latin` |
| `fa` | RTL | `۰۱۲۳` extarab | **Jalali** | `CalmType.arabicScript` |
| `ar` | RTL | `٠١٢٣` arab (**Latin in `ar-MA/DZ/TN/LY`**) | Gregorian | `CalmType.arabicScript` |
| `ckb` | RTL | `۰۱۲۳` extarab | Gregorian (**Jalali in `ckb-IR`**) | `CalmType.arabicScript` |

The last three columns resolve from the device **region**, not the language subtag, and each is a separate user setting (`SPEC.md` §5). `ar-MA` gets Latin digits and Maghrebi separators; `ckb-IR` gets Jalali and toman. Resolution code, the four stored numeral values, and the always-Latin field list: `examples/numeral_formatting.dart`. How `intl`, `NumberFormat`, ARB plurals and input normalisation actually work is `i18n-rtl-l10n` — do not re-derive it here.

## Anti-patterns

- **`fontSize: 11` on a chart axis label** — the shipped CSS does this in two places and it is a defect, not a precedent. Axis labels are `caption`; if 13 does not fit, the chart is too small or has too many ticks.
- **`fontFamily: 'monospace'` / `'RobotoMono'` / `'Courier'` for the VIN or the odometer** — apply `tabularFigures()` to the existing style instead; the gate rejects the family.
- **Porting `--tracking-tight: -0.02em` as `letterSpacing: -0.02`** — em is relative, Flutter's is pixels. Multiply by the step's size (rule 7).
- **Pairing a Latin display face with Vazirmatn inside a Persian screen** — the baseline and weight jump at every model name. One family for the whole tree in `fa`/`ar`/`ckb`.
- **Latin line heights under Arabic script, or any `letterSpacing` at all** — descenders clip silently and the cursive joins break; use `CalmType.arabicScript`.
- **A fixed-height row or a `SizedBox(height:)` around text** — Arabic line boxes are ~15% taller and 200% text scale is a supported state. Give a `minHeight` and let it grow.
- **`Text(overflow: TextOverflow.ellipsis)` on a button or a tab label** — wrap to two lines; a truncated verb is an unknown action (rule 11).
- **`"L/100 km"` or `"1 reminder"` in an ARB value** — the digits stay Latin next to shaped ones, and the plural is wrong in five of six locales. `{n}` placeholder, ICU plural.
- **Shaping digits before grouping, or storing a shaped string** — shape last, store numbers.
- **`toUpperCase()` at render, or a `Text` with `fontStyle: FontStyle.italic`** — Calm has no all-caps and no italic; in Arabic script both are synthesised and wrong.
- **`google_fonts` for Vazirmatn** — it ships an HTTP path into an app that `SPEC.md` §1 promises has no network.

## Definition of done

- [ ] `scripts/check_type_floor.sh` is clean: no `fontSize` under 13, no monospace family, no `fontFamily` literal outside `lib/theme/`, no baked digit in an ARB message.
- [ ] Every rendered string reads one of the nine `CalmType` roles; no widget names a size, height, weight or family.
- [ ] `CalmType.latin` and `CalmType.arabicScript` both exist, both are attached to both `ThemeData`s, and `forLocale()` picks between them.
- [ ] Arabic-script metrics verified on a golden: no clipped descender in `ژ چ گ ج ح خ ڕ ڵ` at 100% and 200% text scale.
- [ ] Vazirmatn bundled as TTF with the `wght` axis intact, `OFL.txt` shipped and registered via `LicenseRegistry`, no `google_fonts` in the lockfile.
- [ ] Font coverage asserted from the asset's own `cmap` for every codepoint in the `fa`, `ar` and `ckb` ARB files plus `ڕ ڵ ۆ ێ ھ ە ڤ`.
- [ ] Every aligned figure carries `tabularFigures()`; `tnum` verified present for both digit blocks.
- [ ] Numeral and calendar settings resolve from region (`ar-MA` → Latin, `ckb-IR` → Jalali) and are covered by a test.
- [ ] VIN, plate, export JSON and filenames render Latin digits under every setting; no bidi control reaches storage, export or a semantics label.
- [ ] Every screen survives the longest of the six translations at 200% text scale with no truncation and no overlap; buttons wrap rather than shrink.
- [ ] Goldens exist for 6 locales × the 8 screens in `SPEC.md` §5 *Testing*.

## Related skills

- See `calm-design-system` for what Calm is and the routing table to the other five.
- See `calm-tokens` for the `ThemeExtension` set that `CalmType` joins, the asserting `of()` and the no-raw-values gate.
- See `calm-components` for which role each widget renders and the two-line reservations per component.
- See `calm-layout-and-motion` for the 52px touch floor and the spacing rhythm the line boxes sit in.
- See `calm-due-state-and-status` for the status strings whose weight and glyph carry meaning alongside colour.
- See `i18n-rtl-l10n` for gen-l10n, ARB parity, ICU plurals, `NumberFormat`, `normalizeToAscii`, FSI/PDI isolation, directional geometry and the vendored `ckb` delegates. **That skill owns the mechanics; this one owns what Calm does with them.**
- See `design-system-structure` for font bundling, `LicenseRegistry`, `FontWeight`-drives-`wght`, subsetting without instancing, and the per-script fallback cascade.
- See `accessibility-as-code` for never clamping `textScaler`, and for the ≥3-non-colour-signals floor.
- See `widget-golden-and-a11y-testing` for the RTL and text-scale golden suites.

## References

- Flutter API — `TextStyle` (`height`, `letterSpacing`, `leadingDistribution`, `fontFeatures`): https://api.flutter.dev/flutter/painting/TextStyle-class.html
- Flutter API — `FontFeature.tabularFigures` / `liningFigures`: https://api.flutter.dev/flutter/dart-ui/FontFeature-class.html
- Flutter API — `StrutStyle` (`forceStrutHeight`): https://api.flutter.dev/flutter/painting/StrutStyle-class.html
- Flutter API — `TextLeadingDistribution`: https://api.flutter.dev/flutter/painting/TextLeadingDistribution.html
- Flutter cookbook — Use a custom font (bundling, `fontFamilyFallback`): https://docs.flutter.dev/cookbook/design/fonts
- Flutter API — `LicenseRegistry`: https://api.flutter.dev/flutter/foundation/LicenseRegistry-class.html
- Vazirmatn (SIL OFL 1.1, variable `wght` 100–900): https://github.com/rastikerdar/vazirmatn
- Unicode UAX #9 — Bidirectional Algorithm, isolate controls: https://www.unicode.org/reports/tr9/
- CLDR — numbering systems (`latn`, `arab`, `arabext`) and week data: https://cldr.unicode.org/translation/numbers-currency/number-and-currency-patterns
- W3C WAI — WCAG 2.2 SC 1.4.3 Contrast (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- W3C WAI — WCAG 2.2 SC 1.4.4 Resize Text: https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html
