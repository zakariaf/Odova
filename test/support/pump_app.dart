import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/l10n/supported_locales.dart';

/// Pumps [child] inside everything a real Odova screen sits in.
///
/// [locale] and [themeMode] are the two axes every parity capture varies, so
/// they are arguments rather than something each test rebuilds: 28 screens ×
/// light/dark × LTR/RTL is 112 combinations, and a harness that made each of
/// them a bespoke `MaterialApp` would produce 112 slightly different ones.
///
/// [themeMode] defaults to [ThemeMode.light] and is never [ThemeMode.system].
/// A capture that follows the host's appearance is a capture that compares a
/// dark screenshot against a light reference on somebody else's machine, which
/// `calm-visual-parity` says is almost always the test rather than the screen.
///
/// The text scaler is deliberately NOT clamped. SPEC.md §17's accessibility
/// gate needs 200% to be reachable, and `MediaQuery.withClampedTextScaling` in
/// a harness makes every large-text test pass without testing anything.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale? locale,
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
}) async {
  assert(
    themeMode != ThemeMode.system,
    'pumpApp pins a theme. ThemeMode.system makes the result depend on the '
    'host that ran the test.',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: noProviderRetry,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: odovaLocalizationsDelegates,
        supportedLocales: odovaSupportedLocales,
        // EPIC-02 replaces these with the Calm themes. Both are named here so
        // themeMode has something to choose between from the first test.
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
