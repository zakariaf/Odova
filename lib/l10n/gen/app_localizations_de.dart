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
}
