// Completed calendar months only.
//
// SPEC.md §12 Ground rules. Including a part-month always reads the same way:
// on the 2nd the figure looks great, and by the 28th it has "risen" — because
// two days of spending were being divided by a whole month.
import 'package:odova/core/money/completed_months.dart';
import 'package:test/test.dart';

void main() {
  test("SPEC.md §12's worked case", () {
    // On 2 September 2026, "Last 12 months" is 1 Sep 2025 to 31 Aug 2026.
    final range = completedMonthsBefore(
      DateTime.utc(2026, 9, 2),
      months: 12,
    );

    expect(range.firstDay, '2025-09-01');
    expect(range.lastDay, '2026-08-31');
    expect(range.months, 12);
  });

  test('the day of the month does not move the range', () {
    // The whole point. The 1st and the 28th give the same answer, so the
    // figure does not climb through the month.
    final first = completedMonthsBefore(DateTime.utc(2026, 9), months: 12);
    final last = completedMonthsBefore(DateTime.utc(2026, 9, 30), months: 12);

    expect(first, last);
  });

  test('the current month is excluded from both ends', () {
    final range = completedMonthsBefore(
      DateTime.utc(2026, 9, 15),
      months: 12,
    );

    expect(range.contains('2026-09-01'), isFalse);
    expect(range.contains('2026-09-15'), isFalse);
    expect(range.contains('2026-08-31'), isTrue);
  });

  test('January rolls back a year', () {
    final range = completedMonthsBefore(DateTime.utc(2026), months: 3);

    expect(range.firstDay, '2025-10-01');
    expect(range.lastDay, '2025-12-31');
  });

  test('the last day is the real last day of that month', () {
    // February, and a leap February, and a 30-day month.
    expect(
      completedMonthsBefore(DateTime.utc(2026, 3, 5), months: 1).lastDay,
      '2026-02-28',
    );
    expect(
      completedMonthsBefore(DateTime.utc(2028, 3, 5), months: 1).lastDay,
      '2028-02-29',
    );
    expect(
      completedMonthsBefore(DateTime.utc(2026, 5, 5), months: 1).lastDay,
      '2026-04-30',
    );
  });

  test('one month is exactly the previous month', () {
    final range = completedMonthsBefore(DateTime.utc(2026, 9, 2), months: 1);
    expect(range.firstDay, '2026-08-01');
    expect(range.lastDay, '2026-08-31');
    expect(range.months, 1);
  });

  test('containment is a string comparison, not a DateTime', () {
    // Dates here are zoneless `YYYY-MM-DD` and compare lexically. Going
    // through DateTime would drag a zone into a question that has none.
    final range = completedMonthsBefore(DateTime.utc(2026, 9, 2), months: 12);
    expect(range.contains('2025-09-01'), isTrue);
    expect(range.contains('2025-08-31'), isFalse);
  });

  test('a range of zero months is a programmer error', () {
    expect(
      () => completedMonthsBefore(DateTime.utc(2026, 9), months: 0),
      throwsArgumentError,
    );
  });
}
