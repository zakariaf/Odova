// What the odometer strip announces when the number is a guess.
//
// SPEC.md §9 and §17. The strip is the one place on Home that always renders a
// figure, and when the reading is old that figure is projected — so it is also
// the place where "the app never guesses in a way that looks like fact" has to
// hold for somebody who cannot see the `~`.
@TestOn('vm')
library;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/features/home/ui/odometer_strip.dart';

import '../support/a11y_harness.dart';

OdometerEstimate estimate({required bool projected}) => OdometerEstimate(
  metres: 187400000,
  asOf: CivilDate.tryParse('2026-09-07')!,
  projection: projected
      ? OdometerProjection.projected
      : OdometerProjection.entered,
  staleDays: projected ? 13 : 0,
);

void main() {
  testWidgets('an estimated reading is announced as an estimate', (
    tester,
  ) async {
    await pumpA11y(
      tester,
      const A11yCase(),
      OdometerStrip(
        estimate: estimate(projected: true),
        unit: DistanceUnit.km,
        formatsTag: 'en',
        onTap: () {},
        onTapValue: () {},
      ),
    );

    final labels = tester.semantics.find(find.byType(OdometerStrip)).toString();

    expect(labels, contains('estimated'));
  });

  testWidgets('and the tilde is NOT read out', (tester) async {
    // The defect this test was written for. The strip built its label from the
    // already-marked string, so a screen reader announced "estimated, about
    // ~187,400 km" — the glyph the label exists to replace, read aloud in the
    // middle of the sentence that replaces it.
    await pumpA11y(
      tester,
      const A11yCase(),
      OdometerStrip(
        estimate: estimate(projected: true),
        unit: DistanceUnit.km,
        formatsTag: 'en',
        onTap: () {},
        onTapValue: () {},
      ),
    );

    expect(
      _allLabels(tester),
      everyElement(isNot(contains('~'))),
      reason: 'the mark is visual; the label says it in words',
    );
  });

  testWidgets('an ENTERED reading is not announced as an estimate', (
    tester,
  ) async {
    // The opposite error, and the same rule: calling a fact a guess is as
    // dishonest as calling a guess a fact.
    await pumpA11y(
      tester,
      const A11yCase(),
      OdometerStrip(
        estimate: estimate(projected: false),
        unit: DistanceUnit.km,
        formatsTag: 'en',
        onTap: () {},
        onTapValue: () {},
      ),
    );

    expect(_allLabels(tester), everyElement(isNot(contains('estimated'))));
  });
}

/// Every label in the tree, which is what a screen reader walks.
///
/// From the ROOT rather than from the widget's own node: a `CalmPressable`
/// inside the strip is its own button and therefore its own semantics node, so
/// asking the strip's node for its descendants misses exactly the part that
/// carries the estimate. A reader does not care which node a label hangs off.
List<String> _allLabels(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) out.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  final root =
      tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) walk(root);
  return out;
}
