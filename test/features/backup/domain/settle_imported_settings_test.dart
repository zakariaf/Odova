// The three settings the FILE does not get the last word on — SPEC.md §6 §4.2.
@TestOn('vm')
library;

import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/features/backup/domain/settle_imported_settings.dart';
import 'package:test/test.dart';

final Currency _irr = Currency.tryParse('IRR')!;
final VehicleId _a = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD')!;
final VehicleId _b = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVE')!;
final VehicleId _gone = VehicleId.tryParse('veh_01JQ8ZK3M7F0R6XN2E9TB4HCVF')!;

Vehicle _vehicle(VehicleId id, {int sortOrder = 0}) => Vehicle(
  id: id,
  name: 'Vehicle',
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  sortOrder: sortOrder,
  createdAtUtcMs: 0,
  updatedAtUtcMs: 0,
);

StoreSnapshot _store({
  List<Vehicle> vehicles = const [],
  AppSettings? settings,
}) => StoreSnapshot(
  settings:
      settings ??
      AppSettings(
        schemaVersion: 1,
        currencyDefault: _irr,
        createdAtUtcMs: 0,
        updatedAtUtcMs: 0,
      ),
  vehicles: vehicles,
);

void main() {
  test("the file's active vehicle is kept when the file contains it", () {
    final settled = settleImportedSettings(
      _store(vehicles: [_vehicle(_a), _vehicle(_b, sortOrder: 1)]),
      preferred: _b,
    );

    expect(settled.activeVehicle, _b);
  });

  test('the settings row itself carries no active vehicle', () {
    // It travels beside the snapshot instead, so the importer applies it
    // through `setActiveVehicle` and the tab stack resets — the stack after an
    // import holds routes for a car that may no longer exist.
    final settled = settleImportedSettings(
      _store(vehicles: [_vehicle(_a)]),
      preferred: _a,
    );

    expect(settled.store.settings.activeVehicleId, isNull);
    expect(settled.activeVehicle, _a);
  });

  test('an active vehicle the file does not contain promotes the first', () {
    // Null would be a garage that opens on nothing, and §7 has no such state.
    final settled = settleImportedSettings(
      _store(
        vehicles: [_vehicle(_b, sortOrder: 3), _vehicle(_a, sortOrder: 1)],
      ),
      preferred: _gone,
    );

    expect(settled.activeVehicle, _a);
  });

  test('a tie on sort order breaks by id, so every device agrees', () {
    // Two vehicles at sort order 0 is the ordinary state of a file written
    // before anyone reordered a garage. A tie broken by list position would
    // promote a different vehicle depending on which array order the writer
    // happened to use.
    final one = settleImportedSettings(
      _store(vehicles: [_vehicle(_a), _vehicle(_b)]),
      preferred: _gone,
    );
    final other = settleImportedSettings(
      _store(vehicles: [_vehicle(_b), _vehicle(_a)]),
      preferred: _gone,
    );

    expect(one.activeVehicle, other.activeVehicle);
    expect(one.activeVehicle, _a);
  });

  test('an empty file leaves no active vehicle', () {
    final settled = settleImportedSettings(_store(), preferred: _a);

    expect(settled.activeVehicle, isNull);
  });

  test('onboarding_done is set true and never read from the file', () {
    final settled = settleImportedSettings(
      _store(
        vehicles: [_vehicle(_a)],
        settings: AppSettings(
          schemaVersion: 1,
          currencyDefault: _irr,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
        ),
      ),
      preferred: _a,
    );

    // A restored phone has data on it, so the first-run flow is finished by
    // definition — and a file written before onboarding existed would
    // otherwise send the user back through it.
    expect(settled.store.settings.onboardingDone, isTrue);
  });

  test('every preference in the file survives', () {
    // Restoring onto a new phone gives back the app you had, not a German one
    // on a German handset.
    final settled = settleImportedSettings(
      _store(
        vehicles: [_vehicle(_a)],
        settings: AppSettings(
          schemaVersion: 1,
          currencyDefault: _irr,
          createdAtUtcMs: 0,
          updatedAtUtcMs: 0,
          language: 'fa',
          calendar: 'jalali',
          numerals: 'extended_arabic_indic',
          firstDayOfWeek: DateTime.saturday,
          theme: 'dark',
          currencyDisplay: 'toman',
          distanceUnit: DistanceUnit.mi,
          notificationTimeMinutes: 7 * 60 + 30,
          weekdaysOnly: true,
          notifyOdometer: false,
          noticeDistance: const Distance(500_000),
        ),
      ),
      preferred: _a,
    );

    final s = settled.store.settings;
    expect(s.language, 'fa');
    expect(s.calendar, 'jalali');
    expect(s.numerals, 'extended_arabic_indic');
    expect(s.firstDayOfWeek, DateTime.saturday);
    expect(s.theme, 'dark');
    expect(s.currencyDisplay, 'toman');
    expect(s.distanceUnit, DistanceUnit.mi);
    expect(s.notificationTimeMinutes, 7 * 60 + 30);
    expect(s.weekdaysOnly, isTrue);
    expect(s.notifyOdometer, isFalse);
    expect(s.noticeDistance, const Distance(500_000));
    expect(s.currencyDefault, _irr);
  });
}
