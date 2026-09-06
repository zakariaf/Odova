// `costs`, in all four combinations.
//
// A TAB root, so the capture draws the tab bar under it — the reference does.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/costs_backdrop.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('costs ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'costs',
        config: config,
        tab: 2,
        child: costsBackdrop(
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
