// The chart, and what stands behind it for somebody who cannot see it.
//
// SPEC.md §17: a screen-reader summary and an accessible data table behind one
// control. The chart IS that control — §17's first row names "chart tap
// targets", so a chart is meant to be tappable and neither of Odova's was.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/chart_alternative.dart';

import '../support/a11y_harness.dart';

List<String> spoken(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) out.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  final handle = tester.ensureSemantics();
  // `pipelineOwner`, not `rootPipelineOwner` — see a11y_harness.dart.
  //
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) walk(root);
  handle.dispose();
  return out;
}

void main() {
  group('the chart', () {
    testWidgets('announces the summary instead of nothing', (tester) async {
      var opened = 0;
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: ChartAlternative(
            summaryLabel:
                'Consumption over 12 months, from 7.1 to 6.4 litres '
                'per 100 kilometres, trending down',
            onShowTable: () => opened++,
            // A painted chart. It exposes nothing on its own, which is the
            // whole reason this wrapper exists.
            child: const SizedBox(width: 300, height: 120),
          ),
        ),
      );

      expect(spoken(tester), anyElement(contains('trending down')));
      expect(opened, 0);
    });

    testWidgets('the painted child is NOT read as well', (tester) async {
      // §17: two representations of the same data must not both be read. What
      // leaks through an unexcluded chart is its axis labels — a bare run of
      // numbers with no idea what they measure.
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: ChartAlternative(
            summaryLabel: 'the summary',
            onShowTable: () {},
            child: const Text('7.1 6.9 7.4 6.4'),
          ),
        ),
      );

      expect(spoken(tester), isNot(anyElement(contains('7.1 6.9'))));
    });

    testWidgets('the whole painted area is the target, not just the ink', (
      tester,
    ) async {
      // A line chart is mostly empty space. Without `HitTestBehavior.opaque` a
      // tap between two points falls through, which is a target that measures
      // 300x120 and behaves like a few thin strokes.
      var opened = 0;
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: ChartAlternative(
            summaryLabel: 'the summary',
            onShowTable: () => opened++,
            child: const SizedBox(width: 300, height: 120),
          ),
        ),
      );

      await tester.tap(find.byType(ChartAlternative));
      expect(opened, 1);
    });

    testWidgets('clears the platform tap-target guidelines', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: ChartAlternative(
            summaryLabel: 'the summary',
            onShowTable: () {},
            child: const SizedBox(width: 300, height: 120),
          ),
        ),
      );

      await expectTapTargets(tester);
    });
  });

  group('the data table', () {
    testWidgets('announces each cell with its column', (tester) async {
      // A reader landing on a row must hear what the number measures. A table
      // read as a flat run of values is a table nobody can use.
      await pumpA11y(
        tester,
        const A11yCase(),
        const ChartDataTable(
          columnHeaders: ['Month', 'Consumption'],
          rows: [
            ['October', '6.4 l/100 km'],
            ['November', '6.9 l/100 km'],
          ],
        ),
      );

      final said = spoken(tester);
      expect(said, anyElement(contains('Month: October')));
      expect(said, anyElement(contains('Consumption: 6.4 l/100 km')));
    });

    testWidgets('a bare number is never announced on its own', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        const ChartDataTable(
          columnHeaders: ['Month', 'Consumption'],
          rows: [
            ['October', '6.4'],
          ],
        ),
      );

      expect(spoken(tester), isNot(anyElement(equals('6.4'))));
    });
  });
}
