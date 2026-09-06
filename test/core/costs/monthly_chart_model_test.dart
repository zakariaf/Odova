// SPEC.md §12's monthly chart, as a pure model.
//
// "Columns for shape, list for figures." The painter draws and decides
// nothing: bucketing, label thinning and scaling all happen here, where they
// can be asserted without a canvas.
//
// The table §12 gives:
//
//   | 0 months with cost | No chart                                    |
//   | 1–2 months         | No chart; rows instead. Two columns are not  |
//   |                    | a shape.                                    |
//   | 3–36 months        | One column per month                        |
//   | over 36 months     | One column per YEAR — 96 columns on a phone  |
//   |                    | is a texture, not a chart.                   |
@TestOn('vm')
library;

import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:test/test.dart';

final Currency eur = Currency.tryParse('EUR')!;
final Currency gbp = Currency.tryParse('GBP')!;

MonthKey month(int year, int m) =>
    MonthKey(calendar: CalmCalendar.gregorian, year: year, month: m);

/// [count] consecutive months from 2024-01, each with one fuel amount.
List<MonthlyCostPoint> series(int count, {Currency? currency}) => [
  for (var i = 0; i < count; i++)
    MonthlyCostPoint(
      month: month(2024 + (i ~/ 12), i % 12 + 1),
      amounts: {
        CostCategoryRow.fuel: Money(10000 + i * 100, currency ?? eur),
      },
    ),
];

void main() {
  group('§12s volume table', () {
    test('no months with cost renders no chart', () {
      expect(
        buildMonthlyChart(points: const [], currency: eur).shape,
        MonthlyChartShape.none,
      );
    });

    test('one or two months render ROWS, not columns', () {
      // §12: "Two columns are not a shape." A chart of two bars asks the user
      // to read a trend from a single comparison.
      for (final n in [1, 2]) {
        expect(
          buildMonthlyChart(points: series(n), currency: eur).shape,
          MonthlyChartShape.rows,
          reason: '$n months',
        );
      }
    });

    test('three to thirty-six months render one column per month', () {
      for (final n in [3, 12, 36]) {
        final chart = buildMonthlyChart(points: series(n), currency: eur);

        expect(chart.shape, MonthlyChartShape.columns, reason: '$n months');
        expect(chart.columns, hasLength(n), reason: '$n months');
      }
    });

    test('over thirty-six months buckets to one column per YEAR', () {
      // 96 columns on a phone is a texture.
      final chart = buildMonthlyChart(points: series(48), currency: eur);

      expect(chart.shape, MonthlyChartShape.columns);
      expect(chart.columns, hasLength(4), reason: 'four years, not 48 months');
      expect(chart.isBucketedByYear, isTrue);
    });

    test('a bucketed year sums its months', () {
      final chart = buildMonthlyChart(points: series(48), currency: eur);
      final firstYear = chart.columns.first;

      // 2024: 10000 + 10100 + ... + 11100, twelve months.
      expect(
        firstYear.total.amountMinor,
        [for (var i = 0; i < 12; i++) 10000 + i * 100].reduce((a, b) => a + b),
      );
    });
  });

  group('label thinning', () {
    test('every month is labelled up to twelve', () {
      final chart = buildMonthlyChart(points: series(12), currency: eur);

      expect(chart.columns.where((c) => c.isLabelled), hasLength(12));
    });

    test('beyond twelve, every third month is labelled', () {
      // §12: "x labels every month to 12, then every third." Thirty-six
      // labels on a phone overlap into a grey band.
      final chart = buildMonthlyChart(points: series(24), currency: eur);
      final labelled = chart.columns.where((c) => c.isLabelled).length;

      expect(labelled, 8, reason: '24 / 3');
    });

    test('a year-bucketed chart labels every column', () {
      // There are at most a handful, and a year with no label is a column
      // nobody can place.
      final chart = buildMonthlyChart(points: series(60), currency: eur);

      expect(chart.columns.every((c) => c.isLabelled), isTrue);
    });
  });

  group('mixed currencies', () {
    test('only the requested currency is drawn', () {
      // §12: "Chart shows € only." A stacked column mixing two currencies is
      // a height that means nothing.
      final points = [
        MonthlyCostPoint(
          month: month(2024, 1),
          amounts: {CostCategoryRow.fuel: Money(10000, eur)},
        ),
        MonthlyCostPoint(
          month: month(2024, 2),
          amounts: {CostCategoryRow.fuel: Money(99999, gbp)},
        ),
        MonthlyCostPoint(
          month: month(2024, 3),
          amounts: {CostCategoryRow.fuel: Money(20000, eur)},
        ),
      ];

      final chart = buildMonthlyChart(points: points, currency: eur);

      expect(chart.columns, hasLength(3));
      expect(chart.columns[1].total.amountMinor, 0, reason: 'the GBP month');
      expect(chart.hasOtherCurrencies, isTrue);
    });

    test('and a single-currency chart says so', () {
      expect(
        buildMonthlyChart(points: series(6), currency: eur).hasOtherCurrencies,
        isFalse,
      );
    });
  });

  group('scaling', () {
    test('every column is a fraction of the tallest', () {
      final chart = buildMonthlyChart(points: series(6), currency: eur);

      expect(chart.columns.last.heightFraction, 1.0);
      expect(chart.columns.first.heightFraction, lessThan(1.0));
      expect(
        chart.columns.every((c) => c.heightFraction <= 1.0),
        isTrue,
      );
    });

    test('an all-zero chart does not divide by zero', () {
      final points = [
        for (var i = 0; i < 4; i++)
          MonthlyCostPoint(
            month: month(2024, i + 1),
            amounts: {CostCategoryRow.fuel: Money(0, eur)},
          ),
      ];

      final chart = buildMonthlyChart(points: points, currency: eur);

      expect(
        chart.columns.every((c) => c.heightFraction == 0),
        isTrue,
      );
    });

    test('a stack keeps its segments in a fixed order', () {
      // The order must not depend on which row happens to be largest in a
      // given month, or the same colour would move up and down the stack
      // across the chart and stop meaning one thing.
      final points = [
        MonthlyCostPoint(
          month: month(2024, 1),
          amounts: {
            CostCategoryRow.service: Money(9000, eur),
            CostCategoryRow.fuel: Money(1000, eur),
          },
        ),
        MonthlyCostPoint(
          month: month(2024, 2),
          amounts: {
            CostCategoryRow.fuel: Money(9000, eur),
            CostCategoryRow.service: Money(1000, eur),
          },
        ),
        MonthlyCostPoint(
          month: month(2024, 3),
          amounts: {CostCategoryRow.fuel: Money(5000, eur)},
        ),
      ];

      final chart = buildMonthlyChart(points: points, currency: eur);

      expect(
        chart.columns[0].segments.map((s) => s.row).toList(),
        chart.columns[1].segments.map((s) => s.row).toList(),
        reason: 'the same order regardless of which is larger',
      );
    });

    test('a zero segment is dropped from the stack', () {
      final points = [
        MonthlyCostPoint(
          month: month(2024, 1),
          amounts: {
            CostCategoryRow.fuel: Money(5000, eur),
            CostCategoryRow.finance: Money(0, eur),
          },
        ),
      ];

      final chart = buildMonthlyChart(points: points, currency: eur);
      expect(chart.columns.single.segments, hasLength(1));
    });
  });
}
