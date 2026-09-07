// What to cancel and what to add, decided before anything is called.
//
// SPEC.md §4.2.2. The whole point is rule 2's promise: buying fuel must not
// cancel and re-add thirty notifications. Undamped, every reprojection moves a
// date by a day or two and rewrites the entire queue — thirty OS calls, on the
// path where somebody is standing at a pump.
//
// Pure, and separated from the IO for the reason every rule here is a claim
// about a SET: "zero calls on unchanged input" cannot be asserted by watching
// one delivery. The gateway loop that consumes this is four lines.
import 'package:odova/core/notifications/reconcile.dart';
import 'package:test/test.dart';

DesiredNotification want(
  String key,
  int id, {
  String fireAtLocal = '2026-10-12T09:00',
  String body = 'Oil and filter is due now.',
}) => DesiredNotification(
  key: key,
  id: id,
  fireAtLocal: fireAtLocal,
  body: body,
);

// `fireAtLocal` is REQUIRED rather than defaulted. Half these tests are about
// a time moving, and a default hides the `from` of the pair on exactly the
// cases where the contrast is the assertion.
KnownNotification have(
  String key,
  int id, {
  required String fireAtLocal,
  NotificationRowState state = NotificationRowState.pending,
}) => KnownNotification(
  key: key,
  osId: id,
  fireAtLocal: fireAtLocal,
  state: state,
);

void main() {
  test('is a no-op on unchanged input', () {
    // Rule 2, stated as zero calls rather than as "the same set".
    final diff = reconcile(
      desired: [want('v1:r1:due', 100)],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toCancel, isEmpty);
    expect(diff.toSchedule, isEmpty);
  });

  test('leaves a pending notification alone when its time moves 6 days', () {
    final diff = reconcile(
      desired: [want('v1:r1:due', 100, fireAtLocal: '2026-10-18T09:00')],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toCancel, isEmpty);
    expect(diff.toSchedule, isEmpty);
  });

  test('reschedules when its time moves 8 days', () {
    final diff = reconcile(
      desired: [want('v1:r1:due', 200, fireAtLocal: '2026-10-20T09:00')],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toCancel, [100]);
    expect(diff.toSchedule.single.id, 200);
  });

  test('schedules what the OS is not holding, whatever the row claims', () {
    // The OS is the truth for "is it pending" — §6.1. A row marked pending that
    // the OS dropped for cap is exactly what this exists to repair, and it is
    // the only way the app can ever learn the drop happened.
    final diff = reconcile(
      desired: [want('v1:r1:due', 100)],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: const {},
    );

    expect(diff.toSchedule.single.id, 100);
  });

  test('cancels an id the OS holds that nothing wants', () {
    final diff = reconcile(
      desired: const [],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toCancel, [100]);
    expect(diff.toSchedule, isEmpty);
  });

  test('cancels an orphan the OS holds that the table has never heard of', () {
    // A leftover from a previous install or a schema this build no longer
    // writes. Left alone it fires with a payload nothing can route.
    final diff = reconcile(
      desired: const [],
      known: const [],
      pendingIds: {999},
    );

    expect(diff.toCancel, [999]);
  });

  test('never reschedules a stage that has already fired', () {
    // §4.2.2 rule 4: once fired, done. Rescheduling a fired stage re-delivers
    // history, which is the single most confusing thing this app could do.
    final diff = reconcile(
      desired: [want('v1:r1:due', 200, fireAtLocal: '2026-11-20T09:00')],
      known: [
        have(
          'v1:r1:due',
          100,
          fireAtLocal: '2026-10-12T09:00',
          state: NotificationRowState.fired,
        ),
      ],
      pendingIds: const {},
    );

    expect(diff.toSchedule, isEmpty);
    expect(diff.toCancel, isEmpty);
  });

  test('re-bakes the body on a reschedule', () {
    // §4.2.2 rule 6. The body is frozen into the OS at schedule time, so the
    // one that goes out is the one in `toSchedule` — not the stored one.
    final diff = reconcile(
      desired: [
        want(
          'v1:r1:due',
          200,
          fireAtLocal: '2026-10-20T09:00',
          body: 'due around 20 October',
        ),
      ],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toSchedule.single.body, 'due around 20 October');
  });

  test('a row the OS no longer holds is marked dropped, never dismissed', () {
    // §6.1: the table is the truth for WHY. Without this distinction there is
    // no telling a notification the user dismissed from one the OS discarded
    // for cap — and only the second one is a bug worth chasing.
    final diff = reconcile(
      desired: const [],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: const {},
    );

    expect(diff.toMarkDropped, ['v1:r1:due']);
  });

  test('a row still pending in the OS is not marked dropped', () {
    final diff = reconcile(
      desired: [want('v1:r1:due', 100)],
      known: [have('v1:r1:due', 100, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {100},
    );

    expect(diff.toMarkDropped, isEmpty);
  });

  test('the lists come back in a defined order, not in input order', () {
    // A mutation removing the sorts survived "deterministic", and the reason is
    // worth keeping: two runs over the same input have the same INSERTION
    // order, so a stability check cannot see an unsorted result. What it hides
    // is a diff whose call order depends on how the caller happened to build
    // its list — two devices with the same data issuing cancels in different
    // orders — exactly the reproducibility §4.2.2 needs when a reconcile
    // has to be compared against the last one.
    final diff = reconcile(
      desired: [
        want('b', 2, fireAtLocal: '2026-12-01T09:00'),
        want('a', 1, fireAtLocal: '2026-10-01T09:00'),
      ],
      known: const [],
      pendingIds: {77, 5},
    );

    expect(diff.toCancel, [5, 77], reason: 'ascending, not set order');
    expect(
      diff.toSchedule.map((n) => n.key),
      ['a', 'b'],
      reason: 'delivery order, not the order the caller listed them',
    );
  });

  test('is deterministic and total', () {
    final args = (
      desired: [want('b:2:due', 2), want('a:1:due', 1)],
      known: [have('a:1:due', 9, fireAtLocal: '2026-10-12T09:00')],
      pendingIds: {9, 77},
    );

    final first = reconcile(
      desired: args.desired,
      known: args.known,
      pendingIds: args.pendingIds,
    );
    final second = reconcile(
      desired: args.desired,
      known: args.known,
      pendingIds: args.pendingIds,
    );

    expect(first.toCancel, second.toCancel);
    expect(first.toSchedule, second.toSchedule);
    expect(
      () => reconcile(
        desired: const [],
        known: const [],
        pendingIds: const {},
      ),
      returnsNormally,
    );
  });
}
