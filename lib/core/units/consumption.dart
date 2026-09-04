// How much fuel a distance took, in any of the six units the user might pick.
//
// SPEC.md §3 Display conversion and rounding. The canonical form is the PAIR —
// a distance and a quantity — and not a ratio, because the six units are not
// all the same ratio: four are fuel-per-distance and two are
// distance-per-fuel, and storing one and inverting loses precision in the
// direction nobody notices.
//
// Every conversion is TOTAL. A zero distance or a zero quantity returns the
// explicit not-computable value rather than `Infinity` or `NaN`, because an
// Infinity that reaches a formatter becomes a very large number on a screen and
// SPEC.md §2 forbids showing a plausible lie.
import 'package:meta/meta.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/value_equality.dart';

/// How consumption is shown.
enum ConsumptionUnit {
  /// Litres per 100 km.
  lPer100km('l_100km'),

  /// Kilometres per litre.
  kmPerL('km_l'),

  /// Miles per US gallon.
  mpgUs('mpg_us'),

  /// Miles per imperial gallon.
  mpgUk('mpg_uk'),

  /// Kilowatt-hours per 100 km.
  kwhPer100km('kwh_100km'),

  /// Miles per kilowatt-hour.
  miPerKwh('mi_kwh');

  const ConsumptionUnit(this.wire);

  /// The value as stored and exported.
  final String wire;

  /// Whether this unit measures fuel PER distance (lower is better).
  ///
  /// The four that are, versus the two that are not. A chart axis and a
  /// best/worst comparison both need to know which direction is good, and
  /// getting it backwards makes the thirstiest tank the "best".
  bool get isFuelPerDistance => switch (this) {
    ConsumptionUnit.lPer100km || ConsumptionUnit.kwhPer100km => true,
    ConsumptionUnit.kmPerL ||
    ConsumptionUnit.mpgUs ||
    ConsumptionUnit.mpgUk ||
    ConsumptionUnit.miPerKwh => false,
  };
}

/// A distance and the fuel it took.
@immutable
class Consumption with ValueEquality {
  /// Creates a consumption from its canonical pair.
  const Consumption({required this.distance, required this.quantity});

  /// How far.
  final Distance distance;

  /// How much fuel.
  final FuelQuantity quantity;

  /// Whether a figure can be computed at all.
  ///
  /// Zero distance means dividing by zero; zero fuel means a segment that
  /// cannot have happened. Both are refusals rather than numbers.
  bool get isComputable => distance.metres > 0 && !quantity.isZero;

  /// This consumption in [unit], or null when it cannot be computed.
  ///
  /// Null and not `Infinity`: an Infinity that reaches a formatter becomes a
  /// very large number on a screen, and SPEC.md §2 would rather show a dash.
  /// Null also covers a MISMATCHED pairing — litres asked for in kWh — because
  /// a converted answer there would be arithmetic on two different things.
  double? asUnit(ConsumptionUnit unit) {
    if (!isComputable) return null;

    return switch (quantity) {
      LiquidVolume(:final volume) => switch (unit) {
        // (mL/1000) / (m/1000) x 100  ==  mL / m / 10
        ConsumptionUnit.lPer100km => volume.litres / distance.km * 100,
        ConsumptionUnit.kmPerL => distance.km / volume.litres,
        ConsumptionUnit.mpgUs => distance.miles / volume.gallonsUs,
        ConsumptionUnit.mpgUk => distance.miles / volume.gallonsUk,
        // A litre quantity has no kWh figure. Not zero, not a conversion: the
        // question does not apply.
        ConsumptionUnit.kwhPer100km || ConsumptionUnit.miPerKwh => null,
      },
      ElectricEnergy(:final energy) => switch (unit) {
        ConsumptionUnit.kwhPer100km => energy.kwh / distance.km * 100,
        ConsumptionUnit.miPerKwh => distance.miles / energy.kwh,
        // An energy quantity has no litre or gallon figure, for the same
        // reason a litre has no kWh one. Listed rather than caught by a
        // wildcard, so a seventh unit is a COMPILE error here and not a silent
        // null on a screen.
        ConsumptionUnit.lPer100km ||
        ConsumptionUnit.kmPerL ||
        ConsumptionUnit.mpgUs ||
        ConsumptionUnit.mpgUk => null,
      },
      // CNG is sold by mass and SPEC.md §3 offers no mass-based consumption
      // unit. Returning a litre figure would mean inventing a density.
      GasMass() => null,
    };
  }

  @override
  List<Object?> get props => [distance, quantity];

  @override
  String toString() => 'Consumption($distance, $quantity)';
}
