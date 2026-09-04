// The current odometer, as a value that knows how it was arrived at.
//
// SPEC.md §3 *Current odometer*, §4.1.3 *The projection expires*, §14
// *Odometer not updated for months*.
//
// The failure this file prevents is named in §14: a reading eight months old,
// extrapolated at 41 km/day, is ten thousand kilometres of invention rendered
// as a number — and every due state downstream then reads as fact.
//
// So the projection STOPS rather than decaying. It does not widen a band or
// lower a confidence; it hands back the last figure the user actually typed and
// says when they typed it, and the strip reads
// "187,412 km · last entered 12 Jul 2025".
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/value_equality.dart';

/// How old a reading may be before the app stops extrapolating from it.
///
/// SPEC.md §4.1.3: "if `today − last.date > 180 days` the window is empty and
/// `odo_now` is invention". Strictly greater — 180 still projects.
const kProjectionExpiryDays = 180;

/// How a figure was arrived at.
///
/// Three members and not a bool. SPEC.md §3's pseudocode writes
/// `is_projected = expired`, which is a boolean holding an enum value; every
/// caller downstream switches on all three, and a bool would make `expired`
/// indistinguishable from `projected` exactly where the difference matters.
enum OdometerProjection {
  /// The user typed this today. Not extrapolated at all.
  entered,

  /// Extrapolated from the last reading at the current rate.
  projected,

  /// The last reading is too old to extrapolate from, so this is that reading
  /// unchanged. **Never carries a projected value.**
  expired,
}

/// An odometer figure and its provenance.
@immutable
class OdometerEstimate with ValueEquality {
  /// Creates an estimate.
  const OdometerEstimate({
    required this.metres,
    required this.asOf,
    required this.projection,
    required this.staleDays,
  });

  /// The figure, in canonical metres.
  ///
  /// For [OdometerProjection.expired] this is the ENTERED value. There is no
  /// field anywhere on this record holding what the projection would have said,
  /// because a screen that can find such a field will eventually render it.
  final int metres;

  /// The date [metres] is true as of.
  ///
  /// Today for a projected figure; the reading's own date for an entered or an
  /// expired one. The UI quotes it, which is the whole point: "last entered
  /// 12 Jul 2025" is honest and "187,412 km" alone is not.
  final CivilDate asOf;

  /// How this figure was arrived at.
  final OdometerProjection projection;

  /// Whole civil days between the last reading and today, never negative.
  final int staleDays;

  @override
  List<Object?> get props => [metres, asOf, projection, staleDays];

  @override
  String toString() =>
      'OdometerEstimate(${metres}m as of $asOf, ${projection.name}, '
      'stale ${staleDays}d)';
}

/// The current odometer for a vehicle, or null when it has no readings.
///
/// **Null and not zero.** Zero is a real odometer value on a car delivered
/// yesterday, so standing it in for "we do not know" makes a new vehicle look
/// like one that has driven nothing and every distance interval instantly due.
OdometerEstimate? estimateOdometer(
  ReadingSeries series,
  DailyDistance rate, {
  required CivilDate today,
}) {
  final last = series.last;
  if (last == null) return null;

  // Never negative. A reading dated in the future — a user typing tomorrow, or
  // a device clock that ran ahead — is still the newest thing there is, and
  // projecting it backwards would report an odometer BELOW the number they
  // just typed.
  final elapsed = last.date.daysUntil(today);
  final staleDays = math.max(0, elapsed);

  if (staleDays == 0) {
    return OdometerEstimate(
      metres: last.cumulative.metres,
      asOf: last.date,
      projection: OdometerProjection.entered,
      staleDays: 0,
    );
  }

  if (staleDays > kProjectionExpiryDays) {
    // §4.1.3. Note what is NOT here: no extrapolation, no decayed rate, no
    // confidence adjustment. The figure is the entered one and `asOf` is the
    // day it was entered, so every distance axis on this vehicle can report
    // `needs_odometer` and no `~` figure appears anywhere.
    return OdometerEstimate(
      metres: last.cumulative.metres,
      asOf: last.date,
      projection: OdometerProjection.expired,
      staleDays: staleDays,
    );
  }

  return OdometerEstimate(
    metres: last.cumulative.metres + rate.metresPerDay * staleDays,
    asOf: today,
    projection: OdometerProjection.projected,
    staleDays: staleDays,
  );
}
