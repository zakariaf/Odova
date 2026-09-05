// `reminders.list` — the full catalogue for one vehicle.
//
// SPEC.md §9 *Groups, in order*, *Interactions*, *States*, *Data*. The screen's
// whole claim is that it needs no legend: the first group speaks Home's
// vocabulary, and the other two have a header carrying the word their rows do
// not print.
//
// **No database for the reads.** Every input is supplied, for the reason every
// other harness in this repo says: a drift stream never delivers under
// `testWidgets` and leaves a timer that fails the NEXT test. The two WRITES are
// asserted against a real in-memory row, because "the screen called a method"
// and "the item is tracked" are different claims.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';
import 'package:odova/ui/calm/calm_swipe_actions.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../../support/fonts.dart';
import '../../home/home_fixture.dart';

/// Mounts `reminders.list` with the catalogue supplied.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<ServiceItem> items,
  List<AssessedItem> assessed = const [],
  Locale? locale = const Locale('en'),
  AppDatabase? database,
  TextScaler? textScaler,
}) => pumpShell(
  tester,
  Routes.reminders,
  locale: locale,
  wrap: textScaler == null
      ? null
      : (child) => Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child,
          ),
        ),
  settings: homeSettings(golfId),
  vehicles: [homeVehicle(golfId, 'The Golf')],
  overrides: <Override>[
    if (database != null) appDatabaseProvider.overrideWithValue(database),
    clockProvider.overrideWithValue(
      Clock.fixed(DateTime.utc(2026, 9, 5, 12)),
    ),
    serviceItemsProvider(golfId).overrideWith((ref) => Stream.value(items)),
    vehicleDueSnapshotProvider(
      golfId,
    ).overrideWithValue(homeSnapshot(assessed)),
  ],
);

/// The app bar's `+`, not the tab bar's.
final Finder _appBarAdd = find.descendant(
  of: find.byType(CalmAppBar),
  matching: find.byIcon(Icons.add),
);

CalmListRow _row(WidgetTester tester, String title) => tester
    .widgetList<CalmListRow>(find.byType(CalmListRow))
    .firstWhere((r) => r.title == title);

