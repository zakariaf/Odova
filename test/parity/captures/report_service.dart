// `report.service`, in all four combinations.
//
// A PUSHED screen, so the capture draws no tab bar under it — the reference
// does not.

import 'package:flutter_test/flutter_test.dart';

import '../support/parity_capture.dart';
import '../support/report_backdrop.dart';

/// Captures `report.service` in one combination.
Future<void> captureReportService(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'report.service',
    config: config,
    child: reportBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
    ),
  );
}
