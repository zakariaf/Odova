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
///
/// EPIC-04 owns the consequence: Arabic month names under a Sorani UI are
/// better than English ones and wrong all the same.
const ckbFrameworkFallback = Locale('ar');

/// Serves any framework localization for `ckb` from [ckbFrameworkFallback].
///
/// One class rather than three. The decision — "ckb borrows from ar" — is one
/// sentence, and three near-identical delegates state it three times and invite
/// the copy-paste bug this shape is prone to: a Material delegate whose `load`
/// forwards to `GlobalWidgetsLocalizations`.
///
/// [LocalizationsDelegate.type] returns `T`, so the type argument inferred from
/// [source] is what `Localizations` keys the result on.
class CkbFallbackDelegate<T> extends LocalizationsDelegate<T> {
  /// Creates a delegate serving `ckb` from [source]'s Arabic localizations.
  const CkbFallbackDelegate(this.source);

  /// The framework delegate the Arabic values come from.
  final LocalizationsDelegate<T> source;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<T> load(Locale locale) => source.load(ckbFrameworkFallback);

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}
