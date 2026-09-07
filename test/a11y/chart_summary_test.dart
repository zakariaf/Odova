// The sentence a chart says when nobody can see it.
//
// SPEC.md §17: both charts need a non-visual alternative. A `CustomPainter`
// draws pixels and exposes NOTHING — a screen reader walking the tree finds an
// empty box where twelve months of spending is. There is no widget-level fix;
// the summary has to be authored, and then it has to be right.
@TestOn('vm')
library;

import 'package:odova/ui/calm/chart_summary.dart';
import 'package:test/test.dart';

void main() {
  test('names the range, the ends and the count', () {
    final s = summariseSeries([7.1, 6.9, 7.4, 6.4])!;

    expect(s.count, 4);
    expect(s.first, 7.1);
    expect(s.last, 6.4);
    expect(s.lowest, 6.4);
    expect(s.highest, 7.4);
  });

  test('the best and worst are the extremes, not the ends', () {
    // A chart MARKS the best and worst points; a mark is not announced. If the
    // summary reported the ends instead, a series that peaked in the middle
    // would announce a range it never reached.
    final s = summariseSeries([7.0, 9.5, 5.5, 7.0])!;

    expect(s.lowest, 5.5);
    expect(s.highest, 9.5);
    expect(s.first, 7.0);
    expect(s.last, 7.0);
  });

  group('the trend', () {
    test('is down when consumption improves', () {
      expect(summariseSeries([7.1, 6.9, 6.6, 6.4])!.trend, SeriesTrend.down);
    });

    test('is up when it worsens', () {
      expect(summariseSeries([6.4, 6.6, 6.9, 7.1])!.trend, SeriesTrend.up);
    });

    test('is flat inside the noise floor', () {
      // Consumption wanders between tanks for reasons that have nothing to do
      // with the car — a headwind, a cold morning, a pump cutting off early.
      // Calling that "trending up" is the app guessing in a way that looks like
      // fact, in the one channel a user cannot check against the picture.
      expect(
        summariseSeries([7.00, 7.20, 6.90, 7.01])!.trend,
        SeriesTrend.flat,
      );
    });

    test('is measured against the SPAN, not the first value', () {
      // 0.2 is enormous on a series that moves by 0.3 and nothing on one that
      // moves by 4. A fraction of the first value says neither.
      expect(
        summariseSeries([7.0, 7.05, 7.1, 7.2])!.trend,
        SeriesTrend.up,
        reason: 'a 0.2 rise across a 0.2 span is the whole story',
      );
      expect(
        summariseSeries([7.0, 11.0, 3.0, 7.2])!.trend,
        SeriesTrend.flat,
        reason: 'the same 0.2 across an 8.0 span is noise',
      );
    });

    test('a perfectly flat series is flat, not a division by zero', () {
      final s = summariseSeries([7.0, 7.0, 7.0])!;

      expect(s.trend, SeriesTrend.flat);
      expect(s.lowest, s.highest);
    });
  });

  group('what it refuses to say', () {
    test('one point is not a trend', () {
      // Null rather than a summary with a made-up direction. The chart renders
      // nothing below two points for the same reason, so the two agree.
      expect(summariseSeries([7.1]), isNull);
      expect(summariseSeries([]), isNull);
    });

    test('two points ARE enough', () {
      expect(summariseSeries([7.1, 6.4])!.trend, SeriesTrend.down);
    });
  });

  test('is a pure function of the plotted values', () {
    // The property that stops the summary and the painting drifting apart: the
    // same list in gives the same sentence out, so a chart that changed its
    // data without changing its summary cannot exist.
    final a = summariseSeries([7.1, 6.9, 7.4, 6.4]);
    final b = summariseSeries([7.1, 6.9, 7.4, 6.4]);

    expect(a, b);
  });
}
