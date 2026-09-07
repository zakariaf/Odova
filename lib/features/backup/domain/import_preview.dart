// What §6 §4.3's preview shows, decided before a widget exists.
//
// "Pick file → read and validate → preview → confirm → write. The preview is
// mandatory, cannot be skipped, and reaching it has changed nothing on the
// device."
//
// The three variants are one model over a sealed type rather than three
// screens, because they differ in two sentences and one button and share
// everything else — and three screens is three places for the replacement
// sentence to be softened independently.
import 'package:meta/meta.dart';

/// One row of §4.3's NOW → AFTER comparison.
@immutable
class ImportCountRow {
  /// Creates a row.
  const ImportCountRow({
    required this.kind,
    required this.now,
    required this.after,
  });

  /// Which record type, as a message key the presentation edge resolves.
  final String kind;

  /// How many the phone holds.
  final int now;

  /// How many it will hold.
  final int after;

  /// Whether this row LOSES records.
  ///
  /// Drawn amber. §4.3 shows the whole comparison, and a row that goes down is
  /// the one fact a user must not scroll past — losing 24 fill-ups must not
  /// look like the three rows above it that gained.
  bool get loses => after < now;
}

/// Which of §4.3's three previews this is.
sealed class PreviewVariant {
  const PreviewVariant();
}

/// The ordinary case: the phone has data and the file will replace it.
final class ReplaceVariant extends PreviewVariant {
  /// Creates the variant.
  const ReplaceVariant();
}

/// §4.3's empty device.
///
/// "Odova is empty, so nothing will be replaced." and the button becomes
/// **Import**. The replacement sentence is TRUE on an empty phone and would be
/// frightening for no reason.
final class EmptyDeviceVariant extends PreviewVariant {
  /// Creates the variant.
  const EmptyDeviceVariant();
}

/// §4.3's already-restored case.
///
/// The `content_hash` matches the last successful import and nothing has been
/// written since. It is the commonest recovery panic — the user is not sure
/// the first one worked — and telling them "nothing will change" is both true
/// and the answer to the question they are actually asking.
final class AlreadyRestoredVariant extends PreviewVariant {
  /// Creates the variant.
  const AlreadyRestoredVariant();
}

/// §4.4's *Undo last import*, which uses the same screen.
///
/// The header names the moment rather than a filename, because the user is
/// looking for a time and not a file: "The data you had before 2 September
/// 2026, 14:12".
final class UndoVariant extends PreviewVariant {
  /// Creates the variant.
  const UndoVariant(this.takenAtUtcMs);

  /// When the copy was written.
  final int takenAtUtcMs;
}

/// Chooses §4.3's variant.
///
/// [lastImportedHash] and [writesSinceLastImport] are what make the
/// already-restored case honest: a matching hash alone is not enough, because
/// a user who restored yesterday and logged four fill-ups today would be told
/// nothing will change while four entries are about to disappear.
PreviewVariant resolvePreviewVariant({
  required int recordsOnDevice,
  required String? fileHash,
  required String? lastImportedHash,
  required int writesSinceLastImport,
  bool isUndo = false,
  int? undoTakenAtUtcMs,
}) {
  if (isUndo && undoTakenAtUtcMs != null) {
    return UndoVariant(undoTakenAtUtcMs);
  }
  if (recordsOnDevice == 0) return const EmptyDeviceVariant();
  if (fileHash != null &&
      fileHash == lastImportedHash &&
      writesSinceLastImport == 0) {
    return const AlreadyRestoredVariant();
  }
  return const ReplaceVariant();
}

/// The comparison, built from two count maps.
///
/// Every record type appears, including the ones that do not change. §4.3 asks
/// for "every record type and the total", and a table that hid the unchanged
/// rows would make a user count the ones that are missing.
List<ImportCountRow> buildComparison({
  required Map<String, int> now,
  required Map<String, int> after,
  required List<String> kinds,
}) => [
  for (final kind in kinds)
    ImportCountRow(kind: kind, now: now[kind] ?? 0, after: after[kind] ?? 0),
];
