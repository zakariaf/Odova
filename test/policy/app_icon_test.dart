// The icon set is complete and uploadable.
//
// Two failures this catches, and both cost a build number rather than a bug
// report. An `AppIcon.appiconset` entry that names a file nobody generated is
// rejected at upload; a 1024 marketing icon **with an alpha channel** is
// rejected as ITMS-90717. A published build number can never be reused, so
// each of those costs one — and they are found at the end of the ritual, after
// the symbols have been archived and the tag written.
//
// It reads the catalog rather than a list typed here. `Contents.json` is what
// Xcode believes; a test with its own list of expected sizes passes while the
// catalog asks for something else.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/png_header.dart';

/// Where the app icon lives.
const _appIcon = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// The catalog's declared images.
List<Map<String, dynamic>> _entries() {
  final json =
      jsonDecode(File('$_appIcon/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  return (json['images'] as List).cast<Map<String, dynamic>>();
}

void main() {
  test('the catalog names only files that exist, at the size it claims', () {
    // The upload failure, found here instead. `size` is in points and `scale`
    // is the multiplier, so a `60x60` at `@3x` must be a 180-pixel square —
    // which is also how a correctly-named file with the wrong contents gets
    // caught.
    final problems = <String>[];

    for (final entry in _entries()) {
      final name = entry['filename'] as String?;
      if (name == null) {
        problems.add('${entry['size']} ${entry['idiom']}: no filename');
        continue;
      }
      final file = File('$_appIcon/$name');
      if (!file.existsSync()) {
        problems.add('$name: declared and missing');
        continue;
      }

      final points = double.parse((entry['size'] as String).split('x').first);
      final scale = int.parse(
        (entry['scale'] as String? ?? '1x').replaceAll('x', ''),
      );
      final expected = (points * scale).round();
      final actual = pngHeaderIn(file);
      if (actual.width != expected || actual.height != expected) {
        problems.add(
          '$name: ${actual.width}x${actual.height}, expected '
          '${expected}x$expected',
        );
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the 1024 marketing icon exists and carries no alpha', () {
    // ITMS-90717, by name. It is rejected at upload rather than at build, so
    // nothing before this point says anything about it.
    final marketing = _entries().where(
      (e) => e['size'] == '1024x1024',
    );
    expect(marketing, hasLength(1), reason: 'no marketing icon in the catalog');

    final file = File('$_appIcon/${marketing.single['filename']}');
    expect(file.existsSync(), isTrue);
    expect(
      pngHeaderIn(file).colourType,
      isNot(anyOf(4, 6)),
      reason:
          'the 1024 icon has an alpha channel — App Store Connect rejects it '
          'as ITMS-90717, and a rejected upload burns its build number',
    );
  });

  test('the icon is still the colour the tokens say it is', () {
    // THE CLAIM THE GENERATOR MAKES, enforced. `design/icon/generate.py` says
    // in its own docstring that "a palette that lives in two files is a palette
    // that disagrees with itself, and the icon is the one surface where nobody
    // notices for months" — and then commits thirteen PNGs, which are that
    // second file. Without this, `--color-brand` can move and the icon keeps
    // the old brown for ever: the exact drift the generator was written to
    // prevent.
    //
    // `launch_screen_test` guards the same drift for the launch colour set by
    // reading the hex out of the stylesheet. The icon had no equivalent.
    //
    // A CORNER pixel, because the gauge is centred and the corners are pure
    // background at every size. Read out of the 1024, whose IDAT is one
    // zlib stream of filtered scanlines.
    final brand = RegExp(
      r'--color-brand:\s*#([0-9A-Fa-f]{6})',
    ).firstMatch(File('design/calm/odova.css').readAsStringSync())?.group(1);
    expect(brand, isNotNull, reason: '--color-brand is not in the stylesheet');

    final marketing = _entries().singleWhere((e) => e['size'] == '1024x1024');
    final pixel = _topLeftPixel(File('$_appIcon/${marketing['filename']}'));

    expect(
      pixel,
      brand!.toUpperCase(),
      reason:
          'the icon was generated from a different --color-brand than the one '
          'the stylesheet declares now — rerun design/icon/generate.py',
    );
  });
}

/// The top-left pixel of a truecolour PNG, as `RRGGBB`.
///
/// Enough of a decoder for one pixel: inflate the IDAT, and the first scanline
/// begins with its filter byte. Filter 0 (`None`) is what the generator emits,
/// and anything else would mean the file was written by something other than
/// the generator — which is itself worth failing on.
String _topLeftPixel(File file) {
  final bytes = file.readAsBytesSync();
  final idat = <int>[];
  var at = 8; // past the signature
  while (at < bytes.length) {
    final length =
        (bytes[at] << 24) |
        (bytes[at + 1] << 16) |
        (bytes[at + 2] << 8) |
        bytes[at + 3];
    final tag = String.fromCharCodes(bytes.sublist(at + 4, at + 8));
    if (tag == 'IDAT') {
      idat.addAll(bytes.sublist(at + 8, at + 8 + length));
    }
    if (tag == 'IEND') break;
    at += 12 + length;
  }

  final raw = ZLibDecoder().convert(idat);
  expect(raw.first, 0, reason: 'the first scanline is not filter None');
  return [
    for (var i = 1; i <= 3; i++) raw[i].toRadixString(16).padLeft(2, '0'),
  ].join().toUpperCase();
}
