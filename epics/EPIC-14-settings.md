# EPIC-14 — Settings, units, language and about

| | |
|---|---|
| **Epic** | EPIC-14 — Settings, units, language and about |
| **Depends on** | EPIC-04, EPIC-08, EPIC-09 |
| **Estimate** | **7.5 h (CC) · ~7–8 weeks (human)** over 9 tasks |
| **Spec sections** | §13 Settings, language, units, notifications, backup and restore |
| **Screens** | `settings`, `settings.language`, `settings.units`, `settings.notifications`, `settings.about` |

Settings is the fourth tab for exactly one reason: **Export lives here, and the person who
needs Export is standing in a phone shop with a dead handset in their pocket** (§13). So
Backup & restore is the *first* row, in its own group, with the only subtitle in the app that
changes colour — and this epic must not let a single new preference push it down the page.

`settings.backup` and `settings.import` are **not** built here. EPIC-15 owns them. This epic
builds the row that pushes to `settings.backup` and stops at the route.

The rules every epic inherits — TDD without exception, tests run per task, `/simplify` then
`/code-review` at the end, a screen is not done until it matches its reference, and `SPEC.md`
wins over any skill — are stated once in `epics/README.md`. They apply here in full.

---

## Where we are now

The repo today holds `SPEC.md`, three candidate design systems under `design/`, the 112-image
Calm reference set under `design/reference/calm/`, the repo gates in `tools/`, and 47 skills
under `.claude/skills/`. **EPIC-01 created the Flutter app** — before it there was no
`pubspec.yaml` and no `lib/`; `analysis_options.yaml` and `l10n.yaml` sat inert in the root.

By the time this epic starts, its predecessors have left behind:

| From | What this epic consumes |
|---|---|
| EPIC-01 | `pubspec.yaml` with `very_good_analysis` pinned, a committed `pubspec.lock`, the feature-first `lib/` tree, the composition root with the `Clock` seam overridden once, the `Result`/`Failure` spine, and CI's Flutter lane armed. |
| EPIC-02 | `lib/theme/calm/**` — the five `ThemeExtension`s `CalmColors`, `CalmType`, `CalmSpace`, `CalmShapes`, `CalmMotion`, each with an asserting `of(context)`. Feature code reads no raw hex, radius or duration. |
| EPIC-03 | `lib/ui/calm/**` — `CalmScaffold`, `CalmAppBar`, `CalmRowGroup`, `CalmListRow`, `CalmSwitch`, `CalmSegmented`, `CalmSheet`, `CalmTile`, `CalmButton`. This epic composes them and styles nothing itself. |
| **EPIC-04** | The §5 localisation and format layer: six ARB files, `gen_l10n` wired, `AppLocalizations`, the `Numerals` / `CalendarSystem` display transforms, `normalizeNumericInput`, the Jalali converter, the FSI/PDI isolate helper, and the unit-label lookups that come from our ARBs rather than the platform unit formatter. |
| EPIC-05 | The Drift store, the `Settings` singleton row (`id = "settings"`, §3), `activeVehicleId`, the repository single write path, and the DAO `.watch` streams. Domain models still carry canonical integers with unit-bearing names (`odometerM`, `quantityMl`, `totalCostMinor` + `currencyCode`) unless EPIC-06 has already swapped them for value objects — the units screen formats whichever shape it finds, at the repository boundary. |
| EPIC-08 | The single `go_router`, the four tab roots plus the docked central **+**, the placeholder sitting at the tab-4 root that Task 14.2 replaces, and the three global dialogs of §7 in `lib/ui/dialogs/`. |
| **EPIC-09** | First run, the garage and vehicles: `firstrun.language`, `firstrun.vehicle`, `vehicle.edit`, the `vehicles` list, `VehicleRepository`, and the seven region-seeded format defaults written on the firstRun language step. |

> Read `epics/progress/EPIC-04.md` and `epics/progress/EPIC-09.md` before Task 14.1. Anything
> named above that is not there yet is a blocker to raise, not a thing to rebuild.

**Deliberately still missing when this epic starts:** every screen in the Settings stack. Tab 4
exists in the shell but its root is EPIC-08's placeholder. There is no `settings.language` in
*settings* mode — EPIC-09 built the `firstrun.language` variant, which is the same screen with
no back affordance, a pinned **Continue** and no trailing paragraph. There is no units screen,
so the Persian build is currently a Persian build with whatever defaults first run happened to
seed. `settings.backup`, `settings.import`, the backup JSON writer and the importer do not
exist and are EPIC-15's whole job.

**And one thing that may still be missing when this epic ends.** EPIC-16 owns the notification
engine — `notification_gateway.dart`, `ReminderScheduler.compute`, and the permission
pre-prompt sheet — and it depends on EPIC-07, EPIC-08 and EPIC-10, not on this epic, so it can land
either side of this one. EPIC-16 says so from its own end: *"`settings.notifications`. The
screen, its five states and its rows belong to the Settings epic. This epic ships the
pre-prompt sheet the screen presents, and the scheduler the screen's writes rebuild."* This
epic therefore builds the **screen** and defines two narrow ports it calls; EPIC-16 supplies
the implementations. Neither epic implements the other's half, and if EPIC-16 has already
landed, Task 14.6 consumes its port instead of declaring one.

---

## What we will have when this is done

