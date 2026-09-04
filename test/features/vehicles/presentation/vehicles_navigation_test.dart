// Where the garage's taps go.
//
// SPEC.md §8's interaction table, and the one rule the whole screen is shaped
// around: "Tap a row → `vehicle.edit`, edit mode. **Never switches the active
// vehicle.**" The caption at the top of the screen says so in words; this says
// so in a test.
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicle_edit_screen.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/ui/calm/calm_scaffold.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../data/support/rows.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';

Future<AppDatabase> _db() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await insertSettings(db, activeVehicleId: _golf);
  await insertVehicle(db, id: _golf);
  await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);
  return db;
}

Future<String?> _activeVehicle(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT active_vehicle_id AS v FROM settings;')
      .getSingle();
  return row.read<String?>('v');
}

void main() {
  testWidgets('tapping a row opens vehicle.edit and switches nothing', (
    tester,
  ) async {
    // The mistake this screen refuses to make. A garage is exactly where
    // somebody expects to pick a car, and picking one here would change what
    // every other tab is showing without saying so.
    final db = await _db();
    addTearDown(db.close);

    await pumpShell(
      tester,
      Routes.vehicles,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20)),
        ),
      ],
    );
    expect(find.byType(VehiclesScreen), findsOneWidget);

    await tester.tap(find.text('The Polo'));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleEditScreen), findsOneWidget);
    expect(
      await _activeVehicle(db),
      _golf,
      reason: 'the garage never switches the active vehicle',
    );
  });

  testWidgets('the + opens the editor in CREATE mode, with no vehicle', (
    tester,
  ) async {
    // §8: "**+** in the app bar → `vehicle.edit`, create mode." The route
    // carries the sentinel id, which the screen reads as a null `VehicleId` —
    // a vehicle that is not there yet, drawn by the same code that draws one
    // that is gone.
    final db = await _db();
    addTearDown(db.close);

    await pumpShell(
      tester,
      Routes.vehicles,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20)),
        ),
      ],
    );

    // The APP BAR's +, not the tab bar's FAB. Both are `Icons.add` and they do
    // entirely different things — one adds a vehicle, the other opens the log
    // form — which is worth a finder that says which.
    await tester.tap(
      find.descendant(
        of: find.byType(CalmAppBar),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<VehicleEditScreen>(find.byType(VehicleEditScreen))
          .vehicleId,
      isNull,
    );
    expect(
      await _activeVehicle(db),
      _golf,
      reason: 'adding a vehicle does not switch to it either',
    );
  });
}
