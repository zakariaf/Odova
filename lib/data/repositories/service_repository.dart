// Service items, records and their lines.
//
// One repository for three tables, because a record and its lines are ONE
// transaction. SPEC.md §3: a record has at least one line and its cost is the
// sum of them, so a record written without its lines is a record with no cost —
// and a half-written pair is worse than a rejected one.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/ids/ulid.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/value_equality.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/audit_mapper.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';
import 'package:odova/data/repositories/odometer_fan_out.dart';
import 'package:odova/data/repositories/watch.dart';

/// Reads and writes the service side of a vehicle.
class ServiceRepository {
  /// Creates a repository over [_db].
  const ServiceRepository(this._db, this._ids);

  final AppDatabase _db;
  final UlidFactory _ids;

  /// Every live service item for one vehicle.
  ///
  /// Scoped to the vehicle in the QUERY and de-duplicated with `distinct`, and
  /// both halves are load-bearing.
  ///
  /// Drift's stream invalidation is TABLE-level: any write to `service_items`
  /// re-runs every query over it, whatever its `WHERE` says. The scope keeps
  /// that re-run cheap — it is one indexed lookup rather than a scan — and
  /// `distinct` is what stops the SUBSCRIBER waking, because the models
  /// compare by value and an unchanged answer is equal to the last one. Without
  /// it, saving a service on the van rebuilds the Golf's screen.
  Stream<List<ServiceItem>> watchItems(VehicleId vehicleId) => watchList(
    _db.select(_db.serviceItems)
      ..where(
        (i) =>
            i.vehicleId.equals(vehicleId.toString()) &
            i.deletedAtUtcMs.isNull(),
      )
      ..orderBy([(i) => OrderingTerm(expression: i.id)]),
    _itemFromRow,
  );

  /// Every live service record for one vehicle, newest first, with its lines.
  Stream<List<ServiceRecord>> watchRecords(VehicleId vehicleId) {
    final records = _db.select(_db.serviceRecords)
      ..where(
        (r) =>
            r.vehicleId.equals(vehicleId.toString()) &
            r.deletedAtUtcMs.isNull(),
      )
      ..orderBy([
        (r) => OrderingTerm(
          expression: r.occurredOn,
          mode: OrderingMode.desc,
        ),
        (r) => OrderingTerm(expression: r.id, mode: OrderingMode.desc),
      ]);

    // TWO queries per emission, not 1 + N. The first version awaited
    // `_recordWithLines` per row, so sixty service records meant sixty-one
    // queries — and because drift's stream invalidation is table-level, all
    // sixty-one ran on every write to `service_records`, including for a
    // vehicle the user is not looking at, and BEFORE `distinct` could decide
    // nothing had changed.
    return records
        .watch()
        .asyncMap((rows) async => _withLines(rows))
        .distinct(valuesEqual);
  }

  /// [rows] as records, with every line fetched in one query and grouped.
  Future<List<ServiceRecord>> _withLines(List<ServiceRecordRow> rows) async {
    if (rows.isEmpty) return const [];

    final lines =
        await (_db.select(_db.serviceLines)
              ..where(
                (l) => l.serviceRecordId.isIn([for (final r in rows) r.id]),
              )
              ..orderBy([(l) => OrderingTerm(expression: l.id)]))
            .get();

    final byRecord = <String, List<ServiceLineRow>>{};
    for (final line in lines) {
      byRecord.putIfAbsent(line.serviceRecordId, () => []).add(line);
    }

    return [
      for (final row in rows) _recordFrom(row, byRecord[row.id] ?? const []),
    ];
  }

