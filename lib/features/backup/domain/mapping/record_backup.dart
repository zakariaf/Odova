// Every record type, as SPEC.md §6 §2.5 writes it.
//
// One pure projection per entity. §6 §2.4 is a MAPPING and never a second
// model — a `BackupFillUp` class would be a second place for a field to be
// added, and the one that got forgotten would be the one silently dropped from
// every backup a user ever made.
//
// The key ORDER in each object is the spec's, and it is load-bearing: §6 §2.6
// makes a streaming reader's one-pass reference resolution depend on it.
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/features/backup/domain/mapping/backup_values.dart';

/// One reminder — §3's `ServiceItem`.
///
/// [lastDone] carries §6's three DERIVED fields, which are listed in the
/// envelope's `derived_fields` so a reader knows to recompute them. They are
/// written anyway because a human opening the file can then see what the app
/// concluded, and because a service history with no "last done" beside each
/// reminder is a file that answers the wrong question.
///
/// There is no `rule`, no `mode` and no stored next-due. §1 forbids persisting
/// a derived value, and a stored due date survives an import and is then wrong
/// for ever — which is the one failure that would make the whole file
/// dangerous rather than merely incomplete.
Map<String, Object?> reminderBackupJson(
  ServiceItem item, {
  ({String? date, int? odometerM, String? serviceId}) lastDone = (
    date: null,
    odometerM: null,
    serviceId: null,
  ),
}) => {
  'id': item.id.toString(),
  'vehicle_id': item.vehicleId.toString(),
  'kind': item.kind.wire,
  'label': item.label,
  'interval_distance_m': metresOrNull(item.intervalDistance),
  'interval_distance_unit': item.intervalDistanceUnit?.wire,
  'interval_months': item.intervalMonths,
  'target_odometer_m': metresOrNull(item.targetOdometer),
  'target_date': item.targetDate,
  'baseline_date': item.baselineDate,
  'baseline_odometer_m': metresOrNull(item.baselineOdometer),
  'notify': item.notify,
  'priority': item.priority.wire,
  'rollover': item.rollover.wire,
  'repeats': item.repeats,
  'is_tracked': item.isTracked,
  'is_active': item.isActive,
  'notice_distance_m': metresOrNull(item.noticeDistance),
  'notice_days': item.noticeDays,
  'snoozed_until': item.snoozedUntil,
  'snooze_until_odometer_m': metresOrNull(item.snoozeUntilOdometer),
  'snooze_count': item.snoozeCount,
  'last_done_date': lastDone.date,
  'last_done_odometer_m': lastDone.odometerM,
  'last_done_service_id': lastDone.serviceId,
  'notes': item.notes,
  'created_at': rfc3339(item.createdAtUtcMs),
  'updated_at': rfc3339(item.updatedAtUtcMs),
  'deleted_at': null,
};

/// One odometer reading.
///
/// STANDALONE readings only, and `source_id` is omitted. §6 §7: a reading a
/// fill-up emitted is re-derived from the fill-up on import, so exporting it
/// would duplicate every fill's reading on the next round trip — the record
/// count would grow on every export/import cycle, which is the shape of data
/// corruption nobody notices for a year.
Map<String, Object?> odometerReadingBackupJson(OdometerReading reading) => {
  'id': reading.id.toString(),
  'vehicle_id': reading.vehicleId.toString(),
  'occurred_on': reading.occurredOn,
  'odometer_m': reading.odometer.metres,
  'odometer_unit': reading.odometerUnit.wire,
  'source': reading.source.wire,
  'notes': reading.notes,
  'created_at': rfc3339(reading.createdAtUtcMs),
  'updated_at': rfc3339(reading.updatedAtUtcMs),
  'deleted_at': null,
};

/// One odometer correction.
Map<String, Object?> odometerCorrectionBackupJson(
  OdometerCorrection correction,
) => {
  'id': correction.id.toString(),
  'vehicle_id': correction.vehicleId.toString(),
  'from_reading_id': correction.fromReadingId.toString(),
  'previous_m': correction.previous.metres,
  'replacement_m': correction.replacement.metres,
  'odometer_unit': correction.odometerUnit.wire,
  'reason': correction.reason.wire,
  'notes': correction.notes,
  'created_at': rfc3339(correction.createdAtUtcMs),
  'updated_at': rfc3339(correction.updatedAtUtcMs),
  'deleted_at': null,
};

