// The one list of what the sweep photographs.
//
// Every feature epic wrote its own `<screen>_parity_test.dart`, and 28 separate
// files catch per-screen drift and nothing else. Two things they cannot catch:
// a screen nobody wrote a file for — `costs.fuel`, `trips.list`, `trips.edit`
// and six `settings.*` screens each had a reference image, a route and no
// capture — and the cross-screen drift this epic exists for, which only shows
// up when all 28 run in one command.
//
// A capture is a FUNCTION here rather than a widget, because the four log
// modals type into their fields, the three dialogs stack over a backdrop and
// `reminders.edit` overrides a notifier into its loaded state. Anything less
// than a closure would need a parameter per screen shape, and the fifth one
// would arrive next epic.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'captures/costs.dart';
import 'captures/costs_fuel.dart';
import 'captures/dialog_confirm_delete.dart';
import 'captures/dialog_discard.dart';
import 'captures/dialog_snooze.dart';
import 'captures/firstrun_language.dart';
import 'captures/firstrun_vehicle.dart';
import 'captures/history.dart';
import 'captures/home.dart';
import 'captures/log_expense.dart';
import 'captures/log_fillup.dart';
import 'captures/log_odometer.dart';
import 'captures/log_service.dart';
import 'captures/reminders_edit.dart';
import 'captures/reminders_list.dart';
import 'captures/report_service.dart';
import 'captures/settings.dart';
import 'captures/settings_about.dart';
import 'captures/settings_backup.dart';
import 'captures/settings_import.dart';
import 'captures/settings_language.dart';
import 'captures/settings_notifications.dart';
import 'captures/settings_units.dart';
import 'captures/trips_edit.dart';
import 'captures/trips_list.dart';
import 'captures/vehicle_edit.dart';
import 'captures/vehicle_switcher.dart';
import 'captures/vehicles.dart';
import 'support/parity_capture.dart';

/// Shoots one screen in one of the four combinations.
typedef ParityCapture =
    Future<void> Function(WidgetTester tester, ParityCase config);

/// One screen in the sweep.
typedef ParityScreen = ({String id, ParityCapture capture});

/// All 28, in `design/calm/screens.html` order.
///
/// The order is the design file's rather than alphabetical, so a person reading
/// this list and a person reading the artboards are walking the same app.
const List<ParityScreen> kParityScreens = [
  (id: 'firstrun.language', capture: captureFirstrunLanguage),
  (id: 'firstrun.vehicle', capture: captureFirstrunVehicle),
  (id: 'home', capture: captureHome),
  (id: 'vehicle.switcher', capture: captureVehicleSwitcher),
  (id: 'reminders.list', capture: captureRemindersList),
  (id: 'reminders.edit', capture: captureRemindersEdit),
  (id: 'log.fillup', capture: captureLogFillup),
  (id: 'log.service', capture: captureLogService),
  (id: 'log.expense', capture: captureLogExpense),
  (id: 'log.odometer', capture: captureLogOdometer),
  (id: 'history', capture: captureHistory),
  (id: 'report.service', capture: captureReportService),
  (id: 'costs', capture: captureCosts),
  (id: 'costs.fuel', capture: captureCostsFuel),
  (id: 'trips.list', capture: captureTripsList),
  (id: 'trips.edit', capture: captureTripsEdit),
  (id: 'settings', capture: captureSettings),
  (id: 'vehicles', capture: captureVehicles),
  (id: 'vehicle.edit', capture: captureVehicleEdit),
  (id: 'settings.language', capture: captureSettingsLanguage),
  (id: 'settings.units', capture: captureSettingsUnits),
  (id: 'settings.notifications', capture: captureSettingsNotifications),
  (id: 'settings.backup', capture: captureSettingsBackup),
  (id: 'settings.import', capture: captureSettingsImport),
  (id: 'settings.about', capture: captureSettingsAbout),
  (id: 'dialog.discard', capture: captureDialogDiscard),
  (id: 'dialog.confirmDelete', capture: captureDialogConfirmdelete),
  (id: 'dialog.snooze', capture: captureDialogSnooze),
];
