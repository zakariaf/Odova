// The settings singleton.
//
// SPEC.md §3: one row, id `settings`. The schema enforces that with
// `CHECK (id = 'settings')`, so this repository cannot create a second one even
// by accident — which is the point of putting it there rather than here.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/row_mappers.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/guard.dart';

/// Reads and writes the settings row.
class SettingsRepository {
  /// Creates a repository over [_db].
  const SettingsRepository(this._db);

  final AppDatabase _db;

  /// The settings, or null before first run has written them.
  ///
  /// Nullable rather than defaulted: "no settings row yet" is what routes a
  /// fresh install into onboarding, and manufacturing a default here would
  /// make a first launch indistinguishable from a returning one.
  Stream<AppSettings?> watch() => _db
      .select(_db.settingsTable)
      .watchSingleOrNull()
      .map((row) => row == null ? null : settingsFromRow(row))
      .distinct();

  /// Reads the settings.
  Future<Result<AppSettings, PersistFailure>> read() => guardPersist(() async {
    final row = await _db.select(_db.settingsTable).getSingleOrNull();
    if (row == null) return const Err(NotFound(AppSettings.id));
    return Ok(settingsFromRow(row));
  });

  /// Points `active_vehicle_id` at [id], and touches nothing else.
  ///
  /// A targeted UPDATE rather than a read-modify-write of the whole row.
  /// SPEC.md §7 says switching the active vehicle writes ONE field, and a
  /// round-trip through the full companion makes that a promise the code keeps
  /// by accident: every default on `AppSettings` becomes a value this statement
  /// would write back, so a field added later and not yet read would be reset
  /// to its default on the next vehicle switch.
  ///
  /// [updatedAtUtcMs] is passed in rather than read from `DateTime.now()` —
  /// SPEC.md §3's rule that time is an argument holds in the data layer too.
  Future<Result<void, PersistFailure>> setActiveVehicle(
    VehicleId? id, {
    required int updatedAtUtcMs,
  }) => guardPersist(() async {
    final rows =
        await (_db.update(
          _db.settingsTable,
        )..where((s) => s.id.equals(AppSettings.id))).write(
          SettingsTableCompanion(
            activeVehicleId: Value(id?.toString()),
            updatedAtUtcMs: Value(updatedAtUtcMs),
          ),
        );
    if (rows == 0) return const Err(NotFound(AppSettings.id));
    return const Ok(null);
  });

  /// Writes [settings].
  Future<Result<AppSettings, PersistFailure>> save(AppSettings settings) =>
      guardPersist(() async {
        await _db.transaction(() async {
          await _db
              .into(_db.settingsTable)
              .insertOnConflictUpdate(
                SettingsTableCompanion.insert(
                  id: AppSettings.id,
                  createdAtUtcMs: settings.createdAtUtcMs,
                  updatedAtUtcMs: settings.updatedAtUtcMs,
                  schemaVersion: settings.schemaVersion,
                  language: settings.language,
                  calendar: settings.calendar,
                  numerals: settings.numerals,
                  firstDayOfWeek: settings.firstDayOfWeek,
                  theme: settings.theme,
                  currencyDefault: settings.currencyDefault.code,
                  currencyDisplay: settings.currencyDisplay,
                  distanceUnit: settings.distanceUnit.wire,
                  volumeUnit: settings.volumeUnit.wire,
                  consumptionUnit: settings.consumptionUnit.wire,
                  noticeDistanceM: Value(
                    metresColumnOrNull(settings.noticeDistance),
                  ),
                  noticeDays: Value(settings.noticeDays),
                  notificationTimeMinutes: settings.notificationTimeMinutes,
                  quietHoursFromMinutes: settings.quietHoursFromMinutes,
                  quietHoursToMinutes: settings.quietHoursToMinutes,
                  weekdaysOnly: Value(settings.weekdaysOnly),
                  notifyService: Value(settings.notifyService),
                  notifyOdometer: Value(settings.notifyOdometer),
                  notifyBackup: Value(settings.notifyBackup),
                  activeVehicleId: Value(settings.activeVehicleId?.toString()),
                  onboardingDone: Value(settings.onboardingDone),
                  lastBackupAtUtcMs: Value(settings.lastBackupAtUtcMs),
                  lastBackupReminderAtUtcMs: Value(
                    settings.lastBackupReminderAtUtcMs,
                  ),
                ),
              );
        });
        return Ok(settings);
      });

  /// Writes exactly the columns [fields] names, and the timestamp.
  ///
  /// Private, and every public write goes through it. A read-modify-write of
  /// the whole row makes every default on `AppSettings` a value the statement
  /// writes back, so a field added later and not yet read is reset on the next
  /// unrelated write — the reason [setActiveVehicle] is a targeted UPDATE, and
  /// there is no reason the other eighteen keys should be different.
  ///
  /// It stays private so `no_drift_in_signatures_test` keeps holding: a
  /// `SettingsTableCompanion` in a public signature would make every caller
  /// need a database.
  Future<Result<void, PersistFailure>> _write(
    SettingsTableCompanion fields, {
    required int updatedAtUtcMs,
  }) => guardPersist(() async {
    final rows =
        await (_db.update(
          _db.settingsTable,
        )..where((s) => s.id.equals(AppSettings.id))).write(
          fields.copyWith(updatedAtUtcMs: Value(updatedAtUtcMs)),
        );
    if (rows == 0) return const Err(NotFound(AppSettings.id));
    return const Ok(null);
  });

