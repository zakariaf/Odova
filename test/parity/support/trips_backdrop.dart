/// The REAL `trips.list` and `trips.edit`, over the artboard's own journeys.
///
/// SPEC.md §12. `trips.list-light-ltr.png` draws one open trip to Augsburg, a
/// three-row Earlier group with "See all 14", and a header strip reading
/// 3,120 km · 62% business · €486. The model is supplied rather than derived,
/// because deriving it means five drift streams and none of them delivers
/// inside the three frames a capture takes.
///
/// The names are the artboard's, translated for the RTL captures the same way
/// every other backdrop does it: the app would never translate a trip title —
/// it is the user's own words — but a capture has to compare like with like.
library;

import 'package:flutter/widgets.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/trips/trip_aggregates.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/trips/application/trips_list_model.dart';

import 'settings_backdrop.dart';
import 'vehicles_backdrop.dart';

final Currency _eur = Currency.tryParse('EUR')!;

Trip _trip({
  required String suffix,
  required String title,
  required String startedOn,
  String? endedOn,
  TripPurpose purpose = TripPurpose.business,
  int? startKm,
}) => Trip(
  id: TripId.tryParse('trp_01JQ8ZK3M7F0R6XN2E9TB4HCV$suffix')!,
  vehicleId: artboardGolfId,
  title: title,
  purpose: purpose,
  startedOn: startedOn,
  endedOn: endedOn,
  startOdometer: startKm == null ? null : Distance.fromKm(startKm),
  odometerUnit: DistanceUnit.km,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
);

TripsListRow _row(Trip trip, {int? km, int? costMinor}) => TripsListRow(
  trip: trip,
  distance: km == null ? null : Distance.fromKm(km),
  cost: MoneyTotal([if (costMinor != null) Money(costMinor, _eur)]),
);

/// The artboard's trips, in the artboard's order.
TripsListModel artboardTrips({required bool rtl}) => TripsListModel(
  summary: TripsSummary(
    // FOURTEEN, which is what "See all 14" counts — the group shows three and
    // the link names the rest. A count taken from the visible rows would draw
    // "See all 3" and look perfectly right.
    tripCount: 14,
    loggedDistance: const Distance.fromKm(3120),
    businessPercent: 62,
    cost: MoneyTotal([Money(48600, _eur)]),
  ),
  open: [
    _row(
      _trip(
        suffix: 'A',
        title: rtl ? 'آوگسبورگ — قرار مشتری' : 'Augsburg — Kundentermin',
        startedOn: '2026-09-04',
        startKm: 187412,
      ),
    ),
  ],
  earlier: [
    _row(
      _trip(
        suffix: 'B',
        // An EN DASH, not the arrow the artboard draws. A trip title is text
        // the user types, so nothing in the app produces `→` — but the SDK's
        // Roboto, which is what every capture in this repo renders Latin with,
        // has no glyph for U+2192 at all. The store screenshots come out of
        // these fixtures, and `08-trips` and `06-history` shipped a tofu box
        // between the two city names in all six locales.
        title: rtl ? 'مونیخ – زالتسبورگ' : 'München – Salzburg',
        startedOn: '2026-08-01',
        endedOn: '2026-08-02',
      ),
      km: 145,
      costMinor: 2650,
    ),
    _row(
      _trip(
        suffix: 'C',
        title: rtl ? 'فرودگاه مونیخ' : 'Flughafen München',
        startedOn: '2026-07-18',
        endedOn: '2026-07-20',
        purpose: TripPurpose.personal,
      ),
      km: 84,
      costMinor: 4500,
    ),
    _row(
      _trip(
        suffix: 'D',
        title: rtl ? 'لاندسبرگ، کارگاه' : 'Landsberg, Baustelle',
        startedOn: '2026-07-09',
        endedOn: '2026-07-09',
      ),
      km: 96,
      costMinor: 1840,
    ),
  ],
  isLoaded: true,
);

/// The `trp_` id the artboard's open trip carries, for `trips.edit`.
String get artboardOpenTripId => 'trp_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

/// [child] under the artboard's trips, ready to be a capture's `child`.
///
/// Through [settingsBackdrop], for the reason `fuelBackdrop` gives: one
/// household, one garage, one capture day, in one place.
Widget tripsBackdrop({
  required bool rtl,
  required Locale locale,
  required Widget child,
}) => settingsBackdrop(
  rtl: rtl,
  locale: locale,
  extra: [
    tripsListProvider.overrideWith((ref, vehicleId) => artboardTrips(rtl: rtl)),
    activeVehicleIdProvider.overrideWithValue(artboardGolfId),
  ],
  child: child,
);
