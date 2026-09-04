// What fuel costs, per currency, never blended.
//
// SPEC.md §3 Fuel maths (`unitPrice`), §3 Currency, §12 `costs.fuel`, §14
// (*Fill-ups in a second currency*).
//
// The rule that shapes this whole file: the app has no exchange rate, so every
// money figure is returned PER CURRENCY. A price per litre that added euros to
// pounds and divided by litres is a number with no meaning that looks like a
// price, and somebody would compare it between two cars.
import 'package:meta/meta.dart';
import 'package:odova/core/fuel/consumption_unavailable.dart';
import 'package:odova/core/fuel/fuel_result.dart';
import 'package:odova/core/fuel/fuel_segment.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/core/value_equality.dart';

/// A fill-up, reduced to what the money figures need.
typedef FillUpCost = ({String id, Money cost, FuelQuantity quantity});

/// The price of one unit of fuel.
///
/// DERIVED, never stored. SPEC.md §3: the form takes any two of {total,
/// quantity, price per unit} and computes the third, and only total and
/// quantity persist — store all three and they will one day disagree, and then
/// nobody knows which is the receipt.
///
/// Returned as minor units per canonical fuel unit — per millilitre, per gram,
/// per watt-hour — because that is the only ratio that stays exact. The
/// presentation edge multiplies up to a litre or a gallon and rounds to three
/// decimals, per SPEC.md §3's table.
FuelValue<double> unitPrice(FillUpCost fill) {
  final amount = _amountOf(fill.quantity);
  if (amount <= 0) {
    return const Unavailable(InsufficientData(have: 0, need: 1));
  }
  return Computed(fill.cost.amountMinor / amount);
}

/// The average price paid, per currency.
///
/// Total cost over total quantity — NOT the mean of the per-fill unit prices.
/// A 5 L top-up at a motorway price and a 60 L fill at a supermarket price have
/// a mean that sits halfway between them and an average that sits near the
/// supermarket, which is what the driver actually paid.
Map<Currency, double> avgPricePaid(Iterable<FillUpCost> fills) {
  final cost = <Currency, int>{};
  final quantity = <Currency, int>{};

  for (final fill in fills) {
    final amount = _amountOf(fill.quantity);
    if (amount <= 0) continue;
    cost.update(
      fill.cost.currency,
      (c) => c + fill.cost.amountMinor,
      ifAbsent: () => fill.cost.amountMinor,
    );
    quantity.update(
      fill.cost.currency,
      (q) => q + amount,
      ifAbsent: () => amount,
    );
  }

  return {
    for (final entry in cost.entries)
      if (quantity[entry.key]! > 0)
        entry.key: entry.value / quantity[entry.key]!,
  };
}

/// What was spent on fuel, per currency.
Map<Currency, Money> fuelSpend(Iterable<FillUpCost> fills) {
  final byCurrency = <Currency, int>{};
  for (final fill in fills) {
    byCurrency.update(
      fill.cost.currency,
      (sum) => sum + fill.cost.amountMinor,
      ifAbsent: () => fill.cost.amountMinor,
    );
  }
  return {
    for (final entry in byCurrency.entries)
      entry.key: Money(entry.value, entry.key),
  };
}

/// The cost of a distance, per currency, and what had to be left out.
@immutable
class FuelCostPerDistance with ValueEquality {
  /// Creates a result.
  const FuelCostPerDistance({
    required this.minorPerMetre,
    required this.excludedSegmentCount,
  });

  /// Minor units per metre, per currency.
  final Map<Currency, double> minorPerMetre;

  /// How many segments were left out because their fills spanned two
  /// currencies.
  ///
  /// Counted rather than silently dropped, because SPEC.md §12 wants the
  /// data-quality row: "1 tank spanned two currencies — no cost per kilometre
  /// for it." A silent drop makes the figure quietly cover less than the user
  /// thinks it does.
  final int excludedSegmentCount;

  @override
  List<Object?> get props => [
    for (final entry in _sorted) '${entry.key.code}:${entry.value}',
    excludedSegmentCount,
  ];

  List<MapEntry<Currency, double>> get _sorted =>
      minorPerMetre.entries.toList()
        ..sort((a, b) => a.key.code.compareTo(b.key.code));
}

/// What each metre of [segments] cost, per currency.
///
/// Uses exactly the fills whose fuel BUILT each segment: those after the
/// opening fill, up to and including the closing one. An open, unmeasured
/// segment at the end contributes neither cost nor distance — charging its
/// fuel against a distance that excludes it is the bug this shape exists to
/// prevent, and it makes the figure high by exactly one tank.
FuelCostPerDistance fuelCostPerDistance(
  List<FuelSegment> segments,
  Map<String, FillUpCost> costsByFillId,
  Map<String, List<String>> contributingFillIds,
) {
  final cost = <Currency, int>{};
  final distance = <Currency, int>{};
  var excluded = 0;

  for (final segment in segments) {
    final ids = contributingFillIds[segment.toFillUpId] ?? const <String>[];
    final fills = [
      for (final id in ids)
        if (costsByFillId[id] != null) costsByFillId[id]!,
    ];
    if (fills.isEmpty) continue;

    final currencies = fills.map((f) => f.cost.currency).toSet();
    if (currencies.length > 1) {
      // SPEC.md §14: a tank filled across a border. It still contributed its
      // volume and its distance to the CONSUMPTION figure; only the money is
      // unanswerable, because the app has no rate.
      excluded++;
      continue;
    }

    final currency = currencies.single;
    cost.update(
      currency,
      (c) => c + fills.fold(0, (s, f) => s + f.cost.amountMinor),
      ifAbsent: () => fills.fold(0, (s, f) => s + f.cost.amountMinor),
    );
    distance.update(
      currency,
      (d) => d + segment.distance.metres,
      ifAbsent: () => segment.distance.metres,
    );
  }

  return FuelCostPerDistance(
    minorPerMetre: {
      for (final entry in cost.entries)
        if ((distance[entry.key] ?? 0) > 0)
          entry.key: entry.value / distance[entry.key]!,
    },
    excludedSegmentCount: excluded,
  );
}

/// The total fuel volume across [fills], where they share a form.
FuelValue<FuelQuantity> fuelVolume(Iterable<FillUpCost> fills) {
  final list = fills.toList();
  if (list.isEmpty) {
    return const Unavailable(InsufficientData(have: 0, need: 1));
  }
  final total = list.fold(0, (sum, f) => sum + _amountOf(f.quantity));
  return Computed(_rebuild(list.first.quantity, total));
}

int _amountOf(FuelQuantity quantity) => switch (quantity) {
  LiquidVolume(:final volume) => volume.millilitres,
  GasMass(:final mass) => mass.grams,
  ElectricEnergy(:final energy) => energy.wattHours,
};

FuelQuantity _rebuild(FuelQuantity like, int amount) => switch (like) {
  LiquidVolume() => LiquidVolume(Volume(amount)),
  GasMass() => GasMass(Mass(amount)),
  ElectricEnergy() => ElectricEnergy(Energy(amount)),
};
