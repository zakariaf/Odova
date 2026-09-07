// Schema v1's raw rows, projected into SPEC.md §6's file format.
//
// This is what makes the pre-migration safety copy a copy the user can
// actually USE. §6.4.4 calls it the escape route; a raw table dump is not one,
// because nothing in the app can read it back. What is written here goes
// through `BackupReader` like any other file.
//
// EVERY CONSTANT HERE IS PINNED TO v1 AND MUST NEVER TRACK A MOVING ONE.
// `kBackupFormat` and `kSupportedFormatVersion` live in the backup feature and
// will change when the format does; this file describes what a v1 DATABASE
// looks like as a v1 FILE, forever. Importing those constants would mean a v5
// binary stamping `format_version: 5` on a document built from v1 columns —
// the exact misreading the numbered readers exist to prevent.
//
// It also imports nothing from `lib/features` and nothing from the current
// mappers, for the same reason: a copy taken through the code that is about to
// migrate is a copy taken through the crash.
import 'package:odova/core/export/export_stamp.dart';
import 'package:odova/data/db/schema_readers/schema_reader.dart';

/// v1's own value for the envelope's `format_version`. Never a constant that
/// moves.
const int kSchemaV1FormatVersion = 1;

/// [raw] — a [SchemaReader] result for v1 — as §6's backup document.
///
/// [stamp] fills the envelope. Passed in rather than read, because this runs
/// during a migration and a function that reads the clock is a function a test
/// cannot pin — and because four loose parameters with defaults is how the
/// production caller ended up stamping every real copy with 1970.
Map<String, Object?> schemaV1BackupDocument(
  Map<String, Object?> raw,
  ExportStamp stamp,
) {
  final tables = raw['tables'] is Map<String, Object?>
      ? raw['tables']! as Map<String, Object?>
      : const <String, Object?>{};

  List<Map<String, Object?>> rows(String table) => [
    for (final row in tables[table] is List ? tables[table]! as List : const [])
      if (row is Map<String, Object?> && row['deleted_at_utc_ms'] == null) row,
  ];

  final lines = <String, List<Map<String, Object?>>>{};
  for (final line in rows('service_lines')) {
    final owner = line['service_record_id'];
    if (owner is String) (lines[owner] ??= []).add(line);
  }

  final settingsRow = rows('settings');
  final document = <String, Object?>{
    'format': 'odova.backup',
    'format_version': kSchemaV1FormatVersion,
    'app_version': stamp.appVersion,
    'app_build': stamp.appBuild,
    'platform': stamp.platform,
    'exported_at': _rfc3339(stamp.nowUtcMs),
    'exported_at_local': _rfc3339(stamp.nowUtcMs),
    'units': const {
      'distance': 'm',
      'volume': 'ml',
      'mass': 'g',
      'energy': 'wh',
      'money': 'minor',
    },
    'derived_fields': const <String>[],
    'record_counts': const <String, Object?>{},
    'content_hash': null,
    'settings': settingsRow.isEmpty
        ? const <String, Object?>{}
        : _settings(settingsRow.first),
    'vehicles': rows('vehicles').map(_vehicle).toList(),
    'reminders': rows('service_items').map(_reminder).toList(),
    // §6 §7: only STANDALONE readings. One a fill-up emitted is re-derived on
    // import, and exporting it would grow the record count on every cycle.
    'odometer_readings': [
      for (final row in rows('odometer_readings'))
        if (row['source'] == 'manual') _reading(row),
    ],
    'odometer_corrections': rows(
      'odometer_corrections',
    ).map(_correction).toList(),
    'fillups': rows('fill_ups').map(_fillUp).toList(),
    'services': [
      for (final row in rows('service_records'))
        _service(row, lines[row['id']] ?? const []),
    ],
    'expenses': rows('expenses').map(_expense).toList(),
    'trips': rows('trips').map(_trip).toList(),
  };

  return {...document, 'record_counts': _counts(document)};
}

Map<String, Object?> _counts(Map<String, Object?> document) {
  const arrays = [
    'vehicles',
    'reminders',
    'odometer_readings',
    'odometer_corrections',
    'fillups',
    'services',
    'expenses',
    'trips',
  ];
  final counts = <String, int>{
    for (final array in arrays) array: (document[array]! as List).length,
  };
  return {
    ...counts,
    'total': counts.values.fold<int>(0, (sum, n) => sum + n),
  };
}

