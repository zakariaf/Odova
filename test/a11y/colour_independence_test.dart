// Every state readable with the colour taken away.
//
// SPEC.md §17's gate and WCAG 1.4.1: colour must never be the ONLY way a piece
// of information is conveyed. Odova's whole home screen is a colour ramp — a
// red card, an amber card, a grey one — so this is the rule the design is most
// exposed to.
//
// The test does not simulate a colour-vision deficiency. Simulation asks "can
// these two hues be told apart", which is a judgement about a person's eyes and
// the answer varies by type and severity. It asks the stronger and cheaper
// question instead: **is there a second channel at all.** If every state ships
// words, the hue question stops mattering — for deuteranopia, protanopia,
// tritanopia, a monochrome screenshot, a photocopy, and a phone in bright sun.
//
// The CVD simulation itself is a human pass and is listed as not done in
// `design/calm/A11Y-SIGNOFF.md`.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/ui/calm/calm_due_card.dart';

import '../support/a11y_harness.dart';

CalmDueView viewFor(DueState state) => CalmDueView(
  state: state,
  driver: DueDriver.distance,
  confidence: RateConfidence.measured,
  title: 'Oil and filter',
  // The real copy per state comes from `due_copy.dart`; this stands in for it
  // so the assertion is about the CHANNEL existing rather than about wording.
  statusLine: switch (state) {
    DueState.overdue => 'Overdue by 2 weeks',
    DueState.due => 'Due now',
    DueState.dueSoon => 'Due in about 3 weeks',
    DueState.ok => 'Next at about 128,400 km',
    DueState.unknown => 'Odova needs a service record to say when',
    DueState.needsOdometer => 'Odova needs a reading to say when',
  },
  actionLabel: 'Log it',
  anchorLine: 'Was due at 186,512 km',
  progress: 0.7,
);

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
  testWidgets('every DueState says something no colour is carrying', (
    tester,
  ) async {
    // The whole rule in one assertion, over the whole enum. A state that ships
    // an empty status line is a state a monochrome user cannot distinguish from
    // any other, and the card would still look correct in a screenshot.
    for (final state in DueState.values) {
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: CalmDueCard(
            view: viewFor(state),
            density: CalmDueDensity.primary,
            onTap: () {},
            onAction: () {},
          ),
        ),
      );

      final said = spoken(tester).join(' | ');
      expect(
        said.replaceAll('Oil and filter', '').trim(),
        isNotEmpty,
        reason: '${state.name} carries nothing but its tint',
      );
    }
  });

  testWidgets('the six states are told apart WITHOUT their colours', (
    tester,
  ) async {
    // Distinctness, not merely presence. Two states that both announce "Due"
    // are two states a colour-blind user reads as one — which is the failure
    // 1.4.1 describes, and it survives a per-state "has a label" check.
    final byState = <DueState, String>{};
    for (final state in DueState.values) {
      await pumpA11y(
        tester,
        const A11yCase(),
        Center(
          child: CalmDueCard(
            view: viewFor(state),
            density: CalmDueDensity.primary,
            onTap: () {},
            onAction: () {},
          ),
        ),
      );
      byState[state] = spoken(tester).join(' | ');
    }

    expect(
      byState.values.toSet(),
      hasLength(DueState.values.length),
      reason: 'two states are announced identically',
    );

    // The pair most likely to collapse, named because §2 cares about it most:
    // `unknown` means no anchor exists, `needsOdometer` means there IS one and
    // the reading is too old. Rendering both as "we do not know" would be
    // honest and useless — the second has a fix the user performs in ten
    // seconds, and the first does not.
    expect(
      byState[DueState.unknown],
      isNot(byState[DueState.needsOdometer]),
    );
  });
}
