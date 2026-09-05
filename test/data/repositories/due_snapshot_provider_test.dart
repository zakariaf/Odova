// One vehicle's due snapshot, composed from six streams.
//
// The engine is `recomputeVehicle` and has its own tests. This is about the
// WIRING: what happens while the inputs are loading, what happens when the
// vehicle is not there, and that the clock is injected rather than read.
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/due/daily_distance.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/data/repositories/due_snapshot_provider.dart';

import '../../support/provider_harness.dart';
import '../support/rows.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
final VehicleId _id = VehicleId.tryParse(_golf)!;

// Sorts BEFORE the Golf, so `firstOrNull` and "find the one asked for" are
// different answers. With the decoy after it they are the same, and the
// mutation that takes whichever vehicle is first passes.
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCV9';

/// A day that is NOT the day this suite runs.
///
/// The first version pinned 2026-09-04, which happened to be the real date —
/// so `DateTime.now()` and the injected clock agreed and the mutation swapping
/// one for the other passed. A fixture that coincides with reality proves
/// nothing about which of the two the code read.
final _pinned = DateTime.utc(2026, 11, 20);

DatabaseHarness _harness() => containerWithDatabase(
  overrides: [clockProvider.overrideWithValue(Clock.fixed(_pinned))],
);

/// Subscribes and turns the loop until every stream has delivered.
Future<void> _settle(DatabaseHarness h) async {
  addTearDown(
    h.container.listen(vehicleDueSnapshotProvider(_id), (_, _) {}).close,
  );
  for (var i = 0; i < 60; i++) {
    if (h.container.read(vehicleDueSnapshotProvider(_id)) != null) return;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('a vehicle with seeded items gets a snapshot', () async {
    final h = _harness();
    await insertSettings(h.db);
    // TWO vehicles, and the wanted one is not the first. With one row in the
    // table, "find the vehicle asked for" and "take whichever is there" are the
    // same code — and the second one is wrong on every garage screen.
    await insertVehicle(h.db, id: _polo, name: 'The Polo');
    await insertVehicle(h.db, id: _golf);
    // BOTH get an item. With items on only one of them, picking the wrong
    // vehicle yields an empty assessment list — and `every` over an empty list
    // is vacuously true, so the assertion below would pass on the wrong car.
    await insertServiceItem(
      h.db,
      id: 'rem_01K1C4V2H9B8N3Q7ZE5RY6TMWZ',
      vehicleId: _polo,
    );
    await insertServiceItem(h.db, vehicleId: _golf);
    await insertReading(h.db, vehicleId: _golf, occurredOn: '2026-09-01');
    await _settle(h);

    final snapshot = h.container.read(vehicleDueSnapshotProvider(_id));
    expect(snapshot, isNotNull);
    expect(snapshot!.assessments, isNotEmpty);
    // The GOLF's item, not the Polo's — the Polo has none, so a snapshot built
    // from the wrong vehicle would have an empty assessment list.
    expect(
      snapshot.assessments.every((a) => a.$1.vehicleId == _id),
      isTrue,
    );
  });

  test('a vehicle that is not there answers null, never an empty summary', () {
    // An empty summary would read as "All good" on the garage row — a
    // confident answer about a vehicle the app cannot find. Null is what
    // `garageStatusOf` turns into "Couldn't work out what's due".
    final h = _harness();
    expect(h.container.read(vehicleDueSnapshotProvider(_id)), isNull);
  });

  test(
    'loading and failing collapse to the same answer, deliberately',
    () async {
      // Every caller draws the same thing for both — SPEC.md §8's hollow dot
      // and
      // an admission — so the provider does not make each screen decide twice.
      final h = _harness();
      // Settings present, but no vehicle and no items: still loading as far as
      // any caller can tell, and still null.
      await insertSettings(h.db);
      await _settle(h);
      expect(h.container.read(vehicleDueSnapshotProvider(_id)), isNull);
    },
  );

  test(
    'the clock is injected, so today is not the machine running this',
    () async {
      // SPEC.md §3: time is an argument. `DateTime.now()` here would make every
      // due date depend on when the suite ran, and the whole engine is a
      // function
      // of the date.
      final h = _harness();
      await insertSettings(h.db);
      await insertVehicle(h.db, id: _golf);
      await insertServiceItem(h.db, vehicleId: _golf);
      await insertReading(h.db, vehicleId: _golf, occurredOn: '2026-09-01');
      await _settle(h);

      final snapshot = h.container.read(vehicleDueSnapshotProvider(_id));
      expect(snapshot, isNotNull);
      // The estimate is anchored on the pinned day rather than on today's date.
      expect(snapshot!.estimate?.asOf.toString(), '2026-11-20');
    },
  );

  test('the snapshot is built from the vehicle asked for', () async {
    // The ITEMS and the READINGS are already scoped by id, so picking the wrong
    // vehicle still assembles the right ones — which is why asserting over the
    // assessments cannot catch it. What the vehicle itself decides is the
    // fallback RATE: `expected_annual_m` is a column on the row, and it is the
    // difference between SPEC.md §5's `assumed` rung and the global default.
    final h = _harness();
    await insertSettings(h.db);
    await insertVehicle(h.db, id: _polo, name: 'The Polo');
    await insertVehicle(h.db, id: _golf);
    await insertServiceItem(h.db, vehicleId: _golf);
    // Only the Golf. No readings anywhere, so the engine has nothing to
    // measure from and must fall back.
    await h.db.customUpdate(
      'UPDATE vehicles SET expected_annual_m = ? WHERE id = ?;',
      variables: [
        const Variable<int>(25000000),
        const Variable<String>(_golf),
      ],
      updates: {h.db.vehicles},
    );
    await _settle(h);

    final snapshot = h.container.read(vehicleDueSnapshotProvider(_id));
    expect(snapshot, isNotNull);
    expect(
      snapshot!.rate.confidence,
      RateConfidence.assumed,
      reason: 'the Polo has no expected annual, so this would read default',
    );
  });
}
