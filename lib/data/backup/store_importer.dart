// SPEC.md §6 §4.1's transactional write: stage, verify, close, rename.
//
// A process kill at ANY instant leaves either the old data or the new data,
// never a mixture. That is the whole contract, and it is why the publish is a
// rename rather than one big transaction: a rename is atomic on every
// filesystem this app ships to and does not depend on the storage engine's
// crash behaviour under a multi-megabyte commit.
//
// Nothing here is destructive until the rename. The staging database is a new
// file beside the live one; the live one is not opened for writing, not
// truncated, and not deleted. Every failure path therefore leaves the live
// database byte-identical, which `store_importer_test` asserts by injecting a
// failure at each stage in turn and comparing bytes.
//
// It takes a `StoreSnapshot` rather than an `ImportPlan`: `ImportPlan` lives in
// the backup FEATURE, and `lib/data` importing a feature would invert the
// layering. The feature calls this with `plan.store`, and maps the failure
// below onto the user-facing one.
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/repositories/store_writer.dart';

/// The stages of §4.1's pipeline, in order.
///
/// Named so a test can inject a failure at each one and so the progress
/// indicator has something to report. `publish` is the only stage past which a
/// failure can leave anything changed.
enum ImportStage {
  /// The safety copy of what is about to be replaced.
  safetyCopy,

  /// Building the new database beside the old one.
  staging,

  /// Counting what was written against what was planned.
  verify,

  /// Closing every handle, so the rename has nothing open under it.
  closing,

  /// The single atomic rename.
  publish,
}

/// Why a store could not be replaced.
@immutable
sealed class ImportWriteFailure extends Failure with ValueEquality {
  const ImportWriteFailure();
}

/// The device does not have room for the staging copy.
///
/// Checked BEFORE staging, because discovering it halfway leaves a
/// part-written file to clean up and tells the user nothing they can act on.
final class NotEnoughSpace extends ImportWriteFailure {
  /// Creates the failure.
  const NotEnoughSpace({required this.neededBytes, required this.freeBytes});

  /// Roughly what the import needs.
  final int neededBytes;

  /// What the device has.
  final int freeBytes;

  @override
  String get code => 'not_enough_space';

  @override
  List<Object?> get props => [neededBytes, freeBytes];
}

/// The staging database could not be built.
final class StagingFailed extends ImportWriteFailure {
  /// Creates the failure.
  const StagingFailed(this.detail);

  /// What went wrong. Diagnostics only, never shown.
  final String detail;

  @override
  String get code => 'staging_failed';

  @override
  List<Object?> get props => [detail];
}

/// What was written does not match what was planned.
///
/// The one check between building the new database and publishing it. A
/// mismatch here means the writer and the plan disagree, and publishing anyway
/// would replace the user's data with a store nobody has counted.
final class CountMismatch extends ImportWriteFailure {
  /// Creates the failure.
  const CountMismatch({required this.expected, required this.written});

  /// What the plan said.
  final int expected;

  /// What the staging database holds.
  final int written;

  @override
  String get code => 'count_mismatch';

  @override
  List<Object?> get props => [expected, written];
}

/// The rename failed.
///
/// The one failure that can leave the app without a live database, so the
/// caller must reopen before showing anything.
final class PublishFailed extends ImportWriteFailure {
  /// Creates the failure.
  const PublishFailed(this.detail);

  /// What the filesystem said.
  final String detail;

  @override
  String get code => 'publish_failed';

  @override
  List<Object?> get props => [detail];
}

/// The user cancelled before the swap.
final class ImportCancelled extends ImportWriteFailure {
  /// Creates the failure.
  const ImportCancelled();

  @override
  String get code => 'import_cancelled';

  @override
  List<Object?> get props => const [];
}

/// What an import actually did.
@immutable
class RestoreReport with ValueEquality {
  /// Creates a report.
  const RestoreReport({
    required this.vehicles,
    required this.records,
    required this.safetyCopyPath,
  });

  /// How many vehicles are now on the phone.
  final int vehicles;

  /// How many records are now on the phone.
  final int records;

  @override
  List<Object?> get props => [vehicles, records, safetyCopyPath];

  /// Where the copy of what was replaced is, for *Undo last import*.
  ///
  /// A PATH and not a `File`. A report is a value that gets compared, logged
  /// and held; a `File` is a live handle with identity equality, so two reports
  /// naming the same copy would not be equal.
  final String? safetyCopyPath;
}

/// Something the user can cancel.
///
/// A flag rather than a `Future`, because the check happens between stages and
/// a cancelled import must leave the device exactly as it was — which means
/// cancelling has to be observed at a point where nothing is half-written, not
/// wherever an await happens to be.
class ImportCancellation {
  /// Whether the user has asked to stop.
  bool isCancelled = false;

  /// Asks to stop at the next stage boundary.
  void cancel() => isCancelled = true;
}

