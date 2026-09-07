// SPEC.md §13's `settings.about` — the promise, the two numbers, the licences.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/app_version.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/features/settings/presentation/about_screen.dart';
import 'package:odova/features/settings/presentation/licences_screen.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

import '../../../app/routing/shell_harness.dart';
import '../../../support/device.dart';
import '../../home/home_fixture.dart';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AboutScreen)));

Future<void> _pump(
  WidgetTester tester, {
  Locale? locale = const Locale('en'),
  TextScaler? textScaler,
}) async {
  tester.useDevice(Device.tallForm);
  await pumpShell(
    tester,
    Routes.settingsAbout,
    locale: locale,
    settings: homeSettings(golfId),
    vehicles: [homeVehicle(golfId, 'The Golf')],
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
  testWidgets('the version, the build and the backup format', (tester) async {
    await _pump(tester);
    final l10n = _l10n(tester);

    expect(
      find.textContaining(l10n.aboutVersion(kAppVersion, kAppBuild)),
      findsOneWidget,
    );
    // From the SAME constant the backup writer writes, so the number on this
    // screen and the number in the file can never disagree.
    expect(
      find.textContaining(
        l10n.aboutBackupFormat('$kSupportedFormatVersion'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the internal schema version is never shown', (tester) async {
    // A user cannot act on it, and a number they cannot act on in a support
    // conversation is a number that wastes the conversation.
    await _pump(tester);
    expect(find.textContaining('schema'), findsNothing);
    expect(find.textContaining('Schema'), findsNothing);
  });

  testWidgets('the privacy promise reads in full at 200% in Persian', (
    tester,
  ) async {
    // §13: no fixed height, no ellipsis. A promise that has to be scrolled
    // inside its own box is a promise with something hidden.
    await _pump(
      tester,
      locale: const Locale('fa'),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text(_l10n(tester).aboutPrivacy, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('the sentence about losing the phone is present', (tester) async {
    // Asserted BY NAME, because it is the one a future PR will quietly
    // delete. §1: the history is worth money and no server holds a copy.
    await _pump(tester);
    expect(find.text(_l10n(tester).aboutBackupWarning), findsOneWidget);
  });

  testWidgets('licences push an offline view', (tester) async {
    await _pump(tester);
    await tester.tap(find.text(_l10n(tester).aboutLicencesRow));
    await tester.pumpAndSettle();

    expect(find.byType(LicencesScreen), findsOneWidget);
  });

  testWidgets('none of the seven things this screen must not have', (
    tester,
  ) async {
    // One test for all seven, so nobody adds one back without deleting a
    // named assertion. §2: no network, no analytics, no ads — and §15 puts
    // rate-this-app, share and support out of v1.
    await _pump(tester);

    for (final absent in [
      'Rate',
      'Share',
      'Support',
      'Privacy policy',
      'Terms',
      'Restore',
      'Debug',
    ]) {
      expect(find.textContaining(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('the version stays Latin under Persian numerals', (tester) async {
    await _pump(tester, locale: const Locale('fa'));

    expect(find.textContaining(kAppVersion), findsOneWidget);
  });
}
