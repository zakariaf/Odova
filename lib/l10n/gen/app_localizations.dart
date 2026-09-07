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

  /// §11's month header count — "9 entries · €412.80". `nText` is a SECOND placeholder for the same number because {n} selects the CLDR category and must be an int, and an int interpolated by gen-l10n renders in Latin digits — which would put "9" in Latin inside a Persian header while every other number on the screen is shaped. SPEC.md §5: one numbering system is active app-wide.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} entry} other{{nText} entries}}'**
  String historyMonthEntryCount(int n, String nText);

  /// §11 verbatim. One of three sentences a fill-up band shows INSTEAD of a figure; a row gets exactly one.
  ///
  /// In en, this message translates to:
  /// **'First fill-up — your first consumption figure arrives at the next full tank.'**
  String get bandFillUpFirstFill;

  /// §11 verbatim. Shown when the tank before this one was not logged.
  ///
  /// In en, this message translates to:
  /// **'No figure: the tank before this wasn\'t logged.'**
  String get bandFillUpChainBroken;

  /// §11 verbatim. Shown for a part fill, which produces no figure on its own.
  ///
  /// In en, this message translates to:
  /// **'No figure: partial fill.'**
  String get bandFillUpPartial;

  /// §11's fill-up band: the segment figure with the distance and dates it covers. Every part arrives already formatted and isolate-wrapped — the numbers are shaped against the FORMATS tag and the date through the locale's calendar.
  ///
  /// In en, this message translates to:
  /// **'{consumption} over {distance} since {date}'**
  String bandFillUpSegment(String consumption, String distance, String date);

  /// §11 verbatim in shape: "€ 480.00 over 12 months = € 40.00 a month." The month count is a pre-formatted, pluralised String rather than an int, so a Persian band does not render a Latin 12.
  ///
  /// In en, this message translates to:
  /// **'{total} over {months} = {perMonth} a month'**
  String bandExpenseSpread(String total, String months, String perMonth);

  /// §11 verbatim in shape: "1,240 km in 31 days — 40 km a day." Shown only where two readings are on different days; the same day implies no rate at all.
  ///
  /// In en, this message translates to:
  /// **'{distance} in {days} — {rate} a day'**
  String bandOdometerRate(String distance, String days, String rate);

  /// The destructive row at the BOTTOM of log.fillup in edit mode. §11: Delete "sits at the bottom of the form, destructive-styled, never in the app bar where Save is."
  ///
  /// In en, this message translates to:
  /// **'Delete this fill-up'**
  String get bandDeleteFillUp;

  /// §11's snackbar second half, verbatim in shape: "14 later fuel figures recalculated". The count comes from the recompute DIFF and never from what was edited — a message that counted the rows the user touched would say this for an edit that changed a vendor name. `nText` is a second placeholder for the same number because {n} selects the CLDR category and must be an int, and gen-l10n renders a bare int in Latin digits.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} later fuel figure recalculated} other{{nText} later fuel figures recalculated}}'**
  String recomputeFiguresRecalculated(int n, String nText);

  /// §11's last snackbar row: shown when NOTHING derived changed. Editing a vendor name must not claim to have recalculated anything.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get recomputeSaved;

  /// The first half of §11's fill-up snackbar. The second half — how many figures moved — is appended only when the diff says some did.
  ///
  /// In en, this message translates to:
  /// **'Fill-up updated'**
  String get recomputeFillUpUpdated;

  /// As recomputeFillUpUpdated, for a service record.
  ///
  /// In en, this message translates to:
  /// **'Service updated'**
  String get recomputeServiceUpdated;

  /// §11's expense row, which has no second half: an expense participates in no consumption figure.
  ///
  /// In en, this message translates to:
  /// **'Expense updated'**
  String get recomputeExpenseUpdated;

  /// As recomputeFillUpUpdated, for a standalone reading.
  ///
  /// In en, this message translates to:
  /// **'Reading updated'**
  String get recomputeOdometerUpdated;

  /// §11's app-bar action opening report.service. A NOUN, because it names a document rather than an act — the report is a thing handed to a buyer.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get historyReport;

  /// The search field's placeholder. One word — §11 makes search a mode inside history, not a screen with an explanation.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get historySearchHint;

  /// The button under a no-match result. Distinct from historyClearFilters: that one drops the chips, this one drops the query, and offering the wrong one leaves the user in the state they wanted out of.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get historySearchClear;

  /// §11 verbatim, quoting the query back so the user can see what was actually searched — a typo is the commonest reason for no match, and a message that does not repeat the term cannot show it.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String historySearchNoMatch(String query);

  /// The search affordance's accessible name. §11 shows it only above 200 rows.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get historySearch;

  /// §11's first filter chip. Selected by default.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// §11's type chip for fill-ups.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get historyFilterFuel;

  /// §11's type chip for service records.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get historyFilterService;

  /// §11's type chip for expenses. Plural in the languages that prefer it for a category of thing.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get historyFilterExpense;

  /// §11's type chip for trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get historyFilterTrip;

  /// §11's type chip for standalone readings.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get historyFilterOdometer;

  /// §11's store-read failure, full screen. It names the app rather than an error code, because the user's next act is a decision about their data and not a bug report.
  ///
  /// In en, this message translates to:
  /// **'Odova couldn\'t open your records.'**
  String get historyReadFailureTitle;

  /// The ONE button on that screen. §11: 'Get the data out of the building first' — export is the only useful act when the store will not open.
  ///
  /// In en, this message translates to:
  /// **'Go to Backup & restore'**
  String get historyReadFailureAction;

  /// §11's text button under an empty filtered list. The chip row stays interactive beside it; this is the one-tap version.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get historyClearFilters;

  /// §11's second line for a new vehicle. It says what starts the record rather than apologising for it being empty.
  ///
  /// In en, this message translates to:
  /// **'Your first fill-up starts the record.'**
  String get historyEmptySubtitle;

  /// §11's empty state for a vehicle with nothing logged. One sentence and a button; §11 gives it no illustration.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet.'**
  String get historyEmptyTitle;

  /// The empty state's single action. A fill-up, because it is what a new owner logs first — 2 to 6 times a month against everything else.
  ///
  /// In en, this message translates to:
  /// **'Log a fill-up'**
  String get historyEmptyAction;

  /// Shown when filters match nothing. The chip row STAYS visible and interactive: §11 never strands the user in a filter they cannot see.
  ///
  /// In en, this message translates to:
  /// **'No entries match these filters.'**
  String get historyFilteredEmpty;

  /// The secondary line of a standalone odometer row, per §11's type table. It names what the row IS, because the primary line is only a number.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get historyOdometerReading;

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

  /// Shown when a save is refused by the odometer monotonicity rule, NOT by a full disk. Every persist failure used to report saveDiskFullError, so a user whose reading was rejected as below the previous one was told their phone was out of space.
  ///
  /// In en, this message translates to:
  /// **'That reading is lower than the one before it. Check the number and try again.'**
  String get saveRefusedBackwards;

  /// Shown when the store is read-only — degraded mode after a failed migration. §10: the modal stays open with everything intact, so the message says so.
  ///
  /// In en, this message translates to:
  /// **'Odova can\'t write right now. Your entry is still here.'**
  String get saveRefusedReadOnly;

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

  /// The snooze swipe tile's label. Shorter than actionSnooze for the reason actionTurnOffShort is: a swipe reveals an 88pt tile with a glyph above two lines of text, and the Persian "یادآوری بعداً" overflowed it by 4pt. A separate key rather than a shortened translation, because the menu row has the room and should keep the fuller phrase.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get actionSnoozeShort;

  /// The reminders.edit modal head, in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderEditTitle;

  /// The reminders.edit modal head, in create mode.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get reminderNewTitle;

  /// The label field. A catalogue kind carries its own name; a custom item needs this one, and the `service_items` CHECK refuses it without.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get reminderName;

  /// The distance-interval field label — "Every 10,000 km". The unit sits at the end INSIDE the field, never concatenated after it.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get reminderEveryDistance;

  /// The time-interval field label. MONTHS and never days — SPEC.md §3: "Manuals say 12 months. Calendar addition stops a 12-month service creeping earlier every year."
  ///
  /// In en, this message translates to:
  /// **'Every … months'**
  String get reminderEveryMonths;

  /// The one-off odometer target. "Cambelt at 120,000 km."
  ///
  /// In en, this message translates to:
  /// **'Or once, at odometer'**
  String get reminderOnceAtOdometer;

  /// The one-off date target. A FUTURE date is allowed here, unlike the baseline.
  ///
  /// In en, this message translates to:
  /// **'Or once, on date'**
  String get reminderOnceOnDate;

  /// Half the baseline. Prefilled from the newest ServiceRecord for this item.
  ///
  /// In en, this message translates to:
  /// **'Last done — date'**
  String get reminderLastDoneDate;

  /// The other half of the baseline.
  ///
  /// In en, this message translates to:
  /// **'Last done — odometer'**
  String get reminderLastDoneOdometer;

  /// The notification switch. Off still shows on Home and still goes red; it just never posts — which is why the label is about notifying and not about tracking.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get reminderNotify;

  /// The two optional notice overrides. Blank means the automatic window, shown as a placeholder — SPEC.md §9, and the German is the reason labels sit ABOVE inputs rather than beside them.
  ///
  /// In en, this message translates to:
  /// **'Tell me this far ahead'**
  String get reminderNoticeAhead;

  /// The hint UNDER the notice pair: the window the due engine would compute when both fields are blank. A hint rather than a placeholder in each field, which is what the artboard draws and what stops the same sentence appearing twice. A PLACEHOLDER-class value and never a stored one — SPEC.md §2 forbids persisting a derived number, and a notice window written into the row would survive an interval change and then be wrong.
  ///
  /// In en, this message translates to:
  /// **'Blank means automatic — {distance} / {days}.'**
  String reminderNoticeAutomatic(String distance, String days);

  /// Safety, Normal or Low. It breaks ties when the notification cap coalesces.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get reminderPriority;

  /// The highest priority — brakes, tyres, a timing belt.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get reminderPrioritySafety;

  /// The default priority.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get reminderPriorityNormal;

  /// The lowest priority — a wiper blade, a cabin filter.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get reminderPriorityLow;

  /// Which day the next interval starts from. SPEC.md §3: from the day it was DONE suits most jobs; from the day it was DUE suits an inspection that stays in April.
  ///
  /// In en, this message translates to:
  /// **'When it repeats, count from'**
  String get reminderRollover;

  /// `from_actual` — the default.
  ///
  /// In en, this message translates to:
  /// **'The day it was done'**
  String get reminderRolloverActual;

  /// `from_due` — for anything on a fixed calendar.
  ///
  /// In en, this message translates to:
  /// **'The day it was due'**
  String get reminderRolloverDue;

  /// Off makes it a one-off that goes `ok` after completion.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get reminderRepeats;

  /// Free text, 500 characters. First-strong direction from the content, not from the UI language.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get reminderNotes;

  /// The inline message under the interval block when none of the four scheduling fields is set. The `service_items` CHECK says the same thing in SQL; this is the sentence that stops the row reaching it.
  ///
  /// In en, this message translates to:
  /// **'Set an interval or a target date — otherwise there\'s nothing to remind you about.'**
  String get reminderNoScheduleError;

  /// The inline message under the baseline odometer. A service cannot have happened before the car had been that far.
  ///
  /// In en, this message translates to:
  /// **'This is below the earliest reading for this vehicle.'**
  String get reminderBaselineTooLowError;

  /// The inline message under the baseline date. The TARGET date has no such rule — a future target is a plan.
  ///
  /// In en, this message translates to:
  /// **'A job cannot have been done in the future.'**
  String get reminderBaselineFutureError;

  /// The inline message under Name when a CUSTOM reminder has none. The `service_items` CHECK is `kind <> 'custom' OR label IS NOT NULL`, so this is the one field a custom item cannot be saved without. It used to print the field's own LABEL, which told the user nothing.
  ///
  /// In en, this message translates to:
  /// **'Give this reminder a name.'**
  String get reminderNameError;

  /// The snackbar after a reminder is deleted outright, with Undo beside it. Separate from homeTurnedOff: a deleted reminder is gone and a turned-off one is still on `reminders.list` under Paused, and saying the wrong one of those tells the user to look in the wrong place.
  ///
  /// In en, this message translates to:
  /// **'Deleted {item}'**
  String reminderDeletedSnack(String item);

  /// The banner on an untracked item, with Start tracking beside it.
  ///
  /// In en, this message translates to:
  /// **'Not tracked — you won\'t be reminded'**
  String get reminderNotTrackedBanner;

  /// The action on the untracked banner. It sets is_tracked.
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get reminderStartTracking;

  /// The action on the paused banner. It sets is_active.
  ///
  /// In en, this message translates to:
  /// **'Turn back on'**
  String get reminderTurnBackOn;

  /// What the destructive control becomes on an item that HAS been referenced by a service line. SPEC.md §9: such an item is not deletable, because deleting it would orphan the records that name it.
  ///
  /// In en, this message translates to:
  /// **'Turn this reminder off'**
  String get reminderTurnThisOff;

  /// The line under Turn this reminder off. It states what would be lost and that nothing will be — SPEC.md §2: eight years of service history is the most valuable object in the app.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} service is recorded against this. Turning it off keeps it.} other{{nText} services are recorded against this. Turning it off keeps them.}}'**
  String reminderCannotDelete(int n, String nText);

  /// The heading above the five most recent service records for this item. SPEC.md §9 calls it "the evidence behind the anchor, so a user who thinks the app is wrong can check instead of argue."
  ///
  /// In en, this message translates to:
  /// **'Last done'**
  String get reminderLastDoneHeading;

  /// The DAYS half of the notice override. Its label is not drawn — SPEC.md §9 asks the question once, above the pair — but it exists so that a screen-reader user can tell the two fields apart, which is the one thing a shared visible label takes away.
  ///
  /// In en, this message translates to:
  /// **'Tell me this far ahead — days'**
  String get reminderNoticeAheadDays;

  /// The log modal's first segment, and the title of the fill-up form. SPEC.md §10 opens on this segment from the central + whatever the caller, because a fill-up is logged ten times more often than anything else.
  ///
  /// In en, this message translates to:
  /// **'Fill-up'**
  String get logSegmentFillUp;

  /// The log modal's second segment, and the title of the service form.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get logSegmentService;

  /// The log modal's third segment, and the title of the expense form.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get logSegmentExpense;

  /// The log modal's fourth segment, and the title of the odometer form.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get logSegmentOdometer;

  /// The title of the fill-up form in edit mode. SPEC.md §10: edit mode has no segment bar, because an entry cannot change type.
  ///
  /// In en, this message translates to:
  /// **'Edit fill-up'**
  String get logEditFillUpTitle;

  /// The title of the service form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get logEditServiceTitle;

  /// The title of the expense form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get logEditExpenseTitle;

  /// The title of the odometer form in edit mode. A READING, not an odometer: what is being edited is one entry in the distance history.
  ///
  /// In en, this message translates to:
  /// **'Edit reading'**
  String get logEditOdometerTitle;

  /// The snackbar after a fill-up save. What HAPPENED, not what the button said — the first version reused logSaveFillUp and the user saw the imperative 'Save fill-up' beside an Undo, after having already saved.
  ///
  /// In en, this message translates to:
  /// **'Fill-up saved'**
  String get logSavedFillUp;

  /// As logSavedFillUp, for a service record.
  ///
  /// In en, this message translates to:
  /// **'Service saved'**
  String get logSavedService;

  /// As logSavedFillUp, for an expense.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get logSavedExpense;

  /// The full-width primary button pinned above the keyboard. SPEC.md §10 puts Save twice on every log form — the app bar's top-end corner is unreachable one-handed on a large phone, which is exactly the posture this form is designed for.
  ///
  /// In en, this message translates to:
  /// **'Save fill-up'**
  String get logSaveFillUp;

  /// The pinned primary button on the service form.
  ///
  /// In en, this message translates to:
  /// **'Save service'**
  String get logSaveService;

  /// The pinned primary button on the expense form.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get logSaveExpense;

  /// The pinned primary button on the odometer form.
  ///
  /// In en, this message translates to:
  /// **'Save reading'**
  String get logSaveOdometer;

  /// The destructive last row of the fill-up form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Delete this fill-up'**
  String get logDeleteFillUp;

  /// The destructive last row of the service form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Delete this service record'**
  String get logDeleteService;

  /// The destructive last row of the expense form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense'**
  String get logDeleteExpense;

  /// The destructive last row of the odometer form in edit mode.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading'**
  String get logDeleteOdometer;

  /// The summary half of dialog.discard when the log modal is dismissed dirty. Deliberately vague where the vehicle editor is specific: the modal holds four independent drafts and naming them all would be a list, not a sentence.
  ///
  /// In en, this message translates to:
  /// **'what you have typed'**
  String get logDiscardSummary;

  /// §10's date row on all four log forms. NOT reminderOnceOnDate, which is reminders.edit's 'Or once, on date' and reads as a schedule choice rather than the day this happened.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get logDateLabel;

  /// §10's odometer field label on the log forms, per the field table and the artboard. Distinct from odometerNowLabel ('Odometer now'), which CalmOdometerInput uses where the point is that the reading is being taken RIGHT NOW.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get logOdometerLabel;

  /// SPEC.md §10, verbatim. Shown under the date row on the fill-up, service and odometer forms. NOT on log.expense, where a future date is legitimate — prepaid insurance is real.
  ///
  /// In en, this message translates to:
  /// **'Pick today or a day in the past.'**
  String get logDateFutureError;

  /// SPEC.md §10, verbatim. The odometer is required on fill-ups and service records. Distinct from odometerEmptyError ('Enter the number on your dash.'), which is first run's wording for a user who has not met the field before.
  ///
  /// In en, this message translates to:
  /// **'Enter the odometer reading.'**
  String get logOdometerRequiredError;

  /// SPEC.md §10's Field kit. Shown when a typed decimal is ambiguous — 1,234,5 — rather than guessing which separator was meant. The example is deliberately concrete: a rule about separators is unreadable, a number is not. [example] is a PLACEHOLDER and not the literal 42.61, because a baked Latin figure would sit under a field the same user is typing Extended Arabic-Indic digits into — SPEC.md §5 resolves numerals from the device REGION, and no translator can fix that from an ARB file. The caller shapes it with formatForDisplay.
  ///
  /// In en, this message translates to:
  /// **'That number isn\'t clear. Try {example}.'**
  String logNumberUnclearError(String example);

  /// The fill-up form's own title, in the modal head. SEPARATE from logSegmentFillUp, which labels the segment bar: the artboard's Persian reads سوخت‌گیری here and سوخت there, so the design wants two words where English has one. A single key would have forced every RTL locale to pick which of the two to be wrong about.
  ///
  /// In en, this message translates to:
  /// **'Fill-up'**
  String get logTitleFillUp;

  /// The service form's title. See logTitleFillUp for why this is separate from the segment label.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get logTitleService;

  /// The expense form's title. See logTitleFillUp.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get logTitleExpense;

  /// The odometer form's title. The artboard's Persian reads کیلومترشمار here and کیلومتر in the segment bar.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get logTitleOdometer;

  /// The odometer field's helper line. The last ENTERED reading and its date — never a projection, because SPEC.md §10 says an estimate that arrives as a default gets saved unread.
  ///
  /// In en, this message translates to:
  /// **'Last entered {distance} on {date}'**
  String logOdometerLastEntered(String distance, String date);

  /// The helper line when the last reading is over 60 days old. It names the AGE instead of offering an estimate chip: SPEC.md §10, 'a 174-day-old estimate offered as a default would launder itself into a fact'. PLURAL on an int, with the rendered figure passed separately as [daysText] — the same shape homeStripStale uses. The first version took days as a plain String, which reads '1 days ago' in English before any translator sees it, and forces German, French and Arabic into a form that is wrong at some counts with no way to fix it from an ARB file. Arabic needs five shapes here, not two.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Last entered {distance} on {date} — {daysText} day ago} other{Last entered {distance} on {date} — {daysText} days ago}}'**
  String logOdometerLastEnteredStale(
    int days,
    String distance,
    String date,
    String daysText,
  );

  /// The tappable projection chip beside the helper line. [value] already carries the ~ from commonEstimatedValue, so this key never writes one. Tapping it fills the field, which is the whole design: an estimate that takes a tap was chosen.
  ///
  /// In en, this message translates to:
  /// **'{value} now'**
  String logOdometerEstimateChip(String value);

  /// The odometer helper's FIRST line: the last entered reading, with no date. The date moves to logOdometerSince, which carries the delta beside it — the artboard draws the two as a two-line block with the estimate chip alongside, not as three stacked rows.
  ///
  /// In en, this message translates to:
  /// **'Last entered {distance}'**
  String logOdometerLastEnteredShort(String distance);

  /// §10's log.odometer panel, second line. The date is on the line above it — 'Last entered … on 12 August' — so this one says 'since then' rather than repeating it. The + is literal, as in logOdometerDelta.
  ///
  /// In en, this message translates to:
  /// **'+{distance} since then'**
  String logOdometerSinceThen(String distance);

  /// The odometer helper's SECOND line: the last reading's date and how far the entry is above it, joined by a middot. The + is literal, exactly as logOdometerDelta carries it — the delta is always an increase here, and a bare number reads as the reading itself rather than the gap. Both halves are already formatted and isolate-wrapped by the caller.
  ///
  /// In en, this message translates to:
  /// **'{date} · +{distance}'**
  String logOdometerSince(String date, String distance);

  /// The live delta above the last reading — SPEC.md §10 calls it 'the cheapest possible check on a dropped digit'. One isolate-wrapped atom so the sign never detaches from the number.
  ///
  /// In en, this message translates to:
  /// **'+{distance} since {date}'**
  String logOdometerDelta(String distance, String date);

  /// Replaces the helper line when the date precedes every reading on the vehicle. Expected on a second-hand car, so it explains rather than warns, and the delta is suppressed.
  ///
  /// In en, this message translates to:
  /// **'Older than anything logged. This becomes your earliest reading.'**
  String get logOdometerOlderThanAnything;

  /// The three-way sheet's title. SPEC.md §10: a below-last value is never a bare error — the three answers are a typo, a replaced cluster, and a backdated entry, and only the user knows which.
  ///
  /// In en, this message translates to:
  /// **'This reading is lower than your last one'**
  String get logOdometerBelowLastTitle;

  /// The three-way sheet's body: the neighbour the new value conflicts with.
  ///
  /// In en, this message translates to:
  /// **'Last entered: {distance} on {date}.'**
  String logOdometerBelowLastBody(String distance, String date);

  /// The first of the three answers. Returns focus with the text selected.
  ///
  /// In en, this message translates to:
  /// **'It\'s a typo — let me fix it'**
  String get logOdometerBelowLastTypo;

  /// The second answer. Opens the correction sheet and writes an OdometerCorrection.
  ///
  /// In en, this message translates to:
  /// **'The odometer was replaced or rolled over'**
  String get logOdometerBelowLastReplaced;

  /// The third answer, offered only when the date is in the past. If the value fits between its date-neighbours the save proceeds silently.
  ///
  /// In en, this message translates to:
  /// **'It\'s an older entry I\'m adding now'**
  String get logOdometerBelowLastOlder;

  /// Blocks a backdated reading that is HIGHER than the current earliest. Names both ends, because SPEC.md §3's three resolutions all need them. [date] is a DAY-AND-MONTH ('2 September') and [when] is a MONTH-AND-YEAR ('May 2019') — the two are deliberately different granularities and a translator cannot tell from the English, because the preposition differs between them in every Romance and Germanic language.
  ///
  /// In en, this message translates to:
  /// **'Your earliest reading is {distance} on {date}. A reading from {when} has to be lower than that.'**
  String logOdometerAboveEarliest(String distance, String date, String when);

  /// An amber soft warning, over 2,000 km/day. It warns and still saves — a delivery driver really does do 2,400 km in a day.
  ///
  /// In en, this message translates to:
  /// **'That\'s about {rate} a day since {date}. Is that right?'**
  String logOdometerRateWarning(String rate, String date);

  /// An amber soft warning on a MILES vehicle when the new value is 1.5-1.7x the last — the ratio of a kilometre reading typed into a miles field. It offers the converted figure and still saves.
  ///
  /// In en, this message translates to:
  /// **'Did you mean {value}? This looks like kilometres.'**
  String logOdometerUnitMixUpWarning(String value);

  /// An amber soft warning on a single jump over 100,000 km. Warns and still saves: an imported vehicle's first manual reading legitimately jumps.
  ///
  /// In en, this message translates to:
  /// **'That\'s a jump of {distance}. Is that right?'**
  String logOdometerJumpWarning(String distance);

  /// Offered after a unit change on one entry. The per-entry override leaves the vehicle alone by design; this is the one place the app asks whether the change was meant to be permanent. The unit word is inside the sentence because German and Persian decline it.
  ///
  /// In en, this message translates to:
  /// **'Show all your readings in kilometres from now on?'**
  String get logOdometerSwitchUnitPrompt;

  /// The accessible name of the unit chip beside the odometer field. It says 'for this entry' because that is exactly what it changes — the vehicle's display unit is untouched.
  ///
  /// In en, this message translates to:
  /// **'Unit for this entry'**
  String get logOdometerUnitChipLabel;

  /// The number pad's secondary key on log.odometer. It empties the field rather than deleting one digit — backspace already does that, and a pad with two ways to delete one character and none to start over is a pad you fight.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logOdometerPadClear;

  /// The backspace key's spoken name. It carries a glyph and no text, so without this a screen reader announces 'button'.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get logOdometerPadBackspace;

  /// §10 log.expense category chip: an insurance premium.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get expenseCategoryInsurance;

  /// §10 log.expense category chip: road tax or registration. German is the longest string in the app and must wrap, never truncate.
  ///
  /// In en, this message translates to:
  /// **'Road tax'**
  String get expenseCategoryTaxRegistration;

  /// §10 log.expense category chip: parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get expenseCategoryParking;

  /// §10 log.expense category chip: a road toll.
  ///
  /// In en, this message translates to:
  /// **'Toll'**
  String get expenseCategoryToll;

  /// §10 log.expense category chip: a traffic fine.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get expenseCategoryFine;

  /// §10 log.expense category chip: a car wash.
  ///
  /// In en, this message translates to:
  /// **'Wash'**
  String get expenseCategoryWash;

  /// §10 log.expense category chip: seasonal tyre storage.
  ///
  /// In en, this message translates to:
  /// **'Tyre storage'**
  String get expenseCategoryTyreStorage;

  /// §10 log.expense category chip: an accessory. Singular — the chip names one purchase.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get expenseCategoryAccessories;

  /// §10 log.expense category chip: a finance or lease payment.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get expenseCategoryFinance;

  /// §10 log.expense category chip: anything else. Requires a name in the label field.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCategoryOther;

  /// The logExpenseCategoryLabel label on log.expense. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get logExpenseCategoryLabel;

  /// Shown when Save is pressed with no category chosen. Category comes FIRST on this form because it is the only field that changes the rest of it.
  ///
  /// In en, this message translates to:
  /// **'Pick what this was for.'**
  String get logExpenseCategoryError;

  /// The field that appears under the chips when Other is picked, and takes focus. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'What was it?'**
  String get logExpenseNameLabel;

  /// Required for the Other category only — `expenses` has a CHECK that refuses a custom expense with no label.
  ///
  /// In en, this message translates to:
  /// **'Give this expense a name.'**
  String get logExpenseNameError;

  /// The logExpenseAmountLabel label on log.expense. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get logExpenseAmountLabel;

  /// Shown for an empty amount. Zero IS allowed: a warranty job and a comped wash both really cost nothing, and refusing 0 would make the user lie.
  ///
  /// In en, this message translates to:
  /// **'Enter what you paid.'**
  String get logExpenseAmountError;

  /// The switch that flips the stored sign. SPEC.md §10 uses a switch and not a minus key: a minus on a numeric pad is inconsistent across platforms and reverses badly in RTL, while a switch reads the same in six languages.
  ///
  /// In en, this message translates to:
  /// **'This is a refund'**
  String get logExpenseRefundLabel;

  /// The logExpenseDatePaidLabel label on log.expense. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'Date paid'**
  String get logExpenseDatePaidLabel;

  /// The switch that reveals a coverage window. On by default for Insurance and Road tax. There is no recurrence engine anywhere: one payment is one row with a window, which the cost views spread — twelve generated rows would be twelve rows to maintain, edit and delete.
  ///
  /// In en, this message translates to:
  /// **'Covers a period'**
  String get logExpenseCoversLabel;

  /// The logExpenseCoversFrom label on log.expense. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get logExpenseCoversFrom;

  /// The logExpenseCoversTo label on log.expense. SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get logExpenseCoversTo;

  /// Shown under To. The only ordering rule on this form; a FUTURE date is allowed, because prepaid insurance is real.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date.'**
  String get logExpenseCoversError;

  /// §10's logFillUpQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get logFillUpQuantityLabel;

  /// The middle field of §10's price trio. The UNIT is interpolated because it changes with the fuel kind — litres, kilograms or kilowatt-hours — and a translator must be able to move it.
  ///
  /// In en, this message translates to:
  /// **'Price/{unit}'**
  String logFillUpPricePerUnitLabel(String unit);

  /// §10's logFillUpTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get logFillUpTotalLabel;

  /// §10's logFillUpFullTank.
  ///
  /// In en, this message translates to:
  /// **'Filled it up'**
  String get logFillUpFullTank;

  /// §10's logFillUpPartFill.
  ///
  /// In en, this message translates to:
  /// **'Part fill'**
  String get logFillUpPartFill;

  /// §10's over-capacity warning. Amber, never a refusal: the app does not know the tank was replaced, and refusing would lose a real fill-up to a spec sheet.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than your tank holds. Saving it as entered.'**
  String get logFillUpOverTankWarning;

  /// Shown when Part fill is chosen. §10 uses a two-option segmented control and not a checkbox: 'Not a full tank' as a negative checkbox is misread by a meaningful fraction of people, and this flag decides whether a consumption figure exists at all.
  ///
  /// In en, this message translates to:
  /// **'Part fills don\'t produce a figure on their own. This one gets added to your next full tank.'**
  String get logFillUpPartFillHint;

  /// Shown when fewer than two of the three money/volume fields carry a value.
  ///
  /// In en, this message translates to:
  /// **'Enter how much fuel you put in, and either the price per litre or the total.'**
  String get logFillUpTrioError;

  /// §10's logFillUpQuantityError.
  ///
  /// In en, this message translates to:
  /// **'Fuel must be more than zero.'**
  String get logFillUpQuantityError;

  /// §10's logFillUpPriceError.
  ///
  /// In en, this message translates to:
  /// **'Price can\'t be negative.'**
  String get logFillUpPriceError;

  /// A negative total is refused; a zero one is not — a free fill-up is a real thing. [zero] is a PLACEHOLDER and not the digit, because a baked Latin 0 would sit in a sentence an fa or ckb user reads in Extended Arabic-Indic digits. The RTL translators spelled the word out to avoid exactly this; a placeholder lets every locale render its own numeral instead.
  ///
  /// In en, this message translates to:
  /// **'Total can\'t be negative. A free fill-up is {zero}.'**
  String logFillUpTotalError(String zero);

  /// One line above the form on a vehicle's first fill-up. SPEC.md §10: 'No empty chart, no zero, no placeholder.'
  ///
  /// In en, this message translates to:
  /// **'Your first consumption figure arrives at your next full fill-up.'**
  String get logFillUpFirstEver;

  /// §10's logServiceWhatWasDone.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get logServiceWhatWasDone;

  /// The caption under the item chips. It states what ticking DOES, because the consequence of a tick is a reminder resetting and that is invisible otherwise.
  ///
  /// In en, this message translates to:
  /// **'Ticking an item resets its reminder.'**
  String get logServiceTickResets;

  /// §10's logServiceOther.
  ///
  /// In en, this message translates to:
  /// **'+ Other'**
  String get logServiceOther;

  /// §10's logServiceCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get logServiceCostLabel;

  /// §10's logServiceSplit.
  ///
  /// In en, this message translates to:
  /// **'Split the cost by item'**
  String get logServiceSplit;

  /// A negative cost is refused; zero is not — a warranty job really did cost nothing. See logFillUpTotalError for why [zero] is a placeholder.
  ///
  /// In en, this message translates to:
  /// **'Cost can\'t be negative. A warranty job is {zero}.'**
  String logServiceCostError(String zero);

  /// Shown for an empty cost. See logFillUpTotalError for why [zero] is a placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter what it cost, or {zero}.'**
  String logServiceCostEmptyError(String zero);

  /// The label a service line takes when several items are ticked or none is. SPEC.md §10's cost model: un-split, the record is one line, and splitting one invoice across the ticked items would be inventing a breakdown the user did not give.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get logServiceGenericLine;

  /// The collapsed section every log form carries. SPEC.md §10: 'More is collapsed by default and collapsed again next time: nothing inside it changes a consumption figure.' The artboard draws it as a nav row with a summary of what is inside rather than an inline disclosure.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get logMoreRow;

  /// What is behind More on log.fillup, listed on the row itself so the section can be skipped without opening it.
  ///
  /// In en, this message translates to:
  /// **'Station · Grade · Trip'**
  String get logMoreFillUpSummary;

  /// What is behind More on log.service. THREE items at most: the value is end-aligned beside the row's title and has no room to wrap, and four overflowed a compact row at 390pt. German and French carry two, because their words are longer and a truncated summary is worse than a shorter honest one.
  ///
  /// In en, this message translates to:
  /// **'Workshop · Invoice · Notes'**
  String get logMoreServiceSummary;

  /// What is behind More on log.expense. See logMoreServiceSummary for the length rule.
  ///
  /// In en, this message translates to:
  /// **'Paid to · Trip · Notes'**
  String get logMoreExpenseSummary;

  /// §10's logFillUpStation label.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get logFillUpStation;

  /// §10's logFillUpGrade label.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get logFillUpGrade;

  /// The checkbox under More. It sits there because it is rare and because ticking it DISCARDS a fuel segment — SPEC.md §10.
  ///
  /// In en, this message translates to:
  /// **'I missed logging a fill-up before this'**
  String get logFillUpChainBroken;

  /// Shown when the chain-broken box is ticked. It states the consequence, because a discarded segment is invisible otherwise.
  ///
  /// In en, this message translates to:
  /// **'Your consumption figures start fresh from this fill-up.'**
  String get logFillUpChainBrokenHint;

  /// §10's logServiceWorkshop label.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get logServiceWorkshop;

  /// Forced LTR, start-aligned and never digit-shaped — SPEC.md §10: 'an identifier, not a quantity'.
  ///
  /// In en, this message translates to:
  /// **'Invoice no.'**
  String get logServiceInvoice;

  /// §10's logNotes label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get logNotes;

  /// §10's logExpensePaidTo label.
  ///
  /// In en, this message translates to:
  /// **'Paid to'**
  String get logExpensePaidTo;

  /// The confirmation panel's headline after a mark-done save. SPEC.md §10 replaces the body for five seconds rather than showing a snackbar, because both the resulting due date AND the due odometer have to be visible — the consequence of finishing 3,000 km early is what a user needs to see once.
  ///
  /// In en, this message translates to:
  /// **'{item} done'**
  String logDoneTitle(String item);

  /// The next-due pair. Both halves, because seeing only one hides the consequence the panel exists to show.
  ///
  /// In en, this message translates to:
  /// **'Next due at {odometer} or {date} — whichever comes first'**
  String logDoneNextBoth(String odometer, String date);

  /// The next-due line for a distance-only item. §10: 'A distance-only or time-only item names one axis' — inventing the other would be a fact the app made up.
  ///
  /// In en, this message translates to:
  /// **'Next due at {odometer}'**
  String logDoneNextDistance(String odometer);

  /// The next-due line for a time-only item. [date] arrives already fuzzy ('around September 2027') when the projection's confidence is not measured.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String logDoneNextDate(String date);

  /// §10's logDoneClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get logDoneClose;

  /// SPEC.md §11's mid-chain fill-up delete body. `segment` is the already-formatted date range of the segment that will be recomputed — a range, not a number, because the user recognises the two dates and would not recognise a segment id.
  ///
  /// In en, this message translates to:
  /// **'Delete this fill-up? The consumption figure for {segment} will be recalculated.'**
  String deleteFillUpRecalculated(String segment);

  /// SPEC.md §11's chain-OPENING fill-up delete body. "Removed", never "recalculated": deleting the fill that opens a chain produces no number rather than a different one, and a user told a figure will be recalculated goes looking for the new one. `nText` is the count pre-shaped in the locale's numerals.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Delete this fill-up? {nText} consumption figure will be removed.} other{Delete this fill-up? {nText} consumption figures will be removed.}}'**
  String deleteFillUpFiguresRemoved(int n, String nText);

  /// The fill-up delete body when nothing derived hangs off it. SPEC.md §2: never state a consequence that will not happen.
  ///
  /// In en, this message translates to:
  /// **'Delete this fill-up?'**
  String get deleteFillUpPlain;

  /// SPEC.md §11's service delete body. `items` is the already-joined list of reminder names the record reset — joined by the caller so the list separator is the locale's, not a hard-coded comma.
  ///
  /// In en, this message translates to:
  /// **'Delete this service? {items} will go back to being due from the job before this one.'**
  String deleteServiceResets(String items);

  /// The service delete body when the record reset no reminders.
  ///
  /// In en, this message translates to:
  /// **'Delete this service?'**
  String get deleteServicePlain;

  /// SPEC.md §11: "Costs are never deleted as a side effect of deleting the thing they were grouped under." The sentence exists to stop someone cancelling a trip deletion because they believe it takes the receipts with it. `nText` is the count pre-shaped in the locale's numerals.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Delete this trip? Its {nText} expense stays — it will just stop being attached to a trip.} other{Delete this trip? Its {nText} expenses stay — they will just stop being attached to a trip.}}'**
  String deleteTripKeepsCosts(int n, String nText);

  /// The trip delete body when no expenses are attached to it.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get deleteTripPlain;

  /// SPEC.md §11's standalone odometer reading delete body.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading?'**
  String get deleteReadingPlain;

  /// The expense delete body. An expense has no derived consequence of its own.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get deleteExpensePlain;

  /// SPEC.md §11: deleting the vehicle's only odometer reading is blocked OUTRIGHT — a refusal with no Delete button, not a confirmation with a scarier body. `vehicle` is the vehicle's name.
  ///
  /// In en, this message translates to:
  /// **'This is the only odometer reading for the {vehicle}. Every car needs one.'**
  String deleteBlockedOnlyReading(String vehicle);

  /// SPEC.md §11: a reading that is the `from_reading_id` of a correction blocks both delete and odometer edit. `date` is the correction's start date, already formatted in the display calendar.
  ///
  /// In en, this message translates to:
  /// **'This reading starts an odometer correction from {date}. Delete the correction first.'**
  String deleteBlockedStartsCorrection(String date);

  /// The separator between all but the last two items of a list — Arabic, Persian and Sorani use U+060C, not a Latin comma. A key rather than a Dart constant because a translator can change it and a `', '` in a switch cannot be found by one.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// Joins the last item of a list to everything before it: "Oil and filter and Inspection". SPEC.md §2 forbids assembling a sentence in Dart — the conjunction, the spacing and the ORDER are all the translator's, and Arabic in particular attaches و to the following word with no space.
  ///
  /// In en, this message translates to:
  /// **'{head} and {last}'**
  String listPairJoin(String head, String last);

  /// SPEC.md §12: the `report.service` screen title and the document heading. German is `Serviceverlauf`, which §12 names as the wrap case for the toggle row.
  ///
  /// In en, this message translates to:
  /// **'Service report'**
  String get reportTitle;

  /// Heads §12's four toggles. "In the document", not "in the report": the preview IS the document, and the wording is what tells the user the chips change what a buyer will see.
  ///
  /// In en, this message translates to:
  /// **'Include in the document'**
  String get reportIncludeHeading;

  /// §12's Costs toggle, on by default.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get reportToggleCosts;

  /// §12's fuel-consumption summary toggle, on by default.
  ///
  /// In en, this message translates to:
  /// **'Fuel summary'**
  String get reportToggleFuel;

  /// §12's plate-and-VIN toggle, OFF by default — "the identity fields are the buyer's to ask for, not the app's to leak into a group chat". German is `Kennzeichen und Fahrgestellnummer`, which §12 names as the two-line wrap case.
  ///
  /// In en, this message translates to:
  /// **'Plate and VIN'**
  String get reportTogglePlateVin;

  /// §12's private-notes toggle, OFF by default.
  ///
  /// In en, this message translates to:
  /// **'My private notes'**
  String get reportToggleNotes;

  /// SPEC.md §12's warning under the notes toggle: notes "say things like 'cheaper than the dealer wanted'". It is shown whether or not the toggle is on, because the point is to be read BEFORE it is turned on.
  ///
  /// In en, this message translates to:
  /// **'Your notes may say things you don’t want a buyer to read.'**
  String get reportNotesWarning;

  /// §12's primary action. The file goes to the OS share sheet; the app never picks a destination.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get reportSharePdf;

  /// §12's overflow item: the same content as plain text, "for pasting into a classifieds listing, which is how cars are actually sold on Divar, Willhaben, Leboncoin and Marketplace".
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get reportCopyAsText;

  /// §12's other overflow item. A4 everywhere except US, CA, MX and PH; this overrides the resolved region.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get reportPaperSize;

  /// §12's no-records state. The header card still renders; only the preview is replaced.
  ///
  /// In en, this message translates to:
  /// **'No services logged yet'**
  String get reportEmptyTitle;

  /// §12's no-records body, verbatim in shape: the report "gets valuable the moment you start adding them". Not an apology — one documented cambelt change is worth printing.
  ///
  /// In en, this message translates to:
  /// **'This report gets valuable the moment you start adding them.'**
  String get reportEmptyBody;

  /// Shown UNDER the disabled Share PDF button, never in a toast. SPEC.md §2: Save is never disabled without an explanation, and §12 says the reason goes under the button because "the user is already stressed".
  ///
  /// In en, this message translates to:
  /// **'There are no services to put in a report yet.'**
  String get reportShareDisabledReason;

  /// §12's ownership span for a vehicle still owned. `date` is the purchase date, already formatted in the display calendar — the span reads open-ended rather than ending at today's date, because a document printed in September and read in November must not claim the span ended in September.
  ///
  /// In en, this message translates to:
  /// **'Owned since {date}'**
  String reportOwnedSince(String date);

  /// SPEC.md §12's UNREMOVABLE footer. `date` is the display-calendar date and `iso` the Gregorian one in brackets — §12 requires both: a Jalali date alone is unreadable to the buyer's insurer, an ISO date alone to the seller.
  ///
  /// In en, this message translates to:
  /// **'Generated by Odova on {date} ({iso}) from records kept by the owner. Not verified by a third party.'**
  String reportGeneratedFooter(String date, String iso);

  /// SPEC.md §12's single footnote for records whose odometer was estimated at the time. One per document, not one per row: "hiding that in a document handed to a buyer is a small lie the app has no business telling."
  ///
  /// In en, this message translates to:
  /// **'~ odometer estimated at the time, not read from the car.'**
  String get reportEstimatedFootnote;

  /// Heads §12's list of tracked items with no completion. They are listed explicitly "because an absent row reads as a hidden row" — a buyer cannot tell a timing belt never done from one the seller removed.
  ///
  /// In en, this message translates to:
  /// **'No record in this app'**
  String get reportNoRecordHeading;

  /// SPEC.md §12's header count — "34 services". `nText` is the count pre-shaped in the locale's numerals; gen-l10n renders a bare int in Latin digits, which is wrong in four of the six shipped locales.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} service} other{{nText} services}}'**
  String reportServiceCount(int n, String nText);

  /// SPEC.md §12's ownership duration, as the reference draws it: "8 yr 6 mo". Both parts are pre-shaped Strings for the same reason. Abbreviated because it sits at the end edge of a header row beside a distance, and the full words wrap there in German.
  ///
  /// In en, this message translates to:
  /// **'{years} yr {months} mo'**
  String reportOwnershipSpan(String years, String months);

  /// SPEC.md §12's record row carries the invoice reference. It is the one field on the row a buyer can take to the workshop and verify, which is why it is labelled rather than printed bare. `ref` is the reference verbatim as typed — never digit-shaped, because it is an identifier and not a quantity.
  ///
  /// In en, this message translates to:
  /// **'Invoice {ref}'**
  String reportInvoiceRef(String ref);

  /// SPEC.md §12's header span: the odometer at purchase and the latest ENTERED reading.
  ///
  /// The separator is an EN DASH, not the arrow the reference draws. The reference is Chrome and falls back to a system face; the app bundles Vazirmatn and Inter and neither carries U+2192 or U+2190 — `font_coverage_test.dart` refused the arrow the moment it was put here, which is what moving it out of Dart and into an ARB was for. SPEC.md §2 forbids fetching a font, so the choice is a dash or a tofu box on a document handed to a buyer. Recorded as a deviation for EPIC-17/18: either the bundled face gains the glyph or the reference set loses the arrow.
  ///
  /// It is in a message rather than in a widget for a second reason too: it mirrors. An en dash between two numbers is direction-neutral, and the message is where a translator could change that if a locale needed it.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String reportOdometerSpan(String from, String to);

  /// SPEC.md §12's PDF table heading. It REPEATS on every page — a reader who turns to page four otherwise sees four columns of numbers with nothing saying which is which.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportColumnDate;

  /// §12's PDF table heading for the odometer column.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get reportColumnOdometer;

  /// §12's PDF table heading. The column holds free text and takes direction from its own content — a German workshop name inside a Persian document renders LTR inside an RTL cell.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get reportColumnWork;

  /// §12's PDF table heading for the cost column. Absent from the document entirely when the Costs toggle is off.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get reportColumnCost;

  /// SPEC.md §12: "Page 2 of 4 in the footer." Both numbers are placeholders because the word order differs — Persian puts the total last, and a string built as '{n} / {total}' in Dart could not be reordered.
  ///
  /// In en, this message translates to:
  /// **'Page {n} of {total}'**
  String reportPageOf(String n, String total);

  /// The ownership-span label in the plain-text export, where there is no room for the full sentence the screen uses.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get reportOwnedLabel;

  /// The word after the service count in the plain-text export. Not a plural key: the count beside it is already shaped by `reportServiceCount` on the screen, and the text export writes the bare number.
  ///
  /// In en, this message translates to:
  /// **'services'**
  String get reportServicesLabel;

  /// SPEC.md §12's tab-3 title.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get costsTitle;

  /// §12's range chip, HIDDEN during January — there is no completed month of this year yet.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get costsRangeThisYear;

  /// §12's range chip: the month of the vehicle's first record onwards.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get costsRangeAll;

  /// The unit under §12's headline figure. A separate key from the figure so the number can be shaped and isolated independently of the word.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get costsPerMonth;

  /// Heads §12's category list.
  ///
  /// In en, this message translates to:
  /// **'Where the money goes'**
  String get costsWhereMoneyGoes;

  /// SPEC.md §12: "One line under the headline says so." Costs are accrual and History is cash — without this sentence a yearly premium appears to have vanished from the month it was paid.
  ///
  /// In en, this message translates to:
  /// **'Yearly costs like insurance are spread over the months they cover.'**
  String get costsAccrualNote;

  /// §12 reports the current month SEPARATELY, because it is out of the numerator and the denominator alike: "an average including a two-day-old month halves itself on the 2nd of every month." `amount` is pre-formatted money.
  ///
  /// In en, this message translates to:
  /// **'This month so far: {amount}'**
  String costsThisMonthSoFar(String amount);

  /// §12's first-run state for tab 3.
  ///
  /// In en, this message translates to:
  /// **'No costs yet.'**
  String get costsEmptyTitle;

  /// The action beside it. It opens the log sheet rather than a specific form: on first run the app does not know which kind of record the user has.
  ///
  /// In en, this message translates to:
  /// **'Log something'**
  String get costsEmptyAction;

  /// §12's category row. Sources: FillUp.total_cost.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get costsCategoryFuel;

  /// §12's category row. Sources: ServiceLine.amount.
  ///
  /// In en, this message translates to:
  /// **'Service & repairs'**
  String get costsCategoryService;

  /// §12's category row. Sources: the `insurance` and `tax_registration` expense categories.
  ///
  /// In en, this message translates to:
  /// **'Insurance & tax'**
  String get costsCategoryInsuranceTax;

  /// §12's category row. Source: the `finance` expense category.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get costsCategoryFinance;

  /// §12's category row. Sources: `parking` and `toll`.
  ///
  /// In en, this message translates to:
  /// **'Parking & tolls'**
  String get costsCategoryParkingTolls;

  /// §12's category row. Sources: `fine`, `wash`, `tyre_storage`, `accessories`, `other`. Everything §12 does not give a row of its own.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get costsCategoryOther;

  /// The row that pushes `costs.fuel`.
  ///
  /// In en, this message translates to:
  /// **'Fuel & consumption'**
  String get costsFuelRow;

  /// The row that pushes `trips.list`.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get costsTripsRow;

  /// SPEC.md §12's explanation when `completedMonths` < 1. It carries NO action — there is nothing the user can do but wait, and offering a button would imply otherwise.
  ///
  /// In en, this message translates to:
  /// **'Come back after the end of the month — there isn’t a full month to average yet.'**
  String get costsNoCompletedMonth;

  /// SPEC.md §12's explanation when the range covers less than 100 km. Paired with **Update odometer**, because that IS the thing the user can do.
  ///
  /// In en, this message translates to:
  /// **'Not enough distance logged in this period to work out a cost per kilometre.'**
  String get costsNotEnoughDistance;

  /// SPEC.md §12's explanation for an estimated cost per distance. `days` is the gap pre-shaped in the locale's numerals — the figure is real and quoted back so the user can judge it.
  ///
  /// In en, this message translates to:
  /// **'Worked out from odometer readings {days} days apart from the dates shown.'**
  String costsBoundaryStale(String days);

  /// The sheet's one action → `log.odometer`.
  ///
  /// In en, this message translates to:
  /// **'Update odometer'**
  String get costsUpdateOdometer;

  /// SPEC.md §12's range chips, which are 3 and 12. The count is a PLACEHOLDER and not baked into the copy: `arb_template_test.dart` refuses a bare digit because a Latin "3" does not shape to Persian, Arabic or Sorani numerals, and the chip would read `3 ماه` on a screen where every other number is `۳`.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} month} other{{nText} months}}'**
  String costsRangeMonths(int n, String nText);

  /// The line above §12's headline figure: the vehicle and which window the figure covers. Two placeholders rather than one sentence, because the vehicle name is the user's own text and must not be part of anything a translator reorders around it.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} · {range}'**
  String costsHeadlineCaption(String vehicle, String range);

  /// The range's name in the headline caption, lower-case because it follows the vehicle name mid-phrase. Distinct from the CHIP label, which is a control and capitalised.
  ///
  /// In en, this message translates to:
  /// **'this year so far'**
  String get costsRangeThisYearSoFar;

  /// The month span beside "Where the money goes" — `January – August`. An EN DASH with spaces, and both ends are pre-formatted month names so the display calendar decides them.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String costsSpanCaption(String from, String to);

  /// SPEC.md §12's cost-per-distance figure, WITH its unit spelled out. `€0.29` alone is ambiguous beside a per-month figure on the same line; the reference writes it in full.
  ///
  /// In en, this message translates to:
  /// **'{amount} per kilometre'**
  String costsPerKilometre(String amount);

  /// The same for a miles vehicle. A separate key rather than a placeholder unit, because the preposition and word order differ by locale and a translator must be able to reorder both.
  ///
  /// In en, this message translates to:
  /// **'{amount} per mile'**
  String costsPerMile(String amount);

  /// SPEC.md §12's range total: `€2,184 in eight months`. The count is a plural placeholder — a bare digit would render Latin in four locales, and the month word inflects.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{amount} in {nText} month} other{{amount} in {nText} months}}'**
  String costsInMonths(int n, String nText, String amount);

  /// SPEC.md §12's household toggle, shown only with two or more non-archived vehicles. It changes what tab 3 SHOWS and never the active vehicle — §7's app-wide scope has exactly one exception and it is scoped to this tab.
  ///
  /// In en, this message translates to:
  /// **'All vehicles'**
  String get costsAllVehicles;

  /// §12's second toggle, OFF by default. A sold car's costs are real history, but a household average that silently included a car nobody drives any more would be wrong in the direction of looking cheap.
  ///
  /// In en, this message translates to:
  /// **'Include sold and archived'**
  String get costsIncludeInactive;

  /// §12's trailing line when vehicles are excluded. A hidden vehicle the user is not told about is a household total they cannot reconcile against the list above it.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} vehicle hidden} other{{nText} vehicles hidden}}'**
  String costsHiddenVehicles(int n, String nText);

  /// SPEC.md §12's business split: `Business 62% · 1,391 €`. Both parts are pre-shaped — a bare int renders Latin digits in four locales, and the amount is money.
  ///
  /// In en, this message translates to:
  /// **'Business {share}% · {amount}'**
  String costsBusinessRow(String share, String amount);

  /// SPEC.md §12's caption under the business row, verbatim in intent. The denominator is LOGGED TRIP distance and not vehicle distance, and this sentence is what stops a user reading the figure as a claim about all their driving — which on a tax form matters.
  ///
  /// In en, this message translates to:
  /// **'Worked out from the trips you logged, not from all your driving.'**
  String get costsBusinessCaption;

  /// The status label on a household row for a sold vehicle, so a row is never mistaken for a live car.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get costsVehicleSold;

  /// The same for an archived one.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get costsVehicleArchived;

  /// SPEC.md §12's `costs.fuel` title.
  ///
  /// In en, this message translates to:
  /// **'Fuel & consumption'**
  String get fuelTitle;

  /// Heads §12's consumption chart. PER TANK, not over time: a segment is a discrete measurement between two full fills, at irregular intervals.
  ///
  /// In en, this message translates to:
  /// **'Consumption per tank'**
  String get fuelConsumptionPerTank;

  /// §12's empty state for `costs.fuel`.
  ///
  /// In en, this message translates to:
  /// **'No fill-ups yet.'**
  String get fuelEmptyTitle;

  /// The action beside it — straight to `log.fillup`, because on this screen there is only one kind of record worth adding.
  ///
  /// In en, this message translates to:
  /// **'Log a fill-up'**
  String get fuelEmptyAction;

  /// SPEC.md §3: "your first figure arrives at your next full fill." Shown where the consumption chart would be with fewer than two full tanks — it explains an absence that would otherwise look like a fault.
  ///
  /// In en, this message translates to:
  /// **'Your first figure arrives at your next full fill.'**
  String get fuelFirstFigure;

  /// SPEC.md §12's `trips.list` title.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsTitle;

  /// §12's empty state.
  ///
  /// In en, this message translates to:
  /// **'No trips yet.'**
  String get tripsEmptyTitle;

  /// The sentence under it, verbatim in intent: a trip is worth logging because it tells you what a journey COST, which is the only reason this screen exists.
  ///
  /// In en, this message translates to:
  /// **'Log one to see what a journey costs.'**
  String get tripsEmptyBody;

  /// Opens `trips.edit`.
  ///
  /// In en, this message translates to:
  /// **'Add trip'**
  String get tripsAddAction;

  /// The chip on a trip with no `ended_on`. §12 pins an open trip at the top of the list — an unfinished trip is the one thing on this screen that needs an action.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tripsOpenBadge;

  /// The action on an open trip. `End this trip` and not `Finish`: SPEC.md §12's prose says Finish, the reference draws `End this trip`, and per epics/README.md rule 4 the reference is the authority. §10 spells it the same way, so the two screens agree.
  ///
  /// In en, this message translates to:
  /// **'End this trip'**
  String get tripsFinishAction;

  /// §10's trip purpose. Kept apart from `commute` deliberately: rolling them together is the easiest way to overstate a deduction, and in most jurisdictions the drive to a regular workplace is not deductible.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get tripsPurposeBusiness;

  /// §10's trip purpose — the drive to a regular workplace, which is NOT business.
  ///
  /// In en, this message translates to:
  /// **'Commute'**
  String get tripsPurposeCommute;

  /// §10's trip purpose.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get tripsPurposePersonal;

  /// §10's trip purpose.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tripsPurposeOther;

  /// The distance tile's label. `km logged`, not `km`: §12 insists the figure says `across logged trips`, because trip distance is NOT the car's distance — people log some trips and not all. Without the second word the tile reads as total mileage.
  ///
  /// In en, this message translates to:
  /// **'{unit} logged'**
  String tripsLoggedLabel(String unit);

  /// The business-share tile's label. Lower case: it sits under a figure, not at the head of a sentence.
  ///
  /// In en, this message translates to:
  /// **'business'**
  String get tripsBusinessLabel;

  /// The cost tile's label.
  ///
  /// In en, this message translates to:
  /// **'trip costs'**
  String get tripsCostsLabel;

  /// The section header over the trips that are not open.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get tripsEarlier;

  /// How many trips are in range — SPEC.md §12's fourth header fact, which the reference draws at the end edge of the Earlier header. `nText` is pre-shaped so Persian, Arabic and Sorani get their own digits; `n` selects the category and is never printed.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No trips} one{{nText} trip} other{{nText} trips}}'**
  String tripsCount(int n, String nText);

  /// The open trip's line when its start odometer is known.
  ///
  /// In en, this message translates to:
  /// **'Started {date} · from {odometer}'**
  String tripsStartedFrom(String date, String odometer);

  /// The same line when it is not. A separate message rather than an empty placeholder: `Started today · from ` is worse than saying less.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String tripsStartedOn(String date);

  /// Beside End this trip. Lower case and secondary — it is a statement of fact about the trip, not a warning.
  ///
  /// In en, this message translates to:
  /// **'no end reading yet'**
  String get tripsNoEndReading;

  /// The business tile's figure. The percent SIGN and its spacing are a translation decision — German and French set a space before it, the Arabic-script three do not — so it lives in the ARB rather than in a Dart `'%'`. `percent` is pre-shaped.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String tripsBusinessValue(String percent);

  /// SPEC.md §10's title in edit mode. The reference draws it; §10's Edit-mode row names it.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get tripEditTitle;

  /// The same bar in create mode.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripNewTitle;

  /// The footer button. `Save trip` and not `Save`: the app bar already carries a Save, and two controls a thumb-width apart reading the same word is where a delivery driver loses a trip.
  ///
  /// In en, this message translates to:
  /// **'Save trip'**
  String get tripSaveAction;

  /// The segmented control's accessible name. It has no visible label in the reference — the four options say what it is — but a screen reader landing on four unlabelled segments does not.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get tripPurposeLabel;

  /// Field 2.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tripTitleLabel;

  /// Field 3.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get tripStartsLabel;

  /// Field 4.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get tripEndsLabel;

  /// Field 5's checkbox. Ticking CLEARS the end date and end odometer, per §10.
  ///
  /// In en, this message translates to:
  /// **'Still going'**
  String get tripStillGoing;

  /// Field 6.
  ///
  /// In en, this message translates to:
  /// **'Start odometer'**
  String get tripStartOdometerLabel;

  /// Field 7.
  ///
  /// In en, this message translates to:
  /// **'End odometer'**
  String get tripEndOdometerLabel;

  /// Field 8, computed with the ƒ badge and editable only when BOTH odometer fields are empty.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get tripDistanceLabel;

  /// The section header over the live query. Not a draft: §10 says an expense added through Add expense appears without a save.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tripExpensesLabel;

  /// Opens `log.expense` with `trip_id` prefilled and locked.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get tripAddExpense;

  /// The section's empty line. `yet` because the expenses arrive after the trip does — a toll is paid on the road, not when the trip is created.
  ///
  /// In en, this message translates to:
  /// **'Nothing charged to this trip yet.'**
  String get tripNoExpenses;

  /// Edit mode only. The confirm dialog says what SURVIVES, which is the fact the user needs.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get tripDeleteAction;

  /// Field 3's exact error, verbatim from §10's field table.
  ///
  /// In en, this message translates to:
  /// **'Pick today or a day in the past.'**
  String get tripStartInFuture;

  /// Field 4's exact error, verbatim from §10.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date.'**
  String get tripEndBeforeStart;

  /// Field 7's exact error, verbatim from §10.
  ///
  /// In en, this message translates to:
  /// **'The end reading is lower than the start reading.'**
  String get tripEndBelowStart;

  /// Field 8's exact error, verbatim from §10.
  ///
  /// In en, this message translates to:
  /// **'Distance must be more than zero.'**
  String get tripDistanceNotPositive;

  /// §10's confirmation after saving.
  ///
  /// In en, this message translates to:
  /// **'Trip saved'**
  String get tripSavedToast;

  /// Under Add expense in CREATE mode. §10 draws the affordance there, but an expense carries `trip_id` and there is no trip yet — so the button is disabled and this says why. A greyed-out button that explains nothing is what `CalmButton` asserts against, and dropping the button entirely would hide a control §10 names.
  ///
  /// In en, this message translates to:
  /// **'Save the trip first, then charge expenses to it.'**
  String get tripSaveFirstToAddExpense;

  /// The estimate sheet's title. SPEC.md §12: tapping any estimated or dashed figure opens one sentence and one action.
  ///
  /// In en, this message translates to:
  /// **'How this was worked out'**
  String get costsEstimateTitle;

  /// §12's >45-day case, verbatim. `days` is pre-shaped: a bare int renders Latin digits in four locales. Not a plural — the figure is always above 45 by construction, so `one` is unreachable and a plural would be five translations of a form nobody sees.
  ///
  /// In en, this message translates to:
  /// **'Worked out from odometer readings {days} days apart from the dates shown.'**
  String costsEstimateStaleBoundary(String days);

  /// §12's under-100 km case, verbatim.
  ///
  /// In en, this message translates to:
  /// **'Not enough distance logged in this period to work out a cost per kilometre.'**
  String get costsEstimateNotEnoughDistance;

  /// §12's `completedMonths < 1` case, verbatim — and the one case with NO action, because updating the odometer does not make the month end sooner.
  ///
  /// In en, this message translates to:
  /// **'Come back after the end of the month — there isn’t a full month to average yet.'**
  String get costsEstimateNoCompletedMonth;

  /// The fourth case `CostReason` names. §12's table lists three, and the engine has always had a fourth: no reading at all to measure between, which is a new vehicle rather than a stale one. Offering `Update odometer` here is exactly right.
  ///
  /// In en, this message translates to:
  /// **'There are no odometer readings in this period to measure between.'**
  String get costsEstimateNoReadings;

  /// The sentence under §12's `costs.fuel` empty title. It states the MECHANISM — consumption is measured between two full tanks, so one fill-up is not enough — because a Calm empty state is allowed to explain why the screen is empty rather than only that it is.
  ///
  /// In en, this message translates to:
  /// **'Your first consumption figure arrives at your second full tank.'**
  String get fuelEmptyBody;

  /// SPEC.md §13's tab-4 title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// §13's FIRST row, in its own group, above Vehicles — because the person who needs Export is standing in a phone shop with a dead handset in their pocket. German is the width constraint for the whole screen and this is the string that sets it.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupRow;

  /// §13's never-exported state. Amber text with an amber dot: the only row in the app that changes colour.
  ///
  /// In en, this message translates to:
  /// **'You’ve never made a backup.'**
  String get settingsBackupNever;

  /// The exported state. Both the DATE and the age, as the reference draws it — §13's table shows only the age, and the date is what a user checks against their own memory of when they last did it.
  ///
  /// In en, this message translates to:
  /// **'Last backup {date} — {ago}'**
  String settingsBackupLast(String date, String ago);

  /// §13's migration-failed state. Red, and the app opened on `settings.backup`.
  ///
  /// In en, this message translates to:
  /// **'Odova couldn’t finish updating.'**
  String get settingsBackupMigrationFailed;

  /// Pushes the garage.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get settingsVehiclesRow;

  /// The Vehicles subtitle beyond three, where the reference's list of names stops fitting. `nText` is pre-shaped; a bare int renders Latin digits in four locales.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{nText} vehicle} other{{nText} vehicles}}'**
  String settingsVehicleCount(int n, String nText);

  /// §13's units screen. `Einheiten & Formate` is the second-longest label and wraps rather than truncating.
  ///
  /// In en, this message translates to:
  /// **'Units & formats'**
  String get settingsUnitsRow;

  /// §13's notifications screen.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsRow;

  /// The row's value — `On · 09:00`. Two facts joined, so the ORDER is a translation decision rather than a Dart concatenation.
  ///
  /// In en, this message translates to:
  /// **'{state} · {time}'**
  String settingsNotificationsValue(String state, String time);

  /// The OS permission state, in a word.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotificationsOn;

  /// The same, denied or off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsNotificationsOff;

  /// The section label over the inline three-valued control. §13 keeps it inline because it is one setting with an instantly visible result.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Follows the OS.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Pushes the about screen, with the version as its value.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutRow;

  /// §13's language row. Its VALUE is the language's own name, never translated.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageRow;

  /// The trailing paragraph on `settings.language`. Present in SETTINGS mode only — SPEC.md §8's firstRun variant omits it, because there is no Units screen to point at yet. It exists to stop a user hunting for the numeral setting in the language list, which is where they look first and where it is not.
  ///
  /// In en, this message translates to:
  /// **'Odova is translated into these six. Numbers, dates and units are set separately under Units & formats.'**
  String get settingsLanguageNote;

  /// The label over §13's live preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get unitsPreviewLabel;

  /// The first group's header.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get unitsGroupMeasurement;

  /// The second group's header.
  ///
  /// In en, this message translates to:
  /// **'Dates and numbers'**
  String get unitsGroupDatesNumbers;

  /// Row 1.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get unitsRowDistance;

  /// Row 2.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get unitsRowVolume;

  /// Row 3.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get unitsRowConsumption;

  /// Row 4 — a SHEET, not a push. §7 allows no branch in this app three levels deep.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get unitsRowCurrency;

  /// Row 5.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get unitsRowCalendar;

  /// Row 6.
  ///
  /// In en, this message translates to:
  /// **'Numerals'**
  String get unitsRowNumerals;

  /// Row 7.
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get unitsRowFirstDay;

  /// The distance option, with its abbreviation so the row's value matches what the preview shows.
  ///
  /// In en, this message translates to:
  /// **'Kilometres (km)'**
  String get unitsDistanceKm;

  /// The other one.
  ///
  /// In en, this message translates to:
  /// **'Miles (mi)'**
  String get unitsDistanceMi;

  /// Litres.
  ///
  /// In en, this message translates to:
  /// **'Litres (L)'**
  String get unitsVolumeLitre;

  /// 3.785 L. Named apart from the imperial gallon because they are different UNITS: offering `gal` alone makes a British user's consumption wrong by 17%.
  ///
  /// In en, this message translates to:
  /// **'US gallons'**
  String get unitsVolumeGalUs;

  /// 4.546 L.
  ///
  /// In en, this message translates to:
  /// **'Imperial gallons'**
  String get unitsVolumeGalUk;

  /// The stored calendar, and the display calendar for five of the six locales.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get unitsCalendarGregorian;

  /// Jalali / Solar Hijri. §18 has an open question about whether `ckb-IR` should default to it.
  ///
  /// In en, this message translates to:
  /// **'Jalali'**
  String get unitsCalendarPersian;

  /// The locale's CLDR default.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get unitsNumeralsAuto;

  /// The Latin numerals row. `digits` is a PLACEHOLDER and not a baked `0–9`: `arb_template_test.dart` refuses a digit in copy, correctly — a baked one cannot be shaped — and here the sample is the point of the row, so the screen supplies it already in the right block.
  ///
  /// In en, this message translates to:
  /// **'Latin ({digits})'**
  String unitsNumeralsLatin(String digits);

  /// The locale's own digits, with a sample of them. The sample answers the question the row asks: a Persian user reading `محلی (۰–۹)` can see what they are choosing without applying it first.
  ///
  /// In en, this message translates to:
  /// **'Local ({digits})'**
  String unitsNumeralsLocal(String digits);

  /// Under the consumption row when the app filled it in from the distance and volume pairing. It says WHY, because a value that changed without being touched reads as a bug.
  ///
  /// In en, this message translates to:
  /// **'Suggested for {distance} and {volume}'**
  String unitsConsumptionSuggested(String distance, String volume);

  /// §13's footer, verbatim in intent. Changing the currency rewrites no stored amount and applies no rate — §2 forbids a rate anywhere in this app — and a user about to switch needs to know that before they tap rather than after.
  ///
  /// In en, this message translates to:
  /// **'These change how Odova shows your records. Nothing you’ve already entered is altered.'**
  String get unitsFooter;

  /// Up to three currencies already used in the user's records, above the A–Z list.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get unitsCurrencyRecent;

  /// The A–Z list's header.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get unitsCurrencyAll;

  /// The sheet's search field. Matches on the CODE and on the localised name, so a Persian user can type `يورو`.
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get unitsCurrencySearch;

  /// The mark that joins two facts on one line. In the ARB because WHICH mark is a translation decision — and because a `' · '` literal in Dart is exactly what `check_status_encoding.sh` was written to find. Identical in all six today, and that is a translator's finding rather than an assumption.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get commonSeparator;

  /// The first group's header.
  ///
  /// In en, this message translates to:
  /// **'What Odova sends'**
  String get notifGroupWhat;

  /// The second.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get notifGroupWhen;

  /// The third.
  ///
  /// In en, this message translates to:
  /// **'How far ahead'**
  String get notifGroupHowFar;

  /// The permission chip beside the first group's header, in the granted state.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notifAllowed;

  /// §13's first category. The ARB comment caps these at 22 characters so the switch never pushes the label to two lines.
  ///
  /// In en, this message translates to:
  /// **'Service reminders'**
  String get notifRowService;

  /// The second.
  ///
  /// In en, this message translates to:
  /// **'Odometer check-ins'**
  String get notifRowOdometer;

  /// The third.
  ///
  /// In en, this message translates to:
  /// **'Backup reminders'**
  String get notifRowBackup;

  /// The daily delivery time, stored as local wall-clock minutes and never as an instant.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get notifRowTimeOfDay;

  /// The window notifications are held out of.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifRowQuietHours;

  /// §3's notice window, by distance.
  ///
  /// In en, this message translates to:
  /// **'By distance'**
  String get notifRowByDistance;

  /// And by date.
  ///
  /// In en, this message translates to:
  /// **'By time'**
  String get notifRowByTime;

  /// The computed default for either notice window. Stores NULL — a stored number is a number that stops tracking the item's own interval.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get notifAutomatic;

  /// What Automatic means, under the two rows. `percent` is pre-shaped; a bare int renders Latin digits in four locales.
  ///
  /// In en, this message translates to:
  /// **'Automatic is about {percent}% before it is due.'**
  String notifAutomaticNote(String percent);

  /// §14's delivery cap, stated as a FACT and not offered as a switch. A user who could raise it would, and then blame the app for the noise.
  ///
  /// In en, this message translates to:
  /// **'At most two notifications a week. Never two in one day.'**
  String get notifCapFooter;

  /// The quiet-hours value when the window is empty — `from == to` is not a zero-length window, it is off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifQuietOff;

  /// §13's never-asked card.
  ///
  /// In en, this message translates to:
  /// **'Reminders are off.'**
  String get notifOffTitle;

  /// Its one action; EPIC-16 owns the sheet it presents.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get notifOffAction;

  /// §13's denied card, verbatim. It names WHERE the setting is, because the app cannot change it and the user has to.
  ///
  /// In en, this message translates to:
  /// **'Odova can’t send reminders because notifications are turned off for Odova in your phone’s settings.'**
  String get notifBlockedTitle;

  /// The only remaining door.
  ///
  /// In en, this message translates to:
  /// **'Open phone settings'**
  String get notifBlockedAction;

  /// §14's OEM background-restriction card, shown once after three unconfirmed deliveries.
  ///
  /// In en, this message translates to:
  /// **'Your phone may be stopping Odova’s reminders.'**
  String get notifBackgroundTitle;

  /// Shown when every category is off. It says what still works, because the alternative reading is that the app has stopped doing anything.
  ///
  /// In en, this message translates to:
  /// **'Odova won’t send you anything. What’s due still shows on the home screen.'**
  String get notifSilentFooter;

  /// The `.ics` export. Moves ABOVE the delivery group when notifications are blocked — it is then the only thing on the screen that still delivers anything.
  ///
  /// In en, this message translates to:
  /// **'Add reminders to my calendar'**
  String get notifRowCalendar;

  /// §13's privacy promise, in plain words and one block. A PROMISE, not a legal notice: it is the sentence the store listing claims and §2 makes true by construction, and breaking it into bullets would make it read like terms nobody reads.
  ///
  /// In en, this message translates to:
  /// **'No account. No sign-up. No server. Nothing is uploaded. No tracking, no analytics, no ads.'**
  String get aboutPrivacy;

  /// The sentence a future PR will quietly delete, which is why the test asserts it by name. §1: the user's history is worth money and no server holds a copy — and the honest consequence of that has to be said out loud somewhere.
  ///
  /// In en, this message translates to:
  /// **'Your records live on this phone only. If you lose it without a backup, they are gone.'**
  String get aboutBackupWarning;

  /// Both numbers, and both stay LATIN digits: §13 says a version string is an identifier a support conversation quotes back, not a number.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// From `kSupportedFormatVersion` — the same constant the backup writer writes — so the two can never disagree. The internal `schema_version` is deliberately never shown: a user cannot act on it.
  ///
  /// In en, this message translates to:
  /// **'Backup format {format}'**
  String aboutBackupFormat(String format);

  /// Pushes an OFFLINE text view from a bundled asset. §2 forbids a network call, so there is nothing to link out to.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get aboutLicencesRow;

  /// Miles per US gallon. NAMED apart from the imperial one because they are different units: a US gallon is 3.785 L and an imperial one 4.546 L, so one figure is 17% off the other and a bare `mpg` makes the two unpickable.
  ///
  /// In en, this message translates to:
  /// **'mpg (US)'**
  String get unitConsumptionMpgUs;

  /// Miles per imperial gallon.
  ///
  /// In en, this message translates to:
  /// **'mpg (imp)'**
  String get unitConsumptionMpgUk;

  /// The mark between items in a short list of names. Arabic-script locales use U+060C, not a Latin comma — a Dart `', '` here puts a Western comma into a Persian list, which is the small wrongness a reader notices without being able to name.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get commonListSeparator;
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
