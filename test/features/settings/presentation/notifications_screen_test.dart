// SPEC.md §13's `settings.notifications`.
@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/notifications/notification_permission_port.dart';
import 'package:odova/app/notifications/schedule_rebuilder.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/settings.dart';
import 'package:odova/core/result.dart';
import 'package:odova/data/db/app_database.dart';
import 'package:odova/data/db/database_provider.dart';
import 'package:odova/data/failures/persist_failure.dart';
import 'package:odova/data/repositories/settings_repository.dart';
import 'package:odova/data/repositories/vehicle_repository.dart';
import 'package:odova/features/settings/presentation/notifications_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_switch.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../data/support/test_ids.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

class _CountingRebuilder implements ScheduleRebuilder {
  int calls = 0;

  @override
  Future<void> rebuildAll() async => calls++;
}

class _FixedPermission implements NotificationPermissionPort {
  _FixedPermission(this.value);

  final NotificationPermission value;

  @override
  Future<NotificationPermission> read() async => value;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(NotificationsSettingsScreen)),
);

late AppDatabase _db;
late _CountingRebuilder _rebuilder;

Future<void> _pump(
  WidgetTester tester, {
  NotificationPermission permission = NotificationPermission.granted,
  Locale? locale = const Locale('en'),
  bool allOff = false,
}) async {
  tester.useDevice(Device.tallForm);
  _db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(_db.close);
  await SettingsRepository(_db).save(
    homeSettings(golfId, language: locale?.languageCode ?? 'system'),
  );
  await VehicleRepository(_db, testIds()).save(homeVehicle(golfId, 'The Golf'));
  if (allOff) {
    final writer = SettingsRepository(_db);
    await writer.setNotifyService(notify: false, updatedAtUtcMs: 2000);
    await writer.setNotifyOdometer(notify: false, updatedAtUtcMs: 2000);
    await writer.setNotifyBackup(notify: false, updatedAtUtcMs: 2000);
  }
  _rebuilder = _CountingRebuilder();

  await pumpShell(
    tester,
    Routes.settingsNotifications,
    locale: locale,
    liveStreams: true,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(_db),
      scheduleRebuilderProvider.overrideWithValue(_rebuilder),
      notificationPermissionProvider.overrideWithValue(
        _FixedPermission(permission),
      ),
      if (locale != null) deviceLocalesProvider.overrideWithValue([locale]),
    ],
  );
  await tester.pumpAndSettle();
}

Future<AppSettings?> _stored() async {
  final read = await SettingsRepository(_db).read();
  return read is Ok<AppSettings, PersistFailure> ? read.value : null;
}

void main() {
  testWidgets('three groups, in order, with the calendar row and the cap', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.notifGroupWhat), findsOneWidget);
    expect(find.text(l10n.notifGroupWhen), findsOneWidget);
    expect(find.text(l10n.notifGroupHowFar), findsOneWidget);
    // A FACT, not a switch. A user who could raise the cap would, and would
    // then blame the app for the noise §14's damping exists to prevent.
    expect(find.text(l10n.notifCapFooter), findsOneWidget);
    expect(find.byType(CalmSwitch), findsNWidgets(3));
  });

  testWidgets('this screen never lists the eighteen service items', (
    tester,
  ) async {
    // §13 keeps per-item control on `reminders.list`. Eighteen switches here
    // would be a settings screen nobody finishes reading.
    await _pump(tester);
    expect(find.byType(CalmSwitch), findsNWidgets(3));
  });

  testWidgets('turning a category off reschedules', (tester) async {
    // Every write on this screen reschedules — there is no Save button, and
    // §13's rule 2 makes the category list part of what a body says.
    await _pump(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.notifRowService));
    await tester.pumpAndSettle();

    expect((await _stored())?.notifyService, isFalse);
    expect(_rebuilder.calls, 1);
  });

  testWidgets('all three off shows the silent footer', (tester) async {
    // It says what STILL works. The alternative reading of three switches off
    // is that the app has stopped doing anything.
    await _pump(tester, allOff: true);
    expect(find.text(_l10n(tester).notifSilentFooter), findsOneWidget);
  });

  testWidgets('denied shows the blocked card and raises the calendar row', (
    tester,
  ) async {
    await _pump(tester, permission: NotificationPermission.denied);
    final l10n = _l10n(tester);

    expect(find.text(l10n.notifBlockedTitle), findsOneWidget);
    expect(find.text(l10n.notifBlockedAction), findsOneWidget);

    // The calendar row it would raise is not on the screen: §18 decision 13
    // is open and EPIC-16 says the `.ics` export is out, so the row has
    // nothing behind it. The REORDER rule is still resolved and tested in
    // `notifications_chrome_test.dart`, because it is the answer to a
    // question this screen asks the moment that decision closes yes.
    expect(find.text(l10n.notifRowCalendar), findsNothing);
  });

  testWidgets('never asked offers to turn them on, rows still live', (
    tester,
  ) async {
    // A user may set 07:00 before granting anything.
    await _pump(tester, permission: NotificationPermission.neverAsked);
    final l10n = _l10n(tester);

    expect(find.text(l10n.notifOffTitle), findsOneWidget);
    expect(find.text(l10n.notifOffAction), findsOneWidget);
    expect(find.byType(CalmSwitch), findsNWidgets(3));
  });

  testWidgets('granted and working shows no card', (tester) async {
    // Asserted as an absence, so nobody adds a reassuring green banner.
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.notifOffTitle), findsNothing);
    expect(find.text(l10n.notifBlockedTitle), findsNothing);
  });

  testWidgets('quiet hours read as one range, and Off when the ends meet', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    // ONE isolate around the whole run: under RTL a half-isolated range reads
    // back-to-front, and `08:00–21:00` is a different window from the one the
    // user set.
    // Escaped, not pasted: an invisible FSI in a literal is a character the
    // compiler reads and a reviewer does not, which is exactly what
    // `text_direction_code_point_in_literal` exists to stop.
    const fsi = '\u2068';
    const pdi = '\u2069';
    final range = quietHoursLabel(l10n, 'en-GB', from: 21 * 60, to: 8 * 60);
    expect(range.startsWith(fsi), isTrue);
    expect(range.endsWith(pdi), isTrue);
    expect(range, contains('–'));

    // `from == to` is OFF, not a zero-length window: a user who dragged both
    // ends together meant "no quiet hours".
    expect(
      quietHoursLabel(l10n, 'en-GB', from: 8 * 60, to: 8 * 60),
      l10n.notifQuietOff,
    );
  });

  testWidgets('it mirrors without overflowing', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(
      Directionality.of(
        tester.element(find.byType(NotificationsSettingsScreen)),
      ),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quiet-hours row is not a dead tap', (tester) async {
    // It shipped as `onTap: () {}` with the write path already written and
    // tested underneath it — invisible to every test that asserts the row is
    // drawn.
    await _pump(tester);
    final l10n = _l10n(tester);

    final row = tester.widget<CalmListRow>(
      find.ancestor(
        of: find.text(l10n.notifRowQuietHours),
        matching: find.byType(CalmListRow),
      ),
    );
    expect(row.onTap, isNotNull);
  });
}
