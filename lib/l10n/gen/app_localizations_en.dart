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
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $nText days',
      one: 'in $nText day',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $nText weeks',
      one: 'in about $nText week',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $nText months',
      one: 'in about $nText month',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText days overdue',
      one: '$nText day overdue',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText reminders due',
      one: '$nText reminder due',
      zero: 'Nothing due',
    );
    return '$_temp0';
  }
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get appTitle => '[Ǿḍǿṽá ǃǃ]';

  @override
  String commonEstimatedA11y(String value) {
    return '[ḗŝţīḿáţḗḍ, áḅǿǔţ $value ǃǃǃǃǃǃǃǃǃǃ]';
  }

  @override
  String get homeDueSoonNoConfidence =>
      '[Ǿḍǿṽá ǹḗḗḍŝ á řḗáḍīǹḡ ţǿ ŝáẏ ẇħḗǹ ǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';

  @override
  String get unitDistanceKm => '[ķḿ ǃ]';

  @override
  String get unitDistanceMi => '[ḿī ǃ]';

  @override
  String get unitVolumeLitre => '[Ŀ ǃ]';

  @override
  String get unitVolumeGallon => '[ḡáŀ ǃǃ]';

  @override
  String unitConsumptionPerDistance(int n) {
    return '[Ŀ/$n ķḿ ǃǃǃǃ]';
  }

  @override
  String get unitConsumptionMpg => '[ḿƥḡ ǃǃ]';

  @override
  String unitPerDistance(String unit) {
    return '[/$unit ǃǃǃ]';
  }

  @override
  String get dateToday => '[Ţǿḍáẏ ǃǃ]';

  @override
  String get dateTomorrow => '[Ţǿḿǿřřǿẇ ǃǃǃǃ]';

  @override
  String get dateYesterday => '[Ẏḗŝţḗřḍáẏ ǃǃǃǃ]';

  @override
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'īǹ $nText ḍáẏŝ',
      one: 'īǹ $nText ḍáẏ',
    );
    return '[$_temp0 ǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'īǹ áḅǿǔţ $nText ẇḗḗķŝ',
      one: 'īǹ áḅǿǔţ $nText ẇḗḗķ',
    );
    return '[$_temp0 ǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'īǹ áḅǿǔţ $nText ḿǿǹţħŝ',
      one: 'īǹ áḅǿǔţ $nText ḿǿǹţħ',
    );
    return '[$_temp0 ǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ḍáẏŝ ǿṽḗřḍǔḗ',
      one: '$nText ḍáẏ ǿṽḗřḍǔḗ',
    );
    return '[$_temp0 ǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText řḗḿīǹḍḗřŝ ḍǔḗ',
      one: '$nText řḗḿīǹḍḗř ḍǔḗ',
      zero: 'Ǹǿţħīǹḡ ḍǔḗ',
    );
    return '[$_temp0 ǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃǃ]';
  }
}