Map<String, Object?> _vehicle(Map<String, Object?> r) => {
  'id': r['id'],
  'name': r['name'],
  'make': r['make'],
  'model': r['model'],
  'year': r['year'],
  'plate': r['plate'],
  'vin': r['vin'],
  'type': r['vehicle_type'],
  'is_business': _bool(r['is_business']),
  'fuel_kind_default': r['fuel_kind_default'],
  'tank_capacity_ml': r['tank_capacity_ml'],
  'purchase_date': r['purchase_date'],
  'purchase_odometer_m': r['purchase_odometer_m'],
  'purchase_price': _money(
    r['purchase_price_minor'],
    r['purchase_price_currency'],
  ),
  'status': r['status'],
  'sold_on': r['sold_on'],
  'sold_price': _money(r['sold_price_minor'], r['sold_price_currency']),
  'expected_annual_m': r['expected_annual_m'],
  'colour': r['colour'],
  'notes': r['notes'],
  'sort_order': r['sort_order'],
  'notifications_muted': _bool(r['notifications_muted']),
  'currency': r['currency'],
  'distance_unit': r['distance_unit'],
  'volume_unit': r['volume_unit'],
  'consumption_unit': r['consumption_unit'],
  'notice_distance_m': r['notice_distance_m'],
  'notice_days': r['notice_days'],
  ..._audit(r),
};

Map<String, Object?> _reminder(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'kind': r['kind'],
  'label': r['label'],
  'interval_distance_m': r['interval_distance_m'],
  'interval_distance_unit': r['interval_distance_unit'],
  'interval_months': r['interval_months'],
  'target_odometer_m': r['target_odometer_m'],
  'target_date': r['target_date'],
  'baseline_date': r['baseline_date'],
  'baseline_odometer_m': r['baseline_odometer_m'],
  'notice_distance_m': r['notice_distance_m'],
  'notice_days': r['notice_days'],
  'is_tracked': _bool(r['is_tracked']),
  'is_active': _bool(r['is_active']),
  'notify': _bool(r['notify']),
  'priority': r['priority'],
  'rollover': r['rollover'],
  'repeats': _bool(r['repeats']),
  'snoozed_until': r['snoozed_until'],
  'snooze_until_odometer_m': r['snooze_until_odometer_m'],
  'snooze_count': r['snooze_count'],
  'notes': r['notes'],
  ..._audit(r),
};

Map<String, Object?> _reading(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'occurred_on': r['occurred_on'],
  'odometer_m': r['odometer_m'],
  'odometer_unit': r['odometer_unit'],
  'source': r['source'],
  'notes': r['notes'],
  ..._audit(r),
};

Map<String, Object?> _correction(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'from_reading_id': r['from_reading_id'],
  'previous_m': r['previous_m'],
  // The COLUMN is `new_m` and the field is `replacement_m`. `new` is a
  // reserved word in enough languages that the file avoids it; the column
  // predates that decision and cannot be renamed without a migration.
  'replacement_m': r['new_m'],
  'odometer_unit': r['odometer_unit'],
  'reason': r['reason'],
  'notes': r['notes'],
  ..._audit(r),
};

Map<String, Object?> _fillUp(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'occurred_on': r['occurred_on'],
  'odometer_m': r['odometer_m'],
  'odometer_unit': r['odometer_unit'],
  // Exactly one of the three, chosen by which column is filled — never all
  // three, and never the wrong one. Writing watt-hours into `quantity_ml`
  // would turn an EV charge into litres of diesel on the way back in.
  if (r['quantity_g'] != null)
    'quantity_g': r['quantity_g']
  else if (r['energy_wh'] != null)
    'energy_wh': r['energy_wh']
  else
    'quantity_ml': r['quantity_ml'],
  'quantity_unit': r['quantity_unit'],
  'total_cost': _money(r['total_cost_minor'], r['currency']),
  'is_full_tank': _bool(r['is_full_tank']),
  'chain_broken': _bool(r['chain_broken']),
  'fuel_kind': r['fuel_kind'],
  'station': r['station'],
  'grade': r['grade'],
  'notes': r['notes'],
  'trip_id': r['trip_id'],
  ..._audit(r),
};

