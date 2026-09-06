// The order a write and its recompute happen in.
//
// SPEC.md §11 numbers the steps, and the numbering is the specification rather
// than a description of it:
//
//     1. write the record and bump `updated_at`, in a single transaction
//     2. drop the entire derived cache for `record.vehicle_id`
//     3. recompute, in dependency order
//     4. diff the resulting due states against the pre-write snapshot
//     5. dismiss the modal and show the snackbar the diff earned
//
// Two of those orderings are easy to get wrong and silent when you do. The
// snapshot must be taken BEFORE the write, or step 4 diffs a state against
// itself and reports that nothing changed on every single edit. And the cache
// must be dropped BETWEEN the write and the after-snapshot, or the after-side
// reads memoised values the write has already invalidated — same silent
// nothing-changed, arrived at from the other direction.
//
// Dropping the whole vehicle's cache is the blunt instrument §11 argues for on
// purpose: "the fine-grained 'which segments does this touch' graph is forty
// lines of subtle code guarding a recompute that costs single-digit
// milliseconds, and a cache that is wrong is worse than one that is cold."
import 'package:meta/meta.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:odova/core/result.dart';

/// What a write and its recompute produced.
///
/// Sealed so the caller's `switch` is exhaustive: there is no third answer, and
/// a snackbar that runs off the end of an `if` chain shows nothing at all.
@immutable
sealed class RecomputeOutcome<F extends Failure> {
  /// Creates an outcome.
  const RecomputeOutcome();
}

/// The write landed, and [diff] says what it changed downstream.
@immutable
final class RecomputeDone<F extends Failure> extends RecomputeOutcome<F> {
  /// Creates a completed outcome.
  const RecomputeDone(this.diff);

  /// What changed between the before- and after-snapshots.
  final RecomputeDiff diff;
}

/// The write failed, so nothing downstream can have changed.
@immutable
final class RecomputeFailed<F extends Failure> extends RecomputeOutcome<F> {
  /// Creates a failed outcome.
  const RecomputeFailed(this.failure);

  /// Why the write did not land.
  final F failure;
}

/// Runs [write] between two snapshots and reports what it changed.
///
/// This is the seam `onWrite`, `onDelete` and `onRestore` all share — the three
/// verbs differ only in what [write] does, and all three have exactly the same
/// obligation afterwards. Undo is a restore, which is why it earns the same
/// recompute and the same snackbar as the write it reverses; a revert that
/// leaves a stale consumption figure on screen is the bug this shape prevents.
///
/// [invalidate] runs only on success. Nothing changed on a failed write, so
/// dropping the vehicle's derived cache would be work with no cause — and the
/// user would pay for it with a cold recompute on the next screen they open.
Future<RecomputeOutcome<F>> runRecompute<F extends Failure>({
  required Future<RecomputeSnapshot> Function() snapshot,
  required Future<Result<void, F>> Function() write,
  required Future<void> Function() invalidate,
}) async {
  final before = await snapshot();

  final written = await write();
  if (written case Err(:final failure)) return RecomputeFailed<F>(failure);

  await invalidate();

  final after = await snapshot();
  return RecomputeDone<F>(diffRecompute(before: before, after: after));
}
