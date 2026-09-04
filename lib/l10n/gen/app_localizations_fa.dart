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
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText روز دیگر',
      one: '$nText روز دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $nText هفته دیگر',
      one: 'حدود $nText هفته دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $nText ماه دیگر',
      one: 'حدود $nText ماه دیگر',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText روز گذشته',
      one: '$nText روز گذشته',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText یادآور موعددار',
      one: '$nText یادآور موعددار',
      zero: 'چیزی موعد ندارد',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'پیدا نشد';

  @override
  String get routeNotFoundBody => 'این پیوند به جایی نمی‌رسد.';

  @override
  String get routeNotFoundGoHome => 'رفتن به خانه';
}
