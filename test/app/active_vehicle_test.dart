// One app-wide active vehicle, and a multi-vehicle feature that is invisible
// until a second vehicle exists.
//
// SPEC.md §7 *Active vehicle*. The rule that costs the most to get wrong is the
// last one: a person with one car must never be shown a switcher, a chevron or
// a "1 of 1". They did not ask for a fleet feature and every pixel of one is a
// tax on them.
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/active_vehicle.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/tab_stack_reset.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';

import '../data/support/rows.dart';
import '../support/provider_harness.dart';
import '../support/source_tree.dart';

/// Two vehicles, neither of them `insertVehicle`'s default.
///
/// Deliberately not the default: every call in this file says WHICH car it
/// means, and a test whose subject is "the active vehicle" reading `id:` from a
/// helper's default would be one rename away from asserting about a car it
/// never mentioned.
const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    final harness = containerWithDatabase(
      overrides: [
        clockProvider.overrideWithValue(Clock.fixed(DateTime.utc(2026, 9, 4))),
      ],
    );
    container = harness.container;
    db = harness.db;
  });

  Future<void> settle() =>
      settleProviders(container, [settingsProvider, vehiclesProvider]);

  test('activeVehicleId is read from Settings, never re-derived', () async {
    // One persisted field. Deriving it — "the only vehicle", "the most recently
    // used" — would make it disagree with the file a user restores from.
    await insertVehicle(db, id: _golf);
    await insertVehicle(db, id: _polo, name: 'The Polo');
    await insertSettings(db, activeVehicleId: _polo);
    await settle();

    expect(container.read(activeVehicleIdProvider)?.toString(), _polo);
  });

  test('it is null before first run has written a settings row', () async {
    await settle();
    expect(container.read(activeVehicleIdProvider), isNull);
  });

  test('setting it writes exactly one Settings column', () async {
    // Asserted over the ROW, not over the model. A read-modify-write through
    // `AppSettings` would put every one of its defaults back into the
    // statement, so a field added later and not yet read would be reset to its
    // default on the next vehicle switch — and a model-level comparison could
    // not see it, because the model would agree with itself.
    await insertVehicle(db, id: _golf);
    await insertSettings(
      db,
      activeVehicleId: _golf,
      distanceUnit: 'mi',
      currencyDefault: 'GBP',
    );
    await settle();

    final before = await _settingsRow(db);
    await setActiveVehicle(container, VehicleId.tryParse(_polo)!);
    final after = await _settingsRow(db);

    expect(after['active_vehicle_id'], _polo);
    expect(after['updated_at_utc_ms'], isNot(before['updated_at_utc_ms']));

    before
      ..remove('active_vehicle_id')
      ..remove('updated_at_utc_ms');
    after.removeWhere((key, _) => !before.containsKey(key));
    expect(after, before);
  });

  test('setting it POSTS a reset that keeps the current tab', () async {
    // Through task 8.3's single function, asserted on the REQUEST rather than
    // by re-implementing the reset here — a test that walks the branches itself
    // would keep passing after the caller stopped asking.
    await insertVehicle(db, id: _golf);
    await insertSettings(db, activeVehicleId: _golf);
    await settle();
    expect(container.read(tabStackResetProvider), isNull);

    await setActiveVehicle(container, VehicleId.tryParse(_polo)!);

    final request = container.read(tabStackResetProvider);
    expect(request, isNotNull);
    // §7: switching the vehicle changes WHAT is shown, not where you were.
    expect(request!.selectHome, isFalse);
  });

  test('with no settings row it writes nothing and resets nothing', () async {
    // First run has not finished, so there is no row to point at a vehicle and
    // no stack worth clearing. It has to be a no-op rather than an insert:
    // manufacturing a settings row here would make a half-finished onboarding
    // indistinguishable from a completed one, and SPEC.md §7's launch gate
    // reads exactly that field to decide.
    await insertVehicle(db, id: _golf);
    await settle();

    await setActiveVehicle(container, VehicleId.tryParse(_golf)!);

    final rows = await db.customSelect('SELECT * FROM settings;').get();
    expect(rows, isEmpty);
    expect(container.read(tabStackResetProvider), isNull);
  });

  test('a write failure is RETURNED, not swallowed', () async {
    // `guardPersist` wraps a thrown UPDATE as well as a missing row — a full
    // disk, a locked database, a degraded-mode refusal. Swallowing it closed
    // the switcher on a vehicle that did not change: the user believes they
    // switched cars and logs the next fill-up against the wrong one.
    await insertVehicle(db, id: _golf);
    await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
    await settle();

    // The settings TABLE is gone, so the UPDATE throws rather than matching
    // zero rows — the failure mode a missing row cannot reproduce.
    await db.customStatement('DROP TABLE settings;');

    final result = await setActiveVehicle(
      container,
      VehicleId.tryParse(_polo)!,
    );

    expect(result, isA<Err<void, PersistFailure>>());
    expect(container.read(tabStackResetProvider), isNull);
  });

  test('and a successful write reports success', () async {
    await insertVehicle(db, id: _golf);
    await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
    await settle();

    final result = await setActiveVehicle(
      container,
      VehicleId.tryParse(_polo)!,
    );

    expect(result, isA<Ok<void, PersistFailure>>());
  });

  group('the one-car user is never taxed', () {
    test('with one vehicle the switcher is hidden', () async {
      await insertVehicle(db, id: _golf);
      await insertSettings(db, activeVehicleId: _golf);
      await settle();

      expect(container.read(showsVehicleSwitcherProvider), isFalse);
    });

    test('with two vehicles it appears', () async {
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertSettings(db, activeVehicleId: _golf);
      await settle();

      expect(container.read(showsVehicleSwitcherProvider), isTrue);
    });

    test('with no vehicles it is hidden, not shown empty', () async {
      await insertSettings(db);
      await settle();

      expect(container.read(showsVehicleSwitcherProvider), isFalse);
    });

    test('a soft-deleted vehicle does not count towards the second', () async {
      // The count is LIVE vehicles. A user who sold their second car and
      // deleted it would otherwise keep a switcher that offers one choice.
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertSettings(db, activeVehicleId: _golf);
      await settle();
      expect(container.read(showsVehicleSwitcherProvider), isTrue);

      // `customUpdate` with `updates:`, not `customStatement`. A raw statement
      // does not tell drift which tables it touched, so the watching query is
      // never invalidated and the stream sits on a stale answer — which is a
      // test that would have passed against a switcher that never hides.
      await db.customUpdate(
        'UPDATE vehicles SET deleted_at_utc_ms = 2000 WHERE id = ?',
        variables: [const Variable<String>(_polo)],
        updates: {db.vehicles},
      );
      await pumpEventQueue();

      expect(container.read(showsVehicleSwitcherProvider), isFalse);
    });
  });

  test('the All-vehicles toggle is not the active vehicle', () async {
    // SPEC.md §7's one exception. It is a tab-scoped view flag and it is
    // explicitly NOT persisted into Settings — decided here so EPIC-13 inherits
    // it rather than making the call again over a half-built screen.
    //
    // Against a SETTLED two-vehicle fixture, and asserting the id is
    // UNCHANGED. The version that asserted `isNull` ran with nothing inserted
    // and nothing settled, so the active vehicle was null before the toggle as
    // well as after — a toggle that also wrote `active_vehicle_id` would have
    // passed it.
    await insertVehicle(db, id: _golf);
    await insertVehicle(db, id: _polo, name: 'The Polo');
    await insertSettings(db, activeVehicleId: _golf, onboardingDone: true);
    await settle();
    expect(container.read(activeVehicleIdProvider)?.toString(), _golf);
    expect(container.read(costsAllVehiclesProvider), isFalse);

    container.read(costsAllVehiclesProvider.notifier).toggle();

    expect(container.read(costsAllVehiclesProvider), isTrue);
    expect(container.read(activeVehicleIdProvider)?.toString(), _golf);
    expect(container.read(tabStackResetProvider), isNull);

    // And nothing reached the database.
    final row = await _settingsRow(db);
    expect(row['active_vehicle_id'], _golf);
  });

  test('active_vehicle_id is written in exactly one place', () async {
    // SPEC.md §7 is explicit that `vehicles` under Settings never switches, and
    // that selection happens only in `vehicle.switcher` or via a deep link.
    // Both of those call `setActiveVehicle`; this asserts nothing else writes
    // the field at all.
    final writers = <String>[];
    for (final file in dartFilesUnder('lib')) {
      if (file.path.endsWith('active_vehicle.dart')) continue;
      if (file.path.startsWith('lib/data/')) continue;
      final source = sourceWithoutLineComments(file);
      // BOTH shapes. The model field is the obvious one; the dangerous one is
      // a feature calling `SettingsRepository.setActiveVehicle` directly,
      // bypassing the tab-stack reset — and that call site contains no
      // `activeVehicleId:` at all, so the first version of this grep could not
      // see the writer it most needed to catch.
      if (RegExp(r'activeVehicleId:|\.setActiveVehicle\(').hasMatch(source)) {
        writers.add(file.path);
      }
    }
    expect(writers, isEmpty, reason: writers.join('\n'));
  });
}

/// The settings row as raw columns.
Future<Map<String, Object?>> _settingsRow(AppDatabase db) async {
  final rows = await db.customSelect('SELECT * FROM settings;').get();
  return Map<String, Object?>.from(rows.single.data);
}
