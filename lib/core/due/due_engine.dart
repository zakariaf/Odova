// One reminder, one vehicle, one date: a state, a driver, and the numbers.
//
// SPEC.md §3 *Due state per item*, and §2's rule that `whichever_first` is the
// only combining rule there is.
//
// Two axes, assessed independently and combined by severity. An item has a
// distance axis only if it has a distance interval or a target odometer, and a
// time axis only if it has a month interval or a target date — which is DERIVED
// from the fields, not stored as a mode. A stored mode is a third thing that
// can disagree with the two it describes.
import 'package:meta/meta.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/due_state.dart';
import 'package:odova/core/due/estimate_odometer.dart';
import 'package:odova/core/due/notice_window.dart';
import 'package:odova/core/due/project_due_date.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/due/resolve_anchor.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// How stale a reading may be before a `due` or `overdue` distance axis is
/// downgraded to `needsOdometer`.
///
/// SPEC.md §3: strictly greater than 60. Distinct from
/// [kProjectionExpiryDays], which is stronger and applies at every severity.
const kStaleOdometerDays = 60;

/// What the engine concluded about one item.
@immutable
class DueAssessment with ValueEquality {
  /// Creates an assessment.
  const DueAssessment({
    required this.state,
    required this.driver,
    required this.confidence,
    required this.progress,
    this.remainingMetres,
    this.remainingDays,
    this.dueAtOdometerMetres,
    this.dueOn,
    this.projectedDueDate,
  });

  /// The state a card renders.
  final DueState state;

  /// Which axis produced it. Selects the copy pattern, never the colour.
  final DueDriver driver;

  /// Metres until due; negative once past. Null when there is no distance axis.
  final int? remainingMetres;

  /// Days until due; negative once past. Null when there is no time axis.
  final int? remainingDays;

  /// The odometer this item is due at, in canonical metres.
  final int? dueAtOdometerMetres;

  /// The date this item is due on, from the time axis.
  final CivilDate? dueOn;

  /// The distance axis's due date, projected at the current rate.
  ///
  /// The single sort key across both axes — see `project_due_date.dart`.
  final CivilDate? projectedDueDate;

  /// How much to trust the rate behind [projectedDueDate] and any `~` figure.
  final RateConfidence confidence;

  /// How far through the interval, as the GREATER of the two axes' fractions.
  ///
  /// Each fraction is `(now − anchor) / (due − anchor)` on its own axis.
  /// **Floored at 0 and deliberately not capped above 1**: a bar that stops at
  /// full cannot show that an item is 60% past due, and SPEC.md §3 asks for
  /// "the max of the two axes' fractions" without defining either fraction —
  /// the definition is here and in SPEC.md, changed in the same PR.
  final double progress;

  @override
  List<Object?> get props => [
    state,
    driver,
    remainingMetres,
    remainingDays,
    dueAtOdometerMetres,
    dueOn,
    projectedDueDate,
    confidence,
    progress,
  ];

  @override
  String toString() => 'DueAssessment(${state.name}, ${driver.name})';
}

/// Whether the engine runs for [item] at all.
///
/// `paused` (`is_active == false`) and untracked items have no due state —
/// they are filtered BEFORE the engine, not represented inside it. That is why
/// neither appears in [DueState].
bool isEligible(ServiceItem item) => item.isTracked && item.isActive;

/// The worse of two states, by SPEC.md §3's severity order.
///
/// `ok < due_soon < due < overdue`. Exposed because the combine is a rule
/// worth testing directly rather than only through the engine.
DueState worseOf(DueState a, DueState b) =>
    _severity(a) >= _severity(b) ? a : b;

int _severity(DueState state) => switch (state) {
  DueState.ok => 0,
  DueState.unknown => 0,
  DueState.needsOdometer => 1,
  DueState.dueSoon => 1,
  DueState.due => 2,
  DueState.overdue => 3,
};