- Tapping tab 4 lands on **Settings** with **Backup & restore** as the first row, in its own
  group, above Vehicles — visible without scrolling at 200% text scale in German.
- The Backup subtitle reads "Last backup 12 days ago" in secondary text, or "You've never made
  a backup." in amber with an amber dot, and turns amber again past 90 days.
- **Appearance** applies on tap with no confirmation; the whole app repaints in the chosen
  theme without a restart.
- **Language** lists seven rows — `System (English)` with the resolution live in the
  parenthesis, then `English`, `Deutsch`, `Français`, `فارسی`, `العربية`, `کوردیی ناوەندی`,
  each in its own script, never translated. Tapping one changes the app's strings, direction
  and font stack **while the list is still on screen**, and the navigation stack survives.
- **Units & formats** shows a live preview line — `12 Mar 2026 · 142,380 km` /
  `38.42 L · €68.90 · 6.4 L/100 km` — that updates in the same frame as any row below it. In
  `fa` with Local numerals it reads `۱۲ اسفند ۱۴۰۴ · ۱۴۲٬۳۸۰ کیلومتر`. Currency opens a
  searchable sheet, not a push.
- **Notifications** shows the three category switches, the delivery time, quiet hours, the two
  lead-time rows, and a card that changes with the OS permission state — including the state
  where the only remaining door is **Open phone settings**.
- **Add reminders to my calendar** hands `odova-reminders-2026-09-02.ics` to the share sheet
  with every active reminder as an all-day event with a 14-day alarm.
- **About** states "No account. No sign-up. No server. Nothing is uploaded. No tracking, no
  analytics, no ads." in plain words, shows `Backup format 1` from `SUPPORTED_FORMAT_VERSION`,
  and pushes an offline licence text view. No links out.
- `flutter test test/parity/` writes 20 PNGs to `build/parity/` and
  `bash .claude/skills/calm-visual-parity/scripts/check_parity.sh` is clean over all five
  screens in all four combinations.
- Every string on every screen above exists in all six ARB files, and no string is assembled
  by concatenation.

---

## Skills to load

Open `flutter-conventions-index` first; it is the front door and it routes the rest.

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The house rules every task inherits: feature-first layers, dumb widgets, one `Notifier` per screen, the single write path, injected side effects. |
| `calm-visual-parity` | Five referenced screens × four combinations = 20 gates. It also states what the check does **not** prove, which is why every screen task ends with a human looking at the sheet. |
| `calm-components` | Every row, group, switch, segmented control and sheet on these screens is a `Calm*` widget. Settings is almost entirely `CalmRowGroup` + `CalmListRow`, and a row that exists outside a group is a bug. |
| `calm-typography-and-rtl` | Six locales, three RTL; the language list renders six scripts at once, and the units preview is the hardest bidi in the app. Also owns the Vazirmatn asset and the RTL line-height multipliers. |
| `i18n-rtl-l10n` | ARB authoring, ICU plurals with all six Arabic categories, FSI/PDI isolates, and the CI checks that fail on a hard-coded literal. |
| `state-management-riverpod` | One `Notifier` per settings screen over immutable state; every write goes through `SettingsRepository`, never a DAO from a widget. |
| `service-boundary-and-native` | `NotificationPermissionGateway`, `AppSettingsGateway` (the OS settings deep link) and `ShareGateway` (the `.ics`) are injected interfaces faked in tests — there is no other way to test the five permission states. |
| `local-notifications-scheduler` | §13's cross-cutting rule 2: a settings change that alters text must cancel, re-render and reschedule, because bodies are baked into the OS at schedule time. |
| `ui-states-and-feedback` | The permission cards, the "Reminders are off." state and the sheet presentations. These screens have no loading or empty state, and the skill is what keeps someone from inventing one. |
| `accessibility-as-code` | The 48×48 dp / 52 pt hit floor on every row, switch and sheet item; the language rows expose their own language so the screen reader switches voice mid-list. |

---

## Tasks

### Task 14.1 — Build the settings feature module and the single write path

- **Goal** — Every settings screen reads one immutable `Settings` value and writes through one
  repository method, and any write that changes user-visible text reschedules notifications.
- **Spec** — §13 *Cross-cutting rules for this section* (1, 2); §3 *Domain model and rules* →
  the `Settings` singleton.
- **Skills** — `flutter-conventions-index`, `state-management-riverpod`,
  `local-notifications-scheduler`, `error-handling-typed-results`.
- **Write these tests first** — `test/features/settings/settings_repository_test.dart`:
  - `writes persist before the stream re-emits` — assert the DAO row is updated when the
    watched stream emits, not before. Fails if the notifier republishes optimistically.
  - `setTheme does not reschedule notifications` — the fake `ScheduleRebuilder` records zero
    calls. Theme changes no text.
  - `setLanguage reschedules` / `setNumerals reschedules` / `setCalendar reschedules` /
    `setDistanceUnit reschedules` / `setNotificationTime reschedules` /
    `setQuietHours reschedules` / `setWeekdaysOnly reschedules` / `setNotifyService
    reschedules` — one case each, asserting exactly one `cancelAllAndReschedule()` on the fake.
    These eight are the §13 rule-2 list; a missing one is a locale change that leaves German
    text arriving on a Persian phone for four months.
  - `the rebuild seam throws until the composition root overrides it` — so a settings write in
    an app with no scheduler wired is a loud failure at startup, not a silent no-op.
  - `a failed write returns Err(PersistFailure) and leaves the stored value unchanged` — the
    fake DAO throws; assert the typed failure and that a re-read gives the old value.
  - `firstDayOfWeek rejects anything outside 1..7` — it is an ISO-8601 weekday, never `"mon"`.
  - `noticeDays clamps to 7..30 when set from the computed default and is used as written when
    set explicitly` — §3's clamp defines the computed default only.
