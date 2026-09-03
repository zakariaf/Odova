
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
