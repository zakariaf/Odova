// SPEC.md §12's `costs.fuel` numbers, composed from EPIC-06's engines.
//
// Two rules decide most of this file.
//
// EVERY AVERAGE IS TOTAL OVER TOTAL. A mean of per-segment figures weights a
// 40 km tank the same as a 900 km one — on the worked fixture in the tests
// that is 13.0 L/100 km against a true 6.6, and it is the number a naive
// implementation prints on the screen a user opens to decide whether the car
// got thirstier.
//
// A SEGMENT WHOSE CONTRIBUTING FILLS MIX CURRENCIES CONTRIBUTES VOLUME AND
// DISTANCE BUT NO MONEY. Dividing euros by litres bought in pounds is the
// arithmetic §12 forbids outright, and the exclusion lives here rather than on
// the screen so a second screen cannot forget it. The segment is COUNTED, so
// the screen can explain why a money figure is thinner than the consumption
// figure beside it.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/build_fuel_segments.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/fuel_quantity.dart';

/// A fill, with what it cost.
///
/// `FillUpPoint` plus the money, because the fuel engine deliberately does not
/// know about currency — §3 keeps the segment builder about volume and
/// distance, and the price figures are §12's, not §3's.
typedef InsightFill = ({
  String id,
  String occurredOn,
  int createdAtUtcMs,
  String fuelKind,
  int? cumulativeM,
  FuelQuantity quantity,
  bool isFullTank,
  bool chainBroken,
  int? tankCapacityMl,
  Money cost,
});

/// §12's fuel figures for one fuel kind, in one currency.
@immutable
class FuelInsights {
  const FuelInsights._({
    required this.costedFillIds,
    required this.mixedCurrencySegments,
    this.chartPoints = const [],
    this.averageLitresPer100Km,
    this.lastLitresPer100Km,
    this.bestOccurredOn,
    this.worstOccurredOn,
    this.averageUnitPriceMinor,
    this.costPerKmMinor,
  });

  /// Every figure, from [fills] of ONE fuel kind.
  factory FuelInsights.forFills(
    List<InsightFill> fills, {
    required Currency currency,
  }) {
    final points = [
      for (final f in fills)
        (
          id: f.id,
          occurredOn: f.occurredOn,
          createdAtUtcMs: f.createdAtUtcMs,
          fuelKind: f.fuelKind,
          cumulativeM: f.cumulativeM,
          quantity: f.quantity,
          isFullTank: f.isFullTank,
          chainBroken: f.chainBroken,
          tankCapacityMl: f.tankCapacityMl,
        ),
    ];

    final set = buildFuelSegments(points);
    if (set.segments.isEmpty) {
      return const FuelInsights._(
        costedFillIds: {},
        mixedCurrencySegments: 0,
      );
    }

    final byId = {for (final f in fills) f.id: f};
    final ordered = [...points]..sort(compareFills);
    final indexOf = {
      for (final (i, p) in ordered.indexed) p.id: i,
    };

    // TOTAL over TOTAL, accumulated across every segment.
    var totalMetres = 0;
    var totalAmount = 0;

    // Money accumulates only over segments whose contributing fills are all
    // in `currency`.
    var costedMetres = 0;
    var costedMinor = 0;
    final costedIds = <String>{};
    var mixed = 0;

    for (final segment in set.segments) {
      totalMetres += segment.distance.metres;
      totalAmount += segment.quantity.amount;

      // The fills whose volume BUILT this segment: those after the opening
      // fill, up to and including the closing one. Including the opening
      // fill's own volume double-counts a tank burned before the segment
      // began — the off-by-one §3 calls the classic error in this category.
      final from = indexOf[segment.fromFillUpId];
      final to = indexOf[segment.toFillUpId];
      if (from == null || to == null) continue;
      final contributing = [
        for (var i = from + 1; i <= to; i++) ordered[i].id,
      ];

      final costs = [for (final id in contributing) byId[id]!.cost];
      if (costs.any((m) => m.currency != currency)) {
        mixed++;
        continue;
      }

      costedMetres += segment.distance.metres;
      costedMinor += costs.fold<int>(0, (s, m) => s + m.amountMinor);
      costedIds.addAll(contributing);
    }

    // The unit price is over EVERY fill in the currency, not only the costed
    // segments' — §12 asks what the user paid per litre, and the fill that
    // opened the first chain was paid for too.
    var priceMinor = 0;
    var priceAmount = 0;
    for (final f in fills) {
      if (f.cost.currency != currency) continue;
      priceMinor += f.cost.amountMinor;
      priceAmount += f.quantity.amount;
    }

    final newest = set.segments.last;
    final ranked = [...set.segments]
      ..sort((a, b) {
        final byFigure = _perHundred(a).compareTo(_perHundred(b));
        // A tie-break on the id, because Dart's `sort` is not documented as
        // stable: two tanks with identical consumption could otherwise swap
        // between runs, and best/worst is a figure the screen NAMES a date
        // for. `consumption_stats.dart`'s `_rank` states the same rule for
        // the same reason.
        return byFigure != 0 ? byFigure : a.toFillUpId.compareTo(b.toFillUpId);
      });

    final bestId = ranked.first.toFillUpId;
    final worstId = ranked.last.toFillUpId;

    return FuelInsights._(
      costedFillIds: costedIds,
      mixedCurrencySegments: mixed,
      chartPoints: [
        if (_isLiquid(set))
          for (final s in set.segments)
            (
              value: _perHundred(s),
              isBest: s.toFillUpId == bestId,
              isWorst: s.toFillUpId == worstId,
            ),
      ],
      averageLitresPer100Km: totalMetres == 0 || !_isLiquid(set)
          ? null
          : totalAmount / 1000 / (totalMetres / 1000) * 100,
      lastLitresPer100Km: _isLiquid(set) ? _perHundred(newest) : null,
      // The CLOSING fill's date. The day a user recognises is the one they
      // were at the pump, and that is the fill that ended the tank.
      bestOccurredOn: byId[ranked.first.toFillUpId]?.occurredOn,
      worstOccurredOn: byId[ranked.last.toFillUpId]?.occurredOn,
      averageUnitPriceMinor: priceAmount == 0
          ? null
          : priceMinor / (priceAmount / 1000),
      costPerKmMinor: costedMetres == 0
          ? null
          : costedMinor / (costedMetres / 1000),
    );
  }

