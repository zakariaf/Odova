import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/error_handlers.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/startup_purge.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/export/export_stamp.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/app_database_opener.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/data/ui_state/ui_state_provider.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/data/backup_wiring.dart';
import 'package:odova/theme/calm/font_licences.dart';
import 'package:path_provider/path_provider.dart';

// Override lives in misc.dart in Riverpod 3.x, not the root library.

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

  // ICU's date symbols, which are NOT compiled in the way its number symbols
  // are. `DateFormat.yMMMMd('de')` throws `LocaleDataException` until this has
  // run, and it runs once for the process — so it belongs on the cold-launch
  // path rather than behind the first screen that formats a date, where the
  // throw would land on a user instead of on a test.
  //
  // It is awaited but not slow: `date_symbol_data_local` is a compiled Dart
  // table, not a file read, so nothing here touches the disk or a socket.
  // Started FIRST, and awaited last. `readLaunchFacts` spawns drift's
  // background isolate and opens the file; `initializeDateFormatting` is
  // synchronous main-isolate CPU that builds ICU's symbol tables. Sequenced the
  // other way they add up; overlapped they cost whichever is slower, and the
  // 2.0s cold-launch budget in SPEC.md §17 is the reason to care.
  // Through `openMigratedDatabase`, not `AppDatabase()`.
  //
  // EPIC-05 built the migration guard — the pre-migration safety copy, the
  // refusal when it cannot be written, the roll-back and the read-only
  // degraded mode — and nothing ever called it. `bootstrap()` opened the
  // database directly, so §6.3.3's escape route and §6.4.4's "no exceptions"
  // were true of a function with no production caller. EPIC-15 task 15.3 then
  // made that copy importable, which is only worth anything if it exists.
  //
  // Found by the review pass over this epic, and it is the third time this
  // project has shipped a seam satisfied only in tests.
  final supportDirectory = await getApplicationSupportDirectory();
  final outcome = await openMigratedDatabase(
    databaseFileIn(supportDirectory),
    safetyDirectory: supportDirectory,
    stamp: ExportStamp(
      nowUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      appVersion: kAppVersion,
      appBuild: kAppBuild,
      platform: Platform.isIOS ? 'ios' : 'android',
    ),
  );

  // Every outcome carries an open database, so nothing here builds one — and
  // `lib/app` therefore imports no drift, which `check_drift_confinement`
  // requires and which the first version of this broke.
  //
  // §14: both failure outcomes come up READ-ONLY on the old schema rather than
  // refusing to launch. The user must be able to open the app and get their
  // data out; a crash loop leaves uninstalling as the only remedy, and
  // uninstalling deletes it.
  final database = switch (outcome) {
    OpenedCleanly(:final database) => database,
    MigrationRefused(:final database) => database,
    MigrationRolledBack(:final database) => database,
  };
  final migrationFailed = outcome is! OpenedCleanly;

  final facts = readLaunchFacts(database, migrationFailed: migrationFailed);
  // Beside the database, in the application SUPPORT directory, and started with
  // it: SPEC.md §9's dismissal keys are read on the FIRST build of Home, so a
  // store that opened later would draw a strip the user already dismissed and
  // then take it away.
  final uiState = _openUiState();

  await initializeDateFormatting();

  // §3's purge, for the deletes whose snackbar never got to expire because the
  // app was killed inside its six seconds.
  //
  // AFTER `facts`, and that ordering is the whole point. It used to be started
  // above with `unawaited`, on the theory that an unawaited future costs the
  // launch nothing. It does not: drift runs one background isolate with a
  // serialized statement queue, so the purge's write TRANSACTION was already
  // in front of `readLaunchFacts`'s `SELECT COUNT(*)` — the query that gates
  // the first frame — and `bootstrap` awaits that below.
  //
  // The scan is genuinely expensive, too. Every index in `app_database.dart`
  // is partial on `WHERE deleted_at_utc_ms IS NULL`, so by construction none
  // of them covers `DELETE ... WHERE deleted_at_utc_ms IS NOT NULL`: eight
  // full table scans in a `synchronous = FULL` transaction. Adding eight more
  // indexes to serve a launch-time sweep would be the wrong trade — they cost
  // every write forever to spare one read at startup.
  //
  // Still unawaited: it is housekeeping over rows the user has already
  // deleted, nothing on the first frame reads them, and
  // `sweepDeletedOnStartup` never throws — which is why an unawaited future
  // here cannot become an unhandled error.
  final launchFacts = await facts;
  unawaited(
    sweepDeletedOnStartup(
      database,
      nowUtcMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );

  return [
    crashSinkProvider.overrideWithValue(crashSink),
    clockProvider.overrideWithValue(const Clock()),
    // The database is built HERE and injected, not constructed by its provider.
    // `readLaunchFacts` has to query it before the first frame, and two
    // connections to one file is how a WAL ends up with a reader that cannot
    // see a writer's committed row.
    appDatabaseProvider.overrideWithValue(database),
    initialLaunchFactsProvider.overrideWithValue(launchFacts),
    uiStateProviderStore.overrideWithValue(await uiState),
    // The midnight timer, armed only in a running app. SPEC.md §9 lists the
    // local midnight crossing as a recompute trigger; a timer set for up to 24
    // hours outlives every widget test, and `testWidgets` fails the NEXT test
    // over one still pending — so the default is inert and this is where it is
    // switched on.
    todayTicksProvider.overrideWithValue(true),
    // EPIC-15. The screen was built against a no-op port so a widget test
    // pumps without a database; this is where the real one is installed. A
    // port with a named no-op and no production wiring is the defect EPIC-13
    // and EPIC-14 each shipped once — `bootstrap_wires_ports_test` reads both
    // out of a bare container so it cannot recur silently.
    backupDirectoryProvider.overrideWithValue(getApplicationSupportDirectory),
    // The free-space probe. Without it `BackupExportService` skips its check
    // entirely, so §13's "free up about 6 MB" and the figure it names were
    // unreachable code and a full disk surfaced as the generic write failure.
    freeDiskBytesProvider.overrideWithValue(freeBytesInSupportDirectory),
    backupActionsProvider.overrideWith(WiredBackupActions.new),
  ];
}

/// The UI-state store, in the same directory as the database file.
///
/// The application SUPPORT directory and not Documents, for the reason
/// `connection.dart` gives about the database: Documents is user-visible and
/// iCloud-backed on iOS, and this file is neither the user's business nor worth
/// syncing.
Future<UiStateStore> _openUiState() async =>
    UiStateStore.open(await getApplicationSupportDirectory());

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
Future<LaunchFacts> readLaunchFacts(
  AppDatabase database, {
  bool migrationFailed = false,
}) async {
  final settings = await SettingsRepository(database).read();
  final vehicles = await database
      .customSelect(
        'SELECT COUNT(*) AS n FROM vehicles WHERE deleted_at_utc_ms IS NULL;',
      )
      .getSingleOrNull();

  return LaunchFacts(
    onboardingDone: settings.valueOrNull?.onboardingDone ?? false,
    liveVehicleCount: vehicles?.read<int>('n') ?? 0,
    // From the OPEN, which is the only place that knows. It decides whether
    // the app launches on `settings.backup` instead of `home` — §7's one
    // exception to opening on Home — so it cannot be defaulted here.
    migrationFailed: migrationFailed,
  );
}
