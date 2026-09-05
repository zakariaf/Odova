// The garage: creating a vehicle, deleting one, and counting what would go
// with it.
//
// SPEC.md §8 and §14. Two claims here are worth more than the rest, because
// both fail silently. `create` is one transaction — a vehicle with no odometer
// reading is forbidden by §3, so a half-succeeded create leaves a record the
// app cannot render and the user cannot fix. And `entryCounts` is what the
// delete dialog states out loud before destroying eight years of history, so a
// count that is quietly low understates what the user is agreeing to.
@TestOn('vm')
library;

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/vehicles/annual_band.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';

import '../../support/values.dart';
import '../support/rows.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';

/// A draft with everything first run collects and nothing more.
VehicleDraft _draft({
  String name = 'The Golf',
  VehicleType type = VehicleType.car,
  FuelKind fuel = FuelKind.diesel,
  bool isBusiness = false,
  int odometerMetres = 187412000,
  DistanceUnit unit = DistanceUnit.km,
  AnnualBand band = AnnualBand.defaultBand,
}) => VehicleDraft(
  name: name,
  vehicleType: type,
  fuelKindDefault: fuel,
  isBusiness: isBusiness,
  odometer: Distance(odometerMetres),
  odometerUnit: unit,
  occurredOn: '2026-09-04',
  distanceUnit: unit,
  expectedAnnual: Distance(band.metresFor(unit)),
);

Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS n FROM $table;')
      .getSingle();
  return row.read<int>('n');
}

