// The four naming rules from SPEC.md §6 §6, and the transliterator they need.
//
// ASCII lowercase, hyphens, no spaces, no translated app name, no vehicle names
// in the backup. Every one of those is there because a filename leaves the app:
// it passes through email, Windows, USB sticks and every cloud drive, it has to
// sort chronologically in a file list, and an RTL filename in an LTR file
// manager renders in ways nobody enjoys.
//
// The date is LOCAL time, not UTC. The user recognises "the evening I sold the
// car"; they do not recognise the same moment written in UTC, and the file list
// they are scrolling is the only index this app has.
import 'package:meta/meta.dart';
import 'package:odova/core/history/search_normalise.dart';
import 'package:odova/core/time/civil_date.dart';

/// `odova-backup-YYYY-MM-DD-HHmm.json`, from local time.
///
/// No vehicle name, deliberately, even on a one-car phone: a backup is the
/// whole store, and naming it after one vehicle would be a promise the file
/// does not keep.
String backupFileName(DateTime local) =>
    'odova-backup-${_date(local)}-${_two(local.hour)}${_two(local.minute)}'
    '.json';

/// `odova-<what>-<vehicle>-YYYY-MM-DD.<extension>`.
///
/// The vehicle slug is already transliterated — `vehicleFileSlug` does that,
/// and takes the list position it needs for the fallback.
String exportFileName({
  required String what,
  required String vehicleSlug,
  required DateTime local,
  required String extension,
}) => 'odova-$what-$vehicleSlug-${_date(local)}.$extension';

/// A vehicle name as `[a-z0-9-]`, or `vehicle-<n>` when nothing survives.
///
/// [position] is the vehicle's ONE-BASED place in the garage list, and the
/// fallback uses it because a name written only in Arabic or Persian script
/// transliterates to nothing at all. `vehicle-2` is a filename the user can
/// still match to the second car in their list; an empty slug is a filename
/// that collides with every other export.
String vehicleFileSlug(String name, {required int position}) {
  final folded = _foldToAscii(name.toLowerCase());
  final slug = folded
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'vehicle-$position' : slug;
}

/// A name with the accents Latin scripts add folded away.
///
/// `VW Käfer` → `vw kafer`. Built ON TOP of `searchLatinFolds`, which is public
/// precisely so a second table does not drift from it — the first version of
/// this was a forty-entry copy that had drifted from it already.
///
/// The extra entries are the ones a FILENAME needs and a search fold does not.
/// Two kinds:
///
/// The LIGATURES, where a filename wants both letters. `ß` folds to `s` for
/// search — because somebody typing `strasse` should find `Straße` — and to
/// `ss` here, because a filename is read rather than matched. The two answers
/// are both right for their own job, and having them in one table would mean
/// one of them was wrong.
///
/// The CENTRAL-EUROPEAN letters, which a search fold has no reason to carry
/// (nothing in this app searches Czech) but a `[a-z0-9-]` filename does: a
/// `Škoda Octavia` that slugged to `koda-octavia` would be a file the user
/// cannot find by name.
///
/// Not a general Unicode normaliser: the honest answer for a script with no
/// ASCII equivalent is the numbered fallback rather than a transliteration
/// nobody asked for.
const Map<String, String> _filenameFolds = {
  'æ': 'ae',
  'œ': 'oe',
  'ß': 'ss',
  'đ': 'd',
  'ð': 'd',
  'þ': 'th',
  'ł': 'l',
  'š': 's',
  'ž': 'z',
  'č': 'c',
  'ř': 'r',
  'ě': 'e',
  'ů': 'u',
};

String _foldToAscii(String name) {
  final out = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    out.write(_filenameFolds[char] ?? searchLatinFolds[char] ?? char);
  }
  return out.toString();
}

/// [name] with `-2`, then `-3`, appended until it is not in [taken].
///
/// Only where Odova controls the destination — its own temporary directory,
/// and the safety-copy folder. Where the OS owns the destination the OS
/// handles collisions, and second-guessing it produces `file-2 (1).json`.
String withoutCollision(String name, Set<String> taken) {
  if (!taken.contains(name)) return name;
  final dot = name.lastIndexOf('.');
  final stem = dot == -1 ? name : name.substring(0, dot);
  final extension = dot == -1 ? '' : name.substring(dot);
  for (var n = 2; n < 1000; n++) {
    final candidate = '$stem-$n$extension';
    if (!taken.contains(candidate)) return candidate;
  }
  throw StateError('a thousand files called $name is not a collision');
}

/// `YYYY-MM-DD` for [local].
///
/// `CivilDate.isoDateOf` and not a sixth hand-rolled `padLeft`: that method's
/// own doc records five previous copies, three of them from one epic.
String _date(DateTime local) => CivilDate.isoDateOf(local);

String _two(int n) => n.toString().padLeft(2, '0');

/// Whether [name] is one Odova wrote and would be happy to hand over.
///
/// The gate the filename tests assert against, so the four rules live in one
/// place rather than in four expectations.
@visibleForTesting
bool isSafeExportFileName(String name) =>
    RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*\.[a-z]+$').hasMatch(name);
