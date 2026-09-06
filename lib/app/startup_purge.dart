// SPEC.md §3: "After the window, the row is PURGED. A settled database has
// `deleted_at IS NULL` on every row that exists: no bin, no tombstones,
// nothing deleted in the export."
//
// The word doing the work is SETTLED. Every soft-delete in this app is purged
// by the timer that expires its snackbar — and a timer dies with the process.
// Kill the app during those six seconds (a task-switcher swipe, an OOM, a
// crash) and the row survives: invisible to every query, present in the file,
// and there for the life of the install, because nothing else ever has a
// reason to look at it.
//
// This sweep is the only thing standing between that promise and a database
// that accumulates ghosts one interrupted delete at a time.
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/deletion.dart';

/// How far back the startup sweep reaches: one minute.
///
/// Not the snackbar's six seconds. A clock that moved backwards between two
/// launches — a timezone change, an NTP correction, a user setting the date —
/// would otherwise purge a row somebody is still looking at. A minute is far
/// shorter than any realistic gap between launches and far longer than any
/// snackbar, so the margin costs nothing and closes the case.
const int kStartupPurgeGraceMs = 60 * 1000;

/// Removes every row soft-deleted more than [kStartupPurgeGraceMs] ago.
///
/// Returns what it removed, per table, for the launch log. An empty map means
/// nothing was there — or that the sweep failed, which is deliberately the
/// same answer to the caller.
///
/// It NEVER throws. This is housekeeping over rows the user has already
/// deleted, and SPEC.md §2 rates losing history as the worst bug this app can
/// have: refusing to launch over a failed cleanup trades a real loss for an
/// imaginary one.
Future<Map<String, int>> sweepDeletedOnStartup(
  AppDatabase database, {
  required int nowUtcMs,
}) async {
  // Catching `Object` rather than a typed failure, which the rest of this
  // codebase does not do and would normally be a finding. `guardPersist`
  // classifies SQLite's own errors, and everything a broken launch can throw
  // goes straight past it: a closed database throws `StateError`, a corrupt
  // file throws from the isolate, a missing directory throws from the VFS.
  // The promise this function makes is not "handles the failures we listed",
  // it is "the app starts" — and the only way to keep that promise is to catch
  // everything.
  try {
    final purged = await purgeDeleted(
      database,
      nowUtcMs - kStartupPurgeGraceMs,
    );
    return switch (purged) {
      Ok(:final value) => value,
      Err() => const {},
    };
    // The comment above this block is the justification: the promise is "the
    // app starts", and only catching everything keeps it.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return const {};
  }
}