void main() {
  late AppDatabase db;
  late VehicleRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = VehicleRepository(
      db,
      // A fixed clock and a seeded Random: the ids are then reproducible, so a
      // failing test names the same vehicle every run.
      testUlids(),
    );
    addTearDown(db.close);
  });

  group('create', () {
    test('writes the vehicle, its first reading and its seeds together', () {
      // §3 forbids a vehicle with no odometer reading, and §4.8 says the
      // catalogue is copied at creation. All three in one transaction, so the
      // app can never render a vehicle it cannot compute a due state for.
      return expectLater(
        repository.create(_draft(), nowUtcMs: 1000).then((result) async {
          expect(result, isA<Ok<Vehicle, PersistFailure>>());

          expect(await _count(db, 'vehicles'), 1);
          expect(await _count(db, 'odometer_readings'), 1);
          // 15, not 16: the default draft is DIESEL, and §4.8.2 seeds spark
          // plugs on petrol, LPG, CNG and hybrid only. A diesel gets no row it
          // would have to work out is irrelevant.
          expect(await _count(db, 'service_items'), 15);

          final reading = await db
              .customSelect('SELECT * FROM odometer_readings;')
              .getSingle();
          expect(reading.read<int>('odometer_m'), 187412000);
          expect(reading.read<String>('source'), OdometerSource.manual.wire);
          return true;
        }),
        completion(isTrue),
      );
    });

    test('a petrol car gets the sixteenth row a diesel does not', () async {
      await repository.create(_draft(fuel: FuelKind.petrol), nowUtcMs: 1000);

      expect(await _count(db, 'service_items'), 16);
      final kinds =
          (await db.customSelect('SELECT kind FROM service_items;').get())
              .map((r) => r.read<String>('kind'))
              .toSet();
      expect(kinds, contains(ServiceKind.sparkPlugs.wire));
    });

    test('mints a veh_ id and a matching odo_ id', () async {
      final created = await repository.create(_draft(), nowUtcMs: 1000);
      final vehicle = (created as Ok<Vehicle, PersistFailure>).value;

      expect(vehicle.id.toString(), startsWith('veh_'));
      final reading = await db
          .customSelect('SELECT * FROM odometer_readings;')
          .getSingle();
      expect(reading.read<String>('id'), startsWith('odo_'));
      expect(reading.read<String>('vehicle_id'), vehicle.id.toString());
    });

    test('a rejected reading rolls the vehicle back', () async {
      // The all-or-nothing rule, forced through the SCHEMA rather than a
      // stubbed failure: a negative odometer violates the table's CHECK, so
      // the insert throws inside the transaction exactly as a disk error would.
      final result = await repository.create(
        _draft(odometerMetres: -1),
        nowUtcMs: 1000,
      );

      expect(result, isA<Err<Vehicle, PersistFailure>>());
      expect(await _count(db, 'vehicles'), 0);
      expect(await _count(db, 'odometer_readings'), 0);
      expect(await _count(db, 'service_items'), 0);
    });

    test('seeds what the draft describes, not what a car would get', () async {
      await repository.create(
        _draft(type: VehicleType.motorcycle, fuel: FuelKind.petrol),
        nowUtcMs: 1000,
      );

      final kinds =
          (await db.customSelect('SELECT kind FROM service_items;').get())
              .map((r) => r.read<String>('kind'))
              .toSet();

      expect(kinds, contains(ServiceKind.chainLube.wire));
      expect(kinds, isNot(contains(ServiceKind.cabinFilter.wire)));
    });

    test('a seeded item carries no label and a real kind', () async {
      // §4.8: the label is rendered FROM the kind, so a vehicle seeded in
      // English reads correctly in all six languages with no migration.
      await repository.create(_draft(), nowUtcMs: 1000);

      final rows = await db
          .customSelect('SELECT label, kind FROM service_items;')
          .get();
      for (final row in rows) {
        expect(row.read<String?>('label'), isNull);
        expect(row.read<String>('kind'), isNot(ServiceKind.custom.wire));
      }
    });
  });

  group('entryCounts', () {
    test('returns the five numbers the delete dialog names', () async {
      await insertVehicle(db, id: _golf);
      await insertServiceItem(db, vehicleId: _golf);
      await insertFillUp(db, vehicleId: _golf);
      await insertServiceRecord(db, vehicleId: _golf);
      await insertExpense(db, vehicleId: _golf);
      await insertTrip(db, vehicleId: _golf);

      final counts = await repository.entryCounts(VehicleId.tryParse(_golf)!);

      expect(counts, isA<Ok<DeleteCounts, PersistFailure>>());
      final value = (counts as Ok<DeleteCounts, PersistFailure>).value;
      expect(value.fillUps, 1);
      expect(value.services, 1);
      expect(value.costs, 1);
      expect(value.trips, 1);
      expect(value.reminders, 1);
    });

    test('a just-created vehicle has reminders but no entries', () async {
      // The end of SPEC.md §8's "Zero entries: one-tap Delete", from the only
      // place it can be proved: a REAL create, with the seeded set §4.8.3 puts
      // on every vehicle. If reminders were entries this number could never be
      // zero, and the rule would have no reachable case — a car added by
      // mistake would demand its own name typed back to remove it (F-9.26).
      final created = await repository.create(_draft(), nowUtcMs: 1000);
      final id = (created as Ok<Vehicle, PersistFailure>).value.id;

      final counts = await repository.entryCounts(id);
      final value = (counts as Ok<DeleteCounts, PersistFailure>).value;
      expect(value.reminders, greaterThan(0), reason: 'the seeded set');
      expect(value.total, 0, reason: 'the user has entered nothing');
    });

    test('counts only this vehicle', () async {
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertFillUp(db, vehicleId: _polo);

      final counts = await repository.entryCounts(VehicleId.tryParse(_golf)!);
      expect((counts as Ok<DeleteCounts, PersistFailure>).value.fillUps, 0);
    });

    test('excludes soft-deleted rows', () async {
      // A user who deleted a fill-up five minutes ago should not be told it is
      // about to go permanently — it already went.
      await insertVehicle(db, id: _golf);
      await insertFillUp(db, vehicleId: _golf);
      await db.customUpdate(
        'UPDATE fill_ups SET deleted_at_utc_ms = 2000;',
        updates: {db.fillUps},
      );

      final counts = await repository.entryCounts(VehicleId.tryParse(_golf)!);
      expect((counts as Ok<DeleteCounts, PersistFailure>).value.fillUps, 0);
    });
  });

  group('the garage list', () {
    test('excludes soft-deleted vehicles', () async {
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await db.customUpdate(
        'UPDATE vehicles SET deleted_at_utc_ms = 2000 WHERE id = ?;',
        variables: [const Variable<String>(_polo)],
        updates: {db.vehicles},
      );

      final garage = await repository.watchGarage().first;
      expect(garage.map((v) => v.id.toString()), [_golf]);
    });

    test('orders by sort_order, then by id', () async {
      // The id tiebreak is not decoration: two vehicles created in the same
      // millisecond otherwise swap places between reads, and a garage that
      // reorders itself on every rebuild is a garage nobody trusts.
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertVehicle(db, id: _golf);
      await db.customUpdate(
        'UPDATE vehicles SET sort_order = 5 WHERE id = ?;',
        variables: [const Variable<String>(_golf)],
        updates: {db.vehicles},
      );

      final garage = await repository.watchGarage().first;
      expect(garage.map((v) => v.id.toString()), [_polo, _golf]);
    });
  });

  group('reorder', () {
    test('writes sort_order in the order given', () async {
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');

      await repository.reorder([
        VehicleId.tryParse(_polo)!,
        VehicleId.tryParse(_golf)!,
      ]);

      final garage = await repository.watchGarage().first;
      expect(garage.map((v) => v.id.toString()), [_polo, _golf]);
    });

    test('is one transaction: a bad id writes nothing', () async {
      // The Golf starts at 5, so a HALF-applied reorder — which would write it
      // to 0 and then fail on the second id — is visible. Starting it at 0
      // made the half-applied case indistinguishable from the aborted one, and
      // removing the abort passed.
      await insertVehicle(db, id: _golf);
      await db.customUpdate(
        'UPDATE vehicles SET sort_order = 5 WHERE id = ?;',
        variables: [const Variable<String>(_golf)],
        updates: {db.vehicles},
      );

      final result = await repository.reorder([
        VehicleId.tryParse(_golf)!,
        VehicleId.tryParse(_polo)!, // not in the garage
      ]);

      expect(result, isA<Err<void, PersistFailure>>());
      expect((await repository.watchGarage().first).single.sortOrder, 5);
    });
  });

  group('sold and archived', () {
    test(
      'markSold writes status, sold_on and sold_price and nothing else',
      () async {
        await insertVehicle(db, id: _golf);
        final before = await db
            .customSelect('SELECT * FROM vehicles;')
            .getSingle();

        await repository.markSold(
          VehicleId.tryParse(_golf)!,
          soldOn: '2026-09-04',
          soldPriceMinor: 850000,
          updatedAtUtcMs: 5000,
        );

        final after = await db
            .customSelect('SELECT * FROM vehicles;')
            .getSingle();
        expect(after.read<String>('status'), VehicleStatus.sold.wire);
        expect(after.read<String>('sold_on'), '2026-09-04');
        expect(after.read<int>('sold_price_minor'), 850000);
        // Everything else, unchanged.
        final changed = <String>{};
        for (final key in before.data.keys) {
          if (before.data[key] != after.data[key]) changed.add(key);
        }
        expect(changed, {
          'status',
          'sold_on',
          'sold_price_minor',
          'updated_at_utc_ms',
        });
      },
    );

    test('archive writes status and leaves sold_on null', () async {
      // Archived is not sold. A vehicle put away in a garage for the winter has
      // no sale date, and inventing one would put a price on the running-cost
      // total that nobody paid.
      await insertVehicle(db, id: _golf);

      await repository.archive(
        VehicleId.tryParse(_golf)!,
        updatedAtUtcMs: 5000,
      );

      final row = await db.customSelect('SELECT * FROM vehicles;').getSingle();
      expect(row.read<String>('status'), VehicleStatus.archived.wire);
      expect(row.read<String?>('sold_on'), isNull);
      expect(row.read<int?>('sold_price_minor'), isNull);
    });
  });

  test('every write returns a typed Result rather than throwing', () async {
    // The boundary rule. A repository that throws makes every caller a
    // try/catch, and the one caller that forgets loses the write silently.
    await db.customStatement('DROP TABLE vehicles;');
    await db.customStatement('DROP TABLE fill_ups;');

    expect(
      await repository.create(_draft(), nowUtcMs: 1000),
      isA<Err<Vehicle, PersistFailure>>(),
    );
    expect(
      await repository.entryCounts(VehicleId.tryParse(_golf)!),
      isA<Err<DeleteCounts, PersistFailure>>(),
    );
    expect(
      await repository.archive(VehicleId.tryParse(_golf)!, updatedAtUtcMs: 1),
      isA<Err<void, PersistFailure>>(),
    );
  });

  test('create stores the annual band the first-run screen chose', () async {
    // `expected_annual_m` is the projection's fallback until there is enough
    // odometer history to measure — SPEC.md §5's `assumed` rung. The draft
    // carried everything else first run collects and dropped this one on the
    // floor, so every vehicle was created with a null and every new car
    // projected at the global 12,000 km/yr default.
    final created = await repository.create(
      _draft(band: AnnualBand.higher),
      nowUtcMs: 1757000000000,
    );
    expect(created, isA<Ok<Vehicle, PersistFailure>>());

    final row =
        await (db.select(
              db.vehicles,
            )..where(
              (v) => v.id.equals(
                (created as Ok<Vehicle, PersistFailure>).value.id.toString(),
              ),
            ))
            .getSingle();
    expect(row.expectedAnnualM, AnnualBand.higher.metresFor(DistanceUnit.km));
  });

  test(
    'the band is read in the vehicle own unit, not the app default',
    () async {
      // A miles user picking "12–18" stores 24,140,160 m — the round MILE
      // number converted once — and not the kilometre band's 25,000,000. §4.8:
      // defined per unit system, not converted.
      final created =
          await repository.create(
                _draft(band: AnnualBand.higher, unit: DistanceUnit.mi),
                nowUtcMs: 1757000000000,
              )
              as Ok<Vehicle, PersistFailure>;

      final row = await (db.select(
        db.vehicles,
      )..where((v) => v.id.equals(created.value.id.toString()))).getSingle();
      expect(row.expectedAnnualM, AnnualBand.higher.metresFor(DistanceUnit.mi));
      expect(
        row.expectedAnnualM,
        isNot(AnnualBand.higher.metresFor(DistanceUnit.km)),
      );
    },
  );

  group('the first vehicle finishes onboarding, and later ones do not', () {
    test(
      'asFirstVehicle points active_vehicle_id at it and sets the flag',
      () async {
        // SPEC.md §8's Data out, fourth line:
        // `UPDATE Settings { active_vehicle_id, onboarding_done: true }`, in
        // the SAME transaction as the vehicle, the reading and the seeded
        // items. It was missing entirely, so first run created a car and then
        // sent the user back to the first-run screen forever.
        await insertSettings(db);

        final created =
            await repository.create(
                  _draft(),
                  nowUtcMs: 1757000000000,
                  asFirstVehicle: true,
                )
                as Ok<Vehicle, PersistFailure>;

        final settings = await db.select(db.settingsTable).getSingle();
        expect(settings.onboardingDone, isTrue);
        expect(settings.activeVehicleId, created.value.id.toString());
        expect(settings.updatedAtUtcMs, 1757000000000);
      },
    );

    test('an ordinary create touches Settings not at all', () async {
      // Task 9.6: "add from the vehicles + appends the vehicle, does not make
      // it active". A second car must never steal the active slot from the one
      // the user is looking at.
      await insertSettings(
        db,
        activeVehicleId: 'veh_existing',
        onboardingDone: true,
      );

      await repository.create(_draft(), nowUtcMs: 1757000000000);

      final settings = await db.select(db.settingsTable).getSingle();
      expect(settings.activeVehicleId, 'veh_existing');
      expect(settings.updatedAtUtcMs, 1000, reason: 'the row was not touched');
    });

    test('no settings row unwinds the whole create', () async {
      // Production cannot reach this: the vehicle step is entered either from
      // `firstrun.language`'s Continue, which writes the settings row, or from
      // a launch with `onboarding_done` already true, which implies one. So it
      // is a routing bug, and the honest answer is to unwind rather than to
      // invent a `currency_default` this layer has no basis for — a repository
      // has no locale and no device region.
      final created = await repository.create(
        _draft(),
        nowUtcMs: 1757000000000,
        asFirstVehicle: true,
      );
      expect(created, isA<Err<Vehicle, PersistFailure>>());

      // All or nothing: no orphan vehicle, no orphan reading, no orphan items.
      expect(await db.select(db.vehicles).get(), isEmpty);
      expect(await db.select(db.odometerReadings).get(), isEmpty);
      expect(await db.select(db.serviceItems).get(), isEmpty);
    });
  });
}
