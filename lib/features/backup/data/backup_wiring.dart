// Everything `settings.backup` does, wired to the real implementations.
//
// The screen was built against ports with named no-op implementations, so a tap
// did nothing rather than crashing. This is the file that makes them do
// something — and it is its own file because that gap is the exact defect
// EPIC-13 and EPIC-14 each shipped once: a provider that throws in production
// while every test passes against a fake.
//
// Composition only. Every decision was made somewhere testable: the filename in
// `export_filename.dart`, the document in `backup_writer.dart`, the validation
// in `backup_reader.dart`, the swap in `store_importer.dart`, and the order of
// the delete-all flow in `delete_all_flow.dart`.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/store_reader.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';
import 'package:odova/features/backup/domain/backup_writer.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';

/// Where temporary exports and safety copies go.
///
/// Injected rather than read, so a test points it at a scratch path without a
/// plugin — and so the production choice is made at the composition root where
/// it can be read.
final Provider<Future<Directory> Function()> backupDirectoryProvider =
    Provider<Future<Directory> Function()>(
      (ref) => throw UnimplementedError(
        'backupDirectoryProvider is unwired. bootstrap() supplies the app '
        'support directory; a test passes its own.',
      ),
    );

/// The writer, carrying this build's identity and this moment.
///
/// Built per export rather than held: it pins an instant, and a writer held
/// across a session would stamp every backup with the time the app started.
BackupWriter backupWriterFor(Ref ref) {
  final now = ref.read(clockProvider).now();
  return BackupWriter(
    nowUtcMs: now.toUtc().millisecondsSinceEpoch,
    localOffset: now.timeZoneOffset,
    appVersion: kAppVersion,
    appBuild: kAppBuild,
    platform: Platform.isIOS ? 'ios' : 'android',
  );
}

/// Reads the whole store, writes it, hands it to the OS, and stamps it.
///
/// Returns the hand-off instant, or the typed failure — §13 renders each of
/// the three inline with its own sentence and its own actions, and a thrown
/// exception here would be a red screen on the one screen a user reaches when
/// something has already gone wrong.
Future<Result<int, ExportFailure>> exportBackup(Ref ref) async {
  final store = await readStoreSnapshot(ref.read(appDatabaseProvider));

  final service = BackupExportService(
    share: ref.read(shareServiceProvider),
    temporaryDirectory: ref.read(backupDirectoryProvider),
    writer: backupWriterFor(ref),
  );

  final result = await service.export(
    store,
    localNow: ref.read(clockProvider).now(),
  );

  return switch (result) {
    Ok(:final value) => Ok(await _stamp(ref, value)),
    Err(:final failure) => Err(failure),
  };
}

/// Stamps the hand-off and returns it.
///
/// §6 §6: on the hand-off, not on a confirmed save. The OS never tells the app
/// what the user did with the file.
///
/// Straight to the REPOSITORY and not through `SettingsWriter`. Two reasons,
/// and the first is a rule: `structure_test` refuses one feature importing
/// another, and the writer belongs to Settings. The second is that the writer's
/// only added behaviour is rescheduling notifications after a text-affecting
/// change, and no notification body names the last backup date — rebuilding
/// the whole schedule after an export would be work nobody asked for at the
/// moment the user is waiting for a share sheet.
Future<int> _stamp(Ref ref, int atUtcMs) async {
  await ref
      .read(settingsRepositoryProvider)
      .setLastBackupAt(atUtcMs: atUtcMs, updatedAtUtcMs: atUtcMs);
  return atUtcMs;
}

/// The export, as one function type.
///
/// A provider rather than a bare function so a test can reach it from a plain
/// `ProviderContainer` — which is exactly how the two defects this file exists
/// to prevent would have been caught.
typedef ExportBackup = Future<Result<int, ExportFailure>> Function();

/// The export, as a provider a test can reach from a bare container.
final Provider<ExportBackup> backupExportProvider = Provider<ExportBackup>(
  (ref) =>
      () => exportBackup(ref),
);

/// The real `BackupActions`.
///
/// Every member that has a real implementation gets one; the ones that do not
/// say so in a comment rather than pretending. The no-op form stays as the
/// provider's default so a widget test pumps without a database, and
/// `bootstrap()` installs this.
class WiredBackupActions implements BackupActions {
  /// Creates the actions over the provider ref.
  const WiredBackupActions(this._ref);

  final Ref _ref;

  @override
  Future<Result<int, ExportFailure>> backUpNow() => exportBackup(_ref);

  // The three below need a vehicle picker and the CSV and PDF writers, which
  // are EPIC-15 tasks 15.8 and 15.9. They are no-ops rather than throws for
  // the same reason as `NoBackupActions`: a tap that does nothing is a bug a
  // user reports, and a tap that crashes is a bug that loses their place.
  @override
  Future<void> exportFillUpsCsv() async {}

  @override
  Future<void> exportCostsCsv() async {}

  @override
  Future<void> exportServiceHistoryPdf() async {}

  // The picker's Dart port exists — `filePickerProvider` — and its native
  // halves do not: the share channel has Kotlin and Swift behind it and this
  // one does not yet. Named here so the gap is a line somebody can search for.
  @override
  Future<void> pickFileToRestore() async {}

  @override
  Future<void> undo(SafetyCopyKind kind) async {}

  @override
  Future<void> beginDeleteAll() async {}
}
