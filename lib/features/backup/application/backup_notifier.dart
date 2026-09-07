// The state `settings.backup` renders, and the actions it offers.
//
// One notifier per screen, over an immutable state — the house rule from
// `flutter-conventions-index`. What is unusual here is how little of it is
// state: the seven presentation states are `resolveBackupChrome`'s, computed
// on every read, because a cached chrome is a screen that keeps saying "never
// backed up" after the export it just performed.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/features/backup/domain/backup_chrome.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';

/// Everything the screen draws.
@immutable
class BackupScreenState {
  /// Creates the state.
  const BackupScreenState({
    required this.nowUtcMs,
    required this.entryCount,
    required this.entriesSinceBackup,
    required this.onDiskKilobytes,
    required this.safetyCopies,
    this.lastBackupAtUtcMs,
    this.migrationFailed = false,
    this.isExporting = false,
    this.calendar = CalmCalendar.gregorian,
    this.numerals = CalmNumerals.auto,
  });

  /// Now, injected so the ninety-day boundary is testable.
  final int nowUtcMs;

  /// Every record on the phone.
  final int entryCount;

  /// What has been written since the last export.
  final int entriesSinceBackup;

  /// The store's size, for §13's storage line.
  final int onDiskKilobytes;

  /// The copies that exist, of every kind.
  final List<SafetyCopy> safetyCopies;

  /// When the user last exported, or null.
  final int? lastBackupAtUtcMs;

  /// Whether the app came up after a failed migration.
  final bool migrationFailed;

  /// Whether an export is in flight, which replaces the button.
  final bool isExporting;

  /// The user's calendar, for the date.
  final CalmCalendar calendar;

  /// The user's numeral system, for every figure on the screen.
  final CalmNumerals numerals;

  /// §13's state table, resolved fresh on every read.
  BackupChrome get chrome => resolveBackupChrome(
    nowUtcMs: nowUtcMs,
    entryCount: entryCount,
    entriesSinceBackup: entriesSinceBackup,
    lastBackupAtUtcMs: lastBackupAtUtcMs,
    safetyCopies: safetyCopies,
    migrationFailed: migrationFailed,
  );

  /// A copy with [isExporting] flipped.
  BackupScreenState exporting({required bool value}) => BackupScreenState(
    nowUtcMs: nowUtcMs,
    entryCount: entryCount,
    entriesSinceBackup: entriesSinceBackup,
    onDiskKilobytes: onDiskKilobytes,
    safetyCopies: safetyCopies,
    lastBackupAtUtcMs: lastBackupAtUtcMs,
    migrationFailed: migrationFailed,
    isExporting: value,
    calendar: calendar,
    numerals: numerals,
  );

  /// A copy that has just been exported at [atUtcMs].
  ///
  /// The count resets to zero because §13's line reads "entries since", and
  /// the answer immediately after an export is none.
  BackupScreenState exportedAt(int atUtcMs) => BackupScreenState(
    nowUtcMs: nowUtcMs,
    entryCount: entryCount,
    entriesSinceBackup: 0,
    onDiskKilobytes: onDiskKilobytes,
    safetyCopies: safetyCopies,
    lastBackupAtUtcMs: atUtcMs,
    migrationFailed: migrationFailed,
    calendar: calendar,
    numerals: numerals,
  );
}

/// What the screen's buttons do.
///
/// An interface, and every method is a no-op in the default implementation
/// below. §13's actions reach the OS share sheet, the OS document picker and a
/// destructive dialog, none of which exists in a widget test — and a port that
/// THREW would be a screen that crashes the moment somebody taps a row, while
/// every test passes against a fake. EPIC-13 and EPIC-14 each shipped one of
/// those.
abstract class BackupActions {
  /// Writes a backup and hands it to the OS. Returns the hand-off instant.
  Future<int?> backUpNow();

  /// Opens the fill-ups CSV flow.
  Future<void> exportFillUpsCsv();

  /// Opens the all-costs CSV flow.
  Future<void> exportCostsCsv();

  /// Opens the service-history PDF flow.
  Future<void> exportServiceHistoryPdf();

  /// Opens the OS document picker. A cancelled picker changes nothing.
  Future<void> pickFileToRestore();

  /// Restores the safety copy of [kind].
  Future<void> undo(SafetyCopyKind kind);

  /// Writes the wipe safety copy, then opens the typed-confirm dialog.
  ///
  /// The copy is written BEFORE the dialog opens, not after confirmation: a
  /// copy written after the user says yes is a copy that does not exist at the
  /// moment they change their mind about having said it.
  Future<void> beginDeleteAll();
}

/// Nothing wired in.
///
/// Named rather than left as a throwing port, so the gap is visible in a code
/// search instead of on a user's phone.
class NoBackupActions implements BackupActions {
  /// Creates the no-op actions.
  const NoBackupActions();

  @override
  Future<int?> backUpNow() async => null;

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

/// The actions the screen calls.
final Provider<BackupActions> backupActionsProvider = Provider<BackupActions>(
  (ref) => const NoBackupActions(),
);

/// The screen's state before anything has loaded.
///
/// Overridden by the composition root and by every test. A provider that threw
/// here would be a screen that cannot be pumped.
final Provider<BackupScreenState> backupInitialStateProvider =
    Provider<BackupScreenState>(
      (ref) => const BackupScreenState(
        nowUtcMs: 0,
        entryCount: 0,
        entriesSinceBackup: 0,
        onDiskKilobytes: 0,
        safetyCopies: [],
      ),
    );

/// The screen's notifier.
class BackupNotifier extends Notifier<BackupScreenState> {
  @override
  BackupScreenState build() => ref.watch(backupInitialStateProvider);

  /// Runs the export, showing the inline progress state while it does.
  Future<void> backUpNow() async {
    if (state.isExporting) return;
    state = state.exporting(value: true);
    final at = await ref.read(backupActionsProvider).backUpNow();
    // Stamped on the HAND-OFF and not on a confirmed save: the OS never tells
    // us what the user did with the file.
    state = at == null ? state.exporting(value: false) : state.exportedAt(at);
  }

  /// Opens the fill-ups CSV flow.
  Future<void> exportFillUpsCsv() =>
      ref.read(backupActionsProvider).exportFillUpsCsv();

  /// Opens the all-costs CSV flow.
  Future<void> exportCostsCsv() =>
      ref.read(backupActionsProvider).exportCostsCsv();

  /// Opens the service-history PDF flow.
  Future<void> exportServiceHistoryPdf() =>
      ref.read(backupActionsProvider).exportServiceHistoryPdf();

  /// Opens the OS document picker.
  Future<void> pickFileToRestore() =>
      ref.read(backupActionsProvider).pickFileToRestore();

  /// Restores a safety copy.
  Future<void> undo(SafetyCopyKind kind) =>
      ref.read(backupActionsProvider).undo(kind);

  /// Starts the delete-all flow.
  Future<void> beginDeleteAll() =>
      ref.read(backupActionsProvider).beginDeleteAll();
}

/// The screen's state.
final NotifierProvider<BackupNotifier, BackupScreenState> backupScreenProvider =
    NotifierProvider<BackupNotifier, BackupScreenState>(
      BackupNotifier.new,
    );
