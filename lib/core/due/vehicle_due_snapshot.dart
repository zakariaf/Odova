// The one function every §4.2.1 trigger calls.
//
// SPEC.md §4.2.1's trigger table — a new reading, a reminder edited, a vehicle
// archived, the app foregrounded after six hours, a full rebuild — all lead
// here. §4.2.1: "Reprojection is a pure function over the local database, and
// five vehicles x 16 reminders is 80 rows of arithmetic. Recompute everything,
// always; there is no incremental-invalidation cleverness to get wrong."
//
// So this is deliberately not incremental, and
// `test/core/due/vehicle_due_snapshot_test.dart` asserts the cost so that the
// decision stays affordable rather than becoming a thing somebody optimises
// later on a hunch.
//
// The rate and the estimate are computed ONCE for the vehicle, not once per
// item: they depend on the reading series and nothing else, and sixteen
// identical slope computations per vehicle is the one piece of waste this
// shape makes easy.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_engine.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/due_summary.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// Everything a screen needs about one vehicle's reminders.
@immutable
class VehicleDueSnapshot with ValueEquality {
  /// Creates a snapshot.
  const VehicleDueSnapshot({
    required this.assessments,
    required this.summary,
    required this.rate,
    required this.clock,
    this.estimate,
    this.nextDueOn,
  });

  /// One entry per ELIGIBLE item, in the order they were given.
  ///
  /// Ineligible items — paused, untracked — are absent rather than present with
  /// a placeholder state, because §3 does not give them one.
  final List<AssessedItem> assessments;

  /// The counts and the worst item, for the garage row and Home.
  final DueSummary summary;

  /// The vehicle's daily distance, computed once.
  final DailyDistance rate;

  /// The current odometer, computed once. Null when the vehicle has no
  /// readings at all.
  final OdometerEstimate? estimate;

  /// The earliest projected due date over eligible, unsnoozed items.
  final CivilDate? nextDueOn;

  /// Whether the device clock was believed.
  final ClockSuspicion clock;

  @override
  List<Object?> get props => [
    // The ids and the assessments THEMSELVES, not a string built from them.
    //
    // This encoded each pair as `'${item.id}:$assessment'`, and
    // `DueAssessment.toString()` prints only `state` and `driver` — so two
    // snapshots whose remaining metres, remaining days, due date, projection,
    // confidence and progress all differed compared EQUAL. `valuesEqual` is the
    // `distinct` predicate on the repositories' watch streams, so the home
    // screen would not have rebuilt when the only thing that changed was the
    // numbers it renders.
    //
    // A `toString()` is a debug convenience and must never be load-bearing for
    // equality. `DueAssessment` already has full value equality; the item is
    // compared by ID because two snapshots naming the same reminders are the
    // same snapshot whatever else that row has changed.
    for (final (item, _) in assessments) item.id,
    for (final (_, assessment) in assessments) assessment,
    summary,
    rate,
    estimate,
    nextDueOn,
    clock,
  ];

  @override
  String toString() =>
      'VehicleDueSnapshot(${assessments.length} items, ${summary.counts})';
}

/// Recomputes everything for one vehicle. Pure: reads nothing, writes nothing.
///
/// [buildDate] is what `today` is validated against — SPEC.md §3's
/// `[build_date, build_date + 10 years]`. When the clock is suspect every item
/// reports `unknown` and no projection is produced, because a due date computed
/// from a date the app does not believe is a confident wrong answer, which §2
/// rates worse than no answer.
VehicleDueSnapshot recomputeVehicle(
  Vehicle vehicle,
  List<ServiceItem> items,
  List<ServiceRecord> records,
  ReadingSeries series,
  AppSettings settings, {
  required CivilDate today,
  required CivilDate buildDate,
}) {
  final clock = assessClock(today: today, buildDate: buildDate);

  // Once per vehicle, not once per item.
  final rate = dailyDistance(
    series,
    expectedAnnualMetres: vehicle.expectedAnnual?.metres,
    today: today,
  );
  final estimate = estimateOdometer(series, rate, today: today);

  // Once per vehicle too: `resolveAnchor` otherwise walks every record and
  // every line for each of sixteen items.
  final completing = newestCompletingByItem(records);

  final assessments = <AssessedItem>[];
  for (final item in items) {
    if (!isEligible(item)) continue;

    if (clock.isSuspect) {
      // §3: "every due state renders `unknown`". Uniformly, whatever the item's
      // intervals say — the arithmetic is fine and the date it starts from is
      // not.
      assessments.add((
        item,
        DueAssessment(
          state: DueState.unknown,
          driver: DueDriver.none,
          confidence: rate.confidence,
          progress: 0,
        ),
      ));
      continue;
    }

    final anchor = resolveAnchor(
      item,
      records,
      vehicle,
      series,
      completingIndex: completing,
    );
    final window = noticeWindow(
      item: item,
      vehicle: vehicle,
      settings: settings,
    );
    // The engine fills `confidence` and `projectedDueDate` itself now. This
    // used to reconstruct all nine fields to overwrite exactly those two, which
    // meant the engine's return value was never a valid assessment on its own
    // and only this caller knew how to finish it.
    assessments.add((
      item,
      computeDueState(
        item,
        anchor,
        estimate,
        window,
        today: today,
        rate: rate,
        series: series,
      ),
    ));
  }

  return VehicleDueSnapshot(
    assessments: List.unmodifiable(assessments),
    summary: dueSummary(assessments),
    rate: rate,
    estimate: estimate,
    // Nothing to schedule against when the clock is not believed.
    //
    // DEFENSIVE, not load-bearing: in suspect mode every assessment above is
    // built with a null `projectedDueDate`, so `nextDue` already returns null
    // and removing this guard passes the suite. It stays because the
    // alternative is that `nextDueOn` depends on a detail of how the suspect
    // branch happens to construct its assessment — give that branch a
    // projection one day, for a screen that wants to show something greyed
    // out, and notifications quietly start scheduling against a date the app
    // does not believe.
    nextDueOn: clock.isSuspect ? null : nextDue(assessments, today: today),
    clock: clock,
  );
}
