// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'estimé, environ $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'Odova a besoin d’un relevé pour le dire';

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
  String get dateToday => 'Aujourd’hui';

  @override
  String get dateTomorrow => 'Demain';

  @override
  String get dateYesterday => 'Hier';

  @override
  String dateInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans $n jours',
      many: 'dans $n jours',
      one: 'dans $n jour',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans environ $n semaines',
      many: 'dans environ $n semaines',
      one: 'dans environ $n semaine',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans environ $n mois',
      many: 'dans environ $n mois',
      one: 'dans environ $n mois',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'en retard de $n jours',
      many: 'en retard de $n jours',
      one: 'en retard de $n jour',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rappels à échéance',
      many: '$n rappels à échéance',
      one: '$n rappel à échéance',
      zero: 'Rien à faire',
    );
    return '$_temp0';
  }
}
