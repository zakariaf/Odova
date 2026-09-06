// SPEC.md §12's four ranges, and the one sentence that decides all of them:
//
//   "A range ends on the last day of the previous calendar month… The current
//    month is out of numerator and denominator alike, reported separately as
//    `This month so far: 64 €`. An average including a two-day-old month
//    halves itself on the 2nd of every month."
//
// That last clause is the entire argument for completed months. A user who
// opens Costs on the 2nd and watches their monthly average collapse does not
// think "ah, the current month is partial" — they think the app is wrong, and
// they are not being unreasonable.
//
// `today` is INJECTED, everywhere. `core_is_pure_test.dart` refuses `dart:io`,
// but `DateTime.now()` is pure Dart and would sail through it — so the rule
// that matters here is enforced by the signatures rather than by the gate.
import 'package:meta/meta.dart';
import 'package:odova/core/time/civil_date.dart';

/// A half-open-free window over completed calendar months.
///
/// Both ends INCLUSIVE, and both on month boundaries: `from` is the first day
/// of a month and `to` is the last day of one. Callers compare `occurred_on`
/// with `>=` and `<=` and never have to think about a partial month, which is
/// the whole point of computing the window once.
@immutable
class CostRange {
  const CostRange._({
    required this.from,
    required this.to,
    required this.today,
    this.purchasedOn,
    this.soldOn,
  });

  /// The last [count] COMPLETED calendar months.
  ///
  /// Never includes the month [today] falls in, whatever day of it that is —
  /// the 1st and the 30th are equally "current".
  factory CostRange.months(
    int count, {
    required CivilDate today,
    CivilDate? purchasedOn,
    CivilDate? soldOn,
  }) {
    final end = _lastCompletedMonthEnd(today);
    final start = _firstOf(end).addMonths(-(count - 1));
    return CostRange._(
      from: start,
      to: end,
      today: today,
      purchasedOn: purchasedOn,
      soldOn: soldOn,
    );
  }

  /// 1 January to the end of the last completed month.
  ///
  /// NULL during January: there is no completed month of this year yet, and
  /// §12 hides the chip rather than showing one that yields a dash. A control
  /// that punishes the tap is worse than a control that is not there.
  static CostRange? thisYear({
    required CivilDate today,
    CivilDate? purchasedOn,
    CivilDate? soldOn,
  }) {
    if (today.month == 1) return null;
    final end = _lastCompletedMonthEnd(today);
    return CostRange._(
      from: CivilDate.tryParse('${_pad4(today.year)}-01-01')!,
      to: end,
      today: today,
      purchasedOn: purchasedOn,
      soldOn: soldOn,
    );
  }

  /// The month of the vehicle's first record, to the last completed month.
  ///
  /// NULL when the first record is in the current month: there is no completed
  /// month to average over, and a range of zero months is not a range.
  static CostRange? all({
    required CivilDate firstRecordOn,
    required CivilDate today,
    CivilDate? purchasedOn,
    CivilDate? soldOn,
  }) {
    final end = _lastCompletedMonthEnd(today);
    final start = _firstOf(firstRecordOn);
    if (start > end) return null;
    return CostRange._(
      from: start,
      to: end,
      today: today,
      purchasedOn: purchasedOn,
      soldOn: soldOn,
    );
  }

  /// The first day of the range's first month.
  final CivilDate from;

  /// The last day of the range's last month.
  final CivilDate to;

  /// The injected clock's today, kept so [thisMonthSoFar] needs no second one.
  final CivilDate today;

  /// When this owner bought the vehicle, if known.
  final CivilDate? purchasedOn;

  /// When they sold it, if they have.
  final CivilDate? soldOn;

  /// How many whole months of this range the vehicle was OWNED for.
  ///
  /// The denominator of every per-month figure, and clipping it is what stops
  /// a car bought in June reporting a third of its real monthly cost because
  /// the range still says twelve.
  ///
  /// A partial month at either end does not count. A car bought on 15 June was
  /// not owned for June, so June is neither in the numerator (its costs before
  /// the 15th are not this owner's) nor the denominator.
  ///
  /// ZERO is a real answer, and the caller must render a dash rather than
  /// divide. Returning 1 "to be safe" invents a monthly cost for a car that
  /// was not owned in the range at all.
  int get completedMonths {
    var start = from;
    var end = to;

    final bought = purchasedOn;
    if (bought != null) {
      // The first WHOLE month of ownership: the month of purchase itself is
      // partial unless the purchase was on its first day.
      final firstWhole = bought.day == 1
          ? _firstOf(bought)
          : _firstOf(bought).addMonths(1);
      if (firstWhole > start) start = firstWhole;
    }

    final sold = soldOn;
    if (sold != null) {
      final lastMonthStart = _firstOf(sold);
      final lastDayOfSaleMonth = lastMonthStart.addMonths(1).addDays(-1);
      // Symmetrically: the month of sale counts only if it was owned to its
      // last day.
      final lastWholeEnd = sold == lastDayOfSaleMonth
          ? lastDayOfSaleMonth
          : lastMonthStart.addDays(-1);
      if (lastWholeEnd < end) end = lastWholeEnd;
    }

    if (start > end) return 0;
    return _firstOf(start).monthsUntil(_firstOf(end)) + 1;
  }

  /// §12's separately-reported current month: its 1st to TODAY.
  ///
  /// "So far" is the operative word — running to the end of the month would
  /// count days that have not happened.
  ({CivilDate from, CivilDate to}) get thisMonthSoFar =>
      (from: _firstOf(today), to: today);

  @override
  bool operator ==(Object other) =>
      other is CostRange &&
      other.from == from &&
      other.to == to &&
      other.today == today &&
      other.purchasedOn == purchasedOn &&
      other.soldOn == soldOn;

  @override
  int get hashCode => Object.hash(from, to, today, purchasedOn, soldOn);

  @override
  String toString() => 'CostRange($from..$to)';

  static CivilDate _lastCompletedMonthEnd(CivilDate today) =>
      _firstOf(today).addDays(-1);

  static CivilDate _firstOf(CivilDate d) =>
      CivilDate.tryParse('${_pad4(d.year)}-${_pad2(d.month)}-01')!;

  static String _pad4(int v) => v.toString().padLeft(4, '0');

  static String _pad2(int v) => v.toString().padLeft(2, '0');
}
