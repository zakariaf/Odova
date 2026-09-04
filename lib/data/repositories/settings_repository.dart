// The settings singleton.
//
// SPEC.md §3: one row, id `settings`. The schema enforces that with
// `CHECK (id = 'settings')`, so this repository cannot create a second one even
// by accident — which is the point of putting it there rather than here.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/mappers/audit_mapper.dart';
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
      .map((row) => row == null ? null : _fromRow(row))
      .distinct();

  /// Reads the settings.
  Future<Result<AppSettings, PersistFailure>> read() => guardPersist(() async {
    final row = await _db.select(_db.settingsTable).getSingleOrNull();
    if (row == null) return const Err(NotFound(AppSettings.id));
    return Ok(_fromRow(row));
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
                  currencyDefault: settings.currencyDefault,
                  currencyDisplay: settings.currencyDisplay,
                  distanceUnit: settings.distanceUnit.wire,
                  volumeUnit: settings.volumeUnit.wire,
                  consumptionUnit: settings.consumptionUnit.wire,
                  noticeDistanceM: Value(settings.noticeDistanceM),
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

  AppSettings _fromRow(SettingsRow row) {
    final times = repairAuditTimes(
      createdAtUtcMs: row.createdAtUtcMs,
      updatedAtUtcMs: row.updatedAtUtcMs,
    );

    return AppSettings(
      schemaVersion: row.schemaVersion,
      language: row.language,
      calendar: row.calendar,
      numerals: row.numerals,
      firstDayOfWeek: row.firstDayOfWeek,
      theme: row.theme,
      currencyDefault: row.currencyDefault,
      currencyDisplay: row.currencyDisplay,
      distanceUnit: enumFromWire(
        DistanceUnit.values,
        (v) => v.wire,
        row.distanceUnit,
      ),
      volumeUnit: enumFromWire(
        VolumeUnit.values,
        (v) => v.wire,
        row.volumeUnit,
      ),
      consumptionUnit: enumFromWire(
        ConsumptionUnit.values,
        (v) => v.wire,
        row.consumptionUnit,
      ),
      noticeDistanceM: row.noticeDistanceM,
      noticeDays: row.noticeDays,
      notificationTimeMinutes: row.notificationTimeMinutes,
      quietHoursFromMinutes: row.quietHoursFromMinutes,
      quietHoursToMinutes: row.quietHoursToMinutes,
      weekdaysOnly: row.weekdaysOnly,
      notifyService: row.notifyService,
      notifyOdometer: row.notifyOdometer,
      notifyBackup: row.notifyBackup,
      activeVehicleId: row.activeVehicleId == null
          ? null
          : idFromStored(VehicleId.tryParse, row.activeVehicleId!),
      onboardingDone: row.onboardingDone,
      lastBackupAtUtcMs: row.lastBackupAtUtcMs,
      lastBackupReminderAtUtcMs: row.lastBackupReminderAtUtcMs,
      createdAtUtcMs: times.createdAtUtcMs,
      updatedAtUtcMs: times.updatedAtUtcMs,
    );
  }
}
