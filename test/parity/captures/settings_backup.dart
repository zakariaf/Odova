// `settings.backup`, in all four combinations.
//
// SPEC.md §13 and §4. The state is SUPPLIED rather than read: the screen's
// figures are a record count, a size on disk and the age of the last export,
// and every one of them comes from a database this capture does not have. The
// numbers are the artboard's.
//
// `backupActionsProvider` is NOT overridden. Its own default is
// `const NoBackupActions()` — seven no-ops declared beside it in
// `backup_notifier.dart` — so an override here would have restored the default
// through a second copy of the same interface, which goes stale silently the
// day `BackupActions` gains a method.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
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
      rtl: isRtl(config),
      locale: config.locale,
      extra: [
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
