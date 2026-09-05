// Which conditional strips Home shows, and in what order.
//
// SPEC.md §9's *Conditional strips* row: "Max 2, priority: (1)
// done-from-notification confirmation, (2) away digest, (3) stale odometer.
// Overflow queues to the next appearance." And the sentence the whole table
// exists to protect: "A conditional strip pushes the tiles below the fold,
// never the cards — strips are capped at two, and the primary card is never
// displaced."
//
// Pure Dart, no Flutter import. The eligibility of each strip is a fact the
// screen supplies; what to do with three facts is arithmetic, and arithmetic
// belongs where it can be tested at a boundary.
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// §9's cap. Two, and the third waits for the next appearance of Home.
const int kHomeStripCap = 2;

/// `stale_days >= 60` on its own is enough.
const int kStaleOdometerDays = 60;

/// `stale_days >= 30` plus drift is enough.
const int kStaleOdometerDaysWithDrift = 30;

/// The drift that makes 30 days enough: 500 km, or 300 mi.
///
/// Two numbers rather than one converted, because §9 gives both and they are
/// not each other: 300 mi is 483 km, and rounding one into the other would move
/// the threshold for half the users by 17 km.
const Distance kStaleOdometerDriftKm = Distance(500000);

/// The mile-side threshold — 300 mi.
const Distance kStaleOdometerDriftMi = Distance(482803);

/// How long §9's `✕` hides the staleness strip: "7 days, this vehicle".
const int kStalenessDismissalDays = 7;

/// The three strips, in the priority order §9 gives them.
///
/// The ORDER of the enum is the priority. A separate rank table would be a
/// second place for the same decision to live, and the sort below reads the
/// declaration order rather than a number somebody has to keep in step.
enum HomeStripKind {
  /// "You marked Oil and filter done on 12 September." Not dismissible.
  doneConfirmation,

  /// "Oil and filter went overdue on 12 August." One dismissible card.
  awayDigest,

  /// "Odometer last updated 68 days ago", with an inline field and Save.
  staleOdometer,
}

/// The strips to draw, capped and ordered.
///
/// Everything not returned "queues to the next appearance" — which needs no
/// storage, because eligibility is recomputed from the same facts next time.
List<HomeStripKind> homeStripQueue(Set<HomeStripKind> eligible) =>
    List.unmodifiable(
      HomeStripKind.values.where(eligible.contains).take(kHomeStripCap),
    );

/// Whether the odometer is stale enough to ask about.
///
/// §9: "The conditional strip appears when `stale_days >= 60`, or
/// `stale_days >= 30` **and** projected drift exceeds 500 km / 300 mi."
///
/// [driftMetres] is how far the app believes the car has gone since the last
/// reading. It is a PROJECTION, and the threshold is what stops the app asking
/// about a car that has not moved: thirty days of a stationary vehicle is not a
/// stale odometer, it is a holiday.
bool isOdometerStale({
  required int staleDays,
  required int driftMetres,
  required DistanceUnit unit,
}) {
  if (staleDays >= kStaleOdometerDays) return true;
  if (staleDays < kStaleOdometerDaysWithDrift) return false;
  final threshold = unit == DistanceUnit.mi
      ? kStaleOdometerDriftMi
      : kStaleOdometerDriftKm;
  return driftMetres > threshold.metres;
}

/// Whether the `✕` still has this vehicle's strip hidden.
///
/// [dismissedUntil] is the stored value, or null when it was never dismissed.
/// An unparseable one counts as NOT dismissed: a strip shown once too often is
/// a nuisance and a strip hidden forever by a corrupt string is a car whose
/// odometer never gets updated again.
bool isStalenessDismissed(String? dismissedUntil, CivilDate today) {
  if (dismissedUntil == null) return false;
  final until = CivilDate.tryParse(dismissedUntil);
  if (until == null) return false;
  return today.compareTo(until) < 0;
}

/// The day the `✕` hides it until.
CivilDate stalenessDismissedUntil(CivilDate today) =>
    today.addDays(kStalenessDismissalDays);