/// Replaces the live store with [store], atomically.
///
/// [liveFile] is the database in use. [openStaging] builds a database against a
/// file this function chooses; [closeLive] must close every handle on
/// [liveFile] and [reopenLive] must open it again afterwards — both injected,
/// because the live connection is owned by a provider and this function must
/// not reach into one.
///
/// [writeSafetyCopy] runs FIRST and its result is carried into the report.
/// §6 §4.4: any operation that destroys data writes its file first. No
/// exceptions — and returning null from it is a decision the caller makes, not
/// one this function makes for them.
Future<Result<RestoreReport, ImportWriteFailure>> importStore({
  required File liveFile,
  required StoreSnapshot store,
  required int expectedRecords,
  required Future<AppDatabase> Function(File staging) openStaging,
  required Future<void> Function() closeLive,
  required Future<void> Function() reopenLive,
  required Future<File?> Function() writeSafetyCopy,
  Future<int> Function()? freeBytes,
  ImportCancellation? cancellation,
  void Function(ImportStage stage)? onStage,
}) async {
  bool cancelled() => cancellation?.isCancelled ?? false;

  // Roughly twice the live file, because the staging copy exists beside it for
  // the length of the import. Approximate on purpose: the exact figure is not
  // knowable before the write, and a user told "free up about 40 MB" can act
  // on it where "not enough space" leaves them guessing.
  if (freeBytes != null) {
    final needed = liveFile.existsSync() ? liveFile.lengthSync() * 2 : 0;
    final free = await freeBytes();
    if (free < needed) {
      return Err(NotEnoughSpace(neededBytes: needed, freeBytes: free));
    }
  }

  // A leftover from a previous attempt that died before its own cleanup.
  // Removed rather than reused: a half-written staging file with the right
  // name is the one thing that could turn a rename into corruption.
  final staging = File('${liveFile.path}.importing');
  _removeStaging(staging);

  var published = false;
  try {
    onStage?.call(ImportStage.safetyCopy);
    final safetyCopy = await writeSafetyCopy();
    if (cancelled()) return const Err(ImportCancelled());

    onStage?.call(ImportStage.staging);
    AppDatabase? database;
    final int written;
    try {
      database = await openStaging(staging);
      await writeStoreSnapshot(database, store);

      onStage?.call(ImportStage.verify);
      written = await _countRecords(database);
    } finally {
      // Always, on every path. A staging database left open holds a WAL that
      // the rename would carry over as a file nothing owns.
      await database?.close();
    }

    if (written != expectedRecords) {
      return Err(CountMismatch(expected: expectedRecords, written: written));
    }
    if (cancelled()) return const Err(ImportCancelled());

    onStage?.call(ImportStage.closing);
    await closeLive();

    onStage?.call(ImportStage.publish);
    try {
      // The staging database's own WAL and shm are removed rather than
      // renamed alongside: `close` checkpointed them into the main file, and a
      // stale WAL beside a renamed database is a file SQLite would try to
      // replay against data it does not describe. The LIVE pair goes too, for
      // the same reason from the other direction.
      for (final suffix in ['-wal', '-shm']) {
        _deleteIfPresent(File('${staging.path}$suffix'));
        _deleteIfPresent(File('${liveFile.path}$suffix'));
      }
      // THE publish. One rename, after every handle is closed.
      staging.renameSync(liveFile.path);
      published = true;
    } on FileSystemException catch (error) {
      await reopenLive();
      return Err(PublishFailed(error.message));
    }

    await reopenLive();
    return Ok(
      RestoreReport(
        vehicles: store.vehicles.length,
        records: expectedRecords,
        safetyCopyPath: safetyCopy?.path,
      ),
    );
  } on Object catch (error) {
    // NOTHING escapes as a throw. §14 names the crash loop as the worst
    // possible outcome, and an import is exactly where a user cannot afford
    // one: the app they are trying to get their data back into is the app
    // that has just died. The first version of this let a throw from any
    // stage past `staging` straight out, which the byte-comparison test
    // caught by never reaching its assertion.
    return Err(StagingFailed('$error'));
  } finally {
    // Whatever happened, the staging file does not outlive the attempt —
    // unless it BECAME the live database, in which case it no longer exists
    // under that name.
    if (!published) _removeStaging(staging);
  }
}

void _deleteIfPresent(File file) {
  if (file.existsSync()) file.deleteSync();
}

void _removeStaging(File staging) {
  for (final path in [
    staging.path,
    '${staging.path}-wal',
    '${staging.path}-shm',
  ]) {
    _deleteIfPresent(File(path));
  }
}

/// How many records the staging database holds.
///
/// Counted from the DATABASE and not from the snapshot that filled it: the
/// point of the check is to catch a writer that dropped a row, and counting
/// the input would agree with itself whatever happened.
Future<int> _countRecords(AppDatabase db) async {
  var total = 0;
  for (final table in const [
    'vehicles',
    'service_items',
    'odometer_readings',
    'odometer_corrections',
    'fill_ups',
    'service_records',
    'expenses',
    'trips',
  ]) {
    final row = await db
        .customSelect('SELECT COUNT(*) AS n FROM $table;')
        .getSingle();
    total += row.read<int>('n');
  }
  return total;
}
