// `history`, in all four combinations.
//
// A TAB root, so the capture draws the tab bar under it — the reference does.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/history_backdrop.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('history ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'history',
        config: config,
        tab: 1,
        child: historyBackdrop(
          rtl: config.dir == 'rtl',
          locale: config.locale,
        ),
      );
    });
  }
}
