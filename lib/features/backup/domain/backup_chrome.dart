// The seven states of SPEC.md §13's `settings.backup`, as one pure function.
//
// They differ in more than a sentence: two of them disable controls, one hides
// whole rows, one reorders the screen behind a red banner, and three change the
// colour of the same line. A screen that decided that inline would be a
// `build()` with seven branches in it and no way to test any of them without a
// widget harness — and the state that matters most, migration-failed, is the
// one nobody would remember to pump.
import 'package:meta/meta.dart';
import 'package:odova/features/backup/domain/backup_nudge.dart';
import 'package:odova/features/backup/domain/safety_copy_store.dart';

/// How the last-backup line reads.
enum BackupAge {
  /// No export has ever happened. Amber, with the count line always shown.
  never,

  /// Within ninety days. Neutral, and the count line is hidden below twenty
  /// new entries — a number nobody needs is a number in the way.
  recent,

  /// Over ninety days. Amber, the warning glyph, and the count line always
  /// shown.
  stale,
}

/// Everything §13's state table decides, decided once.
@immutable
class BackupChrome {
  /// Creates the chrome.
  const BackupChrome({
    required this.age,
    required this.showsEntryCount,
    required this.canBackUp,
    required this.showsOtherExports,
    required this.canRestore,
    required this.canDelete,
    required this.showsMigrationBanner,
    required this.undoRows,
  });

  /// How the date line reads.
  final BackupAge age;

  /// Whether "N entries since" is drawn.
  final bool showsEntryCount;

  /// Whether **Back up now** is enabled.
  ///
  /// False only when there is nothing to back up. It stays ENABLED after a
  /// failed migration, because getting the data out of the building is the
  /// entire reason the app opened on this screen.
  final bool canBackUp;

  /// Whether the CSV and PDF rows are drawn at all.
  ///
  /// Hidden rather than disabled on an empty store: a disabled row invites a
  /// tap and answers nothing, where an absent one asks no question.
  final bool showsOtherExports;

  /// Whether Restore is enabled.
  final bool canRestore;

  /// Whether Delete all data is enabled.
  final bool canDelete;

  /// Whether the red migration banner sits above everything.
  final bool showsMigrationBanner;

  /// One row per safety copy that exists, newest first.
  ///
  /// The COPIES, not their kinds. `_newestFirst` has already found the newest
  /// of each; handing the screen only the kind made it fold the same list
  /// again to get the timestamp back for the expiry line.
  ///
  /// A kind with no copy has NO ROW — absent, not greyed. A greyed control
  /// with no explanation is a worse answer than no control, and a user who
  /// sees "Undo" greyed out will tap it.
  final List<SafetyCopy> undoRows;
}

/// Resolves §13's table.
///
/// [entryCount] is every record on the phone; [entriesSinceBackup] is what has
/// been written since the last export — the same number the nudge reads.
BackupChrome resolveBackupChrome({
  required int nowUtcMs,
  required int entryCount,
  required int entriesSinceBackup,
  required int? lastBackupAtUtcMs,
  required List<SafetyCopy> safetyCopies,
  required bool migrationFailed,
}) {
  final empty = entryCount == 0;
  final age = lastBackupAtUtcMs == null
      ? BackupAge.never
      : backupLineIsStale(
          nowUtcMs: nowUtcMs,
          lastExportUtcMs: lastBackupAtUtcMs,
        )
      ? BackupAge.stale
      : BackupAge.recent;

  return BackupChrome(
    age: age,
    // Always shown when the news is bad, hidden below twenty when it is not.
    // §13: the count line exists to make "three months ago" concrete, and on a
    // recent backup there is nothing to make concrete.
    showsEntryCount:
        !empty &&
        (age != BackupAge.recent ||
            entriesSinceBackup >= kBackupNudgeRecordFloor),
    canBackUp: !empty,
    showsOtherExports: !empty,
    // Both disabled after a failed migration. The app is running on a schema
    // it does not fully understand; replacing or destroying the store from
    // there is how a bad update becomes a lost history.
    canRestore: !migrationFailed,
    canDelete: !migrationFailed,
    showsMigrationBanner: migrationFailed,
    undoRows: [
      for (final copy in _newestFirst(safetyCopies))
        if (!copy.isExpired(nowUtcMs) && copy.kind != SafetyCopyKind.migration)
          copy,
    ],
  );
}

/// The copies, newest first, one per kind.
///
/// One per kind because §6 §4.4 keeps exactly one file per destructive
/// operation; two rows for the same kind would mean the store had gone wrong,
/// and showing both would offer the user a choice between two things with the
/// same name.
List<SafetyCopy> _newestFirst(List<SafetyCopy> copies) {
  final byKind = <SafetyCopyKind, SafetyCopy>{};
  for (final copy in copies) {
    final current = byKind[copy.kind];
    if (current == null || copy.writtenAtUtcMs > current.writtenAtUtcMs) {
      byKind[copy.kind] = copy;
    }
  }
  return byKind.values.toList()
    ..sort((a, b) => b.writtenAtUtcMs.compareTo(a.writtenAtUtcMs));
}
