// Can this reading be written, and if so what should the user be told?
//
// SPEC.md §3 Invariants (Monotonicity, Soft warnings) and §14 Odometer and
// data integrity. Pure Dart: the repository calls it, and the decision is
// testable at every threshold with three records and no database.
//
// The distinction that runs through the whole file: a monotonicity violation
// BLOCKS and offers three resolutions, and a soft warning WARNS AND WRITES. A
// warning that blocks makes the app unusable for the delivery driver who
// really did do 900 km yesterday; a violation that writes corrupts the
// distance history for everything downstream.
import 'package:meta/meta.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/core/units/distance.dart';

/// Something worth telling the user, that does not stop the write.
enum OdometerWarning {
  /// More than 2,000 km/day since the previous reading.
  ///
  /// Real for a delivery driver on a long day, and a missing digit otherwise.
  /// SPEC.md is explicit that this warns and never blocks.
  impliedRateHigh,

  /// A single jump above 100,000 km.
  jumpVeryLarge,

  /// 1.5x-1.7x the predecessor on a MILES vehicle: a probable km/mi mix-up.
  ///
  /// 1.609 is the ratio, and the band is around it because a real jump lands
  /// there sometimes. Evaluated after the per-entry unit conversion, so it is
  /// comparing two numbers already in metres.
  probableUnitMixUp,
}

/// Why a reading cannot be written.
@immutable
class OdometerBlocked {
  /// Creates a block.
  const OdometerBlocked({
    required this.previousCumulative,
    required this.previousOccurredOn,
    required this.attemptedCumulative,
  });

  /// What the neighbour it must not go below reads, cumulatively.
  final Distance previousCumulative;

  /// And when. The UI names both — "Your earliest reading is 140,000 km on
  /// 2 September" — because a bare refusal gives the user nothing to act on.
  final String previousOccurredOn;

  /// What was offered.
  final Distance attemptedCumulative;
}

/// The verdict on one proposed reading.
@immutable
class OdometerVerdict {
  /// Creates a verdict.
  const OdometerVerdict({required this.warnings, this.blocked});

  /// Non-null when the reading must not be written.
  final OdometerBlocked? blocked;

  /// Told to the user either way. A blocked reading can also be implausible.
  final List<OdometerWarning> warnings;

  /// Whether the reading may be written.
  bool get isAllowed => blocked == null;
}

/// 2,000 km/day, in metres.
const int _maxPlausibleMetresPerDay = 2000 * 1000;

/// 100,000 km, in metres.
const _maxPlausibleJump = Distance(100000 * 1000);

