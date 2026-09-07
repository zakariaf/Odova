// The `settings` object, as SPEC.md §6 §2.5 writes it.
//
// The times are WALL-CLOCK strings — `"09:00"`, not minutes past midnight —
// because §6's file is meant to be readable in a text editor, and `540` is a
// number a human has to decode. The database stores minutes because arithmetic
// on them is what the scheduler does; the file stores the thing a person reads.
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/features/backup/domain/mapping/backup_values.dart';

/// Minutes past midnight as `HH:mm`, zero-padded and ASCII.
///
/// ASCII whatever the app's numeral setting: §6 says every digit in the file is
/// ASCII 0-9, because a backup with Persian digits in its timestamps is a
/// backup that only opens on a Persian device — which is the one thing a
/// backup must never be.
String wallClock(int minutes) {
  final clamped = minutes.clamp(0, 24 * 60 - 1);
  final hh = (clamped ~/ 60).toString().padLeft(2, '0');
  final mm = (clamped % 60).toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// [settings] as its JSON object, in §6 §2.5's key order.
///
/// `last_backup_reminder_at` is absent, and so is the internal
/// `schema_version`: §6 §7 excludes both. The reminder timestamp is
/// device-local nagging state that means nothing on another phone, and the
/// schema version belongs to the DATABASE while `format_version` in the
/// envelope belongs to the file — conflating them is how a reader decides it
/// cannot open a file it could read perfectly well.
Map<String, Object?> settingsBackupJson(AppSettings settings) => {
  'language': settings.language,
  'theme': settings.theme,
  'currency_default': settings.currencyDefault.code,
  // `none` or `toman`, and the STORED currency stays IRR either way. §5 makes
  // the toman a display convention worth ten rials and not a currency, and a
  // non-ISO code in a backup is a code no other tool can resolve.
  'currency_display': settings.currencyDisplay,
  'distance_unit': settings.distanceUnit.wire,
  'volume_unit': settings.volumeUnit.wire,
  'consumption_unit': settings.consumptionUnit.wire,
  'first_day_of_week': settings.firstDayOfWeek,
  'calendar': settings.calendar,
  'numerals': settings.numerals,
  'notification_time': wallClock(settings.notificationTimeMinutes),
  'quiet_hours_from': wallClock(settings.quietHoursFromMinutes),
  'quiet_hours_to': wallClock(settings.quietHoursToMinutes),
  'weekdays_only': settings.weekdaysOnly,
  'notify_service': settings.notifyService,
  'notify_odometer': settings.notifyOdometer,
  'notify_backup': settings.notifyBackup,
  'notice_days': settings.noticeDays,
  'notice_distance_m': metresOrNull(settings.noticeDistance),
  'active_vehicle_id': settings.activeVehicleId?.toString(),
  'last_backup_at': rfc3339OrNull(settings.lastBackupAtUtcMs),
};
