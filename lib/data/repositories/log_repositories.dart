// Fill-ups, expenses and trips: the three logs with no decision in them.
//
// One file rather than three, because the three repositories are the same
// shape — scoped watch, insert-or-update inside one transaction, map to a
// domain model — and splitting them would be three copies of the same eight
// lines with different table names. `OdometerRepository` and
// `ServiceRepository` are separate because they carry rules; these do not.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/audit_mapper.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';
import 'package:odova/data/repositories/odometer_fan_out.dart';
import 'package:odova/data/repositories/watch.dart';

/// Reads and writes fill-ups.
class FillUpRepository {
  /// Creates a repository over [_db].
  ///
  /// [_ids] mints the id of the derived odometer reading this emits. SPEC.md
  /// §3: every record carrying an odometer emits one, and the fan-out is
  /// inside this repository's transaction so the pair is written together or
  /// not at all.
  const FillUpRepository(this._db, this._ids);

  final AppDatabase _db;
  final UlidFactory _ids;

  /// Every live fill-up for one vehicle, newest first.
  ///
  /// The order matches `idx_fillups_vehicle_date` exactly, so the page is an
  /// index read rather than a scan and a sort.
  Stream<List<FillUp>> watchForVehicle(VehicleId vehicleId) => watchList(
    _db.select(_db.fillUps)
      ..where(
        (f) =>
            f.vehicleId.equals(vehicleId.toString()) &
            f.deletedAtUtcMs.isNull(),
      )
      ..orderBy([
        (f) => OrderingTerm(
          expression: f.occurredOn,
          mode: OrderingMode.desc,
        ),
        (f) => OrderingTerm(expression: f.id, mode: OrderingMode.desc),
      ]),
    fillUpFromRow,
  );

  /// Writes [fillUp].
  Future<Result<FillUp, PersistFailure>> save(FillUp fillUp) =>
      guardPersist(() async {
        final refusal = await checkDerivedReading(
          _db,
          parentId: fillUp.id.toString(),
          vehicleId: fillUp.vehicleId,
          source: OdometerSource.fillUp,
          occurredOn: fillUp.occurredOn,
          odometerM: fillUp.odometer?.metres,
          nowUtcMs: fillUp.updatedAtUtcMs,
        );
        if (refusal != null) return Err(refusal);

        await _db.transaction(() async {
          await _db
              .into(_db.fillUps)
              .insertOnConflictUpdate(
                FillUpsCompanion.insert(
                  id: fillUp.id.toString(),
                  createdAtUtcMs: fillUp.createdAtUtcMs,
                  updatedAtUtcMs: fillUp.updatedAtUtcMs,
                  vehicleId: fillUp.vehicleId.toString(),
                  occurredOn: fillUp.occurredOn,
                  odometerM: Value(fillUp.odometer?.metres),
                  odometerUnit: fillUp.odometerUnit.wire,
                  fuelKind: fillUp.fuelKind.wire,
                  quantityMl: Value(millilitresColumn(fillUp.quantity)),
                  quantityG: Value(gramsColumn(fillUp.quantity)),
                  energyWh: Value(wattHoursColumn(fillUp.quantity)),
                  quantityUnit: fillUp.quantityUnit.wire,
                  totalCostMinor: fillUp.totalCost.amountMinor,
                  currency: fillUp.totalCost.currency.code,
                  isFullTank: Value(fillUp.isFullTank),
                  chainBroken: Value(fillUp.chainBroken),
                  grade: Value(fillUp.grade),
                  station: Value(fillUp.station),
                  tripId: Value(fillUp.tripId?.toString()),
                  notes: Value(fillUp.notes),
                ),
              );
          await syncDerivedReading(
            _db,
            ids: _ids,
            parentId: fillUp.id.toString(),
            vehicleId: fillUp.vehicleId,
            source: OdometerSource.fillUp,
            occurredOn: fillUp.occurredOn,
            odometerUnit: fillUp.odometerUnit,
            odometerM: fillUp.odometer?.metres,
            nowUtcMs: fillUp.updatedAtUtcMs,
          );
        });
        return Ok(fillUp);
      });
}

