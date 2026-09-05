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

  /// Fuel consumption as volume per distance, e.g. "L/100 km". {n} is the hundred, as a PLACEHOLDER rather than a literal, and a String rather than an int: gen-l10n interpolates a bare int in Latin digits, and SPEC.md §5 shapes every number through `formatForDisplay` against the FORMATS tag, which follows the device region rather than the UI language.
  ///
  /// In en, this message translates to:
  /// **'L/{n} km'**
  String unitConsumptionPerDistance(String n);

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

  /// Shown under the typed-confirmation field when what was typed does not match. SPEC.md §8 gives the wording: "That doesn't match The Golf." Without it the user who mistypes reads the instruction again and is never told they got it wrong.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t match {subject}.'**
  String confirmDeleteMismatch(String subject);

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

  /// Moves to the next step of first run. SPEC.md §8 gives the label in all six: Continue / Weiter / Continuer / ادامه / متابعة / بەردەوام بە. It is rendered in the language the user has just tapped, not the device's, so it wraps to two lines rather than shrinking — "Weiter" and "بەردەوام بە" are very different widths.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Opens the OS document picker on the way to settings.import. Offered on both first-run screens because the second-most-likely reason a stranger is on them is a new phone.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get commonRestoreBackup;

  /// The first row of the seven-row language list. The parenthesis names what `system` resolves to RIGHT NOW and updates live, so a de-DE device reads "System (Deutsch)". SPEC.md §5 Override.
  ///
  /// In en, this message translates to:
  /// **'System ({language})'**
  String settingsLanguageSystem(String language);

  /// Sits under the language list when the device language is none of the six. SPEC.md §5 and §8. It deliberately takes NO placeholder — EPIC-09 F-9.8: nothing in the dependency set supplies a language's own name for an arbitrary tag, and a hand-written endonym table would put a misspelling of somebody's own language, in their own script, on the app's first screen.
  ///
  /// In en, this message translates to:
  /// **'Odova isn’t translated into your device’s language yet. Numbers, dates, units and money will still follow your region.'**
  String get settingsLanguageNotTranslated;

  /// One line under the wordmark on firstrun.language. It is in the artboard rather than in SPEC's prose, and CLAUDE.md §7 makes the reference the authority for what the screen says.
  ///
  /// In en, this message translates to:
  /// **'Pick the one you read best.'**
  String get firstRunLanguageTagline;

  /// The caption between Continue and Restore a backup on firstrun.language. SPEC.md §8's wording wins over §14's — EPIC-09 F-9.3.
  ///
  /// In en, this message translates to:
  /// **'Moving from another phone?'**
  String get firstRunRestorePrompt;

  /// App bar title on `firstrun.vehicle`, the second and last screen of first run.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get firstRunVehicleTitle;

  /// App bar subtitle. It promises how short the setup is, which is the screen's whole job — SPEC.md §8: one vehicle and one odometer reading in under thirty seconds.
  ///
  /// In en, this message translates to:
  /// **'One vehicle and one number. That is the whole setup.'**
  String get firstRunVehicleSubtitle;

  /// Vehicle type tile. The stored value is `car`; this is only the label. EPIC-09 F-9.11: three tiles, because §4.8's seeded set has three distinct outcomes and `truck` and `other` both take the car set.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vehicleTypeCar;

  /// Vehicle type tile. The STORED value is `motorcycle` even though the English label is "Motorbike" — a UI label must never leak into the wire value.
  ///
  /// In en, this message translates to:
  /// **'Motorbike'**
  String get vehicleTypeMotorcycle;

  /// Vehicle type tile. A small COMMERCIAL van — the plumber's Transit, not a people carrier. German must not borrow "Van", which means an MPV there.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleTypeVan;

  /// Field label above the vehicle name input.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vehicleNameLabel;

  /// Prefilled vehicle name when the type is car. Pre-selected, so the first keystroke replaces it — SPEC.md §8.
  ///
  /// In en, this message translates to:
  /// **'My car'**
  String get vehicleNameDefaultCar;

  /// Prefilled vehicle name when the type is motorbike. Follows the type tile.
  ///
  /// In en, this message translates to:
  /// **'My motorbike'**
  String get vehicleNameDefaultMotorcycle;

  /// Prefilled vehicle name when the type is van. Follows the type tile.
  ///
  /// In en, this message translates to:
  /// **'My van'**
  String get vehicleNameDefaultVan;

  /// Field label above the fuel chips. It covers electric too, which the English word strictly does not; the translations follow the English rather than repairing it.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get vehicleFuelLabel;

  /// Fuel kind chip. Gasoline.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// Fuel kind chip.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// Fuel kind chip. A battery electric vehicle.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelElectric;

  /// Fuel kind, in the More… sheet. Liquefied petroleum gas / autogas.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// Fuel kind, in the More… sheet. Compressed natural gas.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get fuelCng;

  /// Fuel kind, in the More… sheet. Petrol-electric hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get fuelHybrid;

  /// Fuel kind, in the More… sheet. Anything else.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fuelOther;

  /// Opens a sheet with the remaining options. The ellipsis is ONE character, U+2026 — three full stops are three characters a screen reader reads out.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get commonMore;

  /// Field label above the odometer input. "Now" means the reading as of today, which is what makes this an observation rather than a vehicle fact.
  ///
  /// In en, this message translates to:
  /// **'Odometer now'**
  String get odometerNowLabel;

  /// Hint under the odometer field. It is ALWAYS visible, and it is what stands in for the explanation a disabled button would otherwise owe the user — EPIC-09 F-9.10.
  ///
  /// In en, this message translates to:
  /// **'Read it off the dash.'**
  String get odometerFirstRunHint;

  /// Inline error when Start is pressed with an empty odometer.
  ///
  /// In en, this message translates to:
  /// **'Enter the number on your dash.'**
  String get odometerEmptyError;

  /// Inline error when the odometer cannot be parsed at all.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a number. Digits only.'**
  String get odometerNotANumberError;

  /// A WARNING and never a block, shown above 3,000,000 km. SPEC.md §8 pairs it with "Use it anyway": the app doubts the number, it does not refuse it.
  ///
  /// In en, this message translates to:
  /// **'That\'s higher than any car has driven. Check the number.'**
  String get odometerImplausibleWarning;

  /// Dismisses a warning and accepts the value exactly as typed.
  ///
  /// In en, this message translates to:
  /// **'Use it anyway'**
  String get commonUseItAnyway;

  /// Label above the four annual-distance bands, kilometre version. The unit lives in the LABEL so the chips carry none — EPIC-09 F-9.12, which is why they need no truncation budget in German.
  ///
  /// In en, this message translates to:
  /// **'About how far a year? (thousand km)'**
  String get annualBandLabelKm;

  /// The same label for a miles vehicle. The bands are defined per unit system and are not converted (SPEC.md §4.8).
  ///
  /// In en, this message translates to:
  /// **'About how far a year? (thousand miles)'**
  String get annualBandLabelMi;

  /// The lowest annual band. {max} is a number the app has already formatted in the active numbering system — never write a digit into this string, and never add a unit.
  ///
  /// In en, this message translates to:
  /// **'under {max}'**
  String annualBandUnder(String max);

  /// A middle annual band. The separator is U+2013 EN DASH, not a hyphen and not an em dash. Both values arrive already formatted.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max}'**
  String annualBandRange(String min, String max);

  /// The highest annual band, which is open-ended.
  ///
  /// In en, this message translates to:
  /// **'over {min}'**
  String annualBandOver(String min);

  /// The primary button that finishes first-run setup and opens the app.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// Quiet button under Start, opening the OS document picker. Deliberately SHORTER than `firstrun.language`'s two-line offer: by this screen the user has already declined it once. Odova is the app name.
  ///
  /// In en, this message translates to:
  /// **'I already have an Odova backup'**
  String get firstRunHaveBackup;

  /// Shown when the create transaction fails. SPEC.md §8: a disk write is the only thing that can fail on this screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Your phone may be out of space.'**
  String get saveDiskFullError;

  /// Tries the failed save again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Modal title on the screen that edits every fact about one vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleEditTitle;

  /// Accessible name for the ✕ that dismisses a full-screen modal. NEVER drawn as text — a screen reader speaks it, which is why the label is required even when a glyph replaces it.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// The modal end action that commits the form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Vehicle type. Not a car, van or motorbike. `truck` has no segment — EPIC-09 F-9.21, raised rather than closed.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vehicleTypeOther;

  /// Field label. The manufacturer.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehicleMakeLabel;

  /// Field label. The model name.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModelLabel;

  /// Field label. Model year. German uses Baujahr, which is strictly build year — the everyday word, and what every German car form asks for.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get vehicleYearLabel;

  /// Field label. The registration plate, stored VERBATIM — never digit-shaped, never uppercased, and forced LTR in its own field even on an RTL screen.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get vehiclePlateLabel;

  /// Field label. Vehicle identification number. German ships FIN, its own established abbreviation and the one printed on a German registration document; the other five keep VIN.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vehicleVinLabel;

  /// Field label above a scrolling row of paint swatches.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get vehicleColourLabel;

  /// Field label. Free multiline text, taking direction from its content.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vehicleNotesLabel;

  /// Switch label. Turning it on splits this vehicle into the business side of the cost report.
  ///
  /// In en, this message translates to:
  /// **'Do you drive this for work?'**
  String get vehicleBusinessLabel;

  /// Switch label. Stops notifications for this vehicle only.
  ///
  /// In en, this message translates to:
  /// **'Mute reminders for this vehicle'**
  String get vehicleMuteLabel;

  /// A READ-ONLY row showing the latest reading; tapping it opens log.odometer. SPEC.md §8: a facts form is the wrong place to write a dated reading.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get vehicleOdometerRow;

  /// The odometer row's sub-line on `vehicle.edit`: how old the reading is. It used to end '· tap to update', which promised a tap the row does not have — EPIC-11 owns `log.odometer`, and until it exists the row is inert. EPIC-11 puts the invitation back when the destination does. SPEC.md §8's rule for the disclosure groups is the same rule: a control that lies is worse than one that is absent.
  ///
  /// In en, this message translates to:
  /// **'entered {age}'**
  String vehicleOdometerRowHint(String age);

  /// Opens the sale form. Offered before Delete because it is what people usually mean.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get vehicleMarkAsSold;

  /// SPEC.md §8 quotes this button verbatim in `dialog.confirmDelete`: `[ Keep it — mark it sold ]`. Deliberately NOT `vehicleMarkAsSold`, which is the row and the sheet's own title: the 'Keep it —' half is the reassurance, and §8 offers the sale before Delete because 'I sold the car' is what people mean most of the time they reach for Delete.
  ///
  /// In en, this message translates to:
  /// **'Keep it — mark it sold'**
  String get vehicleKeepItMarkSold;

  /// A destructive ROW, not a dialog title — it takes NO question mark, because a row does not ask. Deliberately NOT `confirmDeleteTitle`, which always ends in one.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and its {countText} entries'**
  String vehicleDeleteRow(String name, String countText);

  /// The same row when the vehicle has no entries at all.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String vehicleDeleteRowEmpty(String name);

  /// A disclosure group, collapsed by default, holding purchase date, purchase odometer, purchase price and the sale fields.
  ///
  /// In en, this message translates to:
  /// **'Purchase and sale'**
  String get vehiclePurchaseGroup;

  /// A disclosure group, collapsed by default, holding the six per-vehicle overrides.
  ///
  /// In en, this message translates to:
  /// **'This vehicle\'s units & currency'**
  String get vehicleUnitsGroup;

  /// The option that writes NULL and lets the app-wide setting decide. Null is not "a value that matches the global" — it is an instruction to keep following it.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get commonAutomatic;

  /// Field label. When the user bought the vehicle. Never later than today.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get vehiclePurchaseDate;

  /// Field label. What they paid.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get vehiclePurchasePrice;

  /// Field label. The reading when they bought it. A vehicle FACT and not an observation — it emits no odometer reading, because the series records what was seen on a date.
  ///
  /// In en, this message translates to:
  /// **'Odometer at purchase'**
  String get vehiclePurchaseOdometer;

  /// Field label in the sale form. The date it was sold.
  ///
  /// In en, this message translates to:
  /// **'Sold on'**
  String get vehicleSoldOn;

  /// Field label in the sale form. What it sold for.
  ///
  /// In en, this message translates to:
  /// **'Sold price'**
  String get vehicleSoldPrice;

  /// Inline error under the year field. Both values are already-formatted numbers. The upper bound is next year, because next year's models are on sale this year.
  ///
  /// In en, this message translates to:
  /// **'Enter a year between {min} and {max}.'**
  String vehicleYearRangeError(String min, String max);

  /// A NOTE and not an error: the field still saves. Some pre-1981 and non-road vehicles have shorter numbers, and refusing theirs would mean refusing the vehicle.
  ///
  /// In en, this message translates to:
  /// **'A VIN is usually {countText} characters.'**
  String vehicleVinLengthNote(String countText);

  /// A NOTE and not an error: duplicates are allowed. Two vans with the same name is the user's business. No full stop, matching a label rather than a sentence.
  ///
  /// In en, this message translates to:
  /// **'You already have a vehicle called {name}'**
  String vehicleDuplicateNameNote(String name);

  /// A PERMANENT line under the per-vehicle currency override. It promises that changing it rewrites no history — money already stored keeps the currency it was stored in.
  ///
  /// In en, this message translates to:
  /// **'Only new entries use this. Nothing already saved changes.'**
  String get vehicleCurrencyChangeNote;

  /// Shown once when the fuel kind changes. It promises that petrol becoming diesel deletes and rewrites no reminder row, which would be deleting somebody’s history.
  ///
  /// In en, this message translates to:
  /// **'Reminders keep the intervals they already have.'**
  String get vehicleFuelChangeNote;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colourWhite;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colourSilver;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get colourGrey;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colourBlack;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colourRed;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colourBlue;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colourGreen;

  /// Vehicle paint colour.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colourYellow;

  /// Not one of the eight paints. Drawn as an OUTLINED swatch with no fill — EPIC-09 F-9.18, which refused to invent a ninth hex.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get colourOther;

  /// How long ago something was recorded. A PAST phrase, and deliberately not `dateDaysOverdue`, which is about a missed due date. German capitalises it, because `vehicleOdometerRowHint` places it first: "Vor 3 Tagen erfasst".
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} day ago} other{{nText} days ago}}'**
  String dateDaysAgo(int n, String nText);

  /// How long ago, in weeks, for a span of 14 to 55 days. SPEC.md §5: a rounded answer rather than a day count. German capitalises it because vehicleOdometerRowHint places it first.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{about {nText} week ago} other{about {nText} weeks ago}}'**
  String dateAboutWeeksAgo(int n, String nText);

  /// How long ago, in months, for a span of 56 days or more. SPEC.md §8: "Odometer last updated 4 months ago".
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{about {nText} month ago} other{about {nText} months ago}}'**
  String dateAboutMonthsAgo(int n, String nText);

  /// App bar title of the garage: the screen that lists, reorders, sells and deletes vehicles. Management only — NOT where the active vehicle is switched.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehiclesTitle;

  /// A caption at the top of the garage. It exists to stop people looking for the car switcher here; it lives on the Home title instead. German drops "garage", where the word means the building.
  ///
  /// In en, this message translates to:
  /// **'Manage the garage here. Switching cars happens from the Home title.'**
  String get vehiclesIntro;

  /// A caption at the foot of the garage, teaching two gestures. Hidden when there is only one vehicle, because neither gesture applies.
  ///
  /// In en, this message translates to:
  /// **'Press and hold a row to reorder. Swipe for sell and delete.'**
  String get vehiclesReorderHint;

  /// A collapsed group header at the bottom of the garage, holding vehicles the user no longer drives.
  ///
  /// In en, this message translates to:
  /// **'Sold and archived'**
  String get vehiclesSoldArchived;

  /// The third line of a garage row when nothing is due. Calm and final — a fact stated, never congratulation offered.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get vehicleStatusAllGood;

  /// The third line when the vehicle has no tracked reminders at all. A statement, not a prompt.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get vehicleStatusNoReminders;

  /// The third line when the last reading is too old to project from. It names the action without commanding it.
  ///
  /// In en, this message translates to:
  /// **'Odometer needs updating'**
  String get vehicleStatusNeedsOdometer;

  /// The third line when the due engine failed. The row never disappears — SPEC.md §2: the app admits it does not know rather than guessing. An admission, never an apology.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t work out what\'s due'**
  String get vehicleStatusUnknown;

  /// The status half of the garage row's third line when the last reading is over 60 days old. SPEC.md §8. {age} is a bucketed phrase from relative_past.dart — "4 months ago", never a day count.
  ///
  /// In en, this message translates to:
  /// **'Odometer last updated {age}'**
  String vehicleOdometerStale(String age);

  /// The status half of the garage row's third line past the 180-day projection lifetime, when the figure shown is the ENTERED one and carries no ~. SPEC.md §8: "187,412 km · last entered 12 Jul 2025".
  ///
  /// In en, this message translates to:
  /// **'last entered {date}'**
  String vehicleOdometerLastEntered(String date);

  /// The third line naming the worst item. {item} is an already-localised service name like "Oil and filter".
  ///
  /// In en, this message translates to:
  /// **'{item} overdue'**
  String vehicleStatusOverdue(String item);

  /// The garage's third line for an item that is DUE with no day count. A distance-only reminder has no remainingDays, and vehicleStatusDueInDays cannot render without one — SPEC.md §2 forbids inventing the number, and falling through to vehicleStatusOverdue makes a louder claim than the engine did.
  ///
  /// In en, this message translates to:
  /// **'{item} due'**
  String vehicleStatusDue(String item);

  /// The {item} in vehicleStatusOverdue and vehicleStatusDueInDays when the app cannot name the item. A catalogue ServiceItem's label comes from the 28 kind strings EPIC-10 owns, and until they exist the garage would otherwise pair a red dot with "Couldn't work out what's due" — two contradictory statements. This is a generic noun, not a guess: something tracked really is overdue, and only its name is missing.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get vehicleStatusItemGeneric;

  /// Added to the delete confirmation when the garage holds one vehicle. It warns without forbidding — the user may still delete it.
  ///
  /// In en, this message translates to:
  /// **'This is your only vehicle. Deleting it starts Odova over.'**
  String get vehiclesOnlyOneWarning;

  /// A snackbar action after adding a vehicle from the garage. The new vehicle is NOT made active automatically; this offers it.
  ///
  /// In en, this message translates to:
  /// **'Switch to it'**
  String get vehicleSwitchToIt;

  /// Title of `vehicle.edit` in CREATE mode, where there is no vehicle name to title it with. Deliberately its own key rather than `switcherAddVehicle`: that one is a button in a sheet, and a translator may want a different register for a modal's title.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get vehicleAddTitle;

  /// The snackbar after adding a vehicle from the garage. Paired with the `vehicleSwitchToIt` action, because SPEC.md §8 says the new vehicle does NOT become active — it is offered.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String vehicleAddedSnack(String name);

  /// Title of the sheet that changes which vehicle the app is showing.
  ///
  /// In en, this message translates to:
  /// **'Switch vehicle'**
  String get switcherTitle;

  /// A subtitle under the switcher title, counting the LIVE vehicles — sold and archived ones are not in it.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} vehicle} other{{nText} vehicles}}'**
  String switcherCount(int n, String nText);

  /// A footer action in the switcher sheet. Opens the vehicle form over the sheet.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get switcherAddVehicle;

  /// A footer action in the switcher sheet. Dismisses and opens the garage. SPEC.md §8 names the German wording for this one itself.
  ///
  /// In en, this message translates to:
  /// **'Manage vehicles'**
  String get switcherManageVehicles;

  /// A small badge on a vehicle driven for work. One word, on a chip.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get vehicleBusinessBadge;

  /// Accessible name for the back chevron in an app bar. Never drawn as text.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Accessible name for a + in an app bar. Never drawn as text.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// A destructive action label. Deliberately the same word as `confirmDeleteDelete`, so a row and the dialog it opens cannot disagree.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// The snackbar action. SPEC.md §10: confirmation is a snackbar with Undo, never a dialog. French uses Annuler for both Cancel and Undo — they are different actions in English and the same word here, which is correct and worth knowing before somebody 'fixes' it.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// The snackbar after a vehicle delete. SPEC.md §8 gives it a 10-second Undo rather than the usual 6.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String vehicleDeletedSnack(String name);

  /// The snackbar after Mark as sold. No Undo: the sale is one row and the form that wrote it is one tap away, unlike a delete that takes five tables with it.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as sold'**
  String vehicleSoldSnack(String name);

  /// The second line of a sold vehicle in the garage. {date} is an already-formatted ABSOLUTE date — a relative one would read "Sold Today". Written WITHOUT a plural first, which rendered "1 entries"; two translators caught it independently before any test did. SPEC.md §8 requires an explicit =0 case, and every locale carries one EXCEPT Arabic: CLDR's Arabic `zero` category is n = 0, so an =0 clause shadows it and the language renders five forms where it has six. Arabic already owns the slot, so the date-only sentence lives in `zero` there. `plurals_test.dart` caught this; it is not a thing a reviewer would see.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Sold {date}} one{Sold {date} · {countText} entry} other{Sold {date} · {countText} entries}}'**
  String vehicleSoldSummary(int n, String date, String countText);

  /// The third line of a garage row when the worst reminder is due soon. {item} is an already-localised service name. Arabic's `one` and `two` branches carry NO {countText}, because Arabic encodes 1 and 2 in the noun itself — printing the numeral there would be the same defect as "1 entries", in Arabic.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{item} due in {countText} day} other{{item} due in {countText} days}}'**
  String vehicleStatusDueInDays(int n, String item, String countText);

  /// Home's status line when the distance axis drove the overdue. SPEC.md §9: overdue uses its own POSITIVE string — never "in −1,400 km". The distance and its unit arrive as one already-isolated run.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {distance}'**
  String homeOverdueByDistance(String distance);

  /// The same line when the time axis drove it.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {duration}'**
  String homeOverdueByTime(String duration);

  /// Both axes overdue. §9: "distance phrasing wins when both axes are overdue, because a kilometre figure is checkable against the dash and a date is not" — so the distance leads.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {distance} and {duration}'**
  String homeOverdueByBoth(String distance, String duration);

  /// The `due` status line. No number: §9 gives this state a bare statement, because a figure would suggest a precision the grace window does not have.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get homeDueNow;

  /// `due_soon` driven by distance, at `measured` or `assumed` confidence only. At `default` the card says `homeDueSoonNoConfidence` instead and shows no figure at all.
  ///
  /// In en, this message translates to:
  /// **'in about {distance}'**
  String homeDueSoonDistance(String distance);

  /// The `needs_odometer` status line. §9: "a request, not an accusation" — the app has lost track of the distance axis and is asking, not blaming.
  ///
  /// In en, this message translates to:
  /// **'Needs an odometer reading'**
  String get homeNeedsOdometer;

  /// The unknown-anchor card's heading. §9: a used car must not open on eleven cards shouting OVERDUE, so every item anchored on purchase or the first reading collapses into this one card.
  ///
  /// In en, this message translates to:
  /// **'When were these last done?'**
  String get homeUnknownTitle;

  /// The line under the named items on the unknown-anchor card. It says what answering buys, rather than nagging.
  ///
  /// In en, this message translates to:
  /// **'Telling me turns them into reminders.'**
  String get homeUnknownHint;

  /// How many unknown-anchored items the card did not name. The =0 case is the card's row WITHOUT a count — the screen draws no "+ 0 more", and a zero branch that rendered empty would be indistinguishable from a branch somebody emptied by mistake.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{See all} one{+ {nText} more} other{+ {nText} more}}'**
  String homeUnknownMore(int n, String nText);

  /// The red see-all row under the stack, counting the due or overdue items that did not fit in three cards. At =0 nothing is left over and the screen uses `remindersSeeAll` instead; this branch is the honest fallback rather than an empty string.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{See all reminders} one{See all — {nText} more due or overdue} other{See all — {nText} more due or overdue}}'**
  String homeMoreDue(int n, String nText);

  /// A snoozed item's fourth line. §9: it stays on Home and stays red — the snooze is a note, not a state.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}'**
  String homeSnoozedUntil(String date);

  /// The see-all row, counting ALL tracked items rather than the due ones — §9 is explicit, and counting the due ones would make the row disagree with the screen it opens. At =0 the vehicle has nothing tracked and §9 does not draw the row at all.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{See all reminders} one{See all reminders ({nText})} other{See all reminders ({nText})}}'**
  String remindersSeeAll(int n, String nText);

  /// The header on `reminders.list` and on first run's seeded catalogue — SPEC.md §4.8's own sentence, and the same key in both places so the two cannot drift.
  ///
  /// In en, this message translates to:
  /// **'Odova starts you off with the usual jobs. Your handbook wins — edit anything here.'**
  String get remindersDisclaimer;

  /// The primary card's button for every state the user can act on directly.
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get actionLogIt;

  /// The primary button when the app needs a reading before it can say anything — `needs_odometer`, and `due_soon` by distance at default confidence.
  ///
  /// In en, this message translates to:
  /// **'Update odometer'**
  String get actionUpdateOdometer;

  /// How far past due, as a bare quantity. SPEC.md §9 supplies the word "overdue" around it, so this carries no direction — the overshoot is positive and the sentence says which way it points.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} day} other{{nText} days}}'**
  String homeDurationDays(int n, String nText);

  /// See homeDurationDays. The buckets are `bucketRelativeDays` read forwards, so "21 days overdue" reads as "3 weeks".
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} week} other{{nText} weeks}}'**
  String homeDurationWeeks(int n, String nText);

  /// See homeDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} month} other{{nText} months}}'**
  String homeDurationMonths(int n, String nText);

  /// The odometer strip's second line when the number is a READING the user typed. SPEC.md §9 keeps entered and projected visibly different, and this is half of that: an entered value has no tilde and says when it was entered.
  ///
  /// In en, this message translates to:
  /// **'entered {date}'**
  String homeEnteredOn(String date);

  /// The popover behind an estimated value. §9 allows exactly one sentence and one action, and no percentage, no bar and no tier name — "the tilde and the word 'about' are the whole vocabulary".
  ///
  /// In en, this message translates to:
  /// **'Estimated from about {rate} a day since {date}.'**
  String homeEstimatedFrom(String rate, String date);

  /// The popover when `estimateOdometer` has stopped projecting — past 180 days. §9: "Ten thousand kilometres of invented number is worse than a blank." It says the app stopped rather than pretending it did not.
  ///
  /// In en, this message translates to:
  /// **'Your last reading is too old, so Odova has stopped guessing. Enter what the dash says now.'**
  String get homeEstimateExpired;

  /// The popover behind the consumption tile before there are two full fill-ups. §9 makes this one dismissal-only: there is nothing for the user to do but drive and fill up.
  ///
  /// In en, this message translates to:
  /// **'Your first consumption figure arrives at your next full fill-up.'**
  String get homeConsumptionPending;

  /// The 56pt read-out row under the glance tiles. A heading, not a link — SPEC.md §9 gives the row no action.
  ///
  /// In en, this message translates to:
  /// **'Last fill-up'**
  String get homeLastFillUp;

  /// The last fill-up row's second line: when it happened and how much went in. Both parts are formatted upstream; the separator is the only copy here.
  ///
  /// In en, this message translates to:
  /// **'{date} · {volume}'**
  String homeLastFillUpDetail(String date, String volume);

  /// The other-vehicles row when another car has overdue work. It names the VEHICLE and the count, never the job — SPEC.md §9: "Home shows whose problem it is, not what it is."
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{name} · {nText} overdue} other{{name} · {nText} overdue}}'**
  String homeOtherVehicleOverdue(int n, String nText, String name);

  /// The other-vehicles row when another car has work due but nothing overdue. A separate key from homeOtherVehicleOverdue because the two words are not interchangeable.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{name} · {nText} due} other{{name} · {nText} due}}'**
  String homeOtherVehicleDue(int n, String nText, String name);

  /// The second glance tile's two-line label — cost per kilometre or mile. {unit} is the abbreviation from the unit keys, never spelled out here.
  ///
  /// In en, this message translates to:
  /// **'per {unit}'**
  String homeTilePerDistance(String unit);

  /// The third glance tile's two-line label — what the vehicle costs in a month.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get homeTilePerMonth;

  /// The accessible name of the due card's ⋯ button. It carries no visible word, so this is the only thing a screen reader can announce.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get homeMoreActions;

  /// The card overflow's second item, opening dialog.snooze. A verb: it is what the tap does, not what the state is called.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get actionSnooze;

  /// The card overflow's third item, opening reminders.edit for this item.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get actionEditReminder;

  /// The card overflow's last item. It sets is_active = false on the item — it does not delete anything, which is why the wording is "turn off" rather than "remove".
  ///
  /// In en, this message translates to:
  /// **'Turn this off'**
  String get actionTurnOff;

  /// The snackbar after Turn this off. It carries an Undo, so it names the item rather than saying "done".
  ///
  /// In en, this message translates to:
  /// **'{item} turned off'**
  String homeTurnedOff(String item);

  /// Consumption as distance per volume — the inverse direction, where HIGHER is better. Its own key rather than a reversal of unitConsumptionPerDistance, which bakes the hundred in.
  ///
  /// In en, this message translates to:
  /// **'km/L'**
  String get unitConsumptionKmPerLitre;

  /// Electric consumption as energy per distance. {n} is the hundred, as a PLACEHOLDER rather than a literal, for the same reason unitConsumptionPerDistance carries one — and a String for the same reason too: the shaping belongs to the formats tag, not to gen-l10n.
  ///
  /// In en, this message translates to:
  /// **'kWh/{n} km'**
  String unitConsumptionKwhPerDistance(String n);

  /// Electric consumption as distance per energy, where HIGHER is better.
  ///
  /// In en, this message translates to:
  /// **'mi/kWh'**
  String get unitConsumptionMiPerKwh;

  /// The energy abbreviation, for an electric fill-up. Ours rather than the platform's, like every other unit label — SPEC.md §5.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get unitEnergyKwh;

  /// The mass abbreviation, for a CNG fill-up, which is sold by weight rather than by volume.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitMassKg;

  /// An estimated figure, with the mark SPEC.md §1.4 gives it. The tilde is the marker in every locale, so the six values are identical today — the key exists so that the mark's SIDE is a translation decision rather than a Dart concatenation, and so it lands inside the number's bidi isolate instead of in front of it.
  ///
  /// In en, this message translates to:
  /// **'~{value}'**
  String commonEstimatedValue(String value);

  /// The overdue card's anchor line when DISTANCE drove the status. SPEC.md §9: a kilometre figure is checkable against the dash and a date is not, so the distance leads whenever there is one.
  ///
  /// In en, this message translates to:
  /// **'Was due at {odometer}'**
  String homeWasDueAt(String odometer);

  /// The overdue card's anchor line when TIME drove the status and there is no odometer to name.
  ///
  /// In en, this message translates to:
  /// **'Was due {date}'**
  String homeWasDueOn(String date);

  /// The overdue card's anchor line when both axes are past. One message rather than two joined in Dart — SPEC.md §2 forbids assembling a sentence from parts, and the separator's side is a translation decision.
  ///
  /// In en, this message translates to:
  /// **'Was due at {odometer} · {date}'**
  String homeWasDueAtOn(String odometer, String date);

  /// The due card's anchor line when only a distance is known. Present tense: the job is due now, not overdue.
  ///
  /// In en, this message translates to:
  /// **'At {odometer}'**
  String homeDueAt(String odometer);

  /// The due card's anchor line when both axes are known — SPEC.md §9's `At 192,000 km · 10 October`.
  ///
  /// In en, this message translates to:
  /// **'At {odometer} · {date}'**
  String homeDueAtOn(String odometer, String date);

  /// A date PROJECTED from the distance axis, and the only vocabulary SPEC.md §9 allows for one: the word "around" and nothing else. Never used for a date the calendar produced, which is exact and reads plainly.
  ///
  /// In en, this message translates to:
  /// **'around {date}'**
  String homeAroundDate(String date);

  /// The needs-odometer card's anchor line. It states what the app HAS rather than what it wants — an accusation the app cannot support is the thing SPEC.md §9 is most careful to avoid.
  ///
  /// In en, this message translates to:
  /// **'Last entered {date}'**
  String homeLastEntered(String date);

  /// The stale-odometer strip's first line. It states a fact about the APP rather than asking the user for something — SPEC.md §1: the app tells people things rather than asking them things, and the field underneath is the ask.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Odometer last updated {nText} day ago.} other{Odometer last updated {nText} days ago.}}'**
  String homeStripStale(int n, String nText);

  /// The stale-odometer strip's ✕, as a screen reader hears it. The glyph carries no word, and "close" would understate it: SPEC.md §9 hides the strip for seven days on that vehicle, which is a decision rather than a dismissal.
  ///
  /// In en, this message translates to:
  /// **'Hide this for a week'**
  String get homeStripStaleDismiss;

  /// The done-from-notification confirmation strip, first line. Second person, because the user did this and the app is confirming it back — not announcing it.
  ///
  /// In en, this message translates to:
  /// **'You marked {item} done on {date}.'**
  String homeStripDoneTitle(String item, String date);

  /// The confirmation strip's second line. It names what the app GUESSED, so the estimate mark travels with the number — that is what "Add the real numbers" is offering to replace.
  ///
  /// In en, this message translates to:
  /// **'I recorded {odometer} and no cost.'**
  String homeStripDoneRecorded(String odometer);

  /// The confirmation strip's third line — the consequence of the record, which is the thing the user actually wanted to know.
  ///
  /// In en, this message translates to:
  /// **'Next due at {odometer} · {date}.'**
  String homeStripDoneNext(String odometer, String date);

  /// The confirmation strip's first action. It opens log.service in edit mode on the record the notification wrote.
  ///
  /// In en, this message translates to:
  /// **'Add the real numbers'**
  String get actionAddRealNumbers;

  /// The confirmation strip's second action. It clears odometer_estimated and cost_estimated on the record — the user has confirmed the app's guesses, so they stop being guesses.
  ///
  /// In en, this message translates to:
  /// **'That\'s right'**
  String get actionThatsRight;

  /// One line of the away digest, for something that went past due while the app was closed. Past tense: it already happened.
  ///
  /// In en, this message translates to:
  /// **'{item} went overdue on {date}'**
  String homeDigestOverdue(String item, String date);

  /// One line of the away digest, for something coming up rather than past.
  ///
  /// In en, this message translates to:
  /// **'{item} is due {date}'**
  String homeDigestDue(String item, String date);

  /// The away digest's ✕, as a screen reader hears it.
  ///
  /// In en, this message translates to:
  /// **'Dismiss this summary'**
  String get homeDigestDismiss;

  /// The snackbar after the stale-odometer strip writes a reading. It carries an Undo, so it says what happened rather than thanking the user.
  ///
  /// In en, this message translates to:
  /// **'Odometer saved'**
  String get odometerSavedSnack;

  /// The all-clear headline. Present tense, no exclamation mark, no praise: SPEC.md §9 makes this the most common state in the app and the one most apps waste.
  ///
  /// In en, this message translates to:
  /// **'Nothing due'**
  String get homeNothingDue;

  /// The all-clear card's second line — the next item and its exact date, off the TIME axis. Without it the card is an assertion; with it, an answer.
  ///
  /// In en, this message translates to:
  /// **'Next: {item}, {date}'**
  String homeNextIs(String item, String date);

  /// The label above the all-clear's receipt line. The receipt is what turns a claim into evidence — SPEC.md §9 names the most recent service, whatever it was.
  ///
  /// In en, this message translates to:
  /// **'Since the last {item}:'**
  String homeSinceLast(String item);

  /// The receipt itself — "3,120 km · 4 months". Both halves are formatted upstream; the separator is the only copy here.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {duration}'**
  String homeSinceLastFigure(String distance, String duration);

  /// The unknown-anchor card's headline on FIRST RUN, where the app knows nothing yet. An invitation, not the "When were these last done?" question it asks once it has a list.
  ///
  /// In en, this message translates to:
  /// **'Set up your reminders — tell me when things were last done'**
  String get homeFirstRunSetUp;

  /// The one line under the first-run tiles. A STATEMENT and not a button — SPEC.md §9: "the + is already one tap away".
  ///
  /// In en, this message translates to:
  /// **'Log a fill-up and your consumption starts here.'**
  String get homeFirstRunConsumption;

  /// The panel that REPLACES the due stack on a sold or archived vehicle. It states the fact rather than nagging: SPEC.md §9 gives such a vehicle no reminders, no notifications and no nudges.
  ///
  /// In en, this message translates to:
  /// **'This vehicle is marked sold ({date}).'**
  String homeSoldTitle(String date);

  /// The sold panel's ownership summary. Both figures come from records the user entered, which is why the panel keeps History and Costs fully available beneath it.
  ///
  /// In en, this message translates to:
  /// **'Owned {duration} · {distance} driven'**
  String homeSoldOwned(String duration, String distance);

  /// The whole of Home when the store cannot be read. One message and one button — SPEC.md §9: get the data out of the building before anything else.
  ///
  /// In en, this message translates to:
  /// **'Odova can\'t read your data.'**
  String get homeErrorTitle;

  /// The error state's only action. It goes to settings.backup, because the first thing to do with data that cannot be read is to get a copy of it out.
  ///
  /// In en, this message translates to:
  /// **'Open Backup & restore'**
  String get actionOpenBackup;

  /// One card whose derived state threw. SPEC.md §9: "one bad row never blanks the screen" — the card is grey, says so, and offers a chevron to the editor.
  ///
  /// In en, this message translates to:
  /// **'Something\'s wrong with this reminder'**
  String get homeRowBroken;

  /// The reminders.list app-bar title. The screen's own name, with the vehicle beside it.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// The second group header on reminders.list — items with is_active = false. SPEC.md §9 makes the header carry the word for a group whose rows print no status of their own, so the screen needs no legend.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get remindersGroupPaused;

  /// The third group header — catalogue rows the user has not switched on. They are excluded from the due engine, from Home and from notifications.
  ///
  /// In en, this message translates to:
  /// **'Not tracked'**
  String get remindersGroupNotTracked;

  /// The action in place of a status on an untracked row. It sets is_tracked and opens the editor, because a tracked item with no anchor is just another unknown. It WRAPS to two lines rather than truncating — German is "+ Verfolgen".
  ///
  /// In en, this message translates to:
  /// **'+ Track'**
  String get remindersTrack;

  /// A paused row's end text. The same word as its group header and a separate key, because a header names a group and this names one row — a translator may need different grammar for each.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get remindersPausedStatus;

  /// The reminders.list empty state — every item deleted. One line and the +, never an illustration.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet.'**
  String get remindersEmpty;

  /// Shown above the Paused group when every item is paused. A statement of fact rather than a nag: the user turned them off on purpose.
  ///
  /// In en, this message translates to:
  /// **'Nothing is being tracked on this vehicle.'**
  String get remindersNothingTracked;

  /// The end text of a tracked row the app has no anchor for — SPEC.md §9's reminders.list drawing. A question, because that is what it is; the row opens the editor where the answer goes.
  ///
  /// In en, this message translates to:
  /// **'When was this last done'**
  String get remindersWhenLastDone;

  /// The first swipe action on a reminders.list row. It writes a ServiceRecord through the logging mark-done path and offers an Undo.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get actionDoneToday;

  /// The third swipe action. Shorter than actionTurnOff because a swipe reveals a narrow tile, and a separate key because a swipe tile and a menu row have different room.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get actionTurnOffShort;
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
