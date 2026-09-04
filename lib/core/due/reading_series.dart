// Every source of odometer truth on a vehicle, as one ordered series.
//
// SPEC.md §4.1.1. Two ideas live here and they are not the same one:
//
//   * a POINT is what the odometer read on a day. Every contributing source
//     produces one, and the projection reads the last of them.
//   * a RATE ENDPOINT is a point a slope may be drawn FROM or TO. Fewer points
//     qualify, and the ones that do not are the reason this type exists.
//
// Draw a slope between two readings six hours apart and the answer is
// "400 km/day", which projects a service into next week and puts a red card on
// the home screen of somebody whose car is fine. Draw one across an odometer
// replacement and the answer is negative.
//
// The three normalisation steps run IN THE ORDER SPEC states, because the order
// changes the answer — collapse before sort pairs the wrong two readings, and
// marking endpoints before restarting at a decrease marks a slope across it.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/value_equality.dart';

/// One reading, reduced to what the projection needs.
@immutable
class OdometerPoint with ValueEquality {
  /// Creates a point.
  const OdometerPoint({
    required this.date,
    required this.cumulative,
    required this.isRateEndpoint,
  });

  /// The day it was read.
  final CivilDate date;

  /// What it read, with every correction at or before it applied.
  ///
  /// CUMULATIVE and not the raw dash number: after a cluster replacement the
  /// dash says 1,000 and the car has done 188,412 km, and a distance between
  /// two readings is only the distance driven if both are on the same scale.
  final Distance cumulative;

  /// Whether a slope may be drawn from or to this point.
  final bool isRateEndpoint;

  @override
  List<Object?> get props => [date, cumulative, isRateEndpoint];

  @override
  String toString() =>
      'OdometerPoint($date, ${cumulative.metres}m'
      '${isRateEndpoint ? ', endpoint' : ''})';
}

/// The sources §4.1.1 says contribute a reading to the RATE series.
///
/// Not the same as the sources that contribute to the odometer LOG, which is
/// every one of them. An expense carries an odometer the user typed at a desk
/// while paying an insurance bill — real, worth keeping, and not a measurement
/// of driving. A trip's START duplicates whatever reading preceded it, so
/// counting both manufactures a same-day pair out of one journey.
const rateSeriesSources = <OdometerSource>{
  OdometerSource.manual,
  OdometerSource.fillUp,
  OdometerSource.service,
  OdometerSource.tripEnd,
  OdometerSource.import,
};

/// A vehicle's readings, normalised.
@immutable
class ReadingSeries with ValueEquality {
  const ReadingSeries._(this.points);

