// The three things edit mode adds to a `log.*` form, and one it must not.
//
// SPEC.md §11: "There is no read-only detail screen. Tapping a history row
// opens the same form that created the record, prefilled, segment selector
// hidden, with a context band pinned above the fields."
//
// The segment selector is the load-bearing absence: an entry cannot change
// type, so a form offering the choice would be offering to delete this row and
// write a different one.
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/ui/log_modal.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

const String _entryId = 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMW1';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LogModalShell)));

Future<void> _pump(WidgetTester tester, {required bool edit}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    edit
        ? Routes.logEdit(LogType.fillUp, _entryId)
        : Routes.log(LogType.fillUp),
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('edit mode hides the segment selector', (tester) async {
    await _pump(tester, edit: true);

    expect(find.byKey(kLogSegmentBarKey), findsNothing);
  });

  testWidgets('and create mode shows it', (tester) async {
    // The other half. Without it the first test passes on a form that never
    // had a segment bar at all.
    await _pump(tester, edit: false);

    expect(find.byKey(kLogSegmentBarKey), findsOneWidget);
  });

  testWidgets('Delete sits at the bottom, and names what dies', (
    tester,
  ) async {
    // §11: "Delete sits at the bottom of the form, destructive-styled, never
    // in the app bar where Save is." Per segment, because "Delete this
    // fill-up" and "Delete this expense" are different promises.
    await _pump(tester, edit: true);
    final l10n = _l10n(tester);

    expect(find.text(l10n.logDeleteFillUp), findsOneWidget);
  });

  testWidgets('Delete is destructive-styled', (tester) async {
    await _pump(tester, edit: true);
    final l10n = _l10n(tester);

    final button = tester.widget<CalmButton>(
      find.widgetWithText(CalmButton, l10n.logDeleteFillUp),
    );
    expect(button.variant, CalmButtonVariant.danger);
  });

  testWidgets('Delete is NOT in the app bar beside Save', (tester) async {
    // The rule §11 states as a negative, and the reason is one slip: Save and
    // Delete a thumb apart, and only one of them is undone by pressing it
    // again.
    await _pump(tester, edit: true);
    final l10n = _l10n(tester);

    expect(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.text(l10n.logDeleteFillUp),
      ),
      findsNothing,
    );
  });

  testWidgets('create mode has no Delete at all', (tester) async {
    // There is nothing to delete yet, and a disabled destructive button is a
    // control that teaches the user to reach for it.
    await _pump(tester, edit: false);

    expect(find.text(_l10n(tester).logDeleteFillUp), findsNothing);
  });
}
