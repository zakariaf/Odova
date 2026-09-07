// The three settings the FILE does not get the last word on — SPEC.md §6 §4.2.
//
// Everything else in the file is the user's data and wins. These three are
// about the device the file is landing on, and a file that decided them would
// leave the user somewhere they cannot get out of: an active vehicle that does
// not exist, or a first-run flow they have to walk through again on a phone
// that now holds eight years of history.
//
// Pure, and separate from the importer, because it is the one part of an import
// that is a DECISION rather than a write.
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/domain/models/store_snapshot.dart';
import 'package:odova/core/ids/record_id.dart';

/// [store] with its settings settled, and the vehicle to select afterwards.
///
/// TWO values and not one, because the active vehicle does not travel in the
/// settings row. `test/app/active_vehicle_test.dart` asserts that exactly one
/// place in the app selects a vehicle — selecting one has to reset the tab
/// stack, and after an import that is not optional: the stack holds routes for
/// a car that no longer exists. So the choice is MADE here, where the rule
/// lives, and APPLIED by the importer through `setActiveVehicle`.
///
/// [preferred] is the file's own `active_vehicle_id`, carried on the plan
/// rather than in the settings row — see `ImportPlan.preferredActiveVehicleId`.
///
/// Everything else the file says about preferences is APPLIED: language,
/// direction, units, calendar, numerals, notification time. Restoring onto a
/// new phone must give back the app you had, not a German one on a German
/// handset.
({StoreSnapshot store, VehicleId? activeVehicle}) settleImportedSettings(
  StoreSnapshot store, {
  VehicleId? preferred,
}) {
  final ids = {for (final vehicle in store.vehicles) vehicle.id};

  // A file whose active vehicle is not in it — because the vehicle was an
  // orphan's, or the file was hand-edited — promotes the first by sort order.
  // Null would be a garage that opens on nothing, and §7 has no such state.
  final active = preferred != null && ids.contains(preferred)
      ? preferred
      : _firstBySortOrder(store);

  final settings = store.settings;
  final settled = StoreSnapshot(
    settings: AppSettings(
      schemaVersion: settings.schemaVersion,
      currencyDefault: settings.currencyDefault,
      createdAtUtcMs: settings.createdAtUtcMs,
      updatedAtUtcMs: settings.updatedAtUtcMs,
      // Applied from the file, all of it. Restoring onto a new phone gives
      // back the app you had.
      language: settings.language,
      calendar: settings.calendar,
      numerals: settings.numerals,
      firstDayOfWeek: settings.firstDayOfWeek,
      theme: settings.theme,
      currencyDisplay: settings.currencyDisplay,
      distanceUnit: settings.distanceUnit,
      volumeUnit: settings.volumeUnit,
      consumptionUnit: settings.consumptionUnit,
      noticeDistance: settings.noticeDistance,
      noticeDays: settings.noticeDays,
      notificationTimeMinutes: settings.notificationTimeMinutes,
      quietHoursFromMinutes: settings.quietHoursFromMinutes,
      quietHoursToMinutes: settings.quietHoursToMinutes,
      weekdaysOnly: settings.weekdaysOnly,
      notifyService: settings.notifyService,
      notifyOdometer: settings.notifyOdometer,
      notifyBackup: settings.notifyBackup,
      lastBackupAtUtcMs: settings.lastBackupAtUtcMs,
      // Never read from the file. A restored phone has data on it, so the
      // first-run flow is finished by definition — and a file written before
      // onboarding existed would otherwise send the user back through it.
      onboardingDone: true,
    ),
    vehicles: store.vehicles,
    reminders: store.reminders,
    odometerReadings: store.odometerReadings,
    odometerCorrections: store.odometerCorrections,
    fillUps: store.fillUps,
    services: store.services,
    expenses: store.expenses,
    trips: store.trips,
  );
  return (store: settled, activeVehicle: active);
}

VehicleId? _firstBySortOrder(StoreSnapshot store) {
  if (store.vehicles.isEmpty) return null;
  final ordered = [...store.vehicles]
    ..sort((a, b) {
      final bySort = a.sortOrder.compareTo(b.sortOrder);
      // Ties broken by id, which for a ULID is creation order — so two
      // vehicles at sort order 0 promote the same one on every device.
      return bySort != 0 ? bySort : a.id.toString().compareTo(b.id.toString());
    });
  return ordered.first.id;
}