/// One fill-up.
Map<String, Object?> fillUpBackupJson(FillUp fill) => {
  'id': fill.id.toString(),
  'vehicle_id': fill.vehicleId.toString(),
  'occurred_on': fill.occurredOn,
  'odometer_m': metresOrNull(fill.odometer),
  'odometer_unit': fill.odometerUnit.wire,
  'quantity_ml': fill.quantity?.amount,
  'quantity_unit': fill.quantityUnit.wire,
  'total_cost': moneyJson(fill.totalCost),
  'is_full_tank': fill.isFullTank,
  'chain_broken': fill.chainBroken,
  'fuel_kind': fill.fuelKind.wire,
  'station': fill.station,
  'grade': fill.grade,
  'notes': fill.notes,
  'trip_id': fill.tripId?.toString(),
  'created_at': rfc3339(fill.createdAtUtcMs),
  'updated_at': rfc3339(fill.updatedAtUtcMs),
  'deleted_at': null,
};

/// One service line.
///
/// The amount is written FLAT — `amount_minor` and `currency` as siblings —
/// which is §6 §2.5's shape for a line and differs from the nested
/// `{amount_minor, currency}` object every other money field uses. Followed
/// rather than normalised: the spec is the format, and a reader written
/// against it would refuse a document that "improved" on it.
Map<String, Object?> serviceLineBackupJson(ServiceLine line) => {
  'id': line.id.toString(),
  'service_item_id': line.serviceItemId?.toString(),
  'label': line.label,
  'amount_minor': line.amount.amountMinor,
  'currency': line.amount.currency.code,
  'part_number': line.partNumber,
  'notes': line.notes,
};

/// One service record, with its lines nested.
///
/// NO `total_cost`, `parts_cost` or `labour_cost`. §6 §7: the cost is the sum
/// of the lines, and a stored total is a derived value that survives an import
/// and then disagrees with the lines under it for ever.
Map<String, Object?> serviceBackupJson(ServiceRecord record) => {
  'id': record.id.toString(),
  'vehicle_id': record.vehicleId.toString(),
  'occurred_on': record.occurredOn,
  'odometer_m': metresOrNull(record.odometer),
  'odometer_unit': record.odometerUnit.wire,
  'odometer_estimated': record.odometerEstimated,
  'cost_estimated': record.costEstimated,
  'lines': [for (final line in record.lines) serviceLineBackupJson(line)],
  'vendor': record.vendor,
  'invoice_ref': record.invoiceRef,
  'warranty_until': record.warrantyUntil,
  'notes': record.notes,
  'created_at': rfc3339(record.createdAtUtcMs),
  'updated_at': rfc3339(record.updatedAtUtcMs),
  'deleted_at': null,
};

/// One expense.
Map<String, Object?> expenseBackupJson(Expense expense) => {
  'id': expense.id.toString(),
  'vehicle_id': expense.vehicleId.toString(),
  'occurred_on': expense.occurredOn,
  'odometer_m': metresOrNull(expense.odometer),
  'odometer_unit': expense.odometerUnit.wire,
  'category': expense.category.wire,
  'label': expense.label,
  // The one money field in the app that may be NEGATIVE — §10 gives the
  // refund switch its sign — and the pair carries that through unchanged.
  'amount': moneyJson(expense.amount),
  'vendor': expense.vendor,
  'notes': expense.notes,
  'covers_from': expense.coversFrom,
  'covers_to': expense.coversTo,
  'trip_id': expense.tripId?.toString(),
  'created_at': rfc3339(expense.createdAtUtcMs),
  'updated_at': rfc3339(expense.updatedAtUtcMs),
  'deleted_at': null,
};

/// One trip.
Map<String, Object?> tripBackupJson(Trip trip) => {
  'id': trip.id.toString(),
  'vehicle_id': trip.vehicleId.toString(),
  'title': trip.title,
  'purpose': trip.purpose.wire,
  'started_on': trip.startedOn,
  'ended_on': trip.endedOn,
  'start_odometer_m': metresOrNull(trip.startOdometer),
  'end_odometer_m': metresOrNull(trip.endOdometer),
  'odometer_unit': trip.odometerUnit.wire,
  'manual_distance_m': metresOrNull(trip.manualDistance),
  'notes': trip.notes,
  'created_at': rfc3339(trip.createdAtUtcMs),
  'updated_at': rfc3339(trip.updatedAtUtcMs),
  'deleted_at': null,
};
