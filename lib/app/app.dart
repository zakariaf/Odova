import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/lifecycle_observer.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/supported_locales.dart';

/// The root of the widget tree: the single [ProviderScope], the lifecycle
/// observer, and the app.
///
/// [overrides] come from `bootstrap()`. The default — none — is what a test
/// that does not care about infrastructure gets, and every placeholder
/// provider then throws by name rather than returning null.
class OdovaRoot extends StatelessWidget {
  /// Creates the root.
  const OdovaRoot({super.key, this.overrides = const []});

  /// The real infrastructure, built once in `bootstrap()`.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      retry: noProviderRetry,
      child: const _LifecycleScope(child: OdovaApp()),
    );
  }
}

/// Registers exactly one [LifecycleObserver], for exactly as long as the app
/// is mounted.
class _LifecycleScope extends ConsumerStatefulWidget {
  const _LifecycleScope({required this.child});

  final Widget child;

  @override
  ConsumerState<_LifecycleScope> createState() => _LifecycleScopeState();
}

class _LifecycleScopeState extends ConsumerState<_LifecycleScope> {
  late final LifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    // ref.read, never watch: this is a service the observer calls, and a watch
    // would rebuild the whole app whenever it changed.
    _observer = LifecycleObserver(() => ref.read(durableFlushProvider)());
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The root widget.
///
/// It carries the locale contract and nothing else yet: the theme arrives in
/// EPIC-02 and the router in EPIC-08.
class OdovaApp extends StatelessWidget {
  /// Creates the root widget.
  const OdovaApp({
    super.key,
    this.locale,
    this.home,
    this.themeMode = ThemeMode.system,
  });

  /// Forces a locale, overriding the device's list.
  ///
  /// Null — the shipping default — resolves through
  /// [odovaSupportedLocales]. Tests pass one to pin a direction.
  final Locale? locale;

  /// Replaces the placeholder screen.
  ///
  /// Tests pass a `Builder` here to read the resolved [Directionality] or
  /// [AppLocalizations] from inside the app's own `Localizations` scope.
  final Widget? home;

  /// Pins the palette.
  ///
  /// [ThemeMode.system] — the shipping default — follows the device. A test or
  /// a parity capture passes an explicit value, because a capture that follows
  /// the host compares a dark screenshot against a light reference on somebody
  /// else's machine.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: odovaLocalizationsDelegates,
      supportedLocales: odovaSupportedLocales,
      // EPIC-02 replaces these two with buildCalmTheme(Brightness.light|dark).
      // Both are named now so themeMode has something to choose between, and so
      // that swap is one edit in one place — the test harness pumps THIS
      // widget, not a second MaterialApp of its own.
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: home ?? const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(AppLocalizations.of(context).appTitle)),
    );
  }
}
