// The FIRST painted frame is the destination, not Home followed by a redirect.
//
// `app-startup-and-bootstrap` rule 5: a flash of the wrong screen is a visible
// defect, and it is what happens when the app always opens on `/` and lets the
// redirect sort it out. So `bootstrap()` reads the launch facts before
// `runApp`, and the router's `initialLocation` is already the answer.
//
// Two groups, and the split is deliberate. Where the facts COME FROM is a
// database question and is asked in a plain `test` — a drift stream under
// `testWidgets` never delivers, because the widget binding's fake async does
// not run its timers, and the symptom is a test that hangs for ten minutes
// rather than one that fails. What the app DOES with the facts is a widget
// question and is asked with the facts injected.
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/bootstrap.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/app_router.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/routing/placeholder_screen.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/degraded_mode.dart';
import 'package:odova/data/repositories/providers.dart';

import '../data/support/rows.dart';
import '../support/provider_harness.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';

/// The facts a widget test is pretending to have read.
class _Facts extends Notifier<LaunchFacts> {
  _Facts(this._initial);

  final LaunchFacts _initial;

  @override
  LaunchFacts build() => _initial;

  /// Replaces the facts, as a database change would.
  set current(LaunchFacts value) => state = value;

  /// What the app is being told right now.
  LaunchFacts get current => state;
}

