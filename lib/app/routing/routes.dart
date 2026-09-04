// Every location in the app, in one place.
//
// SPEC.md §7 lists 28 screens. This file is the single registry of what they
// are called and where they live, and it is the only place a path literal is
// allowed to appear — a `context.go('/settings/untis')` typo elsewhere is a
// silent 404 that nobody notices until a user reports it, while a typo here is
// caught by `route_table_test.dart` on the next run.
//
// No Flutter import on purpose. The table is data; `app_router.dart` turns it
// into a navigation graph, and EPIC-18's parity harness reads the same table
// rather than keeping a second list of screens.

/// How a screen in `design/calm/screens.html` is reached.
///
/// Two kinds and no third: a screen either has a URL or it is a dialog.
sealed class ScreenRoute {
  const ScreenRoute();

  /// A screen with a URL.
  const factory ScreenRoute.location(String path) = ScreenLocation;

  /// A dialog, which has none.
  const factory ScreenRoute.dialog(String id) = ScreenDialog;
}

/// A screen reachable by URL.
final class ScreenLocation extends ScreenRoute {
  /// Creates the location.
  const ScreenLocation(this.path);

  /// The path, with `:param` for any segment that carries an id.
  final String path;

  @override
  String toString() => 'ScreenLocation($path)';
}

/// A screen that is a dialog, and therefore has no URL.
///
/// A dialog returns a DECISION to whoever opened it, and a URL cannot carry one
/// back. A deep link into "discard changes?" is meaningless besides: on a cold
/// start there is nothing to discard.
final class ScreenDialog extends ScreenRoute {
  /// Creates the dialog entry.
  const ScreenDialog(this.id);

  /// The `data-screen` id.
  final String id;

  @override
  String toString() => 'ScreenDialog($id)';
}

/// The four segments of the log modal.
///
/// **Not `RecordIdKind`.** That enum has nine members and names the nine
/// entities that own an id; these four name the segments of one modal, and the
/// two disagree on purpose — the log modal's `service` segment writes a service
/// RECORD (`srv_`), never a service item (`rem_`), and there is no log segment
/// for a service line, an odometer correction or a vehicle.
enum LogType {
  /// Fuel. The default segment — see [Routes.log].
  fillUp,

  /// Service work that was done.
  service,

  /// Anything else that cost money.
  expense,

  /// A reading on its own.
  odometer;

  /// The `:type` path segment. ASCII, lower-case, never localised.
  ///
  /// Derived rather than declared, and that is the whole point. Written the
  /// obvious way — `fillUp('fillup')` — this file would declare four wire
  /// strings that `OdometerSource` in `lib/core/domain/enums.dart` also
  /// declares, and `test/policy/one_money_type_test.dart` calls that two
  /// vocabularies for one setting. Here it IS coincidence of English rather
  /// than shared meaning: `OdometerSource.service` means "this reading came
  /// from a service record" and this means "the log modal is on the Service
  /// segment", and the sets differ besides — `OdometerSource` has no
  /// `odometer` (its equivalent is `manual`) and carries three values no URL
  /// ever names. But a caller cannot see that from the call site, and three of
  /// the four would write into `odometer_readings.source` and look right.
  ///
  /// [name] lower-cased is only safe because [screenId] is asserted against
  /// `kScreenRoutes` — and through it against `design/calm/screens.html` — by
  /// `route_table_test.dart`. A fifth member whose name is not a single
  /// lower-case word goes red there before it reaches a URL.
  String get wire => name.toLowerCase();

  /// The `data-screen` id this segment opens.
  String get screenId => 'log.$wire';

  /// [wire] back to a member, or null if the URL carries something else.
  ///
  /// Null rather than a throw: this reads a segment a user could have typed, or
  /// that an old notification could be carrying after a rename, and an unknown
  /// one lands on the 404 like any other bad link.
  static LogType? tryParse(String wire) {
    for (final type in values) {
      if (type.wire == wire) return type;
    }
    return null;
  }
}

/// The path Odova uses for a record that does not exist yet.
///
/// `/reminders/new` and `/settings/vehicles/new` create; the same path with an
/// id edits. One route, two modes, and the builder tells them apart by this
/// constant — which is why no id may ever be the string `new`. Every id in the
/// app is `<prefix>_<26 Crockford characters>`, so none can be.
const kNewRecordId = 'new';

/// Every location, as a constant or a builder.
///
/// A `static String` builder per id-bearing route rather than a format string
/// at the call site: the id goes in through a named parameter, so the compiler
/// checks that a vehicle id is not being passed to the trip route.
abstract final class Routes {
  /// Tab 1's root, and the only question the app exists to answer.
  static const home = '/';

  /// The vehicle switcher sheet.
  static const vehicleSwitcher = '/vehicle-switcher';

  /// The reminder list.
  static const reminders = '/reminders';

  /// One reminder, in edit mode.
  static String reminderEdit(String reminderId) => '/reminders/$reminderId';

  /// The reminder editor, creating.
  static const reminderNew = '/reminders/$kNewRecordId';

  /// The log modal, on [type]'s segment.
  static String log(LogType type) => '/log/${type.wire}';

