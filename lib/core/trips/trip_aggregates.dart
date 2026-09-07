// SPEC.md §12's `trips.list` arithmetic, and nothing else.
//
//   tripDistance(t) = cumulative(end_odometer) − cumulative(start_odometer)
//                     ?? t.manual_distance_m
//   tripCost(t)     = Σ FillUp.total_cost + Σ Expense.amount  where trip_id = t
//   businessShare   = Σ tripDistance(business) / Σ tripDistance(all)
//
// The one rule that governs this whole file: **trip distances are never summed
// into vehicle distance.** People log some trips and not all of them, so the
// odometer is the source of truth for how far the car has gone and these
// figures only attribute cost. Nothing here takes the vehicle's readings as an
// input, which is what stops the two from being confused later — the mistake
// is not one somebody makes on purpose, it is one they make by reaching for
// the number that looks more complete.
import 'package:meta/meta.dart';
import 'package:odova/core/costs/business_share.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/value_equality.dart';

/// One odometer reading a trip emitted, by the id the cumulative map is keyed
/// on.
///
/// A trip stores its endpoints as RAW dash numbers; the reading rows it emits
/// carry the same values and are what corrections are applied to. Resolving
/// through the readings is therefore not indirection for its own sake — it is
/// the only path on which a mid-history cluster swap has been folded in.
typedef TripEndpoint = ({String tripId, bool isEnd, String readingId});

/// One amount attributed to a trip — a fill-up's total or an expense.
typedef TripCostLine = ({String tripId, Money amount});

/// One trip's distance, or null when it is not knowable.
///
/// The subtraction wins and [manual] is the fallback, per SPEC.md §3: a
/// hand-typed distance is used ONLY when the odometer cannot answer. Null and
/// not zero when neither can — a trip with no figures is not a trip of no
/// distance, and §1 forbids the app guessing in a way that looks like fact.
@useResult
Distance? tripDistance({
  required Distance? cumulativeStart,
  required Distance? cumulativeEnd,
  required Distance? manual,
}) {
  if (cumulativeStart == null || cumulativeEnd == null) return manual;
  return cumulativeEnd - cumulativeStart;
}

/// [tripDistance] for every trip in [trips] that has one.
///
/// [cumulative] is the whole vehicle's map from `cumulativeByReading`, and
/// [endpoints] is what selects a trip's own two rows out of it. Readings that
/// belong to a fill-up, a service or the odometer log are in [cumulative] too
/// and are never reachable from here.
@useResult
Map<String, Distance> tripDistances(
  Iterable<Trip> trips,
  Iterable<TripEndpoint> endpoints,
  Map<String, Distance> cumulative,
) {
  final starts = <String, String>{};
  final ends = <String, String>{};
  for (final endpoint in endpoints) {
    (endpoint.isEnd ? ends : starts)[endpoint.tripId] = endpoint.readingId;
  }

  final distances = <String, Distance>{};
  for (final trip in trips) {
    final id = trip.id.toString();
    final distance = tripDistance(
      cumulativeStart: cumulative[starts[id]],
      cumulativeEnd: cumulative[ends[id]],
      manual: trip.manualDistance,
    );
    if (distance != null) distances[id] = distance;
  }
  return distances;
}

/// What each trip cost, per currency.
///
/// A [MoneyTotal] and not a [Money], because a trip abroad has a tankful in
/// one currency and a toll in another, and there is no rate in this app to
/// convert between them. §12 prints them side by side.
@useResult
Map<String, MoneyTotal> tripCosts(Iterable<TripCostLine> lines) {
  final byTrip = <String, List<Money>>{};
  for (final line in lines) {
    byTrip.putIfAbsent(line.tripId, () => []).add(line.amount);
  }
  return {
    for (final entry in byTrip.entries) entry.key: MoneyTotal(entry.value),
  };
}

/// The header strip over `trips.list`.
@immutable
class TripsSummary with ValueEquality {
  /// Creates a summary.
  const TripsSummary({
    required this.tripCount,
    required this.loggedDistance,
    required this.businessPercent,
    required this.cost,
  });

  /// How many trips are in range.
  final int tripCount;

  /// Their distance added up — **logged trip distance, not the car's.**
  final Distance loggedDistance;

  /// The whole-percentage business share, or null when unknowable.
  final int? businessPercent;

  /// What they cost, per currency.
  final MoneyTotal cost;

  @override
  List<Object?> get props => [
    tripCount,
    loggedDistance,
    businessPercent,
    cost,
  ];
}

/// Summarises [trips] for the header strip.
///
/// A trip with no knowable distance still COUNTS — it happened — but adds
/// nothing to the distance and nothing to either side of the share. Treating
/// it as zero kilometres would quietly dilute the business percentage, and
/// that percentage is the figure that goes on a tax form.
@useResult
TripsSummary summariseTrips({
  required List<Trip> trips,
  required Map<String, Distance> distances,
  required Iterable<TripCostLine> lines,
}) {
  final legs = <TripLeg>[];
  var metres = 0;
  for (final trip in trips) {
    final distance = distances[trip.id.toString()];
    if (distance == null) continue;
    metres += distance.metres;
    legs.add((distance: distance, purpose: trip.purpose));
  }

  return TripsSummary(
    tripCount: trips.length,
    loggedDistance: Distance(metres),
    businessPercent: businessShare(legs),
    cost: MoneyTotal([for (final line in lines) line.amount]),
  );
}
