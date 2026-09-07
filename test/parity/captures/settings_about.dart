// `settings.about`, in all four combinations.
//
// SPEC.md §13. The one screen in the sweep that reads no provider at all — its
// content is the version string and the offline promise — so a difference here
// is a typography or spacing difference and can be nothing else.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/settings/presentation/about_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings.about` in one combination.
Future<void> captureSettingsAbout(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.about',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
      child: const AboutScreen(),
    ),
  );
}
