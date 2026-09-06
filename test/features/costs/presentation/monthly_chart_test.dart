// SPEC.md §12's chart, as it renders.
//
// The assertion the epic singles out — "this is the one people get wrong" —
// is the RTL one: the AXIS mirrors and the SERIES does not. The oldest month
// moves to the right edge, and the stack order inside every column stays
// identical, because "insurance sits above fuel" is a fact about the data
// rather than about reading direction.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/features/costs/presentation/monthly_cost_chart.dart';

import '../../../support/pump_app.dart';

final Currency eur = Currency.tryParse('EUR')!;

MonthKey month(int m) =>
    MonthKey(calendar: CalmCalendar.gregorian, year: 2026, month: m);

MonthlyChart chartOf(int count) => buildMonthlyChart(
  points: [
    for (var i = 0; i < count; i++)
      MonthlyCostPoint(
        month: month(i + 1),
        amounts: {
          CostCategoryRow.fuel: Money(10000 + i * 500, eur),
          CostCategoryRow.service: Money(4000, eur),
        },
      ),
  ],
  currency: eur,
);

Future<void> pumpChart(
  WidgetTester tester,
  MonthlyChart chart, {
  Locale locale = const Locale('en'),
}) => pumpApp(
  tester,
  MonthlyCostChart(
    chart: chart,
    labelFor: (c) => '${c.month.month}',
  ),
  locale: locale,
);

/// The centre x of the column whose label is [label].
double centreOf(WidgetTester tester, String label) =>
    tester.getCenter(find.text(label).first).dx;

void main() {
  testWidgets('no chart is drawn below three months', (tester) async {
    await pumpChart(tester, chartOf(2));

    expect(find.byType(MonthlyCostChart), findsOneWidget);
    expect(find.text('1'), findsNothing, reason: 'rows, not columns');
  });

  testWidgets('three months draw three columns', (tester) async {
    await pumpChart(tester, chartOf(3));

    for (final label in ['1', '2', '3']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  group('the axis mirrors and the series does not', () {
    testWidgets('LTR puts the oldest month at the LESSER x', (tester) async {
      await pumpChart(tester, chartOf(6));

      expect(centreOf(tester, '1'), lessThan(centreOf(tester, '6')));
    });

    testWidgets('RTL puts the oldest month at the GREATER x', (tester) async {
      // The axis moves. This is the half people remember.
      await pumpChart(tester, chartOf(6), locale: const Locale('fa'));

      expect(centreOf(tester, '1'), greaterThan(centreOf(tester, '6')));
    });

    testWidgets('and the stack order is IDENTICAL in both', (tester) async {
      // The half people forget. Reversing the column list would mirror the
      // axis and the series together, so fuel would sit above insurance in
      // Persian — a different claim about the same data.
      List<Color> stackOf(WidgetTester tester) => tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(MonthlyCostChart),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          .take(2)
          .toList();

      await pumpChart(tester, chartOf(4));
      final ltr = stackOf(tester);

      await pumpChart(tester, chartOf(4), locale: const Locale('fa'));
      final rtl = stackOf(tester);

      expect(rtl, ltr, reason: 'same segments, same order, both directions');
    });
  });

  testWidgets('the stack is drawn bottom-first, as the model orders it', (
    tester,
  ) async {
    // The model lists segments BOTTOM first — fuel, then service, in enum
    // order. A `Column` lays out downwards, so the layout reverses them and
    // the TOPMOST box is the last segment.
    //
    // Comparing LTR against RTL cannot catch this: both are wrong together if
    // the reversal is dropped. Asserting which colour is on top is what pins
    // it, and dropping the `.reversed` puts fuel above service — a different
    // claim about the same money.
    late BuildContext context;
    await pumpApp(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return MonthlyCostChart(chart: chartOf(3), labelFor: (_) => 'x');
        },
      ),
    );

    final boxes = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MonthlyCostChart),
            matching: find.byType(ColoredBox),
          ),
        )
        .toList();

    expect(
      boxes.first.color,
      monthlyChartColour(context, CostCategoryRow.service),
      reason: 'service is above fuel, because fuel is the lower enum value',
    );
    expect(
      boxes[1].color,
      monthlyChartColour(context, CostCategoryRow.fuel),
    );
  });

  testWidgets('ticks are real text, so digits shape per locale', (
    tester,
  ) async {
    // A digit painted onto the canvas from a raw string would be Latin
    // forever. The label comes from the caller, already shaped — this asserts
    // it reaches the tree as TEXT rather than as paint.
    await pumpApp(
      tester,
      MonthlyCostChart(chart: chartOf(4), labelFor: (c) => '۱۲'),
      locale: const Locale('fa'),
    );

    expect(find.text('۱۲'), findsWidgets);
  });

  testWidgets('every colour the chart draws is a Calm token', (tester) async {
    // Read through `CalmColors.of(context)`. A raw hex here fails the parity
    // colour gate later, on a screen whose author has moved on.
    late BuildContext context;
    await pumpApp(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return MonthlyCostChart(chart: chartOf(4), labelFor: (_) => 'x');
        },
      ),
    );

    final tokens = {
      for (final row in CostCategoryRow.values)
        monthlyChartColour(context, row),
    };
    final drawn = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MonthlyCostChart),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((b) => b.color)
        .toSet();

    expect(
      drawn.difference(tokens),
      isEmpty,
      reason: 'no colour that is not one of the six token reads',
    );
  });

  testWidgets('an all-zero chart renders flat rather than throwing', (
    tester,
  ) async {
    final chart = buildMonthlyChart(
      points: [
        for (var i = 0; i < 4; i++)
          MonthlyCostPoint(
            month: month(i + 1),
            amounts: {CostCategoryRow.fuel: Money(0, eur)},
          ),
      ],
      currency: eur,
    );

    await pumpChart(tester, chart);

    expect(tester.takeException(), isNull);
  });
}