- **Then build** — `lib/features/settings/data/settings_repository.dart` — `SettingsRepository`
  with one intent method per key (`setTheme`, `setLanguage`, `setNumerals`, `setCalendar`,
  `setFirstDayOfWeek`, `setDistanceUnit`, `setVolumeUnit`, `setConsumptionUnit`,
  `setCurrencyDefault`, `setCurrencyDisplay`, `setNotificationTime`, `setQuietHours`,
  `setWeekdaysOnly`, `setNotifyService`, `setNotifyOdometer`, `setNotifyBackup`,
  `setNoticeDistanceMetres`, `setNoticeDays`), each returning
  `Future<Result<void, PersistFailure>>`, each persisting first and then letting the watched
  stream re-emit. A private `_rescheduleIfTextAffecting` gate holds the eight-key list in one
  place so it cannot drift per call site. `lib/features/settings/data/settings_providers.dart`
  — `settingsRepositoryProvider` and `settingsProvider` (a `StreamNotifierProvider` over the
  DAO watch). There is **no Save button anywhere in Settings**, so there is no draft state and
  `dialog.discard` never fires from this feature.
  The reschedule goes through **one narrow port** —
  `lib/services/notifications/schedule_rebuilder.dart`, `abstract interface class
  ScheduleRebuilder { Future<void> rebuildAll(); }` — behind a provider that throws until
  overridden. **If EPIC-16 has landed, this port is already satisfied by its
  `ReminderScheduler` and you override the provider rather than declaring a second seam.** Do
  not reach for `notification_gateway.dart` from this feature: exactly one file in the app is
  allowed to know `flutter_local_notifications` exists, and EPIC-16's policy test enforces it.
