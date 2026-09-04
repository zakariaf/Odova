// The one settings row.
//
// SPEC.md §3 Entities (`Settings`), §3 Scope: global vs per vehicle. Language,
// calendar, numerals, theme, notification settings, unit and currency defaults,
// the active vehicle and backup state are global; everything else hangs off a
// vehicle.
import 'package:drift/drift.dart';
import 'package:odova/data/db/tables/audit_columns.dart';

/// The settings singleton.
///
/// One row, forced by `CHECK (id = 'settings')` rather than by a repository
/// that promises to only ever write one. A second row would give the app two
/// answers about which vehicle is active, and nothing above the database would
/// notice which one it read.
@DataClassName('SettingsRow')
class SettingsTable extends Table with AuditColumns {
  @override
  String get tableName => 'settings';

  @override
  TextColumn get id =>
      text().customConstraint("NOT NULL CHECK (id = 'settings')")();

  /// The schema version, mirrored on write.
  ///
  /// **Drift's own `user_version` stays authoritative for the migration
  /// ladder.** This column mirrors it and is what the EXPORT reads — the
  /// backup file needs the number without opening the database. Treating the
  /// two as independent is how a restore ends up believing a version the
  /// tables do not have.
  IntColumn get schemaVersion => integer().named('schema_version')();

  /// `system` follows the device.
  TextColumn get language => text().customConstraint(
    'NOT NULL CHECK (language IN '
    "('system', 'en', 'de', 'fr', 'fa', 'ar', 'ckb'))",
  )();

  /// Gregorian or Jalali. Hijri is not offered in v1.
  TextColumn get calendar => text().customConstraint(
    "NOT NULL CHECK (calendar IN ('gregorian', 'persian'))",
  )();

  /// Which digits are drawn. `auto` is the locale's CLDR default.
  TextColumn get numerals => text().customConstraint(
    'NOT NULL CHECK (numerals IN '
    "('auto', 'latin', 'arabic_indic', 'extended_arabic_indic'))",
  )();

  /// 1 = Monday, 7 = Sunday, as `DateTime`'s weekday constants.
  IntColumn get firstDayOfWeek => integer()
      .named('first_day_of_week')
      .customConstraint(
        'NOT NULL CHECK (first_day_of_week BETWEEN 1 AND 7)',
      )();

  /// Light, dark or the device's.
  TextColumn get theme => text().customConstraint(
    "NOT NULL CHECK (theme IN ('system', 'light', 'dark'))",
  )();

  /// The ISO 4217 code new vehicles inherit.
  /// The length is checked in SQL, not with `withLength`, which is a
  /// DART-side validator that emits nothing into the schema — so an import or
  /// a migration could write `'EU'`, and the exponent that turns 4599 into
  /// 45.99 comes from this code.
  TextColumn get currencyDefault => text()
      .named('currency_default')
      .customConstraint('NOT NULL CHECK (length(currency_default) = 3)')();

  /// `toman` divides a stored IRR amount by ten FOR DISPLAY. Storage stays
  /// IRR, because `IRT` is not an ISO 4217 code and a non-ISO code in a backup
  /// would fail the file's own validation.
  TextColumn get currencyDisplay => text()
      .named('currency_display')
      .customConstraint(
        "NOT NULL CHECK (currency_display IN ('none', 'toman'))",
      )();

  /// Kilometres or miles.
  TextColumn get distanceUnit => text()
      .named('distance_unit')
      .customConstraint("NOT NULL CHECK (distance_unit IN ('km', 'mi'))")();

  /// Litres or gallons.
  TextColumn get volumeUnit => text()
      .named('volume_unit')
      .customConstraint(
        "NOT NULL CHECK (volume_unit IN ('l', 'gal_us', 'gal_uk'))",
      )();

  /// How consumption reads.
  TextColumn get consumptionUnit => text()
      .named('consumption_unit')
      .customConstraint(
        "NOT NULL CHECK (consumption_unit IN ('l_100km', 'km_l', 'mpg_us', "
        "'mpg_uk', 'kwh_100km', 'mi_kwh'))",
      )();

  /// Global distance notice window override, in metres. Null = computed.
  IntColumn get noticeDistanceM =>
      integer().named('notice_distance_m').nullable()();

  /// Global time notice window override, in days. Null = computed.
  IntColumn get noticeDays => integer().named('notice_days').nullable()();

  /// When the daily due check fires, as minutes after local midnight.
  ///
  /// Minutes, not a `DateTime`: it is a LOCAL time of day and not an instant,
  /// so storing it as one would move it when the user crosses a zone. 09:00
  /// stays 09:00 in Tehran and in Toronto.
  IntColumn get notificationTimeMinutes => integer()
      .named('notification_time_minutes')
      .customConstraint(
        'NOT NULL CHECK (notification_time_minutes BETWEEN 0 AND 1439)',
      )();

  /// Quiet hours start, minutes after local midnight. Default 21:00.
  IntColumn get quietHoursFromMinutes => integer()
      .named('quiet_hours_from_minutes')
      .customConstraint(
        'NOT NULL CHECK (quiet_hours_from_minutes BETWEEN 0 AND 1439)',
      )();

  /// Quiet hours end, minutes after local midnight. Default 08:00.
  IntColumn get quietHoursToMinutes => integer()
      .named('quiet_hours_to_minutes')
      .customConstraint(
        'NOT NULL CHECK (quiet_hours_to_minutes BETWEEN 0 AND 1439)',
      )();

  /// Whether reminders only fire on weekdays.
  BoolColumn get weekdaysOnly =>
      boolean().named('weekdays_only').withDefault(const Constant(false))();

  /// Whether service reminders fire.
  BoolColumn get notifyService =>
      boolean().named('notify_service').withDefault(const Constant(true))();

  /// Whether the odometer nudge fires.
  BoolColumn get notifyOdometer =>
      boolean().named('notify_odometer').withDefault(const Constant(true))();

  /// Whether the backup nudge fires.
  BoolColumn get notifyBackup =>
      boolean().named('notify_backup').withDefault(const Constant(true))();

  /// Which vehicle the app opens on.
  TextColumn get activeVehicleId =>
      text().named('active_vehicle_id').nullable()();

  /// Whether onboarding has been completed.
  BoolColumn get onboardingDone =>
      boolean().named('onboarding_done').withDefault(const Constant(false))();

  /// When the last backup was written. UTC epoch milliseconds.
  IntColumn get lastBackupAtUtcMs =>
      integer().named('last_backup_at_utc_ms').nullable()();

  /// When the app last nudged about a backup. UTC epoch milliseconds.
  IntColumn get lastBackupReminderAtUtcMs =>
      integer().named('last_backup_reminder_at_utc_ms').nullable()();
}
