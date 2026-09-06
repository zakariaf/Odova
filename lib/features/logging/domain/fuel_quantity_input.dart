// A typed quantity, into the one column its fuel kind uses.
//
// SPEC.md §3: a fill-up has three quantity columns — `quantity_ml`,
// `quantity_g`, `energy_wh` — and exactly one of them is non-null. Which one is
// not a choice the form makes; it follows from the fuel kind, because CNG is
// sold by the kilogram and electricity by the kilowatt-hour and petrol by the
// litre, and a litre of electricity is not a thing.
//
// `FuelQuantity` is the sealed type that says this better than three nullable
// fields do. This file is the one place a STRING becomes one.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/features/logging/domain/decimal_input.dart';

/// [canonical] as the quantity [kind] is sold by, or null.
///
/// Null for an empty field, for anything that is not a number, and for a
/// negative — §10 gives the keypad no minus key, so a negative litre figure
/// can only arrive by paste and is not a volume. Null is not zero: zero litres
/// is a claim about a fill-up and an empty field is the absence of one, which
/// is why the columns are nullable.
///
/// The scaling is `scaleByPowerOfTen` underneath, so `1.0005 L` is 1001 mL and
/// not the 1000 a double would produce.
FuelQuantity? fuelQuantityFrom({
  required FuelKind kind,
  required String canonical,
}) => switch (kind) {
  // Sold by MASS. §3 names `quantity_g` for exactly this.
  FuelKind.cng => switch (gramsFrom(canonical)) {
    final int grams => GasMass(Mass(grams)),
    _ => null,
  },
  // Sold by ENERGY.
  FuelKind.electric => switch (wattHoursFrom(canonical)) {
    final int wh => ElectricEnergy(Energy(wh)),
    _ => null,
  },
  // Everything else is a liquid. `hybrid` and `other` land here because the
  // FILL-UP has one kind even when the vehicle has two: §10 shows the fuel-kind
  // row on those vehicles precisely so this answer comes from the user rather
  // than from a default that would be wrong half the time.
  FuelKind.petrol ||
  FuelKind.diesel ||
  FuelKind.lpg ||
  FuelKind.hybrid ||
  FuelKind.other => switch (millilitresFrom(canonical)) {
    final int ml => LiquidVolume(Volume(ml)),
    _ => null,
  },
};
