// Handing a backup to the OS — SPEC.md §6 §6.
//
// Four promises, and three of them are about what the app does NOT do: it
// chooses no destination, requests no storage permission, remembers nothing
// about where the file went, and exports nothing automatically, on a schedule,
// or in the background. Every file leaving this app is a thing the user tapped.
//
// It streams to a temp file and hands over the PATH rather than the bytes.
// `ShareService.shareFile` takes a `Uint8List`, and a 12,000-record backup
// assembled in memory is tens of megabytes of it on a phone that is already
// low — arriving at the exact moment the user is trying to rescue their data.
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:odova/app/share/share_service.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';
import 'package:odova/features/backup/domain/backup_writer.dart';
import 'package:odova/features/backup/domain/export_filename.dart';

/// The mime type a `.json` backup is offered as.
///
/// `application/json` and not `text/plain`: it is what the file is. Providers
/// routinely hand it BACK as `application/octet-stream`, which is why import
/// identifies by the `format` key and never by mime type — but that is the
/// receiving side's problem, and lying on the way out would not help it.
const String kBackupMimeType = 'application/json';

/// Why an export did not finish.
@immutable
sealed class ExportFailure extends Failure with ValueEquality {
  const ExportFailure();
}

/// The file could not be written. Usually a full disk.
final class ExportWriteFailed extends ExportFailure {
  /// Creates the failure.
  const ExportWriteFailed(this.detail);

  /// What the filesystem said. Diagnostics only.
  final String detail;

  @override
  String get code => 'export_write';

  @override
  List<Object?> get props => [detail];
}

/// There is no room for the file.
final class ExportNoSpace extends ExportFailure {
  /// Creates the failure.
  const ExportNoSpace({required this.neededBytes});

  /// Roughly what it needs, so the message can name a figure. "Free up about
  /// 40 MB" is advice; "not enough space" is not.
  final int neededBytes;

  @override
  String get code => 'export_no_space';

  @override
  List<Object?> get props => [neededBytes];
}

/// The OS would not take the file.
final class ExportShareRefused extends ExportFailure {
  /// Creates the failure.
  const ExportShareRefused(this.detail);

  /// What the platform said.
  final String detail;

  @override
  String get code => 'export_share_refused';

  @override
  List<Object?> get props => [detail];
}

/// Writes a backup and offers it to the OS.
class BackupExportService {
  /// Creates the service.
  ///
  /// [temporaryDirectory] is the app's OWN temp directory — not a destination
  /// the app chose for the user, and not one it will remember.
  const BackupExportService({
    required this.share,
    required this.temporaryDirectory,
    required this.writer,
    this.freeBytes,
  });

  /// The hand-off port.
  final ShareService share;

  /// Where the temp file goes.
  final Future<Directory> Function() temporaryDirectory;

  /// The writer, already carrying the instant and the app version.
  final BackupWriter writer;

  /// How much room the device has, if the caller can find out.
  final Future<int> Function()? freeBytes;

  /// Writes [store] and hands the file over.
  ///
  /// Returns the moment the OS took it — which is the ONLY moment this app can
  /// observe. §6 §6: the app does not know what the user did with the file,
  /// so `last_backup_at` is stamped on the hand-off and never on a confirmed
  /// save. Pretending otherwise would mean a Settings line that stays amber
  /// forever on a phone whose user backs up every week.
  Future<Result<int, ExportFailure>> export(
    StoreSnapshot store, {
    required DateTime localNow,
  }) async {
    final name = backupFileName(localNow);

    final Directory directory;
    final File file;
    try {
      directory = await temporaryDirectory();
      final taken = directory
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toSet();
      // Odova owns this directory, so Odova handles the collision. Where the
      // OS owns the destination the OS handles it, and second-guessing
      // produces `file-2 (1).json`.
      file = File('${directory.path}/${withoutCollision(name, taken)}');
    } on FileSystemException catch (error) {
      return Err(ExportWriteFailed(error.message));
    }

    if (freeBytes != null) {
      // A rough figure, and rough on purpose: the exact size is not knowable
      // before the write, and one kilobyte per record with a floor is enough
      // to refuse the case that actually happens — a phone with nothing left.
      final needed = 1024 * (store.vehicles.length + _records(store)) + 65536;
      if (await freeBytes!() < needed) {
        return Err(ExportNoSpace(neededBytes: needed));
      }
    }

    // Written under `.writing` and RENAMED. A failed write then publishes
    // nothing by construction rather than by remembering to clean up: the
    // name the user will see is only ever created by a rename, which happens
    // after the last byte is flushed and the hash is stamped.
    //
    // The alternative — write to the real name and delete on failure — leaves
    // a half-written backup under the right name for as long as it takes the
    // catch block to run, and leaves one for ever if the delete also fails on
    // the full disk that caused the problem. A user who keeps that file
    // believes they have a backup.
    final pending = File('${file.path}.writing');
    try {
      await writer.writeToFile(pending, store);
      pending.renameSync(file.path);
    } on Object catch (error) {
      try {
        if (pending.existsSync()) pending.deleteSync();
      } on FileSystemException {
        // A leftover `.writing` file is cleared by `deleteLeftoverExports` on
        // the next launch. Failing the caller a second time over the cleanup
        // of a failure would replace one honest message with a confusing one.
      }
      return Err(ExportWriteFailed('$error'));
    }

    final offered = await share.shareWrittenFile(
      file: file,
      mimeType: kBackupMimeType,
    );

    return switch (offered) {
      Ok() => Ok(localNow.toUtc().millisecondsSinceEpoch),
      Err(:final failure) => Err(ExportShareRefused(failure.code)),
    };
  }
}

int _records(StoreSnapshot store) =>
    store.reminders.length +
    store.odometerReadings.length +
    store.odometerCorrections.length +
    store.fillUps.length +
    store.services.length +
    store.expenses.length +
    store.trips.length;

/// Deletes every temporary export left behind by a previous run.
///
/// §6 §6: temporary copies are deleted on the next launch. The OS share sheet
/// hands a path to another app and returns immediately, so the app cannot know
/// when the copy stopped being needed — the next cold start is the first moment
/// it is certainly safe.
///
/// Never throws. A leftover file is a nuisance; failing a launch over one is
/// the app not opening.
Future<int> deleteLeftoverExports(Directory directory) async {
  if (!directory.existsSync()) return 0;
  var deleted = 0;
  for (final entity in directory.listSync()) {
    final name = entity.uri.pathSegments.last;
    if (entity is! File || !name.startsWith('odova-')) continue;
    try {
      entity.deleteSync();
      deleted++;
    } on FileSystemException {
      // Left for the next launch.
    }
  }
  return deleted;
}
