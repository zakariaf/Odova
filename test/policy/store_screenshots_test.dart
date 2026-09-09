// The screenshot set is complete, the right size, and not three copies of one
// screen.
//
// Apple asks for 6.9-inch iPhone shots and derives the smaller classes from
// them, so one display covers the requirement — but it must be the right pixel
// size, and a set at the wrong size is rejected at upload, at the end of the
// ritual.
//
// **The duplicate check is the one that earned its place.** The first capture
// run produced three identical Home shots for fa, ar and ckb: the app mirrors
// for RTL, every scripted tap landed on empty space, the screen never changed,
// and the script reported success three times. A count check passes that. A
// human reviewing the folder sees three thumbnails and moves on.
//
// A Persian listing showing English screenshots — or the same screen three
// times — is the most common way a six-language launch looks unfinished, and
// it is invisible to everyone who does not read the language.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _locales = ['en', 'de', 'fr', 'fa', 'ar', 'ckb'];

/// What App Store Connect accepts for the 6.9-inch class, in portrait.
const _width = 1320;
const _height = 2868;

/// At least this many shots per locale, per Apple's minimum.
const _minimum = 3;

List<File> _shots(String locale) {
  final dir = Directory('store/screenshots/$locale/6.9-inch');
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<File>()
      .where(
        (f) => f.path.endsWith('.png'),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// The width and height from a PNG's IHDR.
({int width, int height}) _size(File file) {
  final bytes = file.readAsBytesSync();
  int at(int o) =>
      (bytes[o] << 24) |
      (bytes[o + 1] << 16) |
      (bytes[o + 2] << 8) |
      bytes[o + 3];
  return (width: at(16), height: at(20));
}

void main() {
  test('every locale has the minimum number of shots', () {
    for (final locale in _locales) {
      expect(
        _shots(locale).length,
        greaterThanOrEqualTo(_minimum),
        reason: '$locale has fewer than $_minimum screenshots',
      );
    }
  });

  test('every shot is exactly the 6.9-inch size', () {
    final wrong = <String>[];
    for (final locale in _locales) {
      for (final shot in _shots(locale)) {
        final size = _size(shot);
        if (size.width != _width || size.height != _height) {
          wrong.add('${shot.path}: ${size.width}x${size.height}');
        }
      }
    }
    expect(
      wrong,
      isEmpty,
      reason: 'not ${_width}x$_height:\n${wrong.join('\n')}',
    );
  });

  test('no locale ships the same screen twice', () {
    // The RTL failure, by construction. Byte equality is enough: two captures
    // of the same screen from the same simulator are identical, and two
    // captures of different screens never are.
    final duplicated = <String>[];
    for (final locale in _locales) {
      final seen = <String, String>{};
      for (final shot in _shots(locale)) {
        final digest = shot.readAsBytesSync().fold<int>(
          17,
          (h, b) => (h * 31 + b) & 0x3FFFFFFF,
        );
        final key = '${shot.lengthSync()}:$digest';
        final first = seen[key];
        if (first != null) {
          duplicated.add('$locale: ${shot.uri.pathSegments.last} == $first');
        } else {
          seen[key] = shot.uri.pathSegments.last;
        }
      }
    }

    expect(
      duplicated,
      isEmpty,
      reason:
          'a scripted tap landed on nothing and the screen never changed:\n'
          '${duplicated.join('\n')}',
    );
  });
}
