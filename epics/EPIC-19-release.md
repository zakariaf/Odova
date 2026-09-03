# EPIC-19 — Release engineering and store shipping

| | |
|---|---|
| **Epic** | EPIC-19 — Release engineering and store shipping |
| **Depends on** | EPIC-17, EPIC-18 |
| **Estimate** | **8.5 h (CC) · ~8.5 weeks (human)** total |
| **Spec sections** | §17 Definition of done for v1 (offline gate, data-safety gate, per-locale gate, scale gate) |
| **Screens** | none |

CI proves the *code*. A release proves the *artifact* — the exact bundle built with R8,
obfuscation, tree-shaking and stripped asserts, signed by a key that must never be lost,
declaring things about itself to a store that will pull the app if they are untrue.

Two things make Odova's release unusual and both are load-bearing here. First, the app has
**no network code at all** (§2), so the privacy declaration is the easiest one anybody will
ever fill in and the one most likely to be filled in carelessly — the value is in proving it
from the source graph and the merged manifest, not in asserting it. Second, CI can only prove
that no banned import exists in the source graph; it cannot prove the shipped binary opens no
socket on a real phone. §17's offline gate therefore ends in a **manual** aeroplane-mode pass
from a clean install, and that pass is a release artifact, not a chore.

One rule from `release-and-store-shipping` deserves calling out because it is the most
expensive thing to get wrong and it does **not** apply to Odova: Apple requires a first
release to submit the app version *and* its first in-app purchase in one submission, and a
version submitted alone is closed without review under Guideline 2.1(b). **Odova has no
in-app purchase, no ads and no monetisation of any kind** (§15), so there is nothing to
attach and `reviewSubmissions/{id}/items` correctly returns 1 item, not 2. Task 19.9 records
that in the repo so nobody re-derives it under submission pressure — and pins it with a test,
so the day someone adds an IAP the claim fails loudly instead of quietly.

**Building, signing, uploading and tagging are side-effecting, and part of it is
irreversible** — a published build number can never be reused and an iOS build can never be
unshipped. Tasks 19.1 – 19.9 are config and gates and are always in scope. Task 19.10 runs
only when the developer asks for a release **by name**.

## Where we are now

The app is built and reviewed. Concretely, at the moment this epic starts:

- `pubspec.yaml`, `lib/`, `android/` and `ios/` exist (EPIC-01 created them with
  `flutter create`; `.flutter-version` pins 3.44.6). All 28 screens work in six locales, both
  directions.
- EPIC-17 left CI green — `dart format --set-exit-if-changed`, `flutter analyze
  --fatal-infos --fatal-warnings`, `flutter gen-l10n` freshness, `flutter test` — and the §17
  functional, data-safety, per-locale and scale gates each backed by a check. **If any of
  those is not true when this epic starts, stop.** Nothing here substitutes for them, and a
  release cut over a red gate is a release you cannot un-ship.
- EPIC-18 left `design/review/SIGNOFF-<date>.md`, tracked, reading `SIGNED OFF`. That file is
  a precondition of the release ritual, not part of it.
- `.github/workflows/ci.yml` already runs the repo gates, including
  `bash tools/check_release_hygiene.sh`, and has done since before the app existed. It walks
  `git log --all` for signing material, which needs `fetch-depth: 0` — verify that, because a
  shallow checkout makes the history half of the gate silently pass.
- `tools/check_gates_selftest.sh` proves each repo gate can actually fail, by planting a real
  violation (it plants `./upload-keystore.jks` for the hygiene gate). Every gate this epic
  adds gets the same treatment.

Deliberately still missing: the app ships Flutter's default icon and launch screen; there is
no signing configuration, no `store/` directory, no privacy manifest, no release workflow, no
symbol archive, and `version:` is still whatever EPIC-01 wrote. Nothing has ever been
uploaded, so build number 1 has not been burned.

## What we will have when this is done

- Odova's own icon on both platforms and a launch screen in Calm's `--color-surface`, light
  and dark, with the hexes read from the tokens rather than typed twice.
- `android/key.properties`, the keystore, the App Store Connect `.p8` and the Play
  service-account JSON all injected from secrets, none of them in the working tree or
  anywhere in `git log --all` — proved by a gate that has been seen to fail.
- `version: 1.0.0+1` in `pubspec.yaml` as the only version source, and `settings.about`
  showing that version and `SUPPORTED_FORMAT_VERSION` read from build constants (§13).
- `android/expected_permissions.txt` and `test/policy/permissions_test.dart` asserting the
  **merged** manifest's permission set whole, with `android.permission.INTERNET` provably
  absent.
- `store/{en,de,fr,fa,ar,ckb}/` — title, subtitle, short and full description in all six
  languages, inside the store's length limits, with no absolute privacy claim, plus
  `store/screenshots/` for every required display type.
- `ios/Runner/PrivacyInfo.xcprivacy`, a Data Safety answer sheet and nutrition labels, all
  reconciled against `pubspec.lock` — and the OS-auto-backup question (§18.12) answered in
  writing, because the answer changes the privacy copy.
- `tools/release.sh` and `.github/workflows/release.yml` producing an `.aab` and an `.ipa`
  with `--obfuscate --split-debug-info=build/symbols/<x.y.z>+<N>/`, symbols archived before
  anything is uploaded.
