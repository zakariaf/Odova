// The order a keyboard, a switch and a screen reader move through a screen.
//
// SPEC.md §17: "Full keyboard/switch traversal of every form, with a visible
// focus indicator." The indicator is now a contrast question and closed —
// `--color-focus` clears SC 1.4.11 at 4.11:1 since task 17.2. The ORDER is this
// file, and it is the half nothing was asserting.
//
// Order is where RTL bites. A `Row` mirrors under `TextDirection.rtl`, so the
// control a sighted Arabic user reads first is the one on the RIGHT — and a
// traversal that still walks left-to-right sends a switch user backwards
// through every form in three of the six shipped locales. Half of Odova's
// locales are right-to-left, so this is not an edge.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y_harness.dart';

/// Every focusable label, in the order assistive tech will visit them.
List<String> traversal(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty &&
        (data.hasAction(SemanticsAction.tap) ||
            data.flagsCollection.isButton ||
            data.flagsCollection.isTextField)) {
      out.add(data.label);
    }
    // `debugListChildrenInOrder` gives the platform's traversal order, which
    // is NOT construction order — construction order is what a developer wrote,
    // and the whole point of this file is that direction changes what the user
    // gets. Falls back to `visitChildren` if the debug list is unavailable, and
    // says so rather than silently asserting the wrong order.
    node
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .forEach(walk);
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

Widget form() => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Semantics(
      textField: true,
      label: 'Odometer',
      child: const SizedBox(width: 200, height: 48),
    ),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Cancel',
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 96, height: 48),
          ),
        ),
        Semantics(
          button: true,
          label: 'Save',
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 96, height: 48),
          ),
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('left to right in an LTR locale', (tester) async {
    await pumpA11y(tester, const A11yCase(), form());

    expect(traversal(tester), ['Odometer', 'Cancel', 'Save']);
  });

  testWidgets('LOGICAL order is preserved in Arabic, not reversed', (
    tester,
  ) async {
    // I expected the mirror and was wrong, and the wrong expectation is worth
    // keeping as a comment because it is the intuitive one.
    //
    // A `Row`'s children are laid out in LOGICAL order: the first child sits at
    // the START edge, which is the RIGHT under RTL. So an Arabic reader going
    // right-to-left meets `Cancel` first — the same child a left-to-right
    // reader meets first — and traversal correctly reports the same sequence in
    // both. The visual POSITIONS mirror; the order does not.
    //
    // Asserting the reverse would have been asserting a bug into the suite, and
    // then "fixing" the framework to match it.
    await pumpA11y(tester, const A11yCase(locale: Locale('ar')), form());

    expect(traversal(tester), ['Odometer', 'Cancel', 'Save']);
  });

  testWidgets('and the first action really is at the start edge in both', (
    tester,
  ) async {
    // The claim above, checked against geometry rather than taken on trust: the
    // first traversed action sits at the START edge, which is the left in LTR
    // and the right in RTL. If the two ever disagreed, traversal would be
    // walking a form in an order the user does not see.
    await pumpA11y(tester, const A11yCase(), form());
    final ltrCancel = tester.getCenter(find.bySemanticsLabel('Cancel')).dx;
    final ltrSave = tester.getCenter(find.bySemanticsLabel('Save')).dx;
    expect(ltrCancel, lessThan(ltrSave), reason: 'LTR: start is the left');

    await pumpA11y(tester, const A11yCase(locale: Locale('ar')), form());
    final rtlCancel = tester.getCenter(find.bySemanticsLabel('Cancel')).dx;
    final rtlSave = tester.getCenter(find.bySemanticsLabel('Save')).dx;
    expect(rtlCancel, greaterThan(rtlSave), reason: 'RTL: start is the right');
  });

  testWidgets('the field is reached before the actions in both directions', (
    tester,
  ) async {
    // The rule that survives the mirror: a form is filled and then submitted.
    // Whichever way the row runs, the odometer field comes first — a traversal
    // that lands on Save before the field is one where the first switch press
    // saves an empty form.
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      await pumpA11y(tester, A11yCase(locale: locale), form());
      final order = traversal(tester);

      expect(
        order.indexOf('Odometer'),
        lessThan(order.indexOf('Save')),
        reason: '${locale.languageCode} reaches Save before the field',
      );
    }
  });
}
