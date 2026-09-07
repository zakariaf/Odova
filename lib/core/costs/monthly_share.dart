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

/// What every month is charged for one expense.
///
/// Everything is in MINOR UNITS. No step of this touches a `double`: §3 makes
/// storage canonical integers, and a float anywhere in this path is exactly
/// where the missing cent comes from.
///
/// **Buckets days by the KEY's own calendar.** The first version built its
/// months as `MonthKey(calendar: gregorian, …)` and compared a Gregorian
/// `year`/`month` pair against the key it was asked about — and `MonthKey.==`
/// includes the calendar, so for a Persian user NO month ever matched: every
/// line returned zero, the stacked chart and "this month so far" were empty,
/// and the headline total (computed down a different path) showed real money
/// beside them. A Jalali month also starts around the 21st of a Gregorian one,
/// so even ignoring the equality the buckets were the wrong days.
///
/// A day is a day in every calendar, so the walk is over DAYS and only the
/// bucketing is calendar-aware.
Map<MonthKey, Money> monthlyShares({
  required Money amount,
  required CivilDate occurredOn,
  required CalmCalendar calendar,
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
    return {monthKeyOf(occurredOn.toString(), calendar): amount};
  }

  // One pass over the window's days. Only a covered expense — insurance and
  // road tax, per §10's two period categories — reaches this at all, so the
  // day walk runs over a handful of rows rather than the whole history.
  final weights = <MonthKey, int>{};
  var cursor = from;
  while (cursor <= to) {
    weights.update(
      monthKeyOf(cursor.toString(), calendar),
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    cursor = cursor.addDays(1);
  }

  final keys = weights.keys.toList();
  final shares = allocateByWeight(amount, [
    for (final key in keys) weights[key]!,
  ]);
  return {
    for (final (i, key) in keys.indexed) key: shares[i],
  };
}

/// What one month is charged for an expense.
///
/// [monthlyShares] for the whole window, indexed. Callers that need every
/// month should use that directly: this one recomputes the window per month
/// asked, which is `months × lines` walks instead of `lines`.
Money monthlyShare({
  required Money amount,
  required CivilDate occurredOn,
  required MonthKey month,
  CivilDate? coversFrom,
  CivilDate? coversTo,
}) =>
    monthlyShares(
      amount: amount,
      occurredOn: occurredOn,
      // The KEY's calendar, not a parameter. Asking about a Persian month in
      // Gregorian buckets is the bug this function had.
      calendar: month.calendar,
      coversFrom: coversFrom,
      coversTo: coversTo,
    )[month] ??
    Money(0, amount.currency);

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
