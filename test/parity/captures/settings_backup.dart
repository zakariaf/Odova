// `settings.backup`, in all four combinations.
//
// SPEC.md §13 and §4. The state is SUPPLIED rather than read: the screen's
// figures are a record count, a size on disk and the age of the last export,
// and every one of them comes from a database this capture does not have. The
// numbers are the artboard's.
//
// `backupActionsProvider` is overridden with a fake that answers nothing. It is
// never called — a capture takes a frame and presses no buttons — but the real
// one reaches a share sheet, and a provider that could open one during a test
// run is a provider that should not be reachable from here.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/result.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/backup_export_service.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';
import 'package:odova/features/backup/presentation/backup_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings.backup` in one combination.
Future<void> captureSettingsBackup(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.backup',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
      extra: [
        backupActionsProvider.overrideWithValue(_NoActions()),
        backupInitialStateProvider.overrideWithValue(
          BackupScreenState(
            nowUtcMs: kSettingsCaptureDay.millisecondsSinceEpoch,
            entryCount: 431,
            entriesSinceBackup: 68,
            onDiskKilobytes: 4200,
            safetyCopies: const [],
            lastBackupAtUtcMs: kArtboardLastBackupMs,
          ),
        ),
      ],
      child: const BackupScreen(),
    ),
  );
}

/// Answers nothing, and is never asked.
class _NoActions implements BackupActions {
  @override
  Future<Result<int, ExportFailure>> backUpNow() async =>
      const Err(ExportShareRefused('not in a capture'));

  @override
  Future<void> exportFillUpsCsv() async {}

  @override
  Future<void> exportCostsCsv() async {}

  @override
  Future<void> exportServiceHistoryPdf() async {}

  @override
  Future<void> pickFileToRestore() async {}

  @override
  Future<void> undo(SafetyCopyKind kind) async {}

  @override
  Future<void> beginDeleteAll() async {}
}
