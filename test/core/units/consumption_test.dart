// The six consumption conversions, and the refusals.
//
// SPEC.md §3 Display conversion and rounding. Every formula is checked against
// an INDEPENDENT oracle — `testing-strategy` rule 3 — because checking a
// function against itself proves only that it is consistent.
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';
import 'package:test/test.dart';

/// 41.2 L over 640 km — SPEC.md §3's worked case.
Consumption get _worked => const Consumption(
  distance: Distance(640000),
  quantity: LiquidVolume(Volume(41200)),
);

void main() {
  group('the six formulas', () {
    test("l_100km matches SPEC.md's worked case", () {
      // 41.2 L over 640 km is 6.4375, which SPEC.md shows as 6.4 after the
      // consumption rounding of one decimal.
      expect(_worked.asUnit(ConsumptionUnit.lPer100km), closeTo(6.4375, 1e-9));
    });

    test('km_l is the reciprocal of l_100km times 100', () {
      final lPer100 = _worked.asUnit(ConsumptionUnit.lPer100km)!;
      final kmPerL = _worked.asUnit(ConsumptionUnit.kmPerL)!;
      expect(kmPerL, closeTo(100 / lPer100, 1e-9));
      expect(kmPerL, closeTo(15.5340, 1e-4));
    });

    test('mpg_us and mpg_uk agree with the independent oracle', () {
      // 235.214583 / (L/100km) and 282.481 / (L/100km) are the standard
      // conversion constants, derived from the gallon and mile definitions
      // rather than from this code. If both sides were the same arithmetic
      // this would prove nothing.
      final lPer100 = _worked.asUnit(ConsumptionUnit.lPer100km)!;

      expect(
        _worked.asUnit(ConsumptionUnit.mpgUs),
        closeTo(235.214583 / lPer100, 1e-3),
      );
      expect(
        _worked.asUnit(ConsumptionUnit.mpgUk),
        closeTo(282.481 / lPer100, 1e-3),
      );
    });

    test('the two gallons give visibly different MPG', () {
      // The whole reason they are separate units. Reporting one as the other
      // is a 20% error in a figure the user compares between cars.
      final us = _worked.asUnit(ConsumptionUnit.mpgUs)!;
      final uk = _worked.asUnit(ConsumptionUnit.mpgUk)!;
      expect(uk / us, closeTo(1.2009, 1e-3));
    });

    test('kwh_100km and mi_kwh work from an energy quantity', () {
      const ev = Consumption(
        distance: Distance(300000),
        quantity: ElectricEnergy(Energy(52000)),
      );

      // 52 kWh over 300 km.
      expect(
        ev.asUnit(ConsumptionUnit.kwhPer100km),
        closeTo(17.3333, 1e-4),
      );
      expect(ev.asUnit(ConsumptionUnit.miPerKwh), closeTo(3.58483, 1e-5));
    });

    test('the units are independent of how the fill-up was entered', () {
      // Litres in with MPG out is a supported pairing: plenty of people log in
      // litres and think in MPG.
      expect(_worked.asUnit(ConsumptionUnit.mpgUs), isNotNull);
      expect(_worked.asUnit(ConsumptionUnit.kmPerL), isNotNull);
    });
  });

  group('every conversion is total', () {
    test('a zero distance is not computable, never Infinity', () {
      // An Infinity that reaches a formatter becomes a very large number on a
      // screen, and SPEC.md §2 would rather show a dash than a plausible lie.
      const zeroDistance = Consumption(
        distance: Distance.zero,
        quantity: LiquidVolume(Volume(41200)),
      );

      expect(zeroDistance.isComputable, isFalse);
      for (final unit in ConsumptionUnit.values) {
        expect(zeroDistance.asUnit(unit), isNull, reason: unit.wire);
      }
    });

    test('a zero quantity is not computable', () {
      const zeroFuel = Consumption(
        distance: Distance(640000),
        quantity: LiquidVolume(Volume.zero),
      );

      expect(zeroFuel.isComputable, isFalse);
      expect(zeroFuel.asUnit(ConsumptionUnit.lPer100km), isNull);
      expect(zeroFuel.asUnit(ConsumptionUnit.kmPerL), isNull);
    });

    test('a negative distance is not computable', () {
      const backwards = Consumption(
        distance: Distance(-1000),
        quantity: LiquidVolume(Volume(41200)),
      );
      expect(backwards.isComputable, isFalse);
    });

    test('nothing returns NaN or Infinity for any unit', () {
      for (final consumption in [
        _worked,
        const Consumption(
          distance: Distance.zero,
          quantity: LiquidVolume(Volume.zero),
        ),
        const Consumption(
          distance: Distance(1),
          quantity: ElectricEnergy(Energy(1)),
        ),
      ]) {
        for (final unit in ConsumptionUnit.values) {
          final value = consumption.asUnit(unit);
          if (value != null) {
            expect(value.isFinite, isTrue, reason: '$consumption in $unit');
          }
        }
      }
    });
  });

  group('a mismatched pairing is a refusal, not a conversion', () {
    test('a litre quantity has no kWh figure', () {
      // Not zero and not a converted number: the question does not apply, and
      // answering it would be arithmetic on two different things.
      expect(_worked.asUnit(ConsumptionUnit.kwhPer100km), isNull);
      expect(_worked.asUnit(ConsumptionUnit.miPerKwh), isNull);
    });

    test('an energy quantity has no litre figure', () {
      const ev = Consumption(
        distance: Distance(300000),
        quantity: ElectricEnergy(Energy(52000)),
      );
      expect(ev.asUnit(ConsumptionUnit.lPer100km), isNull);
      expect(ev.asUnit(ConsumptionUnit.mpgUs), isNull);
    });

    test('CNG has no consumption unit at all', () {
      // Sold by mass, and SPEC.md §3 offers no mass-based unit. Returning a
      // litre figure would mean inventing a density.
      const cng = Consumption(
        distance: Distance(300000),
        quantity: GasMass(Mass(12000)),
      );

      expect(cng.isComputable, isTrue, reason: 'the pair is well-formed');
      for (final unit in ConsumptionUnit.values) {
        expect(cng.asUnit(unit), isNull, reason: unit.wire);
      }
    });
  });

  group('the unit knows which direction is better', () {
    test('four are fuel-per-distance and two are not', () {
      // A chart axis and a best/worst comparison both need this, and getting
      // it backwards makes the thirstiest tank the "best".
      expect(ConsumptionUnit.lPer100km.isFuelPerDistance, isTrue);
      expect(ConsumptionUnit.kwhPer100km.isFuelPerDistance, isTrue);
      expect(ConsumptionUnit.kmPerL.isFuelPerDistance, isFalse);
      expect(ConsumptionUnit.mpgUs.isFuelPerDistance, isFalse);
      expect(ConsumptionUnit.mpgUk.isFuelPerDistance, isFalse);
      expect(ConsumptionUnit.miPerKwh.isFuelPerDistance, isFalse);
    });

    test('two are electric', () {
      expect(ConsumptionUnit.kwhPer100km.isElectric, isTrue);
      expect(ConsumptionUnit.miPerKwh.isElectric, isTrue);
      expect(ConsumptionUnit.lPer100km.isElectric, isFalse);
    });

    test('the six wire values match SPEC.md §3 Enums', () {
      expect(ConsumptionUnit.values.map((u) => u.wire), [
        'l_100km',
        'km_l',
        'mpg_us',
        'mpg_uk',
        'kwh_100km',
        'mi_kwh',
      ]);
    });
  });
}
