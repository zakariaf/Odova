// The More section, as one sheet for the three forms that have one.
//
// SPEC.md §10 puts Station, Grade, Trip, Notes and the missed-fill checkbox
// behind More on `log.fillup`, and its own smaller set behind More on
// `log.service` and `log.expense`. The rule that decides the whole design is
// "collapsed by default and collapsed again next time: nothing inside it
// changes a consumption figure" — so nothing in here is ever a default, and
// `log.odometer` does not have one at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/logging/domain/fillup_draft.dart';
import 'package:odova/features/logging/ui/log_modal.dart';
import 'package:odova/features/logging/ui/log_more_sheet.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_switch.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/pump_app.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LogMoreSheet)));

CalmField _field(WidgetTester tester, String label) => tester
    .widgetList<CalmField>(find.byType(CalmField))
    .firstWhere((f) => f.label == label);

Future<FillUpDraft> _pumpFillUp(
  WidgetTester tester, {
  FillUpDraft draft = const FillUpDraft(),
}) async {
  var current = draft;
  tester.useDevice(Device.tallForm);
  await pumpApp(
    tester,
    StatefulBuilder(
      builder: (context, setState) => LogMoreSheet(
        type: LogType.fillUp,
        fillUp: current,
        onFillUpChanged: (next) => setState(() => current = next),
      ),
    ),
  );
  return current;
}

void main() {
  testWidgets('the fill-up More section carries §10 four fields and the box', (
    tester,
  ) async {
    await _pumpFillUp(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.logFillUpStation), findsOneWidget);
    expect(find.text(l10n.logFillUpGrade), findsOneWidget);
    expect(find.text(l10n.logNotes), findsOneWidget);
    expect(find.text(l10n.logFillUpChainBroken), findsOneWidget);
  });

  testWidgets('nothing in here is prefilled', (tester) async {
    // §10: the recents are offered as chips and "never auto-fill". A station
    // that arrives as a default gets saved unread.
    await _pumpFillUp(tester);
    final l10n = _l10n(tester);

    expect(_field(tester, l10n.logFillUpStation).controller.text, '');
    expect(_field(tester, l10n.logFillUpGrade).controller.text, '');
  });

  testWidgets('the missed-fill box explains what it does', (tester) async {
    // It silently changes what the next full tank means, so §10 gives it a
    // sentence rather than leaving the consequence to be discovered on the
    // fuel screen three weeks later.
    await _pumpFillUp(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.logFillUpChainBrokenHint), findsOneWidget);
  });

  testWidgets('typing a station reaches the draft', (tester) async {
    await _pumpFillUp(tester);
    final l10n = _l10n(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'Shell A61',
    );
    await tester.pump();

    expect(
      _field(tester, l10n.logFillUpStation).controller.text,
      'Shell A61',
    );
  });

  testWidgets('editing a second field keeps the first', (tester) async {
    // The sheet is pushed as its own ROUTE, so the shell's `setState` never
    // rebuilds it: `widget.fillUp` stays exactly as it was when the sheet
    // opened. This test reproduces that by holding `fillUp` CONSTANT — a
    // `StatefulBuilder` that feeds each change back in rebuilds the sheet and
    // hides the bug completely, which is how the first version of this test
    // passed against the broken code.
    //
    // Deriving each change from the frozen draft meant the second field edited
    // discarded the first.
    final emitted = <FillUpDraft>[];
    tester.useDevice(Device.tallForm);
    await pumpApp(
      tester,
      LogMoreSheet(
        type: LogType.fillUp,
        fillUp: const FillUpDraft(),
        onFillUpChanged: emitted.add,
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Shell A61');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '95');
    await tester.pump();

    expect(emitted.last.grade, '95');
    expect(
      emitted.last.station,
      'Shell A61',
      reason: 'the station survived the grade being typed after it',
    );
  });

  testWidgets('the missed-fill switch flips', (tester) async {
    // Read back from the frozen draft it never appeared to change at all.
    final emitted = <FillUpDraft>[];
    tester.useDevice(Device.tallForm);
    await pumpApp(
      tester,
      LogMoreSheet(
        type: LogType.fillUp,
        fillUp: const FillUpDraft(),
        onFillUpChanged: emitted.add,
      ),
    );

    await tester.tap(find.byType(CalmSwitch));
    await tester.pump();

    expect(emitted.last.chainBroken, isTrue);
  });

  testWidgets('every form that has a More section shows its Date row', (
    tester,
  ) async {
    // The Date row and the More row are one card, built by the shell. When the
    // two slots were collapsed into one, `log.expense` — which had a `moreRow`
    // and no `dateRow` to rename — lost both, and the form shipped with no way
    // to change the date at all. Asserted per segment so a fourth body cannot
    // quietly drop it again.
    for (final type in [LogType.fillUp, LogType.service, LogType.expense]) {
      tester.useDevice(Device.tallForm);
      await pumpShell(
        tester,
        Routes.log(type),
        settings: homeSettings(golfId),
        vehicles: [homeVehicle(golfId, 'The Golf')],
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LogModalShell)),
      );
      expect(find.text(l10n.logDateLabel), findsOneWidget, reason: type.wire);
      expect(find.text(l10n.logMoreRow), findsOneWidget, reason: type.wire);
    }
  });

  testWidgets('log.odometer has no More section', (tester) async {
    // §10: "Two fields. No notes, no category, no More section — this screen
    // exists to be finished before the user changes their mind; one more
    // optional field would be a net loss."
    expect(logTypeHasMore(LogType.odometer), isFalse);
    for (final type in [LogType.fillUp, LogType.service, LogType.expense]) {
      expect(logTypeHasMore(type), isTrue, reason: type.wire);
    }
  });
}
