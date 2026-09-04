import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';

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
/// [textScaler], [boldText] and [accessibleNavigation] are the three
/// accessibility axes SPEC.md §17's gate varies. They are arguments rather
/// than a MediaQuery each test builds, because a MediaQuery built inside the
/// app sits BELOW MaterialApp and is overridden by the one the app inserts.
///
/// All three are NULLABLE and default to null, which `copyWith` ignores. A
/// default of `TextScaler.noScaling` would silently pin every test to 100%
/// and override a scale set on the platform dispatcher — a harness that
/// clamps makes every large-text test pass by not testing anything.
///
/// The text scaler is deliberately NOT clamped. SPEC.md §17's accessibility
/// gate needs 200% to be reachable, and `MediaQuery.withClampedTextScaling` in
/// a harness makes every large-text test pass without testing anything.
///
/// This pumps [OdovaApp] itself rather than rebuilding an equivalent
/// `MaterialApp`. The 112 parity captures depend on the harness and the app
/// being the same widget: a fork means every theme, delegate or locale change
/// has to be made twice, and the day it is made once the captures are of
/// something the user never sees.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale? locale,
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
  TextScaler? textScaler,
  bool? boldText,
  bool? accessibleNavigation,
  bool settle = true,
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
      // The MediaQuery sits ABOVE the app, not inside it: MaterialApp inserts
      // none of its own, so this is the nearest ancestor and it wins. It is
      // built from `copyWith` rather than a bare MediaQueryData so the surface
      // `useDevice` pinned is not zeroed.
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            boldText: boldText,
            accessibleNavigation: accessibleNavigation,
          ),
          child: OdovaApp(
            locale: locale,
            themeMode: themeMode,
            router: singleScreenRouter(child),
          ),
        ),
      ),
    ),
  );
  // A repeating animation NEVER settles — a spinner, a shimmer, a pulsing due
  // dot. `settle: false` is the escape, and it is one pump rather than a
  // longer timeout, because waiting on something that cannot finish is not a
  // slower test, it is a different test.
  if (!settle) {
    await tester.pump();
    return;
  }
  // Bounded on purpose. The default pumpAndSettle runs to a TEN MINUTE timeout
  // against a repeating animation, so the first looping Calm animation on a
  // pumped screen would turn one test into a ten-minute hang instead of a fast
  // failure.
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

/// A router that shows [child] at `/` and nothing else.
///
/// EPIC-08 replaced `OdovaApp.home` with a router, because
/// `MaterialApp.router` has no `home:`. A component test still wants to pump
/// one widget inside the real app's themes, locales and text scaler, so it
/// pumps it as the only screen of a one-route graph rather than losing that
/// wrapping.
///
/// It deliberately does NOT set `navigatorKey`. `rootNavigatorKey` belongs to
/// the app's own router, and two routers claiming one GlobalKey is a duplicate
/// key crash the moment both are mounted.
GoRouter singleScreenRouter(Widget child) => GoRouter(
  routes: [GoRoute(path: '/', builder: (context, state) => child)],
);
