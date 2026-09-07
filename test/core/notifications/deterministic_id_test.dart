// The int the OS speaks, derived so that reconcile can be a plain diff.
//
// SPEC.md §4.2.2 rule 1. Android needs a 31-bit int id, and the app thinks in
// keys — `<vehicle_id>:<reminder_id>:<stage>`. This is the bridge, and it has
// one job that is easy to get subtly wrong.
//
// The id folds in the RESOLVED FIRE INSTANT and the body, not just the key.
// `getPending()` returns ids and nothing else, so if the id ignored the fire
// time then editing the delivery hour from 09:00 to 14:00 without moving the
// date would produce the same id — skipped by BOTH the cancel loop and the
// schedule loop, and the notification would fire at the old time forever. That
// is the classic bug in this design, and it is invisible on a green test suite
// that only checks the set of keys.
//
// Unchanged input must still give the same id, or reconcile is never a no-op
// and the app cancels and re-adds thirty notifications every time somebody buys
// fuel.
import 'package:odova/core/notifications/deterministic_id.dart';
import 'package:test/test.dart';

void main() {
  group('deterministicId', () {
    test('is stable for the same key, instant and body', () {
      expect(
        deterministicId(
          key: 'v1:r1:due',
          fireAtLocal: '2026-10-12T09:00',
          body: 'Oil and filter is due now.',
        ),
        deterministicId(
          key: 'v1:r1:due',
          fireAtLocal: '2026-10-12T09:00',
          body: 'Oil and filter is due now.',
        ),
      );
    });

    test('changes when the fire TIME moves but the date does not', () {
      // The bug this whole function exists to prevent.
      expect(
        deterministicId(
          key: 'v1:r1:due',
          fireAtLocal: '2026-10-12T09:00',
          body: 'x',
        ),
        isNot(
          deterministicId(
            key: 'v1:r1:due',
            fireAtLocal: '2026-10-12T14:00',
            body: 'x',
          ),
        ),
      );
    });

    test('changes when the body is re-baked', () {
      // §4.2.2 rule 6: a reschedule regenerates the body from current numbers,
      // and a changed body has to become a changed id or the OS keeps the old
      // sentence.
      expect(
        deterministicId(
          key: 'v1:r1:due',
          fireAtLocal: '2026-10-12T09:00',
          body: 'due around 12 October',
        ),
        isNot(
          deterministicId(
            key: 'v1:r1:due',
            fireAtLocal: '2026-10-12T09:00',
            body: 'due around 19 October',
          ),
        ),
      );
    });

    test('changes when the key changes', () {
      expect(
        deterministicId(key: 'v1:r1:due', fireAtLocal: 'T', body: 'x'),
        isNot(deterministicId(key: 'v1:r2:due', fireAtLocal: 'T', body: 'x')),
      );
    });

    test('always fits in a positive 31-bit int', () {
      // Android's requirement. A negative id or one past 2^31-1 throws on the
      // platform and nowhere else, so it is asserted over a wide spread rather
      // than on one example.
      for (var i = 0; i < 2000; i++) {
        final id = deterministicId(
          key: 'veh_$i:rem_$i:overdue2',
          fireAtLocal: '2026-10-${(i % 28) + 1}T09:00',
          body: 'body $i',
        );
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(1 << 31));
      }
    });

    test('linear-probes past an id already taken', () {
      final first = deterministicId(key: 'k', fireAtLocal: 'T', body: 'b');

      expect(
        deterministicId(key: 'k', fireAtLocal: 'T', body: 'b', taken: {first}),
        first + 1,
      );
      expect(
        deterministicId(
          key: 'k',
          fireAtLocal: 'T',
          body: 'b',
          taken: {first, first + 1},
        ),
        first + 2,
      );
    });

    test('a probe that runs off the top wraps rather than going negative', () {
      // The probe has to stay inside 31 bits, and the top of the range is where
      // an off-by-one becomes a platform exception on one user's phone.
      const top = (1 << 31) - 1;
      expect(
        deterministicId(
          key: 'k',
          fireAtLocal: 'T',
          body: 'b',
          taken: {top},
          seed: top,
        ),
        0,
      );
    });
  });

  group('the 7-day hysteresis', () {
    // §4.2.2 rule 2. A projection wandering by a day or two must not cancel and
    // re-add every notification the user has — that is thirty OS calls every
    // time somebody buys fuel.
    test('leaves a pending notification alone when it moves 6 days', () {
      expect(
        shouldReschedule(from: '2026-10-12T09:00', to: '2026-10-18T09:00'),
        isFalse,
      );
    });

    test('reschedules when it moves 8 days', () {
      expect(
        shouldReschedule(from: '2026-10-12T09:00', to: '2026-10-20T09:00'),
        isTrue,
      );
    });

    test('exactly 7 days moves it', () {
      // "less than 7 days: do not touch it" — so 7 is a move.
      expect(
        shouldReschedule(from: '2026-10-12T09:00', to: '2026-10-19T09:00'),
        isTrue,
      );
    });

    test('is symmetric: 8 days EARLIER also reschedules', () {
      // The obvious implementation subtracts one from the other and compares,
      // which silently never reschedules anything that moved earlier — and a
      // due date moving earlier is the direction that matters.
      expect(
        shouldReschedule(from: '2026-10-20T09:00', to: '2026-10-12T09:00'),
        isTrue,
      );
    });

    test('an unparseable time reschedules rather than being ignored', () {
      // Fail toward doing the work. A row whose stored time cannot be read is
      // a row we know nothing about, and leaving it pending forever is how a
      // notification fires with a body from four months ago.
      expect(shouldReschedule(from: 'rubbish', to: '2026-10-12T09:00'), isTrue);
    });
  });
}
