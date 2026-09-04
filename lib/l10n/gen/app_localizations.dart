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

  /// App bar title on the 404 screen. SPEC.md §7: an unknown link lands somewhere designed rather than on a red error box.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get routeNotFoundTitle;

  /// The one sentence on the 404 screen. Deliberately does not name the app or the link — a dead end is worse than a wrong turn, and the sentence exists only to hand the user the button below it.
  ///
  /// In en, this message translates to:
  /// **'That link doesn\'t lead anywhere.'**
  String get routeNotFoundBody;

  /// The single action on the 404 screen. Home is the one screen that always exists and always has something to say.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get routeNotFoundGoHome;

  /// Tab 1. SPEC.md §7: the tab labels are always visible under their icons — there is no icon-only mode to fall into. German and Sorani both run long here and wrap to two lines rather than truncating.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Tab 2.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// Tab 3.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get tabCosts;

  /// Tab 4.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Spoken label for the central + . It carries no visible text, so this is the only name a screen reader has for the app's most-pressed control. SPEC.md §7: logging is an act that finishes and returns you, which is why it is a button and not a fifth tab.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get tabLogA11y;

  /// Title of the global discard dialog. SPEC.md §7: dismissing a dirty modal opens this; dismissing a clean one is silent.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// The body of the discard dialog. It names what would be lost, because a generic "you have unsaved changes" is not a question the user can answer — {subject} is what is being edited and {summary} is the edits themselves, both supplied by the caller and both already localised.
  ///
  /// In en, this message translates to:
  /// **'Your edits to {subject} — {summary} — have not been saved.'**
  String discardBody(String subject, String summary);

  /// The safe action, and the one the reference puts FIRST. SPEC.md §7: no dialog is ever dismissed into a destructive outcome, so tap-out and system back both return this.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get discardKeepEditing;

  /// The destructive action. SPEC.md §10: it drops every segment draft, not only the visible one.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardDiscard;

  /// Title of the global delete confirmation. Names the subject and its total entry count so the user is agreeing to a size, not a word. SPEC.md §2: delete is immediate, with Undo in the moment — there is no trash to recover from, which is why the count is in the title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Delete {subject}?} other{Delete {subject} and {count, plural, one{its {countText} entry} other{its {countText} entries}}?}}'**
  String confirmDeleteTitle(String subject, int count, String countText);

  /// The five per-type counts, as ONE ICU message. SPEC.md §2 forbids assembling a sentence from parts: five plurals in one message is legal ICU and translatable, and a sentence built in Dart is a sentence no translator can reorder. Every count has an explicit =0 because a vehicle with no trips must not read '0 trips'.
  ///
  /// In en, this message translates to:
  /// **'{fillUps, plural, =0{No fill-ups} one{{fillUpsText} fill-up} other{{fillUpsText} fill-ups}}, {services, plural, =0{no services} one{{servicesText} service} other{{servicesText} services}}, {costs, plural, =0{no costs} one{{costsText} cost} other{{costsText} costs}}, {trips, plural, =0{no trips} one{{tripsText} trip} other{{tripsText} trips}} and {reminders, plural, =0{no reminders} one{{remindersText} reminder} other{{remindersText} reminders}} go permanently.'**
  String confirmDeleteBody(
    int fillUps,
    String fillUpsText,
    int services,
    String servicesText,
    int costs,
    String costsText,
    int trips,
    String tripsText,
    int reminders,
    String remindersText,
  );

  /// Label above the typed-confirmation field. SPEC.md §8: required exactly when the entry count is non-zero.
  ///
  /// In en, this message translates to:
  /// **'Type {subject} to confirm'**
  String confirmDeleteTypeToConfirm(String subject);

  /// The destructive action. Disabled until the typed name matches.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDeleteDelete;

  /// Title of the snooze dialog. The item label is interpolated AS STORED: the reference lower-cases it inside the sentence, and an ICU message cannot case-fold a placeholder — German capitalises every noun (EPIC-08 finding F-8.6).
  ///
  /// In en, this message translates to:
  /// **'Snooze {item}'**
  String snoozeTitle(String item);

  /// The reference's sentence, verbatim. It is deliberately state-neutral: it says what snoozing does and does not do, which is true for a due, due-soon or overdue item alike, so no ICU select over DueState is needed (EPIC-08 finding F-8.8).
  ///
  /// In en, this message translates to:
  /// **'This quiets the reminder. It does not change when the job is due.'**
  String get snoozeBody;

  /// The first snooze option.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String snoozeThreeDays(String count);

  /// The second.
  ///
  /// In en, this message translates to:
  /// **'{count} week'**
  String snoozeOneWeek(String count);

  /// The third. A calendar month, clamped to the last day of the target month.
  ///
  /// In en, this message translates to:
  /// **'{count} month'**
  String snoozeOneMonth(String count);

  /// The fourth, shown only when the item has a distance interval. SPEC.md §4.7.2 writes it as 500 km with no mile equivalent; §4.8 says defaults are defined per unit system rather than converted, and that is unsettled (EPIC-08 finding F-8.9).
  ///
  /// In en, this message translates to:
  /// **'After another {distance}'**
  String snoozeDistance(String distance);

  /// The resolved date on a time option. {date} is already formatted in the active calendar and numerals.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String snoozeUntil(String date);

  /// The resolved reading on the distance option. {odometer} is the entered cumulative reading plus 500 km, already formatted — never a projection, which would move every time the estimate did.
  ///
  /// In en, this message translates to:
  /// **'at {odometer}'**
  String snoozeAtOdometer(String odometer);

  /// The way out of any dialog. ONE key, not one per dialog: it was the same word in all six locales twice over, which is two chances for a translator to make two dialogs in the same app disagree about "Cancel". Tap-out and system back both mean this, and SPEC.md §7 says no dialog is ever dismissed into a destructive outcome.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;
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
