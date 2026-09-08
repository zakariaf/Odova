// `settings`, in all four combinations.
//
// SPEC.md §13's tab-4 root. The artboard draws a backup taken 4 June 2026 with
// its age line, the three-car garage named in one row, and the appearance
// segmented control on System — so the fixture supplies a stored theme and a
// real `todayProvider` rather than letting either fall back.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/settings/presentation/settings_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings` in one combination.
Future<void> captureSettings(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'settings',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      child: const SettingsScreen(),
    ),
  );
}
