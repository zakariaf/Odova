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

/// Where the app icon lives.
const _appIcon = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// The catalog's declared images.
List<Map<String, dynamic>> _entries() {
  final json =
      jsonDecode(File('$_appIcon/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  return (json['images'] as List).cast<Map<String, dynamic>>();
}

/// The width and height of a PNG, from its IHDR chunk.
///
/// Eight bytes of signature, then a length and the `IHDR` tag, then width and
/// height as big-endian 32-bit integers. Parsed here rather than pulled in as a
/// dependency: SPEC.md §2 makes every added package a thing to audit, and this
/// is sixteen bytes at a fixed offset.
({int width, int height}) _pngSize(File file) {
  final bytes = file.readAsBytesSync();
  int at(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return (width: at(16), height: at(20));
}

/// The PNG colour type byte, also from IHDR.
///
/// 0 greyscale, 2 truecolour, 3 indexed, 4 greyscale+alpha, 6 truecolour+alpha.
/// Apple rejects the marketing icon for the two that carry alpha.
int _pngColourType(File file) => file.readAsBytesSync()[25];

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
      final actual = _pngSize(file);
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
      _pngColourType(file),
      isNot(anyOf(4, 6)),
      reason:
          'the 1024 icon has an alpha channel — App Store Connect rejects it '
          'as ITMS-90717, and a rejected upload burns its build number',
    );
  });
}
