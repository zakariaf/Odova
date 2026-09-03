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
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال $nText يوم',
      many: 'خلال $nText يومًا',
      few: 'خلال $nText أيام',
      two: 'خلال يومين',
      one: 'خلال يوم',
      zero: 'خلال $nText يوم',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال حوالي $nText أسبوع',
      many: 'خلال حوالي $nText أسبوعًا',
      few: 'خلال حوالي $nText أسابيع',
      two: 'خلال حوالي أسبوعين',
      one: 'خلال حوالي أسبوع',
      zero: 'خلال حوالي $nText أسبوع',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'خلال حوالي $nText شهر',
      many: 'خلال حوالي $nText شهرًا',
      few: 'خلال حوالي $nText أشهر',
      two: 'خلال حوالي شهرين',
      one: 'خلال حوالي شهر',
      zero: 'خلال حوالي $nText شهر',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'متأخر $nText يوم',
      many: 'متأخر $nText يومًا',
      few: 'متأخر $nText أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا',
      zero: 'متأخر $nText يوم',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText تذكير مستحق',
      many: '$nText تذكيرًا مستحقًا',
      few: '$nText تذكيرات مستحقة',
      two: 'تذكيران مستحقان',
      one: 'تذكير واحد مستحق',
      zero: 'لا شيء مستحق',
    );
    return '$_temp0';
  }
}