  /// One set of figures per fuel kind.
  ///
  /// §12: a bi-fuel LPG car has TWO averages. Merging the series produces a
  /// figure for a fuel the car does not burn — and `buildFuelSegments`
  /// already refuses a mixed list, because an LPG fill in a petrol chain
  /// reads as a chain break.
  static Map<String, FuelInsights> byFuelKind(
    List<InsightFill> fills, {
    required Currency currency,
  }) {
    final byKind = <String, List<InsightFill>>{};
    for (final f in fills) {
      (byKind[f.fuelKind] ??= []).add(f);
    }
    return {
      for (final entry in byKind.entries)
        entry.key: FuelInsights.forFills(entry.value, currency: currency),
    };
  }

  /// The fills whose cost entered [costPerKmMinor].
  ///
  /// Exposed so a test can name them: an off-by-one at the segment boundary
  /// is invisible in the resulting figure and obvious in this set.
  final Set<String> costedFillIds;

  /// How many segments were excluded from the money figures for mixing
  /// currencies. §12's data-quality row reports it.
  final int mixedCurrencySegments;

  /// Total volume over total distance, as a per-100 km figure.
  final double? averageLitresPer100Km;

  /// The newest segment's figure.
  final double? lastLitresPer100Km;

  /// The closing fill's date for the most economical segment.
  final String? bestOccurredOn;

  /// And for the least.
  final String? worstOccurredOn;

  /// Total cost over total quantity — never the mean of per-fill unit prices,
  /// which weights a 5 L top-up the same as a 60 L fill.
  final double? averageUnitPriceMinor;

  /// Minor units per kilometre, over the costed segments only.
  final double? costPerKmMinor;

  /// Every segment's figure, OLDEST FIRST, with the best and worst marked.
  ///
  /// Oldest-first and never reversed: §12 mirrors the chart's AXIS under RTL
  /// and not its series, and the one place that distinction is applied is the
  /// painter's x mapping.
  final List<({double value, bool isBest, bool isWorst})> chartPoints;

  /// The segment's consumption in the unit its QUANTITY is measured in.
  ///
  /// `quantity.amount` is millilitres for a liquid and watt-hours for an
  /// electric charge, so `amount / 1000` is litres or kilowatt-hours and the
  /// arithmetic is right for both. What is NOT right for both is the name:
  /// every field this feeds is called `…LitresPer100Km` and the screen renders
  /// "L/100 km" beside it, so an electric car is shown kWh labelled as litres.
  ///
  /// SPEC.md §1 forbids guessing in a way that looks like fact, and a figure
  /// under the wrong unit is exactly that — so `_isLiquid` gates the fields
  /// rather than this function returning a wrong one. The proper fix is a
  /// unit-carrying figure through `Consumption.asUnit`, and it belongs with
  /// the fuel-kind selector this epic deferred: that control is where a
  /// bi-fuel or electric car chooses its unit in the first place.
  static double _perHundred(FuelSegment segment) => segment.distance.metres == 0
      ? 0
      : segment.quantity.amount / 1000 / (segment.distance.metres / 1000) * 100;

  /// Whether these figures are litres, and may therefore wear the L/100 km
  /// label the screen draws.
  static bool _isLiquid(FuelSegmentSet set) =>
      set.segments.every((s) => s.quantity is LiquidVolume);
}
