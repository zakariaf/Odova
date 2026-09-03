# EPIC-04 — Localisation, numerals and RTL

| | |
|---|---|
| **Epic** | EPIC-04 — Localisation, numerals and RTL |
| **Depends on** | EPIC-02 |
| **Estimate** | **8 h (CC) · ~8 weeks (human)** |
| **Spec sections** | §5 *Languages, RTL and formats* — in full: the six locales, locale selection, mirroring, bidi, numerals, calendars, plurals, fonts, formats, the translation workflow, a11y of text and numbers, and §5 *Testing*. Plus §18 open questions 8 and 9. |
| **Screens** | none — this epic builds the localisation layer that every screen reads |

The shared rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, a screen is not done until it matches its reference, and
`SPEC.md` wins — are stated once in `epics/README.md`. They are not repeated here.

---

## Where we are now

Today the repository is at specification stage: `SPEC.md`, `design/`, `tools/`, `.claude/skills/`
and the repo gates. **There is no Flutter app** — no `pubspec.yaml`, no `lib/`, no `test/`.

One artefact for this epic already exists and is inert: **`l10n.yaml` at the repo root**, written
against `SPEC.md` §5 and armed by `pubspec.yaml`. It already sets `arb-dir: lib/l10n/arb`,
`template-arb-file: app_en.arb`, `output-dir: lib/l10n/gen`, `output-class: AppLocalizations`,
`preferred-supported-locales: [en]` and — load-bearing — **`nullable-getter: false`**. Do not
rewrite it; wire the app to it.

`design/_fonts/Vazirmatn.woff2` exists. **Flutter does not load woff2** — see the findings note in
Task 4.9.

Two epics run before this one. When EPIC-04 starts:

**EPIC-01 has created the app**: `pubspec.yaml` on Flutter 3.44.6 with a committed lockfile,
`analysis_options.yaml`, `lib/main.dart`, `lib/app.dart`, a `ProviderScope` composition root, and
`test/support/harness.dart` with `Device` and `pumpApp`.

**EPIC-02 has built the token layer** — eight files in `lib/theme/calm/` (`calm_palette.dart`,
`calm_colors.dart`, `calm_type.dart`, `calm_space.dart`, `calm_shapes.dart`, `calm_motion.dart`,
`calm_status.dart`, `calm_theme.dart`) holding every colour literal, font size, radius, duration
and curve in the app: the five `ThemeExtension`s, the hand-authored light and dark `ColorScheme`s,
`buildCalmTheme`, and `CalmType.latin` / `CalmType.arabicScript` with the Arabic-script metric
variant, plus Vazirmatn bundled as an asset with `OFL.txt` registered through `LicenseRegistry`
and its `wght` axis and Sorani coverage already asserted by `test/theme/`.

**Deliberately still missing when this epic starts:** there is no `lib/l10n/`, no ARB file, no
`AppLocalizations`, no locale resolution, no formatter and no calendar. Every widget built so far
takes its strings as constructor parameters — that was a deliberate constraint of EPIC-03, and
this epic is what turns those parameters into six languages. There are no screens and no feature
modules, so nothing in this epic renders a screen; it builds the layer under them.

EPIC-03 may run before, after or alongside this epic — they touch disjoint directories
(`lib/ui/calm/` and `lib/l10n/`) and both depend only on EPIC-02. Nothing here waits on it.

---

## What we will have when this is done

- `lib/l10n/arb/app_{en,de,fr,fa,ar,ckb}.arb` — six files, every key present in all six, every key
  in the template carrying a `description` and typed `placeholders`, and `maxChars` where §5
  constrains length.
- `flutter gen-l10n` produces `lib/l10n/gen/app_localizations.dart`, and a mistyped key is a
  **compile error**, not a blank label.
- The app runs in all six languages. `fa`, `ar` and `ckb` render right-to-left with the correct
  digit block each: `۱۲۳` for `fa`/`ckb`, `١٢٣` for `ar`, `123` for `ar-MA`.
- A Persian user sees Jalali dates; a Sorani user in Iraq sees Gregorian; nobody sees Hijri.
- `1.234,56`, `1,234.56`, `۱٬۲۳۴٫۵۶` and `١٢٣٤٫٥٦` all parse to the same number, and an ambiguous
  string is **rejected with an inline error rather than guessed at**.
- `VW Golf TDI 2.0` inside a Persian sentence reads correctly, and no bidi control character
  reaches storage, an export or a semantics label.
- Six commands pass: `flutter gen-l10n`, `flutter analyze --fatal-infos --fatal-warnings`,
  `flutter test`, `check_arb_parity.sh`, `check_i18n_bans.sh`, `check_type_floor.sh`.
- `epics/progress/EPIC-04.md` records the answer taken for `SPEC.md` §18 questions 8 and 9, with
  the name of who is being asked and what the code does until they answer.

**This epic has no visual-parity gate.** It builds no screen, and `calm-visual-parity` compares a
built screen against one of the 112 images in `design/reference/calm/`. What it *will* do is make
the RTL half of that reference set reachable at all: a screen epic cannot shoot a `-rtl` capture
until the locale it needs resolves to `TextDirection.rtl`, which is Task 4.2's job.

---

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Rule 12 — RTL and a11y by construction, every user string from an ARB via gen-l10n — is what this epic implements. |
| `i18n-rtl-l10n` | Owns the mechanics: gen-l10n and `l10n.yaml`, ARB parity, ICU plural/select, `NumberFormat` and the pinned numbering system, `normalizeToAscii`, FSI/PDI, directional geometry, and the three vendored delegates a locale Flutter lacks needs. |
| `calm-typography-and-rtl` | Owns what *Calm* decided: the four stored numeral values, region-not-language resolution, the always-Latin field list, Jalali display, the relative-date buckets, money as one atomic isolate, and the two per-script metric variants. |
| `value-objects-money-and-units` | Money is minor units plus an ISO 4217 code in a pure core; toman is a display-only divide-by-ten. The formatter must not become a second source of truth. |
| `accessibility-as-code` | Per-run language tagging so a voice switches mid-screen, numbers announced in the display digit set, the `~` never read as "tilde", and isolates stripped before a semantics label. |
| `widget-golden-and-a11y-testing` | The golden lanes must load real fonts — Persian digits and Arabic joining are never exercised under Ahem — plus the text-scale matrix the longest-string pass rides on. |
| `testing-strategy` | The pure, clock-injected core these formatters and the calendar conversion belong in, and the property/round-trip shape their tests take. |
| `error-handling-typed-results` | `normalizeNumericInput` rejects rather than guesses; the rejection is a typed `Failure` with a stable code, not a localised string. |
| `ci-pipeline-and-gates` | Wiring the ARB parity, i18n bans and type-floor gates so CI is red on a dead key, a mismatched placeholder, a missing plural category or a physical-side offset. |

