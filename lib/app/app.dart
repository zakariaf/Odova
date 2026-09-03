import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Override lives in misc.dart in Riverpod 3.x, not the root library.
import 'package:flutter_riverpod/misc.dart';
import 'package:odova/app/lifecycle_observer.dart';
import 'package:odova/app/providers.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/supported_locales.dart';
import 'package:odova/theme/calm/calm_colors.dart';
import 'package:odova/theme/calm/calm_theme.dart';
import 'package:odova/theme/calm/calm_type.dart';

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

  /// The type variant for the locale this app was asked for.
  ///
  /// `locale` may be null — the shipping default, meaning "follow the device"
  /// — and the resolved locale is not knowable above [MaterialApp]. Latin is
  /// the right answer for null: it is what `en` takes, and `en` is the
  /// fallback.
  CalmType _typeFor(BuildContext context) =>
      locale == null ? CalmType.latin : CalmType.forLocale(locale!);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: odovaLocalizationsDelegates,
      supportedLocales: odovaSupportedLocales,
      // One builder, both brightnesses, and the locale's type variant on each.
      // SPEC.md §5 needs no restart on a language change: a locale flip is a
      // rebuild from the root, and because the type rides the ThemeData that
      // rebuild carries the Arabic-script metrics with it.
      //
      // `builder` rather than a field read: `locale` here is the REQUESTED
      // locale, and the resolved one is only known inside the app. Reading it
      // from the Localizations scope is what makes `system` work.
      theme: buildCalmTheme(Brightness.light, type: _typeFor(context)),
      darkTheme: buildCalmTheme(Brightness.dark, type: _typeFor(context)),
      themeMode: themeMode,
      // MaterialApp mounts an AnimatedTheme and crossfades ThemeData over
      // ~200ms unless told not to. That is not a Calm token, and it is
      // actively worse than either alternative here: CalmMotion and CalmType
      // lerp as deliberate STEPS, so without this the ColorScheme crossfades
      // while the durations and weights snap at the midpoint. Motion is
      // CalmMotion's, at the call site, or it does not happen.
      themeAnimationStyle: AnimationStyle.noAnimation,
      // Restoring a persisted ThemeMode before the first frame is
      // design-system-structure rule 9. There is no settings store yet; the
      // seam is `themeMode` and EPIC-14 fills it from SettingsRepository.
      home: home ?? const _PlaceholderHome(),
    );
  }
}

/// The placeholder screen, until EPIC-08 brings the shell.
///
/// A [Material] rather than a [Scaffold]: `check_calm_layering.sh` refuses a
/// raw `Scaffold(` outside `lib/ui/calm/`, because wrapping Material is that
/// layer's job and `CalmScaffold` is EPIC-03's. There is nothing here worth
/// building a screen skeleton for.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final colours = CalmColors.of(context);
    return Material(
      color: colours.bg,
      child: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: CalmType.of(context).hero.copyWith(color: colours.ink),
        ),
      ),
    );
  }
}
