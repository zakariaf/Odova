// What a due card says to somebody who cannot see it.
//
// SPEC.md §17's gate: no state may be conveyed by colour alone. A due card is
// the app's whole answer to "what does my car need next", and its state — ok,
// due soon, due, overdue, unknown, needs a reading — is carried visually by a
// tint, a dot and a ramp. None of those is announced.
//
// The card's own copy is what makes this survivable: `due_copy.dart` builds a
// status line that SAYS the state in words. So the assertion is not "add a
// label" but "the words are actually in the announcement", which is a different
// and weaker-looking claim that happens to be the one that matters.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/ui/calm/calm_due_card.dart';

import '../support/a11y_harness.dart';

CalmDueView view({
  DueState state = DueState.due,
  String title = 'Oil and filter',
  String statusLine = 'Due now',
  String? anchorLine = 'Was due at 186,512 km',
  String? snoozeLine,
}) => CalmDueView(
  state: state,
  driver: DueDriver.distance,
  confidence: RateConfidence.measured,
  title: title,
  statusLine: statusLine,
  actionLabel: 'Log it',
  anchorLine: anchorLine,
  snoozeLine: snoozeLine,
  progress: 0.7,
);

List<String> labels(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) out.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  // `ensureSemantics` FIRST. Without a live handle the semantics tree is not
  // built at all, so a walk finds nothing and the test reports "announces
  // nothing" for a widget that announces perfectly well. A harness that fails
  // for its own reasons is worse than one that does not run.
  final handle = tester.ensureSemantics();
  // `pipelineOwner`, not `rootPipelineOwner`. The newer one's `semanticsOwner`
  // is NULL in a widget test even with a live handle, so a walk from it finds
  // nothing and reports "this widget announces nothing" for one that announces
  // perfectly well. That false negative is worse than no sweep: it sends
  // somebody to fix a screen that was already correct, and it would have
  // reported every screen in the app as broken.
  //
  // Deprecated in favour of interacting with SemanticsBinding, which has no
  // equivalent whole-tree read. Revisit when it does.
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) walk(root);
  handle.dispose();
  return out;
}

Future<void> pumpCard(WidgetTester tester, CalmDueView v) => pumpA11y(
  tester,
  const A11yCase(),
  Center(
    child: CalmDueCard(
      view: v,
      density: CalmDueDensity.primary,
      onTap: () {},
      onAction: () {},
    ),
  ),
);

void main() {
  testWidgets('announces the item, its state and its anchor', (tester) async {
    await pumpCard(tester, view());
    final said = labels(tester).join(' | ');

    expect(said, contains('Oil and filter'));
    expect(said, contains('Due now'), reason: 'the state, in words');
    expect(said, contains('186,512'), reason: 'the anchor a user acts on');
  });

  testWidgets('never reads as "card, button" with the meaning left out', (
    tester,
  ) async {
    // The failure mode this test exists for: a tappable container announced by
    // its role instead of its content, which is what a bare `InkWell` gives.
    await pumpCard(tester, view());

    expect(
      labels(tester).where((l) => l.trim().isNotEmpty),
      isNotEmpty,
      reason: 'the card announced nothing at all',
    );
  });

  testWidgets('every DueState is announced in words, not only as a colour', (
    tester,
  ) async {
    // §17's rule stated over the whole enum rather than one example. The words
    // come from the status line, which `due_copy.dart` builds per state — so
    // this fails the day somebody renders a state with an empty line and lets
    // the tint carry it.
    for (final state in DueState.values) {
      await pumpCard(
        tester,
        view(state: state, statusLine: 'state is ${state.name}'),
      );
      expect(
        labels(tester).join(' | '),
        contains(state.name),
        reason: '${state.name} is not in the announcement',
      );
    }
  });

  testWidgets('a snoozed item keeps its state AND says it is snoozed', (
    tester,
  ) async {
    // SPEC.md §4.7.2: snoozing "does not change the due date, the interval, the
    // overdue state, or the item's red treatment". A reader that heard only
    // "snoozed" would lose the fact that it is still overdue.
    await pumpCard(
      tester,
      view(
        state: DueState.overdue,
        statusLine: 'Overdue by 2 weeks',
        snoozeLine: 'Snoozed until 12 October',
      ),
    );
    final said = labels(tester).join(' | ');

    expect(said, contains('Overdue by 2 weeks'));
    expect(said, contains('Snoozed until 12 October'));
  });

  testWidgets('no confidence tier, percentage or bar is announced', (
    tester,
  ) async {
    // §1.4: "Never show a confidence percentage, a bar, or the word
    // `measured`." The hedging is in the words, because under the no-analytics
    // rule the real error will never be measured — so it must never be implied
    // by a number, including one only a screen reader hears.
    await pumpCard(tester, view());
    final said = labels(tester).join(' | ').toLowerCase();

    for (final banned in ['measured', 'assumed', 'confidence', '%']) {
      expect(said, isNot(contains(banned)), reason: banned);
    }
  });
}