---

## Tasks

### Task 4.1 — Wire gen-l10n and author the six ARB files

- **Goal** — the app has six locales and a string layer, and a mistyped key stops the build.
- **Spec** — §5 *The six locales*; §5 *Translation workflow*.
- **Skills** — `i18n-rtl-l10n` (`references/arb-and-icu.md`), `calm-typography-and-rtl`,
  `ci-pipeline-and-gates`.
- **Write these tests first** — `test/l10n/localizations_test.dart`:
  - `AppLocalizations resolves for each of the six locales` — a parameterised test over `en`,
    `de`, `fr`, `fa`, `ar`, `ckb`: pump under that locale and read one key. Fails if a locale is
    missing from `supportedLocales`.
  - `the template declares a description and typed placeholders for every key` — a pure-Dart test
    that parses `lib/l10n/arb/app_en.arb` and asserts every non-`@` key has an `@key` sibling with
    a non-empty `description`, and that every `{placeholder}` in the value appears in
    `placeholders` with a `type`. Fails on the first key someone adds in a hurry.
  - `no ARB value contains a literal digit` — greps every ARB value for `[0-9٠-٩۰-۹]` outside a
    placeholder. `"L/100 km"` fails; `"L/{n} km"` passes. A baked `100` stays Latin next to shaped
    digits, which §5 forbids outright.
  - `no ARB value contains a bidi control character` — `U+200E`, `U+200F`, `U+061C`,
    `U+2066`–`U+2069`. Isolation happens at render, never in the file.
  - `every key is a valid Dart identifier` — see the naming decision below. Fails on a key with a
    dot in it, which gen-l10n cannot turn into a getter.
  - `a locale ARB carries no key absent from the template` — the dead-key check, as a Dart test as
    well as a script, so it runs in `flutter test`.
- **Then build**
  - `pubspec.yaml`: add `flutter_localizations` (SDK), `intl`, and `generate: true` under
    `flutter:`.
  - `lib/l10n/arb/app_en.arb` as the template plus the five siblings. Seed them with the keys the
    later tasks need — at minimum `common.estimated.a11y`, `home.dueSoonNoConfidence`
    (SPEC §9 / `calm-due-state-and-status` rule 6: *"Odova needs a reading to say when"*, no
    placeholders), the unit abbreviation set from §5 *Number, currency and unit formats*, the
    relative-date bucket messages, and `remindersDueCount` from §5 *Plurals*.
  - **Record the key-naming decision in `epics/progress/EPIC-04.md`.** §5 *Translation workflow*
    says keys are namespaced identifiers and prints `reminders.dueCount`; §5 *Plurals* prints the
    same key as `remindersDueCount` in an actual ARB snippet. gen-l10n turns a key into a Dart
    getter, and `reminders.dueCount` is not a valid Dart identifier — so the dotted form cannot
    ship. The convention this epic adopts is **lowerCamelCase with the namespace as the prefix**
    (`remindersDueCount`, `homeDueSoonNoConfidence`, `settingsBackupExportCta`), which is the form
    §5's own example uses. Note it and move on; it is a transcription slip in the spec, not a
    product decision.
  - `lib/app.dart`: `localizationsDelegates: AppLocalizations.localizationsDelegates` and
    `supportedLocales: AppLocalizations.supportedLocales`. Do **not** re-append the `Global*`
    delegates — that spread already contains them, and re-appending puts them ahead of the ones
    Task 4.2 vendors.
- **Verify**
  ```bash
  flutter pub get --enforce-lockfile
  flutter gen-l10n
  flutter analyze --fatal-infos --fatal-warnings
  flutter test test/l10n/localizations_test.dart
  bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n/arb
  ```
  A pass is: `lib/l10n/gen/app_localizations.dart` generated, analyze clean, parity script silent.
  (Both `check_arb_parity.sh` and `check_type_floor.sh` default to a different directory than
  `l10n.yaml` uses — always pass `lib/l10n/arb` explicitly, and wire it that way in CI.)
- **Done when**
  - [ ] Six ARB files exist and `flutter gen-l10n` succeeds.
  - [ ] `nullable-getter: false` is in force; a deliberately mistyped key fails `flutter analyze`,
        checked once by hand.
  - [ ] Every template key has a description and typed placeholders.
  - [ ] No literal digit and no bidi control in any ARB value.
  - [ ] The key-naming decision is written into the progress file.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 4.2 — Vendor the three `ckb` delegates and prove the app is right-to-left

- **Goal** — Sorani does not crash on the first `Tooltip`, and it does not render backwards
  either.
- **Spec** — §5 *The six locales* (`ckb` ships in v1); §17 *Per-locale gate*.
- **Skills** — `i18n-rtl-l10n` (`references/unsupported-locales.md`), `app-startup-and-bootstrap`,
  `release-and-store-shipping`.
- **Write these tests first** — `test/l10n/ckb_delegates_test.dart`:
  - `the SDK still lacks ckb` — `GlobalMaterialLocalizations.delegate.isSupported(Locale('ckb'))`
    is false, and so is the Cupertino one. This test exists so the vendored code is a **deliberate
    deletion** the day Flutter covers the locale, not dead code nobody dares remove. It fails —
    correctly — when the SDK catches up.
  - `Directionality.of resolves to rtl for fa, ar and ckb and to ltr for en, de, fr` — one
    `testWidgets` per locale, reading the direction from a `Builder` inside the app. **This is the
    test that catches the silent failure**: Flutter's default `WidgetsLocalizations` claims every
    locale and hardcodes `TextDirection.ltr`, so vendoring only the Material half converts a crash
    into an app that reads backwards and logs nothing.
  - `a MaterialLocalizations string resolves under ckb` — read
    `MaterialLocalizations.of(context).okButtonLabel`; it should be the borrowed `fa` string, not
    a throw and not English chrome.
  - `a Tooltip under ckb does not assert` — the loud failure, pinned.
  - `the vendored delegates each claim only their own language code` — `isSupported(Locale('ar'))`
    is false for all three, so they never shadow a locale the SDK does ship.
  - `the vendored delegates sit ahead of the Global* ones` — assert the delegate list's first
    entry of each type is the vendored one. `Localizations._loadAll` takes the first delegate of a
    type that claims the locale; ordering is the whole mechanism.
