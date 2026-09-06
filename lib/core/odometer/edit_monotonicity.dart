// SPEC.md §11: "Monotonicity on an edit is harder than on a new entry, because
// an edited reading has neighbours on BOTH sides."
//
// The asymmetry is the whole of this file, and it is not obvious. A new reading
// has one neighbour and one question. An edited one has two, and the two
// answers are DIFFERENT:
//
//   - Breaking downwards, against the EARLIER neighbour, on the newest
//     reading: the ordinary cluster-swap case. §11 hands it the same three-way
//     dialogue a new entry gets, unchanged.
//   - Breaking downwards, mid-history: refused. "A correction can only start
//     at the newest reading; inserting one mid-history would rewrite every
//     cumulative value after it."
//   - Breaking upwards, past a LATER neighbour: refused, with §11's message
//     naming that reading's date and value.
//
// Treating the two directions alike is the bug this file exists to prevent: it
// would offer to open a correction from the middle of a vehicle's history, and
// the resulting rewrite is silent, wrong, and eight years deep.
import 'package:meta/meta.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/monotonicity.dart';
import 'package:odova/core/units/distance.dart';

/// What may happen to an edited reading.
///
/// Sealed, so the caller's `switch` is exhaustive. The three refusals are
/// different SCREENS — three buttons, two buttons, and a message with no
/// buttons at all — and an `if (blocked)` that collapses them shows the wrong
/// one.
@immutable
sealed class EditVerdict {
  /// Creates a verdict.
  const EditVerdict();
}

/// The reading fits between both neighbours and saves silently.
@immutable
final class EditAccepted extends EditVerdict {
  /// Creates an acceptance.
  const EditAccepted({this.warnings = const []});

  /// Told to the user, never blocking. §3's three soft warnings.
  final List<OdometerWarning> warnings;
}

/// It is the newest reading and it went below the one before it.
///
/// §11's "the new-entry three-way dialogue, unchanged" — the caller shows
/// EPIC-09's dialogue, offering a correction, a re-type, or a cancel.
@immutable
final class EditNeedsCorrection extends EditVerdict {
  /// Creates the correction offer.
  const EditNeedsCorrection({
    required this.previousCumulative,
    required this.previousOccurredOn,
    required this.attemptedCumulative,
  });

  /// What the reading before it reads, cumulatively.
  final Distance previousCumulative;

  /// And when.
  final String previousOccurredOn;

  /// What was typed.
  final Distance attemptedCumulative;
}

/// It collided with a neighbour and no correction can start here.
///
/// Two options only — **Fix the number** and **Cancel** — and the message
/// names [collidedOccurredOn] and [collidedCumulative], because a refusal the
/// user cannot see the cause of is one they retype until it works.
@immutable
final class EditRefused extends EditVerdict {
  /// Creates a refusal.
  const EditRefused({
    required this.collidedOccurredOn,
    required this.collidedCumulative,
    required this.attemptedCumulative,
  });

  /// The date of the reading it collided with — the NEAREST one, not the
  /// newest. Naming the newest tells the user their number clashes with a
  /// reading it is comfortably below.
  final String collidedOccurredOn;

  /// That reading's cumulative value.
  final Distance collidedCumulative;

  /// What was typed.
  final Distance attemptedCumulative;
}

/// This reading is the `from_reading_id` of a correction.
///
/// §11 blocks the odometer edit AND the delete: changing the number under a
/// correction silently changes what every later cumulative value was corrected
/// FROM, and nothing on screen would say so.
@immutable
final class EditLockedByCorrection extends EditVerdict {
  /// Creates the lock.
  const EditLockedByCorrection({required this.readingOccurredOn});

  /// The date the correction starts from, for "Delete the correction first."
  final String readingOccurredOn;
}

/// Checks [edited] against the neighbours on BOTH sides of it.
///
/// [existing] is the vehicle as it stands, INCLUDING the row being edited —
/// which is removed by id before the neighbours are found, so a reading is
/// never its own neighbour.
@useResult
EditVerdict checkEdit({
  required ReadingPoint edited,
  required List<ReadingPoint> existing,
  required List<CorrectionPoint> corrections,
  required DistanceUnit vehicleUnit,
}) {
  // The lock is evaluated FIRST, before any arithmetic. A value that happens
  // to fit between both neighbours is still locked, and checking monotonicity
  // first would let exactly those values slip past the guard — which is the
  // subset most likely to be typed, because the user is nudging a number.
  final locked = corrections.any((c) => c.fromReadingId == edited.id);
  if (locked) {
    final row = existing.where((p) => p.id == edited.id).firstOrNull;
    return EditLockedByCorrection(
      readingOccurredOn: row?.occurredOn ?? edited.occurredOn,
    );
  }

  final others = [...existing.where((p) => p.id != edited.id)]
    ..sort(compareReadings);

  // Neighbours by DATE ORDER, not by value: the list is what the user sees,
  // and "the reading before this one" means the one above it on the screen.
  ReadingPoint? earlier;
  ReadingPoint? later;
  for (final p in others) {
    if (compareReadings(p, edited) < 0) {
      earlier = p;
    } else {
      later ??= p;
    }
  }

  // Upwards first. A value can only collide with one side at a time on a
  // consistent history, and on an inconsistent one the later collision is the
  // one that cannot be resolved — so it is the one to report.
  if (later != null && edited.odometer.metres >= later.odometer.metres) {
    return EditRefused(
      collidedOccurredOn: later.occurredOn,
      collidedCumulative: later.odometer,
      attemptedCumulative: edited.odometer,
    );
  }

  if (earlier != null && edited.odometer.metres <= earlier.odometer.metres) {
    // The fork §11 draws. Only the NEWEST reading may open a correction,
    // because a correction rewrites every cumulative value after its anchor
    // and there is nothing after the newest one.
    return later == null
        ? EditNeedsCorrection(
            previousCumulative: earlier.odometer,
            previousOccurredOn: earlier.occurredOn,
            attemptedCumulative: edited.odometer,
          )
        : EditRefused(
            collidedOccurredOn: earlier.occurredOn,
            collidedCumulative: earlier.odometer,
            attemptedCumulative: edited.odometer,
          );
  }

  return EditAccepted(
    warnings: earlier == null
        ? const []
        : softOdometerWarnings(
            from: earlier.odometer,
            to: edited.odometer,
            fromDate: earlier.occurredOn,
            toDate: edited.occurredOn,
            vehicleUnit: vehicleUnit,
          ),
  );
}
