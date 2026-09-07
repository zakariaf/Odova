// SPEC.md §12's `trips.list` state.
//
// A derived `Provider` and not a `Notifier`, deliberately. Every figure on
// this screen is a pure function of tables that are already watched — trips,
// fill-ups, expenses, readings, corrections — and §12 says nothing on these
// screens is persisted. A Notifier would add a load flag, a microtask seam
// and a second copy of data Riverpod is already keeping live, and would then
// have to be invalidated by hand on every write. `watch` does that for free,
// which is the whole reason the streams exist.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/trips/trip_aggregates.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/repositories/providers.dart';

/// One row on `trips.list`.
@immutable
class TripsListRow {
  /// Creates a row.
  const TripsListRow({
    required this.trip,
    required this.distance,
    required this.cost,
  });

  /// The trip itself.
  final Trip trip;

  /// Its distance, or null when neither the odometer nor a manual figure can
  /// answer. Null and not zero — §1.
  final Distance? distance;

  /// What it cost, per currency.
  final MoneyTotal cost;

  /// Whether it is still running.
  bool get isOpen => trip.endedOn == null;
}

/// What `trips.list` renders.
@immutable
class TripsListModel {
  /// Creates the model.
  const TripsListModel({
    required this.summary,
    required this.open,
    required this.earlier,
    required this.isLoaded,
  });

  /// The empty model, shown while the first read is in flight.
  static final TripsListModel loading = TripsListModel(
    summary: TripsSummary(
      tripCount: 0,
      loggedDistance: Distance.zero,
      businessPercent: null,
      cost: MoneyTotal(const []),
    ),
    open: const [],
    earlier: const [],
    isLoaded: false,
  );

  /// The header strip.
  final TripsSummary summary;

  /// Trips with no end date, pinned above the list.
  ///
  /// A list and not a single trip. In practice there is at most one — you
  /// cannot be on two journeys at once — but pinning ALL of them is one rule
  /// where "pin the newest and leave the rest in the list wearing the same
  /// badge" is two, and the second rule is the one that hides a trip that
  /// needs an action.
  final List<TripsListRow> open;

  /// Everything else, newest first.
  final List<TripsListRow> earlier;

  /// Whether the first read has landed.
  final bool isLoaded;

  /// The row for [tripId], or null.
  ///
  /// On the model, because the partition into [open] and [earlier] is the
  /// model's own decision and a caller that spells out
  /// `[...open, ...earlier].where(...)` has to stay in step with it. It was
  /// spelled out twice on one screen.
  TripsListRow? rowFor(String tripId) {
    for (final row in open) {
      if (row.trip.id.toString() == tripId) return row;
    }
    for (final row in earlier) {
      if (row.trip.id.toString() == tripId) return row;
    }
    return null;
  }

  /// Whether §12's empty state applies.
  ///
  /// Loaded AND nothing. An eager empty would flash "No trips yet" at somebody
  /// who has logged two hundred of them.
  bool get isEmpty => isLoaded && open.isEmpty && earlier.isEmpty;
}

/// `trips.list`'s state for one vehicle.
final ProviderFamily<TripsListModel, VehicleId> tripsListProvider = Provider
    .autoDispose
    .family((ref, vehicleId) {
      final trips = ref.watch(tripsProvider(vehicleId)).value;
      final fills = ref.watch(fillUpsProvider(vehicleId)).value;
      final expenses = ref.watch(expensesProvider(vehicleId)).value;
      final readings = ref.watch(odometerReadingsProvider(vehicleId)).value;
      final corrections = ref
          .watch(odometerCorrectionsProvider(vehicleId))
          .value;

      if (trips == null ||
          fills == null ||
          expenses == null ||
          readings == null ||
          corrections == null) {
        return TripsListModel.loading;
      }

      return buildTripsList(
        trips: trips,
        fills: fills,
        expenses: expenses,
        readings: readings,
        corrections: corrections,
      );
    });

/// Assembles the model. Pure, so it tests without a container.
@useResult
TripsListModel buildTripsList({
  required List<Trip> trips,
  required List<FillUp> fills,
  required List<Expense> expenses,
  required List<OdometerReading> readings,
  required List<OdometerCorrection> corrections,
}) {
  // Corrections folded in FIRST. The trip's own `startOdometer` and
  // `endOdometer` are raw dash numbers; a cluster swap written later moves the
  // history under them, and this map is the only place that has been applied.
  final cumulative = cumulativeByReading(
    readings.map(asReadingPoint),
    corrections.map(asCorrectionPoint),
  );

  final endpoints = <TripEndpoint>[
    for (final reading in readings)
      if (reading.sourceId != null &&
          (reading.source == OdometerSource.tripStart ||
              reading.source == OdometerSource.tripEnd))
        (
          tripId: reading.sourceId!,
          isEnd: reading.source == OdometerSource.tripEnd,
          readingId: reading.id.toString(),
        ),
  ];

  final lines = <TripCostLine>[
    for (final fill in fills)
      if (fill.tripId != null)
        (tripId: fill.tripId!.toString(), amount: fill.totalCost),
    for (final expense in expenses)
      if (expense.tripId != null)
        (tripId: expense.tripId!.toString(), amount: expense.amount),
  ];

  final distances = tripDistances(trips, endpoints, cumulative);
  final costs = tripCosts(lines);

  final rows = [
    for (final trip in trips)
      TripsListRow(
        trip: trip,
        distance: distances[trip.id.toString()],
        cost: costs[trip.id.toString()] ?? MoneyTotal(const []),
      ),
  ];

  return TripsListModel(
    summary: summariseTrips(
      trips: trips,
      distances: distances,
      lines: lines,
    ),
    open: [
      for (final row in rows)
        if (row.isOpen) row,
    ],
    earlier: [
      for (final row in rows)
        if (!row.isOpen) row,
    ],
    isLoaded: true,
  );
}
