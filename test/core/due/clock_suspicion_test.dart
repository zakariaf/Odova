// A phone whose date is wrong stops answering rather than answering wrongly.
//
// SPEC.md §3 *Invariants and validation* — "the device clock is not trusted" —
// and §14 *Device clock wrong*.
//
// §3's window is `[build_date, build_date + 10 years]` and its consequence is
// that every due state renders `unknown`. §14 gave a DIFFERENT trigger and a
// different consequence, and its trigger — "more than 24 hours ahead of the
// newest created_at" — fires for anyone who opens the app on a Wednesday
// having last opened it on a Monday. That is most users most weeks, and the
// clause is corrected in this PR.
import 'package:odova/core/due/clock_suspicion.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate day(String text) => CivilDate.tryParse(text)!;

/// The date this build was cut.
final CivilDate _build = day('2026-09-01');

void main() {
  group('the window is [build_date, build_date + 10 years]', () {
    test('a phone that reset to 1970 is clock-suspect', () {
      // The failure §3 names: "a phone that reset to 1970 writes records whose
      // dates are indistinguishable from real ones afterwards".
      expect(
        assessClock(today: day('1970-01-01'), buildDate: _build).isSuspect,
        isTrue,
      );
    });

    test('one day before the build date is clock-suspect', () {
      expect(
        assessClock(today: _build.addDays(-1), buildDate: _build).isSuspect,
        isTrue,
      );
    });

    test('the build date itself is trusted', () {
      // Somebody installs it the day it ships.
      expect(assessClock(today: _build, buildDate: _build).isSuspect, isFalse);
    });

    test('exactly ten years after the build date is trusted', () {
      final tenYears = _build.addMonths(120);
      expect(
        assessClock(today: tenYears, buildDate: _build).isSuspect,
        isFalse,
      );
    });

    test('ten years and one day after is clock-suspect', () {
      final past = _build.addMonths(120).addDays(1);
      expect(assessClock(today: past, buildDate: _build).isSuspect, isTrue);
    });
  });

  test('a today two days after the newest record is NOT clock-suspect', () {
    // Refutes §14's clause directly. Anyone who opens the app on Wednesday
    // having last logged something on Monday is two days ahead of their newest
    // `created_at`, and under §14 as written the app would refuse to tell them
    // anything. The trigger is the BUILD window and nothing else.
    expect(
      assessClock(today: day('2026-09-03'), buildDate: _build).isSuspect,
      isFalse,
    );
    expect(
      assessClock(today: day('2027-06-01'), buildDate: _build).isSuspect,
      isFalse,
    );
  });

  group('what clock-suspect mode means', () {
    test('the reason names the date, so a banner can quote it', () {
      // §3's banner: "Your phone's date looks wrong — {date}."
      final suspicion = assessClock(
        today: day('1970-01-01'),
        buildDate: _build,
      );
      expect(suspicion.observedToday, day('1970-01-01'));
    });

    test('a trusted clock carries the same date and no suspicion', () {
      final suspicion = assessClock(
        today: day('2026-09-03'),
        buildDate: _build,
      );
      expect(suspicion.isSuspect, isFalse);
      expect(suspicion.observedToday, day('2026-09-03'));
    });
  });
}
