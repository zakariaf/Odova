import 'package:clock/clock.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/error_handlers.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/theme/calm/font_licences.dart';

/// Builds the real infrastructure once and returns it as provider overrides.
///
/// The composition root. Everything with a side effect — the database, the
/// clock, the crash sink, the notification scheduler — is constructed here and
/// injected; nothing constructs its own. That is what makes a fake a
/// one-line override in a test rather than a global somebody has to remember
/// to reset.
///
/// [crashSink] is the sink `main()` already installed into the error handlers,
/// passed in rather than rebuilt so the handlers and the app agree on where an
/// error goes.
///
/// This function does not install a zone. See [installErrorHandlers].
Future<List<Override>> bootstrap({required CrashSink crashSink}) async {
  // SIL OFL 1.1 obliges the licence to travel with the font. Registering is
  // lazy — the stream is only pulled if somebody opens the licences page — so
  // this costs nothing on the cold-launch path SPEC.md §17 budgets at 2.0s.
  registerFontLicences();

  final database = AppDatabase();
  final facts = await readLaunchFacts(database);

  return [
    crashSinkProvider.overrideWithValue(crashSink),
    clockProvider.overrideWithValue(const Clock()),
    // The database is built HERE and injected, not constructed by its provider.
    // `readLaunchFacts` has to query it before the first frame, and two
    // connections to one file is how a WAL ends up with a reader that cannot
    // see a writer's committed row.
    appDatabaseProvider.overrideWithValue(database),
    initialLaunchFactsProvider.overrideWithValue(facts),
  ];
}

/// Reads the three launch facts from [database], before the first frame.
///
/// This is the work `initialLaunchFactsProvider` exists to hold: a database
/// open and two queries — real asynchronous work that cannot happen inside a
/// synchronous provider, which is exactly why the gate cannot derive its first
/// answer from a stream that has not delivered.
///
/// The vehicle count excludes tombstones, like every other count in the app: a
/// user who deleted their last car has zero vehicles, and SPEC.md §7 sends them
/// to the vehicle step rather than to Home.
Future<LaunchFacts> readLaunchFacts(AppDatabase database) async {
  final settings = await SettingsRepository(database).read();
  final vehicles = await database
      .customSelect(
        'SELECT COUNT(*) AS n FROM vehicles WHERE deleted_at_utc_ms IS NULL;',
      )
      .getSingleOrNull();

  return LaunchFacts(
    onboardingDone: settings.valueOrNull?.onboardingDone ?? false,
    liveVehicleCount: vehicles?.read<int>('n') ?? 0,
    // Set by `DegradedModeController` when a migration fails; false here
    // because nothing has had the chance to record one yet.
    migrationFailed: false,
  );
}
