// `settings.language`, in all four combinations.
//
// SPEC.md §13. The list is the same widget `firstrun.language` draws, so the
// two captures photograph one component under two chromes — the difference the
// reference shows is the app bar and the absence of the Continue button.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/settings/presentation/settings_language_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings.language` in one combination.
Future<void> captureSettingsLanguage(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.language',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
      child: const SettingsLanguageScreen(),
    ),
  );
}
