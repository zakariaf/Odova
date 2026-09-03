import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The locale Kurdish Sorani borrows its framework strings from.
///
/// `ckb` is absent from [GlobalMaterialLocalizations]' supported set, and
/// `intl`'s `Bidi` tables do not classify it as right-to-left, so a `ckb` app
/// built on the framework defaults lays out left-to-right with English
/// framework strings. SPEC.md §5 ships `ckb` as a first-class RTL locale, so
/// the framework layer is served from PERSIAN while every Odova string comes
/// from `app_ckb.arb`.
///
/// EPIC-01 shipped `ar` here and left the choice to this epic; EPIC-04 task 4.2
/// names `fa`, and `fa` is right. Sorani and Persian share the Perso-Arabic
/// letterforms Sorani actually uses — `ک` and `گ` and `ی`, which Arabic writes
/// `ك` and has no equivalent of — so Arabic chrome beside Sorani copy renders
/// two different shapes of the same letter on one screen. Both share the
/// direction; only one shares the alphabet.
///
/// It is still a compromise, and named as one: Persian month names under a
/// Sorani UI are better than Arabic ones and wrong all the same.
const ckbFrameworkFallback = Locale('fa');

/// Serves any framework localization for `ckb` from [ckbFrameworkFallback].
///
/// One class rather than three. The decision — "ckb borrows from fa" — is one
/// sentence, and three near-identical delegates state it three times and invite
/// the copy-paste bug this shape is prone to: a Material delegate whose `load`
/// forwards to `GlobalWidgetsLocalizations`.
///
/// [LocalizationsDelegate.type] returns `T`, so the type argument inferred from
/// [source] is what `Localizations` keys the result on.
class CkbFallbackDelegate<T> extends LocalizationsDelegate<T> {
  /// Creates a delegate serving `ckb` from [source]'s Persian localizations.
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
