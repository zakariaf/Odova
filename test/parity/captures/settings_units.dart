// `settings.units`, in all four combinations.
//
// SPEC.md §13 and §5. The screen whose whole content is formats, so the RTL
// captures are the ones that matter: a numeral set or a calendar that did not
// follow the locale shows here before it shows anywhere else.

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/features/settings/presentation/units_screen.dart';

import '../support/parity_capture.dart';
import '../support/settings_backdrop.dart';

/// Captures `settings.units` in one combination.
Future<void> captureSettingsUnits(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'settings.units',
    config: config,
    tab: 3,
    child: settingsBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
      child: const UnitsScreen(),
    ),
  );
}
