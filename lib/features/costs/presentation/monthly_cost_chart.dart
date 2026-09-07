// SPEC.md §12's monthly stacked chart.
//
// "Stacked columns, one per calendar month, coloured by the groups above; one
// baseline, no value-axis labels — columns for shape, list for figures."
//
// Two rules shape the implementation:
//
// The painter DECIDES NOTHING. Bucketing, label thinning and scaling live in
// `monthly_chart_model.dart`, where they are asserted without a canvas. This
// file turns a `MonthlyChart` into rectangles and nothing else.
//
// The AXIS mirrors under RTL; the SERIES does not. §12's time axis runs right
// to left in fa/ar/ckb, so the oldest month sits at the right edge — but the
// stack order within a column is identical in both directions, because
// "insurance sits above fuel" is a fact about the data and not about reading
// direction. That distinction is the one the epic calls out as easy to get
// wrong, and it is why the model's column list is never reversed: only the
// laying-out is.
//
// Ticks are real `Text`, not glyphs painted onto the canvas, so a Persian
// locale renders Persian digits. A digit painted with `TextPainter` from a
// raw string would be Latin forever.
import 'package:flutter/material.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_shapes.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// How tall the columns are, before their labels.
const double kMonthlyChartHeight = 96;

/// §12's stacked monthly chart.
class MonthlyCostChart extends StatelessWidget {
  /// Creates the chart.
  const MonthlyCostChart({
    required this.chart,
    required this.labelFor,
    super.key,
  });

  /// What the model decided.
  final MonthlyChart chart;

  /// One column's tick, already localised and digit-shaped by the caller.
  final String Function(MonthlyChartColumn) labelFor;

  @override
  Widget build(BuildContext context) {
    if (chart.shape != MonthlyChartShape.columns) {
      return const SizedBox.shrink();
    }

    // A plain `Row` of columns. Flutter lays a `Row` out from the START edge,
    // which under RTL is the right — so the axis mirrors for free and the
    // model's oldest-first list stays oldest-first. Reversing the list would
    // mirror the axis AND the series, which is the bug.
    // NO fixed outer height. The bar band is constant — every column
    // reserves `kMonthlyChartHeight` whatever its own value — and the label
    // takes whatever the text needs, which at 200% text scale is more than a
    // guessed constant. A fixed outer height overflowed by three pixels at
    // 1.0x and would have overflowed by far more at 2.0x.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final column in chart.columns)
          Expanded(
            child: _Column(column: column, label: labelFor(column)),
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.column, required this.label});

  final MonthlyChartColumn column;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final shapes = CalmShapes.of(context);
    final space = CalmSpace.of(context);
    final type = CalmType.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: space.s1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The BAND is constant and the fill inside it is the fraction, so
          // every column shares one baseline. Sizing the box itself to the
          // fraction would let short months float, and a chart whose baseline
          // moves is not a comparison.
          SizedBox(
            height: kMonthlyChartHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                // `widthFactor: 1` is load-bearing. Without it the box takes
                // the incoming LOOSE width, and a `ColoredBox` with no child
                // collapses to zero — so the columns were laid out, measured,
                // and painted nothing. The parity capture showed the ticks
                // under an empty band, which is exactly what that looks like.
                widthFactor: 1,
                heightFactor: column.heightFraction.clamp(0.0, 1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(shapes.radiusSm),
                  child: Column(
                    // STRETCH, so each segment fills the column's width. A
                    // `Column` centres by default, which gives its children
                    // loose horizontal constraints — and a `ColoredBox` with
                    // no child collapses to zero width under those. The bars
                    // were being laid out and measured at 0 x 77, which is
                    // why the parity capture showed ticks under an empty band.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bottom-first in the MODEL, so the visual stack is
                      // built top-first here — a `Column` lays out downwards.
                      for (final segment in column.segments.reversed)
                        Expanded(
                          flex: segment.amount.amountMinor,
                          child: ColoredBox(
                            color: monthlyChartColour(context, segment.row),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: space.s2),
          // Real text, so the digits shape. `Opacity` rather than an empty
          // string for an unlabelled column, so every column reserves the same
          // height and the baseline does not step.
          Opacity(
            opacity: column.isLabelled ? 1 : 0,
            child: Text(
              label,
              maxLines: 1,
              style: type.caption.copyWith(color: colors.chartAxisInk),
            ),
          ),
        ],
      ),
    );
  }
}

/// The colour for a category's segment.
///
/// Read through `CalmColors.of(context)` — every one of them a token. A raw
/// hex here would fail the parity colour gate later, on a screen whose author
/// has moved on and cannot explain it.
///
/// ONE switch, and the category list reads it too. Each row gets its own hue
/// because six bars in one colour is a length comparison with nothing to
/// anchor each length to — and the correspondence between the bar under a row
/// and the segment in the chart above it is the only legend the chart has. A
/// second copy of this switch is a seventh category, or a palette change,
/// applied in one place and not the other: silent, and visible only to a
/// human looking at both at once.
///
/// The design system gives five chart colours and §12 gives six rows, so the
/// catch-all takes the neutral axis ink rather than a sixth hue. It reads as
/// "everything else", which is what the row is — and `ink4` is not available
/// for this: it is the WCAG-failing placeholder colour, and
/// `calm_contrast_test.dart` confines it to the four files that need it.
Color monthlyChartColour(BuildContext context, CostCategoryRow row) {
  final colors = CalmColors.of(context);
  return switch (row) {
    CostCategoryRow.fuel => colors.chart1,
    CostCategoryRow.service => colors.chart2,
    CostCategoryRow.insuranceAndTax => colors.chart3,
    CostCategoryRow.finance => colors.chart4,
    CostCategoryRow.parkingAndTolls => colors.chart5,
    CostCategoryRow.other => colors.chartAxisInk,
  };
}
