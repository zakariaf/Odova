/// A `ProviderContainer` over an in-memory database, disposed in the right
/// order.
///
/// Written once because the ORDER is the hard-won part and it was pasted into
/// two files with the same explanatory comment. `addTearDown` runs LIFO, so
/// registering `container.dispose` and `db.close` separately closes the
/// DATABASE first and leaves Riverpod holding live drift streams over a closed
/// connection — every test in the file then times out in its tear-down,
/// reporting nothing at all, while the code under test is fine.
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';

/// The container and the database it reads.
typedef DatabaseHarness = ({ProviderContainer container, AppDatabase db});

/// Builds a container over a fresh in-memory database.
///
/// Both are torn down together, container first.
DatabaseHarness containerWithDatabase({
  List<Override> overrides = const [],
  LaunchFacts initialFacts = const LaunchFacts(
    onboardingDone: false,
    liveVehicleCount: 0,
    migrationFailed: false,
  ),
}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // What `bootstrap()` supplies in production. It has no default in the
      // app on purpose: "we have not read the database yet" and "this is a
      // fresh install" are different facts, and the gate must not guess.
      // A test starts from the fresh-install answer unless it says otherwise.
      initialLaunchFactsProvider.overrideWithValue(initialFacts),
      ...overrides,
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return (container: container, db: db);
}

/// Subscribes to [providers] and lets them deliver.
///
/// A subscription, not `container.read(provider.future)`. With nothing
/// listening, Riverpod keeps a `StreamProvider` in its loading state and the
/// `.future` never completes — the test hangs rather than failing. A
/// subscription is also how the app itself uses these, so the test exercises
/// the real path.
///
/// **Only from a plain `test`.** A drift stream never delivers under
/// `testWidgets`: the widget binding's fake async does not run its timers, and
/// the symptom is a ten-minute hang rather than a failure.
Future<void> settleProviders(
  ProviderContainer container,
  List<ProviderListenable<Object?>> providers,
) async {
  for (final provider in providers) {
    addTearDown(container.listen(provider, (_, _) {}).close);
  }
  await pumpEventQueue();
}