/// Reads and writes expenses.
class ExpenseRepository {
  /// Creates a repository over [_db].
  const ExpenseRepository(this._db, this._ids);

  final AppDatabase _db;
  final UlidFactory _ids;

  /// Every live expense for one vehicle, newest first.
  Stream<List<Expense>> watchForVehicle(VehicleId vehicleId) => watchList(
    _db.select(_db.expenses)
      ..where(
        (e) =>
            e.vehicleId.equals(vehicleId.toString()) &
            e.deletedAtUtcMs.isNull(),
      )
      ..orderBy([
        (e) => OrderingTerm(
          expression: e.occurredOn,
          mode: OrderingMode.desc,
        ),
        (e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc),
      ]),
    _expenseFromRow,
  );

  /// Writes [expense] and its derived odometer reading, together.
  Future<Result<Expense, PersistFailure>> save(
    Expense expense,
  ) => guardPersist(() async {
    final refusal = await checkDerivedReading(
      _db,
      parentId: expense.id.toString(),
      vehicleId: expense.vehicleId,
      source: OdometerSource.expense,
      occurredOn: expense.occurredOn,
      odometerM: expense.odometer?.metres,
      nowUtcMs: expense.updatedAtUtcMs,
    );
    if (refusal != null) return Err(refusal);

    await _db.transaction(() async {
      await _db
          .into(_db.expenses)
          .insertOnConflictUpdate(
            ExpensesCompanion.insert(
              id: expense.id.toString(),
              createdAtUtcMs: expense.createdAtUtcMs,
              updatedAtUtcMs: expense.updatedAtUtcMs,
              vehicleId: expense.vehicleId.toString(),
              tripId: Value(expense.tripId?.toString()),
              occurredOn: expense.occurredOn,
              category: expense.category.wire,
              label: Value(expense.label),
              amountMinor: expense.amount.amountMinor,
              currency: expense.amount.currency.code,
              coversFrom: Value(expense.coversFrom),
              coversTo: Value(expense.coversTo),
              odometerM: Value(expense.odometer?.metres),
              odometerUnit: expense.odometerUnit.wire,
              vendor: Value(expense.vendor),
              notes: Value(expense.notes),
            ),
          );
      // `odometerM` is nullable on an expense, and a null one emits NO
      // reading — `syncDerivedReading` removes any it had. An insurance
      // premium paid online has no odometer to record.
      await syncDerivedReading(
        _db,
        ids: _ids,
        parentId: expense.id.toString(),
        vehicleId: expense.vehicleId,
        source: OdometerSource.expense,
        occurredOn: expense.occurredOn,
        odometerUnit: expense.odometerUnit,
        odometerM: expense.odometer?.metres,
        nowUtcMs: expense.updatedAtUtcMs,
      );
    });
    return Ok(expense);
  });

  Expense _expenseFromRow(ExpenseRow row) {
    final times = repairAuditTimes(
      createdAtUtcMs: row.createdAtUtcMs,
      updatedAtUtcMs: row.updatedAtUtcMs,
    );

    return Expense(
      id: idFromStored(ExpenseId.tryParse, row.id),
      vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
      tripId: row.tripId == null
          ? null
          : idFromStored(TripId.tryParse, row.tripId!),
      occurredOn: row.occurredOn,
      category: enumFromWire(
        ExpenseCategory.values,
        (v) => v.wire,
        row.category,
      ),
      label: row.label,
      amount: moneyOf(row.amountMinor, row.currency),
      coversFrom: row.coversFrom,
      coversTo: row.coversTo,
      odometer: distanceOrNull(row.odometerM),
      odometerUnit: enumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        row.odometerUnit,
      ),
      vendor: row.vendor,
      notes: row.notes,
      createdAtUtcMs: times.createdAtUtcMs,
      updatedAtUtcMs: times.updatedAtUtcMs,
    );
  }
}

/// Reads and writes trips.
class TripRepository {
  /// Creates a repository over [_db].
  const TripRepository(this._db, this._ids);

  final AppDatabase _db;
  final UlidFactory _ids;

