// `log.expense`, in all four combinations.
//
// A MODAL, so no `tab:` — the log routes are root-navigator routes and the
// reference draws no tab bar under them.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';

import '../support/log_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `log.expense` in one combination.
Future<void> captureLogExpense(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'log.expense',
    config: config,
    child: logBackdrop(
      type: LogType.expense,
      rtl: config.dir == 'rtl',
      locale: config.locale,
    ),
    // The odometer the artboard shows, TYPED. §10 is explicit that this
    // field is never prefilled for the user, so a capture that staged it
    // would be photographing a state the app does not have.
    settle: (tester) async {
      await tester.enterText(find.byType(TextField).first, '187412');
      await tester.pump();
    },
  );
}
