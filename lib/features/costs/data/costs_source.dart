// The real `CostsRepository`.
//
// The interface was declared with its notifier in EPIC-13's first task and the
// provider threw `UnimplementedError` — so `costs` was a route that crashed
// the moment a real user opened it, while every test passed against a fake.
// That is the exact shape of gap a fake-only test leaves, and it is worth
// naming here rather than quietly filling.
//
// Everything here is a READ. SPEC.md §12: nothing on these screens is
// persisted, and every figure recomputes from the record tables on the next
// frame after an edit.
//
// It lives in the FEATURE and not in `lib/data/repositories/`, because it is
// not a repository: it composes four of them and then applies §12's accrual
// allocator, which is domain arithmetic. Two directory gates say the same
// thing from their own angle — `no_conversion_on_write_test` reserves an
// unwrap in `lib/data` for the mapper, and `no_drift_in_signatures_test`
// reads every public signature under `lib/data/repositories` — and both are
// right that this is not that layer.

import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/costs/monthly_share.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/due/reading_series.dart';
import 'package:odova/core/history/month_index.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/log_repositories.dart';
import 'package:odova/data/repositories/odometer_repository.dart';
import 'package:odova/data/repositories/service_repository.dart';
import 'package:odova/features/costs/application/costs_notifier.dart';

/// Everything `costs` is computed from.
///
/// TWO classes and not one, because both interfaces name their method `read`
/// with different signatures — a single class cannot implement both, and
/// renaming one of them to make it possible would rename a method to suit an
/// implementation detail of its only implementer.
class CostsSource implements CostsRepository {
  /// Creates a source over the four log repositories.
  ///
  /// Positional, like every other repository in this directory: a named
  /// parameter cannot be an initializing formal for a private field, and the
  /// `field: param` form the analyzer rejects is what that constraint
  /// produces.
  const CostsSource(
    this._fillUps,
    this._expenses,
    this._services,
    this._odometer,
    this._calendar,
  );

  final FillUpRepository _fillUps;
  final ExpenseRepository _expenses;
  final ServiceRepository _services;
  final OdometerRepository _odometer;

  /// The calendar the month buckets are counted in.
  ///
  /// Carried, not looked up: `MonthKey` makes the calendar part of the key
  /// precisely so Mehr 1405 and month 7 of a Gregorian year cannot merge, and
  /// a source that read the setting itself would answer differently between
  /// two callers on the same frame.
  final CalmCalendar _calendar;

  @override
  Future<CostsInputs> read(
    String vehicleId, {
    required CostRange? range,
  }) async {
    final id = VehicleId.tryParse(vehicleId);
    if (id == null) {
      return const CostsInputs(
        amountsByRow: {},
        readings: [],
        corrections: [],
      );
    }

    final fills = await _fillUps.watchForVehicle(id).first;
    final expenses = await _expenses.watchForVehicle(id).first;
    final records = await _services.watchRecords(id).first;
    final readings = await _odometer.watchReadings(id).first;
    final corrections = await _odometer.watchCorrections(id).first;

    final lines = <_CostLine>[
      for (final fill in fills)
        (
          row: CostCategoryRow.fuel,
          amount: fill.totalCost,
          occurredOn: fill.occurredOn,
          coversFrom: null,
          coversTo: null,
        ),
      // Line by line, and NOT for a record whose cost was never recorded:
      // §12 says such a record contributes 0 and prints an em dash, and
      // folding it in as zero would be indistinguishable from a free job.
      for (final record in records)
        if (!record.costEstimated)
          for (final line in record.lines)
            (
              row: CostCategoryRow.service,
              amount: line.amount,
              occurredOn: record.occurredOn,
              coversFrom: null,
              coversTo: null,
            ),
      for (final expense in expenses)
        (
          row: rowForCategory(expense.category),
          amount: expense.amount,
          occurredOn: expense.occurredOn,
          coversFrom: expense.coversFrom,
          coversTo: expense.coversTo,
        ),
    ];

    final first = _earliest(lines);

    // ONE assembly, and a closure that narrows it. The notifier needs
    // `firstRecordOn` before it can build the `All` range, and needed a second
    // whole-history read to get it; `narrowTo` closes over the lines this read
    // produced, so the narrowing cannot see different data from the load.
    CostsInputs forRange(CostRange? forRange) => CostsInputs(
      amountsByRow: _byRow(lines, forRange),
      readings: readings.map(asReadingPoint).toList(),
      corrections: corrections.map(asCorrectionPoint).toList(),
      firstRecordOn: first,
      thisMonthAmounts: _thisMonth(lines, forRange),
      monthlyPoints: [
        for (final month
            in forRange == null ? const <MonthKey>[] : _monthsIn(forRange))
          MonthlyCostPoint(
            month: month,
            // Through `monthlyShare`, which is the ONE allocator: an insurance
            // premium is spread across the months its window covers, and
            // re-deriving that split from a flat list would be a second one.
            amounts: _amountsFor(lines, month),
          ),
      ],
      narrowTo: (next) => _narrow(lines, readings, corrections, first, next),
    );

    return forRange(range);
  }

