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
import 'package:odova/core/costs/household_costs.dart';
import 'package:odova/core/costs/monthly_chart_model.dart';
import 'package:odova/core/l10n/calendar.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/money/money_total.dart';
import 'package:odova/core/odometer/cumulative.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/costs/data/costs_source.dart';
import 'package:odova/l10n/locale_controller.dart';

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

/// What the household read needs to know about one vehicle.
///
/// The costs feature cannot import the vehicles feature, and does not need to:
/// four facts is the whole of what a household line is made of.
typedef HouseholdVehicleFacts = ({
  String id,
  String name,
  bool isArchived,
  bool isSold,
});

/// Everything tab 3 reads for one vehicle.
///
/// Read ONCE per load, for the whole history, and narrowed to a range in
/// memory by [narrow]. The first version took the range as a query parameter,
/// which meant the notifier read twice — once with a null range to learn
/// `firstRecordOn`, which is the only thing the `All` chip's range can be
/// derived from, and again with the range that came out of it. Both reads
/// fetched byte-identical rows, because the source never filtered at the query
/// level, and a write landing between them would have been counted by one and
/// not the other.
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
    this.businessPercent,
    this.narrowTo,
  });

  /// §12's business share, or null when no logged trip has a distance.
  final int? businessPercent;

  /// Narrows every figure to the range this is called with.
  ///
  /// Supplied by the source, which is the only thing that knows the lines
  /// behind the figures and the calendar the months are counted in. A closure
  /// rather than a second read, so the narrowing cannot see different data
  /// from the load it narrows.
  final CostsInputs Function(CostRange? range)? narrowTo;

  /// This, narrowed to [range]. Identity when the source supplied no narrower.
  CostsInputs narrow(CostRange? range) =>
      narrowTo == null ? this : narrowTo!(range);

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
    this.showsHousehold = false,
    this.businessPercent,
    this.household,
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

  /// §12's business share, or null when it is unknowable.
  final int? businessPercent;

  /// Whether §12's All-vehicles panel is showing.
  ///
  /// Separate from [includeInactive], which is the switch INSIDE the panel.
  /// One flag for both would make "show the household" and "count the sold
  /// ones in it" the same decision, and §12 makes them two.
  final bool showsHousehold;

  /// §12's household list, once the toggle has been turned on.
  ///
  /// Null until then. Loading it eagerly would read every vehicle's whole
  /// history on a screen most users open for one car.
  final HouseholdCosts? household;

  /// Whether the first read has landed.
  final bool isLoaded;

  /// Whether §12's first-run state applies.
  ///
  /// Loaded AND empty — before the read lands, an empty screen would flash
  /// "No costs yet" at a user who has eight years of them.
  bool get isEmpty => isLoaded && (total?.byCurrency.isEmpty ?? true);

  /// A copy with the named fields replaced.
  ///
  /// `choose` and `toggleAllVehicles` each hand-listed all ten fields to
  /// change one. An eleventh field then means editing three constructor calls,
  /// and omitting it from one silently resets that field on the next chip
  /// tap — a defect nothing in this file would catch.
  CostsState copyWith({
    CostsRangeChoice? choice,
    bool? includeInactive,
    bool? showsHousehold,
    HouseholdCosts? household,
  }) => CostsState(
    choice: choice ?? this.choice,
    range: range,
    total: total,
    categories: categories,
    perMonth: perMonth,
    perDistance: perDistance,
    thisMonthSoFar: thisMonthSoFar,
    chart: chart,
    includeInactive: includeInactive ?? this.includeInactive,
    showsHousehold: showsHousehold ?? this.showsHousehold,
    businessPercent: businessPercent,
    household: household ?? this.household,
    isLoaded: isLoaded,
  );
}

/// Reads one vehicle's costs.
///
/// An interface rather than a function type, for the reason
/// is: it is a PORT, its fake carries its own fixture, and a typedef makes
/// every override an inline closure with no name in a stack trace.
abstract interface class CostsRepository {
  /// Everything §12's tab 3 is computed from, for [range].
  Future<CostsInputs> read(String vehicleId, {required CostRange? range});

  /// One line per vehicle for §12's All-vehicles panel.
  ///
  /// A different QUESTION from [read] — "what does the household cost per
  /// month" rather than "where does this car's money go" — and the only read
  /// in tab 3 that touches more than one vehicle. §7's active vehicle is not
  /// consulted and not written: §12 makes this toggle the one exception to the
  /// app-wide vehicle scope, and it stays scoped by never reaching for it.
  Future<List<HouseholdVehicle>> readHousehold(
    List<HouseholdVehicleFacts> vehicles, {
    required CivilDate today,
    required CostsRangeChoice choice,
  });
}

/// Tab 3's state.
class CostsNotifier extends Notifier<CostsState> {
  CostsInputs? _inputs;
  var _loading = false;

