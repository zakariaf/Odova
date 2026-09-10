// The screenshot set is complete, the right size, and not ten copies of one
// screen.
//
// Two display classes, because the app declares `TARGETED_DEVICE_FAMILY =
// "1,2"` and Apple asks for a set per family it is told the app supports. A
// missing iPad set is not a warning; it is a version that cannot be submitted,
// discovered at the end of the ritual.
//
// **The duplicate check is the one that earned its place.** The first capture
// run produced three identical Home shots for fa, ar and ckb: the app mirrors
// for RTL, every scripted tap landed on empty space, the screen never changed,
// and the script reported success three times. A count check passes that. A
// human reviewing the folder sees three thumbnails and moves on.
//
// A Persian listing showing English screenshots — or the same screen ten times
// — is the most common way a six-language launch looks unfinished, and it is
// invisible to everyone who does not read the language.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/supported_locales.dart';

import '../support/png_header.dart';

/// The shipped locales, from the app's own list rather than a copy.
///
/// A hand-typed sixth-and-final list is how a seventh locale ships with no
/// store listing and no screenshots: both gates pass, because neither was told
/// the locale exists.
final List<String> _locales = odovaSupportedLocales
    .map((l) => l.languageCode)
    .toList();

/// A display class and the exact pixel size App Store Connect accepts for it.
typedef _Class = ({String dir, int width, int height});

/// Both classes, because `TARGETED_DEVICE_FAMILY` names both families.
///
/// Apple derives the smaller iPhone classes from the 6.9-inch set and the
/// smaller iPad classes from the 13-inch set, so two directories cover every
/// device the app claims to run on.
const List<_Class> _classes = [
  (dir: '6.9-inch', width: 1320, height: 2868),
  (dir: '13-inch', width: 2048, height: 2732),
];

/// Apple's minimum is 3. Ten is this project's number, and it is deliberate:
/// three screens can show that the app exists, and only a full set can show
/// what it does with a car that has a history behind it.
const _expected = 10;

/// The shots for each locale and class, listed ONCE.
///
/// Three tests want the same twelve directory walks; without this they do
/// thirty-six.
final _shots = <String, List<File>>{
  for (final locale in _locales)
    for (final klass in _classes) '$locale/${klass.dir}': _walk(locale, klass),
};

List<File> _walk(String locale, _Class klass) {
  final dir = Directory('store/screenshots/$locale/${klass.dir}');
  if (!dir.existsSync()) return const [];
  return dir.listSync().whereType<File>().where((f) {
    return f.path.endsWith('.png');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  test('every locale has a full set in both display classes', () {
    final short = <String>[];
    for (final key in _shots.keys) {
      final found = _shots[key]!.length;
      if (found != _expected) short.add('$key: $found');
    }
    expect(
      short,
      isEmpty,
      reason:
          'each locale needs exactly $_expected shots per display class, and '
          'these do not have them:\n${short.join('\n')}',
    );
  });

  test('every shot is exactly its class size', () {
    final wrong = <String>[];
    for (final locale in _locales) {
      for (final klass in _classes) {
        for (final shot in _shots['$locale/${klass.dir}']!) {
          final size = pngHeaderIn(shot);
          if (size.width != klass.width || size.height != klass.height) {
            wrong.add(
              '${shot.path}: ${size.width}x${size.height}, '
              'want ${klass.width}x${klass.height}',
            );
          }
        }
      }
    }
    expect(wrong, isEmpty, reason: 'wrong size:\n${wrong.join('\n')}');
  });

  test('no locale ships the same screen twice', () {
    // The RTL failure, by construction. Byte equality is enough: two captures
    // of the same screen at the same size are identical, and two captures of
    // different screens never are.
    final duplicated = <String>[];
    for (final key in _shots.keys) {
      // LENGTH FIRST. Two captures of different screens differ in size almost
      // always, and hashing 8 MB of PNG through a Dart closure to learn that is
      // eight million interpreted iterations for an answer `stat` already had.
      // The bytes are only read when two files are the same size.
      final seen = <int, List<File>>{};
      for (final shot in _shots[key]!) {
        final sameSize = seen.putIfAbsent(shot.lengthSync(), () => []);
        final twin = sameSize.where((f) => _sameBytes(f, shot)).firstOrNull;
        sameSize.add(shot);
        if (twin != null) {
          duplicated.add(
            '$key: ${shot.uri.pathSegments.last} == '
            '${twin.uri.pathSegments.last}',
          );
        }
      }
    }

    expect(
      duplicated,
      isEmpty,
      reason:
          'a capture photographed the screen before it changed:\n'
          '${duplicated.join('\n')}',
    );
  });
}

/// Whether two files hold the same bytes.
bool _sameBytes(File a, File b) {
  final left = a.readAsBytesSync();
  final right = b.readAsBytesSync();
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
