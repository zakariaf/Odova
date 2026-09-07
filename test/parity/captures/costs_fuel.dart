// `costs.fuel`, in all four combinations.
//
// SPEC.md §12. The one screen in the sweep whose reference is mostly a CHART,
// and therefore the one where a band difference most likely means a painter
// difference rather than a spacing one.

import 'package:flutter_test/flutter_test.dart';

import '../support/fuel_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `costs.fuel` in one combination.
Future<void> captureCostsFuel(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'costs.fuel',
    config: config,
    tab: 2,
    child: fuelBackdrop(rtl: config.dir == 'rtl', locale: config.locale),
  );
}