- **Verify**
  ```bash
  flutter test test/features/settings/settings_repository_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is 15 green cases and a clean analyzer.
- **Done when**
  - [ ] Every settings write goes through `SettingsRepository`; no widget or notifier touches a DAO.
  - [ ] The eight text-affecting keys reschedule; `theme` does not.
  - [ ] Writes return `Result`, never throw at the UI.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.2 — Build the `settings` tab root with Backup as the first row

- **Goal** — Tab 4 opens on a shallow settings tree whose first row is Backup & restore, with a
  live subtitle that is the only row in the app that changes colour.
- **Spec** — §13 → `settings`; §7 *Screen map and navigation* → the `settings` edge table.
- **Skills** — `calm-components`, `calm-layout-and-motion`, `calm-visual-parity`,
  `i18n-rtl-l10n`, `navigation-and-routing`, `accessibility-as-code`.
- **Write these tests first** — `test/features/settings/settings_screen_test.dart`:
  - `Backup & restore is the first row and sits in its own group` — assert the first
    `CalmRowGroup` contains exactly one `CalmListRow` and it is the backup row. This is the
    test that stops the next epic appending a preference above it.
  - `never exported shows the amber subtitle and the amber dot` — `lastBackupAt == null` →
    "You've never made a backup." with `CalmStatusDot` present.
  - `exported 12 days ago shows secondary text and no dot`.
  - `exported 4 months ago shows amber text and the dot` — the > 90-day boundary; assert at 90
    and at 91 days so the comparison is not off by one.
  - `migration-failed state shows the red subtitle` — "Odova couldn't finish updating."
  - `one vehicle renders the vehicle name, not a count` — subtitle reads "The Golf".
  - `three vehicles renders "3 vehicles"` as an ICU plural.
  - `appearance applies on tap with no dialog` — tap **Dark**, assert `setTheme(dark)` on the
    fake repository and no route pushed.
  - `each row pushes its route` — six cases: `settings.backup`, `vehicles`,
    `settings.language`, `settings.units`, `settings.notifications`, `settings.about`.
  - `there is no loading state and no empty state` — pumping with a repository that has not
    yet emitted must not render a skeleton; every value is a constant or one indexed read.
  - `the version string stays Latin digits under numerals = extended_arabic_indic` — "1.4.0" is
    a version string, not a number.
  - `no row is shorter than the Calm touch floor` — including the Appearance segments.
- **Then build** — `lib/features/settings/ui/settings_screen.dart` (`SettingsScreen`), its
  `SettingsNotifier` over an immutable `SettingsRootState` (theme, `lastBackupAt`, vehicle
  count or the single vehicle's name, display names for `language` / `distance_unit` /
  `volume_unit` / `currency_default` / `notification_time`, the OS permission word, migration
  state). Compose `CalmScaffold` + four `CalmRowGroup`s; Appearance is an inline
  `CalmSegmented` over `system | light | dark`. Rows are `start: label, end: value + chevron`;
  values are isolate-wrapped so "km · L · €" does not drag the currency symbol to the wrong
  end. Long labels wrap to two lines and drop the value to a third — **never truncate**;
  German ("Sicherung & Wiederherstellung", "Einheiten & Formate") is the width constraint.
  Register the six routes in the app router under the tab-4 stack. Zero vehicles is
  unreachable here — the app is in `vehicle.edit` (firstRun) — so do not write that branch.
- **Verify**
  ```bash
  flutter test test/features/settings/settings_screen_test.dart
  flutter test test/parity/settings_parity_test.dart      # captures 4 PNGs to build/parity/
  node tools/compare_to_reference.mjs build/parity/settings-light-ltr.png settings \
       --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings-light-ltr.png    # look at the side-by-side
  ```
  A pass is `ok` on theme, colour and bands for all four. The differing-pixel percentage is
  informational and sits at 25–45% on a correct screen — do not chase it.
- **Done when**
  - [ ] Backup & restore is the first row, in its own group, above Vehicles.
  - [ ] All five backup-subtitle states render with the right treatment.
  - [ ] Appearance applies on tap and repaints the app with no restart and no dialog.
  - [ ] Every row pushes the route §7 says it does.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.3 — Build `settings.language` in settings mode

- **Goal** — A user in the wrong language can find their own script and fix it in one tap, and
  see the result before the list leaves the screen.
- **Spec** — §13 → `settings.language`; §5 *Languages, RTL and formats* → *The six locales*,
  *Locale selection*, *Override*.
- **Skills** — `i18n-rtl-l10n`, `calm-typography-and-rtl`, `calm-components`,
  `calm-visual-parity`, `local-notifications-scheduler`, `accessibility-as-code`.
- **Write these tests first** — `test/features/settings/language_screen_test.dart`:
  - `seven rows in order: system then en de fr fa ar ckb`.
  - `each name renders in its own script and is never translated` — assert the exact strings
    `English`, `Deutsch`, `Français`, `فارسی`, `العربية`, `کوردیی ناوەندی` are present while
    the UI locale is `de`. Fails if someone routes them through the ARB.
  - `the system row names what it resolves to, live` — device `de-AT` → `System (Deutsch)`;
    device `pt-BR` → `System (English)`.
  - `an unsupported device language preselects System (English) and shows the one-line note` —
    assert `settings.language.notTranslated` renders with the language name in its own
    language, and that it is one ICU message, not a concatenation.
  - `ku, kmr and ku-TR resolve to en, LTR` — Kurmanji is a different language in Latin script.
  - `fa-AF and prs resolve to fa`; `ar-any-region resolves to ar`.
  - `tapping a row applies immediately` — assert `setLanguage` fires on tap, not on back.
  - `applying reschedules notifications` — one `cancelAllAndReschedule()` on the fake.
  - `applying does not touch the seven format defaults` — set `distance_unit = km`,
    `currency_default = EUR`, switch to `ar`, assert both unchanged. Someone in Berlin
    switching to Arabic still wants kilometres and euros.
  - `the navigation stack survives the rebuild` — push the screen from `settings`, switch
    language, assert `settings` is still beneath it.
  - `each row exposes its own language to the semantics tree` — so TalkBack switches voice
    mid-list.
  - `the trailing paragraph is present in settings mode` — and, in the firstRun variant that
    EPIC-09 owns, absent. Assert both from the same widget with a `mode` flag, so the two
    variants can never drift into two implementations.
- **Then build** — `lib/features/settings/ui/language_screen.dart` — `LanguageScreen({required
  LanguageScreenMode mode})` with `LanguageScreenMode.settings | firstRun`, so the screen
  EPIC-09 already ships in firstRun mode gains its settings mode here rather than being
  reimplemented. `LanguageNotifier` exposes the seven rows plus the live resolution of
  `system`. Each name is FSI/PDI isolate-wrapped and rendered in Vazirmatn for the three
  Arabic-script rows. Rows follow the *current* UI direction; they do not each flip their own
  alignment. Crossing LTR↔RTL cross-fades through `CalmMotion` — a slide in the direction that
  is about to reverse is nauseating. The firstRun-only region seeding of the seven format
  defaults stays in EPIC-09's code; this task does not move it.
- **Verify**
  ```bash
  flutter test test/features/settings/language_screen_test.dart
  flutter test test/parity/settings_language_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/settings.language-light-ltr.png \
       settings.language --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.language-light-ltr.png
  ```
  Note that `firstrun.language` is a **separate reference image** owned by EPIC-09; if this
  task changes shared widget code, re-run its four captures too.
- **Done when**
  - [ ] Seven rows, six scripts, no name translated.
  - [ ] The `System (…)` parenthesis is live and correct for a supported and an unsupported device locale.
  - [ ] Tapping applies strings, direction and font stack immediately, with the stack intact.
  - [ ] The apply path cancels, re-renders and reschedules notifications.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.4 — Build the format preview and the units option catalogue

- **Goal** — A pure, total function turns the seven format settings into the three preview lines
  `settings.units` shows, so the screen can be dumb and the bidi can be tested without a widget.
- **Spec** — §13 → `settings.units`; §5 → *Numerals*, *Calendars and dates*, *Number, currency
  and unit formats*; §3 → the unit enums.
- **Skills** — `value-objects-money-and-units`, `i18n-rtl-l10n`, `calm-typography-and-rtl`,
  `dart3-idioms-and-coding-standards`, `seeded-determinism-and-golden-vectors`.
- **Write these tests first** — `test/features/settings/format_preview_test.dart`:
  - `en-US defaults render 12 Mar 2026 · 88,470 mi / 10.15 gal · $68.90 · 27.4 mpg` — pin one
    fixed sample instant and one fixed sample record so the vector is reproducible.
  - `de-DE defaults render the de group and decimal separators and the trailing € with NBSP`.
  - `fr-FR uses U+202F as the group separator` — assert the codepoint, not the look.
  - `fa with numerals = extended_arabic_indic and calendar = persian renders
    ۱۲ اسفند ۱۴۰۴ · ۱۴۲٬۳۸۰ کیلومتر` — the exact string from §13.
  - `ar-EG renders Arabic-Indic ٠١٢٣ and ar-MA renders Latin 0-9` — the Maghreb fork.
  - `every interpolated value is wrapped in FSI…PDI and the separators come from the ARB` —
    assert the `·` is inside the translated message, not appended by code.
  - `a number and its unit are one atomic run` — assert no isolate boundary falls between
    `142,380` and `km`.
  - `unit abbreviations come from our ARB, not the platform formatter` — assert `fa` volume
    renders `لیتر` and never a Latin `L`.
  - `numerals = auto resolves to the locale's CLDR default` — `latn` for en/de/fr, `extarab`
    for fa/ckb, `arab` for ar, `latn` for ar-MA.
  - `only one numbering system is ever active in one preview` — a property test over all
    (language × numerals × calendar) combinations asserting the rendered string contains
    digits from at most one digit set.
  - `the consumption label carries {n} = 100 as a placeholder, never a baked literal`.
  - `suggestConsumptionUnit(km, l) == l_100km` and `suggestConsumptionUnit(mi, gal_us) ==
    mpg_us`, and `suggestConsumptionUnit` returns null once the user has chosen explicitly.
  - `currencyDisplay = toman divides by 10, renders 0 decimals and appends تومان, and IRT never
    appears`.
  - `the option catalogue offers exactly two calendars (gregorian, persian) and exactly three
    numeral rows over four stored values` — and `Local` is offered only where the locale's
    default numbering system is not `latn`.