  /// Normalises [readings] against [corrections], per SPEC.md §4.1.1.
  factory ReadingSeries.from(
    Iterable<OdometerReading> readings,
    Iterable<OdometerCorrection> corrections,
  ) {
    final contributing = readings
        .where((r) => rateSeriesSources.contains(r.source))
        .toList();
    if (contributing.isEmpty) return const ReadingSeries._([]);

    // Step 1 — sort ascending. `compareReadings` breaks a date tie on
    // created-at and then on id, so the order is total and two runs agree.
    final sorted = contributing.map(_asReadingPoint).toList()
      ..sort(compareReadings);

    // Corrections, because every later step compares odometers and a
    // comparison on the raw dash number is a comparison across two scales.
    //
    // `cumulativeBySorted` and not `cumulativeByReading`: the latter sorts
    // internally, so calling it here mapped and sorted the same 1,000 readings
    // TWICE. EPIC-06 split the sorted form out for exactly this reason and its
    // doc says so — passing an unsorted list to it is a wrong answer rather
    // than a slow one, which is why the sort above comes first.
    final cumulative = cumulativeBySorted(
      sorted,
      corrections.map(_asCorrectionPoint),
    );

    final byDate = <String, Distance>{};
    for (final reading in sorted) {
      final value = cumulative[reading.id]!;
      final existing = byDate[reading.occurredOn];
      // The evening reading is what is true at end of day.
      if (existing == null || value > existing) {
        byDate[reading.occurredOn] = value;
      }
    }

    // Explicit, though `byDate` was filled in sorted order and Dart's default
    // map preserves insertion order — so this currently sorts an already
    // sorted list. It stays because the alternative is depending on a map
    // implementation detail for the ordering of the whole series, and nothing
    // would fail loudly the day somebody swaps the map type.
    final dates = byDate.keys.toList()..sort();
    // A date the schema permits and no calendar has is SKIPPED, not fatal.
    //
    // `occurred_on`'s only constraint is a GLOB on the shape, so `2026-02-30`,
    // `2026-13-01` and `0000-00-00` all pass it and `CivilDate.tryParse`
    // correctly refuses all three. This took the result with a `!` — and a
    // backup carrying one such row imported cleanly and then threw on every
    // app foreground, so the home screen never rendered again and the user
    // could not reach the data to fix it.
    //
    // A row nobody can read costs that row. `monotonicity.dart` was changed to
    // the same rule in this epic: a date that will not parse yields no answer
    // rather than a wrong one.
    final collapsed = [
      for (final date in dates)
        if (CivilDate.tryParse(date) case final parsed?)
          (parsed, byDate[date]!),
    ];

    // Steps 2 and 3 in ONE forward pass, and in that order: a decrease
    // restarts the run, and only then is the >= 1 day gap measured — against
    // the previous ENDPOINT rather than the previous point, so a same-day pair
    // followed by a reading a month later does not inherit the gap.
    final points = <OdometerPoint>[];
    CivilDate? lastEndpointDate;
    Distance? previous;

    for (final (date, value) in collapsed) {
      if (previous != null && value < previous) {
        // Step 2. A drop with no correction behind it is a replaced cluster
        // nobody recorded, or a typo. Everything before it was measured on a
        // DIFFERENT SCALE, so no slope may cross the drop and none of the
        // earlier endpoints may pair with anything after it — the endpoint set
        // restarts here, which means the earlier ones are withdrawn as well.
        //
        // Keeping 116,050 as an endpoint and pairing it with a later 5,000
        // gives a fall of 111,050 km, which is the exact answer the restart
        // exists to prevent.
        //
        // This point is not itself an endpoint: it is the last reading of the
        // old scale to the arithmetic and the first of the new one to the
        // user, and the only safe thing to do with that ambiguity is refuse to
        // draw a line through it. It still ANCHORS the timing, so the next
        // endpoint has to be a day or more after it.
        for (var i = 0; i < points.length; i++) {
          points[i] = OdometerPoint(
            date: points[i].date,
            cumulative: points[i].cumulative,
            isRateEndpoint: false,
          );
        }
        points.add(
          OdometerPoint(date: date, cumulative: value, isRateEndpoint: false),
        );
        lastEndpointDate = date;
        previous = value;
        continue;
      }

      // Step 3, and it is DEFENSIVE rather than load-bearing — which is worth
      // saying, because a reader who assumes it is doing work will not
      // understand why removing it changes nothing.
      //
      // SPEC.md §4.1.1 lists it as a separate rule ("a reading is a rate
      // endpoint only if it is >= 1 day from the previous endpoint. Same-day
      // pairs produce meaningless rates") and step 1 has ALREADY made it
      // unreachable: `byDate` is keyed by `occurred_on`, so every surviving
      // point has a distinct date and every gap is at least one day. A
      // mutation to `>= 0` passes the whole suite, and that is the honest
      // reason this comment exists rather than a test.
      //
      // It stays because it is free and because step 1 is the thing making it
      // true: the day somebody collapses per-source instead of per-date, this
      // is the line that stops a six-hour slope, and the assertion below is
      // what will tell them.
      assert(
        lastEndpointDate == null || lastEndpointDate.daysUntil(date) >= 1,
        'step 1 should have collapsed $date; two points share a date',
      );
      final isEndpoint =
          lastEndpointDate == null || lastEndpointDate.daysUntil(date) >= 1;

      points.add(
        OdometerPoint(
          date: date,
          cumulative: value,
          isRateEndpoint: isEndpoint,
        ),
      );
      if (isEndpoint) lastEndpointDate = date;
      previous = value;
    }

    return ReadingSeries._(List.unmodifiable(points));
  }

  /// Every contributing reading, oldest first, corrections applied.
  final List<OdometerPoint> points;

  /// The subset a slope may be drawn between.
  List<OdometerPoint> get rateEndpoints => [
    for (final p in points)
      if (p.isRateEndpoint) p,
  ];

  /// The most recent point, or null on an empty vehicle.
  OdometerPoint? get last => points.isEmpty ? null : points.last;

  @override
  List<Object?> get props => points;

  @override
  String toString() => 'ReadingSeries(${points.length} points)';
}

ReadingPoint _asReadingPoint(OdometerReading reading) => (
  id: reading.id.toString(),
  occurredOn: reading.occurredOn,
  createdAtUtcMs: reading.createdAtUtcMs,
  odometer: reading.odometer,
);

CorrectionPoint _asCorrectionPoint(OdometerCorrection correction) => (
  fromReadingId: correction.fromReadingId.toString(),
  previous: correction.previous,
  replacement: correction.replacement,
);
