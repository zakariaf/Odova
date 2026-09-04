/// Pumping the real app around the real router, once.
///
/// Three tests in this directory need the same four lines, and the fourth line
/// is the one that is easy to get wrong: `MaterialApp.router` builds its
/// `RouterDelegate` once and keeps it, so pumping a second `OdovaApp` over the
/// first leaves the FIRST router driving the tree. Every assertion after that
/// reads the previous case's location while looking like it reads its own — a
/// tap that provably worked in isolation did nothing in the suite, and that is
/// how it was found. [pumpShell] unmounts first, so each case is independent.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odova/app/app.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/app/routing/app_router.dart';
import 'package:odova/app/routing/app_shell.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/locale_controller.dart';

/// Mounts the app at [location], on a torn-down tree, and returns the container
/// its providers live in so a test can read one.
Future<ProviderContainer> pumpShell(
  WidgetTester tester,
  String location, {
  Locale? locale = const Locale('en'),
  List<Override> overrides = const [],
  Widget Function(Widget)? wrap,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());

  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      // The one router, at the location this test starts from.
      routerProvider.overrideWithValue(buildRouter(initialLocation: location)),
      ...overrides,
    ],
  );

  final app = UncontrolledProviderScope(
    container: container,
    child: OdovaApp(locale: locale, themeMode: ThemeMode.light),
  );
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  await tester.pumpAndSettle();
  // Disposed by the harness, not by every caller. A container left alive keeps
  // its providers alive, and a test that forgets is a test that shares state
  // with the next one.
  addTearDown(container.dispose);
  return container;
}

/// The shell's element, offstage or not.
///
/// `skipOffstage: false` because an opaque modal puts the whole shell offstage,
/// and every question a test asks after opening one — where am I, which tab,
/// pop me back — is still asked of the shell underneath it.
Element _shellElement(WidgetTester tester) =>
    tester.element(find.byType(AppShell, skipOffstage: false));

/// Where the app currently is.
String locationOf(WidgetTester tester) =>
    GoRouter.of(_shellElement(tester)).state.uri.toString();

/// The shell, for its branch index.
StatefulNavigationShell shellOf(WidgetTester tester) =>
    (_shellElement(tester).widget as AppShell).navigationShell;

/// Taps a tab by the label [pick] names, in whatever locale is mounted.
Future<void> tapTab(
  WidgetTester tester,
  String Function(AppLocalizations) pick,
) async {
  final l10n = AppLocalizations.of(_shellElement(tester));
  await tester.tap(find.text(pick(l10n)));
  await tester.pumpAndSettle();
}

/// Navigates without a tap, for the pushes a test needs but is not asserting.
void goTo(WidgetTester tester, String location) =>
    GoRouter.of(_shellElement(tester)).go(location);

/// Changes `Settings.language` the way the settings screen will.
///
/// Through the controller, not by re-pumping with a different `locale:` — a
/// re-pump would build a new tree and prove nothing about whether a language
/// change preserves the one that was there.
Future<void> setLocale(
  WidgetTester tester,
  ProviderContainer container,
  Locale locale,
) async {
  container
      .read(localeControllerProvider.notifier)
      .setLanguage(locale.languageCode);
  await tester.pumpAndSettle();
}

/// The direction the app resolved.
TextDirection directionOf(WidgetTester tester) =>
    Directionality.of(_shellElement(tester));

/// Sends the platform message the engine sends on an Android system back.
///
/// The Flutter SDK has this as `simulateSystemBack` in
/// `packages/flutter/test/cupertino/navigator_utils.dart` — a test helper that
/// is not exported from `flutter_test`, so it is copied here rather than
/// approximated with `Navigator.pop`. The two are not the same event: a real
/// system back goes through `PopScope`, and a `Navigator.pop` bypasses the
/// exact guard SPEC.md §7's back rules live in.
Future<void> systemBack() => TestDefaultBinaryMessengerBinding
    .instance
    .defaultBinaryMessenger
    .handlePlatformMessage(
      SystemChannels.navigation.name,
      const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'method': 'popRoute',
      }),
      (_) {},
    );

/// The shell's own back guard.
///
/// The OUTERMOST `PopScope` under [AppShell]. There is more than one in the
/// tree — each branch Navigator brings its own — and the shell's is the one
/// wrapping them all. Found by predicate rather than by type because `PopScope`
/// is generic: a `find.byType` pinned to one type argument reports "no guard"
/// rather than "the guard changed" the day it gets a real result type.
PopScope<Object?> shellGuard(WidgetTester tester) =>
    tester
            .widgetList(
              find.descendant(
                of: find.byType(AppShell),
                matching: find.byWidgetPredicate((w) => w is PopScope),
              ),
            )
            .first
        as PopScope<Object?>;

/// Pops the top route, the way a modal's Save does.
void goBack(WidgetTester tester) => GoRouter.of(_shellElement(tester)).pop();
