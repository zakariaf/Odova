// `log.odometer`, in all four combinations.
//
// A MODAL, so no `tab:` — the log routes are root-navigator routes and the
// reference draws no tab bar under them.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';

import 'support/log_backdrop.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('log.odometer ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'log.odometer',
        config: config,
        child: logBackdrop(
          type: LogType.odometer,
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