- **Then build** — `lib/l10n/ckb_localizations.dart` holding
  `VendoredMaterialLocalizationsDelegate`, `VendoredCupertinoLocalizationsDelegate` and
  `VendoredWidgetsLocalizationsDelegate`, each borrowing `fa` as the script neighbour, from
  `.claude/skills/i18n-rtl-l10n/examples/unsupported_locale_delegates.dart`. Place all three
  **ahead of** `AppLocalizations.localizationsDelegates` in `lib/app.dart`. Add every shipped tag
  to `ios/Runner/Info.plist` `CFBundleLocalizations` and to the Android resource config.
- **Verify**
  ```bash
  flutter test test/l10n/ckb_delegates_test.dart
  flutter run --dart-define=LOCALE_OVERRIDE=ckb     # look at it; the chrome is Persian, the app is Sorani
  ```
  A pass is: six locales, three of them RTL, no assertion, and the borrowed chrome visible and
  named as a compromise rather than discovered later.
- **Done when**
  - [ ] All three delegates vendored, each claiming only `ckb`, all three ahead of the `Global*` ones.
  - [ ] `Directionality.of` asserted per locale.
  - [ ] A `Tooltip` renders under `ckb`.
  - [ ] The SDK-probe test is in the suite, so the vendoring can be deleted deliberately one day.
  - [ ] Platform manifests list all six tags.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 4.3 — Resolve the locale, and change it without a restart

- **Goal** — the app picks the right language from the device, the user can override it, and
  changing it re-renders in place without losing what they were typing.
- **Spec** — §5 *Locale selection*; §5 *No restart*; §13 `settings.language`; §3 *Entities* →
  `Settings.language` (`en|de|fr|fa|ar|ckb` plus the sentinel `system`).
- **Skills** — `i18n-rtl-l10n`, `calm-typography-and-rtl`, `state-management-riverpod`,
  `app-startup-and-bootstrap`.
- **Write these tests first** — `test/l10n/locale_resolution_test.dart`:
  - `an explicit setting wins over the device` — `Settings.language = 'de'` on a `fa-IR` device
    resolves to `de`.
  - `the device list is matched on the language subtag, in order` — `[pt-BR, fr-CA, en-US]`
    resolves to `fr` strings.
  - `formats come from the full tag while strings come from the subtag` — `de-AT` gets German
    strings and Austrian formats; `pt-BR` gets **English strings** with km, L/100 km, BRL and
    Monday. Fails if the code matched on the whole tag and fell back to `en` formats too.
  - `the four aliasing rows resolve as §5's table says` — `ckb-IQ`/`ckb-IR` → `ckb`;
    `ku`/`kmr`/`ku-TR` → **`en`, LTR** (Kurmanji is a different language in Latin script);
    `fa-AF`/`prs`/`prs-AF` → `fa`; any `ar-*` → `ar`. The `ku` row is the one people get wrong.
  - `an unsupported device language resolves to en strings with region-derived formats`.
  - `the override list is seven rows and each of the six is written in its own language` —
    `System (English)`, `English`, `Deutsch`, `Français`, `فارسی`, `العربية`, `کوردیی ناوەندی`,
    never translated into the current UI language. Fails if the list was localised, which would
    strand someone in the wrong language.
  - `the System row names what it resolves to right now` — on a `fa-IR` device the row reads
    `System (فارسی)`.
  - `the not-translated note appears only when the device language is none of the six` — the ICU
    message with the language name in its own language.
  - `test/l10n/locale_switch_test.dart` — `changing the language rebuilds from the root and
    preserves in-progress form input`: type into a `CalmField`, flip the locale, assert the
    controller's text is unchanged and `Directionality.of` has flipped. Fails if the rebuild threw
    the form away.
  - `changing language, numerals, calendar, units or currency each emit one
    LocaleAffectingChange event` — the hook notifications and cached layouts hang off; assert the
    event fires exactly once per change, not per rebuilt widget.
- **Then build** — `lib/l10n/locale_resolver.dart` (a pure function:
  `Locale resolveLocale(String settingLanguage, List<Locale> deviceLocales)`, clock-free and
  device-free, so it is a `package:test` unit), `lib/l10n/locale_controller.dart` (a Riverpod
  `Notifier` over the persisted setting, restored **before the first frame** — the only way a
  locale the OS cannot select is ever reachable), and the seven-row override model that
  `settings.language` will render in a later epic.
