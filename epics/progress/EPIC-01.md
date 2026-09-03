# EPIC-01 — Project scaffold, toolchain and CI

Branch `epic/01-scaffold-and-ci`. One line per task, plus what the next epic
needs to know.

## Tasks

- **1.1 Create the Flutter app** — `flutter create --org io.applander
  --project-name odova --platforms=ios,android --empty .`. minSdk pinned to 26
  as a literal rather than `flutter.minSdkVersion`, which moves with the
  toolchain; `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in all three build
  configurations; `ios/Podfile` written from the tool's own template with
  `platform :ios, '15.0'` uncommented, so a Podfile appearing on somebody's
  first `pod install` cannot carry a different floor than the Xcode project.
  The `INTERNET` permission is out of the debug and profile manifests. Five
  policy tests, all seen red — the identity ones against a real default-org
  `flutter create` before `android/` and `ios/` were deleted and regenerated.

- **1.2 Arm the analyzer** — `very_good_analysis: ^10.3.0`; `flutter_lints`
  removed. **`close_sinks` was a promotion that did nothing.** VGA 10.3.0
  carries `close_sinks: ignore` in its own `errors:` map but never lists the
  rule under `rules:`, so nothing emitted the diagnostic and re-ranking it to
  `error` re-ranked something that did not exist. The epic's instruction was to
  delete such a promotion; deleting it would have been wrong, because Odova
  will hold long-lived StreamControllers behind its service ports. It is
  switched on in our own `linter: rules:` block instead and only then promoted,
  and verified by planting both shapes the rule detects (an unclosed `IOSink`
  field, an unclosed local `StreamController`) and watching each come back as
  `error`. The other eight promotions are enabled by VGA and were confirmed
  individually. `tools/check_lint_include.sh` resolves the include through
  `.dart_tool/package_config.json` rather than guessing at `PUB_CACHE` — the
  vendored version degrades to a *skip* when the cache is relocated, and a gate
  that skips is off.

- **1.3 Folder layout** — `app core data features l10n theme ui` + `main.dart`,
  each with a README naming its owner and its skills. Deviation from
  `project-structure-and-packages` recorded in `lib/app/README.md`: bootstrap,
  app, router and service ports fold into `lib/app/` and `lib/ui/` is added for
  the Calm component layer. Pure-core, feature-isolation and junk-drawer gates
  each seen red against a planted violation.

- **1.4 Six locales** — six ARB files with `appTitle`, `lib/l10n/gen/`
  committed. **`ckb` needed three delegates.** It is absent from
  `GlobalMaterialLocalizations`' supported set and `intl`'s
  `Bidi.isRtlLanguage` does not match it, so a `ckb` app on the framework
  defaults lays out **left to right**, silently. `lib/l10n/ckb_localizations.dart`
  serves Widgets, Material and Cupertino localizations for `ckb` from the
  Arabic ones. They must come **first** in `localizationsDelegates`:
  `Localizations` loads only the first delegate supporting a locale per type,
  and `GlobalWidgetsLocalizations.delegate` claims to support everything.
  Verified by commenting the widgets delegate out and watching the direction
  flip.

- **1.5 Riverpod, bootstrap, error net** — `main()` is 18 lines; two handlers,
  no zone; `PlatformDispatcher.onError` returns true unconditionally; the sink
  is wrapped in a bare catch; `ProviderException` is unwrapped before logging.
  Placeholder providers throw a `StateError` naming themselves, and a second
  test asserts the list the first walks covers every `_unwired(...)` call site.
  Root `retry` returns null. Lifecycle observer seen red in both directions
  (registered twice; never removed).

- **1.6 Dependency policy gate** — `tools/audit_deps.{sh,py}` vendored and
  edited to Odova's ban list. **The gate found something on its first real
  run** — see *What the next epic needs to know*. Ten self-test arms, all
  runnable without a Flutter toolchain. Added `test/policy/no_network_test.dart`,
  which is arguably the more important gate: `dart:io` hands you `HttpClient`
  and `Socket` with no dependency at all, and no dependency walk can see that.

- **1.7 Test harness and coverage** — `pumpApp(tester, child, {locale,
  themeMode, overrides})`; asserts the caller did not pass `ThemeMode.system`;
  does not clamp the text scaler. Both mistakes were planted and seen red.
  `tools/strip_generated_from_lcov.sh` reads the globs from
  `analysis_options.yaml`. Green on three different random seeds.

- **1.8 CI and Dependabot** — three lanes live. The `Contract:` comment test was
  red on four steps. `audit_deps.sh` and `check_lint_include.sh` run in the
  `app` job because that is where their inputs are. Dependabot's `pub` block is
  armed, with `tools/check_dependabot.sh` keeping it that way.

## What the next epic needs to know

1. **The dependency audit carves out the test frameworks, deliberately.**
   Riverpod 3 declares them as *regular* dependencies — `flutter_riverpod`
   exports `RiverpodWidgetTesterX`, a `WidgetTester` extension, and `riverpod`
   declares `package:test` because `ProviderContainer.test()` calls its
   `addTearDown`. That put `web_socket` and `web_socket_channel` in the
   shipping set. `HARNESS_PACKAGES` in `tools/audit_deps.py` stops the walk at
   `flutter_test`, `integration_test`, `flutter_driver` and `test`; two
   self-test arms prove the same banned package is still caught when it is also
   reachable at runtime. If a later epic sees `web_socket` in the "build/test
   only" list, that is this, and it is expected.

2. **`package_info_plus` is banned; the app version comes from
   `--dart-define`.** SPEC.md §6/§17 put `app_version` and `app_build` in the
   backup file, so there is a real shipped use — the decision is deliberate,
   not an oversight. Read them with `String.fromEnvironment('ODOVA_VERSION')`
   and `ODOVA_BUILD`. **EPIC-15 (backup) and EPIC-19 (release) must wire those
   defines into the build**, or the export writes empty strings. The reasoning
   is in the `ALLOW` block of `tools/audit_deps.py`.

3. **`ckb` borrows Arabic framework strings, and EPIC-04 will change that to
   Persian.** EPIC-01 task 1.4 says to supply `ckb` from the `ar` Material
   delegate, so that is what shipped; EPIC-04 task 4.2 says to borrow `fa`
   instead, and `fa` is the better neighbour — `SPEC.md` §5 ships `extarab`
   digits for `ckb` precisely *"because Sorani letterforms follow Persian
   conventions"*. The switch is one constant, `ckbFrameworkFallback` in
   `lib/l10n/ckb_localizations.dart`. Until then, month names,
   `reorderItemToStart` and the Cupertino strings are Arabic under a Sorani UI:
   better than English and wrong all the same. EPIC-04 also adds the SDK-probe
   test that makes this vendoring a deliberate deletion the day Flutter ships
   `ckb`, rather than dead code nobody dares remove.

4. **The crash sink writes to the platform log.** A durable on-disk sink needs
   an application-support directory, which **EPIC-05** owns. The seam is
   `CrashSink` in `lib/app/error_handlers.dart`; override `crashSinkProvider`
   in `bootstrap()` and nothing else changes.

5. **`durableFlushProvider` is a no-op returning `Future<void>`.** The
   lifecycle observer already calls it on `inactive`/`paused`. EPIC-05 overrides
   it rather than adding a second observer.

6. **`Override` and `ProviderException` are exported from
   `package:flutter_riverpod/misc.dart`** in 3.x, not the root library. This
   costs ten minutes the first time.

7. **`lib/l10n/gen/` is committed and CI diffs it.** Run `flutter gen-l10n`
   before committing any ARB change, or the `flutter` job fails on
   `git diff --exit-code`.

8. **The harness is `test/support/pump_app.dart`, not `test/support/harness.dart`,
   and there is no `Device` type yet.** EPIC-03 and EPIC-04 both open with
   *"EPIC-01 has created … `test/support/harness.dart` carrying the `Device`
   value type and the `pumpApp` extension"*. It does not: EPIC-01's own task 1.7
   names `test/support/pump_app.dart` and asks for a `pumpApp(tester, child,
   {locale, themeMode, overrides})` function, which is what exists. The epic
   that owns a task wins over another epic's summary of it. **EPIC-03 builds
   `Device`** — it is the first epic that needs one, for its overflow × text
   scale × bold matrix — and it belongs beside `pumpApp` in `test/support/`.

9. **`pumpApp` pumps `OdovaApp` itself, deliberately.** Not an equivalent
   `MaterialApp`. The 112 parity captures depend on the harness and the app
   being the same widget, so EPIC-02's swap to `buildCalmTheme` is one edit on
   `OdovaApp` and the harness follows. `OdovaApp` already carries `locale`,
   `home` and `themeMode`; add `theme`/`darkTheme` there and nowhere else.

10. **The structure test reads its exclusions from `analysis_options.yaml`.**
   Adding a generated-code family means adding one glob there, and both the
   analyzer and the coverage filter follow. Do not retype the list anywhere —
   `test/policy/lint_test.dart` fails on a second copy.

## `/simplify` — findings answered rather than applied

Four passes ran over the epic's diff (reuse, simplification, efficiency,
altitude) before the PR was opened. Most findings were applied; these three were
not, and this is the answer CLAUDE.md requires in writing.

1. **"`bootstrap()` is `async` with nothing to await."** Correct, and kept. The
   `Future` is the seam EPIC-05 opens the database through, and the comment in
   `lib/app/bootstrap.dart` says so. Making it synchronous now means changing
   `main()`'s shape in the epic that can least afford a startup-order change —
   SPEC.md §2's "data survives app updates" rides on that ordering. The cost is
   one microtask hop before `runApp`.

2. **"`test/support/fakes.dart` contains no code; delete it."** Kept. EPIC-01
   task 1.7 asks for it by name, and `epics/README.md` rule 5 says the epic is
   the product decision where a general default disagrees. Its job is to exist
   before the first fake does, so EPIC-05 does not invent a second location for
   one; a barrel that arrives with its first occupant arrives after the decision
   it was meant to make.

3. **"Evaluate the ban over `lib/`'s import closure rather than the pub
   graph."** Not done, and the two are complementary rather than one being
   deeper. An import-closure model would drop `web_socket_channel` with no name
   list to maintain — but it would also miss a plugin that registers an
   analytics SDK natively without a single Dart import, which is exactly the
   arrival this gate is for. `test/policy/no_network_test.dart` already walks
   what Odova writes; `tools/audit_deps.py` walks what Odova's dependencies
   drag in. Both, or the gate has a hole either way.

Two efficiency findings were noted and left: 11 `RegExp`s recompiled per file in
`no_network_test.dart`, and each ARB read three times in `arb_parity_test.dart`.
Both are milliseconds today. The ARB one scales with the string set and is worth
doing when EPIC-04 next touches that file.

## Deferred

- No theme, no database, no domain type, no route beyond the placeholder. All
  deliberate; EPIC-02 onward.
- `flutter run` on a real API-26 emulator and an iOS 15 simulator has not been
  done in this session. `flutter build apk --debug` is the automated proxy and
  runs in CI's `android build` job.