  /// Every live trip for one vehicle, newest first.
  Stream<List<Trip>> watchForVehicle(VehicleId vehicleId) => watchList(
    _db.select(_db.trips)
      ..where(
        (t) =>
            t.vehicleId.equals(vehicleId.toString()) &
            t.deletedAtUtcMs.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.startedOn,
          mode: OrderingMode.desc,
        ),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]),
    _tripFromRow,
  );

  /// Writes [trip] and its one or two derived odometer readings, together.
  Future<Result<Trip, PersistFailure>> save(
    Trip trip,
  ) => guardPersist(() async {
    // Both endpoints, because either can be the one that goes backwards.
    for (final (source, occurredOn, odometerM) in [
      (OdometerSource.tripStart, trip.startedOn, trip.startOdometer?.metres),
      (
        OdometerSource.tripEnd,
        trip.endedOn ?? trip.startedOn,
        trip.endedOn == null ? null : trip.endOdometer?.metres,
      ),
    ]) {
      final refusal = await checkDerivedReading(
        _db,
        parentId: trip.id.toString(),
        vehicleId: trip.vehicleId,
        source: source,
        occurredOn: occurredOn,
        odometerM: odometerM,
        nowUtcMs: trip.updatedAtUtcMs,
      );
      if (refusal != null) return Err(refusal);
    }

    await _db.transaction(() async {
      await _db
          .into(_db.trips)
          .insertOnConflictUpdate(
            TripsCompanion.insert(
              id: trip.id.toString(),
              createdAtUtcMs: trip.createdAtUtcMs,
              updatedAtUtcMs: trip.updatedAtUtcMs,
              vehicleId: trip.vehicleId.toString(),
              title: Value(trip.title),
              purpose: trip.purpose.wire,
              startedOn: trip.startedOn,
              endedOn: Value(trip.endedOn),
              startOdometerM: Value(trip.startOdometer?.metres),
              endOdometerM: Value(trip.endOdometer?.metres),
              manualDistanceM: Value(trip.manualDistance?.metres),
              odometerUnit: trip.odometerUnit.wire,
              notes: Value(trip.notes),
            ),
          );
      // TWO readings, and they differ by `source` alone — which is why the
      // fan-out keys on `(source_id, source)` rather than on the parent id.
      // An open trip has no end, so its end reading is removed rather than
      // left holding yesterday's number.
      await syncDerivedReading(
        _db,
        ids: _ids,
        parentId: trip.id.toString(),
        vehicleId: trip.vehicleId,
        source: OdometerSource.tripStart,
        occurredOn: trip.startedOn,
        odometerUnit: trip.odometerUnit,
        odometerM: trip.startOdometer?.metres,
        nowUtcMs: trip.updatedAtUtcMs,
      );
      await syncDerivedReading(
        _db,
        ids: _ids,
        parentId: trip.id.toString(),
        vehicleId: trip.vehicleId,
        source: OdometerSource.tripEnd,
        occurredOn: trip.endedOn ?? trip.startedOn,
        odometerUnit: trip.odometerUnit,
        odometerM: trip.endedOn == null ? null : trip.endOdometer?.metres,
        nowUtcMs: trip.updatedAtUtcMs,
      );
    });
    return Ok(trip);
  });

  Trip _tripFromRow(TripRow row) {
    final times = repairAuditTimes(
      createdAtUtcMs: row.createdAtUtcMs,
      updatedAtUtcMs: row.updatedAtUtcMs,
    );

    return Trip(
      id: idFromStored(TripId.tryParse, row.id),
      vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
      title: row.title,
      purpose: enumFromWire(TripPurpose.values, (v) => v.wire, row.purpose),
      startedOn: row.startedOn,
      endedOn: row.endedOn,
      startOdometer: distanceOrNull(row.startOdometerM),
      endOdometer: distanceOrNull(row.endOdometerM),
      manualDistance: distanceOrNull(row.manualDistanceM),
      odometerUnit: enumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        row.odometerUnit,
      ),
      notes: row.notes,
      createdAtUtcMs: times.createdAtUtcMs,
      updatedAtUtcMs: times.updatedAtUtcMs,
    );
  }
}