Map<String, Object?> _service(
  Map<String, Object?> r,
  List<Map<String, Object?>> lines,
) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'occurred_on': r['occurred_on'],
  'odometer_m': r['odometer_m'],
  'odometer_unit': r['odometer_unit'],
  'odometer_estimated': _bool(r['odometer_estimated']),
  'cost_estimated': _bool(r['cost_estimated']),
  // Flat `amount_minor` and `currency`, which is §6 §2.5's shape for a line
  // and differs from every other money field on purpose.
  'lines': [
    for (final line in lines)
      {
        'id': line['id'],
        'service_item_id': line['service_item_id'],
        'label': line['label'],
        'amount_minor': line['amount_minor'],
        'currency': line['currency'],
        'part_number': line['part_number'],
        'notes': line['notes'],
      },
  ],
  'vendor': r['vendor'],
  'invoice_ref': r['invoice_ref'],
  'warranty_until': r['warranty_until'],
  'notes': r['notes'],
  ..._audit(r),
};

Map<String, Object?> _expense(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'occurred_on': r['occurred_on'],
  'odometer_m': r['odometer_m'],
  'odometer_unit': r['odometer_unit'],
  'category': r['category'],
  'label': r['label'],
  'amount': _money(r['amount_minor'], r['currency']),
  'vendor': r['vendor'],
  'notes': r['notes'],
  'covers_from': r['covers_from'],
  'covers_to': r['covers_to'],
  'trip_id': r['trip_id'],
  ..._audit(r),
};

Map<String, Object?> _trip(Map<String, Object?> r) => {
  'id': r['id'],
  'vehicle_id': r['vehicle_id'],
  'title': r['title'],
  'purpose': r['purpose'],
  'started_on': r['started_on'],
  'ended_on': r['ended_on'],
  'start_odometer_m': r['start_odometer_m'],
  'end_odometer_m': r['end_odometer_m'],
  'odometer_unit': r['odometer_unit'],
  'manual_distance_m': r['manual_distance_m'],
  'notes': r['notes'],
  ..._audit(r),
};

Map<String, Object?> _settings(Map<String, Object?> r) => {
  'language': r['language'],
  'theme': r['theme'],
  'currency_default': r['currency_default'],
  'currency_display': r['currency_display'],
  'distance_unit': r['distance_unit'],
  'volume_unit': r['volume_unit'],
  'consumption_unit': r['consumption_unit'],
  'first_day_of_week': r['first_day_of_week'],
  'calendar': r['calendar'],
  'numerals': r['numerals'],
  'notification_time': _wallClock(r['notification_time_minutes']),
  'quiet_hours_from': _wallClock(r['quiet_hours_from_minutes']),
  'quiet_hours_to': _wallClock(r['quiet_hours_to_minutes']),
  'weekdays_only': _bool(r['weekdays_only']),
  'notify_service': _bool(r['notify_service']),
  'notify_odometer': _bool(r['notify_odometer']),
  'notify_backup': _bool(r['notify_backup']),
  'notice_days': r['notice_days'],
  'notice_distance_m': r['notice_distance_m'],
  'active_vehicle_id': r['active_vehicle_id'],
  'last_backup_at': _rfc3339OrNull(r['last_backup_at_utc_ms']),
};

/// The three audit fields every record carries.
///
/// `deleted_at` is always null: a soft-deleted row never reaches this
/// projection, because §6 §7 keeps deleted rows out of the file entirely.
Map<String, Object?> _audit(Map<String, Object?> r) => {
  'created_at': _rfc3339OrNull(r['created_at_utc_ms']),
  'updated_at': _rfc3339OrNull(r['updated_at_utc_ms']),
  'deleted_at': null,
};

/// SQLite has no boolean: v1 stores 0 and 1, and a JSON `0` where the format
/// says `false` is a value a strict reader would reject.
bool _bool(Object? value) => value == 1 || value == true;

Map<String, Object?>? _money(Object? minor, Object? currency) =>
    minor == null || currency == null
    ? null
    : {'amount_minor': minor, 'currency': currency};

String? _wallClock(Object? minutes) {
  if (minutes is! int) return null;
  final clamped = minutes.clamp(0, 24 * 60 - 1);
  return '${(clamped ~/ 60).toString().padLeft(2, '0')}:'
      '${(clamped % 60).toString().padLeft(2, '0')}';
}

String _rfc3339(int utcMs) => DateTime.fromMillisecondsSinceEpoch(
  utcMs,
  isUtc: true,
).toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

String? _rfc3339OrNull(Object? utcMs) => utcMs is int ? _rfc3339(utcMs) : null;