  /// Sets the UI language — `system` or one of the six tags.
  Future<Result<void, PersistFailure>> setLanguage(
    String language, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(language: Value(language)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the display calendar.
  Future<Result<void, PersistFailure>> setCalendar(
    String calendar, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(calendar: Value(calendar)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the numeral system.
  Future<Result<void, PersistFailure>> setNumerals(
    String numerals, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(numerals: Value(numerals)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the ISO-8601 first day of week, 1..7.
  Future<Result<void, PersistFailure>> setFirstDayOfWeek(
    int day, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(firstDayOfWeek: Value(day)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the theme — `system`, `light` or `dark`.
  Future<Result<void, PersistFailure>> setTheme(
    String theme, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(theme: Value(theme)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the default currency.
  Future<Result<void, PersistFailure>> setCurrencyDefault(
    Currency currency, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(currencyDefault: Value(currency.code)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the currency display mode — `none` or `toman`.
  Future<Result<void, PersistFailure>> setCurrencyDisplay(
    String display, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(currencyDisplay: Value(display)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the distance unit.
  Future<Result<void, PersistFailure>> setDistanceUnit(
    DistanceUnit unit, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(distanceUnit: Value(unit.wire)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the volume unit.
  Future<Result<void, PersistFailure>> setVolumeUnit(
    VolumeUnit unit, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(volumeUnit: Value(unit.wire)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the consumption unit.
  Future<Result<void, PersistFailure>> setConsumptionUnit(
    ConsumptionUnit unit, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(consumptionUnit: Value(unit.wire)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the distance notice window.
  ///
  /// Through `metresColumnOrNull`, which is the mapper's job: §3 stores
  /// integer metres and `no_conversion_on_write_test` reserves the unwrap for
  /// `lib/data/db/mappers/`.
  Future<Result<void, PersistFailure>> setNoticeDistance(
    Distance? distance, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(
      noticeDistanceM: Value(metresColumnOrNull(distance)),
    ),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the date notice window, in days.
  Future<Result<void, PersistFailure>> setNoticeDays(
    int? days, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(noticeDays: Value(days)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the daily delivery time, in minutes past midnight.
  Future<Result<void, PersistFailure>> setNotificationTime(
    int minutes, {
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(notificationTimeMinutes: Value(minutes)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets both ends of the quiet-hours window.
  ///
  /// BOTH, in one statement. They are one window and one user decision, and
  /// two writes would leave a frame in which the window is inverted — which is
  /// the shape that silences a whole day rather than a night.
  Future<Result<void, PersistFailure>> setQuietHours({
    required int fromMinutes,
    required int toMinutes,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(
      quietHoursFromMinutes: Value(fromMinutes),
      quietHoursToMinutes: Value(toMinutes),
    ),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets whether delivery is restricted to weekdays.
  Future<Result<void, PersistFailure>> setWeekdaysOnly({
    required bool weekdaysOnly,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(weekdaysOnly: Value(weekdaysOnly)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the service-reminder category.
  Future<Result<void, PersistFailure>> setNotifyService({
    required bool notify,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(notifyService: Value(notify)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the odometer-nudge category.
  Future<Result<void, PersistFailure>> setNotifyOdometer({
    required bool notify,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(notifyOdometer: Value(notify)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Sets the backup-reminder category.
  Future<Result<void, PersistFailure>> setNotifyBackup({
    required bool notify,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(notifyBackup: Value(notify)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Stamps when the user last handed a backup to the OS.
  ///
  /// SPEC.md §6 §6: on the HAND-OFF, not on a confirmed save. The OS never
  /// tells the app what the user did with the file, and waiting for a
  /// confirmation that cannot arrive would leave the Settings line amber for
  /// ever on a phone whose user backs up every week.
  Future<Result<void, PersistFailure>> setLastBackupAt({
    required int atUtcMs,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(lastBackupAtUtcMs: Value(atUtcMs)),
    updatedAtUtcMs: updatedAtUtcMs,
  );

  /// Stamps when the app last nudged about a backup.
  ///
  /// §6 §7 keeps this out of the file: it is device-local nagging state, so a
  /// restored phone starts its ninety-day clock fresh.
  Future<Result<void, PersistFailure>> setLastBackupReminderAt({
    required int atUtcMs,
    required int updatedAtUtcMs,
  }) => _write(
    SettingsTableCompanion(lastBackupReminderAtUtcMs: Value(atUtcMs)),
    updatedAtUtcMs: updatedAtUtcMs,
  );
}
