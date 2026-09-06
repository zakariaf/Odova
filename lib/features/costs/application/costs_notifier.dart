// SPEC.md §12's tab-3 state: which range, and whether all vehicles are shown.
//
// Both are per-TAB-STACK and neither is persisted. §12 opens with "Three of
// these screens are read-only. They write nothing but per-stack UI state —
// range, fuel kind — which dies with the tab-stack reset." A remembered range
// would mean the figure a user last looked at greets them months later with
// no indication of which window it covers.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/costs/cost_aggregates.dart';
import 'package:odova/core/costs/cost_by_category.dart';
import 'package:odova/core/costs/cost_range.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';

/// Which of §12's four ranges is selected.
enum CostsRangeChoice {
  /// The last three completed calendar months.
  threeMonths,

  /// The last twelve — §12's default.
  twelveMonths,

  /// 1 January to the end of the last completed month.
  thisYear,

  /// The vehicle's first record onwards.
  all,
}

/// Everything tab 3 reads for one vehicle.
@immutable
class CostsInputs {
  /// Creates the inputs.
  const CostsInputs({
    required this.amountsByRow,
    required this.readings,
    required this.corrections,
    this.firstRecordOn,
    this.purchasedOn,
    this.soldOn,
    this.thisMonthAmounts = const [],
    this.monthlyPoints = const [],
  });

  /// Every amount in range, already grouped into §12's six rows.
  final Map<CostCategoryRow, List<Money>> amountsByRow;

  /// The vehicle's entered readings, for the per-distance figure.
  final List<ReadingPoint> readings;

  /// And its corrections.
  final List<CorrectionPoint> corrections;

  /// The month of this is where `All` starts.
  final CivilDate? firstRecordOn;

  /// Clips `completedMonths` at the start.
  final CivilDate? purchasedOn;

  /// And at the end.
  final CivilDate? soldOn;

  /// §12's separately-reported current month.
  final List<Money> thisMonthAmounts;

  /// One entry per month in range, for §12's stacked chart.
  ///
  /// Supplied by the repository rather than derived here, because the split
  /// by month is a query — the accrual allocator has already spread every
  /// covered expense across the months it touches, and re-deriving that from
  /// a flat list would be a second allocator.
  final List<MonthlyCostPoint> monthlyPoints;
}

/// What tab 3 renders.
@immutable
class CostsState {
  /// Creates the state.
  const CostsState({
    this.choice = CostsRangeChoice.twelveMonths,
    this.range,
    this.total,
    this.categories = const [],
    this.perMonth,
    this.perDistance,
    this.thisMonthSoFar,
    this.chart,
    this.includeInactive = false,
    this.isLoaded = false,
  });

  /// The selected chip. §12 makes twelve months the default.
  final CostsRangeChoice choice;

  /// The window it resolves to, or null when the choice has none — `This year`
  /// in January, `All` for a vehicle whose only record is this month.
  final CostRange? range;

  /// Per-currency totals for the range.
  final MoneyTotal? total;

  /// §12's category rows, largest first, zero rows already dropped.
  final List<CostCategoryLine> categories;

  /// Cost per completed month, or its refusal.
  final CostFigure? perMonth;

  /// Cost per distance, or its refusal.
  final CostFigure? perDistance;

  /// The current month, reported separately and never averaged in.
  final MoneyTotal? thisMonthSoFar;

  /// §12's stacked chart, already bucketed and thinned.
  final MonthlyChart? chart;

  /// Whether §12's household list includes sold and archived vehicles.
  ///
  /// OFF by default. A sold car's costs are real history, but a household
  /// average that silently included a car nobody drives any more would be
  /// wrong in the direction of looking cheap.
  final bool includeInactive;

  /// Whether the first read has landed.
  final bool isLoaded;

  /// Whether §12's first-run state applies.
  ///
  /// Loaded AND empty — before the read lands, an empty screen would flash
  /// "No costs yet" at a user who has eight years of them.
  bool get isEmpty => isLoaded && (total?.byCurrency.isEmpty ?? true);
}

/// Reads one vehicle's costs.
///
/// An interface rather than a function type, for the reason
/// is: it is a PORT, its fake carries its own fixture, and a typedef makes
/// every override an inline closure with no name in a stack trace.
// ignore: one_member_abstracts
abstract interface class CostsRepository {
  /// Everything §12's tab 3 is computed from, for [range].
  Future<CostsInputs> read(String vehicleId, {required CostRange? range});
}

/// Tab 3's state.
class CostsNotifier extends Notifier<CostsState> {
  CostsInputs? _inputs;
  var _loading = false;

  @override
  CostsState build() => const CostsState();

  /// Loads once, and recomputes when the chip changes.
  void ensureLoaded(String vehicleId, {required CivilDate today}) {
    if (_loading || state.isLoaded) return;
    _loading = true;
    unawaited(_reload(vehicleId, today: today));
  }

