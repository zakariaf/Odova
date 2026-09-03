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
   shipping set. `NEVER_SHIPS` in `tools/audit_deps.py` stops the walk at
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

3. **`ckb` borrows Arabic framework strings.** Month names, `reorderItemToStart`
   and the Cupertino strings are Arabic under a Sorani UI. That is better than
   English and wrong all the same. **EPIC-04 owns fixing it**, and it is one of
   the places `SPEC.md` §18's Sorani questions bite.

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

8. **The structure test reads its exclusions from `analysis_options.yaml`.**
   Adding a generated-code family means adding one glob there, and both the
   analyzer and the coverage filter follow. Do not retype the list anywhere —
   `test/policy/lint_test.dart` fails on a second copy.

## Deferred

- No theme, no database, no domain type, no route beyond the placeholder. All
  deliberate; EPIC-02 onward.
- `flutter run` on a real API-26 emulator and an iOS 15 simulator has not been
  done in this session. `flutter build apk --debug` is the automated proxy and
  runs in CI's `android build` job.
