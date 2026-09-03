
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
