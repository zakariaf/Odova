# EPIC-14 — Settings, units, language and about

**Baseline at branch point** — `main` at `1fc47ef` (EPIC-13 merged), analyzer
clean at `--fatal-infos --fatal-warnings`, 4,249 tests green, every gate green.

**Carried in from EPIC-13's `/code-review` and `/simplify`**, to be taken with
the tasks that touch the same code rather than as a separate sweep:

- **`core/time/completed_months.dart` is dead** and duplicates `CostRange`'s
  window rule. This epic is the next one to open `core/time/`; delete it or
  make `CostRange` delegate.
- **`CalmScaffold` takes an eager `List<Widget>`**, so `ListView.separated`
  cannot virtualise what it is handed and `trips.list` materialises every row.
  A builder API on the scaffold is the fix and every screen inherits it —
  recorded for EPIC-17, but this epic adds five screens to the pile.
- **`CostRange.thisMonthSoFar` still has no production caller.** The "this
  month so far" line now renders, but from `CostsInputs.thisMonthAmounts`
  rather than through that API.
- **`TripDraft.isDirty` and `TripRepository.undelete` have no callers.** Both
  pair with `trips.edit` work EPIC-13 deferred: the `dialog.discard` guard and
  the save Undo. §13 says Settings has no Save button and therefore never
  fires `dialog.discard`, so the guard work does not land here — but the trip
  form's does, and it is small.
- **`fuel_insights` re-derives EPIC-06's `consumption_stats` engine.** Belongs
  with the deferred fuel-kind selector, which is where a bi-fuel or electric
  car chooses its unit.

**Two ports this epic declares and EPIC-16 implements** (§13 and EPIC-16 agree
on the split from both ends): `ScheduleRebuilder` for the reschedule that any
text-affecting write triggers, and the notification-permission gateway behind
`settings.notifications`' five states. If EPIC-16 lands first, override its
implementations rather than declaring a second seam.

## Task 14.1 — the settings write path and the reschedule gate

