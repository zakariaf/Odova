// The inverse of `mapping/*_backup.dart` — a JSON object back to a model.
//
// Every function here returns null rather than throwing when a record cannot
// be read, because SPEC.md §6 §5.1 rung 9 makes an unreadable record a SKIP
// with a warning and not an aborted import. A throw would take the other 1,203
// records with it.
//
// The distinction rung 9 draws, and the one this file exists to hold: a TYPE
// error rejects the record, an ODD VALUE does not. `"quantity_ml": "forty"`
// cannot be read at all. A 312-litre fill in a 50-litre tank is a number the
// user typed, possibly wrongly, possibly because they filled two jerrycans —
// and the app is not entitled to decide which.
//
// Unknown enum values COERCE rather than reject. An unknown category must not
// cost somebody their €612 insurance row: the category is a label on an amount,
// and the amount is the record.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/records.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/money/money.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/energy.dart';
import 'package:odova/core/units/fuel_quantity.dart';
import 'package:odova/core/units/mass.dart';
import 'package:odova/core/units/volume.dart';

/// Which ids in the file resolve, and what to do when one does not.
///
/// Passed INTO the restore functions rather than applied afterwards, because
/// the models are immutable and have no `copyWith` — and adding one to eight
/// of them so that the reader could rewrite a field it already knew the right
/// value for would be eight new public surfaces to keep in step.
///
/// The counters live here so the caller does not have to compare the file's
/// ids against the restored ones a second time to find out what it forgave.
class BackupLinks {
  /// Creates a resolver over the ids that were actually read.
  BackupLinks({
    required this.vehicles,
    required this.trips,
    required this.items,
    required this.readings,
    required this.orphanVehicleId,
  });

  /// Vehicle ids present in the file.
  final Set<VehicleId> vehicles;

  /// Trip ids present in the file.
  final Set<TripId> trips;

  /// Service-item ids present in the file.
  final Set<ServiceItemId> items;

  /// Odometer-reading ids present in the file.
  final Set<OdometerReadingId> readings;

  /// Where a record whose vehicle is missing goes. SPEC.md §5.3.
  final VehicleId orphanVehicleId;

  /// How many records were adopted by the placeholder vehicle.
  int orphans = 0;

  /// How many `trip_id` / `service_item_id` links were nulled.
  int unresolved = 0;

  /// [id] if the file has that vehicle, else the placeholder.
  ///
  /// §5.3: never deleted. A placeholder the user can see beats a number in a
  /// report they will not read.
  VehicleId vehicle(VehicleId id) {
    if (vehicles.contains(id)) return id;
    orphans++;
    return orphanVehicleId;
  }

  /// [id] if the file has that trip, else null.
  ///
  /// Nulled, not dropped. The link is a convenience; the amount and the date
  /// are the record.
  TripId? trip(TripId? id) {
    if (id == null || trips.contains(id)) return id;
    unresolved++;
    return null;
  }

  /// [id] if the file has that reminder, else null.
  ServiceItemId? item(ServiceItemId? id) {
    if (id == null || items.contains(id)) return id;
    unresolved++;
    return null;
  }
}

/// What went wrong reading one record, and what had to be forgiven.
///
/// Mutable and passed down through a record's fields, because the alternative
/// is every reader function returning a pair and every caller unpacking it —
/// thirty places to drop a warning on the floor.
class RestoreLog {
  /// Why the current record could not be read, if it could not.
  String? rejection;

  /// How many enum values were coerced to `other` / `custom`.
  int coercedEnums = 0;

  /// How many strings were longer than the format allows.
  int truncatedStrings = 0;

  /// Marks the current record unreadable, keeping the FIRST reason.
  ///
  /// The first, because it is the one nearest the cause: a record with no
  /// `occurred_on` will also fail to produce a date, and "the date was missing"
  /// is the sentence a user can act on.
  Null reject(String reason) {
    rejection ??= reason;
    return null;
  }
}

/// A required string, or a rejection.
String? requiredString(Object? value, String field, RestoreLog log) =>
    value is String && value.isNotEmpty ? value : log.reject('missing_$field');

/// An optional string, or null when it is absent or the wrong type.
///
/// A wrong-typed OPTIONAL field is treated as absent rather than as a reason to
/// reject: a note that arrived as a number is a note nobody can read, and it is
/// not worth the fill-up it is attached to.
String? optionalString(Object? value) => value is String ? value : null;

