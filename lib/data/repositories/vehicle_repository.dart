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
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/reminders/service_item_catalogue.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/distance.dart';
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
  }) => guardPersist(() async {
    final vehicle = Vehicle(
      id: VehicleId.tryParse('veh_${_ids.next()}')!,
      name: draft.name,
      vehicleType: draft.vehicleType,
      fuelKindDefault: draft.fuelKindDefault,
      status: VehicleStatus.active,
      isBusiness: draft.isBusiness,
      distanceUnit: draft.distanceUnit,
      createdAtUtcMs: nowUtcMs,
      updatedAtUtcMs: nowUtcMs,
    );

    await _db.transaction(() async {
      await _db.into(_db.vehicles).insert(_companionFor(vehicle));

      await _db
          .into(_db.odometerReadings)
          .insert(
            OdometerReadingsCompanion.insert(
              id: 'odo_${_ids.next()}',
              vehicleId: vehicle.id.toString(),
              occurredOn: draft.occurredOn,
              odometerM: metresColumn(draft.odometer),
              odometerUnit: draft.odometerUnit.wire,
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
        type: draft.vehicleType,
        fuel: draft.fuelKindDefault,
        isBusiness: draft.isBusiness,
        unit: draft.distanceUnit ?? draft.odometerUnit,
        liquidCooled: draft.liquidCooled,
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
                  seed.intervalDistanceM == null
                      ? null
                      : (draft.distanceUnit ?? draft.odometerUnit).wire,
                ),
                intervalMonths: Value(seed.intervalMonths),
                createdAtUtcMs: nowUtcMs,
                updatedAtUtcMs: nowUtcMs,
              ),
            );
      }
    });

    return Ok(vehicle);
  });

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
  Future<Result<void, PersistFailure>> markSold(
    VehicleId id, {
    required String soldOn,
    required int updatedAtUtcMs,
    int? soldPriceMinor,
  }) => _setStatus(
    id,
    VehiclesCompanion(
      status: Value(VehicleStatus.sold.wire),
      soldOn: Value(soldOn),
      soldPriceMinor: Value(soldPriceMinor),
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

  /// Motorcycles only: whether it is liquid-cooled.
  ///
  /// §4.8.3 seeds `coolant` on a liquid-cooled motorcycle and never on an
  /// air-cooled one, and Odova stores no cooling field — so first run asks and
  /// the answer travels here rather than being guessed from the fuel kind.
  final bool liquidCooled;
}

/// The five numbers `dialog.confirmDelete` states out loud.
typedef DeleteCounts = ({
  int fillUps,
  int services,
  int costs,
  int trips,
  int reminders,
});