- **Verify**
  ```bash
  flutter test test/l10n/locale_resolution_test.dart test/l10n/locale_switch_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Every row of §5's *Locale selection* table has a test, including `ku` → `en`.
  - [ ] Strings match on the subtag, formats on the full tag.
  - [ ] A language change preserves in-progress input and flips direction in the same frame.
  - [ ] The locale is restored before the first frame.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 4.4 — Numerals out and numerals in: shaping, and the normaliser that refuses to guess

- **Goal** — a Persian user sees `۱۸۷٬۴۰۰` everywhere and can type it back in, and a fuel price
  the app cannot read is rejected instead of silently corrupting the consumption history.
- **Spec** — §5 *Numerals* (the four stored values, the region rule, the always-Latin list, the
  `normalizeNumericInput` pseudocode); §5 *Testing* item 9.
- **Skills** — `calm-typography-and-rtl` (`references/numerals-and-dates.md`), `i18n-rtl-l10n`,
  `error-handling-typed-results`, `testing-strategy`.
- **Write these tests first** — `test/l10n/numerals_test.dart` (pure `package:test`):
  - `resolveNumerals reads the REGION, not the language` — `ar-MA`, `ar-DZ`, `ar-TN`, `ar-LY` →
    `CalmNumerals.latin`; every other `ar-*` → `arabicIndic`; `fa` and `ckb` →
    `extendedArabicIndic`; `en`/`de`/`fr` → `latin`. Fails if someone switched on the language
    subtag, which is the documented mistake.
  - `an explicit setting is never overridden by auto` — `latin` on `fa-IR` stays Latin.
  - `the withdrawn value name persian appears nowhere` — grep `lib/` for a numeral value spelled
    `persian`; `persian` is a **calendar** value only.
  - `shapeDigits is 1:1 by codepoint and leaves separators alone` — `'1,234.56'` →
    `'۱,۲۳۴.۵۶'` under `extendedArabicIndic`; the string length is unchanged, so a live-echoing
    field needs no caret adjustment.
  - `shapeDigits asserts on auto` — `auto` must be resolved first.
  - `the formatter emits §5's verified output for 1234.56` — a table over `en-US` `1,234.56`,
    `de-DE` `1.234,56`, `fr-FR` `1 234,56` with a **narrow NBSP U+202F**, `fa-IR` `۱٬۲۳۴٫۵۶` with
    `٫` U+066B and `٬` U+066C, `ar-EG` `١٬٢٣٤٫٥٦`, `ar-MA` `1.234,56`, `ckb-IQ` `۱٬۲۳۴٫۵۶`.
    Assert the separator **codepoints**, not the rendered look.
  - `ckb borrows fa's number symbols` — `intl` ships none for `ckb` and silently falls back to
    Latin; assert the emitted digit block is U+06F0–06F9.
  - `VIN, plate, export JSON, filenames and version strings stay Latin under every setting` — one
    test per row of §5's always-Latin table. The plate case asserts **verbatim as typed**: a plate
    entered with Persian digits comes back with Persian digits, and one entered with Latin digits
    comes back Latin. Never shaped either way.
  - `test/l10n/normalize_numeric_input_test.dart`:
    - `each digit block folds to ASCII` — `۱۲۳` and `١٢٣` → `123`.
    - `Arabic separators fold` — `٫` → `.`, `٬` → grouping, `،` → `,`.
    - `bidi controls and every space-as-grouper are stripped` — `U+200E`, `U+200F`, `U+061C`,
      `U+2066`–`U+2069`, `U+00A0`, `U+202F`, `U+2009`, plain space.
    - `both separators present: the rightmost is the decimal point` — `1.234,56` → `1234.56` and
      `1,234.56` → `1234.56`.
    - `one separator repeated is grouping` — `1.234.567` → `1234567`.
    - `one separator with exactly three digits after it, where the locale groups with it, is grouping` —
      `1,234` under `en` → `1234`.
    - `otherwise it is the decimal point` — `1,5` under `de` → `1.5`. **`1٫5` is 1.5, not 15** —
      the case that silently corrupts an amount if digits are folded and separators are not.
    - `anything still ambiguous is REJECTED, not guessed` — returns
      `Err(NumericInputFailure.ambiguous)`, a typed `Failure` with a stable code, never a
      localised string and never a best guess. Fails if the function returns a number for
      `1,23,456`.
    - `anything outside [0-9 . -] after normalisation is rejected`, and `more than one '.' is rejected`.
    - `format → normalize → equality round-trip` — a property test over 1,000 seeded values ×
      6 locales × 3 numbering systems, including §5's four fixtures `1.234,56`, `1,234.56`,
      `۱٬۲۳۴٫۵۶`, `١٢٣٤٫٥٦`.
- **Then build** — `lib/l10n/numerals.dart`, porting
  `.claude/skills/calm-typography-and-rtl/examples/numeral_formatting.dart`: `CalmNumerals` with
  its four wire values, `resolveNumerals`, `calmDecimalFormat`, `shapeDigits`, `formatForDisplay`,
  `formatForExport`, and the `CalmFigure` / `CalmCode` render widgets. Add
  `lib/l10n/numeric_input.dart` with `Result<Decimal, NumericInputFailure> normalizeNumericInput(String)`,
  implementing §5's pseudocode line for line. Shaping is the **last** step of formatting, after
  grouping and separators; normalise to ASCII before any comparison, sort or search.
- **Verify**
  ```bash
  flutter test test/l10n/numerals_test.dart test/l10n/normalize_numeric_input_test.dart
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib
  ```
  A pass is: green tests, and the bans gate reporting no raw-ASCII-digit interpolation.
- **Done when**
  - [ ] `auto` resolves from the region; `ar-MA` gets Latin digits.
  - [ ] Shaping is 1:1 and never changes string length.
  - [ ] Every always-Latin field is covered by a test; the plate is verbatim.
  - [ ] An ambiguous input returns a typed failure and no number.
  - [ ] The round-trip property test passes over all three numbering systems.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 4.5 — Calendars: Jalali display, the pinned conversion, and bucketed relative dates

- **Goal** — a Persian user reads `۲۲ مهر ۱۴۰۵`, storage stays Gregorian, and the app says "in
  about 7 weeks" instead of "in 47 days".
- **Spec** — §5 *Calendars and dates*; §5 *Testing* item 10; §11 *History* (month headers group by
  the display calendar).
- **Skills** — `calm-typography-and-rtl`, `i18n-rtl-l10n`
  (`references/numerals-and-calendars.md`), `value-objects-money-and-units`, `testing-strategy`.
- **Write these tests first** — `test/l10n/calendar_test.dart` (pure `package:test`, clock injected):
  - `resolveCalendar: fa → persian; ckb-IR → persian; ckb elsewhere → gregorian; ar → gregorian` —
    and there is **no `hijri` value**; constructing one does not compile.
  - `the four ICU anchors convert exactly` — 1 Farvardin 1403 = 2024-03-20; 1404 = 2025-03-21;
    1405 = 2026-03-21; 30 Esfand 1403 (leap) = 2025-03-20. Fails on any implementation swap,
    which is why the anchors are in the suite and not in a comment.
  - `Gregorian → Jalali → Gregorian is the identity for every day from 1300 to 1500 AP` — ~73,000
    days. Fails if the leap rule drifted by one day anywhere in two centuries.
  - `a Nowruz table holds` — the first of Farvardin for a run of years, spot-checked against the
    anchors.
  - `no Jalali date is ever stored` — a test over the export mapping asserting every emitted date
    matches `^\d{4}-\d{2}-\d{2}$` and every timestamp is RFC 3339 UTC, whatever the display
    calendar. §5: a backup a technical user can read has to contain dates they recognise.
  - `relative dates are bucketed before they are formatted` — today → "Today"; ±1 → "Tomorrow" /
    "Yesterday"; 2–13 → "in {n} days"; 14–55 → "in about {n} weeks"; ≥56 → "in about {n} months".
    Assert the boundaries at 13/14 and 55/56, where an off-by-one lives.
  - `overdue is a separate string, never a negative relative time` — "{n} days overdue". Fails if
    the code passed a negative delta to the relative formatter.
  - `each bucket is an ICU plural message, not a formatter call with a suffix glued on`.
  - `first day of week comes from the region, never the language` — `fa-IR` Sat, `ckb-IQ` Sat,
    `ar-EG` Sat, `ar-SA` Sun, `ar-MA` Mon, `de`/`fr`/`en-GB` Mon, `en-US` Sun.
  - `weekend days come from the region` — `fa-IR`, `ar-SA`, `ar-EG`, `ar-AE`, `ckb-IQ` → Fri+Sat;
    `ar-MA`, `ar-TN`, `ar-LB`, `de`, `fr`, `en-*` → Sat+Sun. It drives `weekdays_only` and nothing
    else.
  - `Arabic Gregorian month names fork by region` — default to the Gulf/Egypt set
    (يناير/فبراير/مارس); `IQ SY LB JO PS` get كانون الثاني/شباط/آذار.
