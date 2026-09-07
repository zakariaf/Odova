// The non-visual half of a chart: a sentence, and a table behind one control.
//
// SPEC.md §17's gate: "Both charts have a non-visual alternative: a
// screen-reader summary and an accessible data table behind one control."
//
// **The chart IS the control.** §17's first row names "chart tap targets"
// alongside the odometer stepper, so a chart is meant to be tappable and today
// neither of Odova's is. Making the chart the control satisfies both rows at
// once and — the part that matters for `calm-visual-parity` — adds NO visible
// element, so `design/reference/calm/` still describes the app. A new segmented
// control on `costs` and `costs.fuel` would be a deliberate design change
// requiring eight re-shot references, and it would be inventing UI to satisfy a
// rule that did not ask for any.
//
// The table opens as a sheet rather than replacing the chart in place. Swapping
// in place changes the height of a card on a screen whose layout is referenced,
// and a taller table would overflow at 200% on the floor device — the exact
// failure §17's other row is about.
//
// The chart is `ExcludeSemantics` while this wrapper speaks for it. §17 is
// explicit that two representations of the same data must not both be read, and
// a `CustomPainter` announces nothing anyway — what would leak through is the
// axis labels, read as a bare run of numbers with no idea what they measure.
import 'package:flutter/material.dart';
import 'package:odova/ui/calm/chart_summary.dart';

/// Wraps a painted chart with the announcement and the table behind it.
class ChartAlternative extends StatelessWidget {
  /// Wraps [child].
  const ChartAlternative({
    required this.summaryLabel,
    required this.onShowTable,
    required this.child,
    super.key,
  });

  /// The one-sentence summary, already localised and numeral-shaped.
  ///
  /// Built by the caller from [ChartSummary] through ARB, because a sentence
  /// assembled here would carry English word order into five languages that do
  /// not share it and three that read the other way.
  final String summaryLabel;

  /// Opens the data table. The whole chart is the control.
  final VoidCallback onShowTable;

  /// The painted chart.
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: summaryLabel,
    button: true,
    // Named so a screen reader says "double tap to show the data table" rather
    // than "double tap to activate", which tells a user nothing about what is
    // behind a chart they cannot see.
    onTapHint: 'show the data table',
    onTap: onShowTable,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onShowTable,
      // Opaque, so the whole painted area is the target rather than only the
      // pixels the painter happened to cover — §17's 48x48 row names chart tap
      // targets, and a line chart is mostly empty space.
      behavior: HitTestBehavior.opaque,
      child: child,
    ),
  );
}

/// A chart's data as a table a screen reader can walk.
///
/// Rows and columns carry headers, because a reader announcing "6.4" with no
/// idea which month or what unit is a reader announcing noise. §17 asks for an
/// "accessible data table", and a `Table` of bare `Text` is not one.
class ChartDataTable extends StatelessWidget {
  /// Creates the table.
  const ChartDataTable({
    required this.columnHeaders,
    required this.rows,
    super.key,
  });

  /// The column names, already localised.
  final List<String> columnHeaders;

  /// One list per row, each the same length as [columnHeaders].
  final List<List<String>> rows;

  /// One row as `header: cell, header: cell`.
  ///
  /// A header past the end is `?` rather than a dropped cell: in release, where
  /// the assert above is compiled out, a ragged row must still announce every
  /// value it holds. Announcing "?: 6.4" is a visible defect; announcing
  /// nothing is an invisible one.
  String _labelFor(List<String> row) => [
    for (var i = 0; i < row.length; i++)
      '${i < columnHeaders.length ? columnHeaders[i] : '?'}: ${row[i]}',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    // A ragged row is a caller bug, and the version that clamped the loop to
    // `columnHeaders.length` DROPPED the extra cells — data missing from the
    // one representation a screen-reader user has, with nothing to notice. An
    // assert fails the caller's test instead of quietly shortening the table.
    assert(
      rows.every((r) => r.length == columnHeaders.length),
      'a row has a different number of cells than there are column headers, '
      'so the table would announce fewer values than the chart plots',
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Semantics(
              container: true,
              // Each CELL announces its own column, so a reader landing on
              // a row hears "October, 6.4 litres per 100 kilometres" rather
              // than a number whose meaning was two swipes ago. A table read
              // as a flat run of values is a table nobody can use.
              label: _labelFor(row),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    for (final cell in row) Expanded(child: Text(cell)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