  /// Selects a range chip and recomputes.
  Future<void> choose(
    CostsRangeChoice choice,
    String vehicleId, {
    required CivilDate today,
  }) async {
    state = CostsState(
      choice: choice,
      range: state.range,
      total: state.total,
      categories: state.categories,
      perMonth: state.perMonth,
      perDistance: state.perDistance,
      thisMonthSoFar: state.thisMonthSoFar,
      chart: state.chart,
      includeInactive: state.includeInactive,
      isLoaded: state.isLoaded,
    );
    await _reload(vehicleId, today: today);
  }

  Future<void> _reload(String vehicleId, {required CivilDate today}) async {
    final inputs = _inputs ??= await ref
        .read(costsRepositoryProvider)
        .read(vehicleId, range: null);

    final range = _rangeFor(state.choice, inputs, today);
    final loaded = range == null
        ? null
        : await ref.read(costsRepositoryProvider).read(vehicleId, range: range);
    final data = loaded ?? inputs;

    final amounts = [
      for (final list in data.amountsByRow.values) ...list,
    ];
    final total = totalCost(amounts: amounts);
    final dominant = total.dominantCurrency;

    state = CostsState(
      choice: state.choice,
      range: range,
      total: total,
      categories: dominant == null || range == null
          ? const []
          : costByCategory(
              totals: {
                for (final entry in data.amountsByRow.entries)
                  entry.key: Money(
                    entry.value
                        .where((m) => m.currency == dominant)
                        .fold<int>(0, (s, m) => s + m.amountMinor),
                    dominant,
                  ),
              },
              currency: dominant,
            ),
      perMonth: range == null || dominant == null
          ? null
          : costPerMonth(
              total: Money(total.byCurrency[dominant] ?? 0, dominant),
              range: range,
            ),
      perDistance: range == null || dominant == null
          ? null
          : costPerDistance(
              total: Money(total.byCurrency[dominant] ?? 0, dominant),
              readings: data.readings,
              corrections: data.corrections,
              range: range,
            ),
      thisMonthSoFar: MoneyTotal(data.thisMonthAmounts),
      chart: dominant == null
          ? null
          : buildMonthlyChart(
              points: data.monthlyPoints,
              currency: dominant,
            ),
      includeInactive: state.includeInactive,
      isLoaded: true,
    );
  }

  /// Toggles §12's sold-and-archived inclusion.
  ///
  /// Writes ONLY to this notifier's own state. §7's `activeVehicleId` is not
  /// read here and not written — this is the one screen-scoped exception to
  /// the app-wide vehicle scope, and it stays scoped by not having the
  /// provider in reach.
  ///
  /// The RANGE is carried through unchanged: §12 preserves it across the
  /// toggle, because a household comparison that silently answered a different
  /// question from the one on screen a moment ago is a comparison nobody can
  /// trust.
  void toggleAllVehicles({required bool includeInactive}) {
    state = CostsState(
      choice: state.choice,
      range: state.range,
      total: state.total,
      categories: state.categories,
      perMonth: state.perMonth,
      perDistance: state.perDistance,
      thisMonthSoFar: state.thisMonthSoFar,
      chart: state.chart,
      includeInactive: includeInactive,
      isLoaded: state.isLoaded,
    );
  }

  static CostRange? _rangeFor(
    CostsRangeChoice choice,
    CostsInputs inputs,
    CivilDate today,
  ) => switch (choice) {
    CostsRangeChoice.threeMonths => CostRange.months(
      3,
      today: today,
      purchasedOn: inputs.purchasedOn,
      soldOn: inputs.soldOn,
    ),
    CostsRangeChoice.twelveMonths => CostRange.months(
      12,
      today: today,
      purchasedOn: inputs.purchasedOn,
      soldOn: inputs.soldOn,
    ),
    CostsRangeChoice.thisYear => CostRange.thisYear(
      today: today,
      purchasedOn: inputs.purchasedOn,
      soldOn: inputs.soldOn,
    ),
    CostsRangeChoice.all =>
      inputs.firstRecordOn == null
          ? null
          : CostRange.all(
              firstRecordOn: inputs.firstRecordOn!,
              today: today,
              purchasedOn: inputs.purchasedOn,
              soldOn: inputs.soldOn,
            ),
  };
}

/// Tab 3's provider.
final NotifierProvider<CostsNotifier, CostsState> costsProvider =
    NotifierProvider<CostsNotifier, CostsState>(CostsNotifier.new);

/// The store tab 3 reads through. Overridden in tests.
final Provider<CostsRepository> costsRepositoryProvider =
    Provider<CostsRepository>(
      (ref) => throw UnimplementedError(
        'costsRepositoryProvider must be overridden until EPIC-13 wires the '
        'per-range read.',
      ),
    );
