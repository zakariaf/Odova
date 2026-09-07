// The one way Settings writes, and the one place the reschedule rule lives.
//
// SPEC.md §13's two cross-cutting rules for the whole section:
//
//   1. Every settings screen reads one immutable value and writes through one
//      method. No widget and no notifier touches a DAO.
//   2. A write that changes user-visible TEXT cancels, re-renders and
//      reschedules every pending notification.
//
// Rule 2 is the one worth a gate. Notification bodies are baked into the OS at
// schedule time, so a language change without a reschedule leaves German text
// arriving on a Persian phone for four months — and the user has no way to
// discover why. The eight keys that affect text are listed ONCE here, in
// `_reschedules`, rather than at each call site, so the list cannot drift as
// keys are added: a new setter that forgets to reschedule is a new setter
// missing from one set, not a rule broken in one of nineteen places.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/core/l10n/numerals.dart';
import 'package:odova/core/money/currency.dart';
import 'package:odova/core/result.dart';
import 'package:odova/core/units/consumption.dart';
import 'package:odova/core/units/distance.dart';
import 'package:odova/core/units/volume.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/providers.dart';
import 'package:odova/data/repositories/settings_repository.dart';

/// Which setting is being written.
///
/// An enum and not a string, so `_reschedules` below is a set the compiler
/// checks rather than a list of spellings.
enum SettingsKey {
  /// The UI language.
  language,

  /// The display calendar.
  calendar,

  /// The numeral system.
  numerals,

  /// The ISO-8601 first day of week.
  firstDayOfWeek,

  /// The theme.
  theme,

  /// The default currency.
  currencyDefault,

  /// The currency display mode.
  currencyDisplay,

  /// The distance unit.
  distanceUnit,

  /// The volume unit.
  volumeUnit,

  /// The consumption unit.
  consumptionUnit,

  /// The distance notice window.
  noticeDistance,

  /// The date notice window.
  noticeDays,

  /// The daily delivery time.
  notificationTime,

  /// The quiet-hours window.
  quietHours,

  /// Whether delivery is restricted to weekdays.
  weekdaysOnly,

  /// The service-reminder category.
  notifyService,

  /// The odometer-nudge category.
  notifyOdometer,

  /// The backup-reminder category.
  notifyBackup,
}

/// §13's rule-2 list: the keys whose value reaches a notification's TEXT or
/// its delivery, and therefore require a rebuild.
///
/// `theme` is deliberately absent — a theme changes no text, and rescheduling
/// every pending notification because somebody tapped Dark is churn the
/// hysteresis in §6.2 exists to avoid.
const Set<SettingsKey> kTextAffectingKeys = {
  SettingsKey.language,
  SettingsKey.numerals,
  SettingsKey.calendar,
  SettingsKey.distanceUnit,
  SettingsKey.notificationTime,
  SettingsKey.quietHours,
  SettingsKey.weekdaysOnly,
  SettingsKey.notifyService,
};

/// Every settings write in the app.
class SettingsWriter {
  /// Creates a writer.
  const SettingsWriter(this._ref);

  final Ref _ref;

  SettingsRepository get _store => _ref.read(settingsRepositoryProvider);

  int get _now => _ref.read(clockProvider).now().millisecondsSinceEpoch;

  /// Sets the UI language.
  Future<Result<void, PersistFailure>> setLanguage(String language) => _gate(
    SettingsKey.language,
    () => _store.setLanguage(language, updatedAtUtcMs: _now),
  );

  /// Sets the display calendar.
  Future<Result<void, PersistFailure>> setCalendar(String calendar) => _gate(
    SettingsKey.calendar,
    () => _store.setCalendar(calendar, updatedAtUtcMs: _now),
  );

  /// Sets the numeral system.
  Future<Result<void, PersistFailure>> setNumerals(CalmNumerals numerals) =>
      _gate(
        SettingsKey.numerals,
        () => _store.setNumerals(numerals.wire, updatedAtUtcMs: _now),
      );

  /// Sets the first day of week, as an ISO-8601 weekday.
  ///
  /// Refused outside 1..7 rather than clamped. It is a weekday, never `"mon"`
  /// and never zero-based, and a value the caller got wrong is a bug to see
  /// rather than a number to guess at.
  Future<Result<void, PersistFailure>> setFirstDayOfWeek(int day) async {
    if (day < DateTime.monday || day > DateTime.sunday) {
      return Err(
        WriteFailed('first day of week must be an ISO weekday 1..7, got $day'),
      );
    }
    return _gate(
      SettingsKey.firstDayOfWeek,
      () => _store.setFirstDayOfWeek(day, updatedAtUtcMs: _now),
    );
  }

  /// Sets the theme.
  Future<Result<void, PersistFailure>> setTheme(String theme) => _gate(
    SettingsKey.theme,
    () => _store.setTheme(theme, updatedAtUtcMs: _now),
  );

