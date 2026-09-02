# Fonts and scripts

Calm has two font stacks and one rule for choosing between them: **the script of the locale decides, and in an Arabic-script locale one family draws everything.**

## The two stacks

```
--font-latin   'Avenir Next', 'Avenir', 'Optima', system-ui, -apple-system,
               'Helvetica Neue', sans-serif      →  Flutter: fontFamily: null (platform font)
--font-arabic  'Vazirmatn', 'Geeza Pro', sans-serif  →  Flutter: 'Vazirmatn', bundled
--font-ui      var(--font-latin), reassigned to var(--font-arabic) under [lang=fa|ar|ckb]
```

`--font-latin` is a web stack of faces we cannot bundle: Avenir Next, Avenir and Optima are Apple system faces, licensed for that platform only. In the Flutter port only its tail survives — `fontFamily: null`, i.e. the platform font: SF Pro on iOS, Roboto on Android. `SPEC.md` §5 *Fonts* makes that the decision, not a compromise: "`en`, `de`, `fr` use the platform font." Accept the Android/iOS difference in Latin locales; do not try to close it by bundling a lookalike.

## Vazirmatn leads for the whole UI in fa / ar / ckb

Including Latin runs inside Persian, Arabic and Sorani text. A Persian sentence containing `VW Golf TDI 2.0` must not change face mid-line: Vazirmatn ships a weight-matched Latin so the baseline and stroke weight stay put. The shipped CSS states it as one reassignment — `[lang="fa"], [lang="ar"], [lang="ckb"] { --font-ui: var(--font-arabic) }` — and the Dart port mirrors it with a whole second `CalmType` instance, not a per-`Text` family override.

Why bundle at all, given both platforms have Arabic fonts (`SPEC.md` §5):

- **Android coverage is OEM-dependent.** Xiaomi, Samsung, Oppo and Vivo substitute or trim AOSP's Noto Naskh Arabic. The Sorani letters `ڕ ڵ ۆ ێ ھ` go missing first, and a letter that falls back mid-word **cannot be joined by the shaper** — the result is ransom-note text, unreadable rather than merely ugly.
- **iOS:** SF Arabic's metrics differ from SF Pro at one type scale (different baselines), and older devices fall back to Geeza Pro, whose `ک` U+06A9 and `ی` U+06CC carry Arabic rather than Persian shapes. `--font-arabic` names Geeza Pro as a fallback; treat it as a last resort we expect never to hit, not a supported rendering.

Fallback family if licensing or the look changes: **Noto Sans Arabic** or **Estedad**. **Not IRANSans** — its licence forbids application embedding.

## Bundling

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: Vazirmatn
      fonts:
        - asset: assets/fonts/Vazirmatn[wght].ttf
```

- **TTF or OTF, not woff2.** The design directory ships `design/_fonts/Vazirmatn.woff2` for the HTML mockups; Flutter's font loader does not read woff2. Take the variable TTF from the upstream release.
- **One variable file, `wght` 100–900** (the `@font-face` in `odova.css` declares that range). `FontWeight` drives the `wght` axis by itself — never add a `FontVariation('wght', …)` beside a `fontWeight`. Calm only uses 400/500/600, so shipping Regular/Medium/SemiBold statics is also legal; the variable file is smaller than three statics.
- **Never `google_fonts`.** It ships an HTTP code path into an app `SPEC.md` §1 promises has no network. `design-system-structure` → `scripts/check_font_bundling.sh` greps for the import.

## The licence obligation

Vazirmatn is SIL OFL 1.1. Ship `OFL.txt` as an asset and register it, so the app's own licences page is honest:

```dart
// In bootstrap, before runApp — see app-startup-and-bootstrap.
LicenseRegistry.addLicense(() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(['Vazirmatn'], text);
});
```

## Subsetting

Shrink the payload, but do not let the subsetter *instance* the font — an instanced variable font is frozen to one weight, and then `FontWeight` and the platform bold-text accessibility flag both stop working, failing only for the user who turned bold text on.

- Keep: Latin-1, **U+0600–06FF**, U+0750–077F, U+08A0–08FF, U+FDF2, **U+200C ZWNJ** (Persian needs it constantly).
- **Exclude U+FB50–U+FEFF presentation forms.** HarfBuzz applies `init/medi/fina/isol/rlig` from the base characters; shipping the presentation block is dead weight and invites a shaper that picks the wrong path.
- Pass `--layout-features='*'` so `GSUB`/`GPOS` survive — dropping them breaks the joins outright — and afterwards assert the `wght` axis still reports min/default/max.

## Coverage is proved from the `cmap`, never from a specimen

Script coverage is not language coverage. A face marketed as "Arabic" can draw Persian flawlessly and still be missing the letters Sorani adds — and a specimen set in Arabic will never show it. Parse the bundled asset's `cmap` in a test and assert every codepoint in the `fa`, `ar` and `ckb` ARB files, plus, explicitly:

```
ڕ U+0695   ڵ U+06B5   ۆ U+06C6   ێ U+06CE   ھ U+06BE   ە U+06D5   ڤ U+06A4
چ U+0686   ژ U+0698   گ U+06AF   پ U+067E   ک U+06A9   ی U+06CC   ‌ U+200C
```

and both digit blocks, U+0660–0669 and U+06F0–06F9. Verify **all four joining forms** render real glyphs, not `.notdef`; medial `ڵ` and the `ھ` variant are what most Arabic fonts get wrong. Recipe and codepoint tables: `i18n-rtl-l10n` → `references/unsupported-locales.md`.

## Metric compensation for Arabic script

Arabic stacks dots above the letter and drops the tails of `ج ح خ ر ز ی` well below the baseline, so a Latin-tuned line box clips them silently. Vazirmatn also runs optically smaller than the Latin platform faces at the same point size. `CalmType.arabicScript` carries these, and nothing else changes:

| Role | Latin height | Arabic-script height | Size |
|---|---|---|---|
| `display` | 1.04 | **1.20** | 46 |
| `hero` | 1.12 | **1.28** | 34 |
| `titleLg` | 1.18 | **1.34** | 27 |
| `title` | 1.26 | **1.42** | 22 |
| `headline` | 1.32 | **1.48** | 19 |
| `bodyLg` | 1.50 | **1.72** | 17 |
| `body` | 1.55 | **1.78** | 15 |
| `label` | 1.40 | **1.60** | 14 → **14.5** |
| `caption` | 1.45 | **1.68** | 13 → **13.5** |

Plus: **`letterSpacing: 0` on every step** (tracking breaks the joins), no italics, no synthetic bold — bundle real weights, because a faux bold mangles the joining strokes.

Never fix a pixel height on a text container in these locales. Give rows a `minHeight` and let them grow, and disable any leading-trim or font-metric override that crops to a Latin cap-height box. Where a line box must be identical across locales (a table column, a chart axis gutter), pin it with `StrutStyle(forceStrutHeight: true)` rather than by fixing the container.

## What to test

RTL goldens at 100% and 200% text scale including a single-line row of `ژ چ گ ج ح خ ڕ ڵ`, and the bidi corpus from `SPEC.md` §5 *Testing*: vehicle `BMW ۳۲۰i`, note `قبض از Shell — €۵۲٫۳۰ (A2)`, workshop `Autohaus Müller`. Add one non-Google Android device (Samsung or Xiaomi) and one older iOS device per release — those are where fallback breaks.
