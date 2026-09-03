/// Pumping something under the Calm theme, and the assert every extension owes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';

/// Pumps a widget under a real Calm [ThemeData] and hands its context to
/// [onContext].
///
/// Lighter than `pumpApp`: no `ProviderScope`, no localizations, no router.
/// Use it when the subject is the theme itself.
Future<void> pumpCalm(
  WidgetTester tester,
  void Function(BuildContext context) onContext, {
  ThemeMode themeMode = ThemeMode.light,
  CalmType? type,
}) async {
  await tester.pumpWidget(
    Theme(
      data: buildCalmTheme(
        themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        type: type,
      ),
      child: Builder(
        builder: (context) {
          onContext(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

/// Registers the test every Calm extension owes: `of()` asserts under a theme
/// that does not carry it, and the message names both the extension and how to
/// get one.
///
/// One helper rather than five copies. The person reading that assertion is
/// looking at a stack trace inside a widget that did nothing wrong, so the
/// message has to tell them what to build — and a `?? fallback` would ship a
/// value no contrast test has ever seen, silently, on whichever screen forgot
/// the theme.
void testOfAsserts(String name, void Function(BuildContext context) read) {
  testWidgets('$name.of asserts, naming the extension and the builder', (
    tester,
  ) async {
    Object? thrown;
    await tester.pumpWidget(
      Theme(
        data: ThemeData.light(),
        child: Builder(
          builder: (context) {
            try {
              read(context);
            } on Object catch (error) {
              thrown = error;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      thrown,
      isA<AssertionError>().having(
        (e) => e.toString(),
        'message',
        allOf(contains(name), contains('buildCalmTheme')),
      ),
      reason: '$name.of returned instead of asserting',
    );
  });
}
