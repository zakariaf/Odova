// `dialog.snooze`, captured over its backdrop, in all four combinations.
//
// The capture FILENAME is the screen id, dot included — `compare_to_reference
// .mjs` looks up its reference by that name. The test file uses underscores
// because Dart does.
@Tags(['parity'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/dialog_backdrop.dart';
import 'support/dialog_overlays.dart';
import 'support/parity_capture.dart';

void main() {
  setUpAll(loadParityFonts);

  for (final config in kParityCases) {
    testWidgets('dialog.snooze ${config.theme}/${config.dir}', (tester) async {
      await captureParity(
        tester,
        screen: 'dialog.snooze',
        config: config,
        child: const HomeBackdrop(),
        overlay: const SnoozeOverlay(),
      );
    });
  }
}
