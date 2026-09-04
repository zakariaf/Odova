// What went into the tank: a volume, a mass, or an energy.
//
// SPEC.md §3 Entities (`FillUp`): "exactly one of these three is non-null,
// discriminated by fuel_kind". A sealed type says that in the type system
// instead of in a comment — a `switch` over it needs no `default:`, so the
// mapper cannot forget a case and a fourth fuel form would be a compile error
// at every call site rather than a silent fall-through.
//
// Three types and not one number with a unit beside it, because the three are
// not interchangeable. CNG is sold by MASS: a kilogram of compressed gas is a
// fixed amount of fuel and a litre of it is not. Electricity is sold by ENERGY.
// Conflating them is how a consumption figure comes out as litres per 100 km
// for a car with no tank.
import 'package:meta/meta.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/core/value_equality.dart';

/// How much fuel a fill-up put in.
@immutable
sealed class FuelQuantity with ValueEquality {
  const FuelQuantity();

  /// Whether this quantity is zero.
  ///
  /// A fill-up of nothing is not a fill-up, and it divides into the
  /// consumption maths.
  bool get isZero;
}

/// Petrol, diesel, LPG — anything sold by the litre.
final class LiquidVolume extends FuelQuantity {
  /// Creates a liquid quantity.
  const LiquidVolume(this.volume);

  /// How much.
  final Volume volume;

  @override
  bool get isZero => volume.millilitres == 0;

  @override
  List<Object?> get props => [volume];
}

/// CNG, sold by mass.
final class GasMass extends FuelQuantity {
  /// Creates a gas quantity.
  const GasMass(this.mass);

  /// How much.
  final Mass mass;

  @override
  bool get isZero => mass.grams == 0;

  @override
  List<Object?> get props => [mass];
}

/// Electricity, sold by energy.
final class ElectricEnergy extends FuelQuantity {
  /// Creates an electric quantity.
  const ElectricEnergy(this.energy);

  /// How much.
  final Energy energy;

  @override
  bool get isZero => energy.wattHours == 0;

  @override
  List<Object?> get props => [energy];
}