  @override
  Future<List<HouseholdVehicle>> readHousehold(
    List<HouseholdVehicleFacts> vehicles, {
    required CivilDate today,
    required CostsRangeChoice choice,
  }) async {
    final rows = <HouseholdVehicle>[];
    for (final vehicle in vehicles) {
      final inputs = await read(vehicle.id, range: null);
      final range = costsRangeFor(choice, inputs, today);
      if (range == null) continue;

      final narrowed = inputs.narrow(range);
      final total = MoneyTotal([
        for (final list in narrowed.amountsByRow.values) ...list,
      ]);
      final dominant = total.dominantCurrency;
      if (dominant == null) continue;

      // Per COMPLETED month, like the headline: §12 is emphatic that a range
      // including a two-day-old month halves its own average on the 2nd, and
      // a household list that used a different divisor from the figure above
      // it would be two answers to one question on one screen.
      final perMonth = costPerMonth(
        total: Money(total.byCurrency[dominant] ?? 0, dominant),
        range: range,
      );
      // Only an EXACT figure joins the household list. §12's list is sorted by
      // cost per month, and a vehicle whose figure is estimated or absent has
      // no place in that ordering — it would sort against a number the app has
      // said it cannot support.
      if (perMonth is! CostExact || perMonth.minorPerMonth == null) continue;

      rows.add(
        HouseholdVehicle(
          vehicleId: vehicle.id,
          name: vehicle.name,
          perMonth: Money(perMonth.minorPerMonth!, dominant),
          isArchived: vehicle.isArchived,
          isSold: vehicle.isSold,
        ),
      );
    }
    return rows;
  }

  CostsInputs _narrow(
    List<_CostLine> lines,
    List<OdometerReading> readings,
    List<OdometerCorrection> corrections,
    CivilDate? first,
    CostRange? range,
  ) => CostsInputs(
    amountsByRow: _byRow(lines, range),
    readings: readings.map(asReadingPoint).toList(),
    corrections: corrections.map(asCorrectionPoint).toList(),
    firstRecordOn: first,
    thisMonthAmounts: _thisMonth(lines, range),
    monthlyPoints: [
      for (final month in range == null ? const <MonthKey>[] : _monthsIn(range))
        MonthlyCostPoint(month: month, amounts: _amountsFor(lines, month)),
    ],
    narrowTo: (next) => _narrow(lines, readings, corrections, first, next),
  );

  Map<CostCategoryRow, List<Money>> _byRow(
    List<_CostLine> lines,
    CostRange? range,
  ) {
    final byRow = <CostCategoryRow, List<Money>>{};
    for (final line in lines) {
      if (!_inRange(line, range)) continue;
      byRow.putIfAbsent(line.row, () => []).add(line.amount);
    }
    return byRow;
  }

  /// §12's separately-reported current month.
  ///
  /// Through `_amountsFor`, which is `monthlyShare` — the SAME allocator the
  /// chart column for this month uses. The first version filtered by month and
  /// took each amount whole, so an annual insurance premium paid this month
  /// landed in "this month so far" at full value while the chart column
  /// directly above it showed one twelfth of the same premium. Two numbers on
  /// one screen disagreeing, under a caption promising the opposite.
  ///
  /// It also compared `MonthKey`s built from the calendar alone, so a row from
  /// the same month of ANY year counted. `monthlyShare` takes the month as a
  /// key with its year in it, so that cannot happen here.
  List<Money> _thisMonth(List<_CostLine> lines, CostRange? range) {
    final today = range?.today;
    if (today == null) return const [];
    return _amountsFor(
      lines,
      monthKeyOf(today.toString(), _calendar),
    ).values.toList();
  }

  Map<CostCategoryRow, Money> _amountsFor(
    List<_CostLine> lines,
    MonthKey month,
  ) {
    final byRow = <CostCategoryRow, Money>{};
    for (final line in lines) {
      final on = CivilDate.tryParse(line.occurredOn);
      if (on == null) continue;
      final share = monthlyShare(
        amount: line.amount,
        occurredOn: on,
        month: month,
        coversFrom: CivilDate.tryParse(line.coversFrom ?? ''),
        coversTo: CivilDate.tryParse(line.coversTo ?? ''),
      );
      if (share.isZero) continue;
      byRow.update(
        line.row,
        (sum) => sum + share,
        ifAbsent: () => share,
      );
    }
    return byRow;
  }

  List<MonthKey> _monthsIn(CostRange range) {
    final months = <MonthKey>[];
    var cursor = CivilDate.tryParse(
      '${range.from.toString().substring(0, 8)}01',
    );
    while (cursor != null && cursor <= range.to) {
      months.add(monthKeyOf(cursor.toString(), _calendar));
      cursor = cursor.addMonths(1);
    }
    return months;
  }

  bool _inRange(_CostLine line, CostRange? range) {
    if (range == null) return true;
    final on = CivilDate.tryParse(line.occurredOn);
    if (on == null) return false;
    return on >= range.from && on <= range.to;
  }

  CivilDate? _earliest(List<_CostLine> lines) {
    CivilDate? first;
    for (final line in lines) {
      final on = CivilDate.tryParse(line.occurredOn);
      if (on == null) continue;
      if (first == null || on < first) first = on;
    }
    return first;
  }
}

typedef _CostLine = ({
  CostCategoryRow row,
  Money amount,
  String occurredOn,
  String? coversFrom,
  String? coversTo,
});
