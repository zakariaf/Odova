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
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ڕۆژی دیکە',
      one: '$nText ڕۆژی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $nText هەفتەی دیکە',
      one: 'نزیکەی $nText هەفتەی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $nText مانگی دیکە',
      one: 'نزیکەی $nText مانگی دیکە',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ڕۆژ دواکەوتووە',
      one: '$nText ڕۆژ دواکەوتووە',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText بیرخەرەوە',
      one: '$nText بیرخەرەوە',
      zero: 'هیچ شتێک نییە',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'نەدۆزرایەوە';

  @override
  String get routeNotFoundBody => 'ئەم بەستەرە بۆ هیچ شوێنێک نابات.';

  @override
  String get routeNotFoundGoHome => 'چوون بۆ ماڵەوە';

  @override
  String get tabHome => 'ماڵەوە';

  @override
  String get tabHistory => 'مێژوو';

  @override
  String get tabCosts => 'تێچووەکان';

  @override
  String get tabSettings => 'ڕێکخستنەکان';

  @override
  String get tabLogA11y => 'تۆمارکردن';

  @override
  String get discardTitle => 'گۆڕانکارییەکان فڕێبدرێن؟';

  @override
  String discardBody(String subject, String summary) {
    return 'دەستکارییەکانت لەسەر $subject — $summary — پاشەکەوت نەکراون.';
  }

  @override
  String get discardKeepEditing => 'بەردەوامبوون لە دەستکاری';

  @override
  String get discardDiscard => 'فڕێدان';
}
