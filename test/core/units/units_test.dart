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
  group('FuelQuantity arithmetic', () {
    // The same three-arm switch was written FOUR times before this existed —
    // `_sum` in build_fuel_segments, `_sumQuantities` in consumption_stats,
    // `_ratio`/`_totalOverTotal` in consumption_trend and `_amountOf`/`_rebuild`
    // in fuel_money — and two of the copies disagreed with the other two. The
    // rule "same form or nothing" belongs on the type, once.

    test('the canonical amount is readable without a switch', () {
      // Every other value object in this epic exposes its canonical integer.
      // FuelQuantity was the one that did not, which is why every caller
      // destructured it by hand.
      expect(const LiquidVolume(Volume(45200)).amount, 45200);
      expect(const GasMass(Mass(4520)).amount, 4520);
      expect(const ElectricEnergy(Energy(52000)).amount, 52000);
    });

    test('withAmount keeps the form and changes only the number', () {
      expect(
        const LiquidVolume(Volume(1)).withAmount(45200),
        const LiquidVolume(Volume(45200)),
      );
      expect(
        const GasMass(Mass(1)).withAmount(4520),
        const GasMass(Mass(4520)),
      );
      expect(
        const ElectricEnergy(Energy(1)).withAmount(52000),
        const ElectricEnergy(Energy(52000)),
      );
    });

    test('adding two of the same form adds their amounts', () {
      expect(
        const LiquidVolume(Volume(40000)) + const LiquidVolume(Volume(5200)),
        const LiquidVolume(Volume(45200)),
      );
      expect(
        const GasMass(Mass(4000)) + const GasMass(Mass(520)),
        const GasMass(Mass(4520)),
      );
    });

    test('adding two DIFFERENT forms is a programmer error, not a total', () {
      // Litres plus grams is not a quantity. `Money.+` refuses across
      // currencies for the same reason and in the same way: a screen that
      // tries it is wrong, so it throws rather than returning a plausible
      // number nobody can tell is wrong.
      expect(
        () => const LiquidVolume(Volume(1)) + const GasMass(Mass(1)),
        throwsArgumentError,
      );
      expect(
        () => const ElectricEnergy(Energy(1)) + const LiquidVolume(Volume(1)),
        throwsArgumentError,
      );
    });

    group('sumOf', () {
      test('adds a run of one form', () {
        expect(
          FuelQuantity.sumOf(const [
            LiquidVolume(Volume(40000)),
            LiquidVolume(Volume(15000)),
            LiquidVolume(Volume(20000)),
          ]),
          const LiquidVolume(Volume(75000)),
        );
      });

      test('works for every form, not just litres', () {
        // The copy in consumption_trend handled ONLY LiquidVolume, so
        // consumptionTrend refused every EV history — a car with 40 charges
        // logged was told there was not enough data.
        expect(
          FuelQuantity.sumOf(const [
            ElectricEnergy(Energy(52000)),
            ElectricEnergy(Energy(48000)),
          ]),
          const ElectricEnergy(Energy(100000)),
        );
        expect(
          FuelQuantity.sumOf(const [GasMass(Mass(4000)), GasMass(Mass(520))]),
          const GasMass(Mass(4520)),
        );
      });

      test('a mixed run is null, never a coerced total', () {
        // Returning null rather than throwing, because a MIXED SEGMENT is data
        // and not a bug: a bi-fuel car logged under one fuel_kind by an
        // importer produces one. The engine discards it; it must not average
        // it. `+` throws because a single addition of two forms is a caller
        // mistake; `sumOf` refuses because a list of them is an input.
        expect(
          FuelQuantity.sumOf(const [
            LiquidVolume(Volume(40000)),
            GasMass(Mass(4000)),
          ]),
          isNull,
        );
      });

      test('an empty run is null, not a zero of some form', () {
        // Summing nothing has no form. Inventing one would report zero litres
        // for a car that runs on electricity.
        expect(FuelQuantity.sumOf(const []), isNull);
      });
    });
  });
}
