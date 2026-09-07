// `log.odometer`, in all four combinations.
//
// A MODAL, so no `tab:` — the log routes are root-navigator routes and the
// reference draws no tab bar under them.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/routing/routes.dart';
import 'package:odova/core/l10n/numerals.dart';

import '../support/log_backdrop.dart';
import '../support/parity_capture.dart';

/// Captures `log.odometer` in one combination.
Future<void> captureLogOdometer(WidgetTester tester, ParityCase config) async {
  await captureParity(
    tester,
    screen: 'log.odometer',
    config: config,
    child: logBackdrop(
      type: LogType.odometer,
      rtl: config.dir == 'rtl',
      locale: config.locale,
    ),
    // Tapped, not typed: this screen has no `TextField` at all — §10 gives
    // it a number pad — so the capture presses the artboard's reading the
    // way a user would. `_digits` renders the locale's own glyphs, so the
    // keys are found by their rendered label rather than by ASCII.
    settle: (tester) async {
      for (final digit in '187412'.split('')) {
        final key = find.text(shapeDigits(digit, digitsFor(config.locale)));
        if (key.evaluate().isEmpty) return;
        await tester.tap(key.first);
        await tester.pump();
      }
    },
  );
}

/// The numeral system [locale] renders digits in.
///
/// The pad draws the locale's own glyphs, so `find.text('1')` matches nothing
/// under `fa` or `ar` — where the reference is precisely the capture that
/// would silently photograph an empty screen instead of failing.
CalmNumerals digitsFor(Locale locale) =>
    resolveNumerals(CalmNumerals.auto, locale.languageCode);
