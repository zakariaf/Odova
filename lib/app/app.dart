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

  /// The four themes, built once.
  ///
  /// Two brightnesses × two script variants. [MaterialApp.builder] runs on
  /// every rebuild of the app root, and constructing a [ThemeData] there would
  /// allocate one per frame.
  static final _themes = <(Brightness, CalmType), ThemeData>{
    (Brightness.light, CalmType.latin): buildCalmTheme(Brightness.light),
    (Brightness.dark, CalmType.latin): buildCalmTheme(Brightness.dark),
    (Brightness.light, CalmType.arabicScript): buildCalmTheme(
      Brightness.light,
      type: CalmType.arabicScript,
    ),
    (Brightness.dark, CalmType.arabicScript): buildCalmTheme(
      Brightness.dark,
      type: CalmType.arabicScript,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: odovaLocalizationsDelegates,
      supportedLocales: odovaSupportedLocales,
      // These two decide the BRIGHTNESS. The script variant is applied in
      // `builder` below, because it depends on the resolved locale.
      theme: _themes[(Brightness.light, CalmType.latin)],
      darkTheme: _themes[(Brightness.dark, CalmType.latin)],
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
      // The script variant follows the RESOLVED locale, and the resolved
      // locale is only knowable below `Localizations` — which is where
      // `builder` runs and where the `theme:` field does not.
      //
      // This is what makes the shipping default work. `locale` is null when
      // the app follows the device, so reading the FIELD would give a Persian
      // phone Persian strings with Latin line heights: descenders clipped
      // silently, on the one configuration nobody passes explicitly in a test.
      //
      // SPEC.md §5 needs no restart on a language change. A locale flip
      // rebuilds from the root, this builder re-runs, and the Arabic-script
      // metrics arrive with it.
      builder: (context, child) => Theme(
        data:
            _themes[(
              Theme.of(context).brightness,
              CalmType.forLocale(Localizations.localeOf(context)),
            )]!,
        child: child!,
      ),
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
