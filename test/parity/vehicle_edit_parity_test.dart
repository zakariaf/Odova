// `vehicle.edit`, in all four combinations.
//
// The reference draws the TOP of the screen — EPIC-09's F-9.20: the artboard is
// a crop rather than a contradiction, and §8's prose is the full field list. So
// the capture is taken with both disclosure groups where the artboard has them,
// which is to say absent (F-9.23: their contents belong to EPIC-11 and
// EPIC-14, and a group that opens on nothing is a control that lies).
@Tags(['parity'])
library;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/features/vehicles/presentation/vehicle_edit_screen.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../data/support/rows.dart';
import 'support/parity_capture.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
final VehicleId _id = VehicleId.tryParse(_golf)!;

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('vehicle.edit ${config.theme}/${config.dir}', (tester) async {
      // A REAL database rather than an override of the edit provider: the row
      // is what the screen loads, and a fixture that skipped the load would
      // capture a screen the app cannot reach.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      // The artboard's own values, so the capture is the screen doing its job
      // rather than a screen with five empty boxes — the same reasoning as
      // F-9.14 for `firstrun.vehicle`.
      await insertVehicle(db, id: _golf, name: 'Golf');
      await db.customUpdate(
        'UPDATE vehicles SET make = ?, model = ?, year = ?, plate = ?, '
        'colour = ? WHERE id = ?;',
        variables: [
          const Variable<String>('VW'),
          const Variable<String>('Golf VII 1.6 TDI'),
          const Variable<int>(2016),
          const Variable<String>('M-AB 1234'),
          const Variable<String>('grey'),
          const Variable<String>(_golf),
        ],
        updates: {db.vehicles},
      );

      await captureParity(
        tester,
        screen: 'vehicle.edit',
        config: config,
        child: ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(
              Clock.fixed(DateTime.utc(2026, 9, 4)),
            ),
            // A continental phone showing whichever language the case asks
            // for, so the odometer reads in kilometres as the artboard draws.
            deviceLocalesProvider.overrideWithValue([
              Locale(config.locale.languageCode, 'DE'),
            ]),
            // Supplied, never streamed. A drift stream does not deliver inside
            // a widget test's fake async, and the capture would shoot a row
            // with no reading in it.
            odometerReadingsProvider(_id).overrideWith(
              (ref) => Stream.value([
                OdometerReading(
                  id: OdometerReadingId.tryParse(
                    'odo_01K1C4V2H9B8N3Q7ZE5RY6TMWY',
                  )!,
                  vehicleId: _id,
                  occurredOn: '2026-09-04',
                  odometer: const Distance.fromKm(187412),
                  odometerUnit: DistanceUnit.km,
                  source: OdometerSource.manual,
                  createdAtUtcMs: 1000,
                  updatedAtUtcMs: 1000,
                ),
              ]),
            ),
            // Supplied for the same reason. The name field reads the garage to
            // notice a duplicate name, and this capture's garage holds only
            // the car it is photographing.
            vehiclesProvider.overrideWith((ref) => const Stream.empty()),
            // And the settings, for the same reason: the annual-band field
            // reads the app's distance unit, and a live drift stream leaves a
            // pending timer this capture is torn down before.
            settingsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: VehicleEditScreen(vehicleId: _id),
        ),
      );
    });
  }
}
