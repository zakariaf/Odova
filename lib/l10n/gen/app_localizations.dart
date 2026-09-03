import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('ckb'),
    Locale('de'),
    Locale('fa'),
    Locale('fr'),
  ];

  /// The application name. A brand name: identical in all six locales, never translated and never transliterated.
  ///
  /// In en, this message translates to:
  /// **'Odova'**
  String get appTitle;

  /// Screen-reader label for any estimated value. SPEC.md §5: the tilde is never read as "tilde" — the visible string keeps the ~ as its non-colour marker and this sentence is what a screen reader says instead.
  ///
  /// In en, this message translates to:
  /// **'estimated, about {value}'**
  String commonEstimatedA11y(String value);

  /// Shown on a due card when the engine has no odometer history to project from. SPEC.md §9: it takes no placeholders, and it must never be assembled from parts — a sentence built in Dart is a sentence no translator can reorder.
  ///
  /// In en, this message translates to:
  /// **'Odova needs a reading to say when'**
  String get homeDueSoonNoConfidence;

  /// Kilometre, abbreviated, as a label beside a formatted number. SPEC.md §5: unit labels come from these files, not the platform unit formatter — ICU renders km in ckb-IQ as a Latin "km".
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitDistanceKm;

  /// Mile, abbreviated, as a label beside a formatted number.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitDistanceMi;

  /// Litre, abbreviated, as a label beside a formatted number. ICU renders 45.2 L in fa-IR as "۴۵٫۲L" — a Latin L with no space — which is why this is ours.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitVolumeLitre;

  /// Gallon, abbreviated. US and imperial gallons are different units and are never conflated; this is the shared label and the system is named elsewhere.
  ///
  /// In en, this message translates to:
  /// **'gal'**
  String get unitVolumeGallon;

  /// Fuel consumption as volume per distance, e.g. "L/100 km". {n} is the hundred, as a PLACEHOLDER rather than a literal, so the active numbering system shapes it like every other number.
  ///
  /// In en, this message translates to:
  /// **'L/{n} km'**
  String unitConsumptionPerDistance(int n);

  /// Fuel consumption as distance per volume: miles per gallon.
  ///
  /// In en, this message translates to:
  /// **'mpg'**
  String get unitConsumptionMpg;

  /// Suffix for a rate expressed per unit of distance, e.g. a cost per kilometre. {unit} is one of the distance labels, never baked in, so the same message serves km and mi.
  ///
  /// In en, this message translates to:
  /// **'/{unit}'**
  String unitPerDistance(String unit);

  /// Relative date bucket: the delta is zero days. SPEC.md §5 buckets before formatting — "in 47 days" is data, "in about 7 weeks" is an answer.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative date bucket: exactly one day ahead.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// Relative date bucket: exactly one day behind.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Relative date bucket: 2 to 13 days ahead.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{in {nText} day} other{in {nText} days}}'**
  String dateInDays(int n, String nText);

  /// Relative date bucket: 14 to 55 days ahead, expressed in whole weeks and hedged. The hedge is the point: the underlying number is a projection.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{in about {nText} week} other{in about {nText} weeks}}'**
  String dateInAboutWeeks(int n, String nText);

  /// Relative date bucket: 56 days or more ahead, expressed in whole months and hedged.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{in about {nText} month} other{in about {nText} months}}'**
  String dateInAboutMonths(int n, String nText);

  /// How far past due something is. A SEPARATE message from the ahead buckets, never a negative relative time — SPEC.md §5.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} day overdue} other{{nText} days overdue}}'**
  String dateDaysOverdue(int n, String nText);

  /// How many reminders are due. Carries an explicit =0 case, because "0 reminders due" is a worse sentence than "Nothing due" in every one of the six.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing due} one{{nText} reminder due} other{{nText} reminders due}}'**
  String remindersDueCount(int n, String nText);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'ckb',
    'de',
    'en',
    'fa',
    'fr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ckb':
      return AppLocalizationsCkb();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