Built `lib/app/notifications/schedule_rebuilder.dart` (the port),
`lib/features/settings/data/settings_writer.dart` (the eighteen intent methods
and §13's rule-2 gate), and eighteen targeted UPDATEs on the data-layer
`SettingsRepository`.

**Two deviations from the epic's plan, both because the repo's rules outrank
it:**

1. **The port is in `lib/app/notifications/`, not `lib/services/`.**
   `structure_test.dart` allows seven top-level directories and `services` is
   not one; `lib/app/` is this repo's composition root and already holds
   `app/share/` and `app/pdf/` on the same footing.
2. **The writes are eighteen targeted UPDATEs, not a read-modify-write.**
   `SettingsRepository.setActiveVehicle` already argued this from EPIC-05: a
   round trip through the full companion makes every default on `AppSettings`
   a value the statement writes back, so a field added later and not yet read
   is reset on the next unrelated write. They go through one PRIVATE
   `_write(SettingsTableCompanion)` — private so
   `no_drift_in_signatures_test` keeps holding, since a companion in a public
   signature would make every caller need a database.

The rule-2 list lives in **one** `Set<SettingsKey>`, not at nineteen call
sites, so a setter added later is missing from a set rather than quietly
breaking a rule. Three mutations checked: adding `theme` to the set, dropping
`weekdaysOnly` from it, and letting the gate fire on a failed write.

`firstDayOfWeek` is REFUSED outside 1..7 rather than clamped — it is an
ISO-8601 weekday and a wrong value is a bug to see. `noticeDays` is written as
given: §3's 7..30 clamp defines the computed default only, and clamping a
number the user typed makes the field lie back at them.

**A note on the failure test.** The epic asked for "the fake DAO throws";
closing the database throws a `StateError`, and `guardPersist` deliberately
does not catch `Error` subtypes — an `Error` there means the schema and the
enums have drifted, which is a bug that must crash in debug rather than become
"something went wrong" in the UI. The test triggers an in-contract failure
instead: the settings row deleted, so the targeted UPDATE matches zero rows
and reports `NotFound`. It asserts on `setLanguage`, which is text-affecting —
the one arm where the gate could fire for a write that did not happen.

## Task 14.2 — the `settings` tab root

Built `lib/features/settings/application/settings_root_model.dart` and
`presentation/settings_screen.dart`, plus `lib/app/app_version.dart`. The
route now renders the real screen; tab 4's root was EPIC-08's placeholder.

Backup & restore is the first row and **alone in its group**, and the test
asserts the first `CalmRowGroup` holds exactly one row — that is the assertion
that stops the next epic appending a preference above it. §13 gives the reason
and it is the shape of the whole screen: the person who needs Export is
standing in a phone shop with a dead handset in their pocket.

**Three lifts, all for the same reason** — `structure_test.dart` refuses one
feature importing another, and each helper now has a second caller:

- `formatDaysAgo` → `lib/l10n/relative_past_text.dart` (the garage,
  `vehicle.edit`, and now the backup row). The first duplicate of it forced
  `'en'` with Latin numerals, so one reading read `۴ ماه پیش` in the garage
  and `4 months ago` one tap away.
- `formatMinutesOfDay` added to `date_format.dart`, through ICU's `Hm`
  skeleton so 12- vs 24-hour is the LOCALE's decision. A hand-rolled
  `'$h:$m'` would have shipped 24-hour time to every American user of a screen
  whose job is telling them when a notification arrives.
- `kAppVersion` as a constant with a test against `pubspec.yaml`, rather than
  `package_info_plus` — a plugin with a native side on both platforms, for one
  string this repo already knows at build time.

**A shared-component change, and the two narrower fixes the tests rejected.**
`CalmListRow`'s value had no width bound. That is fine while every value is
`1.4.0` or `On · 09:00` and is not fine in Persian: the screen overflowed by
26 pixels the first time it drew `اعلان‌ها` beside `روشن · ۹:۰۰`. A `Flexible`
on the end block makes it a flex sibling of the title and moves where text
wraps on EVERY row in the app — eleven vehicle tests and two row goldens went
red. A ceiling on the whole end block starves `end` and the chevron, which are
fixed-size and were never the problem. What landed is a ceiling on the value
alone: short values keep their natural size, the long one wraps, and §13's
"never truncate" holds. All 95 goldens still pass.

**Two divergences from §13's prose, both to the reference:**

1. The Vehicles subtitle NAMES the vehicles (`Golf, Transit, CB500X`) rather
   than counting them. §13's plural survives for a garage of four or more,
   where the line stops fitting on the narrowest phone.
2. The backup line carries the date AND the age — §13's table shows only the
   age, and the two answer different questions: one is checked against memory,
   the other against urgency.

`clockProvider` refuses to default, so `bootstrap_launch_test.dart` now
supplies one: the failed-migration path paints a real screen that asks what
day it is, where it used to paint a placeholder that asked nothing.

**Deferred.** The parity capture, per §6a. The app bar's bell glyph in the
reference — §7's edge table is the authority for navigation and it declares no
destination for it, so an undeclared edge is worse than an unexplained glyph.

## Task 14.3 — `settings.language`

Built `lib/features/settings/presentation/settings_language_screen.dart` and
lifted `LanguageRowList` into `lib/ui/language/`.

**The lift, and what it did NOT take with it.** EPIC-09 had already extracted
the row list inside the first-run feature, with a note saying EPIC-14 would
want it — so this was a move rather than a copy. What changed is the write:
`onSelect` is now a required callback instead of a hard-wired
`firstRunLanguageProvider.select`, because the two frames apply a language
differently. First run commits on Continue; settings applies **on tap**, which
§13 is emphatic about — "not on Continue, not on back: the user must see the
result while the list is still on screen" — and goes through `SettingsWriter`
so the write reschedules notifications. It lives in `lib/ui/` for the reason
`lib/ui/dialogs/` does: two features draw it.

**A bug the tests found in 14.2's screen.** The Settings row's `System (…)`
parenthesis was resolving through the FORMATS tag, and `localeEndonym` throws
on anything outside the six — so a `pt-BR` phone crashed the settings screen.
The two tags differ exactly when the device is set to a seventh language:
formats stay with the region, strings fall back to English.

**The reschedule test needed a real database.** `pumpShell`'s `settings:`
supplies the read stream and nothing behind it, so a `SettingsWriter` call
against it reports `NotFound` and — correctly — never reaches the scheduler.
Asserting the reschedule needs a row a targeted UPDATE can match, so that one
test seeds an in-memory database. That is the shape of the EPIC-13 lesson
applied early: a fake behind an interface proves nothing about the write.

**Deferred.** The parity capture, per §6a. The LTR↔RTL cross-fade §13 asks for
on a direction change — the rebuild is correct and instant today, and the
transition belongs with EPIC-17's motion sweep rather than as an untested
animation here.

## Task 14.4 — the format preview and the units catalogue

Built `lib/features/settings/domain/format_preview.dart` and
`units_catalogue.dart`. Both pure Dart with no Flutter import — the unit words
arrive as an already-resolved `FormatLabels` record, the way EPIC-12's
`ReportFormatters` does, because this is the file whose output has to be
asserted byte-for-byte in six locales and a `BuildContext` would put a widget
harness between the test and the string.

**Two real bugs in `formatLongDate`, both found by the property test.**

1. **It ignored the numeral setting entirely** — the digits were hard-coded to
   `CalmNumerals.auto`. In the preview that means the date renders the
   locale's digits while the distance beside it renders the user's chosen
   ones: one line, two numbering systems, which is the exact confusion the
   preview exists to remove. It now takes `numerals`, defaulted so every
   existing caller is unchanged.
2. **Its Gregorian branch shaped without folding first.** `shapeDigits` only
   maps ASCII into a block, and ICU already renders Persian digits for a `fa`
   locale — so shaping alone could never turn them back into Latin ones, and a
   Persian user who chose Latin numerals read `۱۲ مارس ۲۰۲۶` beside
   `142,380 km`. `number_format.dart` documents the fold-then-shape order for
   the same reason; the date formatter did not follow it.

The property test that found both runs every (locale × numerals × calendar)
combination and asserts each rendered line draws from **at most one** digit
block. It also caught a third thing before the code: the consumption label's
`100` has to arrive pre-shaped, because a baked `L/100 km` puts Latin digits
into an Arabic-Indic line.

`suggestConsumptionUnit` fills the row in for km/L, mi/gal-us and mi/gal-uk,
and returns null for every other pairing and for any user who has chosen
explicitly. Miles with litres has no conventional unit, and inventing one
would be the app stating a preference the user has not got.

**A gate false-positived, and the test moved rather than the gate.**
`no_currency_conversion_test.dart` greps the whole tree for a quoted `IRT`,
and my assertion that toman display never emits it contained the literal it
was asserting against. The gate is right to be that strict, so the test now
asserts on the code that DOES exist — no `IRR` beside the toman word — which
is a truer check anyway.

## Task 14.5 — `settings.units` and the currency sheet

Built `units_screen.dart`, `currency_sheet.dart` and `units_labels.dart`, and
switched the estimate sheet EPIC-13 built over to `CalmSheet.show` with them.

**The preview is two lines, not three.** §13's prose describes three; the
reference draws `2 September 2026 · 187,412 km` over
`42.8 L · €74.20 · 6.4 L/100 km`. Rule 4 makes the reference the authority and
it is also the better shape — the second line is one thought, "what a tankful
looks like", and splitting it strands a lone consumption figure with nothing
to compare it against. The fixed sample moved to the reference's numbers too.

**Three real bugs the tests found, all in code written this task:**

1. **The pairing rule closed over stale build values.** `setVolume` asked
   about the distance unit as it was when the row was rendered, so switching
   to miles and then to gallons asked about (km, gal) and then (mi, L) —
   neither of which has an answer — and the screen sat on `L/100 km` under
   miles and gallons, which is the exact state §13 fills the row in to avoid.
   It reads the settings back through the repository now, not through the
   watched stream, because the stream is asynchronous and returns the row as
   it was before the write.
2. **"The user chose this" was inferred from a null.** When the previous
   pairing implied nothing — miles with litres has no conventional unit — the
   check `current != implied` was `current != null`, always true, so the app
   concluded the user had chosen and never suggested again. `implied != null
   && current != implied` is the honest test.
3. **The numerals row offered no local digits to a Persian speaker on a
   British phone.** §5 keeps formats with the region and strings with the
   language, so that user reads Persian words and British numbers — and
   keying the Local row on the formats tag alone offered them Latin and
   Latin, with no way to choose Persian digits at all. It consults both tags
   now.

**And one in the test harness, worth recording.** `pumpShell`'s `locale:`
goes straight to `OdovaApp` and bypasses `localeControllerProvider`, so a test
that pumps `fa` gets a Persian screen whose RESOLVED tags still say `en-US`.
Every assertion about locale-derived behaviour passed for the wrong reason
until the device locale was overridden too.

Every option row is a sheet, and so is currency: §7 allows no branch in this
app three levels deep, and seven pushed sub-screens would put each choice a
navigation level away from the preview that exists to explain it. The currency
list is curated rather than all 180 ISO codes — `Currency.tryParse` still
accepts any well-formed three letters, because a backup from another phone may
carry one, but a picker of 180 rows would be 160 nobody has checked an amount
against. Every three-decimal currency is in it on purpose: those are the ones
where getting minor units wrong is a silent factor of ten.

**Deferred.** The parity capture, per §6a. The sheet's `Recent` group — it
needs the currencies present in the user's records, which is a read across
every record table that no screen has needed yet; the A–Z list works without
it. Search matches on the CODE only; matching a localised currency NAME needs
a name table the app does not have, and inventing six translations of 35
currency names is EPIC-17 work at best.