- `release/checks/1.0.0+1.md` — the two manual artifacts CI cannot produce: the
  aeroplane-mode walk from a clean install, and the upgrade over an installed build.
- `release/app-store-submission.md` recording the no-IAP position and the account-holder-only
  gates, and a tagged `v1.0.0` with notes and a written rollout halt criterion.

## Skills to load

| Skill | Why this epic needs it |
|---|---|
| `flutter-conventions-index` | The front door; the house rules still hold in `tools/`, `test/policy/` and the composition root. |
| `release-and-store-shipping` | Governs the whole epic: version mapping, signing, obfuscation and symbols, merged-manifest permissions, store declarations, budgets, staged rollout, and the App Review submission rule. |
| `ci-pipeline-and-gates` | Where the new gates live, the three-criteria bar a grep gate must clear, and the honest statement of what CI cannot prove — which is exactly why Task 19.8 exists. |
| `dependency-hygiene` | A new dependency is what changes a store declaration. The no-network claim is a property of `pubspec.lock`, audited here. |
| `design-review-workflow` | Owns the dated sign-off that is a precondition of the release ritual, and the data-safety rehearsal Task 19.8 repeats on the release artifact. |
| `run-migration` | The upgrade-over-the-previous-release path in Task 19.8 is a migration test, and a schema-shape check passes on a migration that copies zero rows. |
| `i18n-rtl-l10n` | The store listing is six locales with the same structural rules as the app: no concatenation, real Persian/Arabic/Sorani, and glyph coverage in the screenshots. |
| `calm-tokens` | The icon and launch-screen colours are Calm tokens, not new values invented at the platform layer. |
| `service-boundary-and-native` | The native seams the merged manifest and the platform launch configuration live behind, and where a flavour's composition root would go. |

## Tasks

### Task 19.1 — App icons and the launch screen, from the Calm palette

- **Goal** — the app looks like Odova from the home screen and the first frame, in both
  themes, with no colour invented at the platform layer.
- **Spec** — §2 Non-negotiables (v1 has no photos; a colour swatch and a silhouette only);
  §17 targets (iOS 15+, Android 8.0 / API 26+).
