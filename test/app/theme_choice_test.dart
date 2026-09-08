// The Appearance control actually changes the palette.
//
// SPEC.md §13 gives `settings` a three-way System / Light / Dark control. It
// wrote `theme` through `settingsWriterProvider` from the day it shipped, and
// nothing read it back: `OdovaApp.themeMode` defaulted to `ThemeMode.system`
// and `app.dart` constructed `OdovaApp()` with no argument. Tapping Dark did
// nothing at all, on a device, for four epics.
//
// The field's own comment said "there is no settings store yet; the seam is
// `themeMode` and EPIC-14 fills it from SettingsRepository". EPIC-14 shipped
// the store. Nothing failed, because a seam nobody connects is a seam whose
// tests all pass.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/data/repositories/providers.dart';

AppSettings _settings(String theme) => AppSettings(
  schemaVersion: 1,
  currencyDefault: Currency.tryParse('EUR')!,
  theme: theme,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

/// What the app needs to build at all, plus the row under test.
///
/// `bootstrap()` supplies the launch facts and the router in production; the
/// app has no default for either and reading one throws.
List<Override> _overrides(String theme) => [
  settingsProvider.overrideWith((ref) => Stream.value(_settings(theme))),
  vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
  initialLaunchFactsProvider.overrideWithValue(
    const LaunchFacts(
      onboardingDone: true,
      liveVehicleCount: 1,
      migrationFailed: false,
    ),
  ),
  clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 8))),
];

Future<ThemeMode> _modeFor(
  WidgetTester tester,
  String stored, {
  ThemeMode? override,
}) async {
  // UNMOUNTED first, the same reason `shell_harness.dart` gives: pumping a
  // second `OdovaApp` over the first leaves the first one's router
  // driving the tree, and every case after the first reads the previous case's
  // answer while looking like it reads its own.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(stored),
      child: OdovaApp(themeMode: override),
    ),
  );
  // The stream lands a frame in; that delay is real and is documented on
  // `_storedThemeMode` rather than papered over.
  await tester.pump();
  await tester.pump();

  return tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
}

void main() {
  testWidgets('the stored choice decides the palette', (tester) async {
    expect(await _modeFor(tester, 'dark'), ThemeMode.dark);
    expect(await _modeFor(tester, 'light'), ThemeMode.light);
    expect(await _modeFor(tester, 'system'), ThemeMode.system);
  });

  testWidgets('an unreadable value follows the device rather than guessing', (
    tester,
  ) async {
    // A row from an older build, or one an import wrote. Picking a palette on
    // a value the app cannot read is a guess the user sees on every screen —
    // SPEC.md §2's rule, applied to the one setting that repaints everything.
    expect(await _modeFor(tester, 'sepia'), ThemeMode.system);
    expect(await _modeFor(tester, ''), ThemeMode.system);
  });

  testWidgets('an explicit argument still wins, for captures and tests', (
    tester,
  ) async {
    // The 112 parity captures pass one: a capture that followed the stored row
    // would compare a dark screenshot against a light reference on whichever
    // machine ran it.
    expect(
      await _modeFor(tester, 'dark', override: ThemeMode.light),
      ThemeMode.light,
    );
  });
}
