// Which of SPEC.md §10's outcomes the odometer field is in.
//
// One field feeds the due engine, so `log.fillup`, `log.service` and
// `log.odometer` must agree about it exactly — three forms with three opinions
// would write three different histories into one table.
//
// The monotonicity ARITHMETIC is not here. `checkReading` in
// `lib/core/odometer/monotonicity.dart` owns it: it folds the proposed reading
// into the corrected cumulative series, compares it against the neighbours that
// actually exist rather than against a global floor, and returns the three soft
// warnings §10 lists. This file turns that verdict into the four states a FORM
// branches on, and adds the one thing the engine has no opinion about — whether
// this reading is becoming the vehicle's earliest, which decides whether a
// delta can be drawn at all.
import 'package:meta/meta.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/units/distance.dart';

/// What the field concluded about the value in it.
@immutable
sealed class OdometerFieldCheck {
  const OdometerFieldCheck();
}

/// The value may be saved. It may still carry warnings.
final class OdometerFieldOk extends OdometerFieldCheck {
  /// Creates the verdict.
  const OdometerFieldOk({
    this.warnings = const [],
    this.sinceLast,
    this.isNewEarliest = false,
  });

  /// Amber lines, in the order the engine found them. Never a block.
  ///
  /// The ENGINE's enum, not a copy of it. The first version re-declared these
  /// three members as an `OdometerFieldWarning` so a form need not know the
  /// engine's vocabulary — and `one_money_type_test` refused it, correctly:
  /// two enums with the same member set are one vocabulary written twice, and
  /// the second one goes stale the day a fourth warning is added.
  final List<OdometerWarning> warnings;

  /// The live delta §10 calls "the cheapest possible check on a dropped
  /// digit". Null when there is no earlier reading to measure from.
  final Distance? sinceLast;

  /// Whether this reading is becoming the vehicle's earliest.
  ///
  /// §10 suppresses the delta then and changes the helper line: a second-hand
  /// car's first backdated entry has nothing before it to be a delta from.
  final bool isNewEarliest;
}

/// The value is below the reading before it. §10's three-way sheet, never an
/// error: only the user knows whether this is a typo, a replaced cluster or a
/// backdated entry.
final class OdometerFieldBelowLast extends OdometerFieldCheck {
  /// Creates the verdict.
  const OdometerFieldBelowLast({
    required this.previous,
    required this.previousOccurredOn,
    required this.offersOlderEntry,
  });

  /// The neighbour it conflicts with, on the corrected scale.
  final Distance previous;

  /// That neighbour's date. The sheet names both, because §3's three
  /// resolutions all need them.
  final String previousOccurredOn;

  /// Whether to offer "It's an older entry I'm adding now".
  ///
  /// §10 offers it "only when the date is in the past" — in the past relative
  /// to the reading it conflicts with. Offering it otherwise proposes an
  /// answer that cannot be true.
  final bool offersOlderEntry;
}

/// A backdated reading higher than the current earliest. Blocked, and §10's
/// sentence names both ends.
final class OdometerFieldAboveEarliest extends OdometerFieldCheck {
  /// Creates the verdict.
  const OdometerFieldAboveEarliest({
    required this.earliest,
    required this.earliestOccurredOn,
  });

  /// The earliest reading on the vehicle.
  final Distance earliest;

  /// Its date.
  final String earliestOccurredOn;
}

/// The id the proposed reading is folded in under.
///
/// It must not collide with a real reading's id, and it never reaches storage:
/// `checkReading` needs an id to find its own entry in the sorted series, and
/// a form's value has none until it is written.
const kProposedReadingId = '__proposed__';

/// What §10 says about [entered], dated [occurredOn], on this vehicle.
@useResult
OdometerFieldCheck checkOdometerField({
  required Distance entered,
  required String occurredOn,
  required List<ReadingPoint> existing,
  required List<CorrectionPoint> corrections,
  required DistanceUnit vehicleUnit,
  Distance? purchaseOdometer,
}) {
  final proposed = (
    id: kProposedReadingId,
    occurredOn: occurredOn,
    // The newest thing on its date, so a same-day entry compares against what
    // was already there rather than displacing it.
    createdAtUtcMs: 1 << 52,
    odometer: entered,
  );

  final verdict = checkReading(
    proposed: proposed,
    existing: existing,
    corrections: corrections,
    vehicleUnit: vehicleUnit,
    purchaseOdometer: purchaseOdometer,
  );

  final ordered = [...existing, proposed]..sort(compareReadings);
  final index = ordered.indexWhere((r) => r.id == kProposedReadingId);
  final before = index > 0 ? ordered[index - 1] : null;

  if (verdict.blocked case final blocked?) {
    // Blocked with NOTHING before it on the timeline is the above-earliest
    // case: the conflict is with what comes after, or with the purchase
    // reading, and neither is "your last one".
    if (before == null && existing.isNotEmpty) {
      final earliest = ordered.firstWhere((r) => r.id != kProposedReadingId);
      return OdometerFieldAboveEarliest(
        earliest: earliest.odometer,
        earliestOccurredOn: earliest.occurredOn,
      );
    }
    return OdometerFieldBelowLast(
      previous: blocked.previousCumulative,
      previousOccurredOn: blocked.previousOccurredOn,
      // Only when this entry's own date is EARLIER than the reading it
      // conflicts with. A same-day or later conflict cannot be "an older
      // entry I'm adding now".
      offersOlderEntry: occurredOn.compareTo(blocked.previousOccurredOn) < 0,
    );
  }

  return OdometerFieldOk(
    warnings: verdict.warnings,
    // Measured against the reading BEFORE it on the timeline, which for a
    // backdated entry is not the newest one on the vehicle.
    sinceLast: before == null ? null : entered - before.odometer,
    isNewEarliest: before == null && existing.isNotEmpty,
  );
}
