// SPEC.md §13's `settings` state.
//
// A derived `Provider`, like `trips.list`'s: §13 says "No empty state and no
// loading state: every value is a constant or one indexed read", and a
// Notifier with a load flag would have to invent the loading state that
// sentence forbids.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:odova/app/routing/launch_gate.dart';
import 'package:odova/app/today.dart';
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/core/time/civil_date.dart';
import 'package:odova/data/repositories/providers.dart';

/// How the backup row reads, and in which colour.
///
/// §13 gives Backup the only subtitle in the app that changes colour, and
/// three of these four states are why: never, stale and broken all need the
/// user to do something, and `recent` is the one that does not.
enum BackupState {
  /// Never exported. Amber, with the dot.
  never,

  /// Exported within 90 days. Secondary text, no dot.
  recent,

  /// Exported more than 90 days ago. Amber, with the dot.
  stale,

  /// The migration failed at launch. Red, and the app opened on
  /// `settings.backup`.
  migrationFailed,
}

/// How old a backup may be before §13 turns the row amber.
const int kBackupStaleDays = 90;

/// What §13's tab-4 root renders.
@immutable
class SettingsRootState {
  /// Creates the state.
  const SettingsRootState({
    required this.backup,
    required this.vehicles,
    required this.theme,
    this.today,
    this.lastBackupAtUtcMs,
    this.notificationTimeMinutes = 9 * 60,
    this.notifyService = true,
    this.distanceUnit = DistanceUnit.km,
    this.volumeUnit = VolumeUnit.l,
    this.currencyCode = 'EUR',
    this.language = 'system',
  });

  /// Which of §13's four backup states applies.
  final BackupState backup;

  /// The garage, in list order — the Vehicles row names them.
  final List<Vehicle> vehicles;

  /// `system`, `light` or `dark`.
  final String theme;

  /// Today, for the age half of the backup line.
  final CivilDate? today;

  /// When the last export happened, for the row's date.
  final int? lastBackupAtUtcMs;

  /// The daily delivery time, for the Notifications row's value.
  final int notificationTimeMinutes;

  /// Whether any category is on — §13's "On / Off" word.
  final bool notifyService;

  /// For the Units row's `km · L · €` summary.
  final DistanceUnit distanceUnit;

  /// The same.
  final VolumeUnit volumeUnit;

  /// The same.
  final String currencyCode;

  /// For the Language row's value.
  final String language;
}

/// Which backup state [lastBackupAtUtcMs] puts the row in.
///
/// The comparison is `>` on days, so exactly 90 days is still `recent` and 91
/// is `stale`. A boundary written as `>=` moves the whole rule by a day and
/// nobody notices for three months.
BackupState backupStateFor({
  required int? lastBackupAtUtcMs,
  required CivilDate? today,
  required bool migrationFailed,
}) {
  // FIRST, before anything about the backup itself. §13 opens the app on
  // `settings.backup` when a migration failed, and the row has to say why —
  // "last backup 3 days ago" over a database the app could not finish
  // updating is the reassuring half of a sentence whose other half matters.
  if (migrationFailed) return BackupState.migrationFailed;
  if (lastBackupAtUtcMs == null) return BackupState.never;
  if (today == null) return BackupState.recent;

  final on = CivilDate.fromDateTime(
    DateTime.fromMillisecondsSinceEpoch(lastBackupAtUtcMs, isUtc: true),
  );
  if (on == null) return BackupState.recent;

  // `>`, so exactly 90 days is still recent and 91 is stale. A boundary
  // written `>=` moves the whole rule by a day and nobody notices for three
  // months.
  return on.daysUntil(today) > kBackupStaleDays
      ? BackupState.stale
      : BackupState.recent;
}

/// §13's tab-4 state.
final Provider<SettingsRootState> settingsRootProvider =
    Provider<SettingsRootState>((ref) {
      final settings = ref.watch(settingsProvider).value;
      final vehicles = ref.watch(vehiclesProvider).value ?? const <Vehicle>[];
      final facts = ref.watch(launchFactsProvider);
      // `todayProvider`, not `clockProvider`. Both are injected seams and both
      // are honest about time being an argument, but the clock throws until
      // `bootstrap()` overrides it — and this provider is read while the FIRST
      // frame paints, including on the failed-migration path where the app
      // opens straight onto Backup. `todayProvider` is null until it is set,
      // which is a state this screen can render: §13 says the row's age line
      // is the one thing on it that is not a constant.
      final today = ref.watch(todayProvider);

      return SettingsRootState(
        backup: backupStateFor(
          lastBackupAtUtcMs: settings?.lastBackupAtUtcMs,
          today: today,
          migrationFailed: facts.migrationFailed,
        ),
        today: today,
        vehicles: vehicles,
        theme: settings?.theme ?? 'system',
        lastBackupAtUtcMs: settings?.lastBackupAtUtcMs,
        notificationTimeMinutes: settings?.notificationTimeMinutes ?? 9 * 60,
        notifyService: settings?.notifyService ?? true,
        distanceUnit: settings?.distanceUnit ?? DistanceUnit.km,
        volumeUnit: settings?.volumeUnit ?? VolumeUnit.l,
        currencyCode: settings?.currencyDefault.code ?? 'EUR',
        language: settings?.language ?? 'system',
      );
    });