List<String> _titles(WidgetTester tester) => [
  for (final r in tester.widgetList<CalmListRow>(find.byType(CalmListRow)))
    r.title,
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('groups render in order: tracked and active, Paused, then Not '
      'tracked', (tester) async {
    final oil = homeItem('Oil and filter');
    final belt = homeItem('Timing belt', suffix: 'B', isActive: false);
    final plugs = homeItem('Spark plugs', suffix: 'C', isTracked: false);
    final inspection = homeItem('Inspection', suffix: 'D');

    await _pump(
      tester,
      items: [plugs, belt, inspection, oil],
      assessed: [
        // Oil is overdue in August, Inspection due next March: the first group
        // sorts by projected date exactly as Home sorts, whatever order the
        // repository handed them over in.
        (oil, homeAssessment(state: DueState.overdue, dueOn: '2026-08-12')),
        (
          inspection,
          homeAssessment(state: DueState.dueSoon, dueOn: '2027-03-14'),
        ),
      ],
    );

    expect(_titles(tester), [
      'Oil and filter',
      'Inspection',
      'Timing belt',
      'Spark plugs',
    ]);
    expect(find.text('Paused'), findsWidgets);
    expect(find.text('Not tracked'), findsOneWidget);
  });

  testWidgets('ok items appear here with their next due', (tester) async {
    // The difference between this screen and Home: §9 keeps `ok` off Home
    // entirely and lists it here.
    final tyres = homeItem('Tyre rotation');
    await _pump(
      tester,
      items: [tyres],
      assessed: [
        (tyres, homeAssessment(state: DueState.ok, remainingDays: 240)),
      ],
    );

    expect(_row(tester, 'Tyre rotation').detailState, DueState.ok);
    expect(find.byType(CalmStatusDot), findsOneWidget);
    // The VALUE, which is the whole point of the row being here. This test
    // asserted the dot and the state and never the text, so it went on passing
    // while the end column was BLANK: `dueStatusLine` returns an empty string
    // for `ok` — correctly, because Home keeps `ok` off the screen — and an
    // `ok` row was being routed through it.
    expect(
      _row(tester, 'Tyre rotation').value,
      isNotEmpty,
      reason: '§9: ok items appear here WITH THEIR NEXT DUE',
    );
    expect(_row(tester, 'Tyre rotation').value, contains('8 months'));
  });

  testWidgets('a distance-driven ok item counts down in distance', (
    tester,
  ) async {
    // The artboard's on-track row reads `in 8,600 km` — the same sentence a
    // `due_soon` distance row gets, because §9 puts this group "in the same
    // dot/colour/wording vocabulary, so no legend is needed".
    final air = homeItem('Air filter');
    await _pump(
      tester,
      items: [air],
      assessed: [
        (
          air,
          homeAssessment(
            state: DueState.ok,
            driver: DueDriver.distance,
            remainingMetres: 8600000,
            remainingDays: null,
          ),
        ),
      ],
    );

    expect(_row(tester, 'Air filter').value, contains('8,600 km'));
  });

  testWidgets('paused rows are greyed and carry no status', (tester) async {
    final belt = homeItem('Timing belt', isActive: false);
    await _pump(tester, items: [belt]);

    final row = _row(tester, 'Timing belt');
    expect(row.value, 'Paused');
    // No DOT and no state: §3 excludes a paused item from the engine, so a row
    // with a status would be showing something nothing computed.
    expect(row.lead, isNull);
    expect(row.detailState, isNull);
    expect(find.byType(CalmStatusDot), findsNothing);
  });

  testWidgets('not-tracked rows carry + Track in place of a status', (
    tester,
  ) async {
    final plugs = homeItem('Spark plugs', isTracked: false);
    await _pump(tester, items: [plugs]);

    final row = _row(tester, 'Spark plugs');
    expect(row.value, '+ Track');
    expect(row.detailState, isNull);
    // No chevron: the row does not open the editor, it turns the item on and
    // THEN opens it — a different promise, and the glyph should not make it.
    expect(row.showChevron, isFalse);
  });

  testWidgets('the header is the same ICU message as the first-run catalogue', (
    tester,
  ) async {
    // The KEY, not the English. §9: "one string, one place to fix it" — and a
    // test that asserted the sentence would pass against a second copy of it.
    await _pump(tester, items: [homeItem('Oil and filter')]);

    expect(find.text(l10nOf(tester).remindersDisclaimer), findsOneWidget);
  });

  testWidgets('+ Track sets is_tracked and opens reminders.edit', (
    tester,
  ) async {
    final db = homeDatabase();
    final plugs = homeItem('Spark plugs', isTracked: false);
    await seedItems(db, [plugs]);

    await _pump(tester, items: [plugs], database: db);

    await tester.tap(find.text('Spark plugs'));
    await tester.pumpAndSettle();

    // The ROW first, then the route. §9: "a tracked item with no anchor is just
    // another `unknown`", so the flag has to land before the editor means
    // anything.
    final rows = await db.select(db.serviceItems).get();
    expect(rows.single.isTracked, isTrue);
    expect(
      locationOf(tester),
      Routes.reminderEdit('rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA'),
    );
  });

  testWidgets('a row tap opens reminders.edit for that item', (tester) async {
    final oil = homeItem('Oil and filter');
    await _pump(
      tester,
      items: [oil],
      assessed: [(oil, homeAssessment(state: DueState.overdue))],
    );

    await tester.tap(find.text('Oil and filter'));
    await tester.pumpAndSettle();
    expect(
      locationOf(tester),
      Routes.reminderEdit('rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA'),
    );
  });

  testWidgets('the app-bar + opens reminders.edit in create mode', (
    tester,
  ) async {
    await _pump(tester, items: [homeItem('Oil and filter')]);

    // By the icon INSIDE THE APP BAR. `CalmAppBarAction` draws the glyph and
    // hands the label to the semantics tree instead — so `find.text` finds
    // nothing — and the tab bar's centre `+` is the same glyph, so an
    // unscoped finder finds two and taps the wrong one.
    await tester.tap(_appBarAdd);
    await tester.pumpAndSettle();
    expect(locationOf(tester), Routes.reminderNew);
  });

  testWidgets('a swipe from the end reveals Done today, Snooze and Turn off', (
    tester,
  ) async {
    final db = homeDatabase();
    final oil = homeItem('Oil and filter');
    await seedItems(db, [oil]);

    await _pump(
      tester,
      items: [oil],
      database: db,
      assessed: [(oil, homeAssessment(state: DueState.overdue))],
    );

    await tester.drag(find.text('Oil and filter'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    for (final label in ['Done today', 'Snooze', 'Turn off']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    // Against the ROW. "The screen called a method" and "the item is off" are
    // different claims, and only the second is what §9 promises.
    final rows = await db.select(db.serviceItems).get();
    expect(rows.single.isActive, isFalse);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('Done today pushes the mark-done path with the item', (
    tester,
  ) async {
    final oil = homeItem('Oil and filter');
    await _pump(
      tester,
      items: [oil],
      assessed: [(oil, homeAssessment(state: DueState.overdue))],
    );

    await tester.drag(find.text('Oil and filter'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done today'));
    await tester.pumpAndSettle();

    // EPIC-11 owns the destination, so the assertion is the ROUTE — name plus
    // arguments — which is the whole navigation contract this epic can keep.
    expect(
      locationOf(tester),
      Routes.log(
        LogType.service,
        itemId: 'rem_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
      ),
    );
  });

  testWidgets('swipe actions are start/end, never left/right', (tester) async {
    // Run in `fa`. The same drag toward the START edge — which is to the RIGHT
    // in Persian — must reveal the same three actions. A row built with
    // `left`/`right` reveals nothing here, or reveals it on the wrong side.
    final oil = homeItem('Oil and filter');
    await _pump(
      tester,
      locale: const Locale('fa'),
      items: [oil],
      assessed: [(oil, homeAssessment(state: DueState.overdue))],
    );

    expect(directionOf(tester), TextDirection.rtl);
    await tester.drag(find.byType(CalmSwipeActions), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text(l10nOf(tester).actionDoneToday), findsOneWidget);
    expect(find.text(l10nOf(tester).actionSnoozeShort), findsOneWidget);
    expect(find.text(l10nOf(tester).actionTurnOffShort), findsOneWidget);
  });

  testWidgets('the empty state is one line and the +', (tester) async {
    await _pump(tester, items: const []);

    expect(find.text('No reminders yet.'), findsOneWidget);
    expect(find.byType(CalmListRow), findsNothing);
    // The + is still there: an empty catalogue is the one state where adding is
    // the only thing to do.
    expect(_appBarAdd, findsOneWidget);
  });

  testWidgets('one item is a one-row list with no group headers', (
    tester,
  ) async {
    final oil = homeItem('Oil and filter');
    await _pump(
      tester,
      items: [oil],
      assessed: [(oil, homeAssessment(state: DueState.overdue))],
    );

    expect(find.byType(CalmListRow), findsOneWidget);
    expect(find.text('Paused'), findsNothing);
    expect(find.text('Not tracked'), findsNothing);
  });

  testWidgets('all paused renders the Paused group alone under its sentence', (
    tester,
  ) async {
    await _pump(
      tester,
      items: [
        homeItem('Oil and filter', isActive: false),
        homeItem('Timing belt', suffix: 'B', isActive: false),
      ],
    );

    expect(
      find.text('Nothing is being tracked on this vehicle.'),
      findsOneWidget,
    );
    expect(find.text('Paused'), findsWidgets);
    expect(find.text('Not tracked'), findsNothing);
    expect(find.byType(CalmListRow), findsNWidgets(2));
  });

  testWidgets('at text scale 2.0 nothing is clipped and the groups keep '
      'their order', (tester) async {
    // The screen's own 200% case. `calm_overflow_matrix_test` covers the
    // COMPONENTS at 3.0 — a row, a swipe tile, a group — and a screen is not
    // its components: three groups with two headers between them, and a swipe
    // opened over them, is a composition no component test assembles.
    tester.useDevice(Device.tallForm);

    await _pump(
      tester,
      textScaler: const TextScaler.linear(2),
      items: [
        homeItem('Oil and filter'),
        homeItem('Brake fluid', suffix: 'B', isActive: false),
        homeItem('Timing belt', suffix: 'C', isTracked: false),
      ],
      assessed: [
        (
          homeItem('Oil and filter'),
          homeAssessment(state: DueState.overdue, dueOn: '2026-08-12'),
        ),
      ],
    );

    // `pumpApp`'s harness turns an overflow into a test failure, so reaching
    // here is half the assertion.
    expect(tester.takeException(), isNull);
    expect(
      _titles(tester),
      containsAllInOrder(['Oil and filter', 'Brake fluid', 'Timing belt']),
      reason: 'a screen that reorders at 200% is a different screen',
    );

    // And it SCROLLS rather than fitting by shrinking something.
    final body = find.descendant(
      of: find.byType(CalmScaffold),
      matching: find.byType(Scrollable),
    );
    await tester.drag(body.first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // And the swipe actions still open and still carry their three labels at
    // twice the size. What this does NOT pin is the tile's HEIGHT: the row is
    // inside a scroll view, so an over-tall tile scrolls rather than
    // overflowing, and both a too-small and a too-large
    // `calmSwipeActionMinHeight` were planted here and passed. The height is
    // `calm_overflow_matrix_test`'s and F-10.6's measurement; this asserts the
    // labels survive the scale, which the matrix cannot see because it has no
    // swipe to open.
    await tester.drag(find.text('Oil and filter'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Done today'), findsOneWidget);
  });

  testWidgets('twenty-six items all render and the list scrolls', (
    tester,
  ) async {
    // §9's "26 items" state. What matters is that nothing is dropped and the
    // screen scrolls rather than clipping — the sticky separators are a
    // presentation nicety and are recorded as deferred.
    final items = [
      for (var i = 0; i < 26; i++)
        homeItem('Item $i', suffix: '0123456789ABCDEFGHJKMNPQRSTV'[i]),
    ];
    await _pump(tester, items: items);

    expect(find.byType(CalmListRow, skipOffstage: false), findsNWidgets(26));
  });
}
