// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'تخمینی، حدود $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'اودووا برای گفتن زمان، به عدد کیلومترشمار نیاز دارد';

  @override
  String get unitDistanceKm => 'کیلومتر';

  @override
  String get unitDistanceMi => 'مایل';

  @override
  String get unitVolumeLitre => 'لیتر';

  @override
  String get unitVolumeGallon => 'گالن';

  @override
  String unitConsumptionPerDistance(int n) {
    return 'ل/$n کم';
  }

  @override
  String get unitConsumptionMpg => 'مایل بر گالن';

  @override
  String unitPerDistance(String unit) {
    return 'در هر $unit';
  }

  @override
  String get dateToday => 'امروز';

  @override
  String get dateTomorrow => 'فردا';

  @override
  String get dateYesterday => 'دیروز';

  @override
  String dateInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n روز دیگر',
      one: '$n روز دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $n هفته دیگر',
      one: 'حدود $n هفته دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $n ماه دیگر',
      one: 'حدود $n ماه دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n روز گذشته',
      one: '$n روز گذشته',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n یادآور موعددار',
      one: '$n یادآور موعددار',
      zero: 'چیزی موعد ندارد',
    );
    return '$_temp0';
  }
}
