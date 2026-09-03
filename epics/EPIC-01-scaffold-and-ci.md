# EPIC-01 — Project scaffold, toolchain and CI

| | |
|---|---|
| **Epic** | EPIC-01 — Project scaffold, toolchain and CI |
| **Depends on** | nothing |
| **Estimate** | **5 h (CC) · ~5 weeks (human)** over 8 tasks |
| **Spec sections** | §2 Non-negotiables · §17 Definition of done for v1 |
| **Screens** | none |

The rules every epic inherits — TDD without exception, tests run per task, `/simplify`
then `/code-review` at the end, `SPEC.md` wins — are stated once in `epics/README.md`.
They apply here in full.

---

## Where we are now

There is no Flutter app. Not a stub, not a broken one — there is no `pubspec.yaml`, no
`lib/`, no `android/`, no `ios/`, no `test/`. What the repo holds today is the
specification and everything written *around* an app that does not exist yet:

| Exists | State |
|---|---|
| `SPEC.md` | Complete, 18 sections, the source of truth. |
| `design/calm/odova.css`, `system.html`, `screens.html` | The chosen design system, 124 custom properties. |
| `design/reference/calm/` | 112 reference PNGs — 28 screens × light/dark × LTR/RTL. |
| `design/_fonts/Vazirmatn.woff2` | The mockup font. **woff2 — Flutter cannot load it.** EPIC-02's problem. |
| `.claude/skills/` | 47 skills, `CLAUDE.md`, and the `calm-*` gate scripts they ship. |
| `tools/` | `check_gates_selftest.sh`, `check_release_hygiene.sh`, `check_spec_examples.py`, `check_skill_frontmatter.py`, plus the Node design pipeline in `tools/package.json`. |
| `.github/workflows/ci.yml` | Runs today. The `repo` job is live; the `app` and `build` jobs are gated on `needs.repo.outputs.has_app` and skip. |
| `analysis_options.yaml` | **Inert.** `include: package:very_good_analysis/analysis_options.10.3.0.yaml` resolves to nothing without the dependency. |
| `l10n.yaml` | **Inert.** Points at `lib/l10n/arb`, which does not exist. |
| `.github/dependabot.yml` | The `pub` block is commented out, deliberately — Dependabot aborts the whole job with "/pubspec.yaml not found". |
| `.flutter-version` | `3.44.6`. A bare version string, not a structured file. |
| `.gitignore` | Already says, in a comment, that `pubspec.lock` is deliberately not ignored. |

Three of those files are loaded weapons pointed at a foot. `analysis_options.yaml` with
no `very_good_analysis` dependency does not fail — it reports **green while checking
nothing**, because an unresolvable `include:` only becomes the fatal
`include_file_not_found` when the package is resolvable and the *file* is missing. A
green analyzer over zero rules is the worst state this repo can be in, and it is one
`git add` away.

This epic makes all of that live, in a shape the next eleven epics inherit without
revisiting.

## What we will have when this is done

- `flutter run` starts an app called **Odova** on an iOS 15+ / Android API 26+ device.
  It shows one screen with the app name in the Calm-less default theme — there is
  deliberately no design here; EPIC-02 brings the theme and EPIC-05 onward bring screens.
- `flutter analyze --fatal-infos --fatal-warnings` runs `very_good_analysis` 10.3.0's
  real ruleset, and you can prove it does: deleting a rule from the include makes a
  planted violation go quiet, and the self-test asserts exactly that.
- `flutter test` is green and `flutter gen-l10n` produces `lib/l10n/gen/` from six ARB
  files — `en de fr fa ar ckb` — which are committed and match.
- `bash tools/audit_deps.sh` refuses `http`, `dio`, `google_fonts`, `firebase_*`,
  `sentry_flutter` and every analytics SDK, walking the **resolved transitive tree**, not
  the pubspec. `bash tools/check_gates_selftest.sh` proves it can go red.
- CI on GitHub shows three green jobs — `repo gates`, `flutter`, `android build` — where
  today it shows one green and two skipped. Dependabot opens grouped `deps` PRs weekly.
- `README.md` §Repo state and `CHANGELOG.md` no longer say "the Flutter app has not been
  created yet", because it has.

