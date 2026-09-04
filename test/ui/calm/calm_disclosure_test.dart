// A collapsed group that reveals its contents.
//
// SPEC.md §8 draws two on `vehicle.edit` — `▸ Purchase and sale` and
// `▸ This vehicle's units & currency` — and they are what keep a form with
// twenty fields from being a wall. The design supplies no component for it, so
// this composes one from a row rather than inventing an appearance.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/ui/calm/calm_disclosure.dart';
import 'package:odova/ui/calm/calm_list_row.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('it starts collapsed, and its contents are not in the tree', (
    tester,
  ) async {
    // Not merely invisible. A hidden-but-built subtree still runs its
    // controllers, still takes focus in a traversal, and still reports its
    // fields to a screen reader — so an `Offstage` here would be a form with
    // twenty invisible tab stops.
    await pumpApp(
      tester,
      const CalmDisclosure(
        title: 'Purchase and sale',
        children: [Text('Purchase date')],
      ),
    );

    expect(find.text('Purchase and sale'), findsOneWidget);
    // `skipOffstage: false` is the whole assertion. With the default, an
    // `Offstage` subtree is invisible to the finder and the test passes on a
    // form that built all fourteen fields and merely hid them — which is the
    // defect, not the fix.
    expect(
      find.text('Purchase date', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('tapping the header reveals and hides again', (tester) async {
    await pumpApp(
      tester,
      const CalmDisclosure(
        title: 'Purchase and sale',
        children: [Text('Purchase date')],
      ),
    );

    await tester.tap(find.text('Purchase and sale'));
    await tester.pumpAndSettle();
    expect(find.text('Purchase date'), findsOneWidget);

    await tester.tap(find.text('Purchase and sale'));
    await tester.pumpAndSettle();
    expect(find.text('Purchase date', skipOffstage: false), findsNothing);
  });

  testWidgets('the header announces as expandable, and says which way', (
    tester,
  ) async {
    // A row that opens something is not a row that navigates. Without the
    // expanded state a screen-reader user cannot tell whether tapping will
    // open or close it, and finds out by doing it.
    await pumpApp(
      tester,
      const CalmDisclosure(title: 'Units', children: [Text('Currency')]),
    );

    // A TRISTATE, and the distinction matters: `isFalse` means "expandable and
    // currently closed", while `isNotSet` would mean "not expandable at all" —
    // which is what a screen reader is told by a row that forgot the flag.
    expect(
      tester.getSemantics(find.text('Units')).flagsCollection.isExpanded,
      Tristate.isFalse,
    );

    await tester.tap(find.text('Units'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Units')).flagsCollection.isExpanded,
      Tristate.isTrue,
    );
  });

  testWidgets('the chevron points down when open and to the end when shut', (
    tester,
  ) async {
    // The disclosure chevron is one of the six glyphs Calm mirrors, so when it
    // is CLOSED it points toward the end edge and flips under RTL. Open, it
    // points down — a direction that has no handedness and must not flip.
    await pumpApp(
      tester,
      const CalmDisclosure(title: 'Units', children: [Text('Currency')]),
    );
    expect(
      tester.widget<CalmListRow>(find.byType(CalmListRow)).showChevron,
      isTrue,
    );

    await tester.tap(find.text('Units'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    // And the end-pointing one is GONE. Two chevrons on one row is a row
    // pointing two ways at once, and the mirroring one would still flip under
    // RTL while the down one did not.
    expect(
      tester.widget<CalmListRow>(find.byType(CalmListRow)).showChevron,
      isFalse,
    );
  });
}
