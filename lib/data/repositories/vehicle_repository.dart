// The vehicle write path.
//
// One rule runs through every repository in this directory: **persist first,
// republish second.** Every mutation is exactly one `db.transaction`, and the
// UI learns about it because the watched stream re-emits — never because the
// repository pushed an optimistic update. `error-handling-typed-results`
// rule 11, and the reason is that an optimistic update that a later constraint
// rejects leaves the screen showing a row the database does not have.
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/reminders/service_item_catalogue.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/vehicles/delete_counts.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';
import 'package:odova/data/repositories/watch.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Reads and writes vehicles.
class VehicleRepository {
  /// Creates a repository over [_db].
  ///
  /// [_ids] mints the `veh_`, `odo_` and `rem_` ids a create needs. Injected
  /// rather than reached for, so a test fixes the clock and the seed and gets
  /// the same vehicle every run.
  const VehicleRepository(this._db, this._ids);

  final AppDatabase _db;
  final UlidFactory _ids;

  /// Every live vehicle, in garage order.
  ///
  /// Through `watchList`, which is where the soft-delete filter's intent and
  /// the de-duplication both live. These two streams were the only ones in the
  /// data layer without `distinct`, and `vehiclesProvider` is the one provider
  /// that is NOT autoDispose — alive for the whole session, feeding the app
  /// shell. So the most-subscribed stream in the app was the one that rebuilt
  /// on every write to `vehicles`, including a `sortOrder` nudge on a car the
  /// user is not looking at.
  Stream<List<Vehicle>> watchAll() => watchList(
    _db.select(_db.vehicles)
      ..where((v) => v.deletedAtUtcMs.isNull())
      ..orderBy([
        (v) => OrderingTerm(expression: v.sortOrder),
        (v) => OrderingTerm(expression: v.id),
      ]),
    vehicleFromRow,
  );

  /// One vehicle, or null while it does not exist.
  Stream<Vehicle?> watchById(VehicleId id) => watchOne(
    _db.select(_db.vehicles)
      ..where((v) => v.id.equals(id.toString()) & v.deletedAtUtcMs.isNull()),
    vehicleFromRow,
  );

  /// Reads one vehicle.
  Future<Result<Vehicle, PersistFailure>> findById(VehicleId id) =>
      guardPersist(() async {
        final row =
            await (_db.select(_db.vehicles)..where(
                  (v) => v.id.equals(id.toString()) & v.deletedAtUtcMs.isNull(),
                ))
                .getSingleOrNull();
        if (row == null) return Err(NotFound(id.toString()));
        return Ok(vehicleFromRow(row));
      });

  /// Writes [vehicle], creating or replacing it.
  ///
  /// One statement inside one transaction. The `Future` resolves after the
  /// DURABLE commit, so a caller that awaits it and then reads gets what it
  /// wrote — including from a second connection over the same file.
  Future<Result<Vehicle, PersistFailure>> save(Vehicle vehicle) =>
      guardPersist(() async {
        await _db.transaction(() async {
          await _db
              .into(_db.vehicles)
              .insertOnConflictUpdate(
                _companionFor(vehicle),
              );
        });
        return Ok(vehicle);
      });

  /// Every live vehicle, in garage order.
  ///
  /// The name §8 uses. [watchAll] is the same stream; this is what the feature
  /// layer reads, so the garage's ordering rule has one name.
  Stream<List<Vehicle>> watchGarage() => watchAll();

  /// Creates a vehicle, its first odometer reading and its seeded reminders.
  ///
  /// **One transaction, and that is the whole point.** SPEC.md §3 forbids a
  /// vehicle with no odometer reading, so a create that wrote the vehicle and
  /// then failed would leave a record the app cannot compute a due state for
  /// and the user cannot repair — the due engine would have nothing to project
  /// from and every screen would read `unknown` forever.
  Future<Result<Vehicle, PersistFailure>> create(
    VehicleDraft draft, {
    required int nowUtcMs,
    bool asFirstVehicle = false,
  }) => createVehicle(
    Vehicle(
      // A placeholder, replaced below. `createVehicle` owns identity, and this
      // is the one field it will not take from a caller.
      id: kUnsavedVehicleId,
      name: draft.name,
      vehicleType: draft.vehicleType,
      fuelKindDefault: draft.fuelKindDefault,
      status: VehicleStatus.active,
      isBusiness: draft.isBusiness,
      distanceUnit: draft.distanceUnit,
      expectedAnnual: draft.expectedAnnual,
      createdAtUtcMs: nowUtcMs,
      updatedAtUtcMs: nowUtcMs,
    ),
    odometer: draft.odometer,
    odometerUnit: draft.odometerUnit,
    occurredOn: draft.occurredOn,
    nowUtcMs: nowUtcMs,
    asFirstVehicle: asFirstVehicle,
    liquidCooled: draft.liquidCooled,
  );

