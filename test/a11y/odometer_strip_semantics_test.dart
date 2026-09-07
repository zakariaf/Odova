// What the odometer strip announces when the number is a guess.
//
// SPEC.md §9 and §17. The strip is the one place on Home that always renders a
// figure, and when the reading is old that figure is projected — so it is also
// the place where "the app never guesses in a way that looks like fact" has to
// hold for somebody who cannot see the `~`.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
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
      spokenLabels(tester),
      everyElement(isNot(contains('~'))),
      reason: 'the mark is visual; the label says it in words',
    );
  });

  group('EstimatedValueText on its own, which is how the tiles use it', () {
    // The strip's root `Semantics` swallows this widget's own announcement, so
    // every assertion above passes whatever it says. A mutation putting the
    // MARKED figure back into its label survived the whole file — and this
    // widget's doc says it is "shared by the strip, the glance tiles and the
    // cards", where nothing swallows anything.
    //
    // So it is pumped standalone here, which is the shape the next caller has.
    testWidgets('announces the estimate WITHOUT its tilde', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: EstimatedValueText(
            estimate: estimate(projected: true),
            unit: DistanceUnit.km,
            formatsTag: 'en',
          ),
        ),
      );

      final said = spokenLabels(tester);
      expect(said, anyElement(contains('estimated')));
      expect(said, everyElement(isNot(contains('~'))));
    });

    testWidgets('announces an entered reading as itself', (tester) async {
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: EstimatedValueText(
            estimate: estimate(projected: false),
            unit: DistanceUnit.km,
            formatsTag: 'en',
          ),
        ),
      );

      expect(spokenLabels(tester), everyElement(isNot(contains('estimated'))));
    });
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

    expect(spokenLabels(tester), everyElement(isNot(contains('estimated'))));
  });

  testWidgets('the estimate popover is reachable without sight', (
    tester,
  ) async {
    // The half of §9 the one-utterance wrapper deleted. `excludeSemantics` on
    // the root collapses the strip to a single node, which is what a reader
    // wants for the sentence — and it took the inner `CalmPressable` with it,
    // so a TalkBack user who double-tapped the strip got the odometer entry
    // modal and the EXPLANATION for the guess existed for sighted users only.
    var explained = 0;
    var entered = 0;
    await pumpA11y(
      tester,
      const A11yCase(),
      OdometerStrip(
        estimate: estimate(projected: true),
        unit: DistanceUnit.km,
        formatsTag: 'en',
        onTap: () => entered++,
        onTapValue: () => explained++,
      ),
    );

    final node = tester.semantics.find(find.byType(OdometerStrip));
    final actions =
        node.getSemanticsData().customSemanticsActionIds ?? const [];
    expect(
      actions,
      hasLength(1),
      reason: 'no custom action, so the popover has no way in',
    );

    final action = CustomSemanticsAction.getAction(actions.first)!;
    expect(action.label, isNotEmpty);

    performCustomAction(tester, node, actions.first);
    await tester.pump();

    expect(explained, 1, reason: 'the action did not open the popover');
    expect(entered, 0, reason: 'it opened the entry modal instead');
  });

  testWidgets('an entered reading offers no popover action', (tester) async {
    // §9: a plain reading has nothing to explain. An action a reader is
    // offered and that opens a sentence about a guess that was never made is
    // the same defect pointed the other way.
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

    final data = tester.semantics
        .find(find.byType(OdometerStrip))
        .getSemanticsData();
    expect(data.customSemanticsActionIds ?? const [], isEmpty);
  });
}
