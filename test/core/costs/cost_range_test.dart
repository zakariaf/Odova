// SPEC.md §12's ranges, and the sentence that decides all four of them:
//
//   "A range ends on the last day of the previous calendar month… The current
//    month is out of numerator and denominator alike, reported separately as
//    `This month so far: 64 €`. An average including a two-day-old month
//    halves itself on the 2nd of every month."
//
// That last clause is the whole reason completed months exist. A user who opens
// Costs on the 2nd of the month and sees their monthly average collapse does
// not conclude the range is inclusive; they conclude the app is wrong.
@TestOn('vm')
library;

import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:test/test.dart';

CivilDate day(String t) => CivilDate.tryParse(t)!;

void main() {
  group('twelve months', () {
    test('on 2 September 2026 it is 1 Sep 2025 to 31 Aug 2026', () {
      // §12's own worked example, verbatim.
      final range = CostRange.months(12, today: day('2026-09-02'));

      expect(range.from, day('2025-09-01'));
      expect(range.to, day('2026-08-31'));
    });

    test('the current month is excluded on the LAST day of it too', () {
      // The 30th is still the current month. A range that included it because
      // "the month is nearly over" would move its own denominator daily.
      final range = CostRange.months(12, today: day('2026-09-30'));

      expect(range.to, day('2026-08-31'));
    });

    test('it spans exactly twelve completed months', () {
      expect(
        CostRange.months(12, today: day('2026-09-02')).completedMonths,
        12,
      );
    });
  });

  group('three months', () {
    test('is the last three completed calendar months', () {
      final range = CostRange.months(3, today: day('2026-09-02'));

      expect(range.from, day('2026-06-01'));
      expect(range.to, day('2026-08-31'));
    });

    test('crossing a year boundary keeps three months', () {
      final range = CostRange.months(3, today: day('2026-01-15'));

      expect(range.from, day('2025-10-01'));
      expect(range.to, day('2025-12-31'));
      expect(range.completedMonths, 3);
    });
  });

  group('this year', () {
    test('runs 1 Jan to the end of the last completed month', () {
      final range = CostRange.thisYear(today: day('2026-09-02'))!;

      expect(range.from, day('2026-01-01'));
      expect(range.to, day('2026-08-31'));
    });

    test('is HIDDEN during January', () {
      // §12 hides the chip rather than showing an empty range: there is no
      // completed month of this year yet, and a chip that yields "—" is a
      // control that punishes the tap.
      expect(CostRange.thisYear(today: day('2026-01-01')), isNull);
      expect(CostRange.thisYear(today: day('2026-01-31')), isNull);
      expect(CostRange.thisYear(today: day('2026-02-01')), isNotNull);
    });
  });

  group('all', () {
    test('starts at the month of the vehicle first record', () {
      final range = CostRange.all(
        firstRecordOn: day('2018-03-04'),
        today: day('2026-09-02'),
      )!;

      expect(range.from, day('2018-03-01'), reason: 'the MONTH, not the day');
      expect(range.to, day('2026-08-31'));
    });

    test(
      'a vehicle whose only record is this month has no completed range',
      () {
        expect(
          CostRange.all(
            firstRecordOn: day('2026-09-01'),
            today: day('2026-09-02'),
          ),
          isNull,
        );
      },
    );
  });

  group('completedMonths', () {
    test('is clipped by purchase_date', () {
      // §12 counts "only whole months during which the vehicle was owned". A
      // car bought in June has no April, and dividing by twelve would report
      // a third of its real monthly cost.
      final range = CostRange.months(
        12,
        today: day('2026-09-02'),
        purchasedOn: day('2026-06-15'),
      );

      expect(
        range.completedMonths,
        2,
        reason: 'July and August; June was partial',
      );
    });

    test('and by sold_on', () {
      final range = CostRange.months(
        12,
        today: day('2026-09-02'),
        soldOn: day('2026-03-20'),
      );

      expect(
        range.completedMonths,
        6,
        reason: 'Sep 2025 through Feb 2026; March was partial',
      );
    });

    test('a vehicle owned for none of the range has zero, not one', () {
      // Zero months is a range with no denominator — the caller must show a
      // dash rather than divide. Returning 1 to be "safe" invents a monthly
      // cost for a car that was not owned.
      final range = CostRange.months(
        3,
        today: day('2026-09-02'),
        purchasedOn: day('2026-09-01'),
      );

      expect(range.completedMonths, 0);
    });
  });

  group('thisMonthSoFar', () {
    test('is the current month, and is not part of the range', () {
      final range = CostRange.months(12, today: day('2026-09-02'));

      expect(range.thisMonthSoFar.from, day('2026-09-01'));
      expect(range.thisMonthSoFar.to, day('2026-09-02'));
      expect(range.to < range.thisMonthSoFar.from, isTrue);
    });

    test('it ends TODAY, not at the end of the month', () {
      // "So far" is the word. Running to the 30th would count days that have
      // not happened.
      expect(
        CostRange.months(12, today: day('2026-09-02')).thisMonthSoFar.to,
        day('2026-09-02'),
      );
    });
  });

  test('no range is built from a clock this file owns', () {
    // §3: `today` is injected everywhere. `core_is_pure_test.dart` already
    // refuses `dart:io`, but `DateTime.now()` is pure Dart and would pass it —
    // so the absence is asserted here, where the ranges are.
    expect(
      CostRange.months(12, today: day('2026-09-02')),
      CostRange.months(12, today: day('2026-09-02')),
      reason: 'the same today gives the same range, twice',
    );
  });
}
