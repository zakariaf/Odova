// The settings singleton.
//
// SPEC.md §3: one row, id `settings`. The schema enforces that with
// `CHECK (id = 'settings')`, so this repository cannot create a second one even
// by accident — which is the point of putting it there rather than here.
import 'package:drift/drift.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/result.dart';
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
}
