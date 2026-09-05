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
  String unitConsumptionPerDistance(String n) {
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

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText تۆماری',
      one: 'یەک تۆماری',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$subject و $_temp0 بسڕدرێتەوە؟',
      zero: '$subject بسڕدرێتەوە؟',
    );
    return '$_temp1';
  }

  @override
  String confirmDeleteBody(
    int fillUps,
    String fillUpsText,
    int services,
    String servicesText,
    int costs,
    String costsText,
    int trips,
    String tripsText,
    int reminders,
    String remindersText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      fillUps,
      locale: localeName,
      other: '$fillUpsText سووتەمەنی',
      one: 'یەک سووتەمەنی',
      zero: 'هیچ سووتەمەنیەک',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText خزمەتگوزاری',
      one: 'یەک خزمەتگوزاری',
      zero: 'هیچ خزمەتگوزارییەک',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText تێچوو',
      one: 'یەک تێچوو',
      zero: 'هیچ تێچوویەک',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText گەشت',
      one: 'یەک گەشت',
      zero: 'هیچ گەشتێک',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText بیرخەرەوە',
      one: 'یەک بیرخەرەوە',
      zero: 'هیچ بیرخەرەوەیەک',
    );
    return '$_temp0، $_temp1، $_temp2، $_temp3 و $_temp4 بۆ هەمیشە دەسڕدرێنەوە.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'بۆ پشتڕاستکردنەوە $subject بنووسە';
  }

  @override
  String confirmDeleteMismatch(String subject) {
    return 'ئەمە لەگەڵ $subject یەک ناگرێتەوە.';
  }

  @override
  String get confirmDeleteDelete => 'سڕینەوە';

  @override
  String snoozeTitle(String item) {
    return 'دواخستنی $item';
  }

  @override
  String get snoozeBody =>
      'ئەمە تەنها بیرخەرەوەکە بێدەنگ دەکات و کاتی پێویستی کارەکە ناگۆڕێت.';

  @override
  String snoozeThreeDays(String count) {
    return '$count ڕۆژ';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count هەفتە';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count مانگ';
  }

  @override
  String snoozeDistance(String distance) {
    return 'دوای $distanceی دیکە';
  }

  @override
  String snoozeUntil(String date) {
    return 'تا $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'لە $odometer';
  }

  @override
  String get commonCancel => 'پاشگەزبوونەوە';

  @override
  String get commonContinue => 'بەردەوام بە';

  @override
  String get commonRestoreBackup => 'پاشەکەوتیک بگەڕێنەوە';

  @override
  String settingsLanguageSystem(String language) {
    return 'سیستەم ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'ئۆدۆڤا هێشتا بۆ زمانی ئامێرەکەت وەرنەگێڕدراوە. ژمارە، بەروار، یەکە و بڕی پارە هێشتا بەپێی هەرێمەکەت دەبن.';

  @override
  String get firstRunLanguageTagline =>
      'ئەو زمانە هەڵبژێرە کە باشتر دەیخوێنیتەوە.';

  @override
  String get firstRunRestorePrompt => 'لە مۆبایلێکی تر هاتوویت؟';

  @override
  String get firstRunVehicleTitle => 'ئۆتۆمبێلەکەت';

  @override
  String get firstRunVehicleSubtitle =>
      'یەک ئۆتۆمبێل و یەک ژمارە. هەموو ئامادەکارییەکە هەر ئەوەیە.';

  @override
  String get vehicleTypeCar => 'ئۆتۆمبێل';

  @override
  String get vehicleTypeMotorcycle => 'مۆتۆرسیکل';

  @override
  String get vehicleTypeVan => 'ڤان';

  @override
  String get vehicleNameLabel => 'ناو';

  @override
  String get vehicleNameDefaultCar => 'ئۆتۆمبێلەکەم';

  @override
  String get vehicleNameDefaultMotorcycle => 'مۆتۆرسیکلەکەم';

  @override
  String get vehicleNameDefaultVan => 'ڤانەکەم';

  @override
  String get vehicleFuelLabel => 'سووتەمەنی';

  @override
  String get fuelPetrol => 'بەنزین';

  @override
  String get fuelDiesel => 'دیزل';

  @override
  String get fuelElectric => 'کارەبایی';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelHybrid => 'هایبرید';

  @override
  String get fuelOther => 'هیتر';

  @override
  String get commonMore => 'زیاتر…';

  @override
  String get odometerNowLabel => 'ژمارەی ئێستای کیلۆمێتر';

  @override
  String get odometerFirstRunHint => 'لە داشبۆردەکەوە بیخوێنەوە.';

  @override
  String get odometerEmptyError => 'ئەو ژمارەیە بنووسە کە لەسەر داشبۆردەکەتە.';

  @override
  String get odometerNotANumberError =>
      'ئەمە لە ژمارە ناچێت. تەنها ڕەقەم بنووسە.';

  @override
  String get odometerImplausibleWarning =>
      'ئەمە لەو مەودایە زیاترە کە هیچ ئۆتۆمبێلێک بڕیبێتی. ژمارەکە بپشکنە.';

  @override
  String get commonUseItAnyway => 'هەر بەکاری بهێنە';

  @override
  String get annualBandLabelKm => 'ساڵانە نزیکەی چەند ڕێگا دەبڕیت؟ (هەزار کم)';

  @override
  String get annualBandLabelMi =>
      'ساڵانە نزیکەی چەند ڕێگا دەبڕیت؟ (هەزار مایل)';

  @override
  String annualBandUnder(String max) {
    return 'کەمتر لە $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'زیاتر لە $min';
  }

  @override
  String get commonStart => 'دەستپێبکە';

  @override
  String get firstRunHaveBackup => 'پێشتر پاشەکەوتێکی ئۆدۆڤام هەیە';

  @override
  String get saveDiskFullError =>
      'پاشەکەوت نەکرا. لەوانەیە بۆشایی مۆبایلەکەت نەمابێت.';

  @override
  String get commonRetry => 'دووبارە هەوڵبدە';

  @override
  String get vehicleEditTitle => 'ئۆتۆمبێل';

  @override
  String get commonClose => 'داخستن';

  @override
  String get commonSave => 'پاشەکەوتکردن';

  @override
  String get vehicleTypeOther => 'هیتر';

  @override
  String get vehicleMakeLabel => 'مارکە';

  @override
  String get vehicleModelLabel => 'مۆدێل';

  @override
  String get vehicleYearLabel => 'ساڵ';

  @override
  String get vehiclePlateLabel => 'پلاک';

  @override
  String get vehicleVinLabel => 'VIN';

  @override
  String get vehicleColourLabel => 'ڕەنگ';

  @override
  String get vehicleNotesLabel => 'تێبینی';

  @override
  String get vehicleBusinessLabel => 'ئەمە بۆ کار لێدەخوڕیت؟';

  @override
  String get vehicleMuteLabel => 'بێدەنگکردنی بیرخەرەوەکانی ئەم ئۆتۆمبێلە';

  @override
  String get vehicleOdometerRow => 'ژمارەی کیلۆمێتر';

  @override
  String vehicleOdometerRowHint(String age) {
    return '$age تۆمارکراوە';
  }

  @override
  String get vehicleMarkAsSold => 'نیشانەکردن وەک فرۆشراو';

  @override
  String get vehicleKeepItMarkSold => 'بیهێڵەوە — وەک فرۆشراو نیشانەی بکە';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return 'سڕینەوەی $name و $countText تۆمارەکەی';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return 'سڕینەوەی $name';
  }

  @override
  String get vehiclePurchaseGroup => 'کڕین و فرۆشتن';

  @override
  String get vehicleUnitsGroup => 'یەکە و دراوی ئەم ئۆتۆمبێلە';

  @override
  String get commonAutomatic => 'خۆکار';

  @override
  String get vehiclePurchaseDate => 'بەرواری کڕین';

  @override
  String get vehiclePurchasePrice => 'نرخی کڕین';

  @override
  String get vehiclePurchaseOdometer => 'ژمارەی کیلۆمێتر لە کاتی کڕین';

  @override
  String get vehicleSoldOn => 'بەرواری فرۆشتن';

  @override
  String get vehicleSoldPrice => 'نرخی فرۆشتن';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'ساڵێک لە نێوان $min و $max بنووسە.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'بەزۆری VIN لە $countText پیت پێکدێت.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'پێشتر ئۆتۆمبێلێکت بە ناوی $name هەیە';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'تەنها تۆمارە نوێیەکان ئەمە بەکاردەهێنن. ئەوەی پێشتر پاشەکەوت کراوە ناگۆڕێت.';

  @override
  String get vehicleFuelChangeNote =>
      'ماوەکانی بیرخەرەوەکان وەک خۆیان دەمێننەوە.';

  @override
  String get colourWhite => 'سپی';

  @override
  String get colourSilver => 'زیوی';

  @override
  String get colourGrey => 'خۆڵەمێشی';

  @override
  String get colourBlack => 'ڕەش';

  @override
  String get colourRed => 'سوور';

  @override
  String get colourBlue => 'شین';

  @override
  String get colourGreen => 'سەوز';

  @override
  String get colourYellow => 'زەرد';

  @override
  String get colourOther => 'هیتر';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ڕۆژ لەمەوبەر',
      one: '$nText ڕۆژ لەمەوبەر',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $nText هەفتە لەمەوبەر',
      one: 'نزیکەی $nText هەفتە لەمەوبەر',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزیکەی $nText مانگ لەمەوبەر',
      one: 'نزیکەی $nText مانگ لەمەوبەر',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'ئۆتۆمبێلەکان';

  @override
  String get vehiclesIntro =>
      'لێرەدا ئۆتۆمبێلەکانت بەڕێوە دەبەیت. گۆڕینی ئۆتۆمبێل لە ناونیشانی پەڕەی ماڵەوە ئەنجام دەدرێت.';

  @override
  String get vehiclesReorderHint =>
      'بۆ گۆڕینی ڕیزبەندی، دەستت لەسەر ڕیزێک ڕابگرە. بۆ فرۆشتن و سڕینەوە، ڕیزەکە بەلایەکدا بکێشە.';

  @override
  String get vehiclesSoldArchived => 'فرۆشراو و ئەرشیفکراو';

  @override
  String get vehicleStatusAllGood => 'هەموو شتێک باشە';

  @override
  String get vehicleStatusNoReminders => 'هێشتا هیچ بیرخەرەوەیەک نییە';

  @override
  String get vehicleStatusNeedsOdometer =>
      'ژمارەی کیلۆمێتر پێویستی بە نوێکردنەوەیە';

  @override
  String get vehicleStatusUnknown => 'نەزانرا چی کاتی هاتووە';

  @override
  String vehicleOdometerStale(String age) {
    return 'کیلۆمەتری $age نوێکراوەتەوە';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'دوایین تۆمار $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return '$item دواکەوتووە';
  }

  @override
  String vehicleStatusDue(String item) {
    return '$item کاتی هاتووە';
  }

  @override
  String get vehicleStatusItemGeneric => 'خزمەتگوزاری';

  @override
  String get vehiclesOnlyOneWarning =>
      'ئەمە تاکە ئۆتۆمبێلتە. ئەگەر بیسڕیتەوە، ئۆدۆڤا لە سەرەتاوە دەست پێدەکاتەوە.';

  @override
  String get vehicleSwitchToIt => 'بۆی بگۆڕە';

  @override
  String get vehicleAddTitle => 'زیادکردنی ئۆتۆمبێل';

  @override
  String vehicleAddedSnack(String name) {
    return '$name زیادکرا';
  }

  @override
  String get switcherTitle => 'گۆڕینی ئۆتۆمبێل';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ئۆتۆمبێل',
      one: '$nText ئۆتۆمبێل',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'زیادکردنی ئۆتۆمبێل';

  @override
  String get switcherManageVehicles => 'بەڕێوەبردنی ئۆتۆمبێلەکان';

  @override
  String get vehicleBusinessBadge => 'کار';

  @override
  String get commonBack => 'گەڕانەوە';

  @override
  String get commonAdd => 'زیادکردن';

  @override
  String get commonDelete => 'سڕینەوە';

  @override
  String get commonUndo => 'گەڕانەوە';

  @override
  String vehicleDeletedSnack(String name) {
    return '$name سڕایەوە';
  }

  @override
  String vehicleSoldSnack(String name) {
    return '$name وەک فرۆشراو نیشانە کرا';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'فرۆشراوە لە $date · $countText تۆمار',
      one: 'فرۆشراوە لە $date · $countText تۆمار',
      zero: 'فرۆشراوە $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$item لە $countText ڕۆژی دیکەدا پێویستە',
      one: '$item لە $countText ڕۆژی دیکەدا پێویستە',
    );
    return '$_temp0';
  }

  @override
  String homeOverdueByDistance(String distance) {
    return '$distance دواکەوتووە';
  }

  @override
  String homeOverdueByTime(String duration) {
    return '$duration دواکەوتووە';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return '$distance و $duration دواکەوتووە';
  }

  @override
  String get homeDueNow => 'ئێستا کاتیەتی';

  @override
  String homeDueSoonDistance(String distance) {
    return 'نزیکەی $distance تر';
  }

  @override
  String get homeNeedsOdometer => 'پێویستی بە خوێندنەوەی کیلۆمەترە';

  @override
  String get homeUnknownTitle => 'ئەمانە دواجار کەی کران؟';

  @override
  String get homeUnknownHint => 'پێم بڵێ تا ببنە بیرخەرەوە.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText تری',
      one: '+ $nText تری',
      zero: 'هەموویان ببینە',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'هەموویان ببینە — $nText تری کاتیەتی یان دواکەوتووە',
      one: 'هەموویان ببینە — $nText تری کاتیەتی یان دواکەوتووە',
      zero: 'هەموو بیرخەرەوەکان',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'دواخراوە هەتا $date';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'هەموو بیرخەرەوەکان ($nText)',
      one: 'هەموو بیرخەرەوەکان ($nText)',
      zero: 'هەموو بیرخەرەوەکان',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'ئۆدۆڤا بە کارە ئاساییەکان دەست پێدەکات. ڕێنمای خۆت سەرەکییە — هەرچی لێرە بگۆڕە.';

  @override
  String get actionLogIt => 'تۆماری بکە';

  @override
  String get actionUpdateOdometer => 'نوێکردنەوەی کیلۆمەتر';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ڕۆژ',
      one: '$nText ڕۆژ',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText هەفتە',
      one: '$nText هەفتە',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مانگ',
      one: '$nText مانگ',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'تۆمارکراوە $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'خەمڵێنراو لە نزیکەی $rate ڕۆژانە لە $dateەوە.';
  }

  @override
  String get homeEstimateExpired =>
      'دوایین خوێندنەوەت زۆر کۆنە، بۆیە ئۆدۆڤا وازی لە خەمڵاندن هێناوە. ئەوەی ئێستا لەسەر داشبۆردە بینووسە.';

  @override
  String get homeConsumptionPending =>
      'یەکەم ژمارەی خەرجکردنت لە پڕکردنەوەی تەواوی داهاتوودا دێت.';

  @override
  String get homeLastFillUp => 'دوایین سووتەمەنی‌کردن';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText دواکەوتوو',
      one: '$name · $nText دواکەوتوو',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText کاتی هاتووە',
      one: '$name · $nText کاتی هاتووە',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'بۆ هەر $unit';
  }

  @override
  String get homeTilePerMonth => 'لە مانگێکدا';

  @override
  String get homeMoreActions => 'کردارەکانی تر';

  @override
  String get actionSnooze => 'دواخستن';

  @override
  String get actionEditReminder => 'دەستکاری بیرخەرەوە';

  @override
  String get actionTurnOff => 'ئەم بیرخەرەوە بکوژێنەوە';

  @override
  String homeTurnedOff(String item) {
    return '$item کوژێنرایەوە';
  }

  @override
  String get unitConsumptionKmPerLitre => 'کم/ل';

  @override
  String unitConsumptionKwhPerDistance(String n) {
    return 'ک.و.س/$n کم';
  }

  @override
  String get unitConsumptionMiPerKwh => 'مایل/ک.و.س';

  @override
  String get unitEnergyKwh => 'ک.و.س';

  @override
  String get unitMassKg => 'کگم';

  @override
  String commonEstimatedValue(String value) {
    return '~$value';
  }

  @override
  String homeWasDueAt(String odometer) {
    return 'کاتی لە $odometer بوو';
  }

  @override
  String homeWasDueOn(String date) {
    return 'کاتی لە $date بوو';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'کاتی لە $odometer · $date بوو';
  }

  @override
  String homeDueAt(String odometer) {
    return 'لە $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'لە $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'نزیکەی $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'دوایین تۆمار $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'کیلۆمەترپێو $nText ڕۆژ لەمەوبەر نوێ کرایەوە.',
      one: 'کیلۆمەترپێو $nText ڕۆژ لەمەوبەر نوێ کرایەوە.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'بۆ هەفتەیەک بیشارەوە';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'تۆ $item ت لە $date بە کراو نیشانە کرد.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'من $odometer و بێ تێچوو تۆمارم کرد.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'داهاتوو لە $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'ژمارە ڕاستەکان بنووسە';

  @override
  String get actionThatsRight => 'ڕاستە';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item لە $date دواکەوت';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item لە $date کاتی دێت';
  }

  @override
  String get homeDigestDismiss => 'داخستنی ئەم کورتەیە';

  @override
  String get odometerSavedSnack => 'کیلۆمەترپێو پاشەکەوت کرا';

  @override
  String get homeNothingDue => 'هیچ شتێک کاتی نەهاتووە';

  @override
  String homeNextIs(String item, String date) {
    return 'دواتر: $item، $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'لە دوایین $itemەوە:';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'بیرخەرەوەکانت ڕێک بخە — پێم بڵێ دوایین جار کەی کراون';

  @override
  String get homeFirstRunConsumption =>
      'سووتەمەنییەک تۆمار بکە و خەرجییەکەت لێرەوە دەست پێدەکات.';

  @override
  String homeSoldTitle(String date) {
    return 'ئەم ئۆتۆمبێلە بە فرۆشراو نیشانە کراوە ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return '$duration خاوەندارێتی · $distance لێخوڕدن';
  }

  @override
  String get homeErrorTitle => 'ئۆدۆڤا ناتوانێت داتاکانت بخوێنێتەوە.';

  @override
  String get actionOpenBackup => 'کردنەوەی پاڵپشت و گەڕاندنەوە';

  @override
  String get homeRowBroken => 'شتێک لەم بیرخەرەوەیە هەڵەیە';

  @override
  String get remindersTitle => 'بیرخەرەوەکان';

  @override
  String get remindersGroupPaused => 'وەستێنراو';

  @override
  String get remindersGroupNotTracked => 'شوێن‌نەکەوتوو';

  @override
  String get remindersTrack => '+ شوێن‌کەوتن';

  @override
  String get remindersPausedStatus => 'وەستاو';

  @override
  String get remindersEmpty => 'هێشتا هیچ بیرخەرەوەیەک نییە.';

  @override
  String get remindersNothingTracked =>
      'هیچ شتێک بۆ ئەم ئۆتۆمبێلە شوێن ناکرێت.';

  @override
  String get remindersWhenLastDone => 'دوایین جار کەی کرا';

  @override
  String get actionDoneToday => 'ئەمڕۆ کرا';

  @override
  String get actionTurnOffShort => 'کوژاندنەوە';
}
