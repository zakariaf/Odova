// The pinned Jalali arithmetic.
//
// SPEC.md §5 testing item 10: Gregorian → Jalali → Gregorian identity for every
// day 1300–1500 AP, plus the four anchors and a Nowruz table.
//
// The anchors are in the suite rather than in a comment because "never swap the
// implementation" is only enforceable if swapping it fails something. Two
// implementations that disagree by one day disagree about which MONTH a service
// happened in, and a history is not re-derivable.
import 'package:odova/core/l10n/jalali.dart';
import 'package:test/test.dart';

void main() {
  group("SPEC.md §5's four ICU anchors convert exactly", () {
    test('1 Farvardin 1403 is 2024-03-20', () {
      expect(jalaliToGregorian(1403, 1, 1), (year: 2024, month: 3, day: 20));
      expect(gregorianToJalali(2024, 3, 20), (year: 1403, month: 1, day: 1));
    });

    test('1 Farvardin 1404 is 2025-03-21', () {
      expect(jalaliToGregorian(1404, 1, 1), (year: 2025, month: 3, day: 21));
      expect(gregorianToJalali(2025, 3, 21), (year: 1404, month: 1, day: 1));
    });

    test('1 Farvardin 1405 is 2026-03-21', () {
      expect(jalaliToGregorian(1405, 1, 1), (year: 2026, month: 3, day: 21));
      expect(gregorianToJalali(2026, 3, 21), (year: 1405, month: 1, day: 1));
    });

    test('30 Esfand 1403 is 2025-03-20, and 1403 is a leap year', () {
      // The leap day itself. An implementation that is right about Nowruz and
      // wrong about the leap rule passes the first three anchors and fails
      // this one.
      expect(isJalaliLeapYear(1403), isTrue);
      expect(jalaliToGregorian(1403, 12, 30), (year: 2025, month: 3, day: 20));
      expect(gregorianToJalali(2025, 3, 20), (year: 1403, month: 12, day: 30));
    });
  });

  test('Gregorian to Jalali and back is the identity for 1300-1500 AP', () {
    // Around 73,000 days. Fails if the leap rule drifted by one day anywhere
    // in two centuries.
    final first = jalaliToJdn(1300, 1, 1);
    final last = jalaliToJdn(1500, 12, 29);
    var mismatches = 0;
    String? firstMismatch;

    for (var jdn = first; jdn <= last; jdn++) {
      final jalali = jdnToJalali(jdn);
      final back = jalaliToJdn(jalali.year, jalali.month, jalali.day);
      if (back != jdn) {
        mismatches++;
        firstMismatch ??= 'jdn $jdn -> $jalali -> $back';
      }
    }

    expect(mismatches, 0, reason: firstMismatch ?? '');
    expect(last - first, greaterThan(70000), reason: 'the range collapsed');
  });

  test('every Jalali month has the length the calendar says it does', () {
    // Months 1-6 are 31 days, 7-11 are 30, and Esfand is 29 or 30 by the leap
    // rule. A conversion that is self-consistent but wrong about month lengths
    // still round-trips, so the round-trip alone cannot catch this.
    for (var jy = 1300; jy <= 1500; jy++) {
      for (var jm = 1; jm <= 12; jm++) {
        final expected = switch (jm) {
          <= 6 => 31,
          <= 11 => 30,
          _ => isJalaliLeapYear(jy) ? 30 : 29,
        };
        final start = jalaliToJdn(jy, jm, 1);
        final next = jm == 12
            ? jalaliToJdn(jy + 1, 1, 1)
            : jalaliToJdn(jy, jm + 1, 1);
        expect(next - start, expected, reason: '$jy-$jm');
      }
    }
  });

  test('Nowruz lands on 20, 21 or 22 March in every year of the range', () {
    // Three days, not two, and the third is not a bug. The equinox drifts
    // against the Gregorian calendar across two centuries: Nowruz 1301 AP fell
    // on 22 March 1922, because the equinox was 21 March 20:49 UTC and Tehran
    // is +3:26. Asserting {20, 21} — which is what today looks like — fails on
    // the 1920s, and "fixing" it would have meant breaking the arithmetic.
    final marchDays = <int>{};
    for (var jy = 1300; jy <= 1500; jy++) {
      final nowruz = jalaliToGregorian(jy, 1, 1);
      expect(nowruz.month, 3, reason: 'Nowruz $jy left March');
      marchDays.add(nowruz.day);
    }
    expect(marchDays, {20, 21, 22});
  });

  test('leap years follow the 33-year cycle, not a naive every-fourth', () {
    // The naive rule gives 1403, 1407, 1411... The real cycle skips one every
    // 33 years, and the skip is what a hand-rolled implementation gets wrong.
    final leaps = [
      for (var jy = 1390; jy <= 1440; jy++)
        if (isJalaliLeapYear(jy)) jy,
    ];
    expect(leaps, contains(1403));
    expect(leaps, isNot(contains(1404)));
    // Consecutive leap years are 4 or 5 apart; a naive rule never gives 5.
    final gaps = [
      for (var i = 1; i < leaps.length; i++) leaps[i] - leaps[i - 1],
    ];
    expect(gaps.toSet(), containsAll([4, 5]));
  });

  test('the range guard is a real guard', () {
    expect(() => jdnToJalali(gregorianToJdn(-2000, 1, 1)), throwsArgumentError);
  });
}
