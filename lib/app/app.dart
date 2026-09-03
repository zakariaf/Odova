import 'package:flutter/material.dart';
import 'package:odova/l10n/gen/app_localizations.dart';
import 'package:odova/l10n/supported_locales.dart';

/// The root widget.
///
/// It carries the locale contract and nothing else yet: the theme arrives in
/// EPIC-02 and the router in EPIC-08.
class OdovaApp extends StatelessWidget {
  /// Creates the root widget.
  const OdovaApp({super.key, this.locale, this.home});

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: locale,
      localizationsDelegates: odovaLocalizationsDelegates,
      supportedLocales: odovaSupportedLocales,
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
