// The single write path: persist first, republish second.
//
// SPEC.md §3 Entities; `error-handling-typed-results` rule 11. The two claims
// worth testing are about TIMING and about failure, because both are invisible
// when they are wrong: an optimistic update looks identical to a real one
// until a constraint rejects it, and a swallowed exception looks identical to
// a success until somebody reopens the app.
@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/connection.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import '../../support/values.dart';

Vehicle _vehicle({
  String id = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String name = 'The Golf',
  int sortOrder = 0,
  Currency? currency,
  int? tankCapacityMl,
}) => Vehicle(
  id: VehicleId.tryParse(id)!,
  name: name,
  vehicleType: VehicleType.car,
  fuelKindDefault: FuelKind.diesel,
  status: VehicleStatus.active,
  createdAtUtcMs: 1000,
  updatedAtUtcMs: 1000,
  sortOrder: sortOrder,
  currency: currency,
  tankCapacityMl: tankCapacityMl,
);

void main() {
  late AppDatabase db;
  late VehicleRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = VehicleRepository(db, testUlids());
  });
  tearDown(() => db.close());

  test('a save round-trips every field', () async {
    final saved = _vehicle(currency: isoCurrency('EUR'));
    expect(await repository.save(saved), isA<Ok<Vehicle, PersistFailure>>());

    final found = await repository.findById(saved.id);
    expect(found, isA<Ok<Vehicle, PersistFailure>>());
    expect((found as Ok<Vehicle, PersistFailure>).value, saved);
  });

  test('a save resolves only after the DURABLE commit', () async {
    // Against a real file and a SECOND connection, because an in-memory
    // database cannot tell "written" from "committed": both connections would
    // be the same one. This is what proves the returned Future is not
    // resolving on an in-flight transaction.
    final dir = await Directory.systemTemp.createTemp('odova_durability');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/odova.sqlite');

    final writer = AppDatabase.forTesting(
      NativeDatabase(file, setup: applyPragmas),
    );
    final saved = _vehicle();
    await VehicleRepository(writer, testUlids()).save(saved);
    await writer.close();

    final reader = AppDatabase.forTesting(
      NativeDatabase(file, setup: applyPragmas),
    );
    final found = await VehicleRepository(
      reader,
      testUlids(),
    ).findById(saved.id);
    await reader.close();

    expect((found as Ok<Vehicle, PersistFailure>).value, saved);
  });

  test('the watched stream re-emits after a write, with no third', () async {
    // Exactly two: the initial empty list and the one after the write. A
    // third would mean an optimistic push on top of the real re-emission,
    // which is what makes a rejected write flicker a row onto the screen and
    // then off it.
    final emissions = <List<Vehicle>>[];
    final subscription = repository.watchAll().listen(emissions.add);

    await pumpEventQueue();
    await repository.save(_vehicle());
    await pumpEventQueue();

    await subscription.cancel();
    expect(emissions, hasLength(2));
    expect(emissions.first, isEmpty);
    expect(emissions.last, hasLength(1));
  });

  test('a failed write emits nothing', () async {
    // A two-letter currency code fails the schema CHECK. The stream must not
    // move: a subscriber that re-rendered here would show a row that is not
    // in the database.
    await repository.save(_vehicle());

    final emissions = <List<Vehicle>>[];
    final subscription = repository.watchAll().listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1));

    final result = await repository.save(
      _vehicle(
        id: 'veh_01JV7B5X4G2K9M6P0S3D8FNRTC',
        tankCapacityMl: 0,
      ),
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(result, isA<Err<Vehicle, PersistFailure>>());
    expect(
      (result as Err<Vehicle, PersistFailure>).failure,
      isA<ConstraintViolated>(),
    );
    expect(emissions, hasLength(1), reason: 'the stream must not have moved');
  });

  test(
    'a constraint failure is classified, not reported as a write error',
    () async {
      // The classification is what lets a caller tell "your data is wrong" from
      // "the disk is full". Both are failures; only one is the user's to fix.
      //
      // The violation used to be a two-letter currency code. EPIC-06 typed
      // `Vehicle.currency` as `Currency`, whose only constructor is
      // `tryParse`, so `'EU'` can no longer be built — the invalid state
      // became unrepresentable and the test could not be written any more.
      // A zero tank capacity is the same shape of CHECK and still reachable,
      // because a tank capacity is an `int` and always will be.
      final result = await repository.save(_vehicle(tankCapacityMl: 0));
      final failure = (result as Err<Vehicle, PersistFailure>).failure;

      expect(failure, isA<ConstraintViolated>());
      expect(failure.code, 'constraint_violated');
    },
  );

  test(
    'a read of something absent is NotFound, not an empty success',
    () async {
      final result = await repository.findById(
        VehicleId.tryParse('veh_01JV7B5X4G2K9M6P0S3D8FNRTC')!,
      );

      expect(result, isA<Err<Vehicle, PersistFailure>>());
      expect((result as Err<Vehicle, PersistFailure>).failure, isA<NotFound>());
    },
  );

  test('a database that cannot be opened returns Err, never throws', () async {
    // Against a path that is a DIRECTORY, not a closed in-memory database:
    // closing an in-memory database destroys it and drift opens a fresh empty
    // one, so the write succeeds and the test proves nothing. That version was
    // written first and passed for exactly that reason.
    //
    // What is being proved is that the exception does not escape. A repository
    // that let it through would take down whatever was awaiting it, and above
    // the data layer that is a Notifier with no handler.
    final dir = await Directory.systemTemp.createTemp('odova_unopenable');
    addTearDown(() => dir.delete(recursive: true));

    final broken = AppDatabase.forTesting(
      NativeDatabase(File(dir.path), setup: applyPragmas),
    );
    addTearDown(broken.close);

    final result = await VehicleRepository(
      broken,
      testUlids(),
    ).save(_vehicle());
    expect(result, isA<Err<Vehicle, PersistFailure>>());
    expect(
      (result as Err<Vehicle, PersistFailure>).failure,
      isA<WriteFailed>(),
      reason: 'a disk problem is not a constraint problem',
    );
  });

  test('soft-deleted vehicles are invisible to both reads', () async {
    // "Invisible everywhere immediately" is one filter in the repository, not
    // a convention each call site follows.
    final saved = _vehicle();
    await repository.save(saved);
    await db.customStatement(
      'UPDATE vehicles SET deleted_at_utc_ms = 2000 WHERE id = ?;',
      [saved.id.toString()],
    );

    expect(await repository.watchAll().first, isEmpty);
    expect(
      await repository.findById(saved.id),
      isA<Err<Vehicle, PersistFailure>>(),
    );
  });

  test('an unchanged garage list does not wake the app shell', () async {
    // `vehiclesProvider` is the one provider that is NOT autoDispose — alive
    // for the whole session, feeding the shell. Drift's stream invalidation is
    // table-level, so a write to ANY vehicle re-runs this query; without
    // `distinct` the shell rebuilt on every write, including one that changed
    // nothing the list shows.
    final golf = _vehicle();
    await repository.save(golf);

    final emissions = <List<Vehicle>>[];
    final subscription = repository.watchAll().listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1));

    // Re-saving an identical row is a real write — drift invalidates and
    // re-runs the query — and the answer it produces is equal to the last one.
    await repository.save(golf);
    await pumpEventQueue();

    await subscription.cancel();
    expect(
      emissions,
      hasLength(1),
      reason:
          'the query re-ran and produced the same answer; the subscriber '
          'must not have been woken',
    );
  });

  test('the garage list is ordered, deterministically', () async {
    // `sortOrder` then `id`. The id tiebreak is free because a ULID sorts in
    // mint order, and without it two vehicles at sortOrder 0 swap places
    // between launches.
    await repository.save(
      _vehicle(id: 'veh_01JV7B5X4G2K9M6P0S3D8FNRTC', name: 'Van', sortOrder: 1),
    );
    await repository.save(_vehicle());

    final all = await repository.watchAll().first;
    expect(all.map((v) => v.name), ['The Golf', 'Van']);
  });
}