- **Then build** — `lib/features/settings/domain/format_preview.dart` — a pure
  `FormatPreview buildFormatPreview(SettingsFormats formats, Locale locale, FormatSample
  sample)` returning three already-isolated display strings, and
  `lib/features/settings/domain/units_catalogue.dart` — the row option lists
  (`DistanceUnit`, `VolumeUnit`, `ConsumptionUnit`, `CalendarSystem`, `NumeralsOption`,
  `FirstDayOfWeek`) with their localised display names and the `suggestConsumptionUnit` pair
  rule. Both are total, clock-injected and free of Flutter imports so they run under
  `package:test`. `FormatSample` is a fixed golden vector, not `DateTime.now()`.
- **Verify**
  ```bash
  flutter test test/features/settings/format_preview_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
  A pass is every vector green, including the two Persian strings byte-for-byte.
- **Done when**
  - [ ] The preview builder is pure, total and has no Flutter import.
  - [ ] Every interpolated value is isolate-wrapped; no sentence is concatenated.
  - [ ] One numbering system per render, proven by a property test over every combination.
  - [ ] Unit labels come from the ARB files.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.5 — Build `settings.units` and the currency sheet

- **Goal** — The screen that makes the Persian build real: distance, volume, consumption,
  currency, calendar, numerals and week start, above a preview that changes in the same frame.
- **Spec** — §13 → `settings.units`; §5 → *Number, currency and unit formats*.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`,
  `i18n-rtl-l10n`, `ui-states-and-feedback`, `accessibility-as-code`.
- **Write these tests first** — `test/features/settings/units_screen_test.dart`:
  - `the preview sits above both groups and shows three lines`.
  - `changing distance from km to mi updates the preview in the same frame` — one `pump()`, not
    `pumpAndSettle()`.
  - `the two groups carry the MEASUREMENT and DATES AND NUMBERS headers, in that order`.
  - `calendar offers exactly Gregorian and Jalali` — assert no third row; `hijri` is not a
    storable value in v1.
  - `numerals offers exactly three rows` — Automatic, Latin (0-9), Local — and `Local` is
    absent for `en`.
  - `choosing km then L suggests L/100 km with the note "Suggested for kilometres and litres"`.
  - `an explicit consumption choice is never overridden afterwards` — set `km_l`, then change
    volume, assert `km_l` survives.
  - `currency opens a sheet, not a push` — assert `CalmSheet` and that the route depth is
    unchanged; no branch in this app reaches three deep.
  - `the currency sheet opens scrolled to the current selection, with up to three Recent
    entries above the A-Z list`.
  - `the currency sheet matches on code and on localised name` — search `يورو` finds `EUR`.
  - `the currency sheet footer says amounts already entered keep their currency` — and
    `changing currency_default rewrites no stored amount` — assert zero writes to any record
    table after the change.
  - `changing units, numerals or calendar reschedules notifications`.
  - `no per-vehicle override appears here and the footer does not mention them`.
  - `writes no records, ever` — a spy repository asserting the only table touched is `Settings`.
  - `every sheet row clears the Calm touch floor`.
