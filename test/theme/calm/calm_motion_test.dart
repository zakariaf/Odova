// CalmMotion: five durations, four curves, and a lerp that steps on purpose.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_motion.dart';

import '../../support/calm_css.dart';

final _durations = <String, Duration Function(CalmMotion)>{
  '--dur-instant': (m) => m.instant,
  '--dur-quick': (m) => m.quick,
  '--dur-base': (m) => m.base,
  '--dur-slow': (m) => m.slow,
  '--dur-sheet': (m) => m.sheet,
};

final _curves = <String, Cubic Function(CalmMotion)>{
  '--ease-standard': (m) => m.easeStandard,
  '--ease-out': (m) => m.easeOut,
  '--ease-in': (m) => m.easeIn,
  '--ease-settle': (m) => m.easeSettle,
};

void main() {
  test('all five durations trace to odova.css', () {
    final css = durationsIn(lightTokenBlock());
    expect(css, hasLength(5));

    for (final MapEntry(key: token, value: slot) in _durations.entries) {
      expect(css, contains(token));
      expect(slot(calmMotion).inMilliseconds, css[token], reason: token);
    }
    expect(_durations.keys.toSet(), css.keys.toSet());
  });

  test('all four curves trace to odova.css, control point by point', () {
    // CSS cubic-bezier(a, b, c, d) is Flutter Cubic(a, b, c, d) with identical
    // semantics, so a mismatch here is a transcription error and nothing else.
    final css = curvesIn(lightTokenBlock());
    expect(css, hasLength(4));

    for (final MapEntry(key: token, value: slot) in _curves.entries) {
      expect(css, contains(token));
      final curve = slot(calmMotion);
      expect([curve.a, curve.b, curve.c, curve.d], css[token], reason: token);
    }
    expect(_curves.keys.toSet(), css.keys.toSet());
  });

  test('the curve slots keep their ease prefix', () {
    // `standard` alone would collide with a duration the moment somebody adds
    // one; `easeStandard` cannot.
    for (final token in _curves.keys) {
      expect(token, startsWith('--ease-'));
    }
  });

  test('easeSettle overshoots, which is why it is not the colour curve', () {
    // y1 = 1.24. Legal in Cubic, and it means a widget animating a Color with
    // easeSettle interpolates PAST the target and clamps — visible on a
    // saturated status fill. Transforms only.
    expect(calmMotion.easeSettle.b, greaterThan(1));
    expect(calmMotion.easeStandard.b, lessThanOrEqualTo(1));
  });

  test('CalmMotion.lerp steps deliberately and says so', () {
    // A half-interpolated Duration is not an observable thing, so this steps.
    // A bare step-lerp with no comment reads as unfinished and the next reader
    // "fixes" it, so the source has to carry the reason and this asserts it.
    const other = CalmMotion(
      instant: Duration(seconds: 9),
      quick: Duration(seconds: 9),
      base: Duration(seconds: 9),
      slow: Duration(seconds: 9),
      sheet: Duration(seconds: 9),
      easeStandard: Cubic(1, 1, 1, 1),
      easeOut: Cubic(1, 1, 1, 1),
      easeIn: Cubic(1, 1, 1, 1),
      easeSettle: Cubic(1, 1, 1, 1),
    );

    expect(calmMotion.lerp(other, 0.4).base, calmMotion.base);
    expect(calmMotion.lerp(other, 0.6).base, other.base);
    expect(calmMotion.lerp(other, 0.4).easeStandard, calmMotion.easeStandard);
    expect(calmMotion.lerp(other, 0.6).easeStandard, other.easeStandard);

    expect(
      File('lib/theme/calm/calm_motion.dart').readAsStringSync(),
      contains('DELIBERATE STEP'),
      reason: 'the step needs its reason next to it, or it reads as unfinished',
    );
  });

  testWidgets('CalmMotion.of asserts, naming the extension and the builder', (
    tester,
  ) async {
    Object? thrown;
    await tester.pumpWidget(
      Theme(
        data: ThemeData.light(),
        child: Builder(
          builder: (context) {
            try {
              CalmMotion.of(context);
            } on Object catch (error) {
              thrown = error;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      thrown,
      isA<AssertionError>().having(
        (e) => e.toString(),
        'message',
        allOf(contains('CalmMotion'), contains('buildCalmTheme')),
      ),
    );
  });
}
