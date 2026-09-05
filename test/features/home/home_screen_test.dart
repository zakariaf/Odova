// `home` — what does my car need next.
//
// SPEC.md §9 *Anatomy*, *The card*, *Ordering*, *Interactions*, and *What is
// deliberately not on Home*. The ORDER and the CAP are decided in
// `home_view_model.dart` and asserted in `home_due_stack_test.dart`; the
// SENTENCES are `home_copy_test.dart`'s. This file is about the screen: what
// is drawn, at which density, above which fold, and where every control goes.
//
// The four `log.*` screens do not exist until EPIC-11, so every navigation
// assertion here reads the ROUTE — name plus arguments — and never the
// destination's contents. That is the epic's stated rule and not a shortcut:
// asserting a placeholder's text would have to be rewritten the day the real
// screen lands, and would prove nothing about the prefill either way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/features/home/ui/glance_tiles.dart';
import 'package:odova/features/home/ui/home_screen.dart';
import 'package:odova/features/home/ui/last_fillup_row.dart';
import 'package:odova/features/home/ui/other_vehicles_row.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_tile.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../../support/fonts.dart';
import 'home_fixture.dart';

/// Nine items due on nine different days, so the sort is total.
List<AssessedItem> _many(int count) => [
  for (var i = 0; i < count; i++)
    (
      homeItem('Item $i', suffix: _suffix(i)),
      homeAssessment(
        state: DueState.overdue,
        dueOn: '2026-08-${(i + 1).toString().padLeft(2, '0')}',
      ),
    ),
];

/// A Crockford character per index — `I`, `L`, `O` and `U` are not in the
/// alphabet, so `String.fromCharCode` over the Latin one would build ids that
/// do not parse.
String _suffix(int i) => '0123456789ABCDEFGHJKMNPQRSTVWXYZ'[i];

