// The conditional strips, on the screen.
//
// SPEC.md §9 *Conditional strips*, *Stale odometer*,
// *Done-from-notification confirmation*, *Away digest*. The THRESHOLDS and the
// priority are `test/features/home/domain/home_strips_test.dart`'s; this is
// about what the screen draws and what a tap on it does.
//
// Two of the three strips have no trigger until EPIC-16 writes one — the
// confirmation reports on a record a notification action creates, and the
// digest needs the permission state and a last-opened time. Their WIDGETS are
// asserted directly here, which is the honest half to test today: pretending to
// trigger them from Home would assert a provider this epic invented.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/ui_state/ui_state_provider.dart';
import 'package:odova/data/ui_state/ui_state_store.dart';
import 'package:odova/features/home/ui/home_strips.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_notice.dart';
import 'package:odova/ui/calm/calm_pressable.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_tile.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'home_fixture.dart';

/// Home on the floor screen, with a reading [days] old and a rate that makes
/// the projected drift `days x driftPerDay`.
Future<ProviderContainer> _pumpStale(
  WidgetTester tester, {
  required int days,
  int driftPerDay = 40000,
  Map<String, String> uiState = const {},
  AppDatabase? database,
}) {
  tester.useDevice(Device.floor);
  return pumpHome(
    tester,
    database: database,
    uiState: uiState,
    snapshots: {
      golfId: homeSnapshot(
        [(homeItem('Oil and filter'), homeAssessment(state: DueState.overdue))],
        estimate: homeEstimate(187412, staleDays: days),
        metresPerDay: driftPerDay,
      ),
    },
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the staleness strip appears at stale_days >= 60', (
    tester,
  ) async {
    await _pumpStale(tester, days: 60, driftPerDay: 0);
    expect(find.byType(StalenessStrip), findsOneWidget);
    expect(find.textContaining('Odometer last updated'), findsOneWidget);

    await _pumpStale(tester, days: 59, driftPerDay: 0);
    expect(find.byType(StalenessStrip), findsNothing);
  });

  testWidgets('the staleness strip appears at stale_days >= 30 with projected '
      'drift over 500 km, and not at 400', (tester) async {
    // 30 x 20 km = 600 km of drift.
    await _pumpStale(tester, days: 30, driftPerDay: 20000);
    expect(find.byType(StalenessStrip), findsOneWidget);

    // 30 x 13.3 km = 399 km. A car that barely moved is not a stale odometer.
    await _pumpStale(tester, days: 30, driftPerDay: 13300);
    expect(find.byType(StalenessStrip), findsNothing);
  });

  testWidgets('strips never displace the primary card', (tester) async {
    // §9: "A conditional strip pushes the tiles below the fold, never the
    // cards — strips are capped at two, and the primary card is never
    // displaced." Both halves, because the first is only interesting if
    // something DID go below.
    await _pumpStale(tester, days: 68);

    final fold = tester.getTopLeft(find.byType(CalmTabBar)).dy;
    expect(find.byType(StalenessStrip), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byType(CalmDueCard).first).dy,
      lessThanOrEqualTo(fold),
      reason: 'the strip displaced the primary card',
    );
    expect(
      tester.getTopLeft(find.byType(CalmTile).first).dy,
      greaterThan(fold),
      reason: 'the tiles should be what the strip pushed down',
    );
  });

  testWidgets('strip Save writes an OdometerReading with source manual and '
      'shows Undo', (tester) async {
    final db = homeDatabase();
    await seedItems(db, [homeItem('Oil and filter')]);

    await _pumpStale(tester, days: 68, database: db);

    await tester.enterText(find.byType(TextField), '188000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.odometerReadings).get();
    expect(rows, hasLength(1));
    expect(rows.single.source, OdometerSource.manual.wire);
    expect(rows.single.odometerM, 188000000);
    expect(find.text('Undo'), findsOneWidget);

    // And Undo takes it back — softly, like every other undo in the app.
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    final after = await db.select(db.odometerReadings).get();
    expect(after.single.deletedAtUtcMs, isNotNull);
  });

  testWidgets('a non-monotonic strip Save yields to the full log.odometer '
      'modal', (tester) async {
    // The strip does not own the typo/correction/backdate dialogue: §3 gives it
    // three resolutions and none of them fits in a panel two lines tall.
    final db = homeDatabase();
    await seedItems(db, [homeItem('Oil and filter')]);
    await seedReading(db, metres: 190000000, occurredOn: '2026-09-01');

    await _pumpStale(tester, days: 68, database: db);

    await tester.enterText(find.byType(TextField), '180000');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      locationOf(tester),
      Routes.log(LogType.odometer, odometerMetres: 180000000),
    );
    // And NOTHING was written. `OdometerWouldGoBackwards` is returned instead
    // of a write, and a strip that half-wrote would be worse than one that
    // refused.
    expect(await db.select(db.odometerReadings).get(), hasLength(1));
  });

  testWidgets('strip ✕ hides it for seven days on that vehicle only', (
    tester,
  ) async {
    final container = await _pumpStale(tester, days: 68);

    await tester.tap(
      find.descendant(
        of: find.byType(CalmNotice),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StalenessStrip), findsNothing);

    final stored = container.read(uiStateProvider);
    expect(
      stored[uiKeyStalenessDismissedUntil(golfId.toString())],
      '2026-09-12',
    );
    // A second vehicle is untouched. The key carries the id for exactly this
    // reason: a global one would silence the van because somebody tidied the
    // Golf's screen.
    expect(stored[uiKeyStalenessDismissedUntil(vanId.toString())], isNull);
  });

  testWidgets('a dismissal that has not expired keeps the strip away', (
    tester,
  ) async {
    await _pumpStale(
      tester,
      days: 68,
      uiState: {uiKeyStalenessDismissedUntil(golfId.toString()): '2026-09-12'},
    );
    expect(find.byType(StalenessStrip), findsNothing);

    // And an expired one lets it back. The stored value is the day it STOPS
    // hiding, so today equal to it is not still hidden.
    await _pumpStale(
      tester,
      days: 68,
      uiState: {uiKeyStalenessDismissedUntil(golfId.toString()): '2026-09-05'},
    );
    expect(find.byType(StalenessStrip), findsOneWidget);
  });

  testWidgets('the strip ✕ clears the 52pt floor', (tester) async {
    // §9: "Every control here, the card ⋯ and the strip ✕ included, has a
    // 48 x 48 dp minimum target." Calm's own floor is 52, and `.notice__close`
    // PAINTS 32 — so the gesture box is the thing to measure.
    await _pumpStale(tester, days: 68);

    final target = find
        .ancestor(
          of: find.descendant(
            of: find.byType(CalmNotice),
            matching: find.byIcon(Icons.close),
          ),
          matching: find.byType(CalmTapTarget),
        )
        .first;
    final size = tester.getSize(target);
    expect(size.height, greaterThanOrEqualTo(52));
    expect(size.width, greaterThanOrEqualTo(52));
  });

  testWidgets('the confirmation strip is not dismissible and offers both '
      'actions', (tester) async {
    var real = 0;
    var right = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: DoneConfirmationStrip(
          itemLabel: 'Oil and filter',
          doneOn: '12 September',
          recordedOdometer: '~187,400 km',
          nextOdometer: '202,400 km',
          nextDate: '12 September 2026',
          onAddRealNumbers: () => real++,
          onConfirm: () => right++,
        ),
      ),
    );

    expect(
      find.text('You marked Oil and filter done on 12 September.'),
      findsOneWidget,
    );
    expect(find.text('I recorded ~187,400 km and no cost.'), findsOneWidget);
    expect(
      find.text('Next due at 202,400 km · 12 September 2026.'),
      findsOneWidget,
    );

    // §9: "Highest-priority strip, NOT dismissible." Expressed by having no
    // close at all rather than a disabled one — a control that refuses is a
    // control the user presses twice.
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('Add the real numbers'));
    await tester.tap(find.text("That's right"));
    expect((real, right), (1, 1));
  });

  testWidgets('the away digest shows at most three lines', (tester) async {
    var dismissed = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: AwayDigestStrip(
          lines: const [
            (item: 'Oil and filter', date: '12 August', overdue: true),
            (item: 'Inspection', date: '14 March', overdue: false),
            (item: 'Brake pads', date: '1 October', overdue: false),
            (item: 'Air filter', date: '2 November', overdue: false),
          ],
          onDismiss: () => dismissed++,
        ),
      ),
    );

    expect(
      find.text('Oil and filter went overdue on 12 August'),
      findsOneWidget,
    );
    expect(find.text('Inspection is due 14 March'), findsOneWidget);
    expect(find.text('Brake pads is due 1 October'), findsOneWidget);
    // The fourth is dropped by the CARD, not by its caller. §9 caps it at
    // three, and a digest that grew a fourth line would be a list — which is
    // what `reminders.list` is.
    expect(find.text('Air filter is due 2 November'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, 1);
  });
}
