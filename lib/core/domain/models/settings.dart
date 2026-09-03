// The one settings row, as a value.
//
// SPEC.md §3 Entities (`Settings`), §3 Scope. Language, calendar, numerals,
// theme, notification settings, unit and currency defaults, the active vehicle
// and backup state are global; everything else hangs off a vehicle.
import 'package:odova/core/domain/enums.dart';
import 'package:odova/core/ids/record_id.dart';
import 'package:odova/core/value_equality.dart';

/// The application settings.
class AppSettings with ValueEquality {
  /// Creates settings.
  const AppSettings({
    required this.schemaVersion,
    required this.currencyDefault,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    this.language = 'system',
    this.calendar = 'gregorian',
    this.numerals = 'auto',
    this.firstDayOfWeek = DateTime.monday,
    this.theme = 'system',
    this.currencyDisplay = 'none',
    this.distanceUnit = DistanceUnit.km,
    this.volumeUnit = VolumeUnit.l,
    this.consumptionUnit = ConsumptionUnit.lPer100km,
    this.noticeDistanceM,
    this.noticeDays,
    this.notificationTimeMinutes = 9 * 60,
    this.quietHoursFromMinutes = 21 * 60,
    this.quietHoursToMinutes = 8 * 60,
    this.weekdaysOnly = false,
    this.notifyService = true,
    this.notifyOdometer = true,
    this.notifyBackup = true,
    this.activeVehicleId,
    this.onboardingDone = false,
    this.lastBackupAtUtcMs,
    this.lastBackupReminderAtUtcMs,
  });

  /// The row's fixed id.
  static const id = 'settings';

  /// Mirrors drift's `user_version`, which stays authoritative.
  ///
  /// This is what the EXPORT reads — the backup file needs the number without
  /// opening the database. Treating the two as independent is how a restore
  /// ends up believing a version the tables do not have.
  final int schemaVersion;

  /// `system` follows the device.
  final String language;

  /// `gregorian` or `persian`.
  final String calendar;

  /// Which digits are drawn.
  final String numerals;

  /// 1 = Monday, 7 = Sunday, as `DateTime`'s weekday constants.
  final int firstDayOfWeek;

  /// `system`, `light` or `dark`.
  final String theme;

  /// The ISO 4217 code new vehicles inherit.
  final String currencyDefault;

  /// `none` or `toman`. Storage stays IRR either way.
  final String currencyDisplay;

  /// Kilometres or miles.
  final DistanceUnit distanceUnit;

  /// Litres or gallons.
  final VolumeUnit volumeUnit;

  /// How consumption reads.
  final ConsumptionUnit consumptionUnit;

  /// Global distance notice window override, in metres.
  final int? noticeDistanceM;

  /// Global time notice window override, in days.
  final int? noticeDays;

  /// When the daily due check fires, as minutes after LOCAL midnight.
  final int notificationTimeMinutes;

  /// Quiet hours start, minutes after local midnight.
  final int quietHoursFromMinutes;

  /// Quiet hours end, minutes after local midnight.
  final int quietHoursToMinutes;

  /// Whether reminders only fire on weekdays.
  final bool weekdaysOnly;

  /// Whether service reminders fire.
  final bool notifyService;

  /// Whether the odometer nudge fires.
  final bool notifyOdometer;

  /// Whether the backup nudge fires.
  final bool notifyBackup;

  /// Which vehicle the app opens on.
  final VehicleId? activeVehicleId;

  /// Whether onboarding has been completed.
  final bool onboardingDone;

  /// When the last backup was written.
  final int? lastBackupAtUtcMs;

  /// When the app last nudged about a backup.
  final int? lastBackupReminderAtUtcMs;

  /// When the row was written.
  final int createdAtUtcMs;

  /// When it was last changed.
  final int updatedAtUtcMs;

  /// Whether [minutes] falls inside quiet hours.
  ///
  /// Handles the window that WRAPS midnight, which is the normal case: 21:00
  /// to 08:00 is quiet from 1260 to 1439 and again from 0 to 479, and treating
  /// it as a simple `from <= x < to` makes the whole night loud.
  bool isQuiet(int minutes) => quietHoursFromMinutes <= quietHoursToMinutes
      ? minutes >= quietHoursFromMinutes && minutes < quietHoursToMinutes
      : minutes >= quietHoursFromMinutes || minutes < quietHoursToMinutes;

  @override
  List<Object?> get props => [
    schemaVersion,
    language,
    calendar,
    numerals,
    firstDayOfWeek,
    theme,
    currencyDefault,
    currencyDisplay,
    distanceUnit,
    volumeUnit,
    consumptionUnit,
    noticeDistanceM,
    noticeDays,
    notificationTimeMinutes,
    quietHoursFromMinutes,
    quietHoursToMinutes,
    weekdaysOnly,
    notifyService,
    notifyOdometer,
    notifyBackup,
    activeVehicleId,
    onboardingDone,
    lastBackupAtUtcMs,
    lastBackupReminderAtUtcMs,
    createdAtUtcMs,
    updatedAtUtcMs,
  ];

  @override
  String toString() => 'AppSettings(v$schemaVersion, $language)';
}
