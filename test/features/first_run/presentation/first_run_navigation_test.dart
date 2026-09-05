// The two steps of first run, and the edge between them.
//
// SPEC.md §8: "Continue — Commits `Settings`, pushes `vehicle.edit`
// (firstRun)."
// And: "Continue, then one screen with one number to type, then Start, and the
// app is on Home."
//
// The edge is easy to leave out and impossible to notice from either screen's
// own tests. `Settings.onboarding_done` stays FALSE until a vehicle exists —
// §8 says so, so that a kill between the two steps replays from the language
// step — which means the launch gate's rule 3 keeps the user on
// `firstrun.language` until something navigates. If nothing does, a fresh
// install can never create a vehicle, and every other test on both screens
// still passes.
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/features/first_run/presentation/first_run_language_screen.dart';
import 'package:odova/features/first_run/presentation/first_run_vehicle_screen.dart';

import '../../../app/routing/shell_harness.dart';

Future<AppDatabase> _emptyDb() async =>
    AppDatabase.forTesting(NativeDatabase.memory());

List<Override> _overrides(AppDatabase db) => <Override>[
  appDatabaseProvider.overrideWithValue(db),
  clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 11, 20))),
];

/// A FRESH install: no settings row, no vehicle.
const _fresh = LaunchFacts(
  onboardingDone: false,
  liveVehicleCount: 0,
  migrationFailed: false,
);

void main() {
  testWidgets('Continue moves the user to the vehicle step', (tester) async {
    // The defect this replaced: Continue wrote the settings row and navigated
    // nowhere. `onboarding_done` is still false at that moment — by design —
    // so `appRedirect` rule 3 pinned the user on the language screen, and
    // nothing in `lib/` pushed `firstrun.vehicle` except the last-vehicle
    // delete. A fresh install could not create a vehicle at all.
    final db = await _emptyDb();
    addTearDown(db.close);

    await pumpShell(
      tester,
      Routes.firstRunLanguage,
      overrides: _overrides(db),
      facts: _fresh,
    );
    expect(find.byType(FirstRunLanguageScreen), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(FirstRunVehicleScreen), findsOneWidget);
    // And the settings row was written on the way — the language choice has to
    // survive a kill between the two steps.
    final settings = await db
        .customSelect('SELECT COUNT(*) AS n FROM settings;')
        .getSingle();
    expect(settings.read<int>('n'), 1);
  });

  testWidgets('a Continue that cannot write says so and stays put', (
    tester,
  ) async {
    // SPEC.md §8's Error state: "Only a disk write can fail." The failure was
    // completely silent — the notifier set `failed` and no widget watched it,
    // so a user on a full disk tapped Continue repeatedly and got nothing.
    final db = await _emptyDb();
    addTearDown(db.close);
    await db.customStatement('DROP TABLE settings;');

    await pumpShell(
      tester,
      Routes.firstRunLanguage,
      overrides: _overrides(db),
      facts: _fresh,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(FirstRunVehicleScreen), findsNothing);
    expect(
      find.textContaining("Couldn't save"),
      findsOneWidget,
      reason: 'a failure the user cannot see is a failure they retry forever',
    );
  });
}
