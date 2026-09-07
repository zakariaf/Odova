// The three files SPEC.md §6 §4.4 keeps, and the rules that keep them apart.
//
// One copy per destructive operation KIND, three at most, each overwritten only
// by the next operation of the same kind. That is the whole reason there are
// three filenames rather than one `odova-safety-<timestamp>.json`: an import
// must never eat the copy a wipe left, and the user who needs the wipe's copy
// is by definition somebody who has already made one mistake today.
//
// They live in app-private storage, so uninstalling deletes them. Settings says
// so, once, next to the button — a seatbelt, not a vault. The user's own
// exported file remains the real backup.
import 'dart:io';

/// Which destructive operation a safety copy belongs to.
enum SafetyCopyKind {
  /// Written before a schema migration, by the numbered reader for the version
  /// ALREADY on disk. Named by that version rather than by a timestamp, so a
  /// user who has updated four times has one file and not four.
  migration('odova-safety-migration'),

  /// Written before an import replaces everything.
  restore('odova-safety-import'),

  /// Written before *Delete all data*.
  wipe('odova-safety-wipe');

  const SafetyCopyKind(this.prefix);

  /// The filename stem, without the discriminator or the extension.
  final String prefix;
}

/// How long a copy is offered before its row disappears.
///
/// §4.4: *Undo last import* is live for 30 days. The ROW disappears rather than
/// greying out — a disabled control with no explanation is a worse answer than
/// no control, and a user who sees "Undo" greyed out will tap it.
const Duration kSafetyCopyLifetime = Duration(days: 30);

/// One copy on disk, with what the UI needs to describe it.
class SafetyCopy {
  /// Creates a description of one copy.
  const SafetyCopy({
    required this.kind,
    required this.file,
    required this.writtenAtUtcMs,
    required this.vehicles,
    required this.records,
    required this.contentHash,
  });

  /// Which operation wrote it.
  final SafetyCopyKind kind;

  /// Where it is.
  final File file;

  /// When it was written, from the FILENAME rather than the filesystem: a
  /// restore, a device migration or a backup tool can rewrite an mtime, and
  /// the name is the app's own record.
  final int writtenAtUtcMs;

  /// How many vehicles it holds — "2 vehicles, 431 records".
  final int vehicles;

  /// How many records it holds.
  final int records;

  /// The `content_hash` of the document, for §4.4's suppression rule.
  final String? contentHash;

  /// Whether [nowUtcMs] is past this copy's thirty days.
  bool isExpired(int nowUtcMs) =>
      nowUtcMs - writtenAtUtcMs > kSafetyCopyLifetime.inMilliseconds;
}

/// The filename §4.4 gives a copy of [kind].
///
/// The migration copy is discriminated by SCHEMA VERSION and the other two by
/// timestamp, exactly as the spec writes it: a second migration from the same
/// starting version overwrites its own copy, while a second import is a
/// different moment the user may want back.
String safetyCopyName(
  SafetyCopyKind kind, {
  int? schemaVersion,
  int? atUtcMs,
}) => switch (kind) {
  SafetyCopyKind.migration => '${kind.prefix}-$schemaVersion.json',
  _ => '${kind.prefix}-${_stamp(atUtcMs!)}.json',
};

/// `YYYYMMDD-HHmm` in UTC, ASCII.
///
/// UTC and not local: the name is bookkeeping the app reads back, and a user
/// who crosses a timezone must not end up with two copies whose names sort
/// wrongly against each other.
String _stamp(int utcMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}';
}

/// The instant encoded in [name], or null if it carries none.
int? safetyCopyInstant(String name) {
  final match = RegExp(
    r'-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})\.json$',
  ).firstMatch(name);
  if (match == null) return null;
  return DateTime.utc(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  ).millisecondsSinceEpoch;
}
