// A date with no time and no zone.
//
// The type exists because `DateTime` is an INSTANT and `occurred_on` is a
// calendar date. Mixing the two produces a bug that is invisible for most of
// the year and wrong twice a year, in whichever direction the user's country
// moves its clocks — and EPIC-06 shipped exactly that bug in
// `monotonicity.dart` before routing around it with `wholeDaysBetween`.
//
// `package:test`, not `flutter_test`: `dart test test/core` runs this directory
// on the plain VM to prove the domain needs no Flutter.
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

void main() {
  group('parsing', () {
    test('round-trips YYYY-MM-DD exactly, including a leap day', () {
      for (final text in [
        '2026-09-03',
        '2028-02-29', // 2028 is a leap year
        '2026-01-01',
        '2026-12-31',
        '1970-01-01',
      ]) {
        expect(CivilDate.tryParse(text).toString(), text, reason: text);
      }
    });

    test('refuses anything that is not a calendar date', () {
      // Null, never a guess. SPEC.md §2: the app does not invent a fact that
      // looks like one, and a date silently rolled forward from 2026-02-30 to
      // 2026-03-02 is a service that never happened.
      for (final bad in [
        '2026-13-01', // month 13
        '2026-00-05', // month 0
        '2026-02-30', // February has no 30th
        '2026-04-31', // April has no 31st
        '2027-02-29', // 2027 is not a leap year
        '2026-2-3', // not zero-padded
        '26-02-03', // two-digit year
        '2026-02-03T00:00:00Z', // an instant, not a date
        '2026/02/03',
        '',
        'today',
        // `int.tryParse` accepts a leading sign and leading whitespace, so
        // each of these parsed as a DIFFERENT valid date until the digit
        // check below existed: '+026-01-03' and ' 026-01-03' became year 26,
        // and '2026-+1-03' became January. A corrupted `baseline_date` was
        // then silently adopted as an anchor, and `toString()` round-tripped
        // it to a date the database never held.
        '+026-01-03',
        ' 026-01-03',
        '2026-+1-03',
        '2026- 1-03',
        '2026-01-+3',
        '2026-01- 3',
      ]) {
        expect(CivilDate.tryParse(bad), isNull, reason: bad);
      }
    });

    test('accepts the leap day only in a leap year', () {
      // The Gregorian rule in full, not "divisible by four".
      expect(CivilDate.tryParse('2000-02-29'), isNotNull, reason: '400-year');
      expect(CivilDate.tryParse('1900-02-29'), isNull, reason: '100-year');
      expect(CivilDate.tryParse('2024-02-29'), isNotNull);
    });
  });

  group('it has no time and no zone', () {
    test('two dates from different sources are equal by value', () {
      expect(
        CivilDate.tryParse('2026-09-03'),
        CivilDate.tryParse('2026-09-03'),
      );
      expect(
        CivilDate.tryParse('2026-09-03').hashCode,
        CivilDate.tryParse('2026-09-03').hashCode,
      );
    });

    test('it carries three ints and nothing else', () {
      final date = CivilDate.tryParse('2026-09-03')!;
      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 3);
    });
  });

  group('daysUntil counts CIVIL days', () {
    test('across a European spring-forward, where DateTime disagrees', () {
      // THE reason this type exists. Europe/Berlin moves its clocks on
      // 2026-03-29. Two dates two calendar days apart span 47 hours there, and
      // `DateTime.parse` returns a LOCAL time, so `.difference().inDays`
      // truncates to 1.
      //
      // In `monotonicity.dart` that halved the divisor of an implied daily
      // rate and told a driver who did 1,100 km/day they had done 2,200.
      final before = CivilDate.tryParse('2026-03-28')!;
      final after = CivilDate.tryParse('2026-03-30')!;

      expect(before.daysUntil(after), 2);
      expect(after.daysUntil(before), -2);
    });

    test('and across a southern-hemisphere autumn-back', () {
      // The other direction: a 25-hour day. Both are one civil day.
      final saturday = CivilDate.tryParse('2026-04-04')!;
      final sunday = CivilDate.tryParse('2026-04-05')!;
      expect(saturday.daysUntil(sunday), 1);
    });

    test('matches an independent day count over 12 years, every day', () {
      // The named DST cases above are correct in every timezone, which is what
      // makes them safe to assert — and also means they do not FAIL in a
      // zone without a transition. CI runs in UTC, so they would pass there
      // against a local-time implementation too.
      //
      // This is the load-bearing one, and the oracle is deliberately a
      // DIFFERENT MECHANISM: `DateTime.utc`, whose day arithmetic has nothing
      // to do with the integer `days_from_civil` the implementation uses. Two
      // implementations of the same algorithm would share a typo; these cannot.
      //
      // `DateTime.utc` is safe as an oracle precisely because it is pinned to
      // UTC — the thing the implementation refuses to rely on is the LOCAL
      // zone, and the test names its zone explicitly.
      //
      // Every day from 2020 to 2032: 4,383 dates, three leap years, every
      // month length, and both February boundaries.
      final epoch = CivilDate.tryParse('2020-01-01')!;
      final epochUtc = DateTime.utc(2020);
      var date = epoch;
      var checked = 0;

      while (date < CivilDate.tryParse('2032-01-01')!) {
        final asUtc = DateTime.utc(date.year, date.month, date.day);
        expect(
          epoch.daysUntil(date),
          asUtc.difference(epochUtc).inDays,
          reason: '$date',
        );
        date = date.addDays(1);
        checked++;
      }

      expect(checked, greaterThan(4000), reason: 'the sweep ran');
    });

    test('is right across a century boundary, in both directions', () {
      // The sweep above runs 2020-2032 and contains no century boundary, so
      // the `~/ 100` term in the epoch-day arithmetic is zero throughout it —
      // deleting that term passed the entire sweep. A mutation found that.
      //
      // These cross all three arms of the Gregorian rule: 2000 was a leap year
      // (divisible by 400), 1900 and 2100 were not (divisible by 100 and not
      // 400). The oracle is again `DateTime.utc`, a different mechanism.
      for (final pair in [
        ('1900-02-28', '1900-03-01'), // not a leap year: 1 day
        ('2000-02-28', '2000-03-01'), // leap year: 2 days
        ('2100-02-28', '2100-03-01'), // not a leap year: 1 day
        ('1899-12-31', '1900-01-01'),
        ('2099-12-31', '2100-01-01'),
        ('1970-01-01', '2100-01-01'), // 47,482 days, straddling two centuries
        ('1900-01-01', '2000-01-01'),
      ]) {
        final from = CivilDate.tryParse(pair.$1)!;
        final to = CivilDate.tryParse(pair.$2)!;
        expect(
          from.daysUntil(to),
          DateTime.utc(
            to.year,
            to.month,
            to.day,
          ).difference(DateTime.utc(from.year, from.month, from.day)).inDays,
          reason: '${pair.$1} -> ${pair.$2}',
        );
      }

      // And the round trip, which exercises `_civilFromEpochDay`'s matching
      // century arm.
      for (final text in [
        '1900-03-01',
        '2000-02-29',
        '2100-03-01',
        '1899-12-31',
      ]) {
        final date = CivilDate.tryParse(text)!;
        expect(date.addDays(0).toString(), text);
        expect(date.addDays(1).addDays(-1).toString(), text);
        expect(date.addDays(36525).addDays(-36525).toString(), text);
      }
    });

    test('the same date is zero days, not one', () {
      final date = CivilDate.tryParse('2026-09-03')!;
      expect(date.daysUntil(date), 0);
    });

    test('counts across a leap day and a year boundary', () {
      expect(
        CivilDate.tryParse(
          '2028-02-28',
        )!.daysUntil(CivilDate.tryParse('2028-03-01')!),
        2,
        reason: '2028 is a leap year, so the 29th is in between',
      );
      expect(
        CivilDate.tryParse(
          '2027-02-28',
        )!.daysUntil(CivilDate.tryParse('2027-03-01')!),
        1,
        reason: '2027 is not',
      );
      expect(
        CivilDate.tryParse(
          '2026-12-31',
        )!.daysUntil(CivilDate.tryParse('2027-01-01')!),
        1,
      );
    });
  });

  group('addDays', () {
    test('crosses a month, a year and a leap day', () {
      expect(
        CivilDate.tryParse('2026-01-31')!.addDays(1).toString(),
        '2026-02-01',
      );
      expect(
        CivilDate.tryParse('2026-12-31')!.addDays(1).toString(),
        '2027-01-01',
      );
      expect(
        CivilDate.tryParse('2028-02-28')!.addDays(1).toString(),
        '2028-02-29',
      );
      expect(
        CivilDate.tryParse('2027-02-28')!.addDays(1).toString(),
        '2027-03-01',
      );
    });

    test('goes backwards too', () {
      expect(
        CivilDate.tryParse('2026-01-01')!.addDays(-1).toString(),
        '2025-12-31',
      );
    });

    test('round-trips with daysUntil', () {
      final start = CivilDate.tryParse('2026-09-03')!;
      for (final n in [0, 1, 7, 31, 365, 1000, -1, -400]) {
        expect(start.daysUntil(start.addDays(n)), n, reason: '$n');
      }
    });
  });

  group('addMonths clamps to the last day of the target month', () {
    test('31 January plus one month is 28 February, never 3 March', () {
      // SPEC.md §3's `interval_months`. "Add 30.44 days" drifts a service date
      // by three days a year and lands mid-month after four; the calendar
      // month is what the user meant when they typed "every 12 months".
      expect(
        CivilDate.tryParse('2026-01-31')!.addMonths(1).toString(),
        '2026-02-28',
      );
      expect(
        CivilDate.tryParse('2028-01-31')!.addMonths(1).toString(),
        '2028-02-29',
        reason: '2028 is a leap year',
      );
      expect(
        CivilDate.tryParse('2026-03-31')!.addMonths(1).toString(),
        '2026-04-30',
        reason: 'April has 30 days',
      );
    });

    test('a day that exists in the target month is untouched', () {
      expect(
        CivilDate.tryParse('2026-01-15')!.addMonths(1).toString(),
        '2026-02-15',
      );
      expect(
        CivilDate.tryParse('2026-01-15')!.addMonths(12).toString(),
        '2027-01-15',
      );
    });

    test('crosses years in both directions', () {
      expect(
        CivilDate.tryParse('2026-11-30')!.addMonths(3).toString(),
        '2027-02-28',
      );
      expect(
        CivilDate.tryParse('2026-01-31')!.addMonths(-1).toString(),
        '2025-12-31',
      );
      expect(
        CivilDate.tryParse('2026-03-31')!.addMonths(-1).toString(),
        '2026-02-28',
      );
    });

    test('is NOT reversible, and a caller must not assume it is', () {
      // 31 Jan + 1 month - 1 month is 28 Feb, not 31 Jan. Pinned because a
      // caller who round-trips through addMonths to "undo" a projection walks
      // a service date backwards a few days every time.
      final endOfJanuary = CivilDate.tryParse('2026-01-31')!;
      expect(endOfJanuary.addMonths(1).addMonths(-1).toString(), '2026-01-28');
      expect(endOfJanuary.addMonths(1).addMonths(-1), isNot(endOfJanuary));
    });

    test('twelve months from a leap day is the 28th', () {
      expect(
        CivilDate.tryParse('2028-02-29')!.addMonths(12).toString(),
        '2029-02-28',
      );
    });
  });

  group('ordering', () {
    test('sorts by calendar order, not by string luck', () {
      final dates = [
        CivilDate.tryParse('2026-10-01')!,
        CivilDate.tryParse('2026-02-09')!,
        CivilDate.tryParse('2025-12-31')!,
        CivilDate.tryParse('2026-02-10')!,
      ]..sort();

      expect(dates.map((d) => d.toString()), [
        '2025-12-31',
        '2026-02-09',
        '2026-02-10',
        '2026-10-01',
      ]);
    });

    test('comparison operators agree with compareTo', () {
      final early = CivilDate.tryParse('2026-02-09')!;
      final late = CivilDate.tryParse('2026-02-10')!;

      expect(early < late, isTrue);
      expect(late > early, isTrue);
      expect(early <= early, isTrue);
      expect(early >= early, isTrue);
      expect(early.compareTo(late), lessThan(0));
      expect(early.compareTo(early), 0);
    });
  });
  group('addMonths below year zero', () {
    test('crossing into a negative year keeps the month', () {
      // `~/` truncates toward zero and `%` floors, so a zero-based month index
      // of -1 gave year 0 month 12 instead of year -1 month 12, and -13 gave
      // a malformed `00-1-12-15`. Reachable only with a negative `months`, and
      // `_timeAxis` is the one caller that passes `interval_months` without a
      // positivity guard.
      final start = CivilDate.tryParse('0000-01-15')!;
      expect(start.addMonths(-1).month, 12);
      expect(start.addMonths(-1).year, -1);
      expect(start.addMonths(-13).year, -2);
      expect(start.addMonths(-13).month, 12);
    });

    test('and round-trips with addMonths in the other direction', () {
      final start = CivilDate.tryParse('0000-06-15')!;
      for (final n in [1, 6, 12, 13, 25]) {
        expect(start.addMonths(-n).addMonths(n), start, reason: '$n');
      }
    });
  });

  group('fromDateTime', () {
    // The entry point the type was missing. Every caller starting from
    // `clockProvider.now()` was string-building a `YYYY-MM-DD` and handing it
    // straight back to `tryParse` — three copies in EPIC-09 alone.
    test('takes the calendar date and drops the time', () {
      expect(
        CivilDate.fromDateTime(
          DateTime.utc(2026, 9, 5, 23, 59, 59),
        )!.toString(),
        '2026-09-05',
      );
      expect(
        CivilDate.fromDateTime(DateTime(2026, 1, 2))!.toString(),
        '2026-01-02',
        reason: 'single digits are padded',
      );
    });

    test('round-trips through toString, which is the format it owns', () {
      for (final when in [
        DateTime.utc(1900),
        DateTime.utc(2026, 2, 29 - 1),
        DateTime.utc(9999, 12, 31),
      ]) {
        final date = CivilDate.fromDateTime(when)!;
        expect(CivilDate.tryParse(date.toString()), date);
      }
    });

    test('a year that has no four digits is null, not a guess', () {
      // A device clock reading year 275760 is real — SPEC.md §3's
      // clock-suspicion check exists because of clocks like it — and it has no
      // `YYYY`. Null rather than a truncation that would silently file a
      // reading under the year 7576.
      expect(CivilDate.fromDateTime(DateTime.utc(275760, 9, 13)), isNull);
      expect(CivilDate.fromDateTime(DateTime.utc(10000)), isNull);
      expect(CivilDate.fromDateTime(DateTime.utc(9999, 12, 31)), isNotNull);
    });
  });
}