- **Then build** — `lib/l10n/calendar.dart`: `CalmCalendar`, `resolveCalendar`, a `CalmDate`
  projection that takes a canonical civil date plus the active calendar and returns display parts,
  the twelve Jalali month names, and the region tables for first-day-of-week and weekend days.
  Use the platform ICU `persian` calendar where available; otherwise **pin one** implementation of
  the Khayyam/Borkowski arithmetic and never swap it — the anchor test is what makes "never swap
  it" enforceable. `lib/l10n/relative_date.dart` holds the bucketing, which returns a bucket plus
  a count and hands both to an ICU message. The month-grid picker widget itself is a later epic's;
  this task ships the arithmetic and the names it will read.
- **Verify**
  ```bash
  flutter test test/l10n/calendar_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is: the 1300–1500 AP round-trip green and the four anchors exact.
- **Done when**
  - [ ] `fa` and `ckb-IR` display Jalali; `ar` displays Gregorian; there is no `hijri`.
  - [ ] The 200-year round-trip and the four anchors pass.
  - [ ] Storage is Gregorian and ISO, asserted.
  - [ ] Relative dates are bucketed, and overdue is its own string.
  - [ ] Week start and weekend come from the region.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 4.6 — Money, units, and the atomic number-plus-unit run

- **Goal** — every amount and every measurement renders with the right symbol, in the right place,
  in one piece.
- **Spec** — §5 *Number, currency and unit formats*; §3 *Currency* (toman is display only; storage
  is IRR minor units); §18 open question 10 (toman presentation, noted not closed here).
- **Skills** — `value-objects-money-and-units`, `calm-typography-and-rtl`, `i18n-rtl-l10n`.
- **Write these tests first** — `test/l10n/money_and_units_test.dart`:
  - `each locale places the symbol as §5's table says` — `en-US` `$1,234.56` (before); `de-DE`
    `1.234,56 €` (after, **NBSP U+00A0**); `fr-FR` `1 234,56 €` (after, NBSP); `fa-IR`
    `۱٬۲۳۵ تومان` (label after); `ar-EG` `١٬٢٣٤٫٥٦ ج.م.`; `ar-MA` `1.234,56 د.م.`; `ckb-IQ`
    `۱٬۲۳۵ د.ع.`. Assert the space **codepoint**, not just "a space".
  - `no ARB value contains a currency symbol adjacent to a placeholder` — a grep over the six
    files. Placement, spacing and any RLM belong to the formatter.
  - `decimal places come from CLDR` — JPY 0, KWD 3, IQD 3, EUR 2, USD 2.
  - `toman divides by ten, renders zero decimals and appends تومان` — and the **stored** value is
    still IRR minor units. Assert both halves: `formatForExport` of the same amount emits the IRR
    figure. `IRT` appears nowhere in the codebase, asserted by a grep test — it is not an ISO 4217
    code.
  - `a negative amount keeps its minus before the digits inside the same isolate` — assert the
    codepoint order, so the sign cannot migrate to the other end under RTL.
  - `a number and its unit are one isolate` — `۴۵٫۲ لیتر` is a single FSI…PDI run; splitting it
    puts the unit on the wrong side.
  - `unit abbreviations come from the ARB, not the platform unit formatter` — assert `fa` volume
    is `لیتر` and not ICU's `۴۵٫۲L`, and `ckb-IQ` distance is `کم` and not Latin `km`. ICU formats
    the number; the label is ours.
  - `the consumption label carries {n} = 100 as a placeholder` — `"ل/{n} کم"`, so the hundred is
    shaped like every other number. Fails on a baked `100`.
  - `mpg (US) and mpg (imp) are distinct units` — they are never conflated in storage or on a
    chart axis; the enum has both and no conversion path treats them as equal.
- **Then build** — `lib/l10n/money_format.dart` and `lib/l10n/unit_format.dart`, sitting on the
  pure money value object from `value-objects-money-and-units` (minor units + ISO 4217 code).
  Toman is a display branch inside the formatter and nothing else in the app knows about it.
- **Verify**
  ```bash
  flutter test test/l10n/money_and_units_test.dart
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh lib lib/l10n/arb
  ```
  A pass is: green tests, and the type-floor gate reporting no digit baked into an ARB message.
- **Done when**
  - [ ] Every row of §5's money table passes, separators asserted by codepoint.
  - [ ] Toman is display-only; storage and export stay IRR; `IRT` is absent from the tree.
  - [ ] Number + unit is one isolate, and the minus sits inside it.
  - [ ] Unit labels come from the ARB, with `{n}` for the hundred.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 4.7 — Bidi isolation, and keeping the controls out of everything that is not a pixel

- **Goal** — `VW Golf TDI 2.0` inside a Persian sentence reads correctly, and no isolate character
  ever reaches a file, a search or a screen reader.
- **Spec** — §5 *Bidi text* (the eight rules); §5 *Accessibility of text and numbers*; §6
  *Backup, export and import* (the file is readable in a text editor).
- **Skills** — `i18n-rtl-l10n` (`references/rtl-and-bidi.md`), `calm-typography-and-rtl`,
  `accessibility-as-code`, `data-export-and-restore`.
