// `settings.import`, in all four combinations.
//
// SPEC.md §4.3's preview. A modal over `settings.backup`, and the reference
// draws it that way — so this capture stacks the two rather than shooting the
// sheet on an empty ground, the same composition the three `dialog.*` captures
// use.
//
// The preview is SUPPLIED, and nothing is written to reach it. §4.3's whole
// promise is that the file is read and compared before anything is applied,
// and a capture that reached this state by importing a fixture would be
// photographing the state after the write it exists to precede.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/application/import_notifier.dart';
import 'package:odova/features/backup/domain/import_plan.dart';
import 'package:odova/features/backup/domain/import_preview.dart';
import 'package:odova/features/backup/presentation/backup_screen.dart';
import 'package:odova/features/backup/presentation/import_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// The file the artboard's header names, and what restoring it would do.
///
/// A REPLACE, which is the only variant v1 has — §2: "import replaces; there is
/// no merge in v1" — and the counts differ in both directions so the preview's
/// NOW → AFTER column has something to say.
ImportPreviewState _preview() => ImportPreviewState(
  variant: const ReplaceVariant(),
  fileName: 'odova-backup-2026-04-11-0930.json',
  exportedAtUtcMs: DateTime.utc(2026, 4, 11, 9, 30).millisecondsSinceEpoch,
  comparison: buildComparison(
    now: const {'vehicles': 1, 'fillups': 412, 'services': 37},
    after: const {'vehicles': 3, 'fillups': 388, 'services': 41},
    kinds: const ['vehicles', 'fillups', 'services'],
  ),
  plan: ImportPlan(
    store: StoreSnapshot(
      settings: AppSettings(
        schemaVersion: 1,
        currencyDefault: Currency.tryParse('EUR')!,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
    ),
    warnings: const [],
    recordsRead: 388,
    recordsInFile: 391,
  ),
);

/// The backdrop's own figures, the same ones `settings.backup` is shot with.
BackupScreenState _backupState() => BackupScreenState(
  nowUtcMs: kSettingsCaptureDay.millisecondsSinceEpoch,
  entryCount: 431,
  entriesSinceBackup: 68,
  onDiskKilobytes: 4200,
  safetyCopies: const [],
  lastBackupAtUtcMs: kArtboardLastBackupMs,
);

/// Captures `settings.import` in one combination.
Future<void> captureSettingsImport(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.import',
    config: config,
    tab: 3,
    // The sheet over `settings.backup`, which is the screen §4.3 opens it
    // from. It was over a `SizedBox.shrink()` first — the file's own doc said
    // it stacked the two and the code did the opposite, so the sheet was shot
    // on an empty ground with the tab bar under nothing.
    child: settingsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      extra: [backupInitialStateProvider.overrideWithValue(_backupState())],
      child: const BackupScreen(),
    ),
    overlay: settingsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      extra: [importInitialStateProvider.overrideWithValue(_preview())],
      child: const ImportScreen(),
    ),
  );
}