  /// Creates a vehicle from a COMPLETE row, plus its first odometer reading
  /// and the seeded set — all in one transaction.
  ///
  /// [create] is first run's door and this one is `vehicle.edit`'s create
  /// mode, which is the same twenty-field form as its edit mode plus an
  /// odometer (SPEC.md §8). The form already knows how to build a `Vehicle`;
  /// asking it to flatten twenty fields into a `VehicleDraft` and then unpack
  /// them again would be two lists of the same columns, kept in step by hand.
  ///
  /// FIVE fields on [facts] are ignored, because they are this method's to
  /// decide: `id`, `status`, `sortOrder`, `createdAtUtcMs` and
  /// `updatedAtUtcMs`. The id is ASSERTED to be `kUnsavedVehicleId` rather than
  /// merely documented — a caller holding a real one was editing a vehicle,
  /// not creating one.
  ///
  /// `sortOrder` is `max + 1`, and an earlier version of this comment argued
  /// it did not need to be: a new row at 0 sorts last on its ULID under the
  /// garage's `(sortOrder, id)` order. That holds only while EVERY row is
  /// still at 0. `reorder` writes `0, 1, 2, …`, so after one drag a new
  /// vehicle lands SECOND — behind whichever car holds index 0 — and task
  /// 9.6's "appends the vehicle" and its "Switch to it" snackbar both stop
  /// describing what the user sees.
  ///
  /// [liquidCooled] is not on `Vehicle` because Odova stores no cooling field;
  /// §4.8.3 seeds `coolant` on a liquid-cooled motorcycle and nowhere else, so
  /// the answer travels as an argument or not at all (F-9.15).
  Future<Result<Vehicle, PersistFailure>> createVehicle(
    Vehicle facts, {
    required Distance odometer,
    required DistanceUnit odometerUnit,
    required String occurredOn,
    required int nowUtcMs,
    bool asFirstVehicle = false,
    bool liquidCooled = false,
  }) {
    assert(
      facts.id == kUnsavedVehicleId,
      'createVehicle mints the id. A caller that had a real one was editing a '
      'vehicle, not creating one — pass `kUnsavedVehicleId` so the discard is '
      'visible at the call site rather than only in this dartdoc.',
    );
    return guardPersist(() async {
      try {
        return await _create(
          facts,
          odometer: odometer,
          odometerUnit: odometerUnit,
          occurredOn: occurredOn,
          nowUtcMs: nowUtcMs,
          asFirstVehicle: asFirstVehicle,
          liquidCooled: liquidCooled,
        );
      } on _MissingSettings {
        return const Err(NotFound(AppSettings.id));
      }
    });
  }