  /// Writes [record] and its lines as one transaction.
  ///
  /// All or nothing. Saving a record whose third line violates a `CHECK`
  /// leaves ZERO rows behind — the record included — rather than a record with
  /// two of its three lines, which would read back as a cheaper service than
  /// the one that happened.
  Future<Result<ServiceRecord, PersistFailure>> saveRecord(
    ServiceRecord record,
  ) => guardPersist(() async {
    if (record.lines.isEmpty) {
      // SQLite cannot express "at least one child row", so this is the one
      // invariant in the schema's contract that lives here. It is checked
      // BEFORE the transaction opens, so the failure carries the rule's name
      // rather than a driver message.
      return const Err(ConstraintViolated('service_record_needs_a_line'));
    }

    // Checked before the transaction opens: the reading this record emits has
    // to pass the same monotonicity guard a manual one does.
    final refusal = await checkDerivedReading(
      _db,
      parentId: record.id.toString(),
      vehicleId: record.vehicleId,
      source: OdometerSource.service,
      occurredOn: record.occurredOn,
      odometerM: record.odometer?.metres,
      nowUtcMs: record.updatedAtUtcMs,
    );
    if (refusal != null) return Err(refusal);

    await _db.transaction(() async {
      await _db
          .into(_db.serviceRecords)
          .insertOnConflictUpdate(_recordCompanion(record));
      // Replace rather than merge: a line removed in the editor has to
      // disappear, and a diff would need a second source of truth about which
      // lines existed.
      await (_db.delete(_db.serviceLines)..where(
            (l) => l.serviceRecordId.equals(record.id.toString()),
          ))
          .go();
      for (final line in record.lines) {
        await _db.into(_db.serviceLines).insert(_lineCompanion(line));
      }
      await syncDerivedReading(
        _db,
        ids: _ids,
        parentId: record.id.toString(),
        vehicleId: record.vehicleId,
        source: OdometerSource.service,
        occurredOn: record.occurredOn,
        odometerUnit: record.odometerUnit,
        odometerM: record.odometer?.metres,
        nowUtcMs: record.updatedAtUtcMs,
      );
    });

    return Ok(record);
  });

  /// Writes [item].
  Future<Result<ServiceItem, PersistFailure>> saveItem(ServiceItem item) =>
      guardPersist(() async {
        await _db.transaction(() async {
          await _db
              .into(_db.serviceItems)
              .insertOnConflictUpdate(_itemCompanion(item));
        });
        return Ok(item);
      });

  /// Reads one record with its lines.
  Future<Result<ServiceRecord, PersistFailure>> findRecordById(
    ServiceRecordId id,
  ) => guardPersist(() async {
    final row =
        await (_db.select(_db.serviceRecords)..where(
              (r) => r.id.equals(id.toString()) & r.deletedAtUtcMs.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) return Err(NotFound(id.toString()));
    return Ok(await _recordWithLines(row));
  });

  Future<ServiceRecord> _recordWithLines(ServiceRecordRow row) async {
    final lines =
        await (_db.select(_db.serviceLines)
              ..where((l) => l.serviceRecordId.equals(row.id))
              ..orderBy([(l) => OrderingTerm(expression: l.id)]))
            .get();
    return _recordFrom(row, lines);
  }

  /// One record and the lines already fetched for it.
  ServiceRecord _recordFrom(ServiceRecordRow row, List<ServiceLineRow> lines) {
    final times = repairAuditTimes(
      createdAtUtcMs: row.createdAtUtcMs,
      updatedAtUtcMs: row.updatedAtUtcMs,
    );

    return ServiceRecord(
      id: idFromStored(ServiceRecordId.tryParse, row.id),
      vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
      occurredOn: row.occurredOn,
      odometer: distanceOrNull(row.odometerM),
      odometerUnit: enumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        row.odometerUnit,
      ),
      odometerEstimated: row.odometerEstimated,
      costEstimated: row.costEstimated,
      vendor: row.vendor,
      invoiceRef: row.invoiceRef,
      warrantyUntil: row.warrantyUntil,
      notes: row.notes,
      lines: lines.map(_lineFromRow).toList(),
      createdAtUtcMs: times.createdAtUtcMs,
      updatedAtUtcMs: times.updatedAtUtcMs,
    );
  }

  ServiceLine _lineFromRow(ServiceLineRow row) => ServiceLine(
    id: idFromStored(ServiceLineId.tryParse, row.id),
    serviceRecordId: idFromStored(
      ServiceRecordId.tryParse,
      row.serviceRecordId,
    ),
    serviceItemId: row.serviceItemId == null
        ? null
        : idFromStored(ServiceItemId.tryParse, row.serviceItemId!),
    label: row.label,
    amount: moneyOf(row.amountMinor, row.currency),
    partNumber: row.partNumber,
    notes: row.notes,
  );

