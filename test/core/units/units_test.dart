// Volume, Energy, Mass and the sealed FuelQuantity.
//
// SPEC.md §3 Canonical units. The three gallon and litre factors are asserted
// rather than commented, because a factor in a comment is a factor nobody
// checks — and 20 mpg means two different things depending on which gallon.
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

void main() {
  group('volume', () {
    test('one litre is 1000 mL', () {
      expect(const Volume.fromLitres(1).millilitres, 1000);
      expect(const Volume.fromLitres(45).litres, 45.0);
    });

    test('one US gallon is 3785.411784 mL', () {
      // Exact, not measured: the US gallon is 231 cubic inches and the inch is
      // exactly 25.4 mm.
      //
      // The constant is NANOlitres, and the name is the only thing checking
      // the arithmetic: the first version called it `microlitres` with this
      // same value, and every gallon reading came out a thousandfold wrong.
      expect(nanolitresPerGallonUs, 3785411784);
      expect(const Volume(3785).gallonsUs, closeTo(0.99989, 0.0001));
      expect(const Volume(3785412).gallonsUs, closeTo(1000, 0.001));
    });

    test('one imperial gallon is 4546.09 mL, a DIFFERENT unit', () {
      expect(nanolitresPerGallonUk, 4546090000);
      expect(const Volume(4546090).gallonsUk, closeTo(1000, 0.001));

      // The whole reason they are two constants: the same volume reads
      // differently, and conflating them puts a 20% error into a consumption
      // figure that looks entirely reasonable.
      const tank = Volume(50000);
      expect(tank.gallonsUs, closeTo(13.209, 0.001));
      expect(tank.gallonsUk, closeTo(10.999, 0.001));
      expect(tank.gallonsUs, isNot(closeTo(tank.gallonsUk, 1)));
    });

    test('the display unit does not change the canonical value', () {
      const tank = Volume(45200);
      expect(tank.inUnit(VolumeUnit.l), tank.litres);
      expect(tank.inUnit(VolumeUnit.galUs), tank.gallonsUs);
      expect(tank.inUnit(VolumeUnit.galUk), tank.gallonsUk);
      expect(tank.millilitres, 45200);
    });
  });

  group('energy', () {
    test('kWh is watt-hours times 1000', () {
      expect(const Energy.fromKwh(52).wattHours, 52000);
      expect(const Energy(52300).kwh, 52.3);
    });

    test('watt-hours keep a tenth of a kWh exact', () {
      // A charging session is quoted to a tenth. Integer kWh would round every
      // one of them, and a 52.3 kWh session stored as 52 is a 0.6% error in
      // every consumption figure it feeds.
      expect(const Energy(52300).kwh, 52.3);
      expect(const Energy(52350).kwh, 52.35);
    });
  });

  group('mass', () {
    test('kg is grams times 1000', () {
      expect(const Mass.fromKg(12).grams, 12000);
      expect(const Mass(12500).kg, 12.5);
    });
  });

  group('a fuel quantity is exactly one of three', () {
    test('a switch over it needs no default', () {
      // The point of the sealed type. A fourth fuel form becomes a compile
      // error at every call site rather than a silent fall-through — and the
      // three are NOT interchangeable: CNG is sold by mass, electricity by
      // energy, and conflating them produces litres per 100 km for a car with
      // no tank.
      String describe(FuelQuantity quantity) => switch (quantity) {
        LiquidVolume(:final volume) => 'liquid ${volume.millilitres}mL',
        GasMass(:final mass) => 'gas ${mass.grams}g',
        ElectricEnergy(:final energy) => 'electric ${energy.wattHours}Wh',
      };

      expect(describe(const LiquidVolume(Volume(45200))), 'liquid 45200mL');
      expect(describe(const GasMass(Mass(12000))), 'gas 12000g');
      expect(
        describe(const ElectricEnergy(Energy(52000))),
        'electric 52000Wh',
      );
    });

    test('zero is recognised whatever the form', () {
      // A fill-up of nothing is not a fill-up, and it divides into the
      // consumption maths.
      expect(const LiquidVolume(Volume.zero).isZero, isTrue);
      expect(const GasMass(Mass.zero).isZero, isTrue);
      expect(const ElectricEnergy(Energy.zero).isZero, isTrue);
      expect(const LiquidVolume(Volume(1)).isZero, isFalse);
    });

    test('two quantities of different KINDS are never equal', () {
      // 12,000 of something is not 12,000 of something else. Without the type
      // check these would compare equal on their props alone.
      expect(
        const GasMass(Mass(12000)) == const LiquidVolume(Volume(12000)),
        isFalse,
      );
    });
  });
}
