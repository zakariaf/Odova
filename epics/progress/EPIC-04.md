
- 4.2 the three `ckb` delegates — 9 tests. **Changed `ckbFrameworkFallback`
  from `ar` to `fa`**, which EPIC-01 shipped as `ar` and explicitly left to this
  epic. `fa` is right: Sorani and Persian share the Perso-Arabic letterforms
  Sorani actually uses — `ک`, `گ`, `ی` — which Arabic writes `ك` and has no
  equivalent of, so Arabic chrome beside Sorani copy renders two shapes of the
  same letter on one screen. Still a compromise, and the doc comment says so.

  **Correction to the epic's premise.** Task 4.2 says
  `GlobalWidgetsLocalizations` "claims every locale"; measured on Flutter
  3.44.6, `isSupported(Locale('ckb'))` is **false**. The trap is real but its
  mechanism is the other one: with no `WidgetsLocalizations` delegate claiming
  `ckb`, Flutter falls back to `DefaultWidgetsLocalizations`, which hardcodes
  `TextDirection.ltr`. Verified by deleting the vendored Widgets delegate and
  watching both direction tests go red.

  Android's `res/xml/locales_config.xml` + `android:localeConfig` added — without
  it Odova is absent from Android 13's per-app language picker entirely. Both
  platform manifests are now asserted against `odovaSupportedLocales`, because
  neither is reachable from Dart at runtime and nothing else in the suite can
  notice them drifting.

- 4.3 locale resolution — `lib/core/l10n/locale_resolution.dart` (pure Dart, no
  Flutter import, runs under `dart test`) plus `lib/l10n/locale_controller.dart`
  as the seam to the widget tree. 19 tests, every row of SPEC §5's table
  including `ku`/`kmr`/`ku-TR` → `en` LTR.

  **The strings/formats split is the substance.** They are two answers, not one:
  `de-AT` reads German and formats Austrian; `pt-BR` reads English and formats
  Brazilian. Falling back to `en` formats as well would put a Brazilian on US
  date order and dollars, so `resolveLocaleTags` returns a pair and the app has
  two providers.

  **Defect found by its own test:** the change event was a bare
  `LocaleAffectingChange` enum in state, and Riverpod notifies on a value
  CHANGE — so `de → fr → fa` fired once, not twice, and every scheduled
  notification body would have stayed in the first language. It carries a
  sequence now. The test that caught it was originally a widget test and was
  measuring the wrong thing: a language change rebuilds from the root, so a
  listener registered in a `Consumer`'s build is disposed and re-registered
  around the very change it is watching. It is a `ProviderContainer` test.

  `OdovaApp` is a `ConsumerWidget` now and watches the resolved locale, so three
  tests that pumped it bare needed a `ProviderScope` — the honest consequence of
  the app having state.

- 4.4 numerals — `lib/core/l10n/numerals.dart` and `numeric_input.dart` (pure,
  under `dart test`), `lib/l10n/numerals.dart` for the intl side and the
  `CalmFigure`/`CalmCode` widgets. 41 tests.

  **Two real defects found by SPEC's own verified-output table**, both silent:

  1. `NumberFormat.decimalPattern('ar_MA')` does not throw and does not fall
     back to `ar` — `intl` carries no `ar_MA`, so it falls back to **en_US**,
     and every Maghreb amount rendered `1,234.56`: American separators under an
     Arabic UI. `numberFormatLocale` now verifies the tag and falls back to the
     LANGUAGE. `intl` has no European-separator Arabic at all, so the Maghreb
     borrows German's number symbols — SPEC §5's verified `1.234,56` is exactly
     German's shape. A second documented borrow beside `ckb` → `fa`.
  2. `groupingSeparatorFor` scanned the formatted string for the first
     non-`[0-9]` character, which trips over the very digits it exists to serve:
     `۱٬۰۰۰` has no ASCII digit in it, so it returned the leading `۱`. It folds
     to ASCII first.

  **Deliberate strengthening of SPEC's pseudocode.** §5 says "one separator
  char appears more than once: it is grouping, remove all", which reads
  `1,23,456` as `123456`. That is Indian grouping, which none of the six locales
  use, so reading it as anything is a guess — and this function's whole contract
  is that it does not guess. The groups must be regular threes or the input is
  rejected as `ambiguous`. The epic's own test list asks for exactly this
  ("Fails if the function returns a number for `1,23,456`"), so the epic and the
  spec's pseudocode disagree and the epic is right.

  **TDD note, honestly.** The normaliser was written before its tests, which is
  the wrong order. `tools/check_numeric_input_selftest.sh` compensates by
  mutating each of the five load-bearing branches and asserting the suite goes
  red — the rightmost-separator rule, the Arabic separator mapping, the
  locale's grouping character, the irregular-grouping rejection, and digit
  folding. All five verified, wired into CI.

- 4.5 calendars — `lib/core/l10n/jalali.dart` (the pinned arithmetic),
  `calendar.dart` (resolution, month names, region tables) and
  `relative_date.dart` (bucketing). 26 tests, all pure.

  **A transcription bug the 73,000-day round-trip caught and no anchor would
  have.** My first `jdnToGregorian` — transcribed from jalaali-js's compact
  form — returned `1921-04-31`, a date that does not exist, and the Jalali
  round-trip inherited it: 12,261 mismatches. All four of SPEC §5's anchors
  passed the whole time, because they are all in the 2020s and the error was
  elsewhere. Replaced with the standard Fliegel–Van Flandern formulas, which
  agree with jalaali-js on the anchors and actually invert. There is now a
  Gregorian-only round-trip test as well, because the Jalali one cannot tell
  which of the two conversions broke.

  **A test assumption that was wrong, not the code.** I asserted Nowruz always
  falls on 20 or 21 March. It fell on **22 March in 1922** — the equinox was
  21 March 20:49 UTC and Tehran is +3:26 — so the assertion failed on the 1920s
  and "fixing" it would have meant breaking correct arithmetic. The set is
  `{20, 21, 22}` with the reason written next to it.

  Also caught: reading the leap flag *after* decrementing the year in
  `jdnToJalali`, a one-day error on every date in the last three months of a
  leap year.