- **Then build** — `lib/features/settings/ui/units_screen.dart` (`UnitsScreen`,
  `UnitsNotifier`), `lib/features/settings/ui/currency_sheet.dart` (`CurrencySheet` over
  `CalmSheet`). The preview band is a dumb widget over `Task 14.4`'s `FormatPreview`; each of
  its values is one atomic isolate-wrapped run, and the `·` separators live in the translated
  string. Currency codes stay Latin and LTR inside their isolate. The footer — "These change
  how Odova shows your records. Nothing you've already entered is altered." — is one ICU
  message. The German title "Maßeinheiten und Formate" wraps to two lines.
- **Verify**
  ```bash
  flutter test test/features/settings/units_screen_test.dart
  flutter test test/parity/settings_units_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/settings.units-light-ltr.png \
       settings.units --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.units-light-rtl.png
  ```
  Look hardest at the RTL sheet: the preview is the hardest bidi in the app, and a number
  stranded on the wrong side of its unit is exactly what the mechanical check cannot see.
- **Done when**
  - [ ] Seven rows in two groups, in the reference's order, above a live preview.
  - [ ] Currency is a sheet; nothing here pushes.
  - [ ] Changing `currency_default` rewrites no stored amount and applies no rate.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.6 — Resolve the five states of `settings.notifications` in one pure function

- **Goal** — The card at the top of `settings.notifications` is decided in one testable place
  from the permission value and two ledgers, rather than by a widget switching on a boolean.
- **Spec** — §13 → `settings.notifications` states table; §14 → *Notifications* (*Permission
  never granted*, *OEM background killers*).
- **Skills** — `service-boundary-and-native`, `state-management-riverpod`,
  `error-handling-typed-results`, `ui-states-and-feedback`, `async-safety`.

> **Boundary with EPIC-16.** EPIC-16 Task 16.8 owns
> `lib/services/notifications/notification_permission_port.dart`, the pre-prompt sheet
> `permission_preprompt_sheet.dart`, the pre-prompt cadence (three ever, one per 30 days,
> never again after the third), and the OEM background-restriction intent. **Do not write
> any of those here.** This task consumes the port and asks only: *given a permission value,
> which card does this screen show?* If EPIC-16 has not landed, declare the port's interface
> here — three sealed values `{ neverAsked, granted, denied }` and a `read()` — and let
> EPIC-16 replace the declaration with its own; the epic that lands second deletes the
> duplicate rather than keeping both.

- **Write these tests first** — `test/features/settings/notifications_card_test.dart`:
  - `neverAsked yields the "Reminders are off." card with a Turn on reminders action, and the
    rows below stay live` — a user may set 07:00 before granting.
  - `denied yields the "Odova can't send reminders because notifications are turned off for
    Odova in your phone's settings." card with an Open phone settings action`.
  - `denied moves the calendar row above the WHEN group` — it is now the useful thing here, so
    the resolver returns the row order, not just the card.
  - `declinedInAppThreeTimes presents exactly as denied and offers no Turn on reminders
    action` — this screen is the only remaining door.
  - `threeDeliveriesUnconfirmed yields the one-time background-restriction card` — "Your phone
    may be stopping Odova's reminders." — and asserts the outcome is recorded so a second
    build does not show it again, and that this card never resolves for `home`.
  - `all three categories off yields the footer "Odova won't send you anything. What's due
    still shows on the home screen."` — with no nag and no banner elsewhere.
  - `granted with at least one category on yields no card at all` — assert the absence, so
    nobody adds a reassuring green banner.
  - `the resolver is pure and performs no I/O` — it takes values, not repositories.
- **Then build** — `lib/features/settings/domain/notifications_screen_state.dart` — a pure
  `NotificationsScreenChrome resolveChrome({required PermissionState permission, required
  DeliveryLedger deliveries, required bool allCategoriesOff})` returning a sealed card
  variant plus the row order. `lib/services/os/app_settings_gateway.dart` —
  `AppSettingsGateway.openAppNotificationSettings()`, the one OS deep link this screen owns
  outright (EPIC-16 owns the OEM battery/autostart one). Fakes live in `test/fakes/`.