/// Decides whether [proposed] may join [existing].
///
/// [existing] and [corrections] describe the vehicle as it stands. [proposed]
/// is not yet in either.
///
/// Monotonicity is checked against the NEIGHBOURS THAT EXIST and never against
/// a floor. A reading dated before the earliest one is accepted when its
/// cumulative value is lower — that is a used-car buyer typing "96,000 km, May
/// 2019" out of a service book, and SPEC.md §14 says it must never require a
/// correction event.
@useResult
OdometerVerdict checkReading({
  required ReadingPoint proposed,
  required List<ReadingPoint> existing,
  required List<CorrectionPoint> corrections,
  required DistanceUnit vehicleUnit,
  Distance? purchaseOdometer,
}) {
  // The proposed reading is folded IN, so its own cumulative value accounts
  // for every correction at or before it. Checking the raw dash number against
  // a corrected neighbour is how a legitimate post-cluster-swap reading gets
  // refused.
  // Sorted ONCE and used twice: the fold needs the order and so does the
  // neighbour lookup below. This used to build two lists and sort both, on
  // every write, over the vehicle's whole reading history.
  final ordered = [...existing, proposed]..sort(compareReadings);
  final cumulative = cumulativeBySorted(ordered, corrections);
  final index = ordered.indexWhere((r) => r.id == proposed.id);

  final proposedDistance = cumulative[proposed.id]!;
  final before = index > 0 ? ordered[index - 1] : null;
  final after = index < ordered.length - 1 ? ordered[index + 1] : null;

  final warnings = <OdometerWarning>[];
  OdometerBlocked? blocked;

  if (before != null) {
    final beforeDistance = cumulative[before.id]!;
    if (proposedDistance < beforeDistance) {
      blocked = OdometerBlocked(
        previousCumulative: beforeDistance,
        previousOccurredOn: before.occurredOn,
        attemptedCumulative: proposedDistance,
      );
    } else {
      warnings.addAll(
        _softWarnings(
          from: beforeDistance,
          to: proposedDistance,
          fromDate: before.occurredOn,
          toDate: proposed.occurredOn,
          vehicleUnit: vehicleUnit,
        ),
      );
    }
  } else if (purchaseOdometer != null && proposedDistance < purchaseOdometer) {
    // The new earliest reading, below what the car read when it was bought.
    // SPEC.md §3: allowed if `>= purchase_odometer_m` when set.
    blocked = OdometerBlocked(
      previousCumulative: purchaseOdometer,
      previousOccurredOn: proposed.occurredOn,
      attemptedCumulative: proposedDistance,
    );
  }

  // A backdated entry also has to fit UNDER its successor. Without this a
  // reading slotted between two others could exceed the one after it, and the
  // history would be non-monotonic at a point nobody looked at.
  if (blocked == null && after != null) {
    final afterDistance = cumulative[after.id]!;
    if (proposedDistance > afterDistance) {
      blocked = OdometerBlocked(
        previousCumulative: afterDistance,
        previousOccurredOn: after.occurredOn,
        attemptedCumulative: proposedDistance,
      );
    }
  }

  return OdometerVerdict(blocked: blocked, warnings: warnings);
}

/// The three warnings, evaluated on a pair of cumulative metres.
List<OdometerWarning> _softWarnings({
  required Distance from,
  required Distance to,
  required String fromDate,
  required String toDate,
  required DistanceUnit vehicleUnit,
}) {
  final warnings = <OdometerWarning>[];
  final jump = to - from;

  // CIVIL days, through `CivilDate`, which cannot hold a time.
  //
  // This used to be `wholeDaysBetween(DateTime.parse(a), DateTime.parse(b))` —
  // the workaround. `DateTime.parse` on a `YYYY-MM-DD` string is the exact
  // construction `CivilDate` was written to remove: it returns a
  // LOCAL time, so across a European spring-forward two dates two calendar days
  // apart differ by 47 hours and `inDays` truncates to 1: the implied rate then
  // DOUBLES, and a driver who did 1,100 km/day over that weekend is told they
  // did 2,200. `wholeDaysBetween` re-anchored to UTC to fix that, which worked
  // and left the parse in place for the next caller to copy.
  //
  // A date that will not parse yields no warning rather than a wrong one: the
  // dates here come from `occurred_on`, which the schema constrains to
  // `YYYY-MM-DD`, so a failure is corruption and inventing a rate from it would
  // be the guess this whole file exists to avoid.
  final fromDay = CivilDate.tryParse(fromDate);
  final toDay = CivilDate.tryParse(toDate);
  final days = fromDay == null || toDay == null ? 0 : fromDay.daysUntil(toDay);

  // Same-day readings have no rate to imply — dividing by zero days would
  // make every second entry of the day look impossible.
  if (days > 0 && jump.metres ~/ days > _maxPlausibleMetresPerDay) {
    warnings.add(OdometerWarning.impliedRateHigh);
  }

  if (jump > _maxPlausibleJump) warnings.add(OdometerWarning.jumpVeryLarge);

  // Only on a miles vehicle, and only against a non-zero predecessor. The
  // ratio is 1.609; the band is around it because a real jump lands there
  // sometimes, which is exactly why this warns instead of blocking.
  if (vehicleUnit == DistanceUnit.mi && from.metres > 0) {
    final ratio = to.metres / from.metres;
    if (ratio >= 1.5 && ratio <= 1.7) {
      warnings.add(OdometerWarning.probableUnitMixUp);
    }
  }

  return warnings;
}
