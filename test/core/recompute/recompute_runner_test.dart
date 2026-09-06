// The order a recompute happens in, and what it invalidates.
//
// SPEC.md §11 numbers the steps and the ORDER is the specification:
//
//     1. write, bump updated_at            (single transaction)
//     2. drop the entire derived cache for record.vehicle_id
//     3. recompute, in dependency order
//     4. diff the due states against the pre-write snapshot
//     5. dismiss the modal … show the snackbar
//
// Step 2 is the blunt instrument §11 argues for: "the fine-grained 'which
// segments does this touch' graph is forty lines of subtle code guarding a
// recompute that costs single-digit milliseconds, and a cache that is wrong is
// worse than one that is cold."
@TestOn('vm')
library;

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:odova/core/recompute/recompute_runner.dart';
import 'package:odova/core/recompute/vehicle_recompute.dart';
import 'package:odova/core/result.dart';
import 'package:test/test.dart';

/// A failure that is not a `PersistFailure`, to prove the runner is generic.
class _Boom extends Failure {
  @override
  String get code => 'boom';
}

void main() {
  test('the snapshot is taken BEFORE the write, and again after', () async {
    // Taking it after would diff a state against itself and report that
    // nothing changed, on every edit.
    final order = <String>[];

    await runRecompute(
      snapshot: () async {
        order.add('snapshot');
        return const RecomputeSnapshot();
      },
      write: () async {
        order.add('write');
        return const Ok<void, _Boom>(null);
      },
      invalidate: () async => order.add('invalidate'),
    );

    expect(order, ['snapshot', 'write', 'invalidate', 'snapshot']);
  });

  test(
    'the cache is dropped BETWEEN the write and the second snapshot',
    () async {
      // §11's step 2 sits between them for a reason: a snapshot taken before
      // the invalidation reads the memoised values the write just made stale,
      // and the diff then says nothing changed.
      final order = <String>[];

      await runRecompute(
        snapshot: () async {
          order.add('snapshot');
          return const RecomputeSnapshot();
        },
        write: () async => const Ok<void, _Boom>(null),
        invalidate: () async => order.add('invalidate'),
      );

      expect(
        order.indexOf('invalidate'),
        lessThan(order.lastIndexOf('snapshot')),
      );
    },
  );

  test('a failed write neither invalidates nor diffs', () async {
    // Nothing changed, so nothing derived can have changed — and dropping a
    // vehicle's cache for a write that did not happen is work with no cause.
    var invalidated = false;
    var snapshots = 0;

    final outcome = await runRecompute(
      snapshot: () async {
        snapshots++;
        return const RecomputeSnapshot();
      },
      write: () async => Err<void, _Boom>(_Boom()),
      invalidate: () async => invalidated = true,
    );

    expect(outcome, isA<RecomputeFailed<_Boom>>());
    expect(invalidated, isFalse);
    expect(snapshots, 1, reason: 'the before-snapshot only');
  });

  test('a successful write returns the diff of the two snapshots', () async {
    var taken = 0;

    final outcome = await runRecompute(
      snapshot: () async {
        taken++;
        return RecomputeSnapshot(
          consumptionByFillUp: taken == 1
              ? const {'a': 6.1, 'b': 6.4}
              : const {'a': 6.1, 'b': 5.9},
        );
      },
      write: () async => const Ok<void, _Boom>(null),
      invalidate: () async {},
    );

    expect(outcome, isA<RecomputeDone<_Boom>>());
    expect(
      (outcome as RecomputeDone<_Boom>).diff.changedConsumptionCount,
      1,
    );
  });

  test('an unchanged vehicle diffs to nothing', () async {
    final outcome = await runRecompute(
      snapshot: () async =>
          const RecomputeSnapshot(consumptionByFillUp: {'a': 6.1}),
      write: () async => const Ok<void, _Boom>(null),
      invalidate: () async {},
    );

    expect(
      (outcome as RecomputeDone<_Boom>).diff.changedNothing,
      isTrue,
    );
  });

  test('Undo is a write, so it earns its own recompute and its own diff', () {
    // §11: "Undo re-applies the pre-write snapshot and re-runs the same
    // pipeline." The word that matters is SAME. A revert that skips the
    // recompute leaves the fourteen figures the original write moved sitting
    // on screen at their post-write values, describing a record that no longer
    // says that — and the user's only evidence that Undo worked is a row that
    // went back, beside figures that did not.
    return fakeAsync((async) {
      final runs = <String>[];
      var odometerKm = 98204;

      Future<RecomputeOutcome<_Boom>> writeOdometer(int km, String label) =>
          runRecompute(
            snapshot: () async => RecomputeSnapshot(
              consumptionByFillUp: {'f2': odometerKm / 40},
            ),
            write: () async {
              runs.add(label);
              odometerKm = km;
              return const Ok<void, _Boom>(null);
            },
            invalidate: () async {},
          );

      late RecomputeOutcome<_Boom> undone;
      unawaited(
        writeOdometer(98204, 'edit').then((_) async {
          // The Undo re-applies the PRE-WRITE value, through the same call.
          undone = await writeOdometer(89204, 'undo');
        }),
      );
      async.elapse(const Duration(seconds: 1));

      expect(runs, ['edit', 'undo']);
      expect(
        (undone as RecomputeDone<_Boom>).diff.changedNothing,
        isFalse,
        reason: 'the revert moved a figure back, which is a change',
      );
    });
  });
}
