// `firstrun.vehicle`'s draft: the one validation, the type rules, and the one
// transaction.
//
// SPEC.md §8's four states live here rather than in the widget, because they
// are decisions about a number and not about a pixel — and because the same
// number arrives through six numbering systems.
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/features/first_run/first_run_vehicle_notifier.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../support/provider_harness.dart';

DatabaseHarness _harness({String device = 'en-GB'}) {
  final parts = device.split('-');
  return containerWithDatabase(
    overrides: [
      deviceLocalesProvider.overrideWithValue([
        Locale(parts.first, parts.length > 1 ? parts[1] : null),
      ]),
      clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
    ],
  );
}

FirstRunVehicleNotifier _notifier(DatabaseHarness h) =>
    h.container.read(firstRunVehicleProvider.notifier);

FirstRunVehicleDraft _draft(DatabaseHarness h) =>
    h.container.read(firstRunVehicleProvider);

void main() {
  group('the odometer, which is the only thing that can be wrong', () {
    test('Start is disabled until it parses, and zero counts', () async {
      final h = _harness();
      final n = _notifier(h);

      // Empty is the entry state, and SPEC.md §8 gives it its own message
      // rather than the generic one: nothing has been typed, so "that doesn't
      // look like a number" would be a lie about what the user did.
      expect(_draft(h).canStart, isFalse);
      expect(_draft(h).problem, OdometerProblem.empty);

      n.typeOdometer('nonsense');
      expect(_draft(h).problem, OdometerProblem.notANumber);
      expect(_draft(h).canStart, isFalse);

      // Zero is allowed. New cars exist, and a delivered car reads 0 or 12.
      n.typeOdometer('0');
      expect(_draft(h).problem, isNull);
      expect(_draft(h).canStart, isTrue);
      expect(_draft(h).odometerMetres, 0);
    });

    test('a fraction is refused rather than guessed at', () async {
      // The German "1,234" is one-point-two-three-four, not one thousand two
      // hundred and thirty-four, and an odometer has no decimals. Guessing the
      // separator the other way round would silently store a car with 1 km on
      // it — and every projection from then on would be nonsense.
      final h = _harness(device: 'de-DE');
      final n = _notifier(h)..typeOdometer('1,234');
      expect(_draft(h).problem, OdometerProblem.notANumber);
      expect(_draft(h).odometerMetres, isNull);

      // The same digits with the German GROUPING separator are a real reading.
      n.typeOdometer('1.234');
      expect(_draft(h).problem, isNull);
      expect(_draft(h).odometerMetres, 1234000);
    });

    test('Extended Arabic-Indic digits read as the number they are', () async {
      // SPEC.md §5: the field accepts every numbering system the app supports.
      // An Iranian user types ۱۸۷۴۱۲ and means 187,412 — the same reading a
      // German user types as 187.412.
      final h = _harness(device: 'fa-IR');
      _notifier(h).typeOdometer('۱۸۷۴۱۲');
      expect(_draft(h).odometerMetres, const Distance.fromKm(187412).metres);
      expect(_draft(h).problem, isNull);
    });

    test(
      'an implausible reading warns, and Use it anyway accepts it',
      () async {
        // SPEC.md §8: above three million km, "That's higher than any car has
        // driven. Check the number." — a warning with an affordance, NEVER a
        // block. The one thing worse than a wrong odometer is a user who cannot
        // enter their real one.
        final h = _harness();
        final n = _notifier(h)..typeOdometer('3000001');
        expect(_draft(h).problem, OdometerProblem.implausible);
        expect(_draft(h).canStart, isFalse);

        n.useItAnyway();
        expect(_draft(h).problem, isNull);
        expect(_draft(h).canStart, isTrue);
      },
    );

    test('a new number is a new question, so the warning does not carry', () {
      // Accepting 3,000,001 must not silently accept the 300,000,001 typed
      // after it — the second is a different mistake and deserves its own ask.
      final h = _harness();
      _notifier(h)
        ..typeOdometer('3000001')
        ..useItAnyway();
      expect(_draft(h).problem, isNull, reason: 'the first one was accepted');

      _notifier(h).typeOdometer('300000001');
      expect(_draft(h).problem, OdometerProblem.implausible);
    });

    test('the reading is read in the unit the field is showing', () {
      // A British device types miles. 187,412 MILES is 301,608,... m, not the
      // 187,412,000 the same digits mean in kilometres — off by a factor of
      // 1.6, which is a decade of driving.
      final gb = _harness();
      _notifier(gb).typeOdometer('187412');
      expect(_draft(gb).unit, DistanceUnit.mi);
      expect(
        _draft(gb).odometerMetres,
        const Distance.fromMiles(187412).metres,
      );

      final de = _harness(device: 'de-DE');
      _notifier(de).typeOdometer('187412');
      expect(_draft(de).unit, DistanceUnit.km);
      expect(_draft(de).odometerMetres, const Distance.fromKm(187412).metres);
    });
  });

  group('the type tile', () {
    test('a van turns is_business on and the others leave it off', () async {
      // EPIC-09 F-9.9 dropped the switch from this screen; the DATA rule
      // survives it. SPEC.md §8's field table: "off; **on** when type = van".
      for (final (type, business) in [
        (VehicleType.car, false),
        (VehicleType.motorcycle, false),
        (VehicleType.van, true),
      ]) {
        final h = _harness();
        final n = _notifier(h)
          ..chooseType(type)
          ..rename('Whatever')
          ..typeOdometer('1000');
        expect(await n.save(), isTrue, reason: '$type');

        final row = await h.db.select(h.db.vehicles).getSingle();
        expect(row.vehicleType, type.wire, reason: '$type');
        expect(row.isBusiness, business, reason: '$type');
      }
    });
  });

  group('Save', () {
    test(
      'writes the vehicle, its reading and its seeded items at once',
      () async {
        final h = _harness(device: 'de-DE');
        final n = _notifier(h)
          ..chooseType(VehicleType.car)
          ..chooseFuel(FuelKind.diesel)
          ..chooseBand(AnnualBand.higher)
          ..rename('The Golf')
          ..typeOdometer('187412');

        expect(await n.save(), isTrue);

        final vehicle = await h.db.select(h.db.vehicles).getSingle();
        expect(vehicle.name, 'The Golf');
        expect(vehicle.fuelKindDefault, FuelKind.diesel.wire);
        expect(
          vehicle.expectedAnnualM,
          AnnualBand.higher.metresFor(DistanceUnit.km),
        );

        final reading = await h.db.select(h.db.odometerReadings).getSingle();
        expect(reading.odometerM, const Distance.fromKm(187412).metres);
        expect(reading.occurredOn, '2026-09-04');
        expect(reading.vehicleId, vehicle.id);

        // A diesel car seeds fifteen — the car set minus spark plugs, which are
        // a petrol job. Proven from task 9.2's catalogue rather than restated.
        final items = await h.db.select(h.db.serviceItems).get();
        expect(items, hasLength(15));
        expect(items.every((i) => i.vehicleId == vehicle.id), isTrue);
      },
    );

    test(
      'a second Save while the first is in flight writes one vehicle',
      () async {
        final h = _harness();
        final n = _notifier(h)
          ..rename('Once')
          ..typeOdometer('1000');

        await Future.wait([n.save(), n.save()]);
        expect(await h.db.select(h.db.vehicles).get(), hasLength(1));
      },
    );

    test('Save refuses while the odometer is unusable', () async {
      final h = _harness();
      final n = _notifier(h)..rename('No number');
      expect(await n.save(), isFalse);
      expect(await h.db.select(h.db.vehicles).get(), isEmpty);

      // And with an unaccepted warning, which is a value the user has not yet
      // stood behind.
      n.typeOdometer('9000000');
      expect(await n.save(), isFalse);
      expect(await h.db.select(h.db.vehicles).get(), isEmpty);
    });
  });

  test('nothing is written until Save', () async {
    // SPEC.md §8: "Backgrounded mid-entry — form state survives in memory;
    // nothing is written. A cold kill loses it and replays this screen — six
    // digits is an acceptable loss, a draft row for a vehicle that does not
    // exist is not."
    final h = _harness();
    _notifier(h)
      ..chooseType(VehicleType.van)
      ..chooseFuel(FuelKind.electric)
      ..chooseBand(AnnualBand.highest)
      ..rename('The Golf')
      ..typeOdometer('187412');

    expect(await h.db.select(h.db.vehicles).get(), isEmpty);
    expect(await h.db.select(h.db.odometerReadings).get(), isEmpty);
    expect(await h.db.select(h.db.serviceItems).get(), isEmpty);
  });
}