  /// The log modal, editing an existing entry.
  static String logEdit(LogType type, String entryId) =>
      '/log/${type.wire}/$entryId';

  /// Tab 2's root.
  static const history = '/history';

  /// The service report, inside History.
  static const serviceReport = '/history/report';

  /// Tab 3's root.
  static const costs = '/costs';

  /// Fuel costs.
  static const costsFuel = '/costs/fuel';

  /// The trip list.
  static const trips = '/costs/trips';

  /// One trip, in edit mode.
  static String tripEdit(String tripId) => '/costs/trips/$tripId';

  /// The trip editor, creating.
  static const tripNew = '/costs/trips/$kNewRecordId';

  /// History again, as a second instance inside the Costs stack.
  ///
  /// Deliberately a second route to the same screen. SPEC.md §7: a cross-tab
  /// data jump pushes into the CURRENT tab, because the app never switches tabs
  /// under the user's finger — so "show me the fill-ups behind this figure"
  /// from Costs pushes here rather than selecting the History tab and throwing
  /// away where the user was.
  static const costsHistory = '/costs/history';

  /// Tab 4's root.
  static const settings = '/settings';

  /// The garage.
  static const vehicles = '/settings/vehicles';

  /// One vehicle, in edit mode.
  static String vehicleEdit(String vehicleId) =>
      '/settings/vehicles/$vehicleId';

  /// The vehicle editor, creating.
  static const vehicleNew = '/settings/vehicles/$kNewRecordId';

  /// Language and region.
  static const settingsLanguage = '/settings/language';

  /// Units and currency.
  static const settingsUnits = '/settings/units';

  /// Notifications.
  static const settingsNotifications = '/settings/notifications';

  /// Backup.
  static const settingsBackup = '/settings/backup';

  /// Import, which REPLACES. A modal above backup, and never a tab root.
  static const settingsImport = '/settings/backup/import';

  /// About.
  static const settingsAbout = '/settings/about';

  /// First run, step one.
  static const firstRunLanguage = '/first-run/language';

  /// First run, step two.
  static const firstRunVehicle = '/first-run/vehicle';

  /// The four locations a tab is rooted at, in tab order.
  ///
  /// Read by the shell, by the depth test and by `resetAllTabStacks`, so the
  /// order lives here once rather than in three places that can disagree.
  static const List<String> tabRoots = [home, history, costs, settings];
}

/// Every `data-screen` id in `design/calm/screens.html`, and how it is reached.
///
/// The registry. `route_table_test.dart` reads the design file itself and
/// asserts this map covers all 28 ids with no extras, so the day a designer
/// adds an artboard nobody routed, the suite says so — rather than a feature
/// epic discovering it three months later.
const kScreenRoutes = <String, ScreenRoute>{
  'home': ScreenRoute.location(Routes.home),
  'vehicle.switcher': ScreenRoute.location(Routes.vehicleSwitcher),
  'reminders.list': ScreenRoute.location(Routes.reminders),
  'reminders.edit': ScreenRoute.location('/reminders/:reminderId'),
  // The four log segments are four screens in the design and one route in the
  // graph, so each id maps to its own concrete URL and `/log/:type` matches
  // all four.
  'log.fillup': ScreenRoute.location('/log/fillup'),
  'log.service': ScreenRoute.location('/log/service'),
  'log.expense': ScreenRoute.location('/log/expense'),
  'log.odometer': ScreenRoute.location('/log/odometer'),
  'history': ScreenRoute.location(Routes.history),
  'report.service': ScreenRoute.location(Routes.serviceReport),
  'costs': ScreenRoute.location(Routes.costs),
  'costs.fuel': ScreenRoute.location(Routes.costsFuel),
  'trips.list': ScreenRoute.location(Routes.trips),
  'trips.edit': ScreenRoute.location('/costs/trips/:tripId'),
  'settings': ScreenRoute.location(Routes.settings),
  'vehicles': ScreenRoute.location(Routes.vehicles),
  'vehicle.edit': ScreenRoute.location('/settings/vehicles/:vehicleId'),
  'settings.language': ScreenRoute.location(Routes.settingsLanguage),
  'settings.units': ScreenRoute.location(Routes.settingsUnits),
  'settings.notifications': ScreenRoute.location(Routes.settingsNotifications),
  'settings.backup': ScreenRoute.location(Routes.settingsBackup),
  'settings.import': ScreenRoute.location(Routes.settingsImport),
  'settings.about': ScreenRoute.location(Routes.settingsAbout),
  'firstrun.language': ScreenRoute.location(Routes.firstRunLanguage),
  'firstrun.vehicle': ScreenRoute.location(Routes.firstRunVehicle),
  // The three global dialogs. SPEC.md §7 groups them as global because they
  // belong to no feature: every screen that edits can discard, every screen
  // that deletes confirms, and both Home and the reminder list snooze.
  'dialog.discard': ScreenRoute.dialog('dialog.discard'),
  'dialog.confirmDelete': ScreenRoute.dialog('dialog.confirmDelete'),
  'dialog.snooze': ScreenRoute.dialog('dialog.snooze'),
};
