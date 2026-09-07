// What a chart says when nobody can see it.
//
// SPEC.md §17's gate: "Both charts have a non-visual alternative: a
// screen-reader summary and an accessible data table behind one control." A
// painted chart has NO semantics at all — a `CustomPainter` draws pixels, and a
// screen reader walking the tree finds an empty box where the data is. There is
// nothing to fix at the widget level; the summary has to be authored.
//
// **Computed from the plotted series, never written by hand.** The epic says so
// and the reason is the one this whole project keeps meeting: a hand-written
// summary and a painted chart are two representations that drift, and the
// drifted one is the one nobody can see. Same list in, same sentence out.
//
// The summary is a RANGE, a DIRECTION and a COUNT, and deliberately not a
// per-point reading. §17 asks for "a screen-reader summary and an accessible
// data table behind one control" — a traversal of forty points is neither, and
// it is how a chart becomes something a screen-reader user swipes past.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// Which way a series is going.
enum SeriesTrend {
  /// The last value is meaningfully lower than the first.
  down,

  /// Meaningfully higher.
  up,

  /// Neither, within the noise floor.
  flat,
}

/// The facts a summary sentence is built from.
///
/// A value type rather than a string, so the presentation edge can render it
/// through ARB in six locales — a sentence assembled here would be English word
/// order in five languages that do not share it, and three that read the other
/// way.
@immutable
class ChartSummary with ValueEquality {
  /// Creates a summary.
  const ChartSummary({
    required this.count,
    required this.first,
    required this.last,
    required this.lowest,
    required this.highest,
  });

  /// How many points are plotted.
  final int count;

  /// The oldest plotted value.
  final double first;

  /// The newest.
  final double last;

  /// The best and worst, which a chart shows as position and a summary must
  /// say — §12 marks them on the line, and a mark is not announced.
  final double lowest;

  /// The highest plotted value.
  final double highest;

  /// Which way it is going.
  ///
  /// DERIVED, not stored. It is a function of [first], [last], [lowest] and
  /// [highest], and a constructor argument is a second place it can be set —
  /// which is the shape SPEC.md §2 forbids everywhere else in this app ("a
  /// stored due date survives an import and is then wrong forever"). A summary
  /// built by hand with `up` on a falling series would announce the opposite of
  /// what the chart draws, to the one user who cannot check.
  SeriesTrend get trend {
    final span = highest - lowest;
    final change = last - first;

    // Measured against the SPAN of the series rather than against the first
    // value. A 0.2 change is enormous on a series that moves by 0.3 and
    // nothing on one that moves by 4, and the fraction of the first value says
    // neither.
    if (span == 0 || change.abs() < span * kTrendNoiseFraction) {
      return SeriesTrend.flat;
    }
    return change < 0 ? SeriesTrend.down : SeriesTrend.up;
  }

  @override
  List<Object?> get props => [count, first, last, lowest, highest];
}

/// Anything below this fraction of the range is noise, not a trend.
///
/// Consumption wanders by a few percent between tanks for reasons that have
/// nothing to do with the car — a headwind, a cold morning, a different pump
/// cutting off early. Calling that "trending up" would be the app guessing in a
/// way that looks like fact, which SPEC.md §2 forbids, and it would be doing it
/// in the one channel the user cannot sanity-check against the picture.
const double kTrendNoiseFraction = 0.05;

/// The summary for a plotted series, or null when there is nothing to say.
///
/// Null rather than an empty summary for fewer than two points: one fill-up is
/// not a trend, and a sentence claiming otherwise is worse than silence. The
/// chart itself renders nothing below two points for the same reason.
ChartSummary? summariseSeries(List<double> values) {
  if (values.length < 2) return null;

  var lowest = values.first;
  var highest = values.first;
  for (final v in values) {
    if (v < lowest) lowest = v;
    if (v > highest) highest = v;
  }

  return ChartSummary(
    count: values.length,
    first: values.first,
    last: values.last,
    lowest: lowest,
    highest: highest,
  );
}