- 4.6 money and units — `lib/core/money.dart` (the minimum EPIC-06 will extend
  rather than replace), `lib/l10n/money_format.dart`, `unit_format.dart` and
  `bidi.dart`. 11 tests.

  **`NumberFormat.currency(name: 'USD')` renders `USD1,234.56`,** not
  `$1,234.56`, and does it without an error — the `name` is used AS the symbol
  unless one is supplied. `simpleCurrency` is the one that reads CLDR's symbol.
  Caught by asserting SPEC §5's table verbatim rather than "starts with a
  symbol".

  **Gate fix:** `check_type_floor.sh`'s ARB digit rule flagged
  `"example": "3"` inside a `@key` placeholder block — metadata, not translated
  copy, and the example is FOR the digit. The rule now matches top-level message
  keys only (two spaces of indent in a 2-space-pretty-printed ARB). Both arms
  re-verified: a real `"L/100 km"` still fails it.

  Toman is a branch inside the formatter and nothing else in the app knows about
  it: the stored integer stays IRR minor units, and a grep test asserts `IRT`
  — which is not an ISO 4217 code — appears nowhere in `lib/` or `test/`.

- 4.7 bidi — `lib/l10n/bidi.dart` holds the one isolation helper set (`isolate`
  FSI, `isolateLtr` LRI, `isolateRtl` RLI) plus `stripBidi`, used at opposite
  ends: isolation on the way to a pixel, stripping on the way to storage, an
  export, a search index or a semantics label. 13 tests over SPEC §5 testing
  item 5's three-fixture corpus verbatim.

  A grep test bans the legacy `LRE`/`RLE`/`LRO`/`RLO`/`PDF` embeddings from
  `lib/` — they do not nest, they leak across a string boundary, and an
  unbalanced one reorders the rest of the paragraph.

  **Not yet wired:** there is no persistence layer (EPIC-05) and no export
  mapping (EPIC-15), so "no control reaches storage" and "no control reaches an
  export" are asserted at the helper boundary rather than through those layers.
  The corpus and the assertions are ready for both; recorded as deferred.

- 4.8 plurals — `test/l10n/support/plural_matrix.dart` derives the key list
  from the template (a hand-kept list drifts the moment somebody adds a plural)
  and holds SPEC §17's fourteen counts. 7 tests, 6 locales × 14 counts × every
  plural key. Verified to fail by deleting Arabic's `two` category.

  **A real defect the matrix caught: `{n}` inside an ICU plural renders in
  Latin digits.** gen-l10n interpolates the int with `toString()`, so
  `dateInDays(1000)` in Persian read `1000 روز دیگر` — a Latin thousand inside
  a Persian sentence, next to shaped digits everywhere else on the screen.

  Fixed by splitting the number in two: `n` (int) SELECTS the CLDR category and
  `nText` (String) is the same number already formatted and shaped by the app.
  Two placeholders for one number is ugly, and the alternative is worse. The
  obvious fix — `"format": "decimalPattern"` on the placeholder — makes
  gen-l10n format with the LOCALE's default numbering system, which is right
  until a Persian user sets `numerals: latin` (a setting SPEC §5 explicitly
  supports, because "younger Persian and Gulf users often prefer Latin digits").
  Then the sentence would shape and the rest of the screen would not, and
  SPEC §5's rule is absolute: never mix two digit sets on one screen.

- 4.9 font coverage — 10 tests plus 2 goldens, all over the real ARB corpus
  rather than a specimen letter list. EPIC-02's tests assert a fixed list; a
  specimen is exactly what hides a face that draws Persian and is missing the
  letters Sorani adds.

  **The woff2 question, resolved:** EPIC-02 already bundled the variable TTF at
  `assets/fonts/Vazirmatn[wght].ttf` (241 KB) with `OFL.txt`.
  `design/_fonts/Vazirmatn.woff2` is a design artefact and stays one — Flutter
  cannot load woff2. Asserted, so it cannot quietly become the shipped asset.

  **Finding against the epic.** Task 4.9 asks for a test that "the
  presentation-forms block is absent" (U+FB50–U+FEFF). Upstream Vazirmatn ships
  **213 of the 944** — including the lam-alef ligatures U+FEF5–U+FEFC that
  Unicode shaping REQUIRES and that have no decomposition path. That assertion
  would have failed on the shipped font on day one. The test asserts what is
  actually true and what actually matters: the block is a partial set (< 300)
  rather than a wholesale duplicate, and the required ligatures are present.
  The epic's underlying concern — a face that ships all 944 and doubles the
  file for nothing — is real, and the remedy is a subsetting build step that
  nothing in this repo has. Not built here; recorded.

  **`tnum` is asserted behaviourally, not by parsing GSUB.** The claim that
  matters is "a Persian odometer does not jitter as a digit changes", so the
  test renders each digit of all three blocks and compares advance widths. A
  GSUB feature-tag parse would prove `tnum` exists without proving it covers
  `۰-۹`, which is the exact bug — a face with tabular Latin and proportional
  Persian gives a stable English odometer and a jittering Persian one.
