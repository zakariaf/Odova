# Odova

An offline, account-free log for car maintenance, fuel and running costs.
Episode 6 of a 50-app challenge.

**`SPEC.md` is the source of truth.** Read the section you are about to touch
before you write code. If the code and the spec disagree, the spec is right
until a deliberate PR changes it. Changing the spec is normal and welcome;
drifting from it silently is not.

## The idea, and why it exists

Most people look after their car by remembering, and remembering fails. Odova
tracks what has been done and works out what is due next — by distance and by
date, **whichever comes first** — so the home screen can answer one question:
*what does my car need next?*

The user is a commuter, a family, a used-car owner, a rideshare driver, a
plumber with two vans. They do not enjoy this task and they are not enthusiasts.
They want under a minute a month, and they want to be told, not asked.

Four facts about them drive everything (SPEC §1): they will not maintain a
database, they log in bad conditions, they forget, and their history is worth
money with no server holding a copy.

## Repo state

**Specification stage.** `SPEC.md` is complete. The Flutter app does not exist
yet — there is no `pubspec.yaml`, no `lib/`. CI runs the repo gates today and
arms its Flutter lane automatically once `pubspec.yaml` appears.

`analysis_options.yaml` and `l10n.yaml` are written and inert; they become live
in the commit that creates the app. **Three things must happen in that same
commit:** add `very_good_analysis` as a dev_dependency (or the pinned `include:`
resolves to nothing and analysis runs with zero rules while reporting green),
uncomment the `pub` block in `.github/dependabot.yml`, and commit `pubspec.lock`
— CI runs `pub get --enforce-lockfile` and the lock is the pin.

Reference implementation: Flutter, pinned to `.flutter-version` (3.44.6).
The spec itself is platform-agnostic; keep it that way.

## Rules that outrank everything else

1. **No network, by construction.** No HTTP client, no analytics, no crash
   reporter, no font CDN, no dependency that transitively opens a socket. The
   store listing claims zero network calls. Refused permanently:
   `google_fonts`, `firebase_*`, `sentry_flutter`, `http`, `dio`, any analytics
   or crash SDK. Fonts are bundled assets.
2. **No account, no server, no sync.** Backup is a plain, unencrypted JSON file
   the user keeps themselves. Import **replaces**; there is no merge (SPEC §2).
3. **Data survives.** Losing eight years of service history outranks every
   feature. Every migration writes a safety copy first, using the *old* schema's
   writer, before new code touches anything.
4. **Storage is canonical.** Distance in integer metres, volume in integer
   millilitres, energy in watt-hours, money in integer minor units plus an ISO
   4217 code. Never store a converted or rounded value; convert on read.
5. **Derived values are never persisted.** Consumption, cost per km, monthly
   totals, next-due dates and due status are pure functions computed at read
   time. A stored due date survives an import and is then wrong forever.
6. **Six locales or none.** `en`, `de`, `fr`, `fa`, `ar`, `ckb` — three of them
   right-to-left. Every user-visible string lands in all six ARB files in the
   same commit.
7. **Never guess in a way that looks like fact.** An estimated odometer is
   prefixed `~`, a projected date is fuzzy ("around mid-October"), a broken fuel
   segment is discarded rather than averaged, and an item with no history says
   `unknown`, never `overdue`. The app would rather show a dash than a plausible
   lie. This is the rule most easily broken by accident.

## How to work

- Read `SPEC.md` for the area first. Cite the section in the PR.
- Domain logic is **pure Dart with no Flutter import** — the due engine, the
  fuel maths, unit conversion, the projection. It must test in milliseconds
  without a widget harness. If you find yourself needing a `BuildContext` in
  domain code, the layering is wrong.
- Prefer deleting to adding. Screen count is a cost; a statistic nobody acts on
  is clutter.
- When the spec is genuinely silent, decide, do it, and say so in the PR rather
  than stopping to ask. When it is silent on something load-bearing, add it to
  §18 Decisions still open.

## TDD

Write the failing test first for anything in the domain layer. The due engine
and the fuel engine each have a fixture suite in the definition of done (SPEC
§17) — every combination of `{distance-only, time-only, both} × {ok, due_soon,
due, overdue, unknown, needs_odometer, paused}`, and first fill / partials /
`chain_broken` / missing odometer / bi-fuel / EV respectively. Those suites are
the specification made executable; extend them rather than writing ad-hoc tests
beside them.

Every gate must have been **seen to fail**. `tools/check_gates_selftest.sh`
plants a real violation for each gate and asserts both arms. New gate, new
self-test — otherwise it is a comment that runs.

## Languages and RTL

- No layout code uses `left` or `right`. Padding, alignment, insets and swipe
  actions are `start` / `end`. A hard-coded `left`/`right` outside the icon-asset
  layer is a bug.
- ICU messages with real CLDR plural categories. Arabic needs all six; French
  needs three. No string concatenation, ever — it cannot be translated.
- Numbers, dates and currency come from the formatter, never from
  interpolation. A number and its unit are one atomic isolate-wrapped run.
- Digits are per-locale: Latin for `en`/`de`/`fr`, Arabic-Indic `٠١٢٣` for `ar`,
  Extended Arabic-Indic `۰۱۲۳` for `fa`/`ckb`. Persian uses the Jalali calendar.
  Defaults resolve from the device **region**, not the language (SPEC §5) —
  `ar-MA` gets Latin digits, `ckb-IR` gets Jalali.
- Kurdish Sorani needs `ڕ ڵ ۆ ێ ھ ە چ ژ گ پ ک ی` in all four joining forms.
  Most Arabic fonts render some of these badly; check before choosing one.
- Test in at least one LTR and one RTL locale. German is ~30% longer than
  English and is what breaks button layouts.

## Do not

- Add a dependency without checking its transitive tree for a network path.
- Store a derived value, a converted unit, or a rounded number.
- Write a user-visible string in only one ARB file.
- Use `left`/`right` in layout.
- Commit signing material. `tools/check_release_hygiene.sh` walks `git log --all`,
  because a credential committed and later deleted is in every clone forever.
- Commit a real backup file as a test fixture. Synthetic fixtures go in
  `test/fixtures/` named `*.fixture.json`.
- Add photos or attachments — withdrawn from v1 (SPEC §2), and an attachment
  store is a second durability problem, a second export format and a second
  privacy conversation.
- Reintroduce anything in §15 Explicitly out of v1 without changing the spec
  first.
