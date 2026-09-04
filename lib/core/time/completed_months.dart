// Calendar month boundaries.
//
// `lib/core/time/` and not `lib/core/money/`, where this started: there is no
// money type anywhere in the file. It landed under money because its first
// caller was a cost figure, and EPIC-07's due engine needs the same
// month-boundary arithmetic for `interval_months` — two implementations of
// "when does a month end" in an app with an OPEN QUESTION about the Jalali
// calendar (SPEC.md §18) is a bug waiting for a Persian user.
//
// SPEC.md §12 Ground rules: a per-month figure divides by COMPLETED months. On
// 2 September 2026, "Last 12 months" is 1 September 2025 to 31 August 2026 —
// and the current month is out of the numerator AND the denominator alike.
//
// Including a part-month is the classic error and it always reads the same way:
// on the 2nd of the month the figure looks great, and by the 28th it has
// "risen" — because two days of spending were being divided by a whole month.
// The user then believes their costs are climbing.
import 'package:meta/meta.dart';
import 'package:odova/core/value_equality.dart';

/// An inclusive range of whole calendar months.
@immutable
class MonthRange with ValueEquality {
  /// Creates a range.
  const MonthRange({
    required this.firstDay,
    required this.lastDay,
    required this.months,
  });

  /// The first day of the first completed month, `YYYY-MM-DD`.
  final String firstDay;

  /// The last day of the last completed month, `YYYY-MM-DD`.
  final String lastDay;

  /// How many whole months the range covers. The denominator.
  final int months;

  /// Whether [day] falls inside the range.
  ///
  /// Dates are zoneless `YYYY-MM-DD` and compare lexically, so this is a string
  /// comparison and not a `DateTime` — which would drag a zone into a question
  /// that has none.
  bool contains(String day) =>
      day.compareTo(firstDay) >= 0 && day.compareTo(lastDay) <= 0;

  @override
  List<Object?> get props => [firstDay, lastDay, months];

  @override
  String toString() => 'MonthRange($firstDay..$lastDay, $months months)';
}

/// The [months] completed calendar months ending before [today]'s month.
///
/// [today] is injected rather than read, so a test can fix it and the whole
/// engine stays deterministic — SPEC.md §3: derived values take no clock except
/// an injected today.
MonthRange completedMonthsBefore(DateTime today, {required int months}) {
  if (months < 1) {
    throw ArgumentError.value(months, 'months', 'must be at least one');
  }

  // The last completed month is the one before today's, whatever the date —
  // the 1st and the 28th give the same answer, which is the whole point.
  final endYear = today.month == 1 ? today.year - 1 : today.year;
  final endMonth = today.month == 1 ? 12 : today.month - 1;

  final startTotal = endYear * 12 + (endMonth - 1) - (months - 1);
  final startYear = startTotal ~/ 12;
  final startMonth = startTotal % 12 + 1;

  return MonthRange(
    firstDay: _day(startYear, startMonth, 1),
    lastDay: _day(endYear, endMonth, _daysIn(endYear, endMonth)),
    months: months,
  );
}

/// How many days [month] of [year] has.
int _daysIn(int year, int month) => DateTime.utc(
  month == 12 ? year + 1 : year,
  month == 12 ? 1 : month + 1,
).subtract(const Duration(days: 1)).day;

String _day(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';
