// SPEC.md §12's `costs.fuel`. Thin by decision — see CLAUDE.md §6a.
//
// The cases kept are the ones where being wrong is silent: consumption to one
// decimal, the chart's RTL mapping, and the absence that §3 explains rather
// than leaving blank.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/fuel/presentation/consumption_line_chart.dart';
import 'package:odova/features/fuel/presentation/fuel_screen.dart';

import '../../../support/pump_app.dart';

void main() {
  group('consumption renders to one decimal', () {
    // §12: "the measurement is not good enough for two." A second decimal
    // invites the reader to compare 6.42 with 6.47 as though the difference
    // meant something — it is noise from a hand-typed odometer and a pump
    // that rounds.
    test('6.4499 is 6.4, not 6.45', () {
      expect(consumptionText('en', 6.4499), '6.4');
    });

    test('and a missing figure is a dash, never a zero', () {
      // Zero L/100 km is a claim that the car uses no fuel.
      expect(consumptionText('en', null), '—');
    });
  });

  group('the chart mirrors its axis, not its series', () {
    const points = [
      (value: 6.0, isBest: true, isWorst: false),
      (value: 7.0, isBest: false, isWorst: false),
      (value: 8.0, isBest: false, isWorst: true),
    ];

    testWidgets('the painter is told the direction, once', (tester) async {
      // The whole file has exactly one place that knows about left and right,
      // and it is the painter's x mapping. This asserts the flag reaches it.
      for (final (locale, expected) in [
        (const Locale('en'), false),
        (const Locale('fa'), true),
      ]) {
        await pumpApp(
          tester,
          const ConsumptionLineChart(points: points, average: 7),
          locale: locale,
        );

        final painter =
            tester
                    .widget<CustomPaint>(
                      find
                          .descendant(
                            of: find.byType(ConsumptionLineChart),
                            matching: find.byType(CustomPaint),
                          )
                          .first,
                    )
                    .painter!
                as ConsumptionLinePainter;

        expect(painter.rtl, expected, reason: '$locale');
        expect(
          painter.points,
          points,
          reason: 'the series is NEVER reversed, in either direction',
        );
      }
    });

    testWidgets('one tank is not a shape and draws nothing', (tester) async {
      // §3: a single segment has no trend to show, and two points is the
      // minimum a line can express.
      await pumpApp(
        tester,
        const ConsumptionLineChart(
          points: [(value: 6.0, isBest: true, isWorst: true)],
          average: 6,
        ),
      );

      // `pumpApp` wraps the tree in framework widgets that paint, so the
      // assertion is that OUR painter is absent rather than that no
      // `CustomPaint` exists anywhere.
      expect(
        find.descendant(
          of: find.byType(ConsumptionLineChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('a flat series does not divide by zero', (tester) async {
      await pumpApp(
        tester,
        const ConsumptionLineChart(
          points: [
            (value: 6.0, isBest: true, isWorst: false),
            (value: 6.0, isBest: false, isWorst: true),
          ],
          average: 6,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
