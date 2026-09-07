// `dialog.discard`, captured over its backdrop, in all four combinations.
//
// The capture FILENAME is the screen id, dot included — `compare_to_reference
// .mjs` looks up its reference by that name. The test file uses underscores
// because Dart does.

import 'package:flutter_test/flutter_test.dart';

import '../support/dialog_overlays.dart';
import '../support/home_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `dialog.discard` in one combination.
Future<void> captureDialogDiscard(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'dialog.discard',
    config: config,
    tab: 0,
    child: homeBackdrop(
      rtl: config.dir == 'rtl',
      locale: config.locale,
    ),
    overlay: const DiscardOverlay(),
  );
}