- **Skills** — `calm-tokens`, `release-and-store-shipping`, `service-boundary-and-native`.
- **Write these tests first**
  - `test/policy/app_icon_test.dart`:
    - `iOS asset catalog has the 1024 marketing icon and no alpha` — `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
      contains the 1024×1024 entry and its PNG has no alpha channel. Fails the upload with
      ITMS-90717 otherwise, which costs a whole build number.
    - `Android ships an adaptive icon with both layers` — `mipmap-anydpi-v26/ic_launcher.xml`
      references a foreground and a background drawable. API 26 is the floor, so there is no
      legacy path to keep.
    - `every launcher density is present` — mdpi through xxxhdpi. Fails on a half-generated
      icon set, which shows as a blurry icon only on the devices you do not own.
  - `test/policy/launch_screen_test.dart`:
    - `the Android launch background equals the Calm surface token` — the colour in
      `android/app/src/main/res/values/colors.xml` equals `#FFFCF7` (`--color-surface`, light)
      and `values-night/colors.xml` equals `#272019` (the dark block's `--color-surface`),
      both read from `design/calm/odova.css` by the test rather than hardcoded in it. Fails
      when a token moves and the platform file does not — the flash of the wrong colour on
      launch that nobody files a bug for.
    - `the iOS launch background equals the same tokens` — the `LaunchBackground` colour set
      in `ios/Runner/Assets.xcassets` has an Any and a Dark appearance matching the same two
      values.
- **Then build**
  - `design/icon/` — the source artwork: the silhouette on `--color-brand` `#7A5340`, per §2's
    "a colour swatch and a silhouette only". Generate the platform sets from it; keep the
    source in the repo so a regeneration is reproducible.
  - `android/app/src/main/res/mipmap-*/`, `mipmap-anydpi-v26/ic_launcher.xml`,
    `values/colors.xml`, `values-night/colors.xml`, `values/styles.xml`.
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `LaunchBackground` colour set, and
    `LaunchScreen.storyboard` pointing at it.
- **Verify**
  ```bash
  flutter test test/policy/app_icon_test.dart test/policy/launch_screen_test.dart
  flutter build apk --debug && flutter install       # look at the icon and the first frame
  flutter run --release                              # dark mode too: the launch screen must flip
  ```
  A pass is both tests green and a launch that goes Calm-surface → Home with no white flash in
  dark mode.
- **Done when**
  - [ ] Icon present at every required size on both platforms; iOS 1024 has no alpha.
  - [ ] Launch background is the Calm surface token in both appearances, asserted against
        `odova.css`.
  - [ ] No colour literal was typed into a platform file that the test does not derive from a
        token.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.2 — Signing, injected from secrets, proved absent from the repo and its history

- **Goal** — the app can be signed for release and no signing material can ever reach the
  repository, including via a commit that is later reverted.
- **Spec** — §17 (the release must be reproducible by an engineer running the list).
- **Skills** — `release-and-store-shipping` (rules 3 and 4, `references/android-play.md`,
  `references/ios-app-store.md`), `ci-pipeline-and-gates`.
- **Write these tests first**
  - Extend `tools/check_gates_selftest.sh` with the cases the current file does not cover —
    it plants `./upload-keystore.jks` today; add, using the same `assert` helper:
    - `red when key.properties is planted` — plant `android/key.properties`, assert
      `tools/check_release_hygiene.sh` exits non-zero, remove it, assert green.
    - `red when a .p8 is planted` — same shape for `AuthKey_XXXXXXXX.p8`.
    - `red when a service-account json is planted` — `service-account-play.json`.
    - `red when a credential exists only in history` — commit a `key.properties` in a scratch
      clone, delete it in a second commit, and assert the gate still fails. This is the case
      the working-tree half cannot see and the reason the gate walks `git log --all`.
  - `test/policy/gitignore_test.dart`:
    - `gitignore covers every credential pattern the hygiene gate knows` — the pattern list in
      `.gitignore` is a superset of `PATTERNS` in `tools/check_release_hygiene.sh`. Fails when
      one file learns a pattern and the other does not.
  - `test/policy/signing_config_test.dart`:
    - `release signing reads key.properties and never a literal` — `android/app/build.gradle.kts`
      loads the keystore from `key.properties` and contains no `storePassword`/`keyAlias`
      literal.
    - `release build type is not debug-signed` — the release `signingConfig` is not
      `signingConfigs.debug`. Fails the single most common accidental ship.
- **Then build**
  - `android/app/build.gradle.kts` — a release `signingConfig` reading `key.properties`, with
    a clear failure message when the file is absent (a local debug build must still work).
  - `android/key.properties.example` — the shape, with no values.
  - GitHub Actions secrets for the keystore (base64), its passwords, the ASC `.p8` and the
    Play service-account JSON; a release-workflow step that materialises them into the runner
    workspace and deletes them after.
  - Enrol in **Play App Signing** and keep the upload key separate — a lost upload key is
    recoverable through support; a lost app-signing key on an unenrolled app is a dead
    listing. Record the enrolment in `release/app-store-submission.md` (Task 19.9).
  - Ensure the CI checkout that runs the hygiene gate uses `fetch-depth: 0`.
- **Verify**
  ```bash
  bash tools/check_gates_selftest.sh          # every new case: red when planted, green when removed
  bash tools/check_release_hygiene.sh
  flutter test test/policy/gitignore_test.dart test/policy/signing_config_test.dart
  git log --all --name-only --diff-filter=A | grep -E 'key\.properties|\.jks|\.p8' || echo clean
  ```
  A pass is the self-test showing each new gate going red on a planted violation and green
  again once removed — a gate that has only ever been green is a comment.
- **Done when**
  - [ ] Every credential pattern is gitignored, absent from the tree, and absent from
        `git log --all`.
  - [ ] Each new gate has been **seen** to fail in `check_gates_selftest.sh`.
  - [ ] CI checks out with `fetch-depth: 0` where the history half of the gate runs.
  - [ ] Play App Signing enrolled; upload key held separately and recorded.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.3 — Version and build numbering, with one source

- **Goal** — `pubspec.yaml` is the only place a version exists, and the About screen shows the
  same numbers the store shows.
- **Spec** — §13 `settings.about` (`Version 1.4.0 (312)` and `Backup format 1` =
  `SUPPORTED_FORMAT_VERSION`); §6 Backup, export and import (`app_version`, `app_build` in the
  export envelope).
- **Skills** — `release-and-store-shipping` (rule 1 and the mapping table), `data-export-and-restore`,
  `naming-conventions`.
- **Write these tests first**
  - `test/policy/version_source_test.dart`:
    - `pubspec declares version x.y.z+N` — `version: 1.0.0+1` parses into a semantic version
      and an integer build number.
    - `no version literal in android/app/build.gradle.kts` — no `versionName`/`versionCode`
      assigned a literal; both come from the Flutter Gradle plugin.
    - `no version literal in Info.plist` — `CFBundleShortVersionString` and `CFBundleVersion`
      are the `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` substitutions. Fails the
      case where a crash report names a version that never shipped.
  - `test/features/settings/about_version_test.dart`:
    - `About shows the pubspec version and build` — pump `settings.about` with a fake
      `PackageInfo` and assert the rendered string matches §13's `Version {x.y.z} ({N})`
      shape.
    - `About shows SUPPORTED_FORMAT_VERSION, not the schema version` — asserts `Backup
      format 1` and that the internal schema version appears nowhere on the screen. §13 is
      explicit: the user cannot act on the schema version.
    - `version digits are Latin and forced LTR under fa` — §13's RTL rule. Fails if the
      version renders in extarab numerals, which would make it unmatchable against the store.
  - `test/export/envelope_version_test.dart`:
    - `the export envelope's app_version and app_build come from the same source` — and are
      in the §17 ignore list for the byte-identical re-export check.
- **Then build**
  - Set `version: 1.0.0+1` in `pubspec.yaml`; strip any version literal from the platform
    files; read the values at runtime through the existing injected build-constants service
    (never `PackageInfo` called from a widget — rule 8 of the index).
- **Verify**
  ```bash
  flutter test test/policy/version_source_test.dart \
               test/features/settings/about_version_test.dart \
               test/export/envelope_version_test.dart
  flutter build appbundle --release --build-name=1.0.0 --build-number=1 && \
    unzip -p build/app/outputs/bundle/release/app-release.aab base/manifest/AndroidManifest.xml | strings | grep -i version
  ```
  A pass is the manifest's `versionName`/`versionCode` matching pubspec exactly.
- **Done when**
  - [ ] `version: 1.0.0+1` is the only version source; platform files carry no literal.
  - [ ] About shows the same version and `Backup format 1`.
  - [ ] The export envelope carries the same numbers.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

### Task 19.4 — Assert the permission set whole, and prove there is no network

- **Goal** — the permissions users see on the listing are exactly the permissions we intend,
  and §17's offline gate has a CI check behind its first line.
- **Spec** — §2 Non-negotiables (no network call of any kind, and no network permission it can
  avoid); §17 offline gate ("a dependency-graph check for networking APIs runs in CI and fails
  the build"); §4 Reminders and notifications (the boot re-arm and the periodic rebuild are
  what justify the permissions that remain).
- **Skills** — `release-and-store-shipping` (rule 7, `references/privacy-permissions-and-claims.md`),
  `ci-pipeline-and-gates` (the three-criteria grep bar), `dependency-hygiene`,
  `local-notifications-scheduler`.
- **Write these tests first**
  - `test/policy/permissions_test.dart`:
    - `shipped Android permissions are exactly the declared set` — parse the **merged**
      manifest (`build/app/intermediates/merged_manifests/release/AndroidManifest.xml`, not
      `android/app/src/main/AndroidManifest.xml`) and assert the `uses-permission` set equals
      the committed list in `android/expected_permissions.txt`, which starts as
      `android.permission.POST_NOTIFICATIONS` and `android.permission.RECEIVE_BOOT_COMPLETED`
      (§4's re-arm). Whole-set equality, not "no forbidden permission" — that is what catches
      a permission a transitive plugin bump introduced.
    - `INTERNET is absent from the merged manifest` — named separately so the failure message
      says the thing that matters. Fails the §2 promise directly.
    - `iOS usage strings are exactly the declared set` — the `NS*UsageDescription` keys in
      `Info.plist` equal the committed list. A missing one is a rejection; an unused one is a
      claim we cannot defend.
  - `test/policy/no_network_test.dart` — **check first whether EPIC-17 already landed this
    gate; if so, extend it rather than writing a second one**:
    - `no networking import anywhere in the source graph` — walk `lib/` and the resolved
      package graph from `pubspec.lock` for `dart:io`'s `HttpClient`/`Socket`/`RawSocket`,
      `dart:html`'s `HttpRequest`, `package:http`, `package:dio`, `package:web_socket_channel`
      and `package:googleapis*`. Fails on the transitive dependency that quietly adds a
      client.
    - `no analytics, crash-reporting or ads package in pubspec.lock` — §15 is explicit that
      each of those is out, and each of them changes the Data Safety declaration in Task 19.5.
  - Extend `tools/check_gates_selftest.sh`: plant an `import 'package:http/http.dart';` in a
    scratch file, assert the no-network gate goes red, remove it, assert green.
- **Then build**
  - `android/expected_permissions.txt`, `ios/expected_usage_descriptions.txt`.
  - Strip anything a plugin injects that Odova does not need with `tools:node="remove"` in
    `android/app/src/main/AndroidManifest.xml` — with a comment naming which plugin injected
    it, because the next person will otherwise remove the removal.
  - Wire both tests into `.github/workflows/ci.yml`. The merged manifest only exists after a
    build, so the permission test runs in the android-build job, not the fast lane.
- **Verify**
  ```bash
  flutter build apk --release
  flutter test test/policy/permissions_test.dart test/policy/no_network_test.dart
  bash tools/check_gates_selftest.sh
  unzip -p build/app/outputs/flutter-apk/app-release.apk AndroidManifest.xml | strings | grep -i permission
  ```
  A pass is the merged set equalling the committed list, with `INTERNET` absent. Note honestly
  in the progress file what this does **not** prove: it is a property of the source graph and
  the manifest, not of the running binary. Task 19.8 covers the rest.
- **Done when**
  - [ ] Whole-set permission assertion runs against the **merged** manifest in CI.
  - [ ] `INTERNET` is provably absent, and the no-network source-graph gate has been seen to
        fail.
  - [ ] Every remaining permission traces to a §4 behaviour, named in a comment.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.5 — Privacy declarations that match an app with no network code

- **Goal** — Data Safety, the App Store nutrition labels and `PrivacyInfo.xcprivacy` all say
  what the code actually does, and every sentence in them is provable from the repo.
- **Spec** — §2 Non-negotiables; §13 `settings.about` (the privacy paragraph, verbatim, is the
  copy this declaration must agree with); §6 (export hands the file to the OS share sheet);
  §18 open decision 12 (Android auto-backup / iOS container backup).
- **Skills** — `release-and-store-shipping` (rules 8 and 9,
  `references/privacy-permissions-and-claims.md`), `dependency-hygiene`,
  `data-export-and-restore`.
- **Write these tests first**
  - `test/policy/privacy_manifest_test.dart`:
    - `PrivacyInfo.xcprivacy exists and is a valid plist` — fails the submission otherwise,
      with a message that names a symptom rather than the file.
    - `NSPrivacyTracking is false and NSPrivacyTrackingDomains is empty` — Odova has no
      network; anything else is a false declaration.
    - `NSPrivacyCollectedDataTypes is empty` — and the test's failure message says "adding a
      crash reporter or analytics SDK changes this file in the same PR".
    - `required-reason APIs are declared` — `NSPrivacyAccessedAPICategoryUserDefaults` with
      reason `CA92.1` and `…FileTimestamp` with `C617.1`, matching what the app actually uses.
      A missing required-reason entry is an automated rejection email, not a review comment.
  - `test/policy/privacy_claims_test.dart`:
    - `no absolute privacy claim in store copy or onboarding` — grep `store/**` and the ARB
      files for "nothing ever leaves your device", "completely private", "100% private" and
      their six-language equivalents. Fails `release-and-store-shipping` rule 9: one share-
      sheet export makes an absolute sentence a lie.
    - `the store privacy paragraph agrees with the About paragraph` — the claim set in
      `store/en/description.txt` is the same claim set as §13's About copy, which states the
      mechanism ("no way to reach the internet") rather than an absolute.
  - `test/policy/data_safety_test.dart`:
    - `the Data Safety answer sheet declares no collection and no sharing` — parse
      `store/data-safety.md` and assert every data type is "not collected".
    - `the answer sheet lists every package in pubspec.lock it depends on` — so a dependency
      bump that adds an SDK fails here rather than at a takedown.
- **Then build**
  - `ios/Runner/PrivacyInfo.xcprivacy`.
  - `store/data-safety.md` — the Play answer sheet, and the App Store nutrition-label answers
    beside it, in one file, so the two can never disagree.
  - **Close §18 open decision 12 in writing.** SPEC §6 says the app's data directory stays
    inside the OS's own app-backup mechanism, and §18.12 leaves it open whether that stays on.
    It is a release-blocking decision *for this task* because the answer changes the copy: if
    Android auto-backup and the iOS container backup stay enabled, the privacy paragraph needs
    a line saying the OS may copy the app's data to the user's own cloud backup. Either
    disable it (`android:allowBackup="false"` plus the iOS exclusion) or write the line — and
    record which, and who decided, in `store/data-safety.md`.
- **Verify**
  ```bash
  flutter test test/policy/privacy_manifest_test.dart test/policy/privacy_claims_test.dart \
               test/policy/data_safety_test.dart
  plutil -lint ios/Runner/PrivacyInfo.xcprivacy
  ```
  A pass is all three tests green and a data-safety sheet a stranger could check against
  `pubspec.lock` in five minutes.
- **Done when**
  - [ ] `PrivacyInfo.xcprivacy` declares no tracking, no collection, and the required-reason
        APIs the app actually uses.
  - [ ] Data Safety and the nutrition labels live in one file and are reconciled against
        `pubspec.lock`.
  - [ ] No absolute privacy claim in any of the six locales or in the onboarding copy.
  - [ ] §18.12 is closed in writing, and the copy matches the decision.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.6 — The store listing in six languages, and the screenshots

- **Goal** — a complete, submittable listing in en, de, fr, fa, ar and ckb, with screenshots
  for every required display type.
- **Spec** — §2 (six languages from day one, in both directions); §5 Languages, RTL and
  formats; §17 per-locale gate.
- **Skills** — `i18n-rtl-l10n`, `release-and-store-shipping` (rule 14 and
  `references/app-store-connect-submission.md`), `design-review-workflow` (the shots this
  reuses), `calm-typography-and-rtl`.
- **Write these tests first**
  - `test/policy/store_listing_test.dart`:
    - `all six locales have the same key set` — `store/{en,de,fr,fa,ar,ckb}/` each contain
      `title.txt`, `subtitle.txt`, `short_description.txt`, `full_description.txt`,
      `keywords.txt`, `whats_new.txt`. Fails on the locale someone forgot, which blocks
      submission per display type with a message that names a device class instead.
    - `every field is within its store limit` — Play: title ≤ 30, short description ≤ 80, full
      description ≤ 4000. App Store: name ≤ 30, subtitle ≤ 30, keywords ≤ 100. Measured in
      characters, not bytes — Persian and Sorani will otherwise pass a byte check and fail the
      upload.
    - `no untranslated English leaks into a non-English listing` — the fa/ar/ckb files do not
      contain the English title sentence. Fails the copy-paste-and-forget case.
    - `RTL listings contain no bidi control characters` — §2 bans storing them.
  - `test/policy/store_screenshots_test.dart`:
    - `every required display type has the required count` — 6.7" and 6.5" iPhone and Android
      phone, at least 3 shots each, present under `store/screenshots/<locale>/<display>/`.
      Fails before the upload rather than during it.
    - `at least one RTL screenshot ships for each RTL locale` — a Persian listing showing
      English screenshots is the most common way a six-language launch looks unfinished.
- **Then build**
  - `store/<locale>/*.txt` — written, not machine-translated; the same ICU-quality bar the app
    holds. Sorani is the highest-risk file (§18.11); if no reviewer is available, say so in
    the progress file rather than shipping unreviewed copy.
  - `store/screenshots/` — derive from EPIC-18's `design/review/shots/` release-build captures
    where the display type matches, and re-shoot at the store's required sizes where it does
    not. Same device frame, same standardised status bar.
  - `store/README.md` — which file maps to which field in each console.
- **Verify**
  ```bash
  flutter test test/policy/store_listing_test.dart test/policy/store_screenshots_test.dart
  ls store/screenshots/*/*/ | head
  ```
  A pass is six complete locales inside the limits, with RTL screenshots that a Persian reader
  would recognise as their app.
- **Done when**
  - [ ] All six locales complete, inside every length limit, no English leakage.
  - [ ] Screenshots present for every required display type, RTL locales included.
  - [ ] A committed screenshot folder is understood to be **not** an uploaded screenshot set —
        Task 19.10 reads the store back.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.7 — The release build: obfuscation, versioned symbols, and the budgets

- **Goal** — one command produces the exact artifact that will be uploaded, with its symbols
  archived before anything leaves the machine.
- **Spec** — §17 scale gate (cold launch to interactive Home under 2.0 s on the floor device;
  peak memory under 250 MB).
- **Skills** — `release-and-store-shipping` (rules 5, 10 and 11), `ci-pipeline-and-gates`
  (rule 9: gates verify, they never bless), `flutter-performance`.
- **Write these tests first**
  - Extend `tools/check_gates_selftest.sh`:
    - `release script refuses a dirty working tree` — plant an untracked change, assert
      `tools/release.sh --dry-run` exits non-zero, clean up, assert green.
    - `release script refuses without a design-review sign-off` — temporarily move
      `design/review/SIGNOFF-*.md`, assert red, restore, assert green. This is how EPIC-18's
      artifact actually gates the release rather than just existing.
    - `release script refuses a build number not greater than the last uploaded` — with a
      recorded `release/uploaded-build-numbers.txt`.
  - `test/policy/debug_affordances_test.dart`:
    - `no dev menu, fixture seeding or eraseDatabaseOnSchemaChange in the release graph` —
      grep `lib/` for `eraseDatabaseOnSchemaChange`, seed/fixture entry points and any debug
      route, excluding files behind `kDebugMode`. §13 is explicit: debug tools are compiled
      out, not hidden behind seven taps on the version number.
    - `no debug banner in release` — `debugShowCheckedModeBanner: false` at the app root.
- **Then build**
  - `tools/release.sh` — the ordered ritual, refusing to proceed when a precondition is
    unmet: clean tree, CI green on this commit, sign-off present, notes written. Then
    ```bash
    flutter build appbundle --release \
      --obfuscate --split-debug-info=build/symbols/1.0.0+1
    flutter build ipa --release \
      --obfuscate --split-debug-info=build/symbols/1.0.0+1 \
      --export-options-plist=ios/ExportOptions.plist
    ```
    then archive `build/symbols/1.0.0+1/` off-machine **before** any upload step, and run
    `.claude/skills/release-and-store-shipping/scripts/check-ipa-slices.sh` on the IPA.
  - `.github/workflows/release.yml` — tag-triggered, materialising the secrets, calling the
    same script. Never `--update-goldens`, never a format fix, never a commit back.
  - Record the budgets in `release/budgets/1.0.0+1.md` from
    `flutter build appbundle --release --analyze-size` and
    `flutter run --profile --trace-startup` on the floor device.
- **Verify**
  ```bash
  bash tools/check_gates_selftest.sh
  flutter test test/policy/debug_affordances_test.dart
  bash tools/release.sh --dry-run
  ls build/symbols/1.0.0+1/                      # app.android-arm64.symbols and friends
  bash .claude/skills/release-and-store-shipping/scripts/check-ipa-slices.sh build/ios/ipa/*.ipa
  ```
  A pass is a dry run that names every precondition it checked, and a symbols directory that
  exists before any upload could have happened.
- **Done when**
  - [ ] Both artifacts build with `--obfuscate --split-debug-info` into a per-build directory.
  - [ ] Symbols archived off-machine before upload; the archive location is written down.
  - [ ] Debug affordances proved unreachable by a gate that has been seen to fail.
  - [ ] Size and cold start recorded against §17's budgets on the floor device.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.8 — The two manual release artifacts CI cannot produce

- **Goal** — the aeroplane-mode walk from a clean install and the upgrade over an installed
  build, both done on real hardware, both written down.
- **Spec** — §17 offline gate ("full manual pass of every screen in aeroplane mode on a device
  that has never been online"); §17 data-safety gate (upgrade from every shipped schema
  version, safety copy restorable, crash-at-five-points during import).
- **Skills** — `design-review-workflow` (the on-device pass, destructive steps last),
  `run-migration`, `release-and-store-shipping` (rule 6), `data-export-and-restore`.
- **Write these tests first**
  - `test/policy/release_check_artifact_test.dart`:
    - `a device-check artifact exists for the current pubspec version` —
      `release/checks/<x.y.z>+<N>.md` exists, and its header names the device, the OS version
      and the date. Fails when someone tags from memory of "basically doing this last time",
      which is the failure this artifact exists to prevent.
    - `every line in the artifact is ticked or explicitly failed` — no blank checkbox at
      sign-off.
  - `test/migration/upgrade_from_shipped_schemas_test.dart` (extend EPIC-17's suite rather
    than duplicating it if it exists):
    - `each shipped schema version upgrades to current with zero record loss` over the §17
      12,000-record dataset.
    - `a pre-migration safety copy exists and restores` — asserts the copy is written with the
      **old** schema's writer before the new code touches anything (§2).
    - `a schema-shape check cannot pass on a migration that copies zero rows` — assert row
      counts, not just column shape. `run-migration` names this as the trap.
- **Then build**
  - `release/checks/1.0.0+1.md` — the checklist, ticked fresh, in this order (destructive
    last, because each of these destroys the state before it):
    1. Clean install of the **release** artifact on a floor-class device that has never had
       Odova on it. Aeroplane mode on before first launch. Walk all 28 screens: first run,
       add a vehicle, log a fill-up, a service, an expense and an odometer reading, open every
       Settings screen, export, import, and let a notification fire. Nothing may hang, retry
       or show a network error, because there is nothing to retry.
    2. Install the previous released build, create data, upgrade in place to the new artifact
       — data intact, migrations run before the first frame.
    3. Export → wipe → import; then feed import a truncated file and a hand-corrupted file: a
       visible error, never a wiped store.
    4. Force-stop and relaunch; then the deliberate crash, exported and symbolized with
       `flutter symbolize -i crash.txt -d build/symbols/1.0.0+1/app.android-arm64.symbols` —
       readable names, and no user content in the log.
  - On a **first** release there is no previous build to upgrade from. Say that in the
    artifact rather than ticking the line; step 2 becomes real from 1.0.1 onward.
- **Verify**
  ```bash
  flutter test test/policy/release_check_artifact_test.dart test/migration/
  flutter symbolize -i crash.txt -d build/symbols/1.0.0+1/app.android-arm64.symbols
  ```
  A pass is a dated, device-named artifact with every line ticked or explicitly failed, and a
  symbolized crash with real function names. Hex offsets mean debug info leaked out of the
  build.
- **Done when**
  - [ ] Aeroplane-mode walk of every screen done from a clean install on a never-online
        device, and recorded.
  - [ ] Upgrade-over-installed-build done, or explicitly marked not-applicable for 1.0.0.
  - [ ] Export/wipe/import and the two damaged files behaved as §17 requires.
  - [ ] The crash log symbolizes to readable names and carries no user content.
- **Estimate** — 1 h (CC) · ~1 week (human)

### Task 19.9 — Record the submission position: no IAP, and the account-holder-only gates

- **Goal** — the App Review rules that apply and the one that does not are written down before
  submission, so nobody re-derives them at 11pm.
- **Spec** — §15 Explicitly out of v1 (no monetisation, no ads, no purchases); §2 (no account).
- **Skills** — `release-and-store-shipping` (rules 14 and 15,
  `references/app-store-connect-submission.md`), `ads-and-iap-monetization` (read only to
  confirm none of it applies), `dependency-hygiene`.
- **Write these tests first**
  - `test/policy/no_iap_test.dart`:
    - `no in-app purchase or ads package in pubspec.lock` — `in_app_purchase`,
      `purchases_flutter`, `google_mobile_ads` and friends are absent. This is what keeps the
      claim in `release/app-store-submission.md` true; the day someone adds one, this test
      fails and the submission plan changes with it.
    - `no StoreKit or Billing entitlement in the platform configuration` — no
      `com.apple.developer.in-app-payments`, no `com.android.vending.BILLING`.
  - `test/policy/submission_record_test.dart`:
    - `the submission record answers every account-holder-only gate` —
      `release/app-store-submission.md` has a filled line for the app record, the privacy
      questionnaire, the Paid Applications Agreement (marked **not required**, with the reason)
      and Play App Signing enrolment. Fails on a blank, because each of these blocks
      submission with a message that names a symptom rather than the setting.
- **Then build**
  - `release/app-store-submission.md`, saying explicitly:
    > **Odova ships no in-app purchase.** `release-and-store-shipping` rule 15 requires a
    > first release to submit the app version *and* its first in-app purchase together, or
    > App Review closes the submission unreviewed under Guideline 2.1(b). That rule has no
    > application here: there is no purchase of any type, so `GET
    > /v1/reviewSubmissions/{id}/items` returns **1** item and that is correct. The Paid
    > Applications Agreement is not required for a free app with no purchases. If a purchase
    > is ever added, `test/policy/no_iap_test.dart` fails and this paragraph is rewritten in
    > the same PR.
    plus the account-holder-only gates, each with a date and a name, raised on day one because
    none of them has an API.
- **Verify**
  ```bash
  flutter test test/policy/no_iap_test.dart test/policy/submission_record_test.dart
  ```
  A pass is a record with no blank lines and a test that will break if the premise changes.
- **Done when**
  - [ ] The no-IAP position is stated explicitly, with the rule it is an exception to named.
  - [ ] Every account-holder-only gate is raised, dated and named.
  - [ ] A future IAP breaks a test rather than a submission.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

### Task 19.10 — Cut 1.0.0+1: the ordered ritual, the staged rollout, the tag

- **Goal** — Odova is in the stores, from a tagged commit, with a halt criterion someone is
  watching.
- **Spec** — §17 (every gate green before the tag).
- **Skills** — `release-and-store-shipping` (the ordered ritual, rules 2, 12, 13 and 14),
  `ci-pipeline-and-gates`, `design-review-workflow`.
- **Write these tests first**
  - `test/policy/release_preconditions_test.dart` — one test per precondition, so the ritual
    cannot be entered on a maybe:
    - `working tree is clean` · `CI is green on this commit` · `design/review/SIGNOFF-*.md
      exists and reads SIGNED OFF` · `release/checks/1.0.0+1.md exists and is complete` ·
      `CHANGELOG.md has a dated 1.0.0 section` · `the build number is greater than every
      number in release/uploaded-build-numbers.txt`.
  - `test/policy/rollout_plan_test.dart`:
    - `a halt criterion is written before the rollout starts` — `release/rollout-1.0.0.md`
      names the crash-free-sessions threshold and the person watching it. Fails on an empty
      plan, which is how a bad build reaches 100%.
- **Then build** — **only when the developer asks for a release by name.** Then, in order and
  without reordering:
  1. Preconditions (the tests above).
  2. `version: 1.0.0+1` committed alone.
  3. `bash tools/release.sh` — artifacts with obfuscation and versioned symbols.
  4. Archive `build/symbols/1.0.0+1/` off-machine. This is the step nobody misses twice.
  5. Install the artifact on real hardware and walk the primary flow (Task 19.8's artifact
     covers the depth; this is the smoke test on the exact bundle).
  6. Record the budgets against Task 19.7's numbers.
  7. Reconcile the declarations — merged permissions, Data Safety, nutrition labels,
     `PrivacyInfo.xcprivacy`, every privacy sentence in six languages.
  8. Upload to the internal track and TestFlight, and smoke-test **from the store**, not from
     a local install — store delivery re-signs and re-compresses.
  9. **Read the store back**: price and territory availability, screenshots present for every
     required display type, metadata complete in all six locales, the privacy questionnaire
     answered. A green upload log is not server state, and a committed screenshot folder is
     not an uploaded screenshot set.
  10. Tag `v1.0.0`, publish the notes, append the build number to
      `release/uploaded-build-numbers.txt`, start the staged rollout (internal → closed →
      production at a percentage) and watch the crash-free rate against the written halt
      criterion.
- **Verify**
  ```bash
  flutter test test/policy/release_preconditions_test.dart test/policy/rollout_plan_test.dart
  bash tools/check_release_hygiene.sh
  git tag -l v1.0.0 && git show --stat v1.0.0
  ```
  A pass is a tag on the exact commit that built the uploaded artifact, with the symbol
  archive and the notes beside it.
- **Done when**
  - [ ] Every precondition passed as a test, not as a memory.
  - [ ] Symbols archived before upload; build number 1 recorded as burned.
  - [ ] Store-side state read back rather than trusted, in all six locales.
  - [ ] `v1.0.0` tagged, notes published, rollout staged with a written halt criterion and a
        named person watching it.
- **Estimate** — 0.5 h (CC) · ~0.5 week (human)

## Definition of done

- [ ] Odova's own icon and a Calm-token launch screen on both platforms, in both appearances.
- [ ] No signing material in the working tree or in `git log --all`, and each hygiene gate has
      been seen to fail on a planted violation.
- [ ] `version: 1.0.0+1` is the only version source; About, the export envelope and the store
      all show the same numbers.
- [ ] The merged manifest's permission set equals the committed list, `INTERNET` absent, and
      the no-network source-graph gate runs in CI.
- [ ] `PrivacyInfo.xcprivacy`, Data Safety and the nutrition labels are reconciled against
      `pubspec.lock`; §18.12 (OS auto-backup) is closed in writing; no absolute privacy claim
      in any locale.
- [ ] Store listing complete in en, de, fr, fa, ar and ckb, inside every length limit, with
      screenshots for every required display type including RTL.
- [ ] Artifacts build with `--obfuscate --split-debug-info`, symbols archived off-machine
      before upload, budgets recorded.
- [ ] `release/checks/1.0.0+1.md` records the aeroplane-mode walk from a clean install on a
      never-online device, and the upgrade check or its explicit not-applicable.
- [ ] `release/app-store-submission.md` states the no-IAP position and why rule 15 does not
      apply, pinned by a test.
- [ ] `v1.0.0` tagged from a green commit with the design-review sign-off present, rolled out
      in stages against a written halt criterion.
- [ ] Every task above is checked off, and its tests pass.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean and `flutter test` is green.
- [ ] `/simplify` has been run over the epic's changes and its findings applied or answered.
- [ ] `/code-review` has been run over the epic's changes and its findings applied or answered.

## Progress file

> **Before starting, create the empty progress file `epics/progress/EPIC-19.md`.** It starts
> empty. Append one line per task as it completes — what was built, what was deferred, and
> anything the next epic needs to know. It is the running log for this epic and the handover
> to the next one.
