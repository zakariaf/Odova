// Swipe-to-reveal row actions.
//
// SPEC.md §8: "Swipe (end actions) — **Mark as sold** (amber), **Delete**
// (red). Declared as `endActions`; the physical direction flips in RTL."
//
// The word ENDACTIONS is the whole design. A component that took
// `rightActions` would put Delete under the user's thumb in English and under
// their other thumb in Arabic, and half the shipped locales are right-to-left.
// The declaration is logical; the physics follow the reading direction.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_space.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';

import '../../support/pump_app.dart';

/// Drags the row [dx] logical pixels horizontally and settles.
Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(find.text('The Golf'), Offset(dx, 0));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  Locale? locale,
  VoidCallback? onDelete,
  double height = 76,
}) => pumpApp(
  tester,
  Material(
    child: CalmSwipeActions(
      endActions: [
        CalmSwipeAction(
          label: 'Mark as sold',
          icon: Icons.sell_outlined,
          tone: CalmSwipeTone.caution,
          onPressed: () {},
        ),
        CalmSwipeAction(
          label: 'Delete',
          icon: Icons.delete_outline,
          tone: CalmSwipeTone.danger,
          onPressed: onDelete ?? () {},
        ),
      ],
      child: SizedBox(height: height, child: const Text('The Golf')),
    ),
  ),
  locale: locale,
);

void main() {
  testWidgets('at rest the row shows nothing but itself', (tester) async {
    // A row that leaks a red edge is a row that looks broken. The actions exist
    // only once the user has asked for them.
    await _pump(tester);
    expect(find.text('The Golf'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Mark as sold'), findsNothing);
  });

  testWidgets('in LTR the actions come from the right edge', (tester) async {
    await _pump(tester);
    await _swipe(tester, -200);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Mark as sold'), findsOneWidget);
    // Delete is the FURTHEST from the row's content — SPEC.md §8 lists Mark as
    // sold first, and the most destructive action is the hardest to reach.
    expect(
      tester.getCenter(find.text('Delete')).dx,
      greaterThan(tester.getCenter(find.text('Mark as sold')).dx),
    );
  });

  testWidgets('in RTL the physical direction flips, and the order with it', (
    tester,
  ) async {
    // The reason `endActions` is a logical name. Under Arabic the end edge is
    // on the LEFT, so the same declaration reveals from the left — and Delete
    // is still the outermost action, which now means the leftmost.
    await _pump(tester, locale: const Locale('ar'));
    await _swipe(tester, 200);
    expect(find.text('Delete'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Delete')).dx,
      lessThan(tester.getCenter(find.text('Mark as sold')).dx),
    );
  });

  testWidgets('swiping the WRONG way reveals nothing', (tester) async {
    // There are no start actions on this row. A drag toward the start edge must
    // do nothing at all rather than rubber-band something into view.
    await _pump(tester);
    await _swipe(tester, 200);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('tapping an action runs it and closes the row', (tester) async {
    var deleted = 0;
    await _pump(tester, onDelete: () => deleted++);
    await _swipe(tester, -200);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(find.text('Delete'), findsNothing, reason: 'the row closed');
  });

  testWidgets('an action is at least a 52pt target', (tester) async {
    // `--touch-min: 52px`, not Material's 48. SPEC.md §1: this happens at a
    // fuel pump, in the rain, one-handed.
    await _pump(tester);
    await _swipe(tester, -200);
    final min = CalmSpace.of(
      tester.element(find.byType(CalmSwipeActions)),
    ).touchMin;
    for (final label in ['Delete', 'Mark as sold']) {
      final size = tester.getSize(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(CalmSwipeActionButton),
        ),
      );
      expect(size.height, greaterThanOrEqualTo(min), reason: label);
      expect(size.width, greaterThanOrEqualTo(min), reason: label);
    }
  });

  testWidgets('every action is reachable without a swipe', (tester) async {
    // A swipe is a gesture a screen-reader user does not make, and TalkBack's
    // and VoiceOver's swipes are already taken by navigation. Without custom
    // actions on the row, Delete would be unreachable to them — SPEC.md §17,
    // and `accessibility-as-code`'s rule that a gesture is never the only path.
    await _pump(tester);
    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.byType(CalmSwipeActions));
    expect(
      node.getSemanticsData().customSemanticsActionIds,
      isNotNull,
      reason: 'no custom actions at all',
    );
    final labels = [
      for (final id in node.getSemanticsData().customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label!,
    ];
    expect(labels, containsAll(['Mark as sold', 'Delete']));
    handle.dispose();
  });

  testWidgets('a half-hearted swipe springs back', (tester) async {
    // Below the threshold the row returns to rest. A row left ajar is a row
    // whose next tap lands on Delete.
    await _pump(tester);
    await _swipe(tester, -20);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('the ROW is what moves, toward the start edge, in both', (
    tester,
  ) async {
    // The actions do not move — they sit behind and the row slides off them,
    // which is what makes the reveal read as uncovering rather than pushing.
    // So asserting where the ACTIONS are cannot see a row sliding the wrong
    // way, and a version that ignored `Directionality` here passed every other
    // test in this file.
    await _pump(tester);
    final ltrRest = tester.getTopLeft(find.text('The Golf')).dx;
    await _swipe(tester, -200);
    expect(
      tester.getTopLeft(find.text('The Golf')).dx,
      lessThan(ltrRest),
      reason: 'LTR: the row moves left, uncovering the right edge',
    );

    await _pump(tester, locale: const Locale('ar'));
    final rtlRest = tester.getTopLeft(find.text('The Golf')).dx;
    await _swipe(tester, 200);
    expect(
      tester.getTopLeft(find.text('The Golf')).dx,
      greaterThan(rtlRest),
      reason: 'RTL: the end edge is on the LEFT, so the row moves right',
    );
  });

  testWidgets('the action width clears the touch floor on its own', (
    tester,
  ) async {
    // The height is the ROW's — these are stretched behind it — so the only
    // dimension this component decides is the width, and 88 has to clear
    // `--touch-min` without help. A `minHeight` here cannot bind, which is why
    // there is not one: a mutation setting it to zero passed every test in this
    // file, and a constraint nobody would notice removing is a comment.
    //
    // The other half of the pairing is Calm's own floor: the shortest row is
    // `CalmRowSize.compact` at 56, above the 52 this needs.
    await _pump(tester);
    final min = CalmSpace.of(
      tester.element(find.byType(CalmSwipeActions)),
    ).touchMin;
    expect(kCalmSwipeActionWidth, greaterThanOrEqualTo(min));
    expect(kCalmCompactRowHeight, greaterThanOrEqualTo(min));
  });
}