  Future<Result<Vehicle, PersistFailure>> _create(
    Vehicle facts, {
    required Distance odometer,
    required DistanceUnit odometerUnit,
    required String occurredOn,
    required int nowUtcMs,
    required bool asFirstVehicle,
    required bool liquidCooled,
  }) async {
    // Read INSIDE the transaction, so two creates cannot both see the same
    // max and land on the same index.
    final vehicle = _asNew(facts, nowUtcMs, await _nextSortOrder());
    // The reading is stored in the unit it was TYPED in, and the seeded
    // intervals in the vehicle's own unit when it has one — the same
    // precedence `create` used, now reading it off the row.
    final seedUnit = vehicle.distanceUnit ?? odometerUnit;

    await _db.transaction(() async {
      await _db.into(_db.vehicles).insert(_companionFor(vehicle));

      await _db
          .into(_db.odometerReadings)
          .insert(
            OdometerReadingsCompanion.insert(
              id: 'odo_${_ids.next()}',
              vehicleId: vehicle.id.toString(),
              occurredOn: occurredOn,
              odometerM: metresColumn(odometer),
              odometerUnit: odometerUnit.wire,
              // `manual`: the user typed it. Not `import`, which would tell a
              // later reader this reading arrived from a backup file.
              source: OdometerSource.manual.wire,
              createdAtUtcMs: nowUtcMs,
              updatedAtUtcMs: nowUtcMs,
            ),
          );

      // Copied out of the catalogue, never referenced. Changing a seed later
      // must not move an interval a user has already corrected — SPEC.md §4.8.
      for (final seed in seedFor(
        type: vehicle.vehicleType,
        fuel: vehicle.fuelKindDefault,
        isBusiness: vehicle.isBusiness,
        unit: seedUnit,
        liquidCooled: liquidCooled,
      )) {
        await _db
            .into(_db.serviceItems)
            .insert(
              ServiceItemsCompanion.insert(
                id: 'rem_${_ids.next()}',
                vehicleId: vehicle.id.toString(),
                kind: seed.kind.wire,
                priority: seed.priority.wire,
                rollover: seed.rollover.wire,
                isTracked: Value(seed.isTracked),
                intervalDistanceM: Value(seed.intervalDistanceM),
                intervalDistanceUnit: Value(
                  seed.intervalDistanceM == null ? null : seedUnit.wire,
                ),
                intervalMonths: Value(seed.intervalMonths),
                createdAtUtcMs: nowUtcMs,
                updatedAtUtcMs: nowUtcMs,
              ),
            );
      }

      if (!asFirstVehicle) return;
      // SPEC.md §8's fourth Data-out line, and it belongs INSIDE this
      // transaction rather than after it. `onboarding_done` is what stops the
      // app replaying first run; a vehicle that exists with the flag still
      // false is a car the user made and cannot reach.
      //
      // Only on the FIRST vehicle. Task 9.6: "add from the vehicles + appends
      // the vehicle, does not make it active" — a second car must never steal
      // the active slot from the one the user is looking at.
      final updated =
          await (_db.update(
            _db.settingsTable,
          )..where((s) => s.id.equals(AppSettings.id))).write(
            SettingsTableCompanion(
              activeVehicleId: Value(vehicle.id.toString()),
              onboardingDone: const Value(true),
              updatedAtUtcMs: Value(nowUtcMs),
            ),
          );
      if (updated == 0) {
        // No settings row, which production cannot reach: `firstrun.vehicle`
        // is entered either from `firstrun.language`'s Continue, which writes
        // the row, or from a launch with `onboarding_done` already true, which
        // implies one. So this is a bug in the caller rather than a user's
        // situation, and the transaction unwinds.
        //
        // The alternative — create the row here — means choosing a
        // `currency_default` this layer has no basis for. A repository has no
        // locale and no device region, and a guessed currency on somebody's
        // first vehicle is exactly the kind of invented fact §2 forbids.
        // Thrown so drift unwinds the transaction, and caught below so the
        // caller gets a typed failure rather than a stack trace. `guardPersist`
        // classifies SQLite errors and this is not one.
        throw const _MissingSettings();
      }
    });

    return Ok(vehicle);
  }

  /// What `dialog.confirmDelete` states out loud before destroying it.
  ///
  /// Soft-deleted rows are excluded: a user who deleted a fill-up five minutes
  /// ago should not be told it is about to go permanently, because it already
  /// went.
  Future<Result<DeleteCounts, PersistFailure>> entryCounts(VehicleId id) =>
      guardPersist(() async {
        Future<int> count(String table) async {
          final row = await _db
              .customSelect(
                'SELECT COUNT(*) AS n FROM $table '
                'WHERE vehicle_id = ? AND deleted_at_utc_ms IS NULL;',
                variables: [Variable<String>(id.toString())],
              )
              .getSingle();
          return row.read<int>('n');
        }

        return Ok((
          fillUps: await count('fill_ups'),
          services: await count('service_records'),
          costs: await count('expenses'),
          trips: await count('trips'),
          reminders: await count('service_items'),
        ));
      });

  /// Writes `sort_order` from the position of each id in [ids].
  ///
  /// One transaction: a list containing an id that is not in the garage writes
  /// nothing at all, rather than half a reorder the user then has to undo by
  /// hand.
  Future<Result<void, PersistFailure>> reorder(List<VehicleId> ids) =>
      guardPersist(() async {
        await _db.transaction(() async {
          for (var index = 0; index < ids.length; index++) {
            final rows =
                await (_db.update(_db.vehicles)
                      ..where((v) => v.id.equals(ids[index].toString())))
                    .write(VehiclesCompanion(sortOrder: Value(index)));
            // An id that is not in the garage aborts the whole reorder. A
            // constraint violation is the right shape for it: `guardPersist`
            // classifies it, and the transaction unwinds, so the user sees
            // their old order rather than half a new one they then have to
            // undo by hand.
            if (rows == 0) {
              throw SqliteException(
                19,
                'vehicle ${ids[index]} is not in the garage',
              );
            }
          }
        });
        return const Ok(null);
      });