- **Write these tests first** — `test/l10n/bidi_test.dart`:
  - `the four helpers wrap with the right controls` — `isolate` uses FSI U+2068 … PDI U+2069;
    `isolateLtr` uses LRI U+2066; `isolateRtl` uses RLI U+2067. No legacy `LRE`/`RLE`/`LRO`/`RLO`
    anywhere — a grep test over `lib/`.
  - `an interpolated value is isolated, and the sentence is one ICU message` — assert the Persian
    template renders `VW Golf TDI 2.0` with the `2.0` and any bracket on the correct side. Fails
    on a concatenated `label + ": " + value`, which is also caught by a grep for `': '` splices.
  - `a code is forced LTR` — VIN and plate render with an explicit LTR paragraph direction, LTR
    isolation and start-of-line alignment **even on an RTL screen**, via `CalmCode`.
  - `free text takes direction from its content` — an English note inside a Persian card is LTR
    and start-aligned within the card; a Persian note in an English card is RTL. First-strong
    per paragraph, decided at render, stored raw.
  - `no bidi control reaches storage` — round-trip a vehicle named `BMW ۳۲۰i`, a note
    `قبض از Shell — €۵۲٫۳۰ (A2)` and a workshop `Autohaus Müller` through the persistence
    boundary and assert the stored strings contain none of U+200E, U+200F, U+061C,
    U+2066–U+2069.
  - `no bidi control reaches an export` — the same three fixtures through the export mapping.
    §5 *Testing* item 5 asks for exactly this corpus.
  - `no bidi control reaches a semantics label` — the accessibility layer strips them, as the
    export layer does. A reader that voices U+2068, or silently swallows it, is a bug either way.
  - `normalisation strips isolates before any comparison, sort or search` — searching for
    `Golf` finds the isolated title.
  - `each text run exposes its language` — a Latin workshop name inside a Persian card carries
    `Semantics(attributedLabel:)` tagged `en`, so TalkBack and VoiceOver switch voice mid-screen.
  - `~ is announced as "about", never as "tilde"` — every estimated value carries
    `semanticsLabel` from `common.estimated.a11y` — *"estimated, about {value}"* — while the `~`
    stays in the **visible** string as the non-colour marker of an estimate.
  - `ellipsis lands at the logical end and truncation does not reorder the remainder`.
- **Then build** — `lib/l10n/bidi.dart` — the one isolation helper set, used at the **view layer
  only** — plus the strip function, and its two call sites at the export boundary and in the
  accessibility layer. Prefer a known-direction isolate over FSI where the direction is known:
  first-strong mis-guesses on leading punctuation.
- **Verify**
  ```bash
  flutter test test/l10n/bidi_test.dart
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib
  ```
  A pass is: green tests, and the bans gate reporting no legacy bidi embedding and no physical-side
  geometry.
- **Done when**
  - [ ] One isolation helper set, used only at the view layer.
  - [ ] The three-fixture bidi corpus round-trips clean through storage and export.
  - [ ] Codes are force-LTR; free text is first-strong per paragraph.
  - [ ] Language tagged per run; the `~` is announced as "about".
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 4.8 — The plural matrix: six locales, real CLDR categories

- **Goal** — Arabic gives six visibly different forms, French has its `many`, Persian reads
  correctly at zero, and no `if (n == 1)` exists anywhere.
- **Spec** — §5 *Plurals*; §17 *Per-locale gate* (n ∈ {0,1,2,3,10,11,20,99,100,101,102,103,110,1000}).
- **Skills** — `i18n-rtl-l10n` (`references/arb-and-icu.md`), `calm-typography-and-rtl`,
  `testing-strategy`, `ci-pipeline-and-gates`.
- **Write these tests first** — `test/l10n/plurals_test.dart`:
  - `every count-bearing key declares the CLDR categories its locale requires` — a pure-Dart test
    parsing the ARB files: `ar` must carry all six of `zero one two few many other`; `fr` must
    carry `many`; `en`, `de`, `fa`, `ckb` must carry `one` and `other`. **Error, not warning** —
    §5's CI table says so.
  - `the plural matrix produces the documented distinct forms` — for each count-bearing key, for
    each of the six locales, for each n in the fourteen-value set, render and assert. Arabic must
    produce **six visibly distinct strings** across that set (103 is `few` again, 100/101/102/1000
    are `other`); Persian must read correctly at 0 (`fa`: 0 → `one`, so a translator writing
    "۱ یادآوری" in `one` would produce it for zero — the `=0` case is what stops that); `ckb`
    0 → `other`, unlike Persian; `fr` 0 → `one`.
  - `every count-bearing key whose zero copy differs from "0 things" carries an explicit =0 case` —
    zero differs across all six locales, so this is a per-key assertion, not a blanket rule.
  - `# renders through the locale number formatter` — assert the rendered count in `fa` is
    `۱٬۰۰۰` for n = 1000, picking up grouping and shaping. Fails if `#` was replaced with a raw
    `$count` splice.
  - `no ternary and no manual pluralisation survives in lib/` — a grep test for
    `count == 1 ?` and `n == 1 ?`.
  - `interval strings are plural too` — "every {n} km", "every {n} months": Arabic inflects the
    unit against the count, so units are not invariant suffixes.
  - `placeholder names and ICU branch shapes are identical across locales` — branch **bodies**
    differ; branch **shapes** must not.
- **Then build** — the plural messages across all six ARB files, and
  `test/l10n/support/plural_matrix.dart` holding the fourteen counts and the key list so the
  matrix cannot drift from the ARB. Any key added later with a `{count, plural, …}` is picked up
  automatically by parsing the template rather than by a hand-kept list.
- **Verify**
  ```bash
  flutter gen-l10n
  flutter test test/l10n/plurals_test.dart
  bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n/arb
  ```
  A pass is: green matrix, and the parity script silent on placeholder mismatch.
- **Done when**
  - [ ] `ar` carries all six categories on every count-bearing key; `fr` carries `many`.
  - [ ] The 6 × 14 matrix passes, with Arabic visibly distinct and Persian correct at zero.
  - [ ] Explicit `=0` wherever the zero copy differs.
  - [ ] No ternary pluralisation anywhere in `lib/`.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 4.9 — Prove the bundled font covers every character the six locales actually use

