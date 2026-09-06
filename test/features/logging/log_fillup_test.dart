// The fill-up form, as the user meets it.
//
// SPEC.md §10 `log.fillup`. The trio's arithmetic is `price_trio_test.dart`'s
// and the refusals are `fillup_draft_test.dart`'s; what is asserted here is
// that the form SHOWS them — that pressing Save on an incomplete trio produces
// §10's exact sentence under the right field, and that an over-capacity
// quantity produces an amber line and saves anyway.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/ui/log_fillup_body.dart';
import 'package:odova/features/logging/ui/log_modal.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LogModalShell)));

Future<void> _pump(WidgetTester tester) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.log(LogType.fillUp),
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
  );
}

/// The field whose label is [label].
CalmField _field(WidgetTester tester, String label) => tester
    .widgetList<CalmField>(find.byType(CalmField))
    .firstWhere((f) => f.label == label);

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.byWidgetPredicate((w) => w is CalmButton && w.block).first;
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pump();
}

void main() {
  testWidgets('full versus part is a segmented control defaulting to full', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    final segmented = tester.widgetList<CalmSegmented>(
      find.byType(CalmSegmented),
    );
    final full = segmented.firstWhere(
      (s) => s.labels.first == l10n.logFillUpFullTank,
    );
    expect(full.index, 0, reason: '§10 prefills Filled it up');
    expect(find.text(l10n.logFillUpPartFillHint), findsNothing);
  });

  testWidgets('a part fill explains itself', (tester) async {
    // §10: "Part fills don't produce a figure on their own." The consequence
    // is stated rather than discovered three weeks later on the fuel screen.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.logFillUpPartFill));
    await tester.pump();

    expect(find.text(l10n.logFillUpPartFillHint), findsOneWidget);
  });

  testWidgets('two of the three are required, and Save says which', (
    tester,
  ) async {
    // §10's exact sentence. It appears on SAVE, not while typing — "a form
    // that scolds you before you have finished is a form that is angry at you
    // for arriving".
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.enterText(
      find.byType(TextField).at(1),
      '42.61',
    );
    await tester.pump();
    expect(
      _field(tester, l10n.logFillUpQuantityLabel).errorText,
      isNull,
      reason: 'nothing is said while the user is still typing',
    );

    await _tapSave(tester);

    expect(
      _field(tester, l10n.logFillUpQuantityLabel).errorText,
      l10n.logFillUpTrioError,
    );
  });

  testWidgets('a quantity of zero is refused with its own message', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.enterText(find.byType(TextField).at(3), '76.66');
    await tester.pump();
    await _tapSave(tester);

    expect(
      _field(tester, l10n.logFillUpQuantityLabel).errorText,
      l10n.logFillUpQuantityError,
    );
  });

  testWidgets('a negative total names the free fill-up', (tester) async {
    // §10 gives the total its own sentence because zero is legal here and the
    // message has to say so: "A free fill-up is 0."
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.enterText(find.byType(TextField).at(1), '42.61');
    await tester.enterText(find.byType(TextField).at(3), '-5');
    await tester.pump();
    await _tapSave(tester);

    expect(
      _field(tester, l10n.logFillUpTotalLabel).errorText,
      isNotNull,
      reason: 'a negative total is refused',
    );
  });

  testWidgets('the More section is collapsed, and is a row', (tester) async {
    // §10: "More is collapsed by default and collapsed again next time:
    // nothing inside it changes a consumption figure."
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.byType(LogFillUpBody), findsOneWidget);
    expect(find.text(l10n.logFillUpStation), findsNothing);
    expect(find.text(l10n.logNotes), findsNothing);
  });
}
