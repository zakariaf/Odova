// `report.service`, in all four combinations.
//
// A PUSHED screen, so the capture draws no tab bar under it — the reference
// does not.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/parity_capture.dart';
import 'support/report_backdrop.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('report.service ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'report.service',
        config: config,
        child: reportBackdrop(
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
