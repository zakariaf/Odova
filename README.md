<div align="center">

# Odova

**Your car, handled.**

An offline, account-free log for car maintenance, fuel and running costs.

[![ci](https://github.com/zakariaf/Odova/actions/workflows/ci.yml/badge.svg)](https://github.com/zakariaf/Odova/actions/workflows/ci.yml)
![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20Android-2B3A42)
![flutter](https://img.shields.io/badge/flutter-3.44.6-02569B)
![network calls](https://img.shields.io/badge/network%20calls-zero-1F7A55)
![locales](https://img.shields.io/badge/locales-6%20·%20LTR%20%2B%20RTL-6B4E9B)
[![licence](https://img.shields.io/badge/licence-Apache--2.0-blue)](LICENSE)

</div>

---

Most people look after their car by remembering. They remember the oil was
changed "sometime last spring", they keep a fuel receipt in the door pocket, and
they find out the timing belt was overdue when it breaks.

Odova replaces remembering with a phone that already knows. You add your car and
its current odometer reading. It tracks what has been done and works out what is
due next — **by distance and by date, whichever comes first** — and tells you
before it becomes a repair bill instead of a service.

The home screen answers one question: **what does my car need next?** Everything
else in the app exists to make that answer correct.

## What it does

- **Service reminders** — oil and filter, brake pads, tyres, coolant, battery,
  timing belt, inspection, and anything you add. Each is due at an interval *and*
  a date; the app watches both.
- **Fuel tracking** — log a fill-up in a few taps. Real consumption
  (L/100 km, km/L, MPG US or imperial), cost per fill, and whether the car is
  quietly getting thirstier.
- **Mileage log** — odometer readings over time, so every reminder stays accurate
  without you doing arithmetic.
- **Trips and expenses** — what the car actually costs: fuel, service, insurance,
  tax, parking, tolls, per month and per kilometre.
- **Service history** — every job, date, reading and price in one place. Worth
  real money when you sell the car.
- **More than one vehicle** — the second car, the motorbike, the work van.

## The rules it is built to

| Rule | What it means for you |
|---|---|
| **No account** | No sign-up, no email, no password. Open it and use it. |
| **No server, no sync, no analytics** | The app ships with no networking code. Nothing leaves your phone because there is nothing to leave through. |
| **Offline, always** | It works in a basement car park in aeroplane mode, forever. |
| **Your backup is a plain JSON file** | Export it, keep it wherever you like, read it in a text editor. No password to lose, no account to recover. |
| **Six languages, both directions** | English, Deutsch, Français, فارسی, العربية, کوردیی ناوەندی — right-to-left is a first-class target, not a port. |
| **Calm** | It tells you what matters and stays quiet otherwise. At most two notifications in any seven days, across every vehicle combined. |

## Repo state

**Scaffold stage.** `SPEC.md` is complete and is the source of truth. The
Flutter app exists and is empty on purpose: it launches, it speaks six
languages, and every gate around it is armed and has been seen to fail. There
is no theme, no database and no screen yet — those are EPIC-02 onward. All
three CI lanes run: `repo gates`, `flutter`, `android build`.

| File | What it is |
|---|---|
| [`SPEC.md`](SPEC.md) | The full specification — data model, due engine, six-locale contract, backup format, every screen and every navigation edge. 18 sections. |
| [`IDEA.md`](IDEA.md) | The idea in plain words, plus the naming research: how the name was chosen and what was checked against both app stores. |
| [`design/`](design/README.md) | Three candidate design systems, each covering all 28 screens, with 340 reference screenshots in light/dark and LTR/RTL. |
| [`epics/`](epics/README.md) | 19 executable build epics derived from the spec — 182 TDD tasks, each screen task gated against its reference screenshot. |
| [`.claude/`](.claude/README.md) | 47 Flutter engineering skills — 40 vendored, 7 written here for the Calm design system. |
| `lib/` | The app. Seven directories with a stated owner each — `app core data features l10n theme ui` — and a policy test that keeps the list at seven. |
| `tools/` | Repo gates, the design mockup pipeline, and the app-name availability checker. |

Start with **§1 Who it is for** and **§2 Non-negotiables**. If you are about to
propose a feature, read **§15 Explicitly out of v1** first.

## Building

```bash
flutter --version           # must match .flutter-version (3.44.6)
flutter pub get --enforce-lockfile
flutter test
flutter run
```

Repo gates, which run with no Flutter toolchain at all:

```bash
bash tools/check_gates_selftest.sh    # proves each gate can fail
bash tools/check_release_hygiene.sh   # no signing material, tree or history
bash tools/check_dependabot.sh        # the pub block is armed, not commented
python3 tools/check_spec_examples.py  # SPEC.md's JSON examples parse
```

Gates that need the resolved dependency tree, so a `flutter pub get` first:

```bash
# --require-graph: without it the audit exits 0 when it cannot resolve the
# tree, having walked nothing. CI passes it and so should you.
bash tools/audit_deps.sh --require-graph   # no dependency opens a network path
bash tools/check_lint_include.sh      # the lint ruleset is actually loaded
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The short version: the spec is decided
before the code is, every user-visible string lands in all six locales at once,
and no dependency may open a network path.

**Native Persian, Arabic and Kurdish Sorani readers are especially welcome** —
`SPEC.md` §18 lists open questions that only a native reader can settle, and
Sorani translation quality is the single largest risk to the launch.

## Licence

[Apache 2.0](LICENSE) © 2026 Zakaria Fatahi. Episode 6 of a 50-app challenge.
