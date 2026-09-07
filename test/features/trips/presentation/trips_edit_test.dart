// SPEC.md §10's `trips.edit` — the four validations and the distance rule, as
// the user meets them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/trips/trip_aggregates.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';
import 'package:odova/features/trips/presentation/trips_edit_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_field.dart';
import 'package:odova/ui/calm/calm_segmented.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

TripId _tripId(String suffix) =>
    TripId.tryParse('trp_${suffix.toUpperCase().padLeft(26, '0')}')!;

Trip _trip({
  String suffix = 'ax',
  String? endedOn = '2026-08-02',
  Distance? startOdometer,
  Distance? endOdometer,
}) => Trip(
  id: _tripId(suffix),
  vehicleId: golfId,
  title: 'Munich run',
  purpose: TripPurpose.business,
  startedOn: '2026-08-01',
  endedOn: endedOn,
  startOdometer: startOdometer,
  endOdometer: endOdometer,
  odometerUnit: DistanceUnit.km,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

TripsListModel _model(List<Trip> trips) => TripsListModel(
  summary: TripsSummary(
    tripCount: trips.length,
    loggedDistance: Distance.zero,
    businessPercent: null,
    cost: MoneyTotal(const []),
  ),
  open: [
    for (final t in trips)
      if (t.endedOn == null)
        TripsListRow(trip: t, distance: null, cost: MoneyTotal(const [])),
  ],
  earlier: [
    for (final t in trips)
      if (t.endedOn != null)
        TripsListRow(trip: t, distance: null, cost: MoneyTotal(const [])),
  ],
  isLoaded: true,
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(TripsEditScreen)));

Future<void> _pump(
  WidgetTester tester, {
  String tripId = kNewRecordId,
  List<Trip> trips = const [],
  bool isBusiness = true,
  Locale? locale = const Locale('en'),
  Device device = Device.tallForm,
  TextScaler? textScaler,
}) async {
  tester.useDevice(device);
  await pumpShell(
    tester,
    Routes.tripEdit(tripId),
    locale: locale,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf', isBusiness: isBusiness)],
    wrap: textScaler == null
        ? null
        : (app) => Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: app,
            ),
          ),
    overrides: <Override>[
      tripsListProvider.overrideWith((ref, vehicleId) => _model(trips)),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('purpose prefills from whether the vehicle is for work', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(
      tester
          .widget<CalmSegmentedOption>(
            find.widgetWithText(
              CalmSegmentedOption,
              l10n.tripsPurposeBusiness,
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('a personal vehicle prefills Personal, never Commute', (
    tester,
  ) async {
    // Commute is the least deductible purpose. A prefill that guessed it would
    // put the wrong answer on the form whose whole point is the other one.
    await _pump(tester, isBusiness: false);
    final l10n = _l10n(tester);

    expect(
      tester
          .widget<CalmSegmentedOption>(
            find.widgetWithText(
              CalmSegmentedOption,
              l10n.tripsPurposePersonal,
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('Save on an invalid draft shows the error, not a dialog', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    // A manual distance of zero — §10's field 8.
    await tester.enterText(
      find.widgetWithText(TextField, '').at(3),
      '0',
    );
    await tester.pump();
    expect(find.text(l10n.tripDistanceNotPositive), findsNothing);

    await tester.tap(find.text(l10n.tripSaveAction));
    await tester.pumpAndSettle();

    // ONE sentence, under the field. Save was never disabled.
    expect(find.text(l10n.tripDistanceNotPositive), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Still going hides the end fields', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.tripEndsLabel), findsOneWidget);
    expect(find.text(l10n.tripEndOdometerLabel), findsOneWidget);

    await tester.tap(find.text(l10n.tripStillGoing));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tripEndsLabel), findsNothing);
    expect(find.text(l10n.tripEndOdometerLabel), findsNothing);
  });

  testWidgets('the distance field is read-only behind an odometer pair', (
    tester,
  ) async {
    await _pump(
      tester,
      tripId: _tripId('ax').toString(),
      trips: [
        _trip(
          startOdometer: const Distance.fromKm(186_459),
          endOdometer: const Distance.fromKm(186_604),
        ),
      ],
    );
    final l10n = _l10n(tester);

    // The computed figure, and no way to disagree with it.
    expect(find.text('145 km'), findsOneWidget);
    final field = tester.widget<CalmField>(
      find.byWidgetPredicate(
        (w) => w is CalmField && w.label == l10n.tripDistanceLabel,
      ),
    );
    expect(field.enabled, isFalse);
    expect(field.computed, isTrue);
  });

  testWidgets('edit mode names the trip and offers Delete', (tester) async {
    await _pump(
      tester,
      tripId: _tripId('ax').toString(),
      trips: [_trip()],
    );
    final l10n = _l10n(tester);

    expect(find.text(l10n.tripEditTitle), findsWidgets);
    expect(find.text(l10n.tripDeleteAction), findsOneWidget);
    // And the trip it loaded is the one named in the PATH. A cold start from
    // a deep link has a null `state.extra`, so identity that travels in
    // `extra` is identity that vanishes when the OS restarts the app —
    // `route_table_test.dart` keeps the inventory and this is its proof for
    // `trips.edit`.
    expect(find.text('Munich run'), findsOneWidget);
  });

  testWidgets('German purpose wraps to a 2x2 grid rather than shrinking', (
    tester,
  ) async {
    // §10: the four German words do not fit abreast at large text scales, and
    // the answer is a grid — not smaller type. The user turned the text up
    // because they could not read it.
    await _pump(
      tester,
      locale: const Locale('de'),
      device: Device.compact,
      textScaler: const TextScaler.linear(1.6),
    );

    expect(find.byType(CalmSegmented), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it mirrors without overflowing', (tester) async {
    await _pump(
      tester,
      locale: const Locale('fa'),
      device: Device.compact,
      trips: [_trip()],
    );

    expect(
      Directionality.of(tester.element(find.byType(TripsEditScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
