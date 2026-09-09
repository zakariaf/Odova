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

/// What App Store Connect accepts for the 6.9-inch class, in portrait.
const _width = 1320;
const _height = 2868;

/// At least this many shots per locale, per Apple's minimum.
const _minimum = 3;

/// The shots for each locale, listed ONCE.
///
/// Three tests want the same six directory walks; without this they do
/// eighteen.
final _byLocale = <String, List<File>>{
  for (final locale in _locales) locale: _shots(locale),
};

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

void main() {
  test('every locale has the minimum number of shots', () {
    for (final locale in _locales) {
      expect(
        _byLocale[locale]!.length,
        greaterThanOrEqualTo(_minimum),
        reason: '$locale has fewer than $_minimum screenshots',
      );
    }
  });

  test('every shot is exactly the 6.9-inch size', () {
    final wrong = <String>[];
    for (final locale in _locales) {
      for (final shot in _byLocale[locale]!) {
        final size = pngHeaderIn(shot);
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
      // LENGTH FIRST. Two captures of different screens differ in size almost
      // always, and hashing 8 MB of PNG through a Dart closure to learn that is
      // eight million interpreted iterations for an answer `stat` already had.
      // The bytes are only read when two files are the same size.
      final seen = <int, List<File>>{};
      for (final shot in _byLocale[locale]!) {
        final sameSize = seen.putIfAbsent(shot.lengthSync(), () => []);
        final twin = sameSize.where((f) => _sameBytes(f, shot)).firstOrNull;
        sameSize.add(shot);
        final key = twin;
        if (key != null) {
          duplicated.add(
            '$locale: ${shot.uri.pathSegments.last} == '
            '${key.uri.pathSegments.last}',
          );
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