- **Goal** — no Sorani reader sees ransom-note text, and nobody finds out on a Xiaomi. EPIC-02
  asserted the face against a fixed letter list; this task asserts it against **the corpus the app
  actually renders**, which did not exist until Task 4.1 wrote the ARB files.
- **Spec** — §5 *Fonts*; §5 *Testing* items 6 and 7; §17 *Per-locale gate* (font coverage, zero
  glyph clipping at 200%).
- **Skills** — `calm-typography-and-rtl` (`references/fonts-and-scripts.md`), `i18n-rtl-l10n`,
  `widget-golden-and-a11y-testing`, `dependency-hygiene`.
- **Write these tests first** — `test/l10n/font_coverage_test.dart`:
  - `every codepoint in the fa, ar and ckb ARB files has a real glyph in the bundled face` — read
    the asset's own `cmap`, not a specimen. A face that draws Persian can be missing the letters
    Sorani adds, and a specimen set in Arabic never shows it. Fails with the offending codepoint
    named.
  - `the Sorani letter list resolves` — `ڕ` U+0695, `ڵ` U+06B5, `ۆ` U+06C6, `ێ` U+06CE, `ھ` U+06BE,
    `ە` U+06D5, `چ` U+0686, `ژ` U+0698, `گ` U+06AF, `پ` U+067E, `ک` U+06A9, `ی` U+06CC, `ڤ` U+06A4 —
    no `.notdef`, no fallback. Medial `ڵ` and the `ھ` variant are what most Arabic fonts get wrong.
  - `the presentation-forms block is absent` — U+FB50–U+FEFF are excluded from the subset;
    HarfBuzz applies `init/medi/fina/isol/rlig` from base characters, and shipping the forms
    doubles the file for nothing.
  - `tabular and lining figures exist for BOTH digit blocks` — `tnum` and `lnum` for `0-9` **and**
    for `۰-۹`. A face with `tnum` for Latin only gives a jittering Persian odometer and a stable
    English one, which is exactly the bug nobody on the team will see.
  - `no google_fonts in the lockfile` — a runtime font fetch in an app that promises no network.
  - `test/l10n/goldens/glyph_clipping_test.dart`, tagged `@Tags(['golden'])`,
    `setUpAll(loadAppFonts)`: `a single-line row of ژ چ گ ج ح خ ڕ ڵ is not clipped at 100% or 200% text scale` —
    real fonts, never Ahem; Arabic stacks dots above and drops tails well below the baseline, and
    a Latin-tuned line box clips them silently.
- **Then build** — `lib/l10n/font_coverage.dart` is **not** the deliverable; this is a test-only
  task over EPIC-02's bundled asset, plus whatever subsetting fix the tests demand. Two things it
  is likely to force:
  1. **The repo ships `design/_fonts/Vazirmatn.woff2` and Flutter cannot load woff2.** EPIC-02 is
     expected to have bundled a variable **TTF** at `assets/fonts/Vazirmatn[wght].ttf`. If it has
     not, this task's first step is sourcing the TTF from the upstream release (SIL OFL 1.1) and
     shipping `OFL.txt` with it. Record which happened in the progress file.
  2. `FontWeight` drives the `wght` axis on its own — never add a `FontVariation('wght', …)`
     beside it.
- **Verify**
  ```bash
  flutter test test/l10n/font_coverage_test.dart
  flutter test --tags golden test/l10n/goldens/glyph_clipping_test.dart
  grep -c google_fonts pubspec.lock          # expect 0
  ```
- **Done when**
  - [ ] Coverage asserted from the face's own `cmap` over the real ARB corpus, not a specimen.
  - [ ] Every Sorani letter resolves in all four joining forms.
  - [ ] `tnum`/`lnum` present for both digit blocks.
  - [ ] No clipping in the descender row at 100% and 200%.
  - [ ] The woff2-vs-TTF question is resolved and recorded.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

### Task 4.10 — Wire the gates: ARB parity, the i18n bans, and the two pseudo-locales

- **Goal** — CI is red on a dead key, a mismatched placeholder, an unparseable message, a missing
  plural category, a hard-coded string or a hard-coded `left`.
- **Spec** — §5 *Translation workflow* (the CI table); §5 *Testing* items 2 and 3; §17
  *Per-locale gate*.
- **Skills** — `ci-pipeline-and-gates`, `i18n-rtl-l10n`, `widget-golden-and-a11y-testing`,
  `calm-typography-and-rtl`.
- **Write these tests first** — `test/l10n/gates_test.dart` and the CI wiring:
  - `a key present in a translation but absent from en is an error` — feed the parity checker a
    fixture ARB pair with a dead key and assert it exits non-zero. The gate's own self-test:
    prove it can fail, the way `tools/check_gates_selftest.sh` already does for the repo gates.
  - `a renamed placeholder is an error`, `an unparseable ICU message is an error`, `a missing CLDR
    plural category is an error` — one fixture each, each asserted to fail.
  - `a key missing from a translation is a warning on main and an error on a release build` —
    assert both branches; the severity differs by build, and that is the rule §5 states.
  - `an untranslated key falls back to English text, never to the raw key` — and in a debug build
    it is wrapped in `‹ ›` and logged in a MISSING report. Fails if a user would ever see
    `settingsBackupExportCta` on screen.
  - `en-XA renders every user-visible string accented, bracketed and +40% long` — pump the eight
    core screens' widget fixtures under the pseudo-locale; **any string that comes back
    unaccented is a hard-coded literal**, and the test names it. This is the practical answer to
    the one check `check_i18n_bans.sh` deliberately does not attempt.
  - `ar-XB forces RTL with reversed Latin and finds no physical-side offset` — catches a
    hard-coded `left`/`right` without needing to read Arabic.
  - `a synthetic longest-of-six locale passes the golden suite at 100% and 200% text scale` — one
    `testWidgets` per scale, `takeException()` null **and** a `getRect` fit assertion. German runs
    ~30% longer, French ~20%.
  - `tab and bottom-nav labels respect their maxChars` — 12 characters at the largest system text
    scale, per §5. If a locale cannot fit, the fix is a shorter translation, not an ellipsis.
- **Then build** — the pseudo-locale generator (`tool/build_pseudo_locales.dart`, deriving
  `app_en_XA.arb` and `app_ar_XB.arb` from the template at build time, never committed as
  hand-edited files), the missing-key fallback and the debug `‹ ›` wrapper, and the CI job that
  runs, in order:
  ```
  flutter gen-l10n
  bash .claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n/arb
  bash .claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib
  bash .claude/skills/calm-typography-and-rtl/scripts/check_type_floor.sh lib lib/l10n/arb
  flutter analyze --fatal-infos --fatal-warnings
  flutter test
  ```
