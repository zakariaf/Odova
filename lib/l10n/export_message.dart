// What §13's three export errors say, and what each one offers.
//
// Beside `import_message.dart` and `persist_failure_message.dart`, and in
// `lib/l10n/` for the same reason: two features will render these — the backup
// screen and, when the CSV rows are wired, the same screen's other three rows
// — and `structure_test` refuses one feature importing another.
//
// The three strings landed in task 15.6 and nothing rendered them until the
// review pass over this epic: `backUpNow` returned `int?`, so "the user
// dismissed the share sheet" and "the disk is full" were the same answer and
// the spinner just stopped.
import 'package:odova/features/backup/domain/backup_export_service.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// What the user is told when an export did not finish.
///
/// [size] is a pre-formatted figure — "about 6 MB" — because §13's first
/// message names one and this function has no numbering system of its own.
String exportFailureMessage(
  AppLocalizations l10n,
  ExportFailure failure, {
  required String size,
}) => switch (failure) {
  ExportNoSpace() => l10n.backupExportNoSpace(size),
  ExportWriteFailed() => l10n.backupExportWriteFailed,
  ExportShareRefused() => l10n.backupExportNoShare,
};

/// Whether §13 offers a retry for [failure].
///
/// Only the write failure. "Free up some space and try again" and "try again
/// after restarting your phone" both ask the user to change something first,
/// and a Try again button beside them would be an invitation to fail twice.
bool exportFailureRetries(ExportFailure failure) =>
    failure is ExportWriteFailed;
