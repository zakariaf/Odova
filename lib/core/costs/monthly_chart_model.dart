// SPEC.md §12's monthly chart, as a model.
//
// "Columns for shape, list for figures." Everything the chart DECIDES happens
// here — how many columns, which are labelled, how tall each is, and in what
// order a stack's segments sit. The painter draws what this returns and
// chooses nothing, which is what lets §12's volume table be asserted without a
// canvas.
//
// The table, verbatim:
//
//   0 months with cost   No chart
//   1–2 months           No chart; rows instead — "two columns are not a shape"
//   3–36 months          One column per month
//   over 36 months       One column per YEAR — 96 columns on a phone is a
//                        texture, not a chart
import 'package:meta/meta.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';

/// One month's costs, before the chart decides anything about them.
@immutable
class MonthlyCostPoint {
  /// Creates a point.
  const MonthlyCostPoint({required this.month, required this.amounts});

  /// Which month, in the user's calendar.
  final MonthKey month;

  /// What it cost, per category row.
  final Map<CostCategoryRow, Money> amounts;
}

/// Which of §12's three renderings applies.
enum MonthlyChartShape {
  /// Nothing to draw.
  none,

  /// One or two months: a list of `Aug 2026 · 214 €` rows.
  rows,

  /// Three or more: columns.
  columns,
}

/// One segment of a stacked column.
@immutable
class MonthlyChartSegment {
  /// Creates a segment.
  const MonthlyChartSegment({required this.row, required this.amount});

  /// Which category — the painter maps this to a colour.
  final CostCategoryRow row;

  /// Its share of the column.
  final Money amount;
}

/// One column.
@immutable
class MonthlyChartColumn {
  /// Creates a column.
  const MonthlyChartColumn({
    required this.month,
    required this.total,
    required this.segments,
    required this.heightFraction,
    required this.isLabelled,
  });

  /// The month, or the January of a bucketed year.
  final MonthKey month;

  /// The column's total.
  final Money total;

  /// Its stack, bottom first, in a FIXED order.
  final List<MonthlyChartSegment> segments;

  /// 0..1 against the tallest column.
  final double heightFraction;

  /// Whether the x axis prints a tick for it.
  final bool isLabelled;
}

/// Everything the painter needs.
@immutable
class MonthlyChart {
  /// Creates a chart.
  const MonthlyChart({
    required this.shape,
    required this.columns,
    required this.isBucketedByYear,
    required this.hasOtherCurrencies,
  });

  /// Which rendering §12's volume table selects.
  final MonthlyChartShape shape;

  /// The columns, oldest first. The AXIS mirrors under RTL; this list does
  /// not — reversing it would reverse what the series means.
  final List<MonthlyChartColumn> columns;

  /// Whether each column is a year rather than a month.
  final bool isBucketedByYear;

  /// Whether money in another currency was excluded, which §12 captions.
  final bool hasOtherCurrencies;
}

/// Above this many months, §12 buckets to one column per year.
const int kMonthlyChartBucketThreshold = 36;

/// Below this many months, §12 draws rows instead of columns.
const int kMonthlyChartMinimumColumns = 3;

/// Every month is labelled up to this many; beyond it, every third.
const int kMonthlyChartAllLabelsUpTo = 12;

/// §12's chart for [points], in ONE currency.
MonthlyChart buildMonthlyChart({
  required List<MonthlyCostPoint> points,
  required Currency currency,
}) {
  final hasOther = points.any(
    (p) => p.amounts.values.any(
      (m) => m.currency != currency && m.amountMinor > 0,
    ),
  );

  if (points.isEmpty) {
    return MonthlyChart(
      shape: MonthlyChartShape.none,
      columns: const [],
      isBucketedByYear: false,
      hasOtherCurrencies: hasOther,
    );
  }

  if (points.length < kMonthlyChartMinimumColumns) {
    return MonthlyChart(
      shape: MonthlyChartShape.rows,
      columns: _columnsFor(points, currency, labelEvery: 1),
      isBucketedByYear: false,
      hasOtherCurrencies: hasOther,
    );
  }

  final bucketed = points.length > kMonthlyChartBucketThreshold;
  final grouped = bucketed ? _byYear(points, currency) : points;

  return MonthlyChart(
    shape: MonthlyChartShape.columns,
    columns: _columnsFor(
      grouped,
      currency,
      // A bucketed chart is a handful of columns, and a year with no label is
      // a column nobody can place. Beyond twelve months, every third — §12's
      // rule, and thirty-six labels on a phone overlap into a grey band.
      labelEvery: bucketed || grouped.length <= kMonthlyChartAllLabelsUpTo
          ? 1
          : 3,
    ),
    isBucketedByYear: bucketed,
    hasOtherCurrencies: hasOther,
  );
}

List<MonthlyCostPoint> _byYear(
  List<MonthlyCostPoint> points,
  Currency currency,
) {
  final byYear = <int, Map<CostCategoryRow, int>>{};
  final calendars = <int, CalmCalendar>{};

  for (final p in points) {
    calendars[p.month.year] = p.month.calendar;
    final bucket = byYear.putIfAbsent(p.month.year, () => {});
    for (final entry in p.amounts.entries) {
      if (entry.value.currency != currency) continue;
      bucket.update(
        entry.key,
        (v) => v + entry.value.amountMinor,
        ifAbsent: () => entry.value.amountMinor,
      );
    }
  }

  final years = byYear.keys.toList()..sort();
  return [
    for (final year in years)
      MonthlyCostPoint(
        month: MonthKey(
          calendar: calendars[year] ?? CalmCalendar.gregorian,
          year: year,
          month: 1,
        ),
        amounts: {
          for (final e in byYear[year]!.entries)
            e.key: Money(e.value, currency),
        },
      ),
  ];
}

List<MonthlyChartColumn> _columnsFor(
  List<MonthlyCostPoint> points,
  Currency currency, {
  required int labelEvery,
}) {
  final totals = [
    for (final p in points)
      p.amounts.entries
          .where((e) => e.value.currency == currency)
          .fold<int>(0, (sum, e) => sum + e.value.amountMinor),
  ];

  final tallest = totals.fold<int>(0, (m, t) => t > m ? t : m);

  return [
    for (final (i, p) in points.indexed)
      MonthlyChartColumn(
        month: p.month,
        total: Money(totals[i], currency),
        // The stack is ordered by the ENUM, not by size. Ordering by amount
        // would move a colour up and down the stack from month to month, and
        // a colour that changes position stops meaning one thing.
        segments: [
          for (final row in CostCategoryRow.values)
            if ((p.amounts[row]?.currency == currency) &&
                (p.amounts[row]?.amountMinor ?? 0) > 0)
              MonthlyChartSegment(row: row, amount: p.amounts[row]!),
        ],
        // Guarded, because an all-zero range is a real state — a vehicle with
        // records but no cost in the window — and a division by zero here
        // would be an exception on a screen that should show flat columns.
        heightFraction: tallest == 0 ? 0 : totals[i] / tallest,
        isLabelled: i % labelEvery == 0,
      ),
  ];
}