void main() {
  group("the facts come from the app's own state", () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      final harness = containerWithDatabase();
      container = harness.container;
      db = harness.db;
    });

    Future<LaunchFacts> facts() async {
      await settleProviders(container, [settingsProvider, vehiclesProvider]);
      return container.read(launchFactsProvider);
    }

    test('a fresh install: nothing done, no vehicles, healthy', () async {
      final read = await facts();
      expect(read.onboardingDone, isFalse);
      expect(read.liveVehicleCount, 0);
      expect(read.migrationFailed, isFalse);
      expect(initialLocationFor(read), Routes.firstRunLanguage);
    });

    test('a settings row is not the same fact as a finished first run', () {
      // The mutation this exists to catch: `onboardingDone` implemented as "a
      // settings row exists". First run writes that row on the LANGUAGE step —
      // language, direction and that locale's default units — and only sets the
      // flag on the vehicle step's Save. So a user who picked Persian and then
      // put the phone down has a settings row and an unfinished first run, and
      // reading the row's existence would skip them past the language step they
      // never confirmed.
      const midFirstRun = LaunchFacts(
        onboardingDone: false,
        liveVehicleCount: 0,
        migrationFailed: false,
      );
      expect(initialLocationFor(midFirstRun), Routes.firstRunLanguage);
    });

    test(
      'a half-finished first run still opens on the language step',
      () async {
        // The same fact, through the real database: the row is there, the flag
        // is not.
        await insertSettings(db, language: 'fa');

        final read = await facts();
        expect(read.onboardingDone, isFalse);
        expect(initialLocationFor(read), Routes.firstRunLanguage);
      },
    );

    test('a returning user with a car opens on Home', () async {
      await insertVehicle(db, id: _golf);
      await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);

      expect(initialLocationFor(await facts()), Routes.home);
    });

    test('an empty garage opens on the vehicle step', () async {
      await insertSettings(db, onboardingDone: true);

      expect(initialLocationFor(await facts()), Routes.firstRunVehicle);
    });

    test('a failed migration opens on Backup', () async {
      await insertVehicle(db, id: _golf);
      await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
      container
          .read(degradedModeProvider.notifier)
          .migrationFailed(atVersion: 1, expectedVersion: 2);

      expect(initialLocationFor(await facts()), Routes.settingsBackup);
    });

    test('the facts follow the database without a relaunch', () async {
      // The half `refreshListenable` depends on: the provider has to CHANGE
      // when first run finishes, or the bridge has nothing to bridge.
      expect((await facts()).onboardingDone, isFalse);

      await insertVehicle(db, id: _golf);
      await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
      await pumpEventQueue();

      final after = container.read(launchFactsProvider);
      expect(after.onboardingDone, isTrue);
      expect(after.liveVehicleCount, 1);
    });

    test('a soft-deleted vehicle is not a live one', () async {
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
      expect((await facts()).liveVehicleCount, 2);

      // `customUpdate` with `updates:` — a raw `customStatement` does not tell
      // drift which tables it touched, so the watching query is never
      // invalidated and the stream keeps the stale answer.
      await db.customUpdate(
        'UPDATE vehicles SET deleted_at_utc_ms = 2000 WHERE id != ?',
        variables: [const Variable<String>(_golf)],
        updates: {db.vehicles},
      );
      await pumpEventQueue();

      expect(container.read(launchFactsProvider).liveVehicleCount, 1);
    });
  });

  group('the facts are known BEFORE the first frame', () {
    // The defect this group exists for, found by a code-review pass and
    // verified against a real database: `launchFactsProvider` derived its
    // answer from two drift streams, and on the first synchronous read those
    // carry no value at all. So the first answer on EVERY cold start was
    // `(onboardingDone: false, liveVehicleCount: 0)` — a returning user with a
    // car and eight years of history opened on the language step, corrected
    // only once the queries landed, which on a slow phone with a large file is
    // many frames later.
    //
    // The tests that should have caught it did not: the widget group injects
    // the facts, and the plain-`test` group settles the streams first. Both are
    // the right shape for what they assert and neither exercises frame ONE.

    test('bootstrap reads them from disk, not from a stream', () async {
      final harness = containerWithDatabase();
      await insertVehicle(harness.db, id: _golf);
      await insertSettings(
        harness.db,
        activeVehicleId: _golf,
        onboardingDone: true,
      );

      final facts = await readLaunchFacts(harness.db);

      expect(facts.onboardingDone, isTrue);
      expect(facts.liveVehicleCount, 1);
      expect(initialLocationFor(facts), Routes.home);
    });

    test('a soft-deleted vehicle is not counted by that read', () async {
      final harness = containerWithDatabase();
      await insertVehicle(harness.db, id: _golf);
      await insertVehicle(harness.db, id: _polo, name: 'The Polo');
      await insertSettings(harness.db, onboardingDone: true);
      await harness.db.customUpdate(
        'UPDATE vehicles SET deleted_at_utc_ms = 2000 WHERE id != ?',
        variables: [const Variable<String>(_golf)],
        updates: {harness.db.vehicles},
      );

      expect((await readLaunchFacts(harness.db)).liveVehicleCount, 1);
    });

    test('the FIRST read of the gate is the disk answer, not (false, 0)', () {
      // The regression itself. Nothing is settled and no stream has delivered:
      // `settingsProvider` and `vehiclesProvider` are both `AsyncLoading` with
      // no value, which is precisely the state the router is built in.
      const returning = LaunchFacts(
        onboardingDone: true,
        liveVehicleCount: 1,
        migrationFailed: false,
      );
      final harness = containerWithDatabase(initialFacts: returning);

      final first = harness.container.read(launchFactsProvider);

      expect(first, returning);
      expect(initialLocationFor(first), Routes.home);
    });

    test('an errored stream keeps the disk answer rather than resetting', () {
      // `AsyncError` carries no value either, and `noProviderRetry` means there
      // is no recovery. Falling back to `false`/`0` would park an established
      // user in onboarding, where first run's Save overwrites the real settings
      // row — a data loss caused by rendering "unknown" as a fact.
      const returning = LaunchFacts(
        onboardingDone: true,
        liveVehicleCount: 2,
        migrationFailed: false,
      );
      final harness = containerWithDatabase(
        initialFacts: returning,
        overrides: [
          settingsProvider.overrideWith(
            (ref) => Stream<AppSettings?>.error(StateError('disk')),
          ),
          vehiclesProvider.overrideWith(
            (ref) => Stream<List<Vehicle>>.error(StateError('disk')),
          ),
        ],
      );
      addTearDown(
        harness.container.listen(launchFactsProvider, (_, _) {}).close,
      );

      expect(harness.container.read(launchFactsProvider), returning);
    });

    test('and a delivered stream overrides the disk answer', () async {
      // The other arm: the fallback must not become a floor. A user who
      // finishes first run in this session has to be seen to.
      final harness = containerWithDatabase();
      await settleProviders(harness.container, [
        settingsProvider,
        vehiclesProvider,
      ]);
      expect(
        harness.container.read(launchFactsProvider).onboardingDone,
        isFalse,
      );

      await insertVehicle(harness.db, id: _golf);
      await insertSettings(
        harness.db,
        activeVehicleId: _golf,
        onboardingDone: true,
      );
      await pumpEventQueue();

      final after = harness.container.read(launchFactsProvider);
      expect(after.onboardingDone, isTrue);
      expect(after.liveVehicleCount, 1);
    });
  });

  group('the first painted frame is the destination', () {
    late _Facts facts;
    late ProviderContainer container;

    /// Mounts the app with [initial] already known, as `bootstrap()` does.
    Future<void> launch(WidgetTester tester, LaunchFacts initial) async {
      facts = _Facts(initial);
      final provider = NotifierProvider<_Facts, LaunchFacts>(() => facts);
      container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [
          launchFactsProvider.overrideWith((ref) => ref.watch(provider)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const OdovaApp(
            locale: Locale('en'),
            themeMode: ThemeMode.light,
          ),
        ),
      );
    }

    /// The screen id the user can actually see.
    ///
    /// `skipOffstage` left at its default, which is what makes this about
    /// PAINTING. `/settings/backup` is a route pushed over `/settings`, so both
    /// screens are in the tree and only the top one is on stage — a finder that
    /// took the first match would report `settings` and call the destination
    /// wrong for a reason that has nothing to do with the gate.
    String screen(WidgetTester tester) => tester
        .widget<PlaceholderScreen>(find.byType(PlaceholderScreen))
        .screenId;

    const returning = LaunchFacts(
      onboardingDone: true,
      liveVehicleCount: 1,
      migrationFailed: false,
    );
    const fresh = LaunchFacts(
      onboardingDone: false,
      liveVehicleCount: 0,
      migrationFailed: false,
    );

    testWidgets('a fresh install paints the language step, not Home', (
      tester,
    ) async {
      await launch(tester, fresh);

      // ONE frame, not `pumpAndSettle` — the claim is about what is PAINTED.
      //
      // Worth being precise about what this proves and what it does not. It
      // does NOT prove `initialLocationFor` is doing the work: go_router
      // applies `redirect` while it resolves the initial route, before the
      // first frame, so this stays green even with the initial location pinned
      // to `/`. That mutation is caught by the pure tests above instead.
      //
      // What it proves is that the two halves AGREE. A gate whose redirect
      // disagreed with the location bootstrap opened on would show up here as
      // the wrong screen — and the flash `app-startup-and-bootstrap` rule 5
      // forbids is what a MISMATCH looks like on a real device, where the
      // engine can paint between resolution and settle.
      await tester.pump();
      expect(screen(tester), 'firstrun.language');
    });

    testWidgets('a returning user paints Home', (tester) async {
      await launch(tester, returning);

      await tester.pump();
      expect(screen(tester), 'home');
    });

    testWidgets('an empty garage paints the vehicle step', (tester) async {
      await launch(
        tester,
        const LaunchFacts(
          onboardingDone: true,
          liveVehicleCount: 0,
          migrationFailed: false,
        ),
      );

      await tester.pump();
      expect(screen(tester), 'firstrun.vehicle');
    });

    testWidgets('a failed migration paints Backup', (tester) async {
      await launch(
        tester,
        const LaunchFacts(
          onboardingDone: true,
          liveVehicleCount: 1,
          migrationFailed: true,
        ),
      );

      await tester.pump();
      expect(screen(tester), 'settings.backup');
    });

    testWidgets('finishing first run releases the gate in place', (
      tester,
    ) async {
      // The `refreshListenable` bridge. Without it the user completes
      // onboarding and stays on the first-run screen until they navigate by
      // hand, which reads as the Save having failed.
      await launch(tester, fresh);
      await tester.pumpAndSettle();
      expect(screen(tester), 'firstrun.language');

      facts.current = returning;
      await tester.pumpAndSettle();

      expect(screen(tester), 'home');
    });

    testWidgets('a second car makes the switcher reachable in place', (
      tester,
    ) async {
      await launch(tester, returning);
      await tester.pumpAndSettle();

      final router = container.read(routerProvider)..go(Routes.vehicleSwitcher);
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), Routes.home);

      facts.current = const LaunchFacts(
        onboardingDone: true,
        liveVehicleCount: 2,
        migrationFailed: false,
      );
      await tester.pumpAndSettle();

      router.go(Routes.vehicleSwitcher);
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), Routes.vehicleSwitcher);
    });
  });
}
