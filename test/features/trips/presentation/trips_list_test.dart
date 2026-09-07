// SPEC.md §12's `trips.list`, as the user meets it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/trips/trip_aggregates.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';
import 'package:odova/features/trips/presentation/trips_list_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_badge.dart';
import 'package:odova/ui/calm/calm_button.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

final Currency _eur = Currency.tryParse('EUR')!;

Trip _trip({
  required String id,
  String? title,
  TripPurpose purpose = TripPurpose.business,
  String startedOn = '2026-08-01',
  String? endedOn = '2026-08-02',
  Distance? startOdometer,
}) => Trip(
  id: TripId.tryParse('trp_${id.toUpperCase().padLeft(26, '0')}')!,
  vehicleId: golfId,
  title: title,
  purpose: purpose,
  startedOn: startedOn,
  endedOn: endedOn,
  startOdometer: startOdometer,
  odometerUnit: DistanceUnit.km,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

TripsListRow _row(Trip trip, {Distance? distance, int? costMinor}) =>
    TripsListRow(
      trip: trip,
      distance: distance,
      cost: MoneyTotal([if (costMinor != null) Money(costMinor, _eur)]),
    );

TripsListModel _model({
  List<TripsListRow> open = const [],
  List<TripsListRow> earlier = const [],
  int? businessPercent = 62,
  Distance logged = const Distance.fromKm(3120),
  int costMinor = 48_600,
}) => TripsListModel(
  summary: TripsSummary(
    tripCount: open.length + earlier.length,
    loggedDistance: logged,
    businessPercent: businessPercent,
    cost: MoneyTotal([Money(costMinor, _eur)]),
  ),
  open: open,
  earlier: earlier,
  isLoaded: true,
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(TripsListScreen)));

Future<void> _pump(
  WidgetTester tester,
  TripsListModel model, {
  Locale? locale = const Locale('en'),
  Device device = Device.tallForm,
}) async {
  tester.useDevice(device);
  await pumpShell(
    tester,
    Routes.trips,
    locale: locale,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      tripsListProvider.overrideWith((ref, vehicleId) => model),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the header strip carries §12 four facts', (tester) async {
    await _pump(
      tester,
      _model(
        earlier: [
          for (var i = 0; i < 14; i++)
            _row(_trip(id: 'e$i'), distance: const Distance.fromKm(100)),
        ],
      ),
    );

    final l10n = _l10n(tester);
    // 3,120 km logged · 62% business · €486.00 trip costs · 14 trips.
    expect(find.text('3,120'), findsOneWidget);
    expect(find.text(l10n.tripsLoggedLabel('km')), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text(l10n.tripsBusinessLabel), findsOneWidget);
    expect(find.text(l10n.tripsCostsLabel), findsOneWidget);
    expect(find.text(l10n.tripsCount(14, '14')), findsOneWidget);
  });

  testWidgets('an open trip is pinned with a badge and End this trip', (
    tester,
  ) async {
    await _pump(
      tester,
      _model(
        open: [
          _row(
            _trip(
              id: 'ax',
              title: 'Augsburg',
              endedOn: null,
              startOdometer: const Distance.fromKm(187_412),
            ),
          ),
        ],
        earlier: [_row(_trip(id: 'bx'), distance: const Distance.fromKm(145))],
      ),
    );

    final l10n = _l10n(tester);
    expect(find.text('Augsburg'), findsOneWidget);
    expect(
      find.widgetWithText(CalmBadge, l10n.tripsOpenBadge),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(CalmButton, l10n.tripsFinishAction),
      findsOneWidget,
    );
    // §1: the start reading is a fact the card states, not one it implies.
    expect(find.textContaining('187,412 km'), findsOneWidget);
  });

  testWidgets('a row falls back to its date range and carries its meta', (
    tester,
  ) async {
    await _pump(
      tester,
      _model(
        earlier: [
          _row(
            // No title.
            _trip(id: 'a', purpose: TripPurpose.personal),
            distance: const Distance.fromKm(145),
            costMinor: 2650,
          ),
        ],
      ),
    );

    final l10n = _l10n(tester);
    // The title falls back to the range, and the meta line repeats it with
    // the two facts §12 adds.
    expect(find.text('Aug 1 – Aug 2'), findsOneWidget);
    expect(
      find.text('Aug 1 – Aug 2 · 145 km · ${l10n.tripsPurposePersonal}'),
      findsOneWidget,
    );
    // Isolate-wrapped: `formatMoney` returns FSI … PDI so the symbol cannot
    // migrate to the far end of an RTL line.
    expect(find.textContaining('€26.50'), findsOneWidget);
  });

  testWidgets('the year changing draws a separator', (tester) async {
    await _pump(
      tester,
      _model(
        earlier: [
          _row(_trip(id: 'a')),
          _row(_trip(id: 'b', startedOn: '2025-12-30', endedOn: '2025-12-31')),
        ],
      ),
    );

    expect(find.text('2025'), findsOneWidget);
    // Not above the first row: the year is a change, not a heading.
    expect(find.text('2026'), findsNothing);
  });

  testWidgets('empty says what a trip is for, and offers Add trip', (
    tester,
  ) async {
    await _pump(tester, _model(businessPercent: null));

    final l10n = _l10n(tester);
    expect(find.text(l10n.tripsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.tripsEmptyBody), findsOneWidget);
    expect(
      find.widgetWithText(CalmButton, l10n.tripsAddAction),
      findsOneWidget,
    );
  });

  testWidgets('the German meta line scrolls rather than overflowing', (
    tester,
  ) async {
    // §12: "chips scroll, so wrapping is never required." The reference puts
    // the purpose in the meta line instead, which turns the same requirement
    // into one about a single line of text — checked on the narrowest phone,
    // because a wide harness passes against a screen that overflows on a
    // real one.
    await _pump(
      tester,
      _model(
        earlier: [
          _row(
            _trip(id: 'a', purpose: TripPurpose.commute),
            distance: const Distance.fromKm(145),
            costMinor: 2650,
          ),
        ],
      ),
      locale: const Locale('de'),
      device: Device.compact,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('it mirrors without overflowing', (tester) async {
    await _pump(
      tester,
      _model(
        open: [_row(_trip(id: 'ax', title: 'سفر', endedOn: null))],
        earlier: [
          _row(
            _trip(id: 'a'),
            distance: const Distance.fromKm(145),
            costMinor: 2650,
          ),
        ],
      ),
      locale: const Locale('fa'),
      device: Device.compact,
    );

    expect(
      Directionality.of(tester.element(find.byType(TripsListScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
