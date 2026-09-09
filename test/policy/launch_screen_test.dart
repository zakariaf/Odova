// The first frame is Calm's surface, in both appearances.
//
// The flash of the wrong colour on launch is the defect nobody files a bug for
// and everybody sees: a white storyboard under a dark app reads as a broken
// app for the fifth of a second before Flutter paints. It is also the defect
// that arrives silently — a token moves in `design/calm/odova.css` and the
// platform file, which is not Dart and not linted, keeps the old value for
// ever.
//
// **The expected hexes are READ from the stylesheet, not typed here.** A test
// with its own copy of the palette is a second place for the palette to be
// wrong, and it passes on the day the first one changes.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The nth `--color-surface` in the Calm stylesheet, as `RRGGBB`.
///
/// Occurrence 0 is the light block and 1 is the dark one — the file declares
/// the palette twice, light first, exactly as `calm_contrast_test` reads it.
String _surface({required int occurrence}) {
  final css = File('design/calm/odova.css').readAsStringSync();
  final hits = RegExp(
    r'--color-surface:\s*#([0-9A-Fa-f]{6})',
  ).allMatches(css).map((m) => m.group(1)!.toUpperCase()).toList();
  expect(
    hits.length,
    greaterThan(occurrence),
    reason: 'the stylesheet declares fewer surfaces than this test expects',
  );
  return hits[occurrence];
}

/// A colour-set component, as an integer 0-255.
///
/// Xcode writes components as either `"1.000"` or `"0xFF"`, and a reader that
/// handles one silently mis-reads the other.
int _component(String raw) => raw.startsWith('0x')
    ? int.parse(raw.substring(2), radix: 16)
    : (double.parse(raw) * 255).round();

/// The `RRGGBB` of the colour-set entry whose appearance matches [dark].
String _launchColour({required bool dark}) {
  final json =
      jsonDecode(
            File(
              'ios/Runner/Assets.xcassets/LaunchBackground.colorset/'
              'Contents.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  for (final entry in (json['colors'] as List).cast<Map<String, dynamic>>()) {
    final appearances = (entry['appearances'] as List?) ?? const [];
    final isDark = appearances.any(
      (a) => (a as Map)['value'] == 'dark',
    );
    if (isDark != dark) continue;

    final components = ((entry['color'] as Map)['components'] as Map)
        .cast<String, String>();
    return [
      for (final channel in ['red', 'green', 'blue'])
        _component(components[channel]!).toRadixString(16).padLeft(2, '0'),
    ].join().toUpperCase();
  }
  fail('no ${dark ? 'dark' : 'any'} appearance in LaunchBackground.colorset');
}

void main() {
  test('the launch background is the Calm surface, light and dark', () {
    expect(
      _launchColour(dark: false),
      _surface(occurrence: 0),
      reason: 'the light launch screen is not --color-surface',
    );
    expect(
      _launchColour(dark: true),
      _surface(occurrence: 1),
      reason: 'the dark launch screen is not the dark --color-surface',
    );
  });

  test('the storyboard paints that colour set and no image', () {
    // The other half. A colour set nothing references is a colour set that
    // does not run, and the default storyboard ships a centred `LaunchImage`
    // on white — which is what would actually be seen.
    final storyboard = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();

    expect(
      storyboard,
      contains('LaunchBackground'),
      reason: 'the storyboard does not reference the colour set',
    );
    expect(
      storyboard,
      isNot(contains('image="LaunchImage"')),
      reason: 'the default placeholder image is still on the launch screen',
    );
  });
}
