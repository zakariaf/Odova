// `/settings/vehicles/:vehicleId` — what the path carries into the screen.
//
// EPIC-09 task 9.8 replaced this route's placeholder with the real
// `VehicleEditScreen`, which takes a PARSED `VehicleId` rather than the raw
// string the placeholder rendered. So `route_table_test`'s id-bearing loop can
// no longer assert it, and this file does instead — against the screen the user
// sees.
//
// The interesting case is the one a deep link makes possible and a tap never
// does: an id that will not parse. SPEC.md §7 says a bad link lands somewhere
// rather than nowhere.
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/features/vehicles/presentation/vehicle_edit_screen.dart';

import '../../data/support/rows.dart';
import 'shell_harness.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

void main() {
  testWidgets('the screen is handed the id the path carries', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await insertSettings(db, activeVehicleId: _golf);
    await insertVehicle(db, id: _golf);

    await pumpShell(
      tester,
      '/settings/vehicles/$_golf',
      liveStreams: true,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        // `clockProvider` throws until `bootstrap()` overrides it — the year
        // bound on the form reads it, and a test that pumps the real screen
        // has to supply what production injects.
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20)),
        ),
      ],
    );

    expect(
      tester
          .widget<VehicleEditScreen>(find.byType(VehicleEditScreen))
          .vehicleId,
      VehicleId.tryParse(_golf),
    );
  });

  testWidgets('an id that will not parse opens the screen, not a crash', (
    tester,
  ) async {
    // `/settings/vehicles/not-an-id` is a link somebody can send, and a
    // `tryParse` that returned into a non-nullable parameter would have thrown
    // in the route builder — a crash on a URL, which is the one thing a deep
    // link must never be able to do.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await insertSettings(db, activeVehicleId: _golf);
    await insertVehicle(db, id: _golf);

    await pumpShell(
      tester,
      '/settings/vehicles/not-an-id',
      liveStreams: true,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        // `clockProvider` throws until `bootstrap()` overrides it — the year
        // bound on the form reads it, and a test that pumps the real screen
        // has to supply what production injects.
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20)),
        ),
      ],
    );

    final screen = tester.widget<VehicleEditScreen>(
      find.byType(VehicleEditScreen),
    );
    expect(screen.vehicleId, isNull);
    // EDIT mode, and this is the assertion that separates the two null-id
    // cases: `tryParse` answers null for `not-an-id` and for the `new`
    // sentinel alike, and they must not draw the same screen.
    expect(screen.mode, VehicleEditMode.edit);
    // And it draws the shell a missing vehicle draws — a modal the user can
    // close, rather than a blank route with no way out.
    expect(find.text('Vehicle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the `new` sentinel opens CREATE mode, not that shell', (
    tester,
  ) async {
    // The other null-id case, and the one that shipped broken: `Routes
    // .vehicleNew` is `/settings/vehicles/new`, `VehicleId.tryParse('new')`
    // is null, and the router read it as a malformed link. Both doors marked
    // "+" opened an empty modal with a Save that called `() {}`.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await insertSettings(db, activeVehicleId: _golf);
    await insertVehicle(db, id: _golf);

    await pumpShell(
      tester,
      Routes.vehicleNew,
      liveStreams: true,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20)),
        ),
      ],
    );

    final screen = tester.widget<VehicleEditScreen>(
      find.byType(VehicleEditScreen),
    );
    expect(screen.mode, VehicleEditMode.create);
    expect(screen.vehicleId, isNull);
    expect(tester.takeException(), isNull);
  });
}