/// A required integer, or a rejection.
int? requiredInt(Object? value, String field, RestoreLog log) =>
    value is int ? value : log.reject('missing_$field');

/// An optional integer, or null. A non-integer is a rejection, because a
/// quantity that arrived as `"forty"` is not an absent quantity.
int? optionalInt(Object? value, String field, RestoreLog log) =>
    switch (value) {
      null => null,
      final int n => n,
      _ => log.reject('unreadable_$field'),
    };

/// An optional boolean, defaulting to [fallback].
bool boolOr(Object? value, {required bool fallback}) =>
    value is bool ? value : fallback;

/// An optional distance in canonical metres.
Distance? optionalDistance(Object? value, String field, RestoreLog log) {
  final metres = optionalInt(value, field, log);
  return metres == null ? null : Distance(metres);
}

/// Money from §6's nested `{amount_minor, currency}` pair.
Money? moneyFrom(Object? value, String field, RestoreLog log) {
  if (value is! Map<String, Object?>) return log.reject('missing_$field');
  return moneyFromParts(value['amount_minor'], value['currency'], field, log);
}

/// Money from a flat minor/code pair, which is §6's shape for a service line.
Money? moneyFromParts(
  Object? minor,
  Object? code,
  String field,
  RestoreLog log,
) {
  final amount = requiredInt(minor, field, log);
  if (amount == null) return null;
  final currency = code is String ? Currency.tryParse(code) : null;
  // A missing or MALFORMED currency rejects the record rather than defaulting.
  // §2 forbids summing across currencies, so a wrong code does not make one
  // amount wrong — it makes every total that includes it wrong.
  //
  // A well-formed code this build has no exponent for is NOT malformed and is
  // kept: `Currency` defaults such a code to two decimals, and refusing a row
  // because ISO 4217 gained a currency after this release would lose data over
  // a table that is out of date.
  return currency == null
      ? log.reject('unknown_currency')
      : Money(
          amount,
          currency,
        );
}

/// Optional money, absent when the field is absent.
Money? optionalMoney(Object? value, String field, RestoreLog log) =>
    value == null ? null : moneyFrom(value, field, log);

/// An enum from its wire value, coercing an unknown one to [fallback].
///
/// An ABSENT field is not a coercion and is not counted. §6 makes most of these
/// optional with a documented default, and warning "4 values Odova no longer
/// has" about four fields nobody wrote would be an alarm about nothing —
/// which is how a user learns to ignore the report that matters.
T enumOr<T>(
  Object? value,
  List<T> values,
  String Function(T) wire,
  T fallback,
  RestoreLog log,
) {
  for (final candidate in values) {
    if (wire(candidate) == value) return candidate;
  }
  if (value != null) log.coercedEnums++;
  return fallback;
}

/// An ISO date, or a rejection. Parsed, not merely non-empty.
String? isoDate(Object? value, String field, RestoreLog log) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return log.reject('missing_$field');
  }
  return DateTime.tryParse(value) == null ? log.reject('bad_$field') : value;
}

/// An optional ISO date, absent when absent and null when unreadable.
String? optionalIsoDate(Object? value) =>
    value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
    ? value
    : null;

/// An RFC 3339 timestamp back to UTC milliseconds, or [fallback].
int timestampOr(Object? value, int fallback) {
  if (value is! String) return fallback;
  return DateTime.tryParse(value)?.toUtc().millisecondsSinceEpoch ?? fallback;
}

/// The same, or null.
int? optionalTimestamp(Object? value) => value is String
    ? DateTime.tryParse(value)?.toUtc().millisecondsSinceEpoch
    : null;

/// `HH:mm` back to minutes past midnight, or [fallback].
int wallClockOr(Object? value, int fallback) {
  if (value is! String) return fallback;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  if (match == null) return fallback;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) return fallback;
  return hours * 60 + minutes;
}

/// The vehicle the file was last looking at, for the importer to select.
///
/// Read separately from [settingsFromBackup] so the restored settings carry no
/// active vehicle at all — see the note there.
VehicleId? activeVehicleFromBackup(Map<String, Object?> json) =>
    VehicleId.tryParse(optionalString(json['active_vehicle_id']) ?? '');

