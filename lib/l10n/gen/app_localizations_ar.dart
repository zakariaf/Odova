// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'تقديري، حوالي $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'يحتاج أودوفا إلى قراءة عدّاد ليحدّد الموعد';

  @override
  String get unitDistanceKm => 'كم';

  @override
  String get unitDistanceMi => 'ميل';

  @override
  String get unitVolumeLitre => 'لتر';

  @override
  String get unitVolumeGallon => 'جالون';

  @override
  String unitConsumptionPerDistance(int n) {
    return 'ل/$n كم';
  }

  @override
  String get unitConsumptionMpg => 'ميل/جالون';

  @override
  String unitPerDistance(String unit) {
    return 'لكل $unit';
  }

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateTomorrow => 'غدًا';

  @override
  String get dateYesterday => 'أمس';

  @override
  String dateInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال $n يوم',
      many: 'خلال $n يومًا',
      few: 'خلال $n أيام',
      two: 'خلال يومين',
      one: 'خلال يوم',
      zero: 'خلال $n يوم',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال حوالي $n أسبوع',
      many: 'خلال حوالي $n أسبوعًا',
      few: 'خلال حوالي $n أسابيع',
      two: 'خلال حوالي أسبوعين',
      one: 'خلال حوالي أسبوع',
      zero: 'خلال حوالي $n أسبوع',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال حوالي $n شهر',
      many: 'خلال حوالي $n شهرًا',
      few: 'خلال حوالي $n أشهر',
      two: 'خلال حوالي شهرين',
      one: 'خلال حوالي شهر',
      zero: 'خلال حوالي $n شهر',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'متأخر $n يوم',
      many: 'متأخر $n يومًا',
      few: 'متأخر $n أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا',
      zero: 'متأخر $n يوم',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n تذكير مستحق',
      many: '$n تذكيرًا مستحقًا',
      few: '$n تذكيرات مستحقة',
      two: 'تذكيران مستحقان',
      one: 'تذكير واحد مستحق',
      zero: 'لا شيء مستحق',
    );
    return '$_temp0';
  }
}
