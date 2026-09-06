// SPEC.md §11: "Monotonicity on an edit is harder than on a new entry, because
// an edited reading has neighbours on BOTH sides."
//
// The asymmetry is the whole content of this file. A new reading has one
// neighbour and one question: is it above the reading before it? An edited one
// has two, and the answers are not symmetric — breaking downwards against the
// EARLIER neighbour is the ordinary case a cluster swap produces, and §11 hands
// it the same three-way dialogue new entries get. Breaking upwards past a LATER
// neighbour is not correctable at all:
//
//   "A correction can only start at the newest reading; inserting one
//    mid-history would rewrite every cumulative value after it."
//
// So that case gets two buttons, not three, and the error names the reading it
// collided with — a refusal the user cannot see the cause of is a refusal they
// retype until it works.
@TestOn('vm')
library;

import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/odometer/edit_monotonicity.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

ReadingPoint r(String id, String on, int km, {int created = 0}) => (
  id: id,
  occurredOn: on,
  createdAtUtcMs: created,
  odometer: Distance.fromKm(km),
);

/// Three readings a year apart, the middle one being the row under edit.
final List<ReadingPoint> _history = [
  r('a', '2024-10-12', 180000),
  r('b', '2025-06-01', 186000),
  r('c', '2026-02-20', 191400),
];

EditVerdict edit(
  int km, {
  String id = 'b',
  List<CorrectionPoint> corrections = const [],
}) => checkEdit(
  edited: r(id, _history.firstWhere((p) => p.id == id).occurredOn, km),
  existing: _history,
  corrections: corrections,
  vehicleUnit: DistanceUnit.km,
);

