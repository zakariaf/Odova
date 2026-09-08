// `costs`, in all four combinations.
//
// A TAB root, so the capture draws the tab bar under it — the reference does.

import 'package:flutter_test/flutter_test.dart';

import '../support/costs_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `costs` in one combination.
Future<void> captureCosts(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'costs',
    config: config,
    tab: 2,
    child: costsBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
    ),
  );
}
