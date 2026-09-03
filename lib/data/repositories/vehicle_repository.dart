// The vehicle write path.
//
// One rule runs through every repository in this directory: **persist first,
// republish second.** Every mutation is exactly one `db.transaction`, and the
// UI learns about it because the watched stream re-emits — never because the
// repository pushed an optimistic update. `error-handling-typed-results`
// rule 11, and the reason is that an optimistic update that a later constraint
// rejects leaves the screen showing a row the database does not have.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';

/// Reads and writes vehicles.
class VehicleRepository {
  /// Creates a repository over [_db].
  const VehicleRepository(this._db);

  final AppDatabase _db;

  /// Every live vehicle, in garage order.
  ///
  /// Soft-deleted rows are excluded HERE rather than at each call site, so
  /// "invisible everywhere immediately" is one filter and not a convention.
  Stream<List<Vehicle>> watchAll() =>
      (_db.select(_db.vehicles)
            ..where((v) => v.deletedAtUtcMs.isNull())
            ..orderBy([
              (v) => OrderingTerm(expression: v.sortOrder),
              (v) => OrderingTerm(expression: v.id),
            ]))
          .watch()
          .map((rows) => rows.map(vehicleFromRow).toList());

  /// One vehicle, or null while it does not exist.
  Stream<Vehicle?> watchOne(VehicleId id) =>
      (_db.select(_db.vehicles)..where(
            (v) => v.id.equals(id.toString()) & v.deletedAtUtcMs.isNull(),
          ))
          .watchSingleOrNull()
          .map((row) => row == null ? null : vehicleFromRow(row));

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
    purchaseOdometerM: Value(vehicle.purchaseOdometerM),
    purchasePriceMinor: Value(vehicle.purchasePriceMinor),
    purchasePriceCurrency: Value(vehicle.purchasePriceCurrency),
    status: vehicle.status.wire,
    soldOn: Value(vehicle.soldOn),
    soldPriceMinor: Value(vehicle.soldPriceMinor),
    soldPriceCurrency: Value(vehicle.soldPriceCurrency),
    expectedAnnualM: Value(vehicle.expectedAnnualM),
    colour: Value(vehicle.colour),
    notes: Value(vehicle.notes),
    sortOrder: Value(vehicle.sortOrder),
    notificationsMuted: Value(vehicle.notificationsMuted),
    currency: Value(vehicle.currency),
    distanceUnit: Value(vehicle.distanceUnit?.wire),
    volumeUnit: Value(vehicle.volumeUnit?.wire),
    consumptionUnit: Value(vehicle.consumptionUnit?.wire),
    noticeDistanceM: Value(vehicle.noticeDistanceM),
    noticeDays: Value(vehicle.noticeDays),
  );
}
