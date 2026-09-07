// Whether to nudge about a backup — SPEC.md §6 §6, the predicate only.
//
// EPIC-16 owns the scheduling: its slot builder places `backup.nudge` in
// the priority order `overdue2 > overdue1 > due > nudge > early` under the
// two-a-week cap, and its router synthesises the stack
// `[home, settings, settings.backup]` so Back walks out through Settings.
// What lives here is the question "should there be one at all", because that
// question is about the user's data and not
// about the notification system.
//
// Two conditions, and both of them exist to stop the app nagging somebody who
// has nothing to lose. At most one every ninety days, and only with twenty or
// more new records since the last export. Never exported and fewer than twenty
// records is SILENCE — a first-week user with three fill-ups does not need to
// be told to back them up.
import 'package:meta/meta.dart';

/// How long between nudges. §6 §6.
const Duration kBackupNudgeInterval = Duration(days: 90);

/// How many new records make a backup worth asking about.
const int kBackupNudgeRecordFloor = 20;

/// Everything the predicate reads.
@immutable
class BackupNudgeState {
  /// Creates the state.
  const BackupNudgeState({
    required this.nowUtcMs,
    required this.recordsSinceLastExport,
    this.lastExportUtcMs,
    this.lastNudgeUtcMs,
  });

  /// Now.
  final int nowUtcMs;

  /// How many records have been written since the last export — or in total,
  /// when there has never been one.
  final int recordsSinceLastExport;

  /// When the user last exported, or null.
  final int? lastExportUtcMs;

  /// When the app last nudged, or null. Device-local bookkeeping: §6 §7 keeps
  /// it out of the file, so a restored phone starts its ninety days fresh.
  final int? lastNudgeUtcMs;
}

/// Whether to schedule a backup nudge now.
bool shouldNudgeAboutBackup(BackupNudgeState state) {
  // Below the floor there is nothing worth the interruption, whether or not
  // the user has ever exported. This is the clause that keeps the app quiet
  // for somebody in their first week.
  if (state.recordsSinceLastExport < kBackupNudgeRecordFloor) return false;

  final lastNudge = state.lastNudgeUtcMs;
  if (lastNudge != null &&
      state.nowUtcMs - lastNudge < kBackupNudgeInterval.inMilliseconds) {
    return false;
  }

  final lastExport = state.lastExportUtcMs;
  // Never exported, and past the floor: that is exactly the person the nudge
  // is for.
  if (lastExport == null) return true;

  return state.nowUtcMs - lastExport >= kBackupNudgeInterval.inMilliseconds;
}

/// Whether Settings should draw the last-backup line in amber.
///
/// The quiet channel, and the one that does the work. §6 §6 gives it the same
/// ninety days as the notification but NO record floor: the line is already on
/// the screen, so showing it in amber costs the user nothing, where a
/// notification they did not need costs them their patience.
bool backupLineIsStale({required int nowUtcMs, int? lastExportUtcMs}) =>
    lastExportUtcMs == null ||
    nowUtcMs - lastExportUtcMs >= kBackupNudgeInterval.inMilliseconds;
