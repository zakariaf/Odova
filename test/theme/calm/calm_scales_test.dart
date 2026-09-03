// CalmSpace: the ten-step ramp plus the fixed metrics.
//
// The ramp is 4/8/12/16/20/24 and then jumps to 32/40/56/72, so it is NOT a
// doubling scale and a step must never be computed. `s4 * 2` is 32, which is
// `s7`, and the arithmetic looks like it works right up to `s5 * 2` being 40,
// which is `s8` — a coincidence that stops holding at `s9`.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';

import '../../support/calm_css.dart';
import '../../support/calm_theme_harness.dart';

/// Every CalmSpace slot, and the CSS token it carries.
final _slotToToken = <String, double Function(CalmSpace)>{
  '--space-1': (s) => s.s1,
  '--space-2': (s) => s.s2,
  '--space-3': (s) => s.s3,
  '--space-4': (s) => s.s4,
  '--space-5': (s) => s.s5,
  '--space-6': (s) => s.s6,
  '--space-7': (s) => s.s7,
  '--space-8': (s) => s.s8,
  '--space-9': (s) => s.s9,
  '--space-10': (s) => s.s10,
  '--screen-pad': (s) => s.screenPad,
  '--appbar-h': (s) => s.appbarH,
  '--statusbar-h': (s) => s.statusbarH,
  '--tabbar-h': (s) => s.tabbarH,
  '--homebar-h': (s) => s.homebarH,
  '--touch-min': (s) => s.touchMin,
};

void main() {
  test('every space and metric token traces to a line in odova.css', () {
    final css = pixelMetricsIn(lightTokenBlock());

    for (final MapEntry(key: token, value: slot) in _slotToToken.entries) {
      expect(css, contains(token), reason: '$token is not in the CSS');
      expect(slot(calmSpace), css[token], reason: token);
    }
  });

  test('the slot table covers every space and metric the CSS declares', () {
    // The radii are the same shape of token but ride CalmShapes, so they are
    // excluded here rather than missing.
    final expected = pixelMetricsIn(
      lightTokenBlock(),
    ).keys.where((k) => !k.startsWith('--radius-')).toSet();

    expect(_slotToToken.keys.toSet(), expected);
  });

  test('the ramp is not a doubling scale, so a step is never computed', () {
    expect(calmSpace.s1, 4);
    expect(calmSpace.s2, 8);
    expect(calmSpace.s6, 24);
    expect(calmSpace.s7, 32);
    // The two that make the point: doubling s6 gives 48, which is not a step
    // at all, and doubling s7 gives 64, which is not s9 (56).
    expect(calmSpace.s7, isNot(calmSpace.s6 * 2));
    expect(calmSpace.s9, isNot(calmSpace.s7 * 2));
  });

  test('touchMin is 52, above Material 48, on purpose', () {
    // SPEC.md §1: logging happens at a pump, in the rain, one-handed.
    expect(calmSpace.touchMin, 52);
    expect(calmSpace.touchMin, greaterThan(48));
  });

  test('screenPad is off the ramp, deliberately', () {
    // 22 is the horizontal gutter, not a spacing step. Reading it as one would
    // put it between s5 and s6 and invite `s5 + 2`.
    expect(calmSpace.screenPad, 22);
    expect(
      [
        calmSpace.s1,
        calmSpace.s2,
        calmSpace.s3,
        calmSpace.s4,
        calmSpace.s5,
        calmSpace.s6,
        calmSpace.s7,
      ],
      isNot(contains(calmSpace.screenPad)),
    );
  });

  testOfAsserts('CalmSpace', CalmSpace.of);
}