- **Verify**
  ```bash
  flutter test test/features/settings/notifications_card_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] All five states from §13's table resolve in one pure function that does no I/O.
  - [ ] The `denied` state reorders the rows, not just the card.
  - [ ] Nothing in this task duplicates EPIC-16 Task 16.8.
- **Estimate** — `0.5 h (CC) · ~half a week (human)`

---

### Task 14.7 — Build `settings.notifications`

- **Goal** — Delivery time, quiet hours, the three category switches, the two lead-time rows and
  the calendar row, with the permission card the previous task resolves.
- **Spec** — §13 → `settings.notifications`; §3 → *Notice window*.
- **Skills** — `calm-components`, `calm-visual-parity`, `forms-and-input`, `i18n-rtl-l10n`,
  `local-notifications-scheduler`, `accessibility-as-code`.
- **Write these tests first** — `test/features/settings/notifications_screen_test.dart`:
  - `three groups in order: WHAT ODOVA SENDS, WHEN, HOW FAR AHEAD, then the calendar row, then
    the footer`.
  - `turning Service reminders off cancels that channel's pending notifications only` — the
    fake scheduler records a per-channel cancel, not a global one.
  - `turning a category on triggers a full schedule rebuild`.
  - `time of day writes notification_time as local wall-clock` — not an instant.
  - `quiet hours from == to disables them and the row reads "Off"`.
  - `weekdays only names the days it will skip, from the locale's CLDR weekend` — `de` → Sat+Sun;
    `fa-IR` → Fri+Sat. The subtitle must show which pair it picked.
  - `How far ahead offers Automatic plus 500/1000/2000 km for a km user and 300/600/1200 mi for
    a miles user` — defined per unit system, **never converted**.
  - `Automatic stores null for notice_distance_m and notice_days` and the row carries
    "Automatic: about 10% before it's due."
  - `an explicitly chosen notice value is used as written and is not clamped to 7..30 / 1000 km`.
  - `the footer states the two-a-week cap as a fact and is not a switch`.
  - `this screen never lists the eighteen service items` — assert no per-reminder row exists.
  - `the scheduled_notifications table is never displayed`.
  - `21:00–08:00 is one isolate-wrapped run` — assert the en-dash and both times share one
    isolate, and under `fa` numerals it reads `۲۱:۰۰–۰۸:۰۰` in the same visual order.
  - `switches sit at the row end and mirror in RTL`.
  - `the three category labels honour their 22-character ARB maxChars` — a lint-style test over
    all six ARBs.
  - `every write on this screen reschedules` — there is no Save button.
- **Then build** — `lib/features/settings/ui/notifications_screen.dart`
  (`NotificationsSettingsScreen`, `NotificationsSettingsNotifier`), the time and quiet-hours
  pickers as `CalmSheet` presentations, `CalmSwitch` at row end, and the chrome from Task 14.6.
  In the `denied` state the calendar row moves above the WHEN group.
  **Turn on reminders** presents the pre-prompt sheet **EPIC-16 Task 16.8 builds** — §13 calls
  it "a sheet owned by this screen", and that ownership is presentational: this screen is where
  it is presented from, EPIC-16 is where it is written. It is not an addressable screen and
  gets no route and no parity gate. If EPIC-16 has not landed, wire the action to the port and
  leave the sheet unbuilt rather than writing a second one for EPIC-16 to delete.
- **Verify**
  ```bash
  flutter test test/features/settings/notifications_screen_test.dart
  flutter test test/parity/settings_notifications_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/settings.notifications-light-ltr.png \
       settings.notifications --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.notifications-dark-rtl.png
  ```
  The reference is shot in the granted state; capture that state for parity and cover the other
  four in the widget test.
- **Done when**
  - [ ] Three switches, three WHEN rows, two lead-time rows, the calendar row and the footer, in the reference's order.
  - [ ] Every write applies immediately and reschedules.
  - [ ] Lead-time options are per unit system and never converted.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `1 h (CC) · ~1 week (human)`

---

### Task 14.8 — Build the `.ics` reminder snapshot

- **Goal** — A user who will never grant notification permission can still get their due dates
  into a calendar, offline, from one row.
- **Spec** — §13 → `settings.notifications` → *Add reminders to my calendar*; §6 *Backup, export
  and import* §8 (the fifth output) and §6 (file naming and delivery).
- **Skills** — `data-export-and-restore`, `service-boundary-and-native`,
  `value-objects-money-and-units`, `i18n-rtl-l10n`, `testing-strategy`.
- **Write these tests first** — `test/features/settings/ics_export_test.dart`:
  - `the file is named odova-reminders-YYYY-MM-DD.ics from local time` — with an injected
    `Clock`; assert ASCII lowercase, hyphens, no spaces, no translated app name.
  - `every active reminder becomes one all-day VEVENT at its projected due date`.
  - `inactive, muted and untracked items are excluded`.
  - `each event carries a 14-day VALARM`.
  - `the file is written to the temp directory and handed to ShareGateway, never to a chosen
    destination` — the fake gateway records exactly one hand-off.
  - `a failed write deletes the temp file and publishes nothing` — force an `IOSink` failure and
    assert the export directory is empty and a typed `ExportFailure` comes back.
  - `dates are ISO and ASCII-digit even under numerals = extended_arabic_indic` — an `.ics` is
    interchange, not display.
  - `summaries are the user's own text, CRLF-folded at 75 octets per RFC 5545, with commas,
    semicolons, backslashes and newlines escaped` — the hostile fixture carries a reminder
    labelled `Öl; wechseln, "jetzt"\nzweite Zeile` and a Persian label.
  - `no bidi control character reaches the file` — the export layer strips isolates exactly as
    the backup layer does.
  - `zero active reminders produces no file and a disabled row`.
- **Then build** — `lib/features/settings/data/ics_export_service.dart` —
  `IcsExportService.export()` returning `Future<Result<ExportArtifact, ExportFailure>>`,
  streaming to a temp file through an `IOSink` and publishing by rename before the
  `ShareGateway` hand-off. The row's subtitle — "A snapshot, not a live calendar. Export again
  after you log a service." — is one ICU message. This is the only export outside the Export
  screen, and it lives here because it *substitutes* for notifications.
