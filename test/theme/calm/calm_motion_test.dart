// CalmMotion: five durations, four curves, and a lerp that steps on purpose.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_motion.dart';

import '../../support/calm_css.dart';
import '../../support/calm_theme_harness.dart';

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
  test('undoWindow is six seconds and is not a CSS token', () {
    // SPEC.md §10. It sits on CalmMotion because every duration in the app
    // sits on CalmMotion, not because the design system chose it — and this
    // test says so, so the next person to look for `--dur-undo` stops here.
    expect(calmMotion.undoWindow, const Duration(seconds: 6));
    expect(
      lightTokenBlock(),
      isNot(contains('--dur-undo')),
      reason: 'a token appeared; trace the slot to it and delete this test',
    );
  });

  test('searchDebounce is 200 ms and is a dwell, not a transition', () {
    // SPEC.md §11's search debounce. The third duration here that traces to no
    // `--dur-*` token, and it is on this extension for the reason the other
    // two are: `check_touch_targets.sh` cannot tell a debounce from an
    // animation, and the repo has already decided twice that "it is not really
    // motion" loses that argument.
    //
    // Not collapsed by reduced motion. Collapsing it would run a LIKE over
    // every text column on every keystroke — which is the cost the debounce
    // exists to avoid, charged hardest to the user who asked for less motion.
    expect(calmMotion.searchDebounce, const Duration(milliseconds: 200));
  });

  test('skeletonDelay is 150 ms and is not a CSS token either', () {
    // SPEC.md §9: "A skeleton appears only past 150 ms, to avoid a flash on
    // the common path." A THRESHOLD, not a transition — it sits here for the
    // reason `undoWindow` does, because "it is not really motion" is not a
    // distinction `check_touch_targets.sh`'s grep can make.
    expect(calmMotion.skeletonDelay, const Duration(milliseconds: 150));
    expect(
      lightTokenBlock(),
      isNot(contains('--dur-skeleton')),
      reason: 'a token appeared; trace the slot to it and delete this test',
    );
  });

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
      undoWindow: Duration(seconds: 9),
      skeletonDelay: Duration(seconds: 9),
      searchDebounce: Duration(seconds: 11),
      easeStandard: Cubic(1, 1, 1, 1),
      easeOut: Cubic(1, 1, 1, 1),
      easeIn: Cubic(1, 1, 1, 1),
      easeSettle: Cubic(1, 1, 1, 1),
    );

    expect(calmMotion.lerp(other, 0.4).base, calmMotion.base);
    expect(calmMotion.lerp(other, 0.6).base, other.base);
    expect(calmMotion.lerp(other, 0.4).easeStandard, calmMotion.easeStandard);
    expect(calmMotion.lerp(other, 0.6).easeStandard, other.easeStandard);

    // Both files that step carry the marker, not just this one. A bare
    // step-lerp with no reason beside it reads as unfinished and the next
    // reader "fixes" it into an interpolation that has no meaning.
    for (final path in [
      'lib/theme/calm/calm_motion.dart',
      'lib/theme/calm/calm_type.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('DELIBERATE STEP'),
        reason: '$path steps without saying why',
      );
    }
  });

  testOfAsserts('CalmMotion', CalmMotion.of);
}
