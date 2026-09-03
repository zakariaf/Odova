/// Raw-SQL row builders for the schema tests.
///
/// Deliberately raw SQL rather than Drift's generated companions: these tests
/// assert what the SCHEMA refuses, and a generated companion would refuse a bad
/// enum value in Dart before SQLite ever saw it — which would make every
/// rejection test pass while proving nothing about the database. A row written
/// by an import, a migration or a future repository arrives as SQL.
library;

import 'package:odova/data/db/app_database.dart';

/// Inserts a vehicle, defaulting everything the table does not require.
Future<void> insertVehicle(
  AppDatabase db, {
  String id = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String name = 'The Golf',
  String vehicleType = 'car',
  String status = 'active',
  String fuelKind = 'diesel',
  int? tankCapacityMl,
  int createdAtUtcMs = 1000,
  int? updatedAtUtcMs,
}) => db.customStatement(
  '''
    INSERT INTO vehicles (
      id, name, vehicle_type, is_business, fuel_kind_default, status,
      sort_order, notifications_muted, tank_capacity_ml,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, 0, ?, ?, 0, 0, ?, ?, ?);
  ''',
  [
    id,
    name,
    vehicleType,
    fuelKind,
    status,
    tankCapacityMl,
    createdAtUtcMs,
    updatedAtUtcMs ?? createdAtUtcMs,
  ],
);

/// Inserts a service item against [vehicleId].
Future<void> insertServiceItem(
  AppDatabase db, {
  String id = 'rem_01JV7B5X4G2K9M6P0S3D8FNRTC',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String kind = 'oil_and_filter',
  String? label,
  int? intervalDistanceM = 15000000,
  int? intervalMonths,
  int? targetOdometerM,
  String? targetDate,
  String priority = 'normal',
  String rollover = 'from_actual',
  int createdAtUtcMs = 1000,
}) => db.customStatement(
  '''
    INSERT INTO service_items (
      id, vehicle_id, kind, label,
      interval_distance_m, interval_months, target_odometer_m, target_date,
      is_tracked, is_active, notify, priority, rollover, repeats, snooze_count,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, 1, ?, ?, 1, 0, ?, ?);
  ''',
  [
    id,
    vehicleId,
    kind,
    label,
    intervalDistanceM,
    intervalMonths,
    targetOdometerM,
    targetDate,
    priority,
    rollover,
    createdAtUtcMs,
    createdAtUtcMs,
  ],
);

/// Inserts the settings singleton.
Future<void> insertSettings(
  AppDatabase db, {
  String id = 'settings',
  String language = 'system',
  String calendar = 'gregorian',
  String numerals = 'auto',
  String theme = 'system',
  String currencyDefault = 'EUR',
  String currencyDisplay = 'none',
  String distanceUnit = 'km',
  String volumeUnit = 'l',
  String consumptionUnit = 'l_100km',
  int schemaVersion = 1,
}) => db.customStatement(
  '''
    INSERT INTO settings (
      id, schema_version, language, calendar, numerals, first_day_of_week,
      theme, currency_default, currency_display, distance_unit, volume_unit,
      consumption_unit, notification_time_minutes, quiet_hours_from_minutes,
      quiet_hours_to_minutes, weekdays_only, notify_service, notify_odometer,
      notify_backup, onboarding_done, created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, 540, 1260, 480, 0, 1, 1, 1,
              0, 1000, 1000);
  ''',
  [
    id,
    schemaVersion,
    language,
    calendar,
    numerals,
    theme,
    currencyDefault,
    currencyDisplay,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
  ],
);
