/// The REAL settings stack, as the artboards draw it.
///
/// Seven of `design/reference/calm/`'s screens live under tab 4 — `settings`
/// itself, `settings.language`, `settings.units`, `settings.notifications`,
/// `settings.backup`, `settings.import` and `settings.about` — and every one
/// of them had a reference image, a route and no capture. They share a fixture
/// because they share a phone: one household, one garage, one set of units,
/// and a backup taken on 4 June 2026, which is what `settings-light-ltr.png`
/// draws in its first row.
///
/// The garage is `vehiclesBackdrop`'s, imported rather than re-typed. The
/// Vehicles row prints "Golf, Transit, CB500X" and the `vehicles` screen lists
/// the same four cars; two fixtures would let those two disagree while both
/// captures passed.
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/l10n/locale_controller.dart';

import 'parity_capture.dart';
import 'vehicles_backdrop.dart';

/// The day every settings capture is taken on.
///
/// 2026-09-04, the same day `vehicles` and `home` are shot on. The Backup row
/// prints an AGE — "Last backup 4 June 2026 — 3 months ago" — so a capture on
/// a different day draws a different sentence and a different band.
final DateTime kSettingsCaptureDay = DateTime.utc(2026, 9, 4);

/// 4 June 2026, which is what the artboard's first row names.
///
/// Three months back, so the row is `recent` and NOT `stale`: §13 turns the
/// amber dot on past 90 days, and 92 days would draw a dot the reference does
/// not have.
final int kArtboardLastBackupMs = DateTime.utc(
  2026,
  6,
  4,
).millisecondsSinceEpoch;

/// The household the settings artboards describe.
///
/// `km · L · €` in the Units row and `On · 09:00` in Notifications, both of
/// which are this record rather than a default — a fixture that let them fall
/// back would still draw the reference's text today and stop the day a default
/// changed.
AppSettings settingsFixture({required String language}) => AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  activeVehicleId: artboardGolfId,
  language: language,
  lastBackupAtUtcMs: kArtboardLastBackupMs,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// The overrides every settings capture needs, around [child].
///
/// The stored LANGUAGE is taken from [locale] rather than left at `system`.
/// `localeControllerProvider` reads the setting and wins over the app's own
/// `locale:`, so a backdrop that left it alone would photograph an English
/// screen under a Persian filename — the single most common way an RTL capture
/// passes for the wrong reason.
Widget settingsBackdrop({
  required bool rtl,
  required Locale locale,
  required Widget child,
  List<Override> extra = const [],
}) => ProviderScope(
  overrides: <Override>[
    settingsProvider.overrideWith(
      (ref) => Stream.value(settingsFixture(language: locale.languageCode)),
    ),
    vehiclesProvider.overrideWith(
      (ref) => Stream.value(artboardGarage(rtl: rtl, includeSold: false)),
    ),
    clockProvider.overrideWithValue(Clock.fixed(kSettingsCaptureDay)),
    // SUPPLIED, because `todayProvider` is null until something sets it and
    // the Backup row's age line is the one thing on this screen that is not a
    // constant. Null renders the row with no age at all, which is a real state
    // — the first frame of a cold launch — and not the one the reference draws.
    todayProvider.overrideWith(ArtboardToday.new),
    // What `bootstrap()` supplies in production; the app has no default and
    // reading it throws. `migrationFailed: false`, so the Backup row is the
    // ordinary one rather than §13's failed-migration variant.
    initialLaunchFactsProvider.overrideWithValue(
      const LaunchFacts(
        onboardingDone: true,
        liveVehicleCount: 3,
        migrationFailed: false,
      ),
    ),
    deviceLocalesProvider.overrideWithValue(
      artboardDeviceLocales(locale),
    ),
    ...extra,
  ],
  child: child,
);

/// A `todayProvider` that is already the capture day.
///
/// Public because `trips.edit` dates its form from today too, and a second
/// copy is a second day the captures could disagree about.
class ArtboardToday extends Today {
  @override
  CivilDate? build() => CivilDate.fromDateTime(kSettingsCaptureDay);
}
