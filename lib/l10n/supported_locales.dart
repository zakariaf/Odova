import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:odova/l10n/ckb_localizations.dart';
import 'package:odova/l10n/gen/app_localizations.dart';

/// The six locales Odova ships, in SPEC.md §5's order: the three left-to-right
/// ones, then the three right-to-left ones.
///
/// `en` is first because it is the fallback, and a missing key should surface
/// in a language the maintainer can read rather than in one they cannot.
const odovaSupportedLocales = <Locale>[
  Locale('en'),
  Locale('de'),
  Locale('fr'),
  Locale('fa'),
  Locale('ar'),
  Locale('ckb'),
];

/// The delegates the root app installs.
///
/// The `ckb` delegates come **first**: [Localizations] loads only the first
/// delegate that supports a locale for each type, so a `ckb` delegate placed
/// after [GlobalWidgetsLocalizations.delegate] — which claims to support every
/// locale — would never be reached, and the app would lay out left-to-right.
const odovaLocalizationsDelegates = <LocalizationsDelegate<Object>>[
  // The type arguments are written out, not inferred. In a list typed
  // `<LocalizationsDelegate<Object>>` inference resolves T to Object from the
  // context, and `LocalizationsDelegate.type` — which is how Localizations keys
  // the loaded value — then reports Object for all three. Localizations loads
  // only the first delegate per type, so the Material and Cupertino ones are
  // never reached and ckb falls back to English with a runtime warning nobody
  // reads.
  CkbFallbackDelegate<WidgetsLocalizations>(
    GlobalWidgetsLocalizations.delegate,
  ),
  CkbFallbackDelegate<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  ),
  CkbFallbackDelegate<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
