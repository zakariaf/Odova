/// Raw-SQL row builders for the schema tests.
///
/// Deliberately raw SQL rather than Drift's generated companions: these tests
/// assert what the SCHEMA refuses, and a generated companion would refuse a bad
/// enum value in Dart before SQLite ever saw it — which would make every
/// rejection test pass while proving nothing about the database. A row written
/// by an import, a migration or a future repository arrives as SQL.
///
/// **Every helper announces its table.** `customStatement` does not tell drift
/// which tables it touched, so a query somebody is already WATCHING is never
/// invalidated and keeps the answer it had before the insert. That is invisible
/// in a test that inserts first and subscribes afterwards, and it silently
/// breaks any test that subscribes first — which is every test about a stream
/// reacting to a write. `markTablesUpdated` is what a real insert does for
/// itself.
library;

import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:odova/data/db/app_database.dart';

/// Runs [sql] and tells drift which tables it touched.
Future<void> _write(
  AppDatabase db,
  String sql,
  List<Object?> variables,
  Iterable<TableInfo<Table, dynamic>> tables,
) async {
  await db.customStatement(sql, variables);
  db.markTablesUpdated(tables);
}

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
}) => _write(
  db,
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
  {db.vehicles},
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
}) => _write(
  db,
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
  {db.serviceItems},
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
  String? activeVehicleId,
  bool onboardingDone = false,
}) => _write(
  db,
  '''
    INSERT INTO settings (
      id, schema_version, language, calendar, numerals, first_day_of_week,
      theme, currency_default, currency_display, distance_unit, volume_unit,
      consumption_unit, notification_time_minutes, quiet_hours_from_minutes,
      quiet_hours_to_minutes, weekdays_only, notify_service, notify_odometer,
      notify_backup, onboarding_done, active_vehicle_id,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, 540, 1260, 480, 0, 1, 1, 1,
              ?, ?, 1000, 1000);
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
    if (onboardingDone) 1 else 0,
    activeVehicleId,
  ],
  {db.settingsTable},
);

/// Inserts a service record.
Future<void> insertServiceRecord(
  AppDatabase db, {
  String id = 'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String occurredOn = '2026-09-03',
  int? odometerM = 186512000,
}) => _write(
  db,
  '''
    INSERT INTO service_records (
      id, vehicle_id, occurred_on, odometer_m, odometer_unit,
      odometer_estimated, cost_estimated, created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, 'km', 0, 0, 1000, 1000);
  ''',
  [id, vehicleId, occurredOn, odometerM],
  {db.serviceRecords},
);

/// Inserts one line of a service record.
Future<void> insertServiceLine(
  AppDatabase db, {
  String id = 'lin_01K0C4V2H9B8N3Q7ZE5RY6TMWY',
  String serviceRecordId = 'srv_01K0C4V2H9B8N3Q7ZE5RY6TMWX',
  String? serviceItemId,
  String label = 'Oil and filter',
  int amountMinor = 8900,
  String currency = 'EUR',
}) => _write(
  db,
  '''
    INSERT INTO service_lines (
      id, service_record_id, service_item_id, label, amount_minor, currency
    ) VALUES (?, ?, ?, ?, ?, ?);
  ''',
  [id, serviceRecordId, serviceItemId, label, amountMinor, currency],
  {db.serviceLines},
);

/// Inserts a fill-up.
Future<void> insertFillUp(
  AppDatabase db, {
  String id = 'fil_01K1C4V2H9B8N3Q7ZE5RY6TMWX',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String occurredOn = '2026-09-03',
  String fuelKind = 'diesel',
  int? quantityMl = 45200,
  int? quantityG,
  int? energyWh,
  int totalCostMinor = 7845,
  String currency = 'EUR',
  String? tripId,
}) => _write(
  db,
  '''
    INSERT INTO fill_ups (
      id, vehicle_id, occurred_on, odometer_m, odometer_unit, fuel_kind,
      quantity_ml, quantity_g, energy_wh, quantity_unit, total_cost_minor,
      currency, is_full_tank, chain_broken, trip_id,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, 186512000, 'km', ?, ?, ?, ?, 'l', ?, ?, 1, 0, ?,
              1000, 1000);
  ''',
  [
    id,
    vehicleId,
    occurredOn,
    fuelKind,
    quantityMl,
    quantityG,
    energyWh,
    totalCostMinor,
    currency,
    tripId,
  ],
  {db.fillUps},
);

/// Inserts an odometer reading.
Future<void> insertReading(
  AppDatabase db, {
  String id = 'odo_01K1C4V2H9B8N3Q7ZE5RY6TMWY',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String occurredOn = '2026-09-03',
  int odometerM = 187412000,
  String odometerUnit = 'km',
  String source = 'manual',
}) => _write(
  db,
  '''
    INSERT INTO odometer_readings (
      id, vehicle_id, occurred_on, odometer_m, odometer_unit, source,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, ?, 1000, 1000);
  ''',
  [id, vehicleId, occurredOn, odometerM, odometerUnit, source],
  {db.odometerReadings},
);

/// Inserts an expense.
Future<void> insertExpense(
  AppDatabase db, {
  String id = 'exp_01K3C4V2H9B8N3Q7ZE5RY6TMWX',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String occurredOn = '2026-09-03',
  String category = 'insurance',
  String? label,
  int amountMinor = 42000,
  String currency = 'EUR',
  String? coversFrom,
  String? coversTo,
  String? tripId,
}) => _write(
  db,
  '''
    INSERT INTO expenses (
      id, vehicle_id, trip_id, occurred_on, category, label, amount_minor,
      currency, covers_from, covers_to, odometer_unit,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'km', 1000, 1000);
  ''',
  [
    id,
    vehicleId,
    tripId,
    occurredOn,
    category,
    label,
    amountMinor,
    currency,
    coversFrom,
    coversTo,
  ],
  {db.expenses},
);

/// Inserts a trip.
Future<void> insertTrip(
  AppDatabase db, {
  String id = 'trp_01K4C4V2H9B8N3Q7ZE5RY6TMWX',
  String vehicleId = 'veh_01JQ8ZK3M7F0R6XN2E9TB4HCVD',
  String purpose = 'business',
  String startedOn = '2026-09-01',
  String? endedOn = '2026-09-03',
  int? startOdometerM = 186000000,
  int? endOdometerM = 186512000,
  int? manualDistanceM,
}) => _write(
  db,
  '''
    INSERT INTO trips (
      id, vehicle_id, purpose, started_on, ended_on, start_odometer_m,
      end_odometer_m, manual_distance_m, odometer_unit,
      created_at_utc_ms, updated_at_utc_ms
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'km', 1000, 1000);
  ''',
  [
    id,
    vehicleId,
    purpose,
    startedOn,
    endedOn,
    startOdometerM,
    endOdometerM,
    manualDistanceM,
  ],
  {db.trips},
);
