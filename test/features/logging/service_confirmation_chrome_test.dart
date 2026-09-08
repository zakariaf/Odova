// The form stands down when the confirmation takes over.
//
// SPEC.md §10: a mark-done save "replaces the body with the confirmation panel
// for five seconds or until Close". The modal took that literally and replaced
// only the BODY — the Save in the app bar stayed live, the segmented control
// still offered Expense, and `Save service` still sat at the bottom, all over
// a card announcing that the save had already happened. A person opened it and
// asked what the screen was.
//
// It is worse than confusing. The row is written by the time the panel appears,
// so a second Save writes it again.
//
// Nothing caught it because `service_confirmation_panel_test.dart` pumps the
// PANEL through `pumpApp` and never through `LogModal` — the same shape as the
// More sheet, whose test pumps the sheet and never opens it. A widget tested
// only in isolation is a widget whose surroundings nobody has looked at.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/features/logging/ui/service_confirmation_panel.dart';
import 'package:odova/ui/calm/calm_button.dart';
import 'package:odova/ui/calm/calm_chip.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../home/home_fixture.dart';

void main() {
  testWidgets('while the panel is up, nothing else offers to save', (
    tester,
  ) async {
    tester.useDevice(Device.tallForm);

    // A REAL in-memory database. The panel only appears once the write has
    // LANDED, so a save that fails shows the error snackbar and returns — which
    // is how this test failed first, for a reason with nothing to do with the
    // chrome it asserts.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await SettingsRepository(db).save(homeSettings(golfId));

    // The item is PERSISTED as well as put in the snapshot. Ticking a chip
    // whose row does not exist writes a service record against a missing
    // foreign key, and the save fails a constraint.
    final item = homeItem('Oil and filter');
    await seedItems(db, [item]);

    await pumpShell(
      tester,
      Routes.log(LogType.service),
      liveStreams: true,
      settings: homeSettings(golfId),
      vehicles: [homeVehicle(golfId, 'The Golf')],
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        // SUPPLIED. `_confirmationFor` reads the snapshot to work out what the
        // item is next due at and returns null without one, so the save would
        // pop with a snackbar and never show the panel.
        vehicleDueSnapshotProvider(golfId).overrideWithValue(
          homeSnapshot([(item, homeAssessment())]),
        ),
      ],
    );

    final before = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(
      before.onEnd,
      isNotNull,
      reason: '§10: Save is never disabled on the four log.* segments',
    );
    expect(find.byType(CalmSegmented), findsOneWidget);

    // The panel appears only for a MARK-DONE — a save that reset a reminder —
    // so the chip has to be ticked, BY LABEL and not `.first`. The first
    // CalmChip on this screen is the
    // odometer's `km` unit affix, and tapping that changes the unit rather
    // than ticking anything.
    final chip = find.widgetWithText(CalmChip, 'Oil and filter');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    final save = find.byWidgetPredicate((w) => w is CalmButton && w.block);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.byType(ServiceConfirmationPanel),
      findsOneWidget,
      reason: 'a ticked chip is a mark-done and §10 shows the panel',
    );

    final after = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(after.onEnd, isNull, reason: 'the app bar Save would write twice');
    expect(
      find.byType(CalmSegmented),
      findsNothing,
      reason: 'switching segment would throw away what was just read',
    );
    expect(
      find.byWidgetPredicate((w) => w is CalmButton && w.block),
      findsNothing,
      reason: 'the footer Save survived the write',
    );
  });
}