What we deliberately will **not** have: any Calm token, any screen, any route beyond the
one placeholder, any database, any domain type. This epic ships an empty, correct,
gated app.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door. Rules 1, 4, 8, 9, 14 are decided here and every later epic inherits them from this scaffold. |
| `project-structure-and-packages` | Owns the physical tree — single package, feature-first, `pubspec.lock` committed, no `lib/src` in the app, no `utils/` junk drawer. Task 1.3 is this skill. |
| `dependency-hygiene` | Caret ranges + committed lock, the transitive audit, and the lint-include-vs-resolved-SDK trap that `analysis_options.yaml` warns about in its own header. Ships `scripts/audit-deps.sh` and `audit_deps.py`, which task 1.6 vendors. |
| `lint-and-style-config` | Why `--fatal-infos` is load-bearing, and rule 5: an `errors:` promotion only re-ranks a rule the base set already enables. The nine promotions in `analysis_options.yaml` must be verified against VGA 10.3.0, not assumed. |
| `ci-pipeline-and-gates` | Every gate maps to one named contract; pin the runner and the toolchain; the three-criteria bar a grep gate must clear; gates verify and never mutate. |
| `app-startup-and-bootstrap` | Task 1.5 is its sequence verbatim: handlers first, exactly two, no `runZonedGuarded`, real infra built in `bootstrap()` and injected via overrides, Riverpod `retry` tuned for a local-only failure model. |
| `state-management-riverpod` | Riverpod 3.x is state *and* DI. Establishing that now is what stops `get_it` arriving in epic seven. |
| `i18n-rtl-l10n` | Six ARB files land together or none do (`CLAUDE.md` rule 6). Task 1.4 arms `gen-l10n` and the `ckb` delegate gap. |
| `testing-strategy` | The `test/` mirror, `test/support/`, and `test/policy/` for the cross-cutting greps. Everything after this epic writes tests into the shape task 1.7 builds. |

`calm-visual-parity` is **not** listed: this epic builds no screen. The first epic that
does carries it.

---

## Tasks

### Task 1.1 — Create the Flutter app

- **Goal** — `flutter run` starts an app named Odova with bundle id `io.applander.odova`,
  on the pinned toolchain, for iOS and Android only.
- **Spec** — §2 Non-negotiables (no network permission it can avoid); §17 Definition of
  done for v1 → *Targets* (iOS 15+, Android 8.0 / API 26+, floor 375×667).
- **Skills** — `project-structure-and-packages`, `dependency-hygiene`.
- **Write these tests first**
  - `test/policy/toolchain_test.dart` → `'pubspec environment sdk is a range, not a pin'`:
    reads `pubspec.yaml`, asserts `environment.sdk` matches `^3.` and contains no exact
    version. Fails today because there is no pubspec.
  - `test/policy/toolchain_test.dart` → `'the pinned Flutter version is 3.44.6 and lives in .flutter-version only'`:
    asserts `.flutter-version` reads `3.44.6` and that `pubspec.yaml` has no
    `environment: flutter:` key duplicating it. Two records of one fact drift.
  - `test/policy/platform_test.dart` → `'android applicationId is io.applander.odova'` and
    `'ios PRODUCT_BUNDLE_IDENTIFIER is io.applander.odova'`: greps
    `android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj`. Fails on the
    `com.example.` default `flutter create` writes when `--org` is forgotten.
  - `test/policy/platform_test.dart` → `'minSdk is 26 and iOS deployment target is 15.0'`:
    §17's floor is a number in two build files, and the default is lower than both.
  - `test/policy/platform_test.dart` → `'no INTERNET permission in any AndroidManifest'`:
    walks `android/app/src/*/AndroidManifest.xml` and asserts
    `android.permission.INTERNET` appears in none of them — **including the debug and
    profile manifests**, which `flutter create` writes it into by default for hot reload.
    This is §2's first non-negotiable made mechanical.
