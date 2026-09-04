// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'geschätzt, etwa $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'Odova braucht einen Kilometerstand, um das zu sagen';

  @override
  String get unitDistanceKm => 'km';

  @override
  String get unitDistanceMi => 'mi';

  @override
  String get unitVolumeLitre => 'l';

  @override
  String get unitVolumeGallon => 'gal';

  @override
  String unitConsumptionPerDistance(int n) {
    return 'l/$n km';
  }

  @override
  String get unitConsumptionMpg => 'mpg';

  @override
  String unitPerDistance(String unit) {
    return '/$unit';
  }

  @override
  String get dateToday => 'Heute';

  @override
  String get dateTomorrow => 'Morgen';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $nText Tagen',
      one: 'in $nText Tag',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in etwa $nText Wochen',
      one: 'in etwa $nText Woche',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in etwa $nText Monaten',
      one: 'in etwa $nText Monat',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Tage überfällig',
      one: '$nText Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Erinnerungen fällig',
      one: '$nText Erinnerung fällig',
      zero: 'Nichts fällig',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'Nicht gefunden';

  @override
  String get routeNotFoundBody => 'Dieser Link führt nirgendwohin.';

  @override
  String get routeNotFoundGoHome => 'Zur Startseite';

  @override
  String get tabHome => 'Start';

  @override
  String get tabHistory => 'Verlauf';

  @override
  String get tabCosts => 'Kosten';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get tabLogA11y => 'Erfassen';

  @override
  String get discardTitle => 'Änderungen verwerfen?';

  @override
  String discardBody(String subject, String summary) {
    return 'Deine Änderungen an $subject — $summary — wurden nicht gespeichert.';
  }

  @override
  String get discardKeepEditing => 'Weiter bearbeiten';

  @override
  String get discardDiscard => 'Verwerfen';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seine $countText Einträge',
      one: 'seinen einen Eintrag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$subject und $_temp0 löschen?',
      zero: '$subject löschen?',
    );
    return '$_temp1';
  }

  @override
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
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      fillUps,
      locale: localeName,
      other: '$fillUpsText Tankfüllungen',
      one: '$fillUpsText Tankfüllung',
      zero: 'Keine Tankfüllungen',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText Services',
      one: '$servicesText Service',
      zero: 'keine Services',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText Kostenposten',
      one: '$costsText Kostenposten',
      zero: 'keine Kostenposten',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText Fahrten',
      one: '$tripsText Fahrt',
      zero: 'keine Fahrten',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText Erinnerungen',
      one: '$remindersText Erinnerung',
      zero: 'keine Erinnerungen',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3 und $_temp4 sind endgültig weg.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'Zum Bestätigen $subject eingeben';
  }

  @override
  String get confirmDeleteDelete => 'Löschen';

  @override
  String snoozeTitle(String item) {
    return '$item zurückstellen';
  }

  @override
  String get snoozeBody =>
      'Das macht nur die Erinnerung still. Der Fälligkeitstermin ändert sich nicht.';

  @override
  String snoozeThreeDays(String count) {
    return '$count Tage';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count Woche';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count Monat';
  }

  @override
  String snoozeDistance(String distance) {
    return 'Nach weiteren $distance';
  }

  @override
  String snoozeUntil(String date) {
    return 'bis $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'bei $odometer';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonRestoreBackup => 'Backup wiederherstellen';

  @override
  String settingsLanguageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'Odova ist noch nicht in die Sprache Ihres Geräts übersetzt. Zahlen, Datumsangaben, Einheiten und Beträge richten sich weiterhin nach Ihrer Region.';

  @override
  String get firstRunLanguageTagline =>
      'Wählen Sie die, die Sie am besten lesen.';

  @override
  String get firstRunRestorePrompt => 'Wechseln Sie von einem anderen Telefon?';
}