- **Verify** — run the block above locally; then deliberately break each of the six rules in a
  scratch commit and confirm CI goes red for each, one at a time. A gate nobody has watched fail
  is a gate nobody can trust.
- **Done when**
  - [ ] All six CI rules from §5's table are wired, and each has been watched to fail.
  - [ ] `en-XA` and `ar-XB` are generated, not hand-maintained, and both run in the suite.
  - [ ] The longest-of-six pass is green at 100% and 200%.
  - [ ] A missing translation falls back to English text and is reported, never shown as a key.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 4.11 — Put `SPEC.md` §18 questions 8 and 9 in front of a native reader, and pin today's answer

- **Goal** — the two Sorani decisions this epic implements are recorded as *decisions awaiting a
  named reviewer*, not as things the code quietly chose.
- **Spec** — §18 *Decisions still open*, items **8** (*Kurdish Sorani numerals: extarab `۰۱۲۳` or
  arab `٠١٢٣`?*) and **9** (*Should `ckb-IR` default to the Jalali calendar, or do Sorani speakers
  in Iran expect Gregorian in a Kurdish-language app?*); §5 *Numerals*; §5 *Calendars and dates*.
- **Skills** — `i18n-rtl-l10n`, `calm-typography-and-rtl`, `dartdoc-conventions`,
  `testing-strategy`.
- **Write these tests first** — `test/l10n/open_questions_test.dart`:
  - `SPEC §18.8 — ckb defaults to extarab, and that is a placeholder for a native ckb-IQ reader` —
    assert `resolveNumerals(CalmNumerals.auto, Locale('ckb', 'IQ'))` is `extendedArabicIndic`,
    with the test's own doc comment naming the question, the alternative (`arab`, which is CLDR's
    default and common in Iraqi Kurdistan print), and the single settings row a user flips to get
    it. Failing this test is how a reviewer's answer lands: change one line, change one test.
  - `SPEC §18.9 — ckb-IR defaults to the Jalali calendar, and that is a placeholder for one native check` —
    assert `resolveCalendar(null, Locale('ckb', 'IR'))` is `CalmCalendar.persian` and
    `resolveCalendar(null, Locale('ckb', 'IQ'))` is `CalmCalendar.gregorian`, with the same shape
    of doc comment.
  - `both defaults are overridable by one settings row` — assert an explicit setting beats the
    default in each case, so the answer is never load-bearing on a user who disagrees with it.
- **Then build** — no product code changes; both defaults are already what Tasks 4.4 and 4.5
  implement. What this task builds is the **record**:
  - `///` doc comments on `resolveNumerals` and `resolveCalendar` naming §18.8 and §18.9 by number,
    stating the current answer, the alternative, and that it is a native reviewer's call.
  - An entry in `epics/progress/EPIC-04.md`: both questions, the answer shipped, the answer's cost
    if it is wrong (a Sorani reader in Iraq sees Persian digit shapes; a Sorani reader in Iran sees
    an unexpected calendar), and the fact that `CONTRIBUTING.md` already invites exactly these
    readers — §18 items 8, 9, 11 and 23 all need a native ckb reviewer, and this epic is the point
    at which they become answerable questions rather than notes.
  - A `SPEC.md` §18 note is **not** edited here. Closing an open question is a deliberate PR with
    the reviewer's sentence in it, which is what §18 says: *"Each can be closed with one sentence
    from the right person."*
- **Verify**
  ```bash
  flutter test test/l10n/open_questions_test.dart
  grep -n "SPEC §18" lib/l10n/numerals.dart lib/l10n/calendar.dart   # both questions named in code
  ```
- **Done when**
  - [ ] Both defaults are pinned by a named test whose doc comment states the question.
  - [ ] Both are overridable by one settings row, asserted.
  - [ ] `epics/progress/EPIC-04.md` records both, with the cost of being wrong.
  - [ ] `SPEC.md` §18 is unedited — closing a question is its own PR.
- **Estimate** — 0.5 h (CC) · ~1 week (human)

---

## Definition of done

- [ ] Six ARB files, key and placeholder parity across all of them, every template key carrying a
      description and typed placeholders.
- [ ] `nullable-getter: false` in force; a mistyped key is a compile error.
- [ ] `ckb` has all three delegates vendored ahead of the `Global*` ones; `Directionality.of` is
      asserted for all six locales.
- [ ] Numerals resolve from the **region**: `ar-MA` gets Latin, `fa`/`ckb` get `extarab`, `ar`
      elsewhere gets `arab`; the value name `persian` appears nowhere as a numeral.
- [ ] `normalizeNumericInput` implements §5's pseudocode and **rejects** an ambiguous string with a
      typed failure; the format→normalise round-trip passes over all three numbering systems.
- [ ] Jalali display for `fa` and `ckb-IR`; the four ICU anchors exact; the 1300–1500 AP round-trip
      green; storage Gregorian and ISO throughout.
- [ ] Plural matrix green for all six locales over the fourteen counts; Arabic gives six distinct
      forms; explicit `=0` wherever the zero copy differs.
- [ ] Money is one atomic isolate with the symbol placed by the formatter; toman is display-only
      and `IRT` is absent from the tree.
- [ ] No bidi control reaches storage, an export, a search or a semantics label.
- [ ] Font coverage asserted from the bundled face's `cmap` over the fa/ar/ckb ARB corpus plus the
      Sorani letter list; no clipping at 200%.
- [ ] CI is red on each of the six §5 rules, each watched to fail once.
- [ ] `SPEC.md` §18 questions 8 and 9 are named in code, pinned by tests, and recorded in the
      progress file.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

This epic builds no screen, so it carries no `calm-visual-parity` line. It is, however, what makes
the RTL half of `design/reference/calm/` checkable at all: until a locale resolves to
`TextDirection.rtl`, a `-rtl` capture cannot be shot.

---

## Progress file

**Before starting, create the empty progress file `epics/progress/EPIC-04.md`.** It starts empty.
Append one line per task as it completes — what was built, what was deferred, and anything the
next epic needs to know. It is the running log for this epic and the handover to the next one.