/// The `settings` object back to [AppSettings].
///
/// Never rejects. Settings are preferences: a file whose `theme` is nonsense
/// should still restore eight years of service history, and every field falls
/// back to the app's own default.
AppSettings settingsFromBackup(
  Map<String, Object?> json,
  RestoreLog log, {
  required int schemaVersion,
  required Currency fallbackCurrency,
  required int nowUtcMs,
}) {
  final code = json['currency_default'];
  return AppSettings(
    schemaVersion: schemaVersion,
    currencyDefault:
        (code is String ? Currency.tryParse(code) : null) ?? fallbackCurrency,
    createdAtUtcMs: nowUtcMs,
    updatedAtUtcMs: nowUtcMs,
    language: optionalString(json['language']) ?? 'system',
    calendar: optionalString(json['calendar']) ?? 'gregorian',
    numerals: optionalString(json['numerals']) ?? 'auto',
    firstDayOfWeek: json['first_day_of_week'] is int
        ? json['first_day_of_week']! as int
        : DateTime.monday,
    theme: optionalString(json['theme']) ?? 'system',
    currencyDisplay: optionalString(json['currency_display']) ?? 'none',
    distanceUnit: enumOr(
      json['distance_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    volumeUnit: enumOr(
      json['volume_unit'],
      VolumeUnit.values,
      (u) => u.wire,
      VolumeUnit.l,
      log,
    ),
    consumptionUnit: enumOr(
      json['consumption_unit'],
      ConsumptionUnit.values,
      (u) => u.wire,
      ConsumptionUnit.lPer100km,
      log,
    ),
    noticeDays: json['notice_days'] is int ? json['notice_days']! as int : null,
    noticeDistance: json['notice_distance_m'] is int
        ? Distance(json['notice_distance_m']! as int)
        : null,
    notificationTimeMinutes: wallClockOr(
      json['notification_time'],
      kDefaultNotificationMinutes,
    ),
    quietHoursFromMinutes: wallClockOr(
      json['quiet_hours_from'],
      kDefaultQuietFromMinutes,
    ),
    quietHoursToMinutes: wallClockOr(
      json['quiet_hours_to'],
      kDefaultQuietToMinutes,
    ),
    weekdaysOnly: boolOr(json['weekdays_only'], fallback: false),
    notifyService: boolOr(json['notify_service'], fallback: true),
    notifyOdometer: boolOr(json['notify_odometer'], fallback: true),
    notifyBackup: boolOr(json['notify_backup'], fallback: true),
    // NOT restored here, deliberately. `test/app/active_vehicle_test.dart`
    // asserts that exactly one place in the app selects a vehicle, because
    // selecting one has to reset the tab stack — and an importer that wrote
    // the column directly would put the user on a Fuel tab belonging to a car
    // they are no longer looking at. The file's value travels on `ImportPlan`
    // instead, and task 15.4 applies it through `setActiveVehicle`.
    onboardingDone: true,
    lastBackupAtUtcMs: optionalTimestamp(json['last_backup_at']),
  );
}

/// One vehicle, or null when it cannot be read.
Vehicle? vehicleFromBackup(Map<String, Object?> json, RestoreLog log) {
  final id = VehicleId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final name = requiredString(json['name'], 'name', log);
  if (name == null) return null;

  return Vehicle(
    id: id,
    name: name,
    vehicleType: enumOr(
      json['type'],
      VehicleType.values,
      (v) => v.wire,
      VehicleType.car,
      log,
    ),
    fuelKindDefault: enumOr(
      json['fuel_kind_default'],
      FuelKind.values,
      (v) => v.wire,
      FuelKind.petrol,
      log,
    ),
    status: enumOr(
      json['status'],
      VehicleStatus.values,
      (v) => v.wire,
      VehicleStatus.active,
      log,
    ),
    make: optionalString(json['make']),
    model: optionalString(json['model']),
    year: json['year'] is int ? json['year']! as int : null,
    plate: optionalString(json['plate']),
    vin: optionalString(json['vin']),
    isBusiness: boolOr(json['is_business'], fallback: false),
    tankCapacityMl: json['tank_capacity_ml'] is int
        ? json['tank_capacity_ml']! as int
        : null,
    purchaseDate: optionalIsoDate(json['purchase_date']),
    purchaseOdometer: json['purchase_odometer_m'] is int
        ? Distance(json['purchase_odometer_m']! as int)
        : null,
    purchasePrice: optionalMoney(json['purchase_price'], 'purchase_price', log),
    soldOn: optionalIsoDate(json['sold_on']),
    soldPrice: optionalMoney(json['sold_price'], 'sold_price', log),
    expectedAnnual: json['expected_annual_m'] is int
        ? Distance(json['expected_annual_m']! as int)
        : null,
    colour: optionalString(json['colour']),
    notes: optionalString(json['notes']),
    sortOrder: json['sort_order'] is int ? json['sort_order']! as int : 0,
    notificationsMuted: boolOr(json['notifications_muted'], fallback: false),
    // Null when inherited, and never materialised. Writing the defaults in
    // would pin every vehicle to whatever this phone happened to be set to,
    // and a later change to the app default would silently stop reaching them.
    currency: Currency.tryParse(optionalString(json['currency']) ?? ''),
    distanceUnit: _enumOrNull(
      json['distance_unit'],
      DistanceUnit.values,
      (u) => u.wire,
    ),
    volumeUnit: _enumOrNull(
      json['volume_unit'],
      VolumeUnit.values,
      (u) => u.wire,
    ),
    consumptionUnit: _enumOrNull(
      json['consumption_unit'],
      ConsumptionUnit.values,
      (u) => u.wire,
    ),
    noticeDistance: json['notice_distance_m'] is int
        ? Distance(json['notice_distance_m']! as int)
        : null,
    noticeDays: json['notice_days'] is int ? json['notice_days']! as int : null,
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

T? _enumOrNull<T>(Object? value, List<T> values, String Function(T) wire) {
  for (final candidate in values) {
    if (wire(candidate) == value) return candidate;
  }
  return null;
}

/// One reminder, or null.
///
/// The three `last_done_*` fields are read and DISCARDED: §6's envelope lists
/// them in `derived_fields`, and §1 says a derived value is recomputed rather
/// than trusted. They are in the file so a human can read it.
ServiceItem? reminderFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = ServiceItemId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);

  return ServiceItem(
    id: id,
    vehicleId: vehicleId,
    kind: enumOr(
      json['kind'],
      ServiceKind.values,
      (k) => k.wire,
      ServiceKind.custom,
      log,
    ),
    priority: enumOr(
      json['priority'],
      ServicePriority.values,
      (p) => p.wire,
      ServicePriority.normal,
      log,
    ),
    rollover: enumOr(
      json['rollover'],
      ServiceRollover.values,
      (r) => r.wire,
      ServiceRollover.fromActual,
      log,
    ),
    label: optionalString(json['label']),
    intervalDistance: optionalDistance(
      json['interval_distance_m'],
      'interval',
      log,
    ),
    intervalDistanceUnit: _enumOrNull(
      json['interval_distance_unit'],
      DistanceUnit.values,
      (u) => u.wire,
    ),
    intervalMonths: json['interval_months'] is int
        ? json['interval_months']! as int
        : null,
    targetOdometer: optionalDistance(json['target_odometer_m'], 'target', log),
    targetDate: optionalIsoDate(json['target_date']),
    baselineDate: optionalIsoDate(json['baseline_date']),
    baselineOdometer: optionalDistance(
      json['baseline_odometer_m'],
      'baseline',
      log,
    ),
    noticeDistance: optionalDistance(json['notice_distance_m'], 'notice', log),
    noticeDays: json['notice_days'] is int ? json['notice_days']! as int : null,
    isTracked: boolOr(json['is_tracked'], fallback: false),
    isActive: boolOr(json['is_active'], fallback: true),
    notify: boolOr(json['notify'], fallback: true),
    repeats: boolOr(json['repeats'], fallback: true),
    snoozedUntil: optionalIsoDate(json['snoozed_until']),
    snoozeUntilOdometer: optionalDistance(
      json['snooze_until_odometer_m'],
      'snooze',
      log,
    ),
    snoozeCount: json['snooze_count'] is int ? json['snooze_count']! as int : 0,
    notes: optionalString(json['notes']),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// One standalone odometer reading, or null.
OdometerReading? odometerReadingFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = OdometerReadingId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final occurredOn = isoDate(json['occurred_on'], 'date', log);
  if (occurredOn == null) return null;
  final metres = requiredInt(json['odometer_m'], 'odometer', log);
  if (metres == null) return null;

  return OdometerReading(
    id: id,
    vehicleId: vehicleId,
    occurredOn: occurredOn,
    odometer: Distance(metres),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    // `manual` for anything unrecognised. §6 exports STANDALONE readings only
    // — a reading a fill-up emitted is re-derived from that fill-up — so a row
    // in this array is one the user typed, whatever its `source` says.
    source: enumOr(
      json['source'],
      OdometerSource.values,
      (s) => s.wire,
      OdometerSource.manual,
      log,
    ),
    notes: optionalString(json['notes']),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// One odometer correction, or null.
OdometerCorrection? odometerCorrectionFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = OdometerCorrectionId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final from = OdometerReadingId.tryParse(
    optionalString(json['from_reading_id']) ?? '',
  );
  if (from == null) return log.reject('missing_from_reading');
  // The ONE link failure that must not be repaired by guessing: a correction
  // applied to an arbitrary reading rewrites a mileage history that looked
  // fine, and the user has no way of knowing which number the app invented.
  if (!links.readings.contains(from)) return log.reject('unmatched_correction');
  final previous = requiredInt(json['previous_m'], 'previous', log);
  final replacement = requiredInt(json['replacement_m'], 'replacement', log);
  if (previous == null || replacement == null) return null;

  return OdometerCorrection(
    id: id,
    vehicleId: vehicleId,
    fromReadingId: from,
    previous: Distance(previous),
    replacement: Distance(replacement),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    // `typo_fix` for an unrecognised reason, because it is the one that claims
    // the least: a cluster replacement and a rollover both change what the
    // mileage history MEANS, and guessing either would rewrite a number the
    // user never questioned.
    reason: enumOr(
      json['reason'],
      OdometerCorrectionReason.values,
      (r) => r.wire,
      OdometerCorrectionReason.typoFix,
      log,
    ),
    notes: optionalString(json['notes']),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// One fill-up, or null.
FillUp? fillUpFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = FillUpId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final occurredOn = isoDate(json['occurred_on'], 'date', log);
  if (occurredOn == null) return null;
  final cost = moneyFrom(json['total_cost'], 'cost', log);
  if (cost == null) return null;
  final quantity = _quantityFrom(json, log);
  if (quantity == null) return null;

  return FillUp(
    id: id,
    vehicleId: vehicleId,
    occurredOn: occurredOn,
    odometer: optionalDistance(json['odometer_m'], 'odometer', log),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    fuelKind: enumOr(
      json['fuel_kind'],
      FuelKind.values,
      (k) => k.wire,
      FuelKind.petrol,
      log,
    ),
    quantity: quantity,
    quantityUnit: enumOr(
      json['quantity_unit'],
      VolumeUnit.values,
      (u) => u.wire,
      VolumeUnit.l,
      log,
    ),
    totalCost: cost,
    isFullTank: boolOr(json['is_full_tank'], fallback: true),
    // A fill with no odometer is a chain break by §6's own import rule, and a
    // file that already says so is believed.
    chainBroken:
        boolOr(json['chain_broken'], fallback: false) ||
        json['odometer_m'] is! int,
    grade: optionalString(json['grade']),
    station: optionalString(json['station']),
    notes: optionalString(json['notes']),
    tripId: links.trip(TripId.tryParse(optionalString(json['trip_id']) ?? '')),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// A fill-up's quantity, from whichever of the three keys carries it.
///
/// Exactly one is non-null in a well-formed file, and the KEY is what says
/// which physical thing the integer counts. Reading them in a fixed order and
/// taking the first is deliberate: a file carrying two is malformed, and
/// litres is the least surprising thing to believe about a fill-up.
///
/// A `"forty"` in any of the three rejects the record — `optionalInt` logs it —
/// because a fill-up that does not say how much fuel went in is the one shape
/// a fill-up cannot take.
FuelQuantity? _quantityFrom(Map<String, Object?> json, RestoreLog log) {
  final millilitres = optionalInt(json['quantity_ml'], 'quantity', log);
  if (millilitres != null) return LiquidVolume(Volume(millilitres));
  final grams = optionalInt(json['quantity_g'], 'quantity', log);
  if (grams != null) return GasMass(Mass(grams));
  final wattHours = optionalInt(json['energy_wh'], 'quantity', log);
  if (wattHours != null) return ElectricEnergy(Energy(wattHours));
  return log.reject('missing_quantity');
}

/// One service line, or null.
ServiceLine? serviceLineFromBackup(
  Map<String, Object?> json,
  ServiceRecordId recordId,
  RestoreLog log,
  BackupLinks links,
) {
  final id = ServiceLineId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final label = requiredString(json['label'], 'label', log);
  if (label == null) return null;
  // FLAT, unlike every other money field: §6 §2.5's shape for a line.
  final amount = moneyFromParts(
    json['amount_minor'],
    json['currency'],
    'amount',
    log,
  );
  if (amount == null) return null;

  return ServiceLine(
    id: id,
    serviceRecordId: recordId,
    serviceItemId: links.item(
      ServiceItemId.tryParse(optionalString(json['service_item_id']) ?? ''),
    ),
    label: label,
    amount: amount,
    partNumber: optionalString(json['part_number']),
    notes: optionalString(json['notes']),
  );
}

/// One service record with its lines, or null.
ServiceRecord? serviceFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = ServiceRecordId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final occurredOn = isoDate(json['occurred_on'], 'date', log);
  if (occurredOn == null) return null;

  final rawLines = json['lines'];
  final lines = <ServiceLine>[];
  if (rawLines is List) {
    for (final raw in rawLines) {
      if (raw is! Map<String, Object?>) continue;
      final line = serviceLineFromBackup(raw, id, log, links);
      if (line != null) lines.add(line);
    }
  }
  // A line that could not be read must not take the whole service with it: the
  // date, the odometer and the other four lines are still the user's history.
  log.rejection = null;

  return ServiceRecord(
    id: id,
    vehicleId: vehicleId,
    occurredOn: occurredOn,
    odometer: optionalDistance(json['odometer_m'], 'odometer', log),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    odometerEstimated: boolOr(json['odometer_estimated'], fallback: false),
    costEstimated: boolOr(json['cost_estimated'], fallback: false),
    lines: lines,
    vendor: optionalString(json['vendor']),
    invoiceRef: optionalString(json['invoice_ref']),
    warrantyUntil: optionalIsoDate(json['warranty_until']),
    notes: optionalString(json['notes']),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// One expense, or null.
Expense? expenseFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = ExpenseId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final occurredOn = isoDate(json['occurred_on'], 'date', log);
  if (occurredOn == null) return null;
  final amount = moneyFrom(json['amount'], 'amount', log);
  if (amount == null) return null;

  return Expense(
    id: id,
    vehicleId: vehicleId,
    occurredOn: occurredOn,
    odometer: optionalDistance(json['odometer_m'], 'odometer', log),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    // Coerced to `other`, never rejected: an unknown category must not cost
    // somebody their €612 insurance row.
    category: enumOr(
      json['category'],
      ExpenseCategory.values,
      (c) => c.wire,
      ExpenseCategory.other,
      log,
    ),
    label: optionalString(json['label']),
    amount: amount,
    vendor: optionalString(json['vendor']),
    notes: optionalString(json['notes']),
    coversFrom: optionalIsoDate(json['covers_from']),
    coversTo: optionalIsoDate(json['covers_to']),
    tripId: links.trip(TripId.tryParse(optionalString(json['trip_id']) ?? '')),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}

/// One trip, or null.
Trip? tripFromBackup(
  Map<String, Object?> json,
  RestoreLog log,
  BackupLinks links,
) {
  final id = TripId.tryParse(optionalString(json['id']) ?? '');
  if (id == null) return log.reject('missing_id');
  final parsed = VehicleId.tryParse(optionalString(json['vehicle_id']) ?? '');
  if (parsed == null) return log.reject('missing_vehicle');
  // §5.3 — a vehicle the file does not contain is not a reason to drop the
  // record. It is adopted here, at construction, because the models are
  // immutable and rewriting the field afterwards would need a `copyWith` on
  // eight of them.
  final vehicleId = links.vehicle(parsed);
  final startedOn = isoDate(json['started_on'], 'date', log);
  if (startedOn == null) return null;

  return Trip(
    id: id,
    vehicleId: vehicleId,
    title: optionalString(json['title']),
    purpose: enumOr(
      json['purpose'],
      TripPurpose.values,
      (p) => p.wire,
      TripPurpose.personal,
      log,
    ),
    startedOn: startedOn,
    endedOn: optionalIsoDate(json['ended_on']),
    startOdometer: optionalDistance(json['start_odometer_m'], 'start', log),
    endOdometer: optionalDistance(json['end_odometer_m'], 'end', log),
    odometerUnit: enumOr(
      json['odometer_unit'],
      DistanceUnit.values,
      (u) => u.wire,
      DistanceUnit.km,
      log,
    ),
    manualDistance: optionalDistance(json['manual_distance_m'], 'manual', log),
    notes: optionalString(json['notes']),
    createdAtUtcMs: timestampOr(json['created_at'], 0),
    updatedAtUtcMs: timestampOr(json['updated_at'], 0),
  );
}
