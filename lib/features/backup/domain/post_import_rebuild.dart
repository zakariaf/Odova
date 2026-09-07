// What happens after the swap, and the order it happens in — SPEC.md §6 §4.1.
//
//   1. corrections are applied
//   2. every derived value is rebuilt — consumption, cost roll-ups, next-due
//   3. all local notifications are cancelled wholesale and rescheduled
//
// The ORDER is the point, and each step depends on the one before it. A due
// date computed before a correction is applied is computed against a mileage
// history the user has already told us was wrong. A notification scheduled
// before the due dates are rebuilt is a notification for a date that no longer
// exists — and the OS is holding IDs that belong to the data this import just
// replaced, which is why step 3 cancels EVERYTHING rather than reconciling.
//
// A three-line function with an interface per step looks like ceremony until
// you notice that all three steps live in different epics: corrections are the
// odometer fan-out's, the rebuild is EPIC-12's snapshot, and the reschedule is
// EPIC-16 task 16.9's. The order is the one thing that belongs to none of them
// and to this task.
import 'package:meta/meta.dart';

/// One step of the post-import sequence.
///
/// Named so `post_import_rebuild_test` can assert the order on a recording
/// fake without knowing what any of them do.
enum RebuildStep {
  /// Odometer corrections are folded into the reading series.
  corrections,

  /// Consumption, cost roll-ups and next-due dates are recomputed.
  derived,

  /// Every pending local notification is cancelled and rescheduled.
  notifications,
}

/// The three things an import has to do after the swap.
///
/// An interface rather than three callbacks, so a caller cannot supply two of
/// them and forget the third: the compiler asks for all three.
abstract class PostImportSteps {
  /// Applies every odometer correction in the newly imported store.
  Future<void> applyCorrections();

  /// Rebuilds every derived value.
  Future<void> rebuildDerived();

  /// Cancels every pending notification and schedules the new ones.
  Future<void> rescheduleNotifications();
}

/// Runs the three steps in §4.1's order.
///
/// Returns the order it ran them in, which is what the test asserts and what a
/// diagnostics log records. Awaiting each before starting the next is the whole
/// contract — running them concurrently would be faster and wrong.
Future<List<RebuildStep>> runPostImportRebuild(PostImportSteps steps) async {
  final ran = <RebuildStep>[];

  await steps.applyCorrections();
  ran.add(RebuildStep.corrections);

  await steps.rebuildDerived();
  ran.add(RebuildStep.derived);

  // Last, and exactly once. The OS holds notification ids belonging to the old
  // data; rescheduling before the due dates are rebuilt would schedule against
  // dates the rebuild is about to change.
  await steps.rescheduleNotifications();
  ran.add(RebuildStep.notifications);

  return ran;
}

/// The steps, with nothing wired in.
///
/// Not a convenience: it is what `settings.import` runs against until EPIC-16
/// supplies the real scheduler, and having it named means the gap is visible
/// rather than a port that throws in production while every test passes against
/// a fake. EPIC-13 and EPIC-14 each shipped one of those.
@immutable
class NoPostImportSteps implements PostImportSteps {
  /// Creates the no-op steps.
  const NoPostImportSteps();

  @override
  Future<void> applyCorrections() async {}

  @override
  Future<void> rebuildDerived() async {}

  @override
  Future<void> rescheduleNotifications() async {}
}
