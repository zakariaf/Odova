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
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/l10n/relative_date.dart';
import 'package:odova/core/odometer/cumulative.dart';

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
    required this.previousCumulativeM,
    required this.previousOccurredOn,
    required this.attemptedCumulativeM,
  });

  /// What the neighbour it must not go below reads, cumulatively.
  final int previousCumulativeM;

  /// And when. The UI names both — "Your earliest reading is 140,000 km on
  /// 2 September" — because a bare refusal gives the user nothing to act on.
  final String previousOccurredOn;

  /// What was offered.
  final int attemptedCumulativeM;
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
const int _maxPlausibleJumpM = 100000 * 1000;

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
  int? purchaseOdometerM,
}) {
  // The proposed reading is folded IN, so its own cumulative value accounts
  // for every correction at or before it. Checking the raw dash number against
  // a corrected neighbour is how a legitimate post-cluster-swap reading gets
  // refused.
  final all = [...existing, proposed];
  final cumulative = cumulativeByReading(all, corrections);
  final ordered = [...all]..sort(compareReadings);
  final index = ordered.indexWhere((r) => r.id == proposed.id);

  final proposedM = cumulative[proposed.id]!;
  final before = index > 0 ? ordered[index - 1] : null;
  final after = index < ordered.length - 1 ? ordered[index + 1] : null;

  final warnings = <OdometerWarning>[];
  OdometerBlocked? blocked;

  if (before != null) {
    final beforeM = cumulative[before.id]!;
    if (proposedM < beforeM) {
      blocked = OdometerBlocked(
        previousCumulativeM: beforeM,
        previousOccurredOn: before.occurredOn,
        attemptedCumulativeM: proposedM,
      );
    } else {
      warnings.addAll(
        _softWarnings(
          fromM: beforeM,
          toM: proposedM,
          fromDate: before.occurredOn,
          toDate: proposed.occurredOn,
          vehicleUnit: vehicleUnit,
        ),
      );
    }
  } else if (purchaseOdometerM != null && proposedM < purchaseOdometerM) {
    // The new earliest reading, below what the car read when it was bought.
    // SPEC.md §3: allowed if `>= purchase_odometer_m` when set.
    blocked = OdometerBlocked(
      previousCumulativeM: purchaseOdometerM,
      previousOccurredOn: proposed.occurredOn,
      attemptedCumulativeM: proposedM,
    );
  }

  // A backdated entry also has to fit UNDER its successor. Without this a
  // reading slotted between two others could exceed the one after it, and the
  // history would be non-monotonic at a point nobody looked at.
  if (blocked == null && after != null) {
    final afterM = cumulative[after.id]!;
    if (proposedM > afterM) {
      blocked = OdometerBlocked(
        previousCumulativeM: afterM,
        previousOccurredOn: after.occurredOn,
        attemptedCumulativeM: proposedM,
      );
    }
  }

  return OdometerVerdict(blocked: blocked, warnings: warnings);
}

/// The three warnings, evaluated on a pair of cumulative metres.
List<OdometerWarning> _softWarnings({
  required int fromM,
  required int toM,
  required String fromDate,
  required String toDate,
  required DistanceUnit vehicleUnit,
}) {
  final warnings = <OdometerWarning>[];
  final jump = toM - fromM;

  // Counted as CIVIL days, through the same UTC anchoring `wholeDaysBetween`
  // uses. `DateTime.parse('2026-03-28')` returns a LOCAL time, and across a
  // European spring-forward two dates two calendar days apart differ by
  // 23 + 24 hours — which `inDays` truncates to 1. The implied rate then
  // DOUBLES, and a driver who did 1,100 km/day over that weekend is told they
  // did 2,200.
  //
  // The same trap `lib/core/l10n/relative_date.dart` already documents: "a
  // 23-hour day across a daylight-saving boundary is still one day".
  final days = wholeDaysBetween(
    DateTime.parse(fromDate),
    DateTime.parse(toDate),
  );
  // Same-day readings have no rate to imply — dividing by zero days would
  // make every second entry of the day look impossible.
  if (days > 0 && jump ~/ days > _maxPlausibleMetresPerDay) {
    warnings.add(OdometerWarning.impliedRateHigh);
  }

  if (jump > _maxPlausibleJumpM) warnings.add(OdometerWarning.jumpVeryLarge);

  // Only on a miles vehicle, and only against a non-zero predecessor. The
  // ratio is 1.609; the band is around it because a real jump lands there
  // sometimes, which is exactly why this warns instead of blocking.
  if (vehicleUnit == DistanceUnit.mi && fromM > 0) {
    final ratio = toM / fromM;
    if (ratio >= 1.5 && ratio <= 1.7) {
      warnings.add(OdometerWarning.probableUnitMixUp);
    }
  }

  return warnings;
}
