// CalmShapes: eight radii, five elevations, and the one unit conversion that
// silently ships every shadow too soft.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_shapes.dart';

import '../../support/calm_css.dart';
import '../../support/calm_theme_harness.dart';
import '../../support/source_tree.dart';

/// The CSS blur is 2σ; Flutter's `blurRadius` is converted with
/// `Shadow.convertRadiusToSigma(r) = r * 0.57735 + 0.5`. This is the inverse.
double _expectedBlur(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;

final _radii = <String, double Function(CalmShapes)>{
  '--radius-xs': (s) => s.radiusXs,
  '--radius-sm': (s) => s.radiusSm,
  '--radius-md': (s) => s.radiusMd,
  '--radius-lg': (s) => s.radiusLg,
  '--radius-xl': (s) => s.radiusXl,
  '--radius-2xl': (s) => s.radius2xl,
  '--radius-3xl': (s) => s.radius3xl,
  '--radius-pill': (s) => s.radiusPill,
};

List<BoxShadow> _elevation(CalmShapes s, int level) => switch (level) {
  0 => s.elev0,
  1 => s.elev1,
  2 => s.elev2,
  3 => s.elev3,
  4 => s.elev4,
  _ => throw ArgumentError('no elev$level'),
};

void main() {
  test('all eight radii exist and trace to odova.css', () {
    final css = pixelMetricsIn(lightTokenBlock());

    for (final MapEntry(key: token, value: slot) in _radii.entries) {
      expect(css, contains(token));
      expect(slot(calmShapesLight), css[token], reason: token);
      expect(
        slot(calmShapesDark),
        css[token],
        reason: '$token — radii are brightness-independent',
      );
    }
  });

  test('radiusPill is the 999 sentinel and reaches only a StadiumBorder', () {
    expect(calmShapesLight.radiusPill, 999);

    // 999 in a ClipRRect allocates a path Skia re-clamps on every frame, and
    // it renders ALMOST right — which is why this is a grep and not an eye.
    for (final file in dartFilesUnder('lib')) {
      // Comment lines stripped, as check_raw_values.sh does: the sentence
      // "not BorderRadius.circular(radiusPill)" above the StadiumBorder that
      // replaced it is the point, and a gate that fails on its own
      // explanation teaches people to delete the explanation.
      final source = file
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      for (final match in RegExp(
        r'(?:BorderRadius|Radius)\.circular\(\s*[a-zA-Z.]*radiusPill',
      ).allMatches(source)) {
        fail('${file.path}: ${match.group(0)} — use a StadiumBorder');
      }
    }
  });

  test('CSS blur is converted, not pasted', () {
    // Pasting the CSS number ships every shadow 1.2-1.65x too soft — worst on
    // the tight first layer — and it survives review because it looks exactly
    // like the token.
    for (final (label, shapes, block) in [
      ('light', calmShapesLight, lightTokenBlock()),
      ('dark', calmShapesDark, darkTokenBlock()),
    ]) {
      for (var level = 0; level <= 4; level++) {
        final css = elevationLayers(block, level);
        final dart = _elevation(shapes, level);

        expect(dart, hasLength(css.length), reason: '$label elev$level layers');

        for (var i = 0; i < css.length; i++) {
          expect(
            dart[i].blurRadius,
            closeTo(_expectedBlur(css[i].blur), 0.01),
            reason: '$label elev$level layer $i: CSS blur ${css[i].blur}px',
          );
          expect(dart[i].offset.dy, css[i].dy, reason: '$label elev$level dy');
          expect(
            dart[i].spreadRadius,
            css[i].spread,
            reason: '$label elev$level spread',
          );
          expect(
            dart[i].color.a,
            closeTo(css[i].alpha, 0.005),
            reason: '$label elev$level alpha',
          );
        }
      }
    }
  });

  test('the conversion is not the identity', () {
    // Guard the guard: if _expectedBlur were wrong in the same way the source
    // is, every assertion above would pass. A 2px CSS blur must NOT be 2.
    expect(_expectedBlur(2), closeTo(0.866, 0.001));
    expect(calmShapesLight.elev1.first.blurRadius, isNot(2));
  });

  test('CalmShapes has two instances and only the elevations differ', () {
    // The radii are brightness-independent; --elev-* is not — warm clay tint in
    // light, black at roughly 6x the alpha in dark. One instance is the bug
    // this catches.
    expect(calmShapesLight.elev1, isNot(calmShapesDark.elev1));
    expect(calmShapesLight.elev1.first.color.a, lessThan(0.1));
    expect(calmShapesDark.elev1.first.color.a, greaterThan(0.3));
  });

  testOfAsserts('CalmShapes', CalmShapes.of);
}
