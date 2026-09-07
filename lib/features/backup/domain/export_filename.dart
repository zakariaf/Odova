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
/// [vehicleSlug] is already transliterated — [vehicleFileSlug] does that, and
/// takes the list position it needs for the fallback.
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

/// [name] with the accents Latin scripts add folded away.
///
/// `VW Käfer` → `vw kafer`. Not a general Unicode normaliser: the job is a
/// FILENAME, and the honest answer for a script with no ASCII equivalent is
/// the numbered fallback rather than a transliteration nobody asked for.
String _foldToAscii(String name) {
  const folds = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'æ': 'ae',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ø': 'o',
    'œ': 'oe',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
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
  final out = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    out.write(folds[char] ?? char);
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

String _date(DateTime local) =>
    '${local.year}-${_two(local.month)}-${_two(local.day)}';

String _two(int n) => n.toString().padLeft(2, '0');

/// Whether [name] is one Odova wrote and would be happy to hand over.
///
/// The gate the filename tests assert against, so the four rules live in one
/// place rather than in four expectations.
@visibleForTesting
bool isSafeExportFileName(String name) =>
    RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*\.[a-z]+$').hasMatch(name);
