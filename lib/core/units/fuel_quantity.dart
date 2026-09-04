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

  /// The canonical integer: millilitres, grams or watt-hours.
  ///
  /// Every other value object in this epic exposes its canonical integer, and
  /// this one did not — so every caller that needed to add two quantities
  /// destructured the sealed type by hand. That switch was written FOUR times
  /// before this existed, and two of the copies disagreed with the other two.
  ///
  /// The unit is NOT in the number and this getter does not say what it is:
  /// two amounts are only comparable when the forms match, which [withAmount]
  /// and [operator +] are what enforce.
  int get amount;

  /// The same form, carrying [amount] instead.
  ///
  /// The inverse of [amount], and the pair is what lets a caller do arithmetic
  /// on the integer without ever losing which physical thing it counts.
  FuelQuantity withAmount(int amount);

  /// Whether this quantity is zero.
  ///
  /// A fill-up of nothing is not a fill-up, and it divides into the
  /// consumption maths.
  bool get isZero => amount == 0;

  /// Adds two quantities OF THE SAME FORM.
  ///
  /// Throws for a mismatch, exactly as `Money.+` throws across currencies and
  /// for the same reason: litres plus grams is not a smaller or larger
  /// quantity, it is not a quantity, and a caller that asks for one is wrong.
  /// A screen cannot recover from this, so it is a programmer error and not a
  /// typed failure.
  ///
  /// A LIST that mixes forms is different — see [sumOf].
  FuelQuantity operator +(FuelQuantity other) {
    if (other.runtimeType != runtimeType) {
      throw ArgumentError(
        'cannot add $runtimeType to ${other.runtimeType}: a fuel quantity is '
        'a volume, a mass or an energy, and the three are not interchangeable',
      );
    }
    return withAmount(amount + other.amount);
  }

  /// The total of [quantities], or null if they are not all the same form.
  ///
  /// **Null and not a throw**, unlike [operator +]. A mixed run is DATA rather
  /// than a caller mistake: a bi-fuel car whose fills an importer landed under
  /// one `fuel_kind` produces one, and SPEC.md §3 says the engine discards
  /// such a segment rather than averaging across two physical things. An empty
  /// run is null too — summing nothing has no form, and inventing one would
  /// report zero litres for a car that runs on electricity.
  static FuelQuantity? sumOf(Iterable<FuelQuantity> quantities) {
    final iterator = quantities.iterator;
    if (!iterator.moveNext()) return null;

    var total = iterator.current;
    while (iterator.moveNext()) {
      if (iterator.current.runtimeType != total.runtimeType) return null;
      total = total.withAmount(total.amount + iterator.current.amount);
    }
    return total;
  }
}

/// Petrol, diesel, LPG — anything sold by the litre.
final class LiquidVolume extends FuelQuantity {
  /// Creates a liquid quantity.
  const LiquidVolume(this.volume);

  /// How much.
  final Volume volume;

  @override
  int get amount => volume.millilitres;

  @override
  LiquidVolume withAmount(int amount) => LiquidVolume(Volume(amount));

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
  int get amount => mass.grams;

  @override
  GasMass withAmount(int amount) => GasMass(Mass(amount));

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
  int get amount => energy.wattHours;

  @override
  ElectricEnergy withAmount(int amount) => ElectricEnergy(Energy(amount));

  @override
  List<Object?> get props => [energy];
}
