// SPEC.md §13's tab-4 root, as the user meets it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/domain/models/vehicle.dart';
import 'package:odova/features/settings/presentation/settings_screen.dart';
import 'package:odova/features/vehicles/presentation/vehicles_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/ui/calm/calm_list_row.dart';
import 'package:odova/ui/calm/calm_row_group.dart';
import 'package:odova/ui/calm/calm_segmented.dart';
import 'package:odova/ui/calm/calm_status_dot.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SettingsScreen)));

Future<void> _pump(
  WidgetTester tester, {
  int? lastBackupAtUtcMs,
  List<Vehicle>? vehicles,
  Locale? locale = const Locale('en'),
  Device device = Device.tallForm,
  TextScaler? textScaler,
}) async {
  tester.useDevice(device);
  final garage = vehicles ?? [homeVehicle(golfId, 'The Golf')];
  await pumpShell(
    tester,
    Routes.settings,
    locale: locale,
    settings: homeSettings(golfId, lastBackupAtUtcMs: lastBackupAtUtcMs),
    vehicles: garage,
    wrap: textScaler == null
        ? null
        : (app) => Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: app,
            ),
          ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Backup & restore is first, and alone in its group', (
    tester,
  ) async {
    // §13 gives one reason and it is the shape of the whole screen: the person
    // who needs Export is standing in a phone shop with a dead handset in
    // their pocket. This is the test that stops the next epic appending a
    // preference above it.
    await _pump(tester);
    final l10n = _l10n(tester);

    final firstGroup = tester.widget<CalmRowGroup>(
      find.byType(CalmRowGroup).first,
    );
    expect(firstGroup.rows, hasLength(1));

    final row = firstGroup.rows.single as CalmListRow;
    expect(row.title, l10n.settingsBackupRow);
  });

  testWidgets('never exported shows the amber line and the dot', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.settingsBackupNever), findsOneWidget);
    expect(find.byType(CalmStatusDot), findsOneWidget);
  });

  testWidgets('a recent backup shows its date and no dot', (tester) async {
    await _pump(
      tester,
      lastBackupAtUtcMs: DateTime.utc(2026, 8, 26).millisecondsSinceEpoch,
    );

    expect(find.textContaining('2026'), findsWidgets);
    expect(find.byType(CalmStatusDot), findsNothing);
  });

  testWidgets('one vehicle names it; four are counted', (tester) async {
    // The reference draws names because they are what a user recognises. Past
    // three the line stops fitting on the narrowest phone, and §13's plural
    // takes over.
    await _pump(tester);
    expect(find.text('The Golf'), findsOneWidget);

    await _pump(
      tester,
      vehicles: [
        homeVehicle(golfId, 'The Golf'),
        homeVehicle(vanId, 'The Van'),
        homeVehicle(bikeId, 'The Bike'),
        homeVehicle(fourthId, 'The Old One'),
      ],
    );
    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsVehicleCount(4, '4')), findsOneWidget);
  });

  testWidgets('appearance applies on tap, with no dialog', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(find.byType(CalmSegmented), findsOneWidget);
    await tester.tap(find.text(l10n.settingsThemeDark));
    await tester.pumpAndSettle();

    // No route pushed, no dialog: §13 makes this one three-valued setting with
    // an instantly visible result, and a confirmation over a change the user
    // can see land asks them to confirm what they are looking at.
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the Vehicles row pushes the garage', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(_l10n(tester).settingsVehiclesRow));
    await tester.pumpAndSettle();

    expect(find.byType(VehiclesScreen), findsOneWidget);
  });

  testWidgets('the version stays Latin digits under Eastern numerals', (
    tester,
  ) async {
    // §13: "1.4.0 stays Latin digits regardless of `numerals` — a version
    // string, not a number." It is an identifier a support conversation quotes
    // back, and Eastern Arabic-Indic digits in a bug report help nobody.
    await _pump(tester, locale: const Locale('fa'));

    expect(find.text(kAppVersion), findsOneWidget);
  });

  testWidgets('it survives German at 200% without overflowing', (tester) async {
    // German is the width constraint — `Sicherung & Wiederherstellung` and
    // `Einheiten & Formate` — and §13 says rows wrap rather than truncate.
    await _pump(
      tester,
      locale: const Locale('de'),
      device: Device.compact,
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
  });
}