  /// Marks [id] sold, and touches nothing else.
  ///
  /// [soldPrice] carries its CURRENCY, and it has to. The two columns are one
  /// fact: `row_mappers.moneyOrNull` returns null unless BOTH are present, so a
  /// price written without its code reads back as no price at all — and then
  /// the next ordinary save of that vehicle writes the null over the number,
  /// because `toVehicle` carries `soldPrice: original.soldPrice`. SPEC.md §2's
  /// storage rule is minor units PLUS an ISO 4217 code, and there is no CHECK
  /// on the table pairing them, so nothing but this signature can enforce it.
  Future<Result<void, PersistFailure>> markSold(
    VehicleId id, {
    required String soldOn,
    required int updatedAtUtcMs,
    Money? soldPrice,
  }) => _setStatus(
    id,
    VehiclesCompanion(
      status: Value(VehicleStatus.sold.wire),
      soldOn: Value(soldOn),
      soldPriceMinor: Value(amountMinorColumnOrNull(soldPrice)),
      soldPriceCurrency: Value(currencyColumnOrNull(soldPrice)),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    ),
  );

  /// Archives [id], leaving `sold_on` null.
  ///
  /// Archived is NOT sold. A vehicle put away for the winter has no sale date,
  /// and inventing one would put a price into the running-cost total that
  /// nobody paid.
  Future<Result<void, PersistFailure>> archive(
    VehicleId id, {
    required int updatedAtUtcMs,
  }) => _setStatus(
    id,
    VehiclesCompanion(
      status: Value(VehicleStatus.archived.wire),
      updatedAtUtcMs: Value(updatedAtUtcMs),
    ),
  );

  Future<Result<void, PersistFailure>> _setStatus(
    VehicleId id,
    VehiclesCompanion companion,
  ) => guardPersist(() async {
    final rows = await (_db.update(
      _db.vehicles,
    )..where((v) => v.id.equals(id.toString()))).write(companion);
    if (rows == 0) return Err(NotFound(id.toString()));
    return const Ok(null);
  });

  /// `facts` as a brand-new row: this repository's id, active, stamped now,
  /// and sorted last.
  ///
  /// Written out rather than through `copyWith`, and the reason is the same one
  /// `VehicleEditDraft` exists for — a `copyWith` over twenty nullable fields
  /// cannot express "clear this", so a partial copy is a class of bug rather
  /// than a shortcut.
  ///
  /// It does NOT make a newly added column a compile error, and an earlier
  /// version of this comment claimed it did: `Vehicle`'s constructor makes all
  /// but seven fields optional-named, so a new nullable one would be dropped
  /// here as quietly as anywhere else. What the list buys is a single place to
  /// look, next to the four fields this method decides — which is worth
  /// stating accurately rather than overstating.
  /// One past the last row's `sort_order`, or 0 for the first vehicle.
  ///
  /// Soft-deleted rows COUNT: a gap in the sequence is harmless, and skipping
  /// them would let a create reuse the index of a vehicle the user can still
  /// undo back into the garage.
  Future<int> _nextSortOrder() async {
    final row = await _db
        .customSelect('SELECT MAX(sort_order) AS m FROM vehicles;')
        .getSingle();
    final max = row.read<int?>('m');
    return max == null ? 0 : max + 1;
  }

  Vehicle _asNew(Vehicle facts, int nowUtcMs, int sortOrder) => Vehicle(
    id: VehicleId.tryParse('veh_${_ids.next()}')!,
    status: VehicleStatus.active,
    createdAtUtcMs: nowUtcMs,
    updatedAtUtcMs: nowUtcMs,
    name: facts.name,
    vehicleType: facts.vehicleType,
    fuelKindDefault: facts.fuelKindDefault,
    make: facts.make,
    model: facts.model,
    year: facts.year,
    plate: facts.plate,
    vin: facts.vin,
    isBusiness: facts.isBusiness,
    tankCapacityMl: facts.tankCapacityMl,
    purchaseDate: facts.purchaseDate,
    purchaseOdometer: facts.purchaseOdometer,
    purchasePrice: facts.purchasePrice,
    // `soldOn` and `soldPrice` are deliberately absent: a new vehicle is
    // active, and a sale date on one is a contradiction, not a fact to carry.
    expectedAnnual: facts.expectedAnnual,
    colour: facts.colour,
    notes: facts.notes,
    sortOrder: sortOrder,
    notificationsMuted: facts.notificationsMuted,
    currency: facts.currency,
    distanceUnit: facts.distanceUnit,
    volumeUnit: facts.volumeUnit,
    consumptionUnit: facts.consumptionUnit,
    noticeDistance: facts.noticeDistance,
    noticeDays: facts.noticeDays,
  );