- **Verify**
  ```bash
  flutter test test/features/settings/ics_export_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] The `.ics` is generated on-device, offline, and handed to the share sheet on an explicit tap.
  - [ ] A failure leaves no artifact and returns a typed failure.
  - [ ] The hostile-fixture labels survive escaping and folding.
- **Estimate** — `0.5 h (CC) · ~half a week (human)`

> **Do not start this task until §18 decision 13 is closed.** Three documents disagree. §6 §8's
> table says the `.ics` ships in v1 ("Yes — offered on `settings.notifications`") and §13
> specifies the row and its subtitle. §18 decision 13 still lists *"Does the `.ics` calendar
> export ship in v1?"* as open. And **EPIC-16 states in writing that it is out**: *"The `.ics`
> calendar export. SPEC §18 decision 13 has not been closed; it is not in this epic and not
> assumed by it."* This epic is the only one that would build it. Get the one sentence that
> closes §18.13; if the answer is no, delete this task, drop the row from Task 14.7's tests,
> and note it in the progress file — the reference image for `settings.notifications` will then
> need re-shooting without that row, which is a design change, not a tolerance question.

---

### Task 14.9 — Build `settings.about` and the offline licence view

- **Goal** — The privacy promise stated in plain words, the two version numbers a user can act
  on, and the licences — with no network and nothing to tap out to.
- **Spec** — §13 → `settings.about`; §6 §3 (`SUPPORTED_FORMAT_VERSION`); §2 *Non-negotiables*.
- **Skills** — `calm-components`, `calm-visual-parity`, `calm-typography-and-rtl`,
  `i18n-rtl-l10n`, `dependency-hygiene`, `accessibility-as-code`.
- **Write these tests first** — `test/features/settings/about_screen_test.dart`:
  - `renders the app name, "Version 1.4.0 (312)" and "Backup format 1"` — the format number
    comes from `SUPPORTED_FORMAT_VERSION`, asserted against the same constant the backup writer
    uses, so the two can never disagree.
  - `the internal schema_version is never rendered` — the user cannot act on it.
  - `version and build stay Latin digits and forced LTR under fa with extended Arabic-Indic
    numerals`.
  - `the privacy paragraph renders in full at 200% text scale with no clipping in all six
    locales` — no fixed height; the RTL locales use the 1.55–1.70 line-height multiplier.
  - `the sentence about losing the phone is present` — an explicit assertion, because it is the
    one a future PR will quietly delete.
  - `Open source licences pushes an offline text view from a bundled asset` — assert the route
    and assert zero network-capable dependencies are reachable from it.
  - `the licence text includes Vazirmatn SIL OFL 1.1` — via `LicenseRegistry`.
  - `none of rate-this-app, share, contact support, privacy policy, terms, restore purchases or
    a debug menu is present` — one test asserting the absence of all seven, so nobody adds one
    back without deleting a test.
  - `the screen makes no network call` — assert against the repo's no-network gate.
- **Then build** — `lib/features/settings/ui/about_screen.dart` (`AboutScreen`) and
  `lib/features/settings/ui/licences_screen.dart` (`LicencesScreen`) over a bundled asset.
  Build constants come from `lib/app/build_info.dart`; `SUPPORTED_FORMAT_VERSION` is imported
  from the backup package EPIC-15 owns — declare the constant here if EPIC-15 has not landed,
  and EPIC-15's Task 15.1 takes ownership of it, leaving this screen reading it.
- **Verify**
  ```bash
  flutter test test/features/settings/about_screen_test.dart
  flutter test test/parity/settings_about_parity_test.dart
  node tools/compare_to_reference.mjs build/parity/settings.about-light-ltr.png \
       settings.about --theme light --dir ltr
  # repeat for dark-ltr, light-rtl, dark-rtl — or:
  bash .claude/skills/calm-visual-parity/scripts/check_parity.sh
  open design/reference/_parity/settings.about-light-rtl.png
  ```
- **Done when**
  - [ ] "No account. No sign-up. No server. Nothing is uploaded. No tracking, no analytics, no ads." reads as a promise, in one ICU block, not a legal notice.
  - [ ] "Backup format 1" reads from the same constant the backup writer writes.
  - [ ] Licences render offline from a bundled file, with no link out.
  - [ ] All four reference combinations pass `calm-visual-parity`.
  - [ ] The side-by-side sheet has been opened and looked at — the tool cannot see type weight,
        icon shape or optical alignment.
- **Estimate** — `0.5 h (CC) · ~half a week (human)`

---

## Definition of done

- [ ] Backup & restore is the first row of Settings, in its own group, and stays first.
- [ ] All five screens are reachable from tab 4 and every edge in §7's `settings` table works.
- [ ] Language applies on tap, in place, with the navigation stack and any in-progress form input intact.
- [ ] The units preview renders correctly in all six locales, both directions, both digit sets and both calendars.
- [ ] All eight text-affecting settings cancel, re-render and reschedule notifications.
- [ ] Every user-visible string on these screens exists in all six ARB files, with no concatenation and no hard-coded literal.
- [ ] Every row, switch, chip and sheet item clears the Calm touch floor.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.
- [ ] Every screen in this epic matches its reference in `design/reference/calm/` in all four
      combinations, checked with `calm-visual-parity`.

---

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-14.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.

EPIC-15 reads this file first. It needs to know, at minimum: whether
`SUPPORTED_FORMAT_VERSION` was declared here or is still waiting on EPIC-15, whether the
`ShareGateway` seam from Task 14.8 is reusable as-is for the backup, CSV and PDF hand-offs, and
what the Backup row's subtitle expects from `last_backup_at`.
