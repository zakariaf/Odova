// `log.fillup`, in all four combinations.
//
// A MODAL, so no `tab:` — the log routes are root-navigator routes and the
// reference draws no tab bar under them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';

import '../support/log_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `log.fillup` in one combination.
Future<void> captureLogFillup(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'log.fillup',
    config: config,
    child: logBackdrop(
      type: LogType.fillUp,
      rtl: isRtl(config),
      locale: config.locale,
    ),
    // The artboard's own numbers, typed the way a user types them. The
    // reference draws 42.8 L for 74.20 € with Price/L computed and wearing
    // its `ƒ`, so the capture enters the two the user entered and lets the
    // trio work out the third — photographing the state, not staging it.
    settle: (tester) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '187412');
      await tester.enterText(fields.at(1), '42.8');
      await tester.enterText(fields.at(3), '74.20');
      await tester.pump();
    },
  );
}
