// Reordering, selling and deleting a vehicle.
//
// SPEC.md §8's interaction table and §14's lifecycle. The delete is the one
// worth the most care: it takes a vehicle's fill-ups, services, costs, trips
// and reminders with it, it writes no safety copy (§4.4 has three kinds and
// this is not one of them), and once the Undo window closes the only recovery
// left is the user's own exported backup.
//
// **A `ProviderContainer` and a real database, in a plain `test`.** A drift
// stream never delivers under `testWidgets` — the widget binding's fake async
// does not run its timers — so anything that awaits a query has to live
// outside a widget harness. This tests the DECISIONS; the screen tests the
// drawing.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/features/vehicles/vehicles_notifier.dart';

import '../../data/support/rows.dart';
import '../../support/values.dart';

const _golf = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVA';
const _polo = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVB';
const _transit = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVC';

VehicleId _id(String raw) => VehicleId.tryParse(raw)!;

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          Clock.fixed(DateTime.utc(2026, 11, 20, 9, 41)),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  VehiclesNotifier notifier() =>
      container.read(vehiclesNotifierProvider.notifier);

  Future<String?> activeVehicle() async {
    final row = await db
        .customSelect('SELECT active_vehicle_id AS v FROM settings;')
        .getSingleOrNull();
    return row?.read<String?>('v');
  }

  Future<List<String>> liveOrder() async {
    final rows = await db
        .customSelect(
          'SELECT id FROM vehicles WHERE deleted_at_utc_ms IS NULL '
          'ORDER BY sort_order, id;',
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }

  group('reorder', () {
    test('writes sort_order from the position in the list', () async {
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo');
      await insertVehicle(db, id: _transit, name: 'Transit');

      final result = await notifier().reorder([
        _id(_transit),
        _id(_golf),
        _id(_polo),
      ]);

      expect(result, isA<Ok<void, PersistFailure>>());
      expect(await liveOrder(), [_transit, _golf, _polo]);
    });

    test('reordering never changes which vehicle is active', () async {
      // SPEC.md §8: this screen is "management only — *not* where you switch
      // cars". Dragging a row past the active one is the most obvious way an
      // implementation could switch it by accident.
      // The Polo is active and is dragged to the BOTTOM. A fixture that put
      // the active car first could not tell "leaves it alone" apart from
      // "makes the first one active" — which is a real thing an implementation
      // does, and the version of this test that reordered [polo, golf] passed
      // against exactly that bug.
      await insertSettings(db, activeVehicleId: _polo);
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);

      await notifier().reorder([_id(_golf), _id(_polo)]);

      expect(await activeVehicle(), _polo);
      expect(await liveOrder(), [_golf, _polo]);
    });
  });

  group('mark as sold', () {
    test('sets the status and the date, and keeps the history', () async {
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertFillUp(
        db,
        id: 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
        vehicleId: _golf,
      );

      final result = await notifier().markSold(
        _id(_golf),
        soldOn: '2024-03-12',
        soldPrice: Money(850000, isoCurrency('EUR')),
      );

      expect(result, isA<Ok<void, PersistFailure>>());
      final row = await db
          .customSelect(
            'SELECT status, sold_on, sold_price_minor, sold_price_currency '
            'FROM vehicles '
            'WHERE id = ?;',
            variables: [const Variable<String>(_golf)],
          )
          .getSingle();
      expect(row.read<String>('status'), VehicleStatus.sold.wire);
      expect(row.read<String>('sold_on'), '2024-03-12');
      expect(row.read<int>('sold_price_minor'), 850000);
      // §8: "Both still accept new entries — late invoices arrive — and both
      // are exported in full." Selling is not deleting.
      final fillUps = await db
          .customSelect('SELECT COUNT(*) AS n FROM fill_ups;')
          .getSingle();
      expect(fillUps.read<int>('n'), 1);
    });

    test('a sold vehicle that was active stops being active', () async {
      // §8: "an archived vehicle can be active; a sold one only by explicit
      // selection". Leaving a just-sold car active would put Home's banner in
      // front of a user who has not asked for it.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);

      await notifier().markSold(_id(_golf), soldOn: '2024-03-12');

      expect(await activeVehicle(), _polo);
    });

    test('selling the ONLY vehicle leaves it active', () async {
      // There is nothing to promote to, and null would mean "no vehicle
      // selected" on a device that has one. §8 allows a sold active vehicle by
      // explicit selection, and this is the most explicit selection there is:
      // it is the only car the user owns.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);

      await notifier().markSold(_id(_golf), soldOn: '2024-03-12');

      expect(await activeVehicle(), _golf);
    });

    test('selling into a garage of sold cars stays put', () async {
      // A SALE does not have to move, and moving would be a switch nobody
      // asked for: both cars are sold, both draw §8's Home banner, and the row
      // just sold is still there and still readable. Only a DELETE is forced
      // to move, because its row is a tombstone.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(
        db,
        id: _polo,
        name: 'The Polo',
        sortOrder: 1,
        status: 'sold',
      );

      await notifier().markSold(_id(_golf), soldOn: '2024-03-12');

      expect(await activeVehicle(), _golf);
    });

    test('selling the driver promotes the archived winter bike', () async {
      // §8: "an archived vehicle CAN be active". It is off the home screen and
      // off notifications, not off the app.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(
        db,
        id: _polo,
        name: 'The Polo',
        sortOrder: 1,
        status: 'archived',
      );

      await notifier().markSold(_id(_golf), soldOn: '2024-03-12');

      expect(await activeVehicle(), _polo);
    });
  });

  group('delete', () {
    test('soft-deletes the vehicle and everything under it', () async {
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertFillUp(
        db,
        id: 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
        vehicleId: _golf,
      );

      final result = await notifier().delete(_id(_golf));
      final deletion = (result as Ok<VehicleDeletion, PersistFailure>).value;

      expect(await liveOrder(), isEmpty);
      expect(deletion.wasLast, isTrue);
      final fillUp = await db
          .customSelect('SELECT deleted_at_utc_ms AS d FROM fill_ups;')
          .getSingle();
      expect(fillUp.read<int?>('d'), deletion.deletedAtUtcMs);
    });

    test(
      'deleting the active vehicle promotes the next in sort_order',
      () async {
        // §8: "Deleting the active vehicle promotes the next live vehicle in
        // sort_order." Not the first by id and not the newest — the order the
        // user themselves put the garage in.
        await insertSettings(db, activeVehicleId: _golf);
        await insertVehicle(db, id: _golf);
        await insertVehicle(db, id: _transit, name: 'Transit', sortOrder: 2);
        await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);

        final result = await notifier().delete(_id(_golf));
        final deletion = (result as Ok<VehicleDeletion, PersistFailure>).value;

        expect(await activeVehicle(), _polo);
        expect(deletion.promoted, _id(_polo));
        expect(deletion.wasLast, isFalse);
      },
    );

    test('a SOLD vehicle is never promoted to active', () async {
      // §8: "a sold one only by explicit selection". A promotion is the app
      // choosing, which is the opposite of explicit.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(
        db,
        id: _polo,
        name: 'The Polo',
        sortOrder: 1,
        status: 'sold',
      );
      await insertVehicle(db, id: _transit, name: 'Transit', sortOrder: 2);

      await notifier().delete(_id(_golf));

      expect(await activeVehicle(), _transit);
    });

    test('an ARCHIVED vehicle is promoted, because it can be active', () async {
      // The other half of the same sentence in §8: "an archived vehicle can be
      // active; a sold one only by explicit selection". The filter read
      // `status == active`, which skipped archived too — so a user with a
      // daily driver and a SORNed winter bike, deleting the driver, was left
      // pointed at a row that no longer exists.
      // The sold Polo sorts FIRST, so a promotion that had merely stopped
      // excluding sold vehicles would land on it. Archived beats sold; only an
      // empty field falls through to sold at all.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(
        db,
        id: _polo,
        name: 'The Polo',
        sortOrder: 1,
        status: 'sold',
      );
      await insertVehicle(
        db,
        id: _transit,
        name: 'Transit',
        sortOrder: 2,
        status: 'archived',
      );

      await notifier().delete(_id(_golf));

      expect(await activeVehicle(), _transit);
    });

    test('deleting the last live car falls back to a sold one', () async {
      // The end of the road. With nothing but a sold vehicle left there is no
      // promotion that is not the app choosing — but the alternative is
      // leaving `active_vehicle_id` pointing at the row just deleted, which is
      // every scoped screen in all four stacks reading a tombstone.
      //
      // `markSold` already settled this exact question the same way: "Selling
      // the ONLY vehicle leaves it active. There is nothing to promote to, and
      // null would mean 'no vehicle selected' on a device that owns one; a
      // garage of one is also the most explicit selection there is." §8 draws
      // the banner Home shows for it.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(
        db,
        id: _polo,
        name: 'The Polo',
        sortOrder: 1,
        status: 'sold',
      );

      final result = await notifier().delete(_id(_golf));

      expect(await activeVehicle(), _polo);
      expect(
        (result as Ok<VehicleDeletion, PersistFailure>).value.wasLast,
        isFalse,
        reason: 'a sold vehicle is still a vehicle: the garage is not empty',
      );
    });

    test(
      'deleting a vehicle that is NOT active leaves the active alone',
      () async {
        await insertSettings(db, activeVehicleId: _golf);
        await insertVehicle(db, id: _golf);
        await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);

        final result = await notifier().delete(_id(_polo));

        expect(await activeVehicle(), _golf);
        expect(
          (result as Ok<VehicleDeletion, PersistFailure>).value.promoted,
          isNull,
        );
      },
    );
  });

  group('undo', () {
    test('restores the rows and the vehicle that was active', () async {
      // Undo has to put BOTH back. Restoring the rows and leaving the promotion
      // in place would hand the user their car back with the app pointed at a
      // different one — a silent switch on a screen whose whole rule is that it
      // never switches.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertVehicle(db, id: _polo, name: 'The Polo', sortOrder: 1);
      await insertFillUp(
        db,
        id: 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
        vehicleId: _golf,
      );

      final deletion =
          (await notifier().delete(_id(_golf))
                  as Ok<VehicleDeletion, PersistFailure>)
              .value;
      expect(await activeVehicle(), _polo);

      await notifier().undoDelete(deletion);

      expect(await liveOrder(), [_golf, _polo]);
      expect(await activeVehicle(), _golf);
      final fillUp = await db
          .customSelect('SELECT deleted_at_utc_ms AS d FROM fill_ups;')
          .getSingle();
      expect(fillUp.read<int?>('d'), isNull);
    });

    test('undo restores only what THIS delete stamped', () async {
      // A fill-up the user deleted five minutes earlier carries a different
      // timestamp and stays deleted. `undoDeleteVehicle` matches on the stamp
      // for exactly this reason and the notifier must not widen it.
      await insertSettings(db, activeVehicleId: _golf);
      await insertVehicle(db, id: _golf);
      await insertFillUp(
        db,
        id: 'fil_01JQ8ZK3M7F0R6XN2E9TB4HCVA',
        vehicleId: _golf,
        deletedAtUtcMs: 1000,
      );

      final deletion =
          (await notifier().delete(_id(_golf))
                  as Ok<VehicleDeletion, PersistFailure>)
              .value;
      await notifier().undoDelete(deletion);

      final fillUp = await db
          .customSelect('SELECT deleted_at_utc_ms AS d FROM fill_ups;')
          .getSingle();
      expect(fillUp.read<int?>('d'), 1000, reason: 'it was already gone');
    });
  });
}
