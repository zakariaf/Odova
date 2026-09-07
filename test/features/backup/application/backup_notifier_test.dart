// The screen's state transitions, without a widget tree.
//
// Two of them are worth their own test because they are decisions rather than
// plumbing: what happens to the count line after an export, and what happens
// when the user taps the button twice.
@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/backup/application/backup_notifier.dart';
import 'package:odova/features/backup/domain/backup_chrome.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';

const int _now = 1788374460000;

class _Actions implements BackupActions {
  int calls = 0;
  Completer<int?>? pending;
  int? at;

  @override
  Future<int?> backUpNow() {
    calls++;
    return pending?.future ?? Future<int?>.value(at);
  }

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

ProviderContainer _container(_Actions actions) {
  final container = ProviderContainer(
    overrides: [
      backupActionsProvider.overrideWithValue(actions),
      backupInitialStateProvider.overrideWithValue(
        const BackupScreenState(
          nowUtcMs: _now,
          entryCount: 68,
          entriesSinceBackup: 68,
          onDiskKilobytes: 4200,
          safetyCopies: [],
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a completed export stamps the instant and clears the count', () async {
    final container = _container(_Actions()..at = _now);

    await container.read(backupScreenProvider.notifier).backUpNow();

    final state = container.read(backupScreenProvider);
    expect(state.lastBackupAtUtcMs, _now);
    // §13's line reads "entries since", and the answer immediately after an
    // export is none.
    expect(state.entriesSinceBackup, 0);
    expect(state.chrome.age, BackupAge.recent);
    expect(state.isExporting, isFalse);
  });

  test('a refused export leaves the date alone', () async {
    // The stamp is the hand-off. If the OS never took the file there was no
    // hand-off, and telling the user they have a backup would be worse than
    // telling them nothing.
    final container = _container(_Actions());

    await container.read(backupScreenProvider.notifier).backUpNow();

    final state = container.read(backupScreenProvider);
    expect(state.lastBackupAtUtcMs, isNull);
    expect(state.entriesSinceBackup, 68);
    expect(state.isExporting, isFalse);
  });

  test('a second tap while exporting is ignored', () async {
    // The button is replaced by the progress state on screen, but a fast
    // double tap can land both before the first frame — and a second export
    // writes a second copy of the whole history.
    final actions = _Actions()..pending = Completer<int?>();
    final container = _container(actions);
    final notifier = container.read(backupScreenProvider.notifier);

    final first = notifier.backUpNow();
    await notifier.backUpNow();
    expect(actions.calls, 1);

    actions.pending!.complete(_now);
    await first;
    expect(container.read(backupScreenProvider).lastBackupAtUtcMs, _now);
  });
}
