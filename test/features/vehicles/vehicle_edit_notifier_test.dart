// `vehicle.edit`'s lifecycle: what it reads, when it writes, and what it does
// not.
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/features/vehicles/vehicle_edit_notifier.dart';

import '../../data/support/rows.dart';
import '../../support/provider_harness.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

DatabaseHarness _harness() => containerWithDatabase(
  overrides: [
    clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
  ],
);

Future<VehicleEditNotifier> _open(
  DatabaseHarness h, {
  String id = _golf,
}) async {
  final provider = vehicleEditProvider(VehicleId.tryParse(id)!);
  // SUBSCRIBED, not read. The provider is `autoDispose`, so an unlistened one
  // is torn down before its load lands and the state never leaves Loading —
  // the same lesson `provider_harness.dart` records for streams.
  addTearDown(h.container.listen(provider, (_, _) {}).close);
  final notifier = h.container.read(provider.notifier);
  // Turn the loop until the read completes. A single `Duration.zero` is one
  // microtask and a drift query is more than one.
  for (var i = 0; i < 50; i++) {
    if (h.container.read(provider) is! VehicleEditLoading) break;
    await Future<void>.delayed(Duration.zero);
  }
  return notifier;
}

VehicleEditState _state(DatabaseHarness h, {String id = _golf}) =>
    h.container.read(vehicleEditProvider(VehicleId.tryParse(id)!));

void main() {
  test('it loads the row it was asked for', () async {
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    await _open(h);

    final state = _state(h);
    expect(state, isA<VehicleEditReady>());
    expect((state as VehicleEditReady).draft.name, 'The Golf');
    expect(state.draft.isDirty, isFalse);
  });

  test('a vehicle deleted while the form opened reads as missing', () async {
    // Not an empty form. A form that draws blank fields for a row that is gone
    // is a form whose Save creates a vehicle the user did not ask for.
    final h = _harness();
    await _open(h);
    expect(_state(h), isA<VehicleEditMissing>());
  });

  test('editing does not write, and Save does', () async {
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    final notifier = await _open(h);

    notifier.edit((d) => d.copyWith(name: 'The Polo', year: 2016));
    expect((_state(h) as VehicleEditReady).draft.isDirty, isTrue);
    final before = await h.db.select(h.db.vehicles).getSingle();
    expect(before.name, 'The Golf', reason: 'nothing written yet');

    expect(await notifier.save(), isTrue);
    final after = await h.db.select(h.db.vehicles).getSingle();
    expect(after.name, 'The Polo');
    expect(after.year, 2016);
    expect(
      after.updatedAtUtcMs,
      DateTime.utc(2026, 9, 4).millisecondsSinceEpoch,
    );
  });

  test('the form is clean again after a save', () async {
    // Otherwise dismissing it asks about changes that are already on disk,
    // which teaches the user that the discard dialog means nothing.
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    final notifier = await _open(h);

    notifier.edit((d) => d.copyWith(name: 'The Polo'));
    await notifier.save();
    expect((_state(h) as VehicleEditReady).draft.isDirty, isFalse);
  });

  test('Save on an untouched form writes nothing and still closes', () async {
    // Pressing Save on a form nobody touched is a way of saying "I am done".
    // Writing the row anyway would move `updated_at` on a vehicle that did not
    // change, and `updated_at` is what a future sync would order by.
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    final notifier = await _open(h);

    expect(await notifier.save(), isTrue);
    final row = await h.db.select(h.db.vehicles).getSingle();
    expect(
      row.updatedAtUtcMs,
      isNot(
        DateTime.utc(2026, 9, 4).millisecondsSinceEpoch,
      ),
    );
  });

  test('Save refuses an empty name and writes nothing', () async {
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    final notifier = await _open(h);

    notifier.edit((d) => d.copyWith(name: '  '));
    expect(await notifier.save(), isFalse);
    expect(
      (await h.db.select(h.db.vehicles).getSingle()).name,
      'The Golf',
    );
  });

  test('the form does not reload underneath the user', () async {
    // Read once, not watched. A form that re-read its own row would discard a
    // half-typed plate the moment anything else in the app touched the vehicle
    // — and its own Save is one of those things.
    final h = _harness();
    await insertVehicle(h.db, id: _golf);
    final notifier = await _open(h);

    notifier.edit((d) => d.copyWith(plate: 'M-AB 12'));
    // Something else writes the row — a rename from the garage, an import, a
    // future sync. `customUpdate` with `updates:` so drift invalidates every
    // watcher exactly as a real write would; a bare `customStatement` would
    // notify nobody and the test would pass by not testing.
    await h.db.customUpdate(
      "UPDATE vehicles SET name = 'Renamed elsewhere' WHERE id = ?;",
      variables: [const Variable<String>(_golf)],
      updates: {h.db.vehicles},
    );
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final draft = (_state(h) as VehicleEditReady).draft;
    expect(draft.plate, 'M-AB 12', reason: 'the half-typed plate survived');
    expect(draft.name, 'The Golf', reason: 'and so did the name being edited');
  });
}
