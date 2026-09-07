// `history`, in all four combinations.
//
// A TAB root, so the capture draws the tab bar under it — the reference does.

import 'package:flutter_test/flutter_test.dart';

import '../support/history_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `history` in one combination.
Future<void> captureHistory(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'history',
    config: config,
    tab: 1,
    child: historyBackdrop(
      rtl: isRtl(config),
      locale: config.locale,
    ),
  );
}