  /// Which vehicle the current state describes.
  ///
  /// Held and compared, because `_loading` was set true on the first call and
  /// never reset: `ensureLoaded` therefore ran exactly ONCE for the app's
  /// lifetime, and switching the active vehicle left tab 3 showing the first
  /// car's costs under the second car's name. That is worse than showing
  /// nothing, because it is a plausible number.
  String? _vehicleId;

  @override
  CostsState build() => const CostsState();

  /// Loads for [vehicleId], and reloads when that becomes a different one.
  void ensureLoaded(String vehicleId, {required CivilDate today}) {
    if (_loading) return;
    if (state.isLoaded && _vehicleId == vehicleId) return;
    _loading = true;
    _vehicleId = vehicleId;
    _inputs = null;
    unawaited(_guarded(vehicleId, today: today));
  }

  /// Selects a range chip and recomputes.
  Future<void> choose(
    CostsRangeChoice choice,
    String vehicleId, {
    required CivilDate today,
  }) async {
    state = state.copyWith(choice: choice);
    await _reload(vehicleId, today: today);
  }

  /// [_reload], with the failure path that `unawaited` otherwise loses.
  ///
  /// `_loading` was cleared only on the success path, so any throw from the
  /// read — a `VehicleId` that will not parse, a disk error — left the flag
  /// true and `isLoaded` false for the life of the provider. Tab 3 then showed
  /// its empty state permanently, with the exception surfacing as an unhandled
  /// async error somewhere else entirely.
  ///
  /// `isLoaded` stays false rather than becoming an empty screen: §1 forbids
  /// stating what the app does not know, and "No costs yet" after a failed
  /// read is exactly that.
  Future<void> _guarded(String vehicleId, {required CivilDate today}) async {
    try {
      await _reload(vehicleId, today: today);
    } on Object {
      _vehicleId = null;
      _inputs = null;
    } finally {
      _loading = false;
    }
  }

  Future<void> _reload(String vehicleId, {required CivilDate today}) async {
    // ONE read, then a pure narrowing. See `CostsInputs`.
    final inputs = _inputs ??= await ref
        .read(costsRepositoryProvider)
        .read(vehicleId, range: null);

    final range = _rangeFor(state.choice, inputs, today);
    final data = inputs.narrow(range);

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
      businessPercent: data.businessPercent,
      includeInactive: state.includeInactive,
      showsHousehold: state.showsHousehold,
      household: state.household,
      isLoaded: true,
    );
  }

  /// Loads §12's household list.
  ///
  /// Called when the All-vehicles toggle is turned on, and again when the
  /// Include-sold-and-archived switch moves — the aggregation changes, and
  /// §12 keeps the RANGE across both, because a household comparison that
  /// silently answered a different question from the one on screen a moment
  /// ago is a comparison nobody can trust.
  Future<void> loadHousehold(
    List<HouseholdVehicleFacts> vehicles, {
    required CivilDate today,
  }) async {
    final rows = await ref
        .read(costsRepositoryProvider)
        .readHousehold(vehicles, today: today, choice: state.choice);
    state = state.copyWith(
      household: buildHousehold(
        vehicles: rows,
        includeInactive: state.includeInactive,
      ),
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
  void toggleAllVehicles({required bool includeAllVehicles}) {
    state = state.copyWith(showsHousehold: includeAllVehicles);
  }

  /// Sets §12's sold-and-archived switch, inside the panel.
  void setIncludeInactive({required bool include}) {
    state = state.copyWith(includeInactive: include);
  }

  static CostRange? _rangeFor(
    CostsRangeChoice choice,
    CostsInputs inputs,
    CivilDate today,
  ) => costsRangeFor(choice, inputs, today);
}

/// The window [choice] resolves to for [inputs].
///
/// Top-level, because the household read needs the same mapping for every
/// vehicle in the garage and a second copy of it is a second answer to which
/// months a chip means.
CostRange? costsRangeFor(
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

/// Tab 3's provider.
final NotifierProvider<CostsNotifier, CostsState> costsProvider =
    NotifierProvider<CostsNotifier, CostsState>(CostsNotifier.new);

/// The store tab 3 reads through. Overridden in tests.
final Provider<CostsRepository> costsRepositoryProvider =
    Provider<CostsRepository>(
      (ref) => CostsSource(
        ref.watch(fillUpRepositoryProvider),
        ref.watch(expenseRepositoryProvider),
        ref.watch(serviceRepositoryProvider),
        ref.watch(odometerRepositoryProvider),
        ref.watch(tripRepositoryProvider),
        // The SETTING, falling back to what the locale implies —
        // `resolveCalendar` is the one place that decision lives, and §18 has
        // an open question about whether `ckb-IR` should default to Jalali.
        resolveCalendar(
          CalmCalendar.tryFromWire(
            ref.watch(settingsProvider).value?.calendar,
          ),
          ref.watch(resolvedLocaleTagsProvider).formats,
        ),
      ),
    );