  /// Sets the default currency.
  Future<Result<void, PersistFailure>> setCurrencyDefault(Currency currency) =>
      _gate(
        SettingsKey.currencyDefault,
        () => _store.setCurrencyDefault(currency, updatedAtUtcMs: _now),
      );

  /// Sets the currency display mode.
  Future<Result<void, PersistFailure>> setCurrencyDisplay(String display) =>
      _gate(
        SettingsKey.currencyDisplay,
        () => _store.setCurrencyDisplay(display, updatedAtUtcMs: _now),
      );

  /// Sets the distance unit.
  Future<Result<void, PersistFailure>> setDistanceUnit(DistanceUnit unit) =>
      _gate(
        SettingsKey.distanceUnit,
        () => _store.setDistanceUnit(unit, updatedAtUtcMs: _now),
      );

  /// Sets the volume unit.
  Future<Result<void, PersistFailure>> setVolumeUnit(VolumeUnit unit) => _gate(
    SettingsKey.volumeUnit,
    () => _store.setVolumeUnit(unit, updatedAtUtcMs: _now),
  );

  /// Sets the consumption unit.
  Future<Result<void, PersistFailure>> setConsumptionUnit(
    ConsumptionUnit unit,
  ) => _gate(
    SettingsKey.consumptionUnit,
    () => _store.setConsumptionUnit(unit, updatedAtUtcMs: _now),
  );

  /// Sets the distance notice window.
  Future<Result<void, PersistFailure>> setNoticeDistance(Distance? distance) =>
      _gate(
        SettingsKey.noticeDistance,
        () => _store.setNoticeDistance(distance, updatedAtUtcMs: _now),
      );

  /// Sets the date notice window, in days.
  ///
  /// Written as given. §3's 7..30 clamp defines the COMPUTED default only, and
  /// silently clamping a number the user typed makes the field lie back at
  /// them.
  Future<Result<void, PersistFailure>> setNoticeDays(int? days) => _gate(
    SettingsKey.noticeDays,
    () => _store.setNoticeDays(days, updatedAtUtcMs: _now),
  );

  /// Sets the daily delivery time, in minutes past midnight.
  Future<Result<void, PersistFailure>> setNotificationTime(int minutes) =>
      _gate(
        SettingsKey.notificationTime,
        () => _store.setNotificationTime(minutes, updatedAtUtcMs: _now),
      );

  /// Sets both ends of the quiet-hours window.
  Future<Result<void, PersistFailure>> setQuietHours({
    required int from,
    required int to,
  }) => _gate(
    SettingsKey.quietHours,
    () => _store.setQuietHours(
      fromMinutes: from,
      toMinutes: to,
      updatedAtUtcMs: _now,
    ),
  );

  /// Sets whether delivery is restricted to weekdays.
  Future<Result<void, PersistFailure>> setWeekdaysOnly({
    required bool weekdaysOnly,
  }) => _gate(
    SettingsKey.weekdaysOnly,
    () => _store.setWeekdaysOnly(
      weekdaysOnly: weekdaysOnly,
      updatedAtUtcMs: _now,
    ),
  );

  /// Sets the service-reminder category.
  Future<Result<void, PersistFailure>> setNotifyService({
    required bool notify,
  }) => _gate(
    SettingsKey.notifyService,
    () => _store.setNotifyService(notify: notify, updatedAtUtcMs: _now),
  );

  /// Sets the odometer-nudge category.
  Future<Result<void, PersistFailure>> setNotifyOdometer({
    required bool notify,
  }) => _gate(
    SettingsKey.notifyOdometer,
    () => _store.setNotifyOdometer(notify: notify, updatedAtUtcMs: _now),
  );

  /// Sets the backup-reminder category.
  Future<Result<void, PersistFailure>> setNotifyBackup({
    required bool notify,
  }) => _gate(
    SettingsKey.notifyBackup,
    () => _store.setNotifyBackup(notify: notify, updatedAtUtcMs: _now),
  );

  /// Runs [write], then reschedules if [key] affects notification text.
  ///
  /// **Only on success.** Rescheduling after a write that did not happen
  /// re-bakes every pending body from a value the database rejected, which is
  /// the OS holding text the app does not believe.
  Future<Result<void, PersistFailure>> _gate(
    SettingsKey key,
    Future<Result<void, PersistFailure>> Function() write,
  ) async {
    final result = await write();
    if (result is Err<void, PersistFailure>) return result;
    if (kTextAffectingKeys.contains(key)) {
      await _ref.read(scheduleRebuilderProvider).rebuildAll();
    }
    return result;
  }
}

/// The app's one settings writer.
final Provider<SettingsWriter> settingsWriterProvider =
    Provider<SettingsWriter>(
      SettingsWriter.new,
    );
