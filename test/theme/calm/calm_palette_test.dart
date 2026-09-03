// Tier 1 traces to the CSS, in both directions.
//
// design/calm/odova.css is the design. A palette constant that is not in it is
// a colour an engineer chose; a CSS colour with no constant is a colour the app
// cannot render. Both are silent, and both make the palette a second source of
// truth for what Odova looks like.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/calm_css.dart';
import '../../support/source_tree.dart';

const _paletteFile = 'lib/theme/calm/calm_palette.dart';

/// [file]'s source with whole comment lines removed.
String _codeOf(File file) => file
    .readAsLinesSync()
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

/// Every `static const <name> = Color(0xFFRRGGBB);` in the palette.
///
/// Parsed rather than reflected: `dart:mirrors` is not available in Flutter,
/// and the file's shape — one constant per line, one colour per constant — is
/// itself part of the contract.
Map<String, String> _paletteConstants() {
  final source = File(_paletteFile).readAsStringSync();
  return {
    for (final match in RegExp(
      r'static const (\w+) = Color\(0x[fF][fF]([0-9A-Fa-f]{6})\);',
    ).allMatches(source))
      match.group(1)!: '#${match.group(2)!.toUpperCase()}',
  };
}

void main() {
  test('every CalmPalette constant appears as a colour in odova.css', () {
    final constants = _paletteConstants();
    expect(constants, isNotEmpty, reason: 'the palette parser found nothing');

    // The shadow tints are the rgba() bases inside --elev-*; they carry no
    // --token name of their own, so they are traced through the shadow lists.
    final declared = {...allCalmHexes(), ...allCalmRgbaBases()};

    for (final MapEntry(key: name, value: hex) in constants.entries) {
      expect(
        declared,
        contains(hex),
        reason:
            '$name is $hex, which appears nowhere in $calmCssPath. Nothing '
            'in this file was chosen by an engineer.',
      );
    }
  });

  test('every distinct colour in odova.css has a CalmPalette constant', () {
    final values = _paletteConstants().values.toSet();

    // 56 roles x 2 themes collapse to 96 distinct hexes; the palette also
    // carries the two --elev-* shadow tints, which is what makes it 98.
    expect(
      allCalmHexes(),
      hasLength(96),
      reason:
          'the CSS has moved since this expectation was written — report '
          'the real number in the progress file rather than editing this',
    );

    for (final hex in allCalmHexes()) {
      expect(
        values,
        contains(hex),
        reason:
            '$hex is declared in $calmCssPath and has no constant, so no '
            'widget can ever render it',
      );
    }
  });

  test('constant names are <family><lightness>, never a rank or an appearance '
      'name', () {
    // A rank scale (100/200/300) has no room to insert a value between two
    // rungs and lies in dark mode, where the ramp inverts. An appearance name
    // (greyLight) inverts catastrophically. Measured OKLCH lightness is a fact
    // about the pixel, so the name cannot lie in either theme.
    const forbidden = {'grey', 'gray', 'dark', 'light', 'primary', 'brand'};

    // The two shadow tints are the opaque bases inside --elev-*, not rungs on
    // any ramp — there is no lightness scale to insert them into, so the
    // <family><lightness> shape does not apply. They are still held to the
    // forbidden-word rule below.
    const notOnARamp = {'shadowTint', 'shadowTintBlack'};

    for (final name in _paletteConstants().keys) {
      if (!notOnARamp.contains(name)) {
        expect(
          RegExp(r'^[a-z]+[0-9]{2}[a-z]?$').hasMatch(name),
          isTrue,
          reason: "'$name' is not <family><lightness>",
        );
      }
      for (final word in forbidden) {
        expect(
          name.toLowerCase().startsWith(word),
          isFalse,
          reason: "'$name' names a rank, an appearance or a brand",
        );
      }
    }
  });

  test('CalmPalette is referenced nowhere outside lib/theme/calm/', () {
    // A widget naming sand96 has hardcoded light mode. This mirrors
    // check_raw_values.sh's second rule; the script is the CI gate and this is
    // the same rule where a person reads it.
    // Comment lines are stripped, like check_raw_values.sh and
    // expectNoBannedPatterns: a doc comment naming CalmPalette in order to
    // explain why a widget must not read it is the most useful line in that
    // file.
    final offenders = dartFilesUnder('lib')
        .where((f) => !f.path.startsWith('lib/theme/calm/'))
        .where((f) => _codeOf(f).contains('CalmPalette.'))
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
