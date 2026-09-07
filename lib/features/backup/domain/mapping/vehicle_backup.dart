// One vehicle, as SPEC.md §6 §2.5 writes it.
//
// A pure projection from the domain type. §6 §2.4 is a MAPPING and never a
// second model: a `BackupVehicle` class would be a second place for a field to
// be added, and the one that got forgotten would be the one silently dropped
// from every backup.
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/features/backup/domain/mapping/backup_values.dart';

/// [vehicle] as its JSON object, in §6 §2.5's key order.
///
/// The per-vehicle unit and currency overrides are written as NULL where they
/// are inherited, never materialised to whatever the app defaults happened to
/// be. Materialising them would pin every vehicle in the file to today's
/// settings, so a user who exports, changes their default currency and
/// imports gets a garage of vehicles each frozen at the old one — an override
/// nobody set and nobody can see they have.
Map<String, Object?> vehicleBackupJson(Vehicle vehicle) => {
  'id': vehicle.id.toString(),
  'name': vehicle.name,
  'make': vehicle.make,
  'model': vehicle.model,
  'year': vehicle.year,
  'plate': vehicle.plate,
  'vin': vehicle.vin,
  'vehicle_type': vehicle.vehicleType.wire,
  'fuel_kind_default': vehicle.fuelKindDefault.wire,
  'is_business': vehicle.isBusiness,
  'tank_capacity_ml': vehicle.tankCapacityMl,
  'distance_unit': vehicle.distanceUnit?.wire,
  'volume_unit': vehicle.volumeUnit?.wire,
  'consumption_unit': vehicle.consumptionUnit?.wire,
  'currency': vehicle.currency?.code,
  'expected_annual_m': metresOrNull(vehicle.expectedAnnual),
  'notice_distance_m': metresOrNull(vehicle.noticeDistance),
  'notice_days': vehicle.noticeDays,
  // The THREE-VALUED status, not the boolean it replaced. §3: `sold` means
  // gone and `archived` means off the road, and they compute differently —
  // a sold vehicle produces no reminders at all. A backup carrying the old
  // boolean would import every sold car as merely archived and start
  // reminding its former owner about it.
  'status': vehicle.status.wire,
  'sold_on': vehicle.soldOn,
  'sold_price': moneyJsonOrNull(vehicle.soldPrice),
  'purchase_date': vehicle.purchaseDate,
  'purchase_odometer_m': metresOrNull(vehicle.purchaseOdometer),
  'purchase_price': moneyJsonOrNull(vehicle.purchasePrice),
  'notifications_muted': vehicle.notificationsMuted,
  'sort_order': vehicle.sortOrder,
  'colour': vehicle.colour,
  'notes': vehicle.notes,
  'created_at': rfc3339(vehicle.createdAtUtcMs),
  'updated_at': rfc3339(vehicle.updatedAtUtcMs),
  // Always null in a backup: §6 §7 excludes deleted rows entirely, so a
  // `deleted_at` that was not null would mean the writer had exported
  // something it should have skipped. Written rather than omitted so the
  // shape is uniform and a reader never has to ask whether a missing key
  // means "not deleted" or "this writer did not know about deletion".
  'deleted_at': null,
};
