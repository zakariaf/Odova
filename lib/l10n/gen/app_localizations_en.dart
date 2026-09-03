// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'estimated, about $value';
  }

  @override
  String get homeDueSoonNoConfidence => 'Odova needs a reading to say when';

  @override
  String get unitDistanceKm => 'km';

  @override
  String get unitDistanceMi => 'mi';

  @override
  String get unitVolumeLitre => 'L';

  @override
  String get unitVolumeGallon => 'gal';

  @override
  String unitConsumptionPerDistance(int n) {
    return 'L/$n km';
  }

  @override
  String get unitConsumptionMpg => 'mpg';

  @override
  String unitPerDistance(String unit) {
    return '/$unit';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'in $n day',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $n weeks',
      one: 'in about $n week',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $n months',
      one: 'in about $n month',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days overdue',
      one: '$n day overdue',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reminders due',
      one: '$n reminder due',
      zero: 'Nothing due',
    );
    return '$_temp0';
  }
}
