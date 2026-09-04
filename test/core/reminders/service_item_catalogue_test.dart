// The set a new vehicle arrives with.
//
// SPEC.md §4.8. Every row of its four tables is transcribed here as an
// assertion, because the catalogue is the one place in the app where a wrong
// number is invisible: a seeded interval that is quietly out by a factor of ten
// produces a reminder that never fires, and nobody notices a notification that
// did not arrive.
//
// §4.8 is also explicit that these are "round numbers approximately right for a
// lot of cars", never manufacturer advice. That is a copy decision, not a
// modelling one — the numbers still have to be the numbers the spec names.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/reminders/service_item_catalogue.dart';
import 'package:odova/core/units/distance.dart';
import 'package:test/test.dart';

/// The seeds for one vehicle shape.
List<ServiceItemSeed> _seed({
  VehicleType type = VehicleType.car,
  FuelKind fuel = FuelKind.petrol,
  bool isBusiness = false,
  DistanceUnit unit = DistanceUnit.km,
}) => seedFor(type: type, fuel: fuel, isBusiness: isBusiness, unit: unit);

/// The seed for [kind], or null when it is not seeded at all.
ServiceItemSeed? _find(List<ServiceItemSeed> seeds, ServiceKind kind) {
  for (final seed in seeds) {
    if (seed.kind == kind) return seed;
  }
  return null;
}

Set<ServiceKind> _kinds(List<ServiceItemSeed> seeds) =>
    seeds.map((s) => s.kind).toSet();

Set<ServiceKind> _tracked(List<ServiceItemSeed> seeds) =>
    seeds.where((s) => s.isTracked).map((s) => s.kind).toSet();

