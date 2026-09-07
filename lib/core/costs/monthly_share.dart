// SPEC.md §12's accrual allocator.
//
// "Costs are accrual; History is cash." An expense with a coverage window is
// spread over the months it covers; everything else is charged to the month it
// was paid. The user is told so in one line under the headline, because a
// yearly premium that vanished from the month it was paid and reappeared in
// twelve slices is otherwise an app that lost their money.
//
// The line that decides the implementation:
//
//   "Allocation runs in minor units with largest-remainder distribution, so
//    1,200.00 EUR over 365 days never becomes 1,199.99."
//
// Twelve monthly shares are twelve divisions and twelve roundings, each losing
// up to half a unit in the same direction. Largest-remainder gives every month
// its floor, then hands the leftover units to the months with the largest
// fractional parts — so the parts sum to the whole by construction rather than
// by luck.
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/allocate.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/time/civil_date.dart';

/// What [month] is charged for an expense.
///
/// Everything is in MINOR UNITS. No step of this touches a `double`: §3 makes
/// storage canonical integers, and a float anywhere in this path is exactly
/// where the missing cent comes from.
Money monthlyShare({
  required Money amount,
  required CivilDate occurredOn,
  required MonthKey month,
  CivilDate? coversFrom,
  CivilDate? coversTo,
}) {
  final from = coversFrom;
  final to = coversTo;

  // §12's fallback, and it covers two cases rather than one: no window at all,
  // and a window whose end precedes its start. The second is corrupt or
  // mistyped data, and charging it as a point cost keeps the money somewhere
  // the user can find — a negative denominator would either throw or silently
  // lose the expense.
  if (from == null || to == null || to < from) {
    return _containsMonth(month, occurredOn)
        ? amount
        : Money(0, amount.currency);
  }

  final months = _monthsSpanned(from, to);
  final shares = allocateByWeight(
    amount,
    [for (final m in months) _overlapDays(m, from, to)],
  );

  for (final (i, m) in months.indexed) {
    if (m == month) return shares[i];
  }
  return Money(0, amount.currency);
}

/// Splits [amount] across [weights] so the parts sum to the whole EXACTLY.
///
/// Through [allocate], which is `lib/core/money/`'s largest-remainder split
/// and was already written, already tested and — until this call — had no
/// caller in `lib/` at all. This function had its own copy of the algorithm
/// for one day, and the copy differed in two ways that matter:
///
///   * It truncated toward zero on a NEGATIVE amount, so a refund spread over
///     a coverage window came back summing to LESS than the refund. `allocate`
///     carries the sign explicitly, and §10 makes `Expense.amount` the one
///     money field in this app allowed to be negative — so that case is
///     reachable from the form.
///   * It had no tie-break documented as load-bearing; `allocate`'s is.
///
/// What stays here is the only genuine difference: `allocate` THROWS on
/// weights that are all zero, because splitting a whole into no parts is a
/// programming error at its call sites. Here it is data — a coverage window
/// that overlaps none of the months asked about — and zero is the answer.
List<Money> allocateByWeight(Money amount, List<int> weights) {
  final total = weights.fold<int>(0, (sum, w) => sum + w);
  if (total <= 0) {
    return [for (final _ in weights) Money(0, amount.currency)];
  }
  return allocate(amount, weights);
}

/// Every month [from]..[to] touches, in order.
List<MonthKey> _monthsSpanned(CivilDate from, CivilDate to) {
  final months = <MonthKey>[];
  var cursor = _firstOf(from);
  while (cursor <= to) {
    months.add(
      MonthKey(
        calendar: CalmCalendar.gregorian,
        year: cursor.year,
        month: cursor.month,
      ),
    );
    cursor = cursor.addMonths(1);
  }
  return months;
}

/// How many days of [month] fall inside [from]..[to], both ends inclusive.
int _overlapDays(MonthKey month, CivilDate from, CivilDate to) {
  final start = _firstOf2(month.year, month.month);
  final end = start.addMonths(1).addDays(-1);

  final lower = start < from ? from : start;
  final upper = end > to ? to : end;
  final days = lower.daysUntil(upper) + 1;
  return days < 0 ? 0 : days;
}

bool _containsMonth(MonthKey month, CivilDate date) =>
    date.year == month.year && date.month == month.month;

CivilDate _firstOf(CivilDate d) => _firstOf2(d.year, d.month);

CivilDate _firstOf2(int year, int month) => CivilDate.tryParse(
  '${year.toString().padLeft(4, '0')}-'
  '${month.toString().padLeft(2, '0')}-01',
)!;
