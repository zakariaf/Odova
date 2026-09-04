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

  @override
  String get routeNotFoundTitle => 'غير موجود';

  @override
  String get routeNotFoundBody => 'هذا الرابط لا يؤدي إلى أي مكان.';

  @override
  String get routeNotFoundGoHome => 'الذهاب إلى الرئيسية';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabHistory => 'السجل';

  @override
  String get tabCosts => 'التكاليف';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get tabLogA11y => 'تسجيل';

  @override
  String get discardTitle => 'تجاهل التغييرات؟';

  @override
  String discardBody(String subject, String summary) {
    return 'لم يتم حفظ تعديلاتك على $subject — $summary.';
  }

  @override
  String get discardKeepEditing => 'متابعة التحرير';

  @override
  String get discardDiscard => 'تجاهل';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText سجل',
      many: '$countText سجلاً',
      few: '$countText سجلات',
      two: 'سجليه',
      one: 'سجله الواحد',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حذف $subject و$_temp0؟',
      zero: 'حذف $subject؟',
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
      other: '$fillUpsText تعبئة',
      many: '$fillUpsText تعبئةً',
      few: '$fillUpsText تعبئات',
      two: 'تعبئتان',
      one: 'تعبئة واحدة',
      zero: 'لا تعبئات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText صيانة',
      many: '$servicesText صيانةً',
      few: '$servicesText صيانات',
      two: 'صيانتان',
      one: 'صيانة واحدة',
      zero: 'لا صيانات',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText تكلفة',
      many: '$costsText تكلفةً',
      few: '$costsText تكاليف',
      two: 'تكلفتان',
      one: 'تكلفة واحدة',
      zero: 'لا تكاليف',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText رحلة',
      many: '$tripsText رحلةً',
      few: '$tripsText رحلات',
      two: 'رحلتان',
      one: 'رحلة واحدة',
      zero: 'لا رحلات',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText تذكير',
      many: '$remindersText تذكيرًا',
      few: '$remindersText تذكيرات',
      two: 'تذكيران',
      one: 'تذكير واحد',
      zero: 'لا تذكيرات',
    );
    return '$_temp0، و$_temp1، و$_temp2، و$_temp3 و$_temp4 تُحذف نهائيًا.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'اكتب $subject للتأكيد';
  }

  @override
  String get confirmDeleteDelete => 'حذف';

  @override
  String snoozeTitle(String item) {
    return 'تأجيل $item';
  }

  @override
  String get snoozeBody =>
      'هذا يُسكت التذكير فقط. ولا يغيّر موعد استحقاق العمل.';

  @override
  String snoozeThreeDays(String count) {
    return '$count أيام';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count أسبوع';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count شهر';
  }

  @override
  String snoozeDistance(String distance) {
    return 'بعد $distance أخرى';
  }

  @override
  String snoozeUntil(String date) {
    return 'حتى $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'عند $odometer';
  }

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonRestoreBackup => 'استعادة نسخة احتياطية';

  @override
  String settingsLanguageSystem(String language) {
    return 'النظام ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'لم تُترجم أودوفا بعد إلى لغة جهازك. ستظل الأرقام والتواريخ والوحدات والمبالغ تتبع منطقتك.';

  @override
  String get firstRunLanguageTagline => 'اختر اللغة التي تقرأها بشكل أفضل.';

  @override
  String get firstRunRestorePrompt => 'هل انتقلت من هاتف آخر؟';

  @override
  String get firstRunVehicleTitle => 'مركبتك';

  @override
  String get firstRunVehicleSubtitle =>
      'مركبة واحدة ورقم واحد. هذا هو الإعداد كله.';

  @override
  String get vehicleTypeCar => 'سيارة';

  @override
  String get vehicleTypeMotorcycle => 'دراجة نارية';

  @override
  String get vehicleTypeVan => 'شاحنة صغيرة';

  @override
  String get vehicleNameLabel => 'الاسم';

  @override
  String get vehicleNameDefaultCar => 'سيارتي';

  @override
  String get vehicleNameDefaultMotorcycle => 'دراجتي النارية';

  @override
  String get vehicleNameDefaultVan => 'شاحنتي';

  @override
  String get vehicleFuelLabel => 'الوقود';

  @override
  String get fuelPetrol => 'بنزين';

  @override
  String get fuelDiesel => 'ديزل';

  @override
  String get fuelElectric => 'كهربائي';

  @override
  String get fuelLpg => 'غاز مسال';

  @override
  String get fuelCng => 'غاز طبيعي';

  @override
  String get fuelHybrid => 'هجين';

  @override
  String get fuelOther => 'أخرى';

  @override
  String get commonMore => 'المزيد…';

  @override
  String get odometerNowLabel => 'العدّاد الآن';

  @override
  String get odometerFirstRunHint => 'اقرأه من لوحة العدّادات.';

  @override
  String get odometerEmptyError => 'أدخل الرقم الظاهر على لوحة العدّادات.';

  @override
  String get odometerNotANumberError => 'هذا لا يبدو رقمًا. أرقام فقط.';

  @override
  String get odometerImplausibleWarning =>
      'هذا أكبر مما قطعته أي سيارة. تحقّق من الرقم.';

  @override
  String get commonUseItAnyway => 'استخدمه على أي حال';

  @override
  String get annualBandLabelKm =>
      'ما المسافة التقريبية في السنة؟ (بآلاف الكيلومترات)';

  @override
  String get annualBandLabelMi =>
      'ما المسافة التقريبية في السنة؟ (بآلاف الأميال)';

  @override
  String annualBandUnder(String max) {
    return 'أقل من $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'أكثر من $min';
  }

  @override
  String get commonStart => 'ابدأ';

  @override
  String get firstRunHaveBackup => 'لديّ بالفعل نسخة احتياطية من أودوفا';

  @override
  String get saveDiskFullError =>
      'تعذّر الحفظ. ربما لا توجد مساحة كافية في هاتفك.';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get vehicleEditTitle => 'المركبة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonSave => 'حفظ';

  @override
  String get vehicleTypeOther => 'أخرى';

  @override
  String get vehicleMakeLabel => 'الماركة';

  @override
  String get vehicleModelLabel => 'الطراز';

  @override
  String get vehicleYearLabel => 'السنة';

  @override
  String get vehiclePlateLabel => 'رقم اللوحة';

  @override
  String get vehicleVinLabel => 'رقم الهيكل';

  @override
  String get vehicleColourLabel => 'اللون';

  @override
  String get vehicleNotesLabel => 'الملاحظات';

  @override
  String get vehicleBusinessLabel => 'هل تستخدم هذه المركبة في العمل؟';

  @override
  String get vehicleMuteLabel => 'كتم تذكيرات هذه المركبة';

  @override
  String get vehicleOdometerRow => 'العدّاد';

  @override
  String vehicleOdometerRowHint(String age) {
    return 'أُدخِل $age · اضغط للتحديث';
  }

  @override
  String get vehicleMarkAsSold => 'تحديد كمباعة';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return 'حذف $name و$countText من سجلاته';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return 'حذف $name';
  }

  @override
  String get vehiclePurchaseGroup => 'الشراء والبيع';

  @override
  String get vehicleUnitsGroup => 'وحدات هذه المركبة وعملتها';

  @override
  String get commonAutomatic => 'تلقائي';

  @override
  String get vehiclePurchaseDate => 'تاريخ الشراء';

  @override
  String get vehiclePurchasePrice => 'سعر الشراء';

  @override
  String get vehiclePurchaseOdometer => 'العدّاد عند الشراء';

  @override
  String get vehicleSoldOn => 'تاريخ البيع';

  @override
  String get vehicleSoldPrice => 'سعر البيع';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'أدخل سنة بين $min و$max.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'عادةً ما يتكوّن رقم الهيكل من $countText خانةً.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'لديك بالفعل مركبة باسم $name';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'ينطبق هذا على السجلات الجديدة فقط. ولا يتغيّر شيء مما حُفظ من قبل.';

  @override
  String get vehicleFuelChangeNote => 'تحتفظ التذكيرات بفتراتها كما هي.';

  @override
  String get colourWhite => 'أبيض';

  @override
  String get colourSilver => 'فضي';

  @override
  String get colourGrey => 'رمادي';

  @override
  String get colourBlack => 'أسود';

  @override
  String get colourRed => 'أحمر';

  @override
  String get colourBlue => 'أزرق';

  @override
  String get colourGreen => 'أخضر';

  @override
  String get colourYellow => 'أصفر';

  @override
  String get colourOther => 'آخر';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل $nText يوم',
      many: 'قبل $nText يومًا',
      few: 'قبل $nText أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
      zero: 'قبل $nText يوم',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل حوالي $nText أسبوع',
      many: 'قبل حوالي $nText أسبوعًا',
      few: 'قبل حوالي $nText أسابيع',
      two: 'قبل حوالي أسبوعين',
      one: 'قبل حوالي أسبوع',
      zero: 'قبل حوالي $nText أسبوع',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قبل حوالي $nText شهر',
      many: 'قبل حوالي $nText شهرًا',
      few: 'قبل حوالي $nText أشهر',
      two: 'قبل حوالي شهرين',
      one: 'قبل حوالي شهر',
      zero: 'قبل حوالي $nText شهر',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'المركبات';

  @override
  String get vehiclesIntro =>
      'أدِر مركباتك من هنا. أمّا التبديل بينها فيتم من عنوان الشاشة الرئيسية.';

  @override
  String get vehiclesReorderHint =>
      'اضغط مطوّلًا على صف لإعادة ترتيبه. اسحب للبيع والحذف.';

  @override
  String get vehiclesSoldArchived => 'مباعة ومؤرشفة';

  @override
  String get vehicleStatusAllGood => 'كل شيء على ما يرام';

  @override
  String get vehicleStatusNoReminders => 'لا تذكيرات بعد';

  @override
  String get vehicleStatusNeedsOdometer => 'العدّاد يحتاج إلى تحديث';

  @override
  String get vehicleStatusUnknown => 'تعذّر تحديد ما هو مستحق';

  @override
  String vehicleOdometerStale(String age) {
    return 'آخر تحديث لعداد المسافة $age';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'آخر إدخال في $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return 'فات موعد $item';
  }

  @override
  String get vehicleStatusItemGeneric => 'صيانة';

  @override
  String get vehiclesOnlyOneWarning =>
      'هذه مركبتك الوحيدة. حذفها يعيد أودوفا إلى نقطة البداية.';

  @override
  String get vehicleSwitchToIt => 'التبديل إليها';

  @override
  String get switcherTitle => 'تبديل المركبة';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مركبة',
      many: '$nText مركبةً',
      few: '$nText مركبات',
      two: 'مركبتان',
      one: 'مركبة واحدة',
      zero: '$nText مركبة',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'إضافة مركبة';

  @override
  String get switcherManageVehicles => 'إدارة المركبات';

  @override
  String get vehicleBusinessBadge => 'للعمل';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonUndo => 'تراجع';

  @override
  String vehicleDeletedSnack(String name) {
    return 'تم حذف $name';
  }

  @override
  String vehicleSoldSnack(String name) {
    return 'تم وضع علامة \"مباعة\" على $name';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'بِيعت في $date · $countText سجل',
      many: 'بِيعت في $date · $countText سجلاً',
      few: 'بِيعت في $date · $countText سجلات',
      two: 'بِيعت في $date · سجلان',
      one: 'بِيعت في $date · سجل واحد',
      zero: 'بِيعت في $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'موعد $item خلال $countText يوم',
      many: 'موعد $item خلال $countText يومًا',
      few: 'موعد $item خلال $countText أيام',
      two: 'موعد $item خلال يومين',
      one: 'موعد $item خلال يوم',
      zero: 'موعد $item خلال $countText يوم',
    );
    return '$_temp0';
  }
}
