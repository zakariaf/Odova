// SPEC.md §12's consumption chart.
//
// The reference draws a LINE with a marker per tank, a dashed average, and a
// green/red marker on the best and worst — not the columns §12's prose
// suggests. The reference is the authority (the epics' inherited rule 4).
//
// The axis mirrors under RTL and the SERIES does not, exactly as the monthly
// chart: the oldest tank moves to the right edge, and the shape of the line is
// unchanged because "this tank was thirstier than that one" is a fact about
// the data. The painter is handed points in oldest-first order and a direction,
// and does the mirroring in ONE place — its x mapping.
import 'package:flutter/material.dart';
import 'package:odova/theme/calm/calm_colors.dart';

/// One tank on the chart.
typedef ConsumptionPoint = ({double value, bool isBest, bool isWorst});

/// §12's consumption-per-tank chart.
class ConsumptionLineChart extends StatelessWidget {
  /// Creates the chart.
  const ConsumptionLineChart({
    required this.points,
    required this.average,
    super.key,
  });

  /// The tanks, OLDEST FIRST. Never reversed — see the header.
  final List<ConsumptionPoint> points;

  /// The dashed line's value.
  final double average;

  @override
  Widget build(BuildContext context) {
    // §12: fewer than two segments is not a shape. The caller shows
    // `fuelFirstFigure` instead, which explains the absence rather than
    // leaving a blank that reads as a fault.
    if (points.length < 2) return const SizedBox.shrink();

    final colors = CalmColors.of(context);

    return SizedBox(
      height: kConsumptionChartHeight,
      child: CustomPaint(
        painter: ConsumptionLinePainter(
          points: points,
          average: average,
          // Every colour a TOKEN, read here where a `BuildContext` exists —
          // a painter cannot reach the theme, and a raw hex inside one is
          // exactly what the parity colour gate is for.
          line: colors.chart1,
          best: colors.chart2,
          worst: colors.danger,
          grid: colors.chartGrid,
          averageLine: colors.chartAxisInk,
          // The direction, resolved once. The painter maps x through it and
          // nothing else in the file knows about left or right.
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// How tall the plot is.
const double kConsumptionChartHeight = 160;

/// Draws §12's consumption line.
class ConsumptionLinePainter extends CustomPainter {
  /// Creates the painter.
  const ConsumptionLinePainter({
    required this.points,
    required this.average,
    required this.line,
    required this.best,
    required this.worst,
    required this.grid,
    required this.averageLine,
    required this.rtl,
  });

  /// Oldest first.
  final List<ConsumptionPoint> points;

  /// The dashed line's value.
  final double average;

  /// Token colours, resolved by the widget.
  final Color line;

  /// The best marker.
  final Color best;

  /// The worst marker.
  final Color worst;

  /// The gridlines.
  final Color grid;

  /// The dashed average.
  final Color averageLine;

  /// Whether the time axis runs right to left.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [for (final p in points) p.value];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    // A flat series still needs a band, or every point lands on one line and
    // the division below is by zero.
    final span = (hi - lo).abs() < 0.01 ? 1.0 : hi - lo;

    double y(double value) => size.height - ((value - lo) / span) * size.height;

    // The ONE place direction is applied. Everything above is oldest-first.
    double x(int i) {
      final t = points.length == 1 ? 0.5 : i / (points.length - 1);
      return (rtl ? 1 - t : t) * size.width;
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final gy = size.height * i / 2;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gridPaint);
    }

    final path = Path();
    for (final (i, p) in points.indexed) {
      final offset = Offset(x(i), y(p.value));
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // The dashed average. Unchanged by direction — a horizontal line has no
    // direction to mirror, and §12 says so explicitly.
    final avgY = y(average);
    // Hoisted. A `Paint` inside the dash loop is ~45 allocations per repaint
    // at phone width, and `custom-canvas-and-gestures` asks `paint()` to
    // allocate nothing.
    final avgPaint = Paint()
      ..color = averageLine
      ..strokeWidth = 1;
    for (var dx = 0.0; dx < size.width; dx += 8) {
      canvas.drawLine(
        Offset(dx, avgY),
        Offset((dx + 4).clamp(0, size.width), avgY),
        avgPaint,
      );
    }

    final bestPaint = Paint()..color = best;
    final worstPaint = Paint()..color = worst;
    for (final (i, p) in points.indexed) {
      if (!p.isBest && !p.isWorst) continue;
      canvas.drawCircle(
        Offset(x(i), y(p.value)),
        4,
        p.isBest ? bestPaint : worstPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ConsumptionLinePainter old) =>
      old.points != points ||
      old.average != average ||
      old.rtl != rtl ||
      old.line != line;
}