CalmDueCard _card(WidgetTester tester, int index) =>
    tester.widgetList<CalmDueCard>(find.byType(CalmDueCard)).elementAt(index);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('renders the primary card at primary density and secondaries at '
      'secondary density', (tester) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          (
            homeItem('Oil and filter'),
            homeAssessment(state: DueState.overdue, dueOn: '2026-08-12'),
          ),
          (
            homeItem('Inspection', suffix: 'B'),
            homeAssessment(state: DueState.dueSoon, dueOn: '2026-09-28'),
          ),
          (
            homeItem('Brake pads', suffix: 'C'),
            homeAssessment(state: DueState.dueSoon, dueOn: '2026-10-14'),
          ),
        ]),
      },
    );

    expect(find.byType(CalmDueCard), findsNWidgets(3));
    expect(_card(tester, 0).density, CalmDueDensity.primary);
    expect(_card(tester, 0).view.title, 'Oil and filter');
    expect(_card(tester, 1).density, CalmDueDensity.secondary);
    expect(_card(tester, 2).density, CalmDueDensity.secondary);

    // The heights are `calm_due_card_test.dart`'s contract; what this asserts
    // is that the screen asked for the two densities in the right order, which
    // is the half a card widget cannot check for itself.
    final primary = tester.getSize(find.byType(CalmDueCard).first);
    expect(primary.height, greaterThanOrEqualTo(kCalmDueCardPrimaryHeight));
    final secondary = tester.getSize(find.byType(CalmDueCard).at(1));
    expect(secondary.height, greaterThanOrEqualTo(kCalmDueCardSecondaryHeight));
    expect(secondary.height, lessThan(kCalmDueCardPrimaryHeight));
  });

  testWidgets('shows at most three cards', (tester) async {
    // TWELVE due items, not nine. §9's own example row reads "See all — 9 more
    // due or overdue", and nine items past a cap of three is six more. The
    // sentence in the epic and the arithmetic in the spec disagree; the
    // arithmetic is the rule and the sentence is the illustration, so the
    // fixture is sized to produce the illustration.
    await pumpHome(
      tester,
      snapshots: {golfId: homeSnapshot(_many(12))},
    );

    expect(find.byType(CalmDueCard), findsNWidgets(3));
    expect(find.text('See all — 9 more due or overdue'), findsOneWidget);

    final row = tester.widget<CalmListRow>(
      find.widgetWithText(CalmListRow, 'See all — 9 more due or overdue'),
    );
    expect(row.danger, isTrue, reason: '§9 makes the overflow row red');
  });

  testWidgets('the see-all row counts tracked items, not due items', (
    tester,
  ) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          // Three due, eleven more tracked and in `ok` — fourteen tracked.
          ..._many(3),
          for (var i = 3; i < 14; i++)
            (
              homeItem('Fine $i', suffix: _suffix(i)),
              homeAssessment(state: DueState.ok),
            ),
        ]),
      },
    );

    expect(find.byType(CalmDueCard), findsNWidgets(3));
    expect(find.text('See all reminders (14)'), findsOneWidget);
    expect(find.textContaining('more due or overdue'), findsNothing);
  });

  testWidgets('the app bar title is a tap target only with two or more '
      'vehicles', (tester) async {
    final due = homeSnapshot([
      (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
    ]);

    await pumpHome(tester, snapshots: {golfId: due});

    expect(find.text('The Golf'), findsOneWidget);
    var bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(bar.showVehicleChevron, isFalse);
    expect(bar.onTapVehicle, isNull, reason: 'one vehicle is not a control');

    await pumpHome(
      tester,
      vehicles: [homeVehicle(golfId, 'The Golf'), homeVehicle(vanId, 'Van')],
      snapshots: {golfId: due, vanId: homeSnapshot(const [])},
    );

    bar = tester.widget<CalmAppBar>(find.byType(CalmAppBar));
    expect(bar.showVehicleChevron, isTrue);
    await tester.tap(find.text('The Golf'));
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.vehicleSwitcher);
  });

  testWidgets('the other-vehicles row appears only when another vehicle has a '
      'due or overdue item', (tester) async {
    final golf = homeSnapshot([
      (homeItem('Oil and filter'), homeAssessment(state: DueState.dueSoon)),
    ]);
    final quiet = homeSnapshot([
      (homeItem('Air filter', suffix: 'B'), homeAssessment(state: DueState.ok)),
    ]);

    await pumpHome(
      tester,
      vehicles: [homeVehicle(golfId, 'The Golf'), homeVehicle(vanId, 'Van')],
      snapshots: {golfId: golf, vanId: quiet},
    );
    expect(find.byType(OtherVehiclesRow), findsNothing);

    await pumpHome(
      tester,
      vehicles: [homeVehicle(golfId, 'The Golf'), homeVehicle(vanId, 'Van')],
      snapshots: {
        golfId: golf,
        vanId: homeSnapshot([
          (
            homeItem('Timing belt', suffix: 'C'),
            homeAssessment(state: DueState.overdue),
          ),
        ]),
      },
    );

    expect(find.text('Van · 1 overdue'), findsOneWidget);
    await tester.tap(find.text('Van · 1 overdue'));
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.vehicleSwitcher);
  });

  for (final language in ['en', 'de', 'ckb']) {
    testWidgets('the fold guarantee holds in $language', (tester) async {
      // SPEC.md §9's one hard layout rule: "on the floor screen (375 x 667 pt,
      // default text scale) the primary card and both secondary cards are
      // fully visible without scrolling". German runs ~30% longer than English
      // and Sorani is right-to-left with a taller line box, so the three
      // languages are the fold's three worst cases and not a sample.
      tester.useDevice(Device.floor);

      await pumpHome(
        tester,
        locale: Locale(language),
        snapshots: {
          golfId: homeSnapshot(
            [
              (
                homeItem('Oil and filter'),
                homeAssessment(state: DueState.overdue, dueOn: '2026-08-12'),
              ),
              (
                homeItem('Inspection', suffix: 'B'),
                homeAssessment(state: DueState.dueSoon, dueOn: '2026-09-28'),
              ),
              (
                homeItem('Brake pads', suffix: 'C'),
                homeAssessment(state: DueState.dueSoon, dueOn: '2026-10-14'),
              ),
            ],
            estimate: homeEstimate(187412),
          ),
        },
      );

      // The TAB BAR's top edge, not the viewport's bottom: a card that ends
      // under the bar is a card the user cannot read, and the bar is laid out
      // on this screen rather than assumed.
      final fold = tester.getTopLeft(find.byType(CalmTabBar)).dy;
      for (var i = 0; i < 3; i++) {
        final card = find.byType(CalmDueCard).at(i);
        expect(
          tester.getBottomLeft(card).dy,
          lessThanOrEqualTo(fold),
          reason: '$language: card $i falls below the fold',
        );
      }
    });
  }

  testWidgets('at text scale 2.0 the screen scrolls in reading order and '
      'nothing is clipped', (tester) async {
    tester.useDevice(Device.floor);

    await pumpHome(
      tester,
      textScaler: const TextScaler.linear(2),
      snapshots: {
        golfId: homeSnapshot(
          [
            (
              homeItem('Oil and filter'),
              homeAssessment(state: DueState.overdue, dueOn: '2026-08-12'),
            ),
            (
              homeItem('Inspection', suffix: 'B'),
              homeAssessment(state: DueState.dueSoon, dueOn: '2026-09-28'),
            ),
          ],
          estimate: homeEstimate(187412),
        ),
      },
    );

    // No overflow — `pumpApp`'s harness turns one into a test failure, so
    // reaching here at all is half the assertion. The other half is that the
    // primary card is still FIRST: a screen that reflows at 200% into a
    // different order is a different screen.
    expect(tester.takeException(), isNull);
    expect(_card(tester, 0).density, CalmDueDensity.primary);
    expect(
      tester.getTopLeft(find.byType(CalmDueCard).first).dy,
      lessThan(tester.getTopLeft(find.byType(CalmDueCard).at(1)).dy),
    );
    // And it SCROLLS, rather than fitting by shrinking something. The drag is
    // on the body's scrollable, not on a card: at 200% the primary card is
    // taller than the viewport, so its centre — where `drag` starts — is off
    // the bottom of the screen and the gesture only warns.
    final body = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    final before = tester.widget<Scrollable>(body.first).controller!.offset;
    await tester.drag(body.first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Scrollable>(body.first).controller!.offset,
      greaterThan(before),
    );
  });

  testWidgets('Log it pushes log.service prefilled with the item, today and '
      'the last known odometer', (tester) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot(
          [
            (
              homeItem('Oil and filter'),
              homeAssessment(state: DueState.overdue),
            ),
          ],
          estimate: homeEstimate(187412),
        ),
      },
    );

    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();

    expect(
      locationOf(tester),
      Routes.log(
        LogType.service,
        itemId: 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
        on: '2026-09-05',
        odometerMetres: 187412000,
      ),
    );
  });

  testWidgets("a needsOdometer card's button is Update odometer and pushes "
      'log.odometer', (tester) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          (
            homeItem('Timing belt'),
            homeAssessment(
              state: DueState.needsOdometer,
              driver: DueDriver.distance,
              confidence: RateConfidence.defaulted,
              remainingDays: null,
              remainingMetres: -4000,
            ),
          ),
        ]),
      },
    );

    expect(find.text('Update odometer'), findsOneWidget);
    expect(find.text('Log it'), findsNothing);

    await tester.tap(find.text('Update odometer'));
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.log(LogType.odometer));
  });

  testWidgets('the card overflow offers Log it, Snooze, Edit reminder and Turn '
      'this off', (tester) async {
    // A PHONE, not the default 800x600 test view. A bottom sheet is laid out
    // against the surface it is shown on, and on a 600pt-tall view the four
    // rows fall off the bottom — where `find.text` still finds them and `tap`
    // only WARNS, so the test would pass by never pressing the button.
    tester.useDevice(Device.floor);

    final db = homeDatabase();
    final item = homeItem('Oil and filter');
    await seedItems(db, [item]);
    await pumpHome(
      tester,
      database: db,
      snapshots: {
        golfId: homeSnapshot([(item, homeAssessment(state: DueState.overdue))]),
      },
    );

    await tester.tap(find.byKey(kCalmDueCardMoreKey));
    await tester.pumpAndSettle();

    const menu = ['Log it', 'Snooze', 'Edit reminder', 'Turn this off'];
    for (final label in menu) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    // Through the ROW, not the label. The sheet's last row sits at the foot of
    // the surface, where the default 800x600 test view puts it under the
    // sheet's own bottom padding — `tap` on the paragraph then warns rather
    // than failing, and the test passes by not pressing the button.
    final turnOff = find.widgetWithText(CalmListRow, 'Turn this off');
    await tester.ensureVisible(turnOff);
    await tester.pumpAndSettle();
    await tester.tap(turnOff);
    await tester.pumpAndSettle();

    // Against the ROW, not against a recording fake: "the screen called a
    // method" and "the item is off" are different claims, and only the second
    // one is what §9 promises.
    final rows = await db.select(db.serviceItems).get();
    expect(rows.single.id, 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA');
    expect(rows.single.isActive, isFalse);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('the glance tiles are on the screen and explain their dashes', (
    tester,
  ) async {
    // The tiles' own behaviour is `glance_tiles_test.dart`'s — with a figure
    // and without. What the SCREEN owes is that the row is there at all and
    // that its dash is reachable, which is the half a component test cannot
    // see.
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      },
    );

    expect(find.byType(GlanceTiles), findsOneWidget);
    expect(find.byType(CalmTile), findsNWidgets(3));

    await tester.tap(find.byKey(kGlanceConsumptionKey));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your first consumption figure arrives at your next full fill-up.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the last fill-up row is a read-out', (tester) async {
    await pumpHome(
      tester,
      fillUps: [homeFillUp()],
      snapshots: {
        golfId: homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      },
    );

    final row = tester.widget<CalmListRow>(
      find.descendant(
        of: find.byType(LastFillUpRow),
        matching: find.byType(CalmListRow),
      ),
    );
    expect(row.title, 'Last fill-up');
    expect(row.onTap, isNull, reason: '§9: Last fill-up row — Nothing');
    expect(row.showChevron, isFalse);
  });

  testWidgets('re-tapping the Home tab scrolls to top', (tester) async {
    tester.useDevice(Device.floor);

    await pumpHome(
      tester,
      fillUps: [homeFillUp()],
      snapshots: {golfId: homeSnapshot(_many(12))},
    );

    final scrollable = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable.first, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scrollable>(scrollable.first).controller!.offset,
      greaterThan(0),
    );

    await tapTab(tester, (l10n) => l10n.tabHome);

    expect(
      tester.widget<Scrollable>(scrollable.first).controller!.offset,
      0,
      reason: 'SPEC.md §7: a re-tap scrolls the tab root to the top',
    );
  });
}
