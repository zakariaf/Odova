// Which of the three quantity columns a fill-up fills.
//
// SPEC.md §3: exactly one of `quantity_ml`, `quantity_g` and `energy_wh` is
// non-null, decided by fuel kind. §10 relabels the field to match — `L`,
// `kg`, `kWh` — so the label the user reads and the column the app writes come
// from the same answer.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/features/logging/domain/fuel_quantity_input.dart';
import 'package:test/test.dart';

void main() {
  test('petrol, diesel, LPG and the rest are a VOLUME', () {
    for (final kind in [
      FuelKind.petrol,
      FuelKind.diesel,
      FuelKind.lpg,
      FuelKind.hybrid,
      FuelKind.other,
    ]) {
      final quantity = fuelQuantityFrom(kind: kind, canonical: '42.61');
      expect(quantity, isA<LiquidVolume>(), reason: kind.wire);
      expect(quantity!.amount, 42610, reason: '${kind.wire} in millilitres');
    }
  });

  test('CNG is a MASS — it is sold by the kilogram', () {
    final quantity = fuelQuantityFrom(kind: FuelKind.cng, canonical: '4.5');
    expect(quantity, isA<GasMass>());
    expect(quantity!.amount, 4500, reason: 'grams');
  });

  test('electric is an ENERGY', () {
    final quantity = fuelQuantityFrom(
      kind: FuelKind.electric,
      canonical: '52.4',
    );
    expect(quantity, isA<ElectricEnergy>());
    expect(quantity!.amount, 52400, reason: 'watt-hours');
  });

  test('it scales by string, like everything else on its way to a column', () {
    // 1.0005 * 1000 is 1000.4999999999999 through a double.
    expect(
      fuelQuantityFrom(kind: FuelKind.petrol, canonical: '1.0005')!.amount,
      1001,
    );
  });

  test('a negative quantity is not a quantity', () {
    // §10 gives the keypad no minus key; a negative can only arrive by paste.
    expect(fuelQuantityFrom(kind: FuelKind.petrol, canonical: '-1'), isNull);
  });

  test('nothing typed is null, not zero', () {
    // Zero litres is a claim; an empty field is the absence of one, and the
    // column is nullable precisely so the two stay different.
    expect(fuelQuantityFrom(kind: FuelKind.petrol, canonical: ''), isNull);
  });
}
