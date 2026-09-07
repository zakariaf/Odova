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
// **The words come from `due_copy.dart`, not from this file.** They were
// hand-written here first, and that made the test assert its own fixture: an
// edit collapsing two states into one sentence — the exact 1.4.1 failure —
// left it green, because the strings it compared had never been near the code
// that ships. Sourcing them found a real one: `unknown` returned '' on
// `reminders.list`, so that row announced its title and a coloured dot.
//
// The CVD simulation itself is a human pass and is listed as not done in
// `design/calm/A11Y-SIGNOFF.md`.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/l10n/due_copy.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/theme/calm/calm_status.dart';
import 'package:odova/ui/calm/calm_due_card.dart';

import '../support/a11y_harness.dart';

/// One assessment per state, with figures a card would really carry.
///
/// `driver` and `confidence` are `distance`/`measured` throughout, because the
/// `defaulted` rung has its own sentence and would answer the question by a
/// route the ramp does not use.
DueAssessment assessmentFor(DueState state) => DueAssessment(
  state: state,
  driver: DueDriver.distance,
  confidence: RateConfidence.measured,
  progress: 0.7,
  remainingMetres: state == DueState.overdue ? -900000 : 1800000,
  remainingDays: state == DueState.overdue ? -14 : 21,
);

void main() {
  /// The line the app itself would draw for [state].
  ///
  /// `remindersStatusLine` rather than `dueStatusLine`: it is the superset —
  /// the one screen that renders every state, including the two Home filters
  /// out before a card is built.
  String lineFor(AppLocalizations l10n, DueState state) => remindersStatusLine(
    l10n,
    'en',
    assessmentFor(state),
    DistanceUnit.km,
  );

  Widget cardFor(DueState state, String statusLine) => Center(
    child: CalmDueCard(
      view: CalmDueView(
        state: state,
        driver: DueDriver.distance,
        confidence: RateConfidence.measured,
        title: 'Oil and filter',
        statusLine: statusLine,
        actionLabel: 'Log it',
        anchorLine: 'Was due at 186,512 km',
        progress: 0.7,
      ),
      density: CalmDueDensity.primary,
      onTap: () {},
      onAction: () {},
    ),
  );

  testWidgets('every DueState ships WORDS, not only a tint', (tester) async {
    // The whole rule in one assertion, over the whole enum.
    //
    // It measures the STATUS LINE and not "did the card announce anything",
    // which is what the first version did and what made it vacuous: a card
    // also speaks its title, its action and its anchor line, so the join was
    // never empty and a state carried by hue alone passed. Removing the fix
    // below left that version green.
    await pumpA11y(tester, const A11yCase(), cardFor(DueState.due, 'x'));
    final l10n = AppLocalizations.of(tester.element(find.byType(CalmDueCard)));

    for (final state in DueState.values) {
      expect(
        lineFor(l10n, state),
        isNotEmpty,
        reason: '${state.name} carries nothing but its tint',
      );
    }
  });

  testWidgets('and the card reads that line out', (tester) async {
    // The other half. A sentence `due_copy.dart` returns and the card never
    // speaks is a sentence nobody hears — the defect this epic already found
    // on the odometer strip, where a nested label was dropped on the way into
    // the semantics tree.
    for (final state in DueState.values) {
      await pumpA11y(tester, const A11yCase(), cardFor(state, 'x'));
      final line = lineFor(
        AppLocalizations.of(tester.element(find.byType(CalmDueCard))),
        state,
      );

      await pumpA11y(tester, const A11yCase(), cardFor(state, line));
      expect(
        spokenLabels(tester).join(' | '),
        contains(line),
        reason: '${state.name} says it and the card does not read it',
      );
    }
  });

  testWidgets('unknown and needsOdometer are never the same sentence', (
    tester,
  ) async {
    // The pair §2 cares about most, and the one most likely to collapse:
    // `unknown` means no anchor exists, `needsOdometer` means there IS one and
    // the reading is too old. Rendering both as "we do not know" would be
    // honest and useless — the second has a fix the user performs in ten
    // seconds, and the first does not.
    //
    // Only this pair, and not a blanket six-way distinctness check. `ok` and
    // `dueSoon` share their wording ON PURPOSE — §9 puts `reminders.list` in
    // "the same dot/colour/wording vocabulary" as Home "so no legend is
    // needed" — and what separates them there is the figure, not the phrase.
    // Asserting six distinct strings would pin a fixture that made them differ
    // and would fail the day the app matched the spec.
    await pumpA11y(tester, const A11yCase(), cardFor(DueState.due, 'x'));
    final l10n = AppLocalizations.of(tester.element(find.byType(CalmDueCard)));

    expect(
      lineFor(l10n, DueState.unknown),
      isNot(lineFor(l10n, DueState.needsOdometer)),
    );
  });
}
