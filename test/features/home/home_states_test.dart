// Home when there is nothing to do, nothing yet, nothing left, or nothing
// readable.
//
// SPEC.md §9 *Every state*, *The unknown-anchor card*, *Error*. Each of these
// REPLACES something rather than sitting beside it, so most of these tests
// assert an absence as well as a presence: an all-clear card above a due stack
// would be a screen that answered its own question twice.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/bidi.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/home/ui/glance_tiles.dart';
import 'package:odova/features/home/ui/home_screen.dart';
import 'package:odova/features/home/ui/home_states.dart';
import 'package:odova/ui/calm/calm_all_clear.dart';
import 'package:odova/ui/calm/calm_due_card.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_tile.dart';

import '../../app/routing/shell_harness.dart';
import '../../support/device.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';
import 'home_fixture.dart';

/// An item whose anchor came from the PURCHASE rung.
///
/// §9: "Home renders any item anchored on the `purchase` or `first_reading`
/// rung as `unknown`, whatever the due engine returns." The engine's answer
/// here is `overdue`, which is the point — a 2019 car entered today really is
/// overdue if you measure from the day it was bought.
AssessedItem _unanchored(String label, {String suffix = 'A'}) => (
  homeItem(label, suffix: suffix),
  DueAssessment(
    state: DueState.overdue,
    driver: DueDriver.distance,
    confidence: RateConfidence.defaulted,
    progress: 1,
    remainingMetres: -400000,
    anchor: DueAnchor(
      date: homeToday,
      dateRung: AnchorRung.purchase,
      odometerRung: AnchorRung.purchase,
    ),
  ),
);