/// The due state of [item], per SPEC.md §3.
///
/// Takes the [rate] and the [series] so it can fill `confidence` and
/// `projectedDueDate` itself. It used to fill neither honestly — `confidence`
/// was a hardcoded `measured`, `projectedDueDate` was a documented `null`, and
/// exactly one caller knew to overwrite both. A return value that is never
/// valid on its own invites the next caller to forget, and the fixture matrix
/// pinned the hardcoded constant as though it were spec output.
DueAssessment computeDueState(
  ServiceItem item,
  DueAnchor anchor,
  OdometerEstimate? estimate,
  NoticeWindow window, {
  required CivilDate today,
  required DailyDistance rate,
  required ReadingSeries series,
}) {
  final distance = _distanceAxis(item, anchor, estimate, window);
  final time = _timeAxis(item, anchor, window, today);

  // The stale-odometer downgrade, applied to the DISTANCE axis alone. §3: ask
  // for a reading rather than make an accusation supportable only by
  // arithmetic. `due_soon` still shows normally — a warning on slightly old
  // arithmetic is still worth having.
  var distanceState = distance.state;
  if (estimate != null && distanceState != null) {
    final expired = estimate.projection == OdometerProjection.expired;
    final stale = estimate.staleDays > kStaleOdometerDays;
    final accusing =
        distanceState == DueState.due || distanceState == DueState.overdue;
    // Expiry is stronger: past 180 days there is no projected figure at all,
    // so the axis cannot be placed at ANY severity (§4.1.3).
    if (expired || (stale && accusing)) distanceState = DueState.needsOdometer;
  }

  if (distanceState == null && time.state == null) {
    return const DueAssessment(
      state: DueState.unknown,
      driver: DueDriver.none,
      confidence: RateConfidence.defaulted,
      progress: 0,
    );
  }

  final state = distanceState == null
      ? time.state!
      : time.state == null
      ? distanceState
      : worseOf(distanceState, time.state!);

  final assessment = DueAssessment(
    state: state,
    driver: _driver(distanceState, time.state, state),
    remainingMetres: distance.remaining,
    remainingDays: time.remaining,
    dueAtOdometerMetres: distance.dueAt,
    dueOn: time.dueOn,
    confidence: rate.confidence,
    progress: _progress(distance, time, anchor, estimate, today),
  );

  return DueAssessment(
    state: assessment.state,
    driver: assessment.driver,
    remainingMetres: assessment.remainingMetres,
    remainingDays: assessment.remainingDays,
    dueAtOdometerMetres: assessment.dueAtOdometerMetres,
    dueOn: assessment.dueOn,
    projectedDueDate: projectDueDate(
      dueOn: assessment.dueOn,
      dueAtOdometerMetres: assessment.dueAtOdometerMetres,
      series: series,
      rate: rate,
      today: today,
    ),
    confidence: assessment.confidence,
    progress: assessment.progress,
  );
}

/// Which axis produced [state].
DueDriver _driver(DueState? distance, DueState? time, DueState state) {
  final byDistance =
      distance != null && _severity(distance) == _severity(state);
  final byTime = time != null && _severity(time) == _severity(state);
  return byDistance && byTime
      ? DueDriver.both
      : byDistance
      ? DueDriver.distance
      : byTime
      ? DueDriver.time
      : DueDriver.none;
}

typedef _Axis = ({
  DueState? state,
  int? remaining,
  int? dueAt,
  CivilDate? dueOn,
});

/// The distance axis, or a null state when the item has none.
_Axis _distanceAxis(
  ServiceItem item,
  DueAnchor anchor,
  OdometerEstimate? estimate,
  NoticeWindow window,
) {
  final target = item.targetOdometer?.metres;
  final interval = item.intervalDistance?.metres;
  if (target == null && interval == null) {
    return (state: null, remaining: null, dueAt: null, dueOn: null);
  }

  final base = anchor.odometerMetres;
  final dueAt = target ?? (base == null ? null : base + interval!);
  if (dueAt == null || estimate == null) {
    return (state: null, remaining: null, dueAt: dueAt, dueOn: null);
  }

  final remaining = dueAt - estimate.metres;
  return (
    state: _band(
      remaining,
      window.noticeDistanceMetres,
      window.graceDistanceMetres,
    ),
    remaining: remaining,
    dueAt: dueAt,
    dueOn: null,
  );
}

/// The time axis, or a null state when the item has none.
_Axis _timeAxis(
  ServiceItem item,
  DueAnchor anchor,
  NoticeWindow window,
  CivilDate today,
) {
  final target = CivilDate.tryParse(item.targetDate ?? '');
  final months = item.intervalMonths;
  if (target == null && months == null) {
    return (state: null, remaining: null, dueAt: null, dueOn: null);
  }

  final base = anchor.date;
  final dueOn = target ?? base?.addMonths(months!);
  if (dueOn == null) {
    return (state: null, remaining: null, dueAt: null, dueOn: null);
  }

  final remaining = today.daysUntil(dueOn);
  return (
    state: _band(remaining, window.noticeDays, window.graceDays),
    remaining: remaining,
    dueAt: null,
    dueOn: dueOn,
  );
}

/// SPEC.md §3's four bands, shared by both axes.
///
/// The boundaries are inclusive where §3 writes them inclusive:
/// `remaining > notice` is ok, `0 < remaining <= notice` is due_soon,
/// `-grace <= remaining <= 0` is due, and anything below is overdue.
DueState _band(int remaining, int notice, int grace) {
  if (remaining > notice) return DueState.ok;
  if (remaining > 0) return DueState.dueSoon;
  if (remaining >= -grace) return DueState.due;
  return DueState.overdue;
}

/// The greater of the two axes' fractions, floored at 0 and uncapped above.
double _progress(
  _Axis distance,
  _Axis time,
  DueAnchor anchor,
  OdometerEstimate? estimate,
  CivilDate today,
) {
  var best = 0.0;

  final base = anchor.odometerMetres;
  final dueAt = distance.dueAt;
  if (base != null && dueAt != null && estimate != null && dueAt != base) {
    best = _atLeast(best, (estimate.metres - base) / (dueAt - base));
  }

  final from = anchor.date;
  final dueOn = time.dueOn;
  if (from != null && dueOn != null && from.daysUntil(dueOn) != 0) {
    best = _atLeast(best, from.daysUntil(today) / from.daysUntil(dueOn));
  }

  return best;
}

double _atLeast(double current, double candidate) =>
    candidate > current ? candidate : current;
