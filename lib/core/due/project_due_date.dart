// One comparable sort key across two axes that measure different things.
//
// SPEC.md §3: "`projected_due_date` is the only sort key the home screen uses.
// It makes '10,000 km' and '12 months' comparable on one axis, which is the
// whole point of the app."
//
// It is a SORT KEY and not a promise. An already-overdue item projects into the
// past, which is what puts it above one due next week.
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/time/civil_date.dart';

/// The earlier of the time axis's date and the distance axis's projection.
///
/// **`min` over the axes that EXIST.** A naive minimum treats a null `due_on`
/// as earliest, so a distance-only item would project as "no date" and sort to
/// the top of the home screen forever.
///
/// SPEC.md §3's formula is
/// `min(due_on, last_reading.date + (due_at_odo − cumulative(last)) / rate)`
/// and §4.1.3 writes the same thing from `today` and `odo_now`; they are
/// algebraically identical because `odo_now` is exactly
/// `last + rate × (today − last.date)`, so only one of them is implemented.
///
/// Takes the two axis results rather than a whole `DueAssessment`: the engine
/// calls this while BUILDING one, so depending on the finished type would be a
/// cycle — and the function never needed more than these two numbers.
CivilDate? projectDueDate({
  required CivilDate? dueOn,
  required int? dueAtOdometerMetres,
  required ReadingSeries series,
  required DailyDistance rate,
  required CivilDate today,
}) {
  final candidates = <CivilDate>[
    ?dueOn,
    ?_distanceProjection(dueAtOdometerMetres, series, rate),
  ];

  if (candidates.isEmpty) return null;
  return candidates.reduce((a, b) => a <= b ? a : b);
}

/// When the distance axis will reach its threshold, at the current rate.
CivilDate? _distanceProjection(
  int? dueAt,
  ReadingSeries series,
  DailyDistance rate,
) {
  final last = series.last;
  // A rate of zero cannot project: dividing by it gives an Infinity that
  // becomes a date. `dailyDistance` clamps to 5 km/day so this is unreachable
  // through it, and a caller may hand in any rate.
  if (dueAt == null || last == null || rate.metresPerDay <= 0) return null;

  final remaining = dueAt - last.cumulative.metres;

  // Rounded UP. 52.4 days is 53: a projection that lands the user at the
  // garage AFTER the threshold is the failure mode, and arriving a day early
  // is not. `ceil` on a negative is toward zero, which is right too — an
  // overdue item projects into the past and the exact day is not load-bearing.
  final days = (remaining / rate.metresPerDay).ceil();
  return last.date.addDays(days);
}