  ServiceItem _itemFromRow(ServiceItemRow row) {
    final times = repairAuditTimes(
      createdAtUtcMs: row.createdAtUtcMs,
      updatedAtUtcMs: row.updatedAtUtcMs,
    );

    return ServiceItem(
      id: idFromStored(ServiceItemId.tryParse, row.id),
      vehicleId: idFromStored(VehicleId.tryParse, row.vehicleId),
      kind: enumFromWire(ServiceKind.values, (v) => v.wire, row.kind),
      label: row.label,
      intervalDistance: distanceOrNull(row.intervalDistanceM),
      intervalDistanceUnit: optionalEnumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        row.intervalDistanceUnit,
      ),
      intervalMonths: row.intervalMonths,
      targetOdometer: distanceOrNull(row.targetOdometerM),
      targetDate: row.targetDate,
      baselineDate: row.baselineDate,
      baselineOdometer: distanceOrNull(row.baselineOdometerM),
      noticeDistance: distanceOrNull(row.noticeDistanceM),
      noticeDays: row.noticeDays,
      isTracked: row.isTracked,
      isActive: row.isActive,
      notify: row.notify,
      priority: enumFromWire(
        ServicePriority.values,
        (v) => v.wire,
        row.priority,
      ),
      rollover: enumFromWire(
        ServiceRollover.values,
        (v) => v.wire,
        row.rollover,
      ),
      repeats: row.repeats,
      snoozedUntil: row.snoozedUntil,
      snoozeUntilOdometer: distanceOrNull(row.snoozeUntilOdometerM),
      snoozeCount: row.snoozeCount,
      notes: row.notes,
      createdAtUtcMs: times.createdAtUtcMs,
      updatedAtUtcMs: times.updatedAtUtcMs,
    );
  }

  ServiceRecordsCompanion _recordCompanion(ServiceRecord record) =>
      ServiceRecordsCompanion.insert(
        id: record.id.toString(),
        createdAtUtcMs: record.createdAtUtcMs,
        updatedAtUtcMs: record.updatedAtUtcMs,
        vehicleId: record.vehicleId.toString(),
        occurredOn: record.occurredOn,
        odometerM: Value(record.odometer?.metres),
        odometerUnit: record.odometerUnit.wire,
        odometerEstimated: Value(record.odometerEstimated),
        costEstimated: Value(record.costEstimated),
        vendor: Value(record.vendor),
        invoiceRef: Value(record.invoiceRef),
        warrantyUntil: Value(record.warrantyUntil),
        notes: Value(record.notes),
      );

  ServiceLinesCompanion _lineCompanion(ServiceLine line) =>
      ServiceLinesCompanion.insert(
        id: line.id.toString(),
        serviceRecordId: line.serviceRecordId.toString(),
        serviceItemId: Value(line.serviceItemId?.toString()),
        label: line.label,
        amountMinor: line.amount.amountMinor,
        currency: line.amount.currency.code,
        partNumber: Value(line.partNumber),
        notes: Value(line.notes),
      );

  ServiceItemsCompanion _itemCompanion(ServiceItem item) =>
      ServiceItemsCompanion.insert(
        id: item.id.toString(),
        createdAtUtcMs: item.createdAtUtcMs,
        updatedAtUtcMs: item.updatedAtUtcMs,
        vehicleId: item.vehicleId.toString(),
        kind: item.kind.wire,
        label: Value(item.label),
        intervalDistanceM: Value(item.intervalDistance?.metres),
        intervalDistanceUnit: Value(item.intervalDistanceUnit?.wire),
        intervalMonths: Value(item.intervalMonths),
        targetOdometerM: Value(item.targetOdometer?.metres),
        targetDate: Value(item.targetDate),
        baselineDate: Value(item.baselineDate),
        baselineOdometerM: Value(item.baselineOdometer?.metres),
        noticeDistanceM: Value(item.noticeDistance?.metres),
        noticeDays: Value(item.noticeDays),
        isTracked: Value(item.isTracked),
        isActive: Value(item.isActive),
        notify: Value(item.notify),
        priority: item.priority.wire,
        rollover: item.rollover.wire,
        repeats: Value(item.repeats),
        snoozedUntil: Value(item.snoozedUntil),
        snoozeUntilOdometerM: Value(item.snoozeUntilOdometer?.metres),
        snoozeCount: Value(item.snoozeCount),
        notes: Value(item.notes),
      );
}