void main() {
  group('the car set', () {
    test('seeds seven tracked items and nine untracked ones', () {
      final seeds = _seed();

      expect(_tracked(seeds), {
        ServiceKind.oilAndFilter,
        ServiceKind.brakePadsCheck,
        ServiceKind.tyreReplace,
        ServiceKind.airFilter,
        ServiceKind.coolant,
        ServiceKind.inspection,
        ServiceKind.insuranceRenewal,
      });
      expect(seeds.where((s) => !s.isTracked), hasLength(9));
    });

    test('every seeded item leaves the label null', () {
      // The label is rendered FROM the kind, so a vehicle seeded in English
      // reads correctly in all six languages with no migration. A stored
      // English string would need one.
      for (final seed in _seed()) {
        expect(seed.label, isNull, reason: seed.kind.wire);
        expect(seed.kind, isNot(ServiceKind.custom), reason: seed.kind.wire);
      }
    });

    test('the seeded-off rows carry is_tracked false', () {
      // §4.8.2: the row exists, reads greyed on `reminders.list`, and is
      // invisible to the due engine until the user enables it. Created rather
      // than omitted because timing belt is the most expensive thing to miss,
      // and a disabled row with an honest note gets a user to look it up.
      final seeds = _seed();
      for (final kind in [
        ServiceKind.timingBelt,
        ServiceKind.tyreRotate,
        ServiceKind.cabinFilter,
        ServiceKind.brakeFluid,
        ServiceKind.sparkPlugs,
        ServiceKind.transmissionFluid,
        ServiceKind.battery,
        ServiceKind.wipers,
        ServiceKind.registration,
      ]) {
        expect(_find(seeds, kind)?.isTracked, isFalse, reason: kind.wire);
      }
    });

    test("§4.8.1's intervals, to the metre and the month", () {
      final seeds = _seed();

      void check(ServiceKind kind, int? metres, int? months) {
        final seed = _find(seeds, kind)!;
        expect(seed.intervalDistanceM, metres, reason: '${kind.wire} distance');
        expect(seed.intervalMonths, months, reason: '${kind.wire} months');
      }

      check(ServiceKind.oilAndFilter, 10000000, 12);
      check(ServiceKind.brakePadsCheck, 20000000, 12);
      check(ServiceKind.tyreReplace, 50000000, 72);
      check(ServiceKind.airFilter, 20000000, 24);
      check(ServiceKind.coolant, 60000000, 48);
      // No distance interval at all — an inspection is a date.
      check(ServiceKind.inspection, null, 12);
      check(ServiceKind.insuranceRenewal, null, 12);
    });

    test("§4.8.2's intervals", () {
      final seeds = _seed();

      void check(ServiceKind kind, int? metres, int? months) {
        final seed = _find(seeds, kind)!;
        expect(seed.intervalDistanceM, metres, reason: '${kind.wire} distance');
        expect(seed.intervalMonths, months, reason: '${kind.wire} months');
      }

      check(ServiceKind.timingBelt, 100000000, 96);
      check(ServiceKind.tyreRotate, 10000000, 12);
      check(ServiceKind.cabinFilter, 20000000, 12);
      check(ServiceKind.brakeFluid, 60000000, 24);
      check(ServiceKind.sparkPlugs, 40000000, 48);
      check(ServiceKind.transmissionFluid, 60000000, 60);
      check(ServiceKind.battery, null, 48);
      check(ServiceKind.wipers, null, 12);
      check(ServiceKind.registration, null, 12);
    });

    test('priorities are the spec\'s, not a guess', () {
      final seeds = _seed();
      for (final (kind, priority) in [
        (ServiceKind.oilAndFilter, ServicePriority.safety),
        (ServiceKind.brakePadsCheck, ServicePriority.safety),
        (ServiceKind.tyreReplace, ServicePriority.safety),
        (ServiceKind.airFilter, ServicePriority.normal),
        (ServiceKind.coolant, ServicePriority.normal),
        (ServiceKind.inspection, ServicePriority.safety),
        (ServiceKind.insuranceRenewal, ServicePriority.normal),
        (ServiceKind.timingBelt, ServicePriority.safety),
        (ServiceKind.cabinFilter, ServicePriority.low),
        (ServiceKind.brakeFluid, ServicePriority.safety),
        (ServiceKind.wipers, ServicePriority.low),
      ]) {
        expect(_find(seeds, kind)?.priority, priority, reason: kind.wire);
      }
    });

    test('the three date-anchored kinds roll over from_due', () {
      // An inspection due in March that is done in April is next due the
      // following MARCH, not the following April — the schedule belongs to the
      // authority, not to when the user got round to it. Everything else rolls
      // from what actually happened.
      final seeds = _seed();
      for (final seed in seeds) {
        final expected = const {
              ServiceKind.inspection,
              ServiceKind.insuranceRenewal,
              ServiceKind.registration,
            }.contains(seed.kind)
            ? ServiceRollover.fromDue
            : ServiceRollover.fromActual;
        expect(seed.rollover, expected, reason: seed.kind.wire);
      }
    });
  });

  group('miles', () {
    test('seeds 6,000 mi rather than 10,000 km rendered as 6,214', () {
      // §4.8: "Defaults are defined per unit system, not converted." A miles
      // user gets a round number in their own unit — the alternative is an oil
      // change every 6,213.7 miles, which reads as a machine talking.
      final seeds = _seed(unit: DistanceUnit.mi);

      expect(_find(seeds, ServiceKind.oilAndFilter)!.intervalDistanceM, 9656064);
      expect(_find(seeds, ServiceKind.tyreReplace)!.intervalDistanceM, 48280320);
    });

    test('and the months do not change with the unit', () {
      final km = _seed();
      final mi = _seed(unit: DistanceUnit.mi);
      for (final seed in km) {
        expect(
          _find(mi, seed.kind)?.intervalMonths,
          seed.intervalMonths,
          reason: seed.kind.wire,
        );
      }
    });
  });

  group('electric', () {
    test('seeds no combustion-engine maintenance', () {
      final kinds = _kinds(_seed(fuel: FuelKind.electric));
      for (final kind in [
        ServiceKind.oilAndFilter,
        ServiceKind.airFilter,
        ServiceKind.sparkPlugs,
        ServiceKind.transmissionFluid,
        ServiceKind.timingBelt,
        ServiceKind.coolant,
      ]) {
        expect(kinds, isNot(contains(kind)), reason: kind.wire);
      }
    });

    test('seeds battery_12v and never battery, and never both', () {
      // §4.8.3 settles it: on an electric vehicle "the battery" otherwise reads
      // as the traction pack, which Odova does not track.
      final kinds = _kinds(_seed(fuel: FuelKind.electric));
      expect(kinds, contains(ServiceKind.battery12v));
      expect(kinds, isNot(contains(ServiceKind.battery)));

      // And the other way on a petrol car.
      final petrol = _kinds(_seed());
      expect(petrol, contains(ServiceKind.battery));
      expect(petrol, isNot(contains(ServiceKind.battery12v)));
    });

    test('turns brake_fluid and cabin_filter ON, at 24 and 12 months', () {
      final seeds = _seed(fuel: FuelKind.electric);

      final brakeFluid = _find(seeds, ServiceKind.brakeFluid)!;
      expect(brakeFluid.isTracked, isTrue);
      expect(brakeFluid.intervalMonths, 24);

      final cabin = _find(seeds, ServiceKind.cabinFilter)!;
      expect(cabin.isTracked, isTrue);
      expect(cabin.intervalMonths, 12);
    });

    test('adds reduction_gearbox_oil, off', () {
      final seed = _find(
        _seed(fuel: FuelKind.electric),
        ServiceKind.reductionGearboxOil,
      )!;
      expect(seed.isTracked, isFalse);
      expect(seed.intervalDistanceM, 100000000);
      expect(seed.priority, ServicePriority.normal);
    });
  });

  group('motorcycle', () {
    test('seeds oil_and_filter at 6,000 km and chain_lube on at 800 km', () {
      final seeds = _seed(type: VehicleType.motorcycle);

      expect(_find(seeds, ServiceKind.oilAndFilter)!.intervalDistanceM, 6000000);
      final chain = _find(seeds, ServiceKind.chainLube)!;
      expect(chain.isTracked, isTrue);
      expect(chain.intervalDistanceM, 800000);
      expect(chain.intervalMonths, isNull);
      expect(chain.priority, ServicePriority.low);
    });

    test('drops the seven kinds a motorcycle does not have', () {
      final kinds = _kinds(_seed(type: VehicleType.motorcycle));
      for (final kind in [
        ServiceKind.cabinFilter,
        ServiceKind.tyreRotate,
        ServiceKind.wipers,
        ServiceKind.transmissionFluid,
        ServiceKind.timingBelt,
        ServiceKind.battery,
        ServiceKind.battery12v,
      ]) {
        expect(kinds, isNot(contains(kind)), reason: kind.wire);
      }
    });

    test('adds its three off rows', () {
      final seeds = _seed(type: VehicleType.motorcycle);
      for (final (kind, metres) in [
        (ServiceKind.chainAndSprockets, 25000000),
        (ServiceKind.valveClearance, 25000000),
        (ServiceKind.forkOil, 30000000),
      ]) {
        final seed = _find(seeds, kind)!;
        expect(seed.isTracked, isFalse, reason: kind.wire);
        expect(seed.intervalDistanceM, metres, reason: kind.wire);
        expect(seed.priority, ServicePriority.normal, reason: kind.wire);
      }
    });

    test('seeds coolant on liquid-cooled and never on air-cooled', () {
      // The one place `FuelKind` is not what decides. Odova has no cooling
      // field, so the seeder takes it as an argument and first run asks.
      expect(
        _kinds(
          seedFor(
            type: VehicleType.motorcycle,
            fuel: FuelKind.petrol,
            isBusiness: false,
            unit: DistanceUnit.km,
            liquidCooled: true,
          ),
        ),
        contains(ServiceKind.coolant),
      );
      expect(
        _kinds(_seed(type: VehicleType.motorcycle)),
        isNot(contains(ServiceKind.coolant)),
      );
    });
  });

  group('van', () {
    test('seeds oil_and_filter at 15,000 km and tyre_replace at 40,000', () {
      final seeds = _seed(type: VehicleType.van);
      expect(_find(seeds, ServiceKind.oilAndFilter)!.intervalDistanceM, 15000000);
      expect(_find(seeds, ServiceKind.tyreReplace)!.intervalDistanceM, 40000000);
    });
  });

  group('business use', () {
    test('shortens oil and air filter and turns tyre rotation on', () {
      final seeds = _seed(isBusiness: true);

      final oil = _find(seeds, ServiceKind.oilAndFilter)!;
      expect(oil.intervalDistanceM, 7500000);
      expect(oil.intervalMonths, 6);
      expect(_find(seeds, ServiceKind.airFilter)!.intervalDistanceM, 15000000);
      expect(_find(seeds, ServiceKind.tyreRotate)!.isTracked, isTrue);
    });
  });

  group('the filters compose', () {
    test('an electric motorcycle takes motorcycle then electric', () {
      // §4.8.3: "electric is a fuel kind, not a vehicle type, so the two
      // filters compose". In that order — the motorcycle pass drops
      // `battery_12v`, and the electric pass must not add it back.
      final kinds = _kinds(
        _seed(type: VehicleType.motorcycle, fuel: FuelKind.electric),
      );

      expect(kinds, isNot(contains(ServiceKind.oilAndFilter)));
      expect(kinds, isNot(contains(ServiceKind.battery12v)));
      expect(kinds, isNot(contains(ServiceKind.cabinFilter)));
      expect(kinds, contains(ServiceKind.chainLube));
      expect(kinds, contains(ServiceKind.brakeFluid));
    });
  });

  group('truck and other', () {
    test('take the car set unchanged', () {
      final car = _seed();
      for (final type in [VehicleType.truck, VehicleType.other]) {
        final seeds = _seed(type: type);
        expect(_kinds(seeds), _kinds(car), reason: type.wire);
        for (final seed in seeds) {
          final same = _find(car, seed.kind)!;
          expect(seed.intervalDistanceM, same.intervalDistanceM);
          expect(seed.intervalMonths, same.intervalMonths);
          expect(seed.isTracked, same.isTracked);
        }
      }
    });
  });

  group('the six never-seeded kinds', () {
    test('appear on no vehicle type, fuel or unit', () {
      // §4.8.5. They ship in the catalogue PICKER for every vehicle type, so a
      // user can add them in one tap — but a wrong default is worse than no
      // default, and `fuel_filter` varies by an order of magnitude between
      // petrol and diesel.
      const never = {
        ServiceKind.fuelFilter,
        ServiceKind.wheelAlignment,
        ServiceKind.acService,
        ServiceKind.brakePadsFront,
        ServiceKind.brakePadsRear,
        ServiceKind.custom,
      };

      for (final type in VehicleType.values) {
        for (final fuel in FuelKind.values) {
          for (final business in [false, true]) {
            final kinds = _kinds(
              _seed(type: type, fuel: fuel, isBusiness: business),
            );
            expect(
              kinds.intersection(never),
              isEmpty,
              reason: '${type.wire}/${fuel.wire}/business=$business',
            );
          }
        }
      }
    });
  });

  test('the catalogue accounts for all 28 ServiceKind values', () {
    // §4.8.5 states this as an invariant, so it is a test rather than a
    // comment: 7 on + 9 off + 6 introduced by a variant + 6 never = 28. A
    // twenty-ninth kind added to the enum without a decision here fails.
    const never = {
      ServiceKind.fuelFilter,
      ServiceKind.wheelAlignment,
      ServiceKind.acService,
      ServiceKind.brakePadsFront,
      ServiceKind.brakePadsRear,
      ServiceKind.custom,
    };

    final seeded = <ServiceKind>{};
    for (final type in VehicleType.values) {
      for (final fuel in FuelKind.values) {
        for (final cooled in [false, true]) {
          seeded.addAll(
            _kinds(
              seedFor(
                type: type,
                fuel: fuel,
                isBusiness: false,
                unit: DistanceUnit.km,
                liquidCooled: cooled,
              ),
            ),
          );
        }
      }
    }

    expect(ServiceKind.values, hasLength(28));
    expect(seeded.union(never), ServiceKind.values.toSet());
    expect(seeded.intersection(never), isEmpty);
    // 16 on the car set, plus the six a variant introduces.
    expect(seeded, hasLength(22));
  });
}