- **Then build**
  - `flutter create --org io.applander --project-name odova --platforms=ios,android
    --empty .` in the repo root. `--empty` skips the counter demo; if the installed
    Flutter writes one anyway, delete `lib/main.dart`'s counter and `test/widget_test.dart`
    rather than leaving template code to rot.
  - Set `minSdk = 26` in `android/app/build.gradle.kts` and
    `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in the Xcode project + `ios/Podfile`.
  - Delete `<uses-permission android:name="android.permission.INTERNET"/>` from
    `android/app/src/debug/AndroidManifest.xml` and `.../profile/AndroidManifest.xml`.
    Hot reload over USB still works; it is the network *permission* the store listing
    claims we do not hold.
  - `flutter pub get` and **commit `pubspec.lock`**. Confirm `.gitignore` does not ignore
    it — it does not today, and its comment says why.
- **Verify**
  ```bash
  flutter --version                       # 3.44.6, matching .flutter-version
  flutter pub get --enforce-lockfile
  flutter test test/policy/
  flutter run                             # the app launches
  git status --short pubspec.lock         # tracked, not ignored
  ```
- **Done when**
  - [ ] All five policy tests pass, and each was seen red before the app existed.
  - [ ] `pubspec.lock` is committed and `flutter pub get --enforce-lockfile` succeeds.
  - [ ] No `com.example` string survives anywhere under `android/` or `ios/`.
  - [ ] No `INTERNET` permission in any of the three manifests.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 1.2 — Arm the analyzer, and prove it is actually checking something

- **Goal** — `flutter analyze` runs `very_good_analysis` 10.3.0's real ruleset with the
  nine promotions in `analysis_options.yaml` live, and a gate exists that fails if it ever
  silently stops.
- **Spec** — §17 (the whole list is unenforceable if the analyzer is checking nothing).
- **Skills** — `lint-and-style-config`, `dependency-hygiene`, `ci-pipeline-and-gates`.
- **Write these tests first**
  - New arm in `tools/check_gates_selftest.sh`, section `== check_lint_include ==`:
    - `'green on the real analysis_options.yaml'` — `bash tools/check_lint_include.sh`
      exits 0.
    - `'red when the include names a file the resolved package does not ship'` — rewrite
      the `include:` to `analysis_options.99.9.9.yaml`, assert non-zero, restore, assert
      green again. This is the exact failure `analysis_options.yaml`'s own header warns
      about, and until this arm exists nobody has seen it happen.
  - `test/policy/lint_test.dart` → `'every rule promoted under errors: is enabled by the base ruleset'`:
    parses the `errors:` map in `analysis_options.yaml` and asserts each of the nine names
    (`unawaited_futures`, `discarded_futures`, `empty_catches`,
    `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`,
    `avoid_dynamic_calls`, `exhaustive_cases`, `avoid_print`) appears in the resolved
    `very_good_analysis` include file. `errors:` re-ranks; it cannot turn an off rule on,
    so a promotion of a rule VGA does not enable is a line that does nothing
    (`lint-and-style-config`, rule 5). `close_sinks` is the one the file already flags as
    shipped at `ignore` and re-promoted — that is the case this test is for.
  - `test/policy/lint_test.dart` → `'the generated-code excludes are read from analysis_options.yaml, never retyped'`:
    asserts the four glob patterns (`**/*.g.dart`, `**/*.freezed.dart`, `**/*.drift.dart`,
    `lib/l10n/gen/**`) are read by whatever consumes them, not duplicated in a second file.
    The header of `analysis_options.yaml` states this contract; this test is it.
- **Then build**
  - Add `very_good_analysis: ^10.3.0` to `dev_dependencies`. Caret range, never an exact
    pin (`dependency-hygiene` rule 1); the lock is the pin.
  - Write `tools/check_lint_include.sh`: resolve the package directory from
    `.dart_tool/package_config.json`, parse the `include:` line out of
    `analysis_options.yaml`, and assert the named file exists on disk. Exit non-zero with
    the filename if it does not.
  - Register the new gate in `tools/check_gates_selftest.sh` following the existing
    `assert <want> <label> <command...>` shape.
- **Verify**
  ```bash
  flutter pub get
  bash tools/check_lint_include.sh        # names the resolved file and exits 0
  bash tools/check_gates_selftest.sh      # the new arms show ok/ok/ok
  flutter analyze --fatal-infos --fatal-warnings
  dart format --output=none --set-exit-if-changed .
  flutter test test/policy/lint_test.dart
  ```
  A pass means `flutter analyze` reports at least one finding when you plant
  `print('x');` in `lib/main.dart` — do that once, by hand, and then remove it. An
  analyzer that has never said no has not been tested.
- **Done when**
  - [ ] `very_good_analysis` is a dev_dependency with a caret range; `pubspec.lock` updated
        in the same commit.
  - [ ] `tools/check_lint_include.sh` exists and both of its self-test arms are seen.
  - [ ] All nine `errors:` promotions are confirmed present in VGA 10.3.0's ruleset, and
        any that are not are removed from `analysis_options.yaml` with a note in the
        progress file.
  - [ ] `flutter analyze --fatal-infos --fatal-warnings` and `dart format` are clean.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 1.3 — Establish the folder layout

- **Goal** — `lib/` has the seven directories every later epic writes into, each with a
  stated owner, and a test that fails when code lands somewhere it does not belong.
- **Spec** — §2 (derived values are never persisted — the `core/` boundary is what makes
  that greppable); §17 (the pure core must test in milliseconds).
- **Skills** — `project-structure-and-packages`, `flutter-architecture`,
  `naming-conventions`.
- **Write these tests first**
  - `test/policy/structure_test.dart` → `'lib/ contains exactly the seven sanctioned directories'`:
    asserts the direct children of `lib/` are `app`, `core`, `data`, `features`, `l10n`,
    `theme`, `ui` plus `main.dart`, and nothing else. A new top-level folder is a
    deliberate decision, not a side effect of a hurried commit.
  - `test/policy/structure_test.dart` → `'lib/core imports no Flutter'`: walks every
    `.dart` under `lib/core/` and asserts no `package:flutter/`, no `dart:ui`, no
    `dart:io` import. `CLAUDE.md`: the due engine, the fuel maths, unit conversion and the
    projection are pure Dart. This test is the only thing that keeps that true as the app
    grows.
  - `test/policy/structure_test.dart` → `'no feature imports another feature'`: for each
    `lib/features/<a>/**`, asserts no import path contains `features/<b>/` where `b != a`.
    Two features share code by lifting it down to `core`/`data`, or they meet via a route.
  - `test/policy/structure_test.dart` → `'no junk-drawer directory'`: asserts no directory
    under `lib/` is named `utils`, `helpers`, `common`, `misc` or `shared`.
  - `test/policy/structure_test.dart` → `'every lib/ directory has a mirror under test/'`:
    asserts the `test/` tree mirrors `lib/` 1:1 for every directory that contains a
    `.dart` file.
- **Then build**
  - Create `lib/app/`, `lib/core/`, `lib/data/`, `lib/features/`, `lib/l10n/`,
    `lib/theme/`, `lib/ui/`, each with a `README.md` naming its owner in one sentence and
    the skill that governs it. An empty directory does not survive git; a README that says
    what belongs there does two jobs.
  - The mapping against `project-structure-and-packages`, stated once so nobody
    re-litigates it: the skill puts `main.dart`, `bootstrap.dart` and `app.dart` at the
    `lib/` root and adds top-level `routing/` and `services/`. Odova folds `bootstrap.dart`,
    `app.dart`, the `go_router` config and the injectable service ports into **`lib/app/`**,
    and adds **`lib/ui/`** for the design-system component layer the `calm-*` skills write
    against (`lib/ui/calm/`). Everything else is the skill verbatim. Record the deviation
    in `lib/app/README.md` with this reason, and in the progress file.
  - `test/support/` (shared fakes and the `pumpApp` harness, populated by later epics) and
    `test/policy/` (these cross-cutting greps).
- **Verify**
  ```bash
  flutter test test/policy/structure_test.dart
  flutter analyze --fatal-infos --fatal-warnings
  find lib -maxdepth 1 -type d | sort     # the seven, and nothing else
  ```
- **Done when**
  - [ ] Five structure tests pass; the feature-isolation and pure-core ones were each seen
        red against a planted violation.
  - [ ] Every one of the seven directories has a README naming its owner and its skill.
  - [ ] The deviation from `project-structure-and-packages` is written down in
        `lib/app/README.md`, not left as folklore.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 1.4 — Arm `l10n.yaml` and land all six locales

- **Goal** — `flutter gen-l10n` produces a committed `lib/l10n/gen/` from six ARB files,
  `AppLocalizations.of` is non-null, and CI is red on a stale generation.
- **Spec** — §5 Languages, RTL and formats (the six locales, the selection ladder, `ckb`
  and its `extarab` digits); §2 (six languages from day one, both directions).
- **Skills** — `i18n-rtl-l10n`, `ci-pipeline-and-gates`, `testing-strategy`.
- **Write these tests first**
  - `test/l10n/arb_parity_test.dart` → `'all six ARB files exist'`: asserts
    `lib/l10n/arb/app_{en,de,fr,fa,ar,ckb}.arb` are all present. `CLAUDE.md` rule 6 — six
    locales or none.
  - `test/l10n/arb_parity_test.dart` → `'every key in app_en.arb exists in all five others'`
    and `'no locale has a key app_en.arb does not'`: a dead key and a missing key are
    different bugs and both are silent.
  - `test/l10n/arb_parity_test.dart` → `'no ARB value contains a bare digit'`: greps every
    value for `[0-9٠-٩۰-۹]` outside an ICU placeholder. §5 forbids two digit sets on one
    screen, and a literal `100` in a string is exactly how that happens
    (`calm-typography-and-rtl` rule 10).
  - `test/l10n/supported_locales_test.dart` → `'supportedLocales is exactly en de fr fa ar ckb'`:
    asserts the list on the root `MaterialApp`, in that order, `en` first so a missing key
    falls back to a language the maintainer can read.
  - `test/l10n/supported_locales_test.dart` → `'fa, ar and ckb resolve to TextDirection.rtl'`:
    pumps the app under each locale and reads `Directionality.of`. **`ckb` is the one that
    will fail**: it is not in `GlobalMaterialLocalizations`' supported set and `intl`'s
    `Bidi` tables may not classify it as RTL. When it fails, the fix is a
    `LocalizationsDelegate` in `lib/l10n/` that supplies `ckb` from the `ar` Material
    delegate plus an explicit `TextDirection.rtl` — not dropping the locale.
  - `test/l10n/supported_locales_test.dart` → `'AppLocalizations.of returns non-null'`:
    `nullable-getter: false` is set in `l10n.yaml`; this asserts the generated signature
    actually honours it, so a missing key stays a compile error.
- **Then build**
  - `lib/l10n/arb/app_en.arb` with the single key `appTitle` → `"Odova"`, plus `@appTitle`
    with a description saying it is a brand name and identical in all six. Copy to the
    other five. One key is enough to arm the pipeline; real strings arrive with the
    screens that need them, six at a time.
  - `flutter gen-l10n`, then **commit `lib/l10n/gen/`**. CI runs the generator and
    `git diff --exit-code` over that directory — a stale generation compiles and serves
    yesterday's strings, which review does not catch across six locales.
  - Wire `localizationsDelegates` and `supportedLocales` on the root app widget in
    `lib/app/`, including whatever `ckb` needs.
  - Add `flutter_localizations` (sdk) and `intl` to `pubspec.yaml`.
- **Verify**
  ```bash
  flutter gen-l10n
  git diff --exit-code -- lib/l10n/gen/   # the CI contract, run locally first
  flutter test test/l10n/
  flutter analyze --fatal-infos --fatal-warnings
  ```
- **Done when**
  - [ ] Six ARB files, one key, all in sync; the parity tests pass.
  - [ ] `lib/l10n/gen/` is committed and `git diff --exit-code` over it is clean after a
        fresh `gen-l10n`.
  - [ ] `ckb` resolves RTL, and whatever delegate that needed is written down in the
        progress file for the i18n epic to build on.
  - [ ] `AppLocalizations.of` is non-null in the generated code.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 1.5 — Riverpod 3.x, `bootstrap()` and the error net

- **Goal** — the app launches through a composition root that installs error handlers
  before anything that can throw, builds infra once, and injects it by provider override.
- **Spec** — §2 (data survives app updates — the first thing that will ever throw on this
  path is opening the database, and a crash before the handlers are installed is invisible
  forever); §17 *Scale gate* (cold launch to interactive Home under 2.0 s).
- **Skills** — `app-startup-and-bootstrap`, `state-management-riverpod`, `async-safety`.
- **Write these tests first**
  - `test/app/bootstrap_test.dart` → `'installErrorHandlers sets both FlutterError.onError and PlatformDispatcher.onError'`:
    asserts both are non-null after the call, and that neither is the framework default.
  - `test/app/bootstrap_test.dart` → `'PlatformDispatcher.onError returns true unconditionally'`:
    feeds it an error and asserts `true`. Returning `false` routes to the embedder
    fallback, where the process may exit or hang.
  - `test/app/bootstrap_test.dart` → `'an error handler that is handed a throwing sink does not itself throw'`:
    injects a crash sink whose `write` throws; asserts the handler swallows it. Without
    the bare `try/catch (_)`, the handler recurses into itself.
  - `test/app/bootstrap_test.dart` → `'main installs no zone'`: greps `lib/main.dart` and
    `lib/app/bootstrap.dart` for `runZonedGuarded` and asserts absent. Two handlers cover
    every path; a zone with no crash SDK buys nothing and costs a documented mismatch
    footgun (`app-startup-and-bootstrap`, rule 2).
  - `test/app/providers_test.dart` → `'every placeholder provider throws until overridden'`:
    reads each placeholder from a bare `ProviderContainer.test()` and asserts it throws
    with a message naming the provider. A forgotten wiring must fail loudly at startup,
    never return null.
  - `test/app/providers_test.dart` → `'the root ProviderScope disables retry'`: asserts the
    configured `retry` returns `null`. Riverpod 3 retries a failing provider for ~38 s by
    default; Odova's only provider failures are local bugs — a corrupt DB, a missing file
    — and a bug behind a spinner is worse than a bug on screen.
  - `test/app/providers_test.dart` → `'no get_it, no package:provider, no legacy StateNotifierProvider anywhere in lib/'`:
    a grep policy test. One composition model, decided now.
- **Then build**
  - `lib/main.dart` — thin: `WidgetsFlutterBinding.ensureInitialized()`, open the crash
    sink, `installErrorHandlers`, `await bootstrap()`, `runApp`. Nothing else.
  - `lib/app/bootstrap.dart` — the composition root. Returns the built infra; overrides the
    placeholder providers in the root `ProviderScope` with `overrideWithValue`.
  - `lib/app/error_handlers.dart` — exactly two handlers, each with the comment saying why
    its discarded error is deliberate. Unwrap `ProviderException` before logging, or every
    entry reads `ProviderException` and hides the real cause.
  - `lib/app/app.dart` — `MaterialApp` (router wiring lands in the navigation epic), the
    localizations delegates from task 1.4, and a single placeholder home showing
    `AppLocalizations.of(context).appTitle`.
  - `lib/app/lifecycle_observer.dart` — one `WidgetsBindingObserver` that flushes durable
    state on `inactive`/`paused`. Nothing to flush yet; the seam exists so the persistence
    epic does not invent a second one. Read services with `ref.read`, never `watch`.
  - Add `flutter_riverpod: ^3.0.0` (or the current 3.x caret range) and `clock`.
- **Verify**
  ```bash
  flutter test test/app/
  flutter analyze --fatal-infos --fatal-warnings
  flutter run                             # launches; the placeholder shows "Odova"
  ```
- **Done when**
  - [ ] All seven tests pass.
  - [ ] `lib/main.dart` is under 40 lines and contains no `runZonedGuarded`.
  - [ ] Every placeholder provider throws with a message naming itself.
  - [ ] The lifecycle observer is registered exactly once.
- **Estimate** — 1 h (CC) · ~1 week (human)

---

### Task 1.6 — The dependency policy gate

- **Goal** — a script, not good intentions, refuses any dependency that opens a network
  path — directly or transitively — and it has been seen to go red.
- **Spec** — §2 Non-negotiables (no network call of any kind; the app ships with no
  networking code); §17 *Offline gate* ("A dependency-graph check for networking APIs runs
  in CI and fails the build").
- **Skills** — `dependency-hygiene`, `ci-pipeline-and-gates`.
- **Write these tests first** — this gate's tests are self-test arms, because the thing
  under test is a script. New section in `tools/check_gates_selftest.sh`,
  `== audit_deps ==`:
  - `'green on the real dependency tree'` — `bash tools/audit_deps.sh` exits 0 against the
    tree task 1.5 left behind.
  - `'red when http is added'` — `dart pub add http --dry-run` is not enough; plant `http`
    in `pubspec.yaml`, run `flutter pub get`, assert non-zero, restore both `pubspec.yaml`
    and `pubspec.lock`, assert green again.
  - `'red on a TRANSITIVE hit'` — the arm that matters. Direct-only inspection of
    `pubspec.yaml` cannot find the second hop, which is exactly where a banned SDK
    arrives. Plant a package whose resolved tree pulls a banned name, assert non-zero,
    restore. If no such package can be planted cheaply, fake it by injecting a synthetic
    node into the `dart pub deps --json` fixture the Python script reads, and say so in a
    comment.
  - `'red when pubspec.lock is missing'` and `'red on an exact version pin in pubspec.yaml'`
    — both already implemented in the vendored script; both need an arm, because a gate
    that has only ever been green is a comment (`CLAUDE.md`).
- **Then build**
  - Vendor `.claude/skills/dependency-hygiene/scripts/audit-deps.sh` and `audit_deps.py`
    into `tools/` as `audit_deps.sh` and `audit_deps.py`. `tools/` is where this repo's
    gates live and where CI and the self-test look.
  - Edit the `BANNED` list to Odova's policy, naming each refusal:
    `http`, `dio`, `web_socket*`, `grpc`, `socket_io*`, `google_fonts`, `firebase_*`,
    `cloud_fire*`, `crashlytics`, `sentry*`, `*analytics*`, `posthog|mixpanel|amplitude|segment`,
    `google_mobile_ads|appsflyer|adjust`, `googleapis|google_sign_in`. `google_fonts` is
    not in the skill's default list and must be added — it is `CLAUDE.md` rule 1's named
    refusal and `calm-tokens`' too, and it ships an HTTP path for a font we bundle.
  - Decide `package_info_plus` explicitly and write the decision in the `ALLOW` list with
    its justification, or keep it banned. §6/§17 put `app_version` and `app_build` in the
    export file, so this is a real question and not a hypothetical: either allow it with a
    written reason, or inject the version at build time with `--dart-define` and keep the
    ban. Whichever is chosen, the `ALLOW` entry or the absence of one is the record.
  - Register the gate in `tools/check_gates_selftest.sh`.
- **Verify**
  ```bash
  flutter pub get
  bash tools/audit_deps.sh                # walks the resolved tree, exits 0
  bash tools/check_gates_selftest.sh      # the new arms show ok on both sides
  ```
- **Done when**
  - [ ] `tools/audit_deps.sh` + `tools/audit_deps.py` exist, are executable, and pass
        `bash -n` (the `repo` job already checks that for every `tools/*.sh`).
  - [ ] All five self-test arms pass, including the transitive one.
  - [ ] `google_fonts` is in `BANNED` with a stated reason.
  - [ ] The `package_info_plus` decision is written down, either as an `ALLOW` entry with
        a justification or in the progress file as "banned; version comes from
        `--dart-define`".
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 1.7 — The test harness and the coverage report

- **Goal** — `flutter test` runs with randomized ordering and collects coverage in the
  same pass, and later epics have a `test/support/` to write into rather than inventing
  one each.
- **Spec** — §17 (every gate in the definition of done is a test somebody has to be able
  to write cheaply).
- **Skills** — `testing-strategy`, `ci-pipeline-and-gates`, `widget-golden-and-a11y-testing`.
- **Write these tests first**
  - `test/support/pump_app.dart` is a harness, not a test — but it needs its own:
    `test/support/pump_app_test.dart` → `'pumpApp installs localizations, a ProviderScope and a pinned ThemeMode'`:
    pumps a trivial widget through it and asserts `AppLocalizations.of` resolves, that a
    provider override applies, and that `MediaQuery.textScalerOf` is **not** clamped.
  - `test/support/pump_app_test.dart` → `'pumpApp accepts locale and themeMode and applies both'`:
    the four-way theme/direction matrix later epics need for parity capture starts here.
    Pinning `ThemeMode` in the harness is what stops the commonest parity failure —
    *"belongs to the dark palette — this build is in the wrong theme"* — which
    `calm-visual-parity` says is almost always the test, not the screen.
  - `test/policy/coverage_test.dart` → `'the coverage filter and the analyzer excludes are the same list'`:
    parses `analysis_options.yaml`'s `analyzer.exclude` and asserts the coverage
    post-processing strips exactly those globs. Excludes and coverage filters that drift
    apart lie the coverage number upward — `analysis_options.yaml` says so in its own
    comment, and this is the test that keeps it true.
- **Then build**
  - `test/support/pump_app.dart` — `pumpApp(tester, child, {locale, themeMode, overrides})`.
    Do not clamp the text scaler; §17's accessibility gate needs 200% to be reachable.
  - `test/support/fakes.dart` — an empty barrel with a comment naming what belongs there
    (fake repositories and services, never a faked `Notifier`).
  - `tools/strip_generated_from_lcov.sh` — removes the generated-code globs from
    `coverage/lcov.info` after the run. Coverage is a **published report, never a gate**:
    no threshold, no paid service.
- **Verify**
  ```bash
  flutter test --coverage --test-randomize-ordering-seed random
  bash tools/strip_generated_from_lcov.sh coverage/lcov.info
  grep -c 'SF:' coverage/lcov.info        # no lib/l10n/gen or *.g.dart entries
  ```
- **Done when**
  - [ ] `pumpApp` exists, takes locale and themeMode, and does not clamp text scale.
  - [ ] `flutter test --test-randomize-ordering-seed random` is green over three
        consecutive runs with different seeds — that is the point of the flag.
  - [ ] `coverage/lcov.info` contains no generated file.
  - [ ] No coverage threshold exists anywhere in CI.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

### Task 1.8 — Arm CI and Dependabot, and tell the truth in the README

- **Goal** — the `flutter` and `android build` jobs run and go green on a real push, the
  new gates are wired into the `repo` job, and no committed document still claims the app
  does not exist.
- **Spec** — §17 (CI is where most of the definition of done eventually lives);
  §2 (the dependency policy has to be enforced on every Dependabot bump, not just ours).
- **Skills** — `ci-pipeline-and-gates`, `dependency-hygiene`.
- **Write these tests first**
  - `test/policy/ci_test.dart` → `'the app and build jobs pin the same Flutter version, read from .flutter-version'`:
    parses `.github/workflows/ci.yml` and asserts both jobs read the pin from the same
    file and neither hardcodes a version. The workflow already says "keep == the app job's
    pin"; this is that comment made mechanical.
  - `test/policy/ci_test.dart` → `'no job uses runs-on: ubuntu-latest'`: image drift moves
    the toolchain with no diff to review.
  - `test/policy/ci_test.dart` → `'no gate carries continue-on-error'`: a gate that cannot
    block is not a gate.
  - `test/policy/ci_test.dart` → `'every gate step in the repo job has a Contract: comment above it'`:
    the workflow's own stated rule — a check with no contract behind it is gate-sprawl.
    This test is what keeps that true when someone adds the twelfth step.
  - New self-test arm `'dependabot pub block is uncommented and grouped'` in
    `tools/check_gates_selftest.sh`, asserting `.github/dependabot.yml` contains an active
    `package-ecosystem: pub` entry. Re-commenting it out must go red.
- **Then build**
  - Add to the `repo` job, each with its `Contract:` comment: `bash tools/audit_deps.sh`
    (gated on `pubspec.yaml` existing — it now does) and `bash tools/check_lint_include.sh`.
    Both belong in `repo` rather than `app` only if they need no Flutter toolchain;
    `audit_deps.sh` needs the resolved tree, so it goes in the **`app`** job, after
    `flutter pub get --enforce-lockfile`. Put each where its inputs are, and say which in
    the comment.
  - Uncomment the `pub` block in `.github/dependabot.yml` exactly as written — weekly,
    limit 5, `deps` prefix, grouped dev-dependencies. Its comment says to do this in the
    same commit that creates `pubspec.yaml`; that commit is task 1.1's, so this is late by
    seven tasks and that is fine as long as it lands in this epic. Note it in the progress
    file.
  - Update `README.md` §Repo state: the app exists, the lane is armed, and the three
    "must happen in that same commit" items are done. Update the same paragraph in
    `CLAUDE.md`. Move the `CHANGELOG.md` "Not yet — The Flutter app" bullet into `Added`.
  - Verify the `flutter` job's `git diff --exit-code -- lib/l10n/gen/` step passes on a
    clean checkout, not just locally.
- **Verify**
  ```bash
  bash tools/check_gates_selftest.sh
  flutter test test/policy/ci_test.dart
  git push                                # then read the Actions tab
  ```
  A pass is **three green jobs** — `repo gates`, `flutter`, `android build` — on a real
  push. Not a local simulation: `flutter build apk --debug` on a Linux runner is the first
  time this app is compiled anywhere but a Mac.
- **Done when**
  - [ ] Three jobs green on GitHub Actions, from a push to a branch.
  - [ ] `audit_deps.sh` and `check_lint_include.sh` run in CI, each under a named contract.
  - [ ] The `pub` block in `.github/dependabot.yml` is live.
  - [ ] `README.md`, `CLAUDE.md` and `CHANGELOG.md` no longer say the app does not exist.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

---

## Definition of done

- [ ] `flutter run` starts Odova on an Android API 26 emulator and an iOS 15 simulator.
- [ ] `flutter pub get --enforce-lockfile` succeeds from a fresh clone with no network
      other than pub.
- [ ] `bash tools/check_gates_selftest.sh` is green, and every gate added in this epic has
      been seen red on a planted violation.
- [ ] `bash tools/audit_deps.sh` refuses `http`, `dio`, `google_fonts`, `firebase_*`,
      `sentry_flutter` and every analytics SDK, transitively.
- [ ] No `android.permission.INTERNET` in any of the three manifests.
- [ ] Six ARB files, a committed `lib/l10n/gen/`, and `git diff --exit-code` clean after a
      fresh `flutter gen-l10n`.
- [ ] Three green jobs on GitHub Actions.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-01.md`.** It
> starts empty. Append one line per task as it completes — what was built, what was
> deferred, and anything the next epic needs to know. It is the running log for this epic
> and the handover to the next one.
