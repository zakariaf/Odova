// Every import failure, warning and skipped entry, in the user's language.
//
// In `lib/l10n/` beside `persist_failure_message.dart` and for the same reason:
// `settings.import` will render these and `settings.backup` will render the
// success line, and `structure_test.dart` refuses one feature importing
// another. It also keeps the switches where the ARB keys are, so a new failure
// variant is a compile error next to the file that has to name it.
//
// The domain carries CODES and typed parameters and never a sentence. SPEC.md
// §2 ships six languages of which three are right-to-left, and a message baked
// into a failure is a message that cannot be translated, mirrored or
// digit-shaped. Every number here arrives pre-shaped as text for the same
// reason: a bare `int` renders Latin digits in four of the six.
import 'package:odova/features/backup/domain/import_failure.dart';
import 'package:odova/features/backup/domain/import_warning.dart';
import 'package:odova/features/backup/domain/mapping/record_restore.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// What the refusal says — SPEC.md §6 §5.2.
///
/// [size] is a pre-formatted file size and [readable] / [total] are pre-shaped
/// record counts, because this function has no numbering system and no
/// locale-aware formatter of its own.
String importFailureMessage(
  AppLocalizations l10n,
  ImportFailure failure, {
  required String size,
  required String readable,
  required String total,
}) => switch (failure) {
  FileTooLarge() => l10n.importFailTooLarge(size),
  CompressedFile() => l10n.importFailCompressed,
  NotUtf8() => l10n.importFailNotUtf8,
  Truncated() => l10n.importFailTruncated,
  // A PDF and a top-level array take the same sentence: the user picked the
  // wrong file, and no wording about types would help them.
  NotValidJson() || NotOdova() => l10n.importFailNotOdova,
  NotMadeByOdova() => l10n.importFailNotMadeByOdova,
  TooNew() => l10n.importFailTooNew,
  CorruptVersion() => l10n.importFailDamagedVersion,
  // A malformed array and a document nested past the cap are the same
  // situation for the user — the file is not shaped like a backup — so they
  // are the same sentence.
  MalformedArray() || TooDeep() => l10n.importFailDamagedFile,
  TooDamaged() => l10n.importFailTooDamaged(readable, total),
  CannotOpenFile() => l10n.importFailCannotOpen,
};

/// What one warning says.
///
/// [countText] is the warning's own count, pre-shaped; [declared] and [found]
/// are the record-count pair, and [year] is rung 10's floor.
String importWarningMessage(
  AppLocalizations l10n,
  ImportWarning warning, {
  required String countText,
  required String declared,
  required String found,
  required String year,
}) => switch (warning) {
  ContentHashMismatch() => l10n.importWarnContentHash,
  RecordCountMismatch() => l10n.importWarnRecordCount(declared, found),
  MissingArray() => l10n.importWarnMissingArray,
  SkippedRecords() => l10n.importWarnSkipped(warning.count, countText),
  CoercedEnums() => l10n.importWarnCoercedEnums(warning.count, countText),
  OutOfRangeDates() => l10n.importWarnOutOfRangeDates(
    warning.count,
    countText,
    year,
  ),
  OrphanRecords() => l10n.importWarnOrphans(warning.count, countText),
  UnresolvedLinks() => l10n.importWarnUnresolvedLinks(warning.count, countText),
  UnmatchedCorrections() => l10n.importWarnUnmatchedCorrections(
    warning.count,
    countText,
  ),
  DuplicateIds() => l10n.importWarnDuplicateIds(warning.count, countText),
  DroppedRules() => l10n.importWarnDroppedRules(warning.count, countText),
  TruncatedStrings() => l10n.importWarnTruncatedStrings(
    warning.count,
    countText,
  ),
};

/// One line of the skipped-entry list — "Fill-up, 14 August 2026 — the amount
/// of fuel was missing".
///
/// [date] is already formatted in the user's calendar and numbering system, and
/// is null when the date was the thing that was missing. No identifier appears:
/// a ULID tells the user nothing and makes the list look like a crash report.
String skippedEntryLine(
  AppLocalizations l10n,
  SkippedEntry entry, {
  String? date,
}) {
  final type = _typeWord(l10n, entry.array);
  final reason = _reasonPhrase(l10n, entry.reason);
  return date == null
      ? l10n.importSkipEntryNoDate(type, reason)
      : l10n.importSkipEntry(type, date, reason);
}

String _typeWord(AppLocalizations l10n, String array) => switch (array) {
  'vehicles' => l10n.importTypeVehicle,
  'reminders' => l10n.importTypeReminder,
  'odometer_readings' => l10n.importTypeReading,
  'odometer_corrections' => l10n.importTypeCorrection,
  'fillups' => l10n.importTypeFillup,
  'services' => l10n.importTypeService,
  'expenses' => l10n.importTypeExpense,
  'trips' => l10n.importTypeTrip,
  // Not reachable — `import_message_completeness_test` asserts every entry of
  // `kBackupArrays` is named above. It returns the raw name rather than a real
  // label, because a wrong type word in a skipped-entry list is a user
  // hunting for a record they never lost.
  _ => array,
};

String _reasonPhrase(AppLocalizations l10n, String reason) => switch (reason) {
  SkipReason.date => l10n.importSkipDate,
  SkipReason.fuel => l10n.importSkipFuel,
  SkipReason.money => l10n.importSkipMoney,
  SkipReason.currency => l10n.importSkipCurrency,
  SkipReason.correction => l10n.importSkipCorrection,
  // `incomplete` and anything a future rung adds. This one CAN fall through
  // honestly: the six reasons are a closed vocabulary the restorers choose
  // from, and "part of it was missing" is true of any of them.
  _ => l10n.importSkipIncomplete,
};
