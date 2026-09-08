// `dialog.confirmDelete`, captured over its backdrop, in all four combinations.
//
// The capture FILENAME is the screen id, dot included — `compare_to_reference
// .mjs` looks up its reference by that name. The test file uses underscores
// because Dart does.

import 'package:flutter_test/flutter_test.dart';

import '../support/dialog_overlays.dart';
import '../support/parity_capture.dart';
import '../support/vehicles_backdrop.dart';

/// Captures `dialog.confirmDelete` in one combination.
Future<void> captureDialogConfirmdelete(
  WidgetTester tester,
  ParityCase config,
) async {
  await captureParity(
    tester,
    screen: 'dialog.confirmDelete',
    config: config,
    // The artboard draws the tab bar with the FOURTH item active — the
    // stand-in this replaced drew no bar at all, which is ten icons and
    // ten labels' worth of band edges the check could never find.
    tab: 3,
    child: vehiclesBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
    ),
    overlay: const ConfirmDeleteOverlay(),
  );
}
