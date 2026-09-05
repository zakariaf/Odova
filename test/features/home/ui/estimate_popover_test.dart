// One sentence, at most one action.
//
// SPEC.md §9: "No percentage, no bar, no tier name: the tilde and the word
// 'about' are the whole vocabulary." A confidence bar would invite the user to
// reason about a number the app is already telling them not to trust.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_popover.dart';

import '../../../support/pump_app.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CalmPopover)));

void main() {
  testWidgets('the estimated case offers Update odometer', (tester) async {
    var pressed = 0;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: CalmPopover(
            message: AppLocalizations.of(
              context,
            ).homeEstimatedFrom('41 km', '12 July'),
            action: (
              label: AppLocalizations.of(context).actionUpdateOdometer,
              onPressed: () => pressed++,
            ),
          ),
        ),
      ),
    );

    final l10n = _l10n(tester);
    expect(
      find.text(l10n.homeEstimatedFrom('41 km', '12 July')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.actionUpdateOdometer));
    expect(pressed, 1);
  });

  testWidgets('the expired case says Odova has stopped guessing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: CalmPopover(
            message: AppLocalizations.of(context).homeEstimateExpired,
            action: (
              label: AppLocalizations.of(context).actionUpdateOdometer,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(_l10n(tester).homeEstimateExpired), findsOneWidget);
  });

  testWidgets('the consumption case is dismissal only', (tester) async {
    // §9 gives this one NO button: there is nothing to do but drive and fill
    // up, and a button that only closes a popover is a control that does
    // nothing.
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: CalmPopover(
            message: AppLocalizations.of(context).homeConsumptionPending,
          ),
        ),
      ),
    );

    expect(find.text(_l10n(tester).homeConsumptionPending), findsOneWidget);
    expect(find.byType(CalmButton), findsNothing);
  });

  testWidgets('it says one sentence and shows no percentage or bar', (
    tester,
  ) async {
    // The vocabulary rule, asserted as an absence: §9 forbids a tier name and a
    // confidence bar, and both are the obvious thing to add here later.
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: CalmPopover(
            message: AppLocalizations.of(
              context,
            ).homeEstimatedFrom('41 km', '12 July'),
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(
      tester.widgetList<Text>(find.byType(Text)),
      hasLength(1),
      reason: 'one sentence, and nothing beside it',
    );
  });
}
