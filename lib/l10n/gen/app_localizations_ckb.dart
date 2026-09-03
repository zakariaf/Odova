// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'خەمڵێنراو، نزیکەی $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'ئۆدۆڤا پێویستی بە ژمارەی کیلۆمێتر هەیە بۆ دیاریکردنی کات';

  @override
  String get unitDistanceKm => 'کم';

  @override
  String get unitDistanceMi => 'مایل';

  @override
  String get unitVolumeLitre => 'لیتر';

  @override
  String get unitVolumeGallon => 'گاڵن';

  @override
  String unitConsumptionPerDistance(int n) {
    return 'ل/$n کم';
  }

  @override
  String get unitConsumptionMpg => 'مایل بۆ گاڵن';

  @override
  String unitPerDistance(String unit) {
    return 'بۆ هەر $unit';
  }

  @override
  String get dateToday => 'ئەمڕۆ';

  @override
  String get dateTomorrow => 'سبەینێ';

  @override
  String get dateYesterday => 'دوێنێ';

  @override
  String dateInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ڕۆژی دیکە',
      one: '$n ڕۆژی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $n هەفتەی دیکە',
      one: 'نزیکەی $n هەفتەی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $n مانگی دیکە',
      one: 'نزیکەی $n مانگی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ڕۆژ دواکەوتووە',
      one: '$n ڕۆژ دواکەوتووە',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n بیرخەرەوە',
      one: '$n بیرخەرەوە',
      zero: 'هیچ شتێک نییە',
    );
    return '$_temp0';
  }
}
