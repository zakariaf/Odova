// `vehicle.edit`'s lifecycle: what it reads, when it writes, and what it does
// not.
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/odometer/odometer_entry.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/vehicle_colour.dart';
import 'package:odova/features/vehicles/vehicle_edit_notifier.dart';
import 'package:odova/l10n/locale_controller.dart';

import '../../data/support/rows.dart';
import '../../support/provider_harness.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';

DatabaseHarness _harness() => containerWithDatabase(
  overrides: [
    clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
    // PINNED. `deviceLocalesProvider` reads `WidgetsBinding.instance`, which a
    // plain `test` does not have — and create mode's odometer field asks for
    // the locale's grouping separator and default unit. Pinning it also keeps
    // a British CI box from reading the field in miles.
    deviceLocalesProvider.overrideWithValue(const [Locale('de', 'DE')]),
  ],
);

Future<VehicleEditNotifier> _open(
  DatabaseHarness h, {
  String id = _golf,
}) async {
  final provider = vehicleEditProvider(VehicleId.tryParse(id));
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
    h.container.read(vehicleEditProvider(VehicleId.tryParse(id)));

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

    expect(await notifier.save(), isNotNull);
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

    expect(await notifier.save(), isNotNull);
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
    expect(await notifier.save(), isNull);
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

  group('create mode', () {
    /// The form with no id: `Routes.vehicleNew`.
    VehicleEditNotifier createForm(DatabaseHarness h) {
      addTearDown(
        h.container.listen(vehicleEditProvider(null), (_, _) {}).close,
      );
      return h.container.read(vehicleEditProvider(null).notifier);
    }

    VehicleEditReady createState(DatabaseHarness h) =>
        h.container.read(vehicleEditProvider(null)) as VehicleEditReady;

    test('it opens ready, blank and clean', () async {
      // No row to read, so no Loading state to sit in — and CLEAN, or the
      // first ✕ on a form nobody touched opens the discard dialog.
      final h = _harness();
      await insertSettings(h.db);
      createForm(h);

      final state = createState(h);
      expect(state.draft.name, isEmpty);
      expect(state.draft.isDirty, isFalse);
      expect(state.odometer, isNotNull, reason: 'create mode asks for one');
      expect(state.creating, isTrue);
    });

    test('an edit-mode form has no odometer entry', () async {
      // SPEC.md §8: "in create mode it is an input; in edit mode a row showing
      // the latest reading and its age". The two are the same field on the
      // artboard and must never both be live.
      final h = _harness();
      await insertVehicle(h.db, id: _golf);
      await _open(h);
      expect((_state(h) as VehicleEditReady).odometer, isNull);
      expect((_state(h) as VehicleEditReady).creating, isFalse);
    });

    test('Save needs a name AND a reading', () async {
      final h = _harness();
      await insertSettings(h.db);
      final form = createForm(h);
      expect(createState(h).canSave, isFalse, reason: 'nothing typed');

      form.edit((d) => d.copyWith(name: 'The Transit'));
      expect(createState(h).canSave, isFalse, reason: 'no reading');

      form.typeOdometer('92050');
      expect(createState(h).canSave, isTrue);

      form.edit((d) => d.copyWith(name: '   '));
      expect(createState(h).canSave, isFalse, reason: 'a name is required');
    });

    test('a doubted reading still saves', () async {
      // §8's warning is a warning here too. The rule lives on `OdometerEntry`
      // and this is the assertion that it is the rule THIS form asks.
      final h = _harness();
      await insertSettings(h.db);
      createForm(h)
        ..typeOdometer('3000001')
        ..edit((d) => d.copyWith(name: 'The Truck'));

      expect(createState(h).odometer!.problem, OdometerProblem.implausible);
      expect(createState(h).canSave, isTrue);
    });

    test('Save writes the vehicle, its reading and its seeded set', () async {
      final h = _harness();
      await insertSettings(h.db);
      final form = createForm(h)
        ..typeOdometer('92050')
        ..edit(
          (d) => d.copyWith(
            name: 'The Transit',
            vehicleType: VehicleType.van,
            make: 'Ford',
            colour: VehicleColour.blue,
            isBusiness: true,
          ),
        );

      final saved = await form.save();
      expect(saved, isNotNull);

      final row = await h.db.select(h.db.vehicles).getSingle();
      expect(row.id, saved!.id.toString());
      expect(saved.name, 'The Transit', reason: 'the row, not just its id');
      expect(row.name, 'The Transit');
      expect(row.make, 'Ford');
      expect(row.colour, 'blue');
      expect(row.isBusiness, isTrue);

      final reading = await h.db.select(h.db.odometerReadings).getSingle();
      expect(reading.odometerM, const Distance.fromKm(92050).metres);
      expect(reading.occurredOn, '2026-09-04');
      expect(await h.db.select(h.db.serviceItems).get(), isNotEmpty);
    });

    test('it does not finish onboarding or steal the active slot', () async {
      // Task 9.6: "add from the vehicles + appends the vehicle, does not make
      // it active". Whether to switch is the SCREEN's decision, and it differs
      // by which button opened the form.
      final h = _harness();
      await insertSettings(h.db, activeVehicleId: _golf);
      await insertVehicle(h.db, id: _golf);
      final form = createForm(h)
        ..typeOdometer('1000')
        ..edit((d) => d.copyWith(name: 'The Polo'));

      await form.save();

      final settings = await h.db
          .customSelect('SELECT active_vehicle_id AS v FROM settings;')
          .getSingle();
      expect(settings.read<String?>('v'), _golf);
    });

    test('typing makes it dirty, so a dismiss asks', () async {
      final h = _harness();
      await insertSettings(h.db);
      final form = createForm(h);
      expect(createState(h).isDirty, isFalse);

      form.typeOdometer('92050');
      expect(
        createState(h).isDirty,
        isTrue,
        reason: 'the odometer is work the user would lose',
      );
      expect(
        createState(h).draft.isDirty,
        isFalse,
        reason:
            'and it is not on the draft, which is why the guard asks the '
            'state instead',
      );
    });
  });
}