/// A service record on [occurredOn] at [km], with one line called [label].
ServiceRecord _record({
  required String occurredOn,
  required int km,
  String label = 'oil change',
}) => ServiceRecord(
  id: ServiceRecordId.tryParse('srv_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
  vehicleId: golfId,
  occurredOn: occurredOn,
  odometer: Distance(km * 1000),
  odometerUnit: DistanceUnit.km,
  lines: [
    ServiceLine(
      id: ServiceLineId.tryParse('lin_01JQ8ZK3M7F0R6XN2E9TB4HCVA')!,
      serviceRecordId: ServiceRecordId.tryParse(
        'srv_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
      )!,
      label: label,
      amount: Money(0, Currency.tryParse('EUR')!),
    ),
  ],
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('nothing due renders CalmAllClear, never CalmEmptyState', (
    tester,
  ) async {
    await pumpHome(
      tester,
      records: [_record(occurredOn: '2026-05-05', km: 184292)],
      snapshots: {
        golfId: homeSnapshot(
          [
            (
              homeItem('Inspection'),
              homeAssessment(state: DueState.ok, dueOn: '2027-03-14'),
            ),
          ],
          estimate: homeEstimate(187412),
        ),
      },
    );

    expect(find.byType(CalmAllClear), findsOneWidget);
    expect(find.byType(CalmEmptyState), findsNothing);
    expect(find.byType(CalmDueCard), findsNothing);

    // Four things and nothing else: the mark, the headline, the next item with
    // its date, and the receipt.
    expect(find.byType(CalmAllClearMark), findsOneWidget);
    expect(find.text('Nothing due'), findsOneWidget);
    expect(find.text('Next: Inspection, 14 March 2027'), findsOneWidget);
    expect(find.text('Since the last oil change:'), findsOneWidget);
    // Bidi isolates STRIPPED. `formatWithUnit` wraps the number and its unit in
    // one FSI…PDI run so the `km` cannot migrate past the digits in Arabic, and
    // leaving them in would make this a test of the isolate as well as of the
    // arithmetic — so a missing isolate and a wrong figure would fail
    // identically.
    expect(
      stripBidi(
        tester.widget<CalmAllClear>(find.byType(CalmAllClear)).since!.figure,
      ),
      '3,120 km · 4 months',
    );
  });

  testWidgets('the all-clear answer is above the fold, and the tiles are '
      'reachable', (tester) async {
    // §9's ONE hard layout rule is that the answer is above the fold, and on
    // this screen the answer is the all-clear card.
    //
    // Its other sentence — the all-clear "saves enough height to pull the tiles
    // above the fold" — does NOT hold on the floor screen, and the reason is
    // Calm's own `.allclear`: `padding: space-8 / space-6 / space-7` around a
    // 92pt mark with a 12pt ring, a title, a line, a meta line and a `since`
    // block, which measures 289pt without the receipt and ~380 with it against
    // the ~148 §9's ASCII budget assumes. Add the see-all row §9's own drawing
    // puts under it and the tiles start below the bar. Recorded in
    // epics/progress/EPIC-10.md rather than fixed by shrinking a component the
    // stylesheet specifies.
    tester.useDevice(Device.floor);
    await pumpHome(
      tester,
      records: [_record(occurredOn: '2026-05-05', km: 184292)],
      snapshots: {
        golfId: homeSnapshot(
          [
            (
              homeItem('Inspection'),
              homeAssessment(state: DueState.ok, dueOn: '2027-03-14'),
            ),
          ],
          estimate: homeEstimate(187412),
        ),
      },
    );

    final fold = tester.getTopLeft(find.byType(CalmTabBar)).dy;
    expect(
      tester.getBottomLeft(find.byType(CalmAllClear)).dy,
      lessThanOrEqualTo(fold),
      reason: 'the answer itself fell below the fold',
    );
    // And the see-all row survives the all-clear — §9's zone table keeps it
    // "whenever the vehicle has >= 1 tracked item", and its *Nothing due*
    // drawing shows it under the card.
    expect(find.text('See all reminders (1)'), findsOneWidget);
    expect(find.byType(CalmTile), findsNWidgets(3));
  });

  testWidgets('service history but no fill-ups keeps the receipt and dashes '
      'the consumption tile', (tester) async {
    await pumpHome(
      tester,
      records: [_record(occurredOn: '2026-05-05', km: 184292)],
      snapshots: {
        golfId: homeSnapshot(
          [(homeItem('Inspection'), homeAssessment(state: DueState.ok))],
          estimate: homeEstimate(187412),
        ),
      },
    );

    expect(find.text('Since the last oil change:'), findsOneWidget);

    // SCROLLED to. The all-clear card and the see-all row fill the viewport on
    // this screen, so the tiles are not built until they are — which is the
    // ListView doing its job, and a `find.text` that skipped them would report
    // "no dashes" for a row that is simply further down.
    await tester.drag(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(Scrollable),
      ),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text(kGlanceDash), findsNWidgets(3));
  });

  testWidgets('first run renders the unknown-anchor card in the primary slot', (
    tester,
  ) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          _unanchored('Oil and filter'),
          _unanchored('Air filter', suffix: 'B'),
          _unanchored('Inspection', suffix: 'C'),
        ]),
      },
    );

    expect(find.byType(UnknownAnchorPanel), findsOneWidget);
    expect(
      find.text(
        'Set up your reminders — tell me when things were last done',
      ),
      findsOneWidget,
    );
    // NOT eleven red cards. That is the whole reason §9 has this rule: "An app
    // that shouts OVERDUE eleven times on day one gets its notifications
    // turned off on day two."
    expect(find.byType(CalmDueCard), findsNothing);
    expect(find.byType(CalmAllClear), findsNothing);
  });

  testWidgets('no fake zeroes on first run', (tester) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([_unanchored('Oil and filter')]),
      },
    );

    for (final tile in tester.widgetList<CalmTile>(find.byType(CalmTile))) {
      expect(
        RegExp('[0-9٠-٩۰-۹]').hasMatch(tile.value),
        isFalse,
        reason: 'a first-run tile rendered "${tile.value}"',
      );
    }
  });

  testWidgets('the unknown card names three items and a + n more', (
    tester,
  ) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          _unanchored('Oil and filter'),
          _unanchored('Air filter', suffix: 'B'),
          _unanchored('Inspection', suffix: 'C'),
          _unanchored('Brake pads', suffix: 'D'),
          _unanchored('Timing belt', suffix: 'E'),
        ]),
      },
    );

    for (final named in ['Oil and filter', 'Air filter', 'Inspection']) {
      expect(find.text(named), findsOneWidget, reason: named);
    }
    expect(find.text('Brake pads'), findsNothing);
    expect(find.text('+ 2 more'), findsOneWidget);

    // A named item opens its editor; the card opens the list.
    await tester.tap(find.text('Air filter'));
    await tester.pumpAndSettle();
    expect(
      locationOf(tester),
      Routes.reminderEdit('rem_01JQ8ZK3M7F0R6XN2E9TB4HCVB'),
    );
  });

  testWidgets('only tracked items appear in the unknown card', (tester) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          _unanchored('Oil and filter'),
          (
            homeItem('Cabin filter', suffix: 'B', isTracked: false),
            _unanchored('Cabin filter', suffix: 'B').$2,
          ),
        ]),
      },
    );

    expect(find.text('Oil and filter'), findsOneWidget);
    // §9: "Only tracked items appear; untracked catalogue rows live on
    // `reminders.list`."
    expect(find.text('Cabin filter'), findsNothing);
  });

  testWidgets('one item renders one primary card and no layout special case', (
    tester,
  ) async {
    await pumpHome(
      tester,
      snapshots: {
        golfId: homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      },
    );

    expect(find.byType(CalmDueCard), findsOneWidget);
    expect(
      tester.widget<CalmDueCard>(find.byType(CalmDueCard)).density,
      CalmDueDensity.primary,
    );
    // The see-all row is still there — it counts tracked items, not due ones.
    expect(find.text('See all reminders (1)'), findsOneWidget);
  });

  testWidgets('a sold vehicle replaces the due stack', (tester) async {
    await pumpHome(
      tester,
      vehicles: [
        homeVehicle(
          golfId,
          'The Golf',
          status: VehicleStatus.sold,
          soldOn: '2026-06-14',
        ),
      ],
      snapshots: {
        golfId: homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      },
    );

    expect(find.byType(SoldVehiclePanel), findsOneWidget);
    expect(
      find.text('This vehicle is marked sold (14 June 2026).'),
      findsOneWidget,
    );
    // §9: "The due stack is replaced entirely; no reminders, no notifications,
    // no nudges."
    expect(find.byType(CalmDueCard), findsNothing);
  });

  testWidgets('a sold vehicle says how long it was owned and how far', (
    tester,
  ) async {
    // §9's `homeSoldOwned` — "Owned {duration} · {distance} driven". The panel
    // took `owned` and `driven` as REQUIRED parameters and the one call site
    // passed null for both, so the line it exists to draw could not appear and
    // an ICU key translated into six locales was unreachable.
    await pumpHome(
      tester,
      vehicles: [
        homeVehicle(
          golfId,
          'The Golf',
          status: VehicleStatus.sold,
          soldOn: '2026-06-14',
          purchaseDate: '2020-06-14',
          purchaseOdometer: const Distance.fromKm(42000),
        ),
      ],
      snapshots: {
        golfId: homeSnapshot(const [], estimate: homeEstimate(187412)),
      },
    );

    // "72 months", not "6 years": `homeDurationLine`'s ladder tops out at
    // months, because §9 built it for an overshoot and a service receipt —
    // spans of weeks. Ownership is the first span measured in years, and a
    // years bucket is a copy decision across six locales and a shared ladder
    // that also words every due date. Recorded rather than invented here.
    final line = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(SoldVehiclePanel),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .last;
    // The distance carries its bidi isolate, as every figure beside a unit
    // does — so this reads around it rather than pinning the marks.
    expect(line, startsWith('Owned 72 months'));
    expect(line, contains('145,412 km'));
    expect(line, endsWith('driven'));
  });
  testWidgets('an unreadable store renders one message and one button', (
    tester,
  ) async {
    await pumpHome(
      tester,
      unreadable: true,
      snapshots: {
        golfId: homeSnapshot([
          (homeItem('Oil and filter'), homeAssessment(state: DueState.overdue)),
        ]),
      },
    );

    expect(find.text("Odova can't read your data."), findsOneWidget);
    expect(find.byType(CalmDueCard), findsNothing);
    expect(find.byType(CalmTile), findsNothing);

    await tester.tap(find.text('Open Backup & restore'));
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.settingsBackup);
  });

  testWidgets('one bad row is a grey card with a way into the editor', (
    tester,
  ) async {
    // §9: "A single item whose derived state throws renders as a grey card,
    // `Something's wrong with this reminder`, with a chevron to
    // `reminders.edit` — one bad row never blanks the screen."
    //
    // Pumped DIRECTLY, because nothing can trigger it yet: `recomputeVehicle`
    // returns one `DueAssessment` per eligible item and has no way to report
    // that one of them threw — a per-item failure is a change to EPIC-07's
    // engine, not to this screen. The card is built and asserted so that the
    // day the engine can say so, the drawing already exists. Recorded in
    // epics/progress/EPIC-10.md.
    var opened = 0;
    await pumpApp(
      tester,
      Scaffold(body: BrokenReminderCard(onTap: () => opened++)),
    );

    expect(find.text("Something's wrong with this reminder"), findsOneWidget);
    // GREY. It must not borrow overdue's red: the app does not know that this
    // item is overdue, it knows it cannot say.
    expect(
      tester.widget<CalmStatusDot>(find.byType(CalmStatusDot)).style.state,
      DueState.unknown,
    );

    await tester.tap(find.text("Something's wrong with this reminder"));
    expect(opened, 1);
  });

  testWidgets('the skeleton appears only past 150 ms', (tester) async {
    var built = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: DelayedSkeleton(
          child: Builder(
            builder: (_) {
              built++;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      settle: false,
    );

    // A load that finishes in 100 ms never shows it. That is the common path —
    // a warm database answering in single-digit milliseconds — and a
    // silhouette that flashes for one frame reads as a stutter.
    await tester.pump(const Duration(milliseconds: 100));
    expect(built, 0);

    await tester.pump(const Duration(milliseconds: 60));
    expect(built, 1);
  });
}