  VehiclesCompanion _companionFor(Vehicle vehicle) => VehiclesCompanion.insert(
    id: vehicle.id.toString(),
    createdAtUtcMs: vehicle.createdAtUtcMs,
    updatedAtUtcMs: vehicle.updatedAtUtcMs,
    name: vehicle.name,
    make: Value(vehicle.make),
    model: Value(vehicle.model),
    year: Value(vehicle.year),
    plate: Value(vehicle.plate),
    vin: Value(vehicle.vin),
    vehicleType: vehicle.vehicleType.wire,
    isBusiness: Value(vehicle.isBusiness),
    fuelKindDefault: vehicle.fuelKindDefault.wire,
    tankCapacityMl: Value(vehicle.tankCapacityMl),
    purchaseDate: Value(vehicle.purchaseDate),
    purchaseOdometerM: Value(metresColumnOrNull(vehicle.purchaseOdometer)),
    purchasePriceMinor: Value(amountMinorColumnOrNull(vehicle.purchasePrice)),
    purchasePriceCurrency: Value(currencyColumnOrNull(vehicle.purchasePrice)),
    status: vehicle.status.wire,
    soldOn: Value(vehicle.soldOn),
    soldPriceMinor: Value(amountMinorColumnOrNull(vehicle.soldPrice)),
    soldPriceCurrency: Value(currencyColumnOrNull(vehicle.soldPrice)),
    expectedAnnualM: Value(metresColumnOrNull(vehicle.expectedAnnual)),
    colour: Value(vehicle.colour),
    notes: Value(vehicle.notes),
    sortOrder: Value(vehicle.sortOrder),
    notificationsMuted: Value(vehicle.notificationsMuted),
    currency: Value(vehicle.currency?.code),
    distanceUnit: Value(vehicle.distanceUnit?.wire),
    volumeUnit: Value(vehicle.volumeUnit?.wire),
    consumptionUnit: Value(vehicle.consumptionUnit?.wire),
    noticeDistanceM: Value(metresColumnOrNull(vehicle.noticeDistance)),
    noticeDays: Value(vehicle.noticeDays),
  );
}

/// Everything first run collects, and nothing more.
///
/// SPEC.md §8 calls `firstrun.vehicle` the highest drop-off screen in the
/// product and says it asks for ONE number. So this carries a name, what the
/// vehicle is, and the odometer — the rest of `Vehicle`'s thirty fields are
/// filled in later, on `vehicle.edit`, by the users who want to.
@immutable
class VehicleDraft {
  /// Creates a draft.
  const VehicleDraft({
    required this.name,
    required this.vehicleType,
    required this.fuelKindDefault,
    required this.odometer,
    required this.odometerUnit,
    required this.occurredOn,
    this.isBusiness = false,
    this.distanceUnit,
    this.liquidCooled = false,
    this.expectedAnnual,
  });

  /// What the user calls it.
  final String name;

  /// What it is. Decides which catalogue seeds.
  final VehicleType vehicleType;

  /// What it burns. Composes with [vehicleType] — SPEC.md §4.8.3.
  final FuelKind fuelKindDefault;

  /// The reading on the dash right now.
  final Distance odometer;

  /// The unit that reading was TYPED in.
  ///
  /// Stored per record, because a user who moves country reads a different
  /// cluster and SPEC.md §3 keeps the unit with the number rather than
  /// converting on the way in.
  final DistanceUnit odometerUnit;

  /// The day it was read, `YYYY-MM-DD`.
  final String occurredOn;

  /// Whether this is a work vehicle. Shortens the seeded intervals (§4.8.4).
  final bool isBusiness;

  /// This vehicle's distance unit, when it differs from the app's.
  final DistanceUnit? distanceUnit;

  /// Roughly how far this vehicle goes in a year — `AnnualBand`'s answer.
  ///
  /// The projection's fallback until there is enough odometer history to
  /// measure, which is SPEC.md §5's `assumed` rung. Null leaves the vehicle on
  /// the global 12,000 km/yr default, so a null here is not a neutral choice:
  /// it is a delivery driver and a pensioner getting the same guess.
  final Distance? expectedAnnual;

  /// Motorcycles only: whether it is liquid-cooled.
  ///
  /// §4.8.3 seeds `coolant` on a liquid-cooled motorcycle and never on an
  /// air-cooled one, and Odova stores no cooling field — so first run asks and
  /// the answer travels here rather than being guessed from the fuel kind.
  final bool liquidCooled;
}

/// Thrown inside `create`'s transaction when there is no settings row to
/// complete, so drift unwinds it and `create` answers with a typed failure.
///
/// A private exception rather than a `SqliteException` with a borrowed result
/// code: this is not a database error, and dressing it as one would put "the
/// disk is full" in front of a user whose disk is fine.
class _MissingSettings implements Exception {
  const _MissingSettings();
}
