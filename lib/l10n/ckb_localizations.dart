import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The locale Kurdish Sorani borrows its framework strings from.
///
/// `ckb` is absent from [GlobalMaterialLocalizations]' supported set, and
/// `intl`'s `Bidi` tables do not classify it as right-to-left, so a `ckb` app
/// built on the framework defaults lays out left-to-right with English
/// framework strings. SPEC.md §5 ships `ckb` as a first-class RTL locale, so
/// the framework layer is served from Arabic — the closest script, direction
/// and letterforms available — while every Odova string comes from
/// `app_ckb.arb`.
const _ckbFrameworkFallback = Locale('ar');

bool _isCkb(Locale locale) => locale.languageCode == 'ckb';

/// Serves [WidgetsLocalizations] for `ckb`, which is what sets
/// [Directionality] at the root of the app.
class CkbWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  /// Creates the delegate.
  const CkbWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isCkb(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_ckbFrameworkFallback);

  @override
  bool shouldReload(CkbWidgetsLocalizationsDelegate old) => false;
}

/// Serves [MaterialLocalizations] for `ckb`.
class CkbMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  /// Creates the delegate.
  const CkbMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isCkb(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_ckbFrameworkFallback);

  @override
  bool shouldReload(CkbMaterialLocalizationsDelegate old) => false;
}

/// Serves [CupertinoLocalizations] for `ckb`.
class CkbCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  /// Creates the delegate.
  const CkbCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isCkb(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_ckbFrameworkFallback);

  @override
  bool shouldReload(CkbCupertinoLocalizationsDelegate old) => false;
}