void main() {
  test('a reading that fits between both neighbours saves silently', () {
    // 186,000 → 187,000, still above 180,000 and still below 191,400.
    expect(edit(187000), isA<EditAccepted>());
  });

  test('the boundaries are inclusive of neither neighbour', () {
    // Equal to a neighbour is not "fits": two readings at the same value
    // produce a zero-distance segment, which the fuel engine discards. §3
    // treats it as a break, and so does this.
    expect(edit(180000), isNot(isA<EditAccepted>()));
    expect(edit(191400), isNot(isA<EditAccepted>()));
  });

  group('breaking against the earlier neighbour', () {
    test('on the NEWEST reading, opens the three-way dialogue', () {
      // §11: "the new-entry three-way dialogue, unchanged." A cluster swap
      // genuinely does lower the dash number, and the newest reading is the
      // only place a correction may start.
      final verdict = checkEdit(
        edited: r('c', '2026-02-20', 40000),
        existing: _history,
        corrections: const [],
        vehicleUnit: DistanceUnit.km,
      );

      expect(verdict, isA<EditNeedsCorrection>());
      final needs = verdict as EditNeedsCorrection;
      expect(needs.previousCumulative, const Distance.fromKm(186000));
      expect(needs.previousOccurredOn, '2025-06-01');
    });

    test('MID-HISTORY, it is refused instead — two buttons, not three', () {
      // The row under edit is 'b', which has 'c' after it. Lowering it below
      // 'a' cannot open a correction, because a correction starting here would
      // rewrite 'c' as well.
      final verdict = edit(170000);

      expect(verdict, isA<EditRefused>());
      expect(verdict, isNot(isA<EditNeedsCorrection>()));
    });
  });

  group('breaking against a LATER neighbour', () {
    test('is refused, and the message names that reading and its value', () {
      // §11's exact error: "This is lower than your reading on 12 Oct 2024
      // (191,400 km). Odometers only go up." The date and the figure are the
      // two facts the user needs to fix it themselves; a bare "invalid" is a
      // refusal they retype until it works.
      final verdict = edit(195000);

      expect(verdict, isA<EditRefused>());
      final refused = verdict as EditRefused;
      expect(refused.collidedOccurredOn, '2026-02-20');
      expect(refused.collidedCumulative, const Distance.fromKm(191400));
      expect(refused.attemptedCumulative, const Distance.fromKm(195000));
    });

    test('the collision names the NEAREST later reading, not the newest', () {
      // With two readings after the edited one, the one it actually collided
      // with is the nearer. Naming the newest instead tells the user their
      // 195,000 clashes with a reading it is comfortably below.
      final verdict = checkEdit(
        edited: r('a', '2024-10-12', 300000),
        existing: _history,
        corrections: const [],
        vehicleUnit: DistanceUnit.km,
      );

      expect((verdict as EditRefused).collidedOccurredOn, '2025-06-01');
    });
  });

  test('a reading that starts a correction is locked, for edit and delete', () {
    // §11: "This reading starts an odometer correction from 12 Mar 2023.
    // Delete the correction first." Editing the number under a correction
    // would silently change what every later cumulative value was corrected
    // FROM, and nothing on screen would say so.
    final verdict = edit(
      187000,
      corrections: [
        (
          fromReadingId: 'b',
          previous: const Distance.fromKm(186000),
          replacement: const Distance.fromKm(40000),
        ),
      ],
    );

    expect(verdict, isA<EditLockedByCorrection>());
    expect((verdict as EditLockedByCorrection).readingOccurredOn, '2025-06-01');
  });

  test(
    'the oldest reading has no earlier neighbour and is not refused for it',
    () {
      expect(
        checkEdit(
          edited: r('a', '2024-10-12', 1000),
          existing: _history,
          corrections: const [],
          vehicleUnit: DistanceUnit.km,
        ),
        isA<EditAccepted>(),
        reason: 'lowering the earliest reading collides with nothing before it',
      );
    },
  );

  test('the newest reading has no later neighbour and may rise freely', () {
    expect(
      checkEdit(
        edited: r('c', '2026-02-20', 400000),
        existing: _history,
        corrections: const [],
        vehicleUnit: DistanceUnit.km,
      ),
      isA<EditAccepted>(),
    );
  });

  group('after a cluster swap', () {
    // The defect: `checkEdit` used `corrections` only for the lock test and
    // then compared RAW dash numbers, while naming its result fields
    // `previousCumulative` and `collidedCumulative`.
    //
    // A pre-swap value always exceeds the post-swap raw number, so EVERY edit
    // of EVERY pre-swap reading was refused — and the refusal named a figure
    // (1,000 km) that no screen in the app shows.

    final swapped = [
      r('a', '2026-01-01', 188000),
      r('b', '2026-02-01', 1000, created: 2),
      r('c', '2026-03-01', 3000, created: 3),
    ];

    final correction = [
      (
        fromReadingId: 'b',
        previous: const Distance.fromKm(188412),
        replacement: const Distance.fromKm(1000),
      ),
    ];

    test('a typo fix on a PRE-swap reading is accepted', () {
      // 188,000 -> 187,000 is monotonic on the cumulative scale: b folds to
      // 188,412, which is above it.
      expect(
        checkEdit(
          edited: r('a', '2026-01-01', 187000),
          existing: swapped,
          corrections: correction,
          vehicleUnit: DistanceUnit.km,
        ),
        isA<EditAccepted>(),
      );
    });

    test('and one that really does collide is still refused', () {
      // The arm that keeps this honest: accepting everything would pass the
      // test above. 189,000 is above b's folded 188,412.
      expect(
        checkEdit(
          edited: r('a', '2026-01-01', 189000),
          existing: swapped,
          corrections: correction,
          vehicleUnit: DistanceUnit.km,
        ),
        isA<EditRefused>(),
      );
    });

    test('the refusal names a CUMULATIVE figure, not a raw one', () {
      // 1,000 km is the raw dash number after the swap. It appears on no
      // screen, and a user told their edit collided with it has nothing to
      // act on.
      final verdict =
          checkEdit(
                edited: r('a', '2026-01-01', 189000),
                existing: swapped,
                corrections: correction,
                vehicleUnit: DistanceUnit.km,
              )
              as EditRefused;

      expect(verdict.collidedCumulative, const Distance.fromKm(188412));
    });
  });
}
