// One rate, four rungs, one clamp.
//
// SPEC.md §4.1.2. Every projected date in this app divides by this number, so
// it is also the single biggest source of a wrong answer that looks right.
//
// The rung order is the design: each is less true than the one above it, and
// the CONFIDENCE says which was used. That is what lets a screen render a firm
// date for a measured rate and a fuzzy one — "around mid-October" — for an
// assumed or defaulted one, per SPEC.md §2's rule that the app never guesses in
// a way that looks like fact.
import 'package:meta/meta.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// The recency window a slope is preferred to be measured over.
///
/// It leans recent ON PURPOSE. SPEC.md §4.1.2: "an estimate that overshoots is
/// corrected at the next reading; a lagging one silently misses the due point."
const kRateWindowDays = 180;

/// The shortest baseline that counts as a measurement.
///
/// A fortnight is where a week off work stops dominating the answer.
const kRateMinSpanDays = 14;

/// The least distance between two endpoints that counts as a measurement.
///
/// A month of barely driving says nothing about the month ahead.
const kRateMinDistanceMetres = 100000;

/// 5 km/day. Below this the number came from a typo, not from driving.
const kRateFloorMetresPerDay = 5000;

/// 500 km/day. Above this, likewise.
const kRateCeilingMetresPerDay = 500000;

/// 12,000 km a year, the rate a vehicle added five minutes ago gets.
///
/// It exists so the home screen shows SOMETHING rather than an empty state on
/// the day a user adds their car.
const kDefaultAnnualMetres = 12000000;

/// How much to trust a rate.
enum RateConfidence {
  /// A real slope between two real readings.
  measured('measured'),

  /// Derived from the vehicle's `expected_annual_m`, which the user typed at
  /// first run rather than measured.
  assumed('assumed'),

  /// [kDefaultAnnualMetres]. Nothing about this vehicle informed it.
  ///
  /// Named `defaulted` because `default` is a Dart reserved word. SPEC.md
  /// §4.1 calls this rung `default` and [wire] is what any payload carries, so
  /// the spelling difference stops at the language boundary.
  defaulted('default');

  const RateConfidence(this.wire);

  /// The value as SPEC.md §4.1 names it.
  final String wire;
}

/// A rate, and how much to trust it.
@immutable
class DailyDistance with ValueEquality {
  /// Creates a rate.
  const DailyDistance({
    required this.metresPerDay,
    required this.confidence,
  });

  /// Metres per day, always within the clamp.
  final int metresPerDay;

  /// Which rung of §4.1.2 produced it.
  final RateConfidence confidence;

  @override
  List<Object?> get props => [metresPerDay, confidence];

  @override
  String toString() => 'DailyDistance($metresPerDay m/day, ${confidence.wire})';
}

/// The rate for a vehicle, per SPEC.md §4.1.2's four rungs.
///
/// [expectedAnnualMetres] comes from the vehicle row. §3 writes this signature
/// as `dailyDistance(readings, today)` and §4.1.2 as `dailyDistance(vehicle)`;
/// the pure core cannot hold a `Vehicle`, so the readings form wins and the one
/// field it needs is passed in.
///
/// Total: an empty series with no expected annual returns the default rate
/// rather than throwing or returning null. Every caller is a screen.
DailyDistance dailyDistance(
  ReadingSeries series, {
  required int? expectedAnnualMetres,
  required CivilDate today,
}) {
  final endpoints = series.rateEndpoints;

  // Rung 1a — the window. `a` is the earliest endpoint INSIDE it, `b` the
  // latest endpoint overall: a reading older than the window cannot open a
  // slope, but the newest reading always closes one.
  final windowStart = today.addDays(-kRateWindowDays);
  final inWindow = [
    for (final point in endpoints)
      if (point.date >= windowStart) point,
  ];

  final measured =
      _slope(inWindow) ?? // rung 1a — the window
      _slope(endpoints); // rung 1b — the same test over all history

  if (measured != null) {
    return DailyDistance(
      metresPerDay: _clamp(measured),
      confidence: RateConfidence.measured,
    );
  }

  // Rung 2 — what the user said they drive.
  if (expectedAnnualMetres != null && expectedAnnualMetres > 0) {
    return DailyDistance(
      metresPerDay: _clamp(expectedAnnualMetres ~/ 365),
      confidence: RateConfidence.assumed,
    );
  }

  // Rung 3 — 12,000 km a year.
  return DailyDistance(
    metresPerDay: _clamp(kDefaultAnnualMetres ~/ 365),
    confidence: RateConfidence.defaulted,
  );
}

/// The two-endpoint slope across [points], or null when it does not qualify as
/// a measurement.
///
/// **The slope, never the mean of per-segment rates.** SPEC.md §4.1.2: a mean
/// gives a one-day gap the same weight as a two-month one, so one short segment
/// during a holiday week can double the estimate.
///
/// SPEC phrases rung 1a as "a = earliest endpoint IN WINDOW, b = latest
/// endpoint OVERALL", which reads as two different lists and is one: the window
/// is `[today - 180 days, ...]` with no upper bound, so the latest endpoint in
/// it is the latest endpoint there is. Writing it as two lists produced a
/// parameter no input could distinguish — a mutation swapping them passed every
/// test, because there is no such input. One list, and this note so the next
/// reader does not "restore" the spec's phrasing thinking it was lost.
int? _slope(List<OdometerPoint> points) {
  if (points.isEmpty) return null;

  final a = points.first;
  final b = points.last;

  final days = a.date.daysUntil(b.date);
  if (days < kRateMinSpanDays) return null;

  final metres = b.cumulative.metres - a.cumulative.metres;
  if (metres < kRateMinDistanceMetres) return null;

  return metres ~/ days;
}

/// Bounds a rate to §4.1.2's 5-500 km/day.
///
/// The NUMBER only. The confidence is never demoted by a clamp: the readings
/// really were measured, and letting a typo change how every other figure on
/// the screen is rendered would spread one bad row across the whole vehicle.
int _clamp(int metresPerDay) => metresPerDay < kRateFloorMetresPerDay
    ? kRateFloorMetresPerDay
    : metresPerDay > kRateCeilingMetresPerDay
    ? kRateCeilingMetresPerDay
    : metresPerDay;
