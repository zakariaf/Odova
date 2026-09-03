// The Arabic-script locales get a real font, in a format Flutter can load.
//
// SPEC.md §5 Fonts: en/de/fr use the platform font; fa/ar/ckb get Vazirmatn for
// the entire UI, Latin runs included. SPEC.md §2: it is an asset, never a
// fetch — which is why `google_fonts` is refused by name.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/font_licences.dart';

import '../../support/ttf_reader.dart';

const _licencePath = 'assets/fonts/OFL.txt';

void main() {
  test('the Vazirmatn asset is a TTF or OTF, never woff2', () {
    // design/_fonts/Vazirmatn.woff2 belongs to the HTML mockup pipeline.
    // Flutter's font loader cannot read woff2 at all, so the app's asset has to
    // come from the upstream release rather than from a conversion of the
    // mockup file.
    expect(
      File(vazirmatnPath).existsSync(),
      isTrue,
      reason: '$vazirmatnPath missing',
    );
    expect(vazirmatn.isWoff2, isFalse);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains(vazirmatnPath),
      reason: 'the asset is not declared under flutter: fonts:',
    );
  });

  test('the wght axis reports min 100, default 400, max 900', () {
    // A subsetter that INSTANCES the font freezes it to one weight and drops
    // fvar. FontWeight then stops working, and so does the platform's
    // bold-text accessibility flag — failing only for the user who turned bold
    // text on, who is nobody in review.
    final axes = vazirmatn.variationAxes;
    expect(axes, hasLength(1), reason: 'expected exactly the wght axis');

    final wght = axes.single;
    expect(wght.tag, 'wght');
    expect(wght.min, 100);
    expect(wght.def, 400);
    expect(wght.max, 900);
  });

  test('OFL.txt ships as an asset and names the SIL licence', () {
    expect(File(_licencePath).existsSync(), isTrue);
    final licence = File(_licencePath).readAsStringSync();
    expect(licence, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains(_licencePath),
      reason:
          'the licence is not declared as an asset, so rootBundle cannot '
          'read it and the licences page would show nothing',
    );
  });

  testWidgets('the licence is registered and reaches the licences page', (
    tester,
  ) async {
    // SIL OFL 1.1 requires the licence to travel with the font. Flutter's
    // built-in licences page reads LicenseRegistry, so registering is the
    // difference between honouring that and not.
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);

    registerFontLicences();

    final entries = await LicenseRegistry.licenses.toList();
    final vazirmatn = entries.where((e) => e.packages.contains('Vazirmatn'));
    expect(vazirmatn, isNotEmpty, reason: 'no Vazirmatn entry was registered');
    expect(
      vazirmatn.single.paragraphs.map((p) => p.text).join(' '),
      contains('SIL OPEN FONT LICENSE'),
    );
  });
}
