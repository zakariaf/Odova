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
  String unitConsumptionPerDistance(String n) {
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
  String historyMonthEntryCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مدخل',
      many: '$nText مدخلًا',
      few: '$nText مدخلات',
      two: 'مدخلان',
      one: 'مدخل واحد',
      zero: '$nText مدخل',
    );
    return '$_temp0';
  }

  @override
  String get bandFillUpFirstFill =>
      'أول تعبئة — سيظهر أول رقم استهلاك عند الخزان الممتلئ التالي.';

  @override
  String get bandFillUpChainBroken => 'لا يوجد رقم: لم يُسجَّل الخزان السابق.';

  @override
  String get bandFillUpPartial => 'لا يوجد رقم: تعبئة جزئية.';

  @override
  String bandFillUpSegment(String consumption, String distance, String date) {
    return '$consumption على $distance منذ $date';
  }

  @override
  String bandExpenseSpread(String total, String months, String perMonth) {
    return '$total على $months = $perMonth شهريًا';
  }

  @override
  String bandOdometerRate(String distance, String days, String rate) {
    return '$distance في $days — $rate يوميًا';
  }

  @override
  String get bandDeleteFillUp => 'حذف هذه التعبئة';

  @override
  String recomputeFiguresRecalculated(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText رقم استهلاك أُعيد حسابه',
      many: '$nText رقمًا من أرقام الاستهلاك أُعيد حسابه',
      few: '$nText أرقام استهلاك أُعيد حسابها',
      two: 'رقما استهلاك أُعيد حسابهما',
      one: 'رقم استهلاك واحد أُعيد حسابه',
      zero: '$nText رقم استهلاك أُعيد حسابه',
    );
    return '$_temp0';
  }

  @override
  String get recomputeSaved => 'تم الحفظ';

  @override
  String get recomputeFillUpUpdated => 'تم تحديث التعبئة';

  @override
  String get recomputeServiceUpdated => 'تم تحديث الصيانة';

  @override
  String get recomputeExpenseUpdated => 'تم تحديث المصروف';

  @override
  String get recomputeOdometerUpdated => 'تم تحديث القراءة';

  @override
  String get historyReport => 'تقرير';

  @override
  String get historySearchHint => 'بحث';

  @override
  String get historySearchClear => 'مسح البحث';

  @override
  String historySearchNoMatch(String query) {
    return 'لا شيء يطابق «$query».';
  }

  @override
  String get historySearch => 'بحث في السجل';

  @override
  String get historyFilterAll => 'الكل';

  @override
  String get historyFilterFuel => 'الوقود';

  @override
  String get historyFilterService => 'الصيانة';

  @override
  String get historyFilterExpense => 'المصاريف';

  @override
  String get historyFilterTrip => 'الرحلات';

  @override
  String get historyFilterOdometer => 'العدّاد';

  @override
  String get historyReadFailureTitle => 'تعذّر على أودوفا فتح سجلاتك.';

  @override
  String get historyReadFailureAction => 'الانتقال إلى النسخ الاحتياطي';

  @override
  String get historyClearFilters => 'مسح المرشحات';

  @override
  String get historyEmptySubtitle => 'أول تعبئة تبدأ السجل.';

  @override
  String get historyEmptyTitle => 'لم يُسجَّل شيء بعد.';

  @override
  String get historyEmptyAction => 'سجّل تعبئة';

  @override
  String get historyFilteredEmpty => 'لا توجد إدخالات تطابق هذه المرشحات.';

  @override
  String get historyOdometerReading => 'قراءة';

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
  String confirmDeleteMismatch(String subject) {
    return 'هذا لا يطابق $subject.';
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
  String get saveRefusedBackwards =>
      'هذه القراءة أقل من السابقة. تحقّق من الرقم.';

  @override
  String get saveRefusedReadOnly =>
      'لا يمكن الحفظ الآن. إدخالك ما زال موجودًا.';

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
    return 'أُدخِل $age';
  }

  @override
  String get vehicleMarkAsSold => 'تحديد كمباعة';

  @override
  String get vehicleKeepItMarkSold => 'احتفظ بها — وحدّدها كمباعة';

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
  String vehicleStatusDue(String item) {
    return '$item مستحقة';
  }

  @override
  String get vehicleStatusItemGeneric => 'صيانة';

  @override
  String get vehiclesOnlyOneWarning =>
      'هذه مركبتك الوحيدة. حذفها يعيد أودوفا إلى نقطة البداية.';

  @override
  String get vehicleSwitchToIt => 'التبديل إليها';

  @override
  String get vehicleAddTitle => 'إضافة مركبة';

  @override
  String vehicleAddedSnack(String name) {
    return 'تمت إضافة $name';
  }

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

  @override
  String homeOverdueByDistance(String distance) {
    return 'متأخّر بمقدار $distance';
  }

  @override
  String homeOverdueByTime(String duration) {
    return 'متأخّر بمقدار $duration';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return 'متأخّر بمقدار $distance و$duration';
  }

  @override
  String get homeDueNow => 'مستحقّ الآن';

  @override
  String homeDueSoonDistance(String distance) {
    return 'بعد $distance تقريبًا';
  }

  @override
  String get homeNeedsOdometer => 'يحتاج قراءة عدّاد';

  @override
  String get homeUnknownTitle => 'متى جرى هذا آخر مرّة؟';

  @override
  String get homeUnknownHint => 'أخبِرني لتتحوّل إلى تذكيرات.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText عنصر آخر',
      many: '+ $nText عنصرًا آخر',
      few: '+ $nText عناصر أخرى',
      two: '+ عنصران آخران',
      one: '+ عنصر واحد آخر',
      zero: 'عرض الكل',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'عرض الكل — $nText عنصر مستحقّ أو متأخّر',
      many: 'عرض الكل — $nText عنصرًا مستحقًّا أو متأخّرًا',
      few: 'عرض الكل — $nText عناصر أخرى مستحقّة أو متأخّرة',
      two: 'عرض الكل — عنصران آخران مستحقّان أو متأخّران',
      one: 'عرض الكل — عنصر واحد آخر مستحقّ أو متأخّر',
      zero: 'كل التذكيرات',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'مؤجَّل حتى $date';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'كل التذكيرات ($nText تذكير)',
      many: 'كل التذكيرات ($nText تذكيرًا)',
      few: 'كل التذكيرات ($nText تذكيرات)',
      two: 'كل التذكيرات (تذكيران)',
      one: 'كل التذكيرات (تذكير واحد)',
      zero: 'كل التذكيرات',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'تبدأ أودوفا بالأعمال المعتادة. دليلك هو المرجع — عدّل أي شيء هنا.';

  @override
  String get actionLogIt => 'سجّلها';

  @override
  String get actionUpdateOdometer => 'تحديث العدّاد';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText يوم',
      many: '$nText يومًا',
      few: '$nText أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$nText يوم',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText أسبوع',
      many: '$nText أسبوعًا',
      few: '$nText أسابيع',
      two: 'أسبوعان',
      one: 'أسبوع واحد',
      zero: '$nText أسبوع',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText شهر',
      many: '$nText شهرًا',
      few: '$nText أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: '$nText شهر',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'أُدخِل $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'تقدير من نحو $rate يوميًا منذ $date.';
  }

  @override
  String get homeEstimateExpired =>
      'قراءتك الأخيرة قديمة جدًا، لذا توقّفت أودوفا عن التقدير. أدخِل ما يظهر على العدّاد الآن.';

  @override
  String get homeConsumptionPending =>
      'يصل أول رقم استهلاك عند تعبئة الخزان بالكامل في المرّة القادمة.';

  @override
  String get homeLastFillUp => 'آخر تعبئة';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText تذكير متأخر',
      many: '$name · $nText تذكيرًا متأخرًا',
      few: '$name · $nText تذكيرات متأخرة',
      two: '$name · تذكيران متأخران',
      one: '$name · تذكير واحد متأخر',
      zero: '$name · $nText تذكير متأخر',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText تذكير مستحق',
      many: '$name · $nText تذكيرًا مستحقًا',
      few: '$name · $nText تذكيرات مستحقة',
      two: '$name · تذكيران مستحقان',
      one: '$name · تذكير واحد مستحق',
      zero: '$name · $nText تذكير مستحق',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'لكل $unit';
  }

  @override
  String get homeTilePerMonth => 'شهريًا';

  @override
  String get homeMoreActions => 'إجراءات أخرى';

  @override
  String get actionSnooze => 'تأجيل';

  @override
  String get actionEditReminder => 'تعديل التذكير';

  @override
  String get actionTurnOff => 'إيقاف هذا التذكير';

  @override
  String homeTurnedOff(String item) {
    return 'تم إيقاف $item';
  }

  @override
  String get unitConsumptionKmPerLitre => 'كم/ل';

  @override
  String unitConsumptionKwhPerDistance(String n) {
    return 'ك.و.س/$n كم';
  }

  @override
  String get unitConsumptionMiPerKwh => 'ميل/ك.و.س';

  @override
  String get unitEnergyKwh => 'ك.و.س';

  @override
  String get unitMassKg => 'كجم';

  @override
  String commonEstimatedValue(String value) {
    return '~$value';
  }

  @override
  String homeWasDueAt(String odometer) {
    return 'كان مستحقًا عند $odometer';
  }

  @override
  String homeWasDueOn(String date) {
    return 'كان مستحقًا في $date';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'كان مستحقًا عند $odometer · $date';
  }

  @override
  String homeDueAt(String odometer) {
    return 'عند $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'عند $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'حوالي $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'آخر إدخال في $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم تحديث عداد المسافة قبل $nText يوم.',
      many: 'تم تحديث عداد المسافة قبل $nText يومًا.',
      few: 'تم تحديث عداد المسافة قبل $nText أيام.',
      two: 'تم تحديث عداد المسافة قبل يومين.',
      one: 'تم تحديث عداد المسافة أمس.',
      zero: 'تم تحديث عداد المسافة قبل $nText يوم.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'إخفاء لمدة أسبوع';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'لقد وضعت علامة على $item كمنجَز في $date.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'سجّلت $odometer وبدون تكلفة.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'الاستحقاق التالي عند $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'أدخل الأرقام الحقيقية';

  @override
  String get actionThatsRight => 'هذا صحيح';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item أصبح متأخرًا في $date';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item مستحق في $date';
  }

  @override
  String get homeDigestDismiss => 'إغلاق هذا الملخص';

  @override
  String get odometerSavedSnack => 'تم حفظ عداد المسافة';

  @override
  String get homeNothingDue => 'لا شيء مستحق';

  @override
  String homeNextIs(String item, String date) {
    return 'التالي: $item، $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'منذ آخر $item:';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'أعدّ تذكيراتك — أخبرني متى تم كل شيء آخر مرة';

  @override
  String get homeFirstRunConsumption =>
      'سجّل تعبئة وقود ويبدأ استهلاكك من هنا.';

  @override
  String homeSoldTitle(String date) {
    return 'هذه المركبة مُعلَّمة كمباعة ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return 'ملكية $duration · $distance مقطوعة';
  }

  @override
  String get homeErrorTitle => 'لا يستطيع أودوفا قراءة بياناتك.';

  @override
  String get actionOpenBackup => 'فتح النسخ الاحتياطي والاستعادة';

  @override
  String get homeRowBroken => 'هناك خطأ ما في هذا التذكير';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersGroupPaused => 'موقوف مؤقتًا';

  @override
  String get remindersGroupNotTracked => 'غير متتبَّع';

  @override
  String get remindersTrack => '+ تتبُّع';

  @override
  String get remindersPausedStatus => 'موقوف';

  @override
  String get remindersEmpty => 'لا توجد تذكيرات بعد.';

  @override
  String get remindersNothingTracked => 'لا يتم تتبع أي شيء لهذه المركبة.';

  @override
  String get remindersWhenLastDone => 'متى تم هذا آخر مرة';

  @override
  String get actionDoneToday => 'تم اليوم';

  @override
  String get actionTurnOffShort => 'إيقاف';

  @override
  String get actionSnoozeShort => 'تأجيل';

  @override
  String get reminderEditTitle => 'تذكير';

  @override
  String get reminderNewTitle => 'تذكير جديد';

  @override
  String get reminderName => 'الاسم';

  @override
  String get reminderEveryDistance => 'كل';

  @override
  String get reminderEveryMonths => 'كل … أشهر';

  @override
  String get reminderOnceAtOdometer => 'أو مرة واحدة، عند العداد';

  @override
  String get reminderOnceOnDate => 'أو مرة واحدة، في تاريخ';

  @override
  String get reminderLastDoneDate => 'آخر مرة — التاريخ';

  @override
  String get reminderLastDoneOdometer => 'آخر مرة — العداد';

  @override
  String get reminderNotify => 'أبلغني';

  @override
  String get reminderNoticeAhead => 'أخبرني قبل هذا القدر';

  @override
  String reminderNoticeAutomatic(String distance, String days) {
    return 'الفراغ يعني تلقائي — $distance / $days.';
  }

  @override
  String get reminderPriority => 'الأولوية';

  @override
  String get reminderPrioritySafety => 'السلامة';

  @override
  String get reminderPriorityNormal => 'عادية';

  @override
  String get reminderPriorityLow => 'منخفضة';

  @override
  String get reminderRollover => 'عند التكرار، احسب من';

  @override
  String get reminderRolloverActual => 'يوم إنجازه';

  @override
  String get reminderRolloverDue => 'يوم استحقاقه';

  @override
  String get reminderRepeats => 'يتكرر';

  @override
  String get reminderNotes => 'ملاحظات';

  @override
  String get reminderNoScheduleError =>
      'حدّد فاصلًا أو تاريخًا مستهدفًا — وإلا فلا شيء لأذكّرك به.';

  @override
  String get reminderBaselineTooLowError =>
      'هذا أقل من أقدم قراءة لهذه المركبة.';

  @override
  String get reminderBaselineFutureError =>
      'لا يمكن أن يكون العمل قد تم في المستقبل.';

  @override
  String get reminderNameError => 'امنح هذا التذكير اسمًا.';

  @override
  String reminderDeletedSnack(String item) {
    return 'تم حذف $item';
  }

  @override
  String get reminderNotTrackedBanner => 'غير متتبَّع — لن يتم تذكيرك';

  @override
  String get reminderStartTracking => 'ابدأ التتبع';

  @override
  String get reminderTurnBackOn => 'أعد التشغيل';

  @override
  String get reminderTurnThisOff => 'أوقف هذا التذكير';

  @override
  String reminderCannotDelete(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText خدمة مسجلة على هذا. الإيقاف يبقيها.',
      many: '$nText خدمةً مسجلة على هذا. الإيقاف يبقيها.',
      few: '$nText خدمات مسجلة على هذا. الإيقاف يبقيها.',
      two: 'خدمتان مسجلتان على هذا. الإيقاف يبقيهما.',
      one: 'خدمة واحدة مسجلة على هذا. الإيقاف يبقيها.',
      zero: '$nText خدمة مسجلة على هذا. الإيقاف يبقيها.',
    );
    return '$_temp0';
  }

  @override
  String get reminderLastDoneHeading => 'آخر مرات';

  @override
  String get reminderNoticeAheadDays => 'أخبرني قبل هذا القدر — أيام';

  @override
  String get logSegmentFillUp => 'التعبئة';

  @override
  String get logSegmentService => 'الصيانة';

  @override
  String get logSegmentExpense => 'التكلفة';

  @override
  String get logSegmentOdometer => 'العدّاد';

  @override
  String get logEditFillUpTitle => 'تعديل التعبئة';

  @override
  String get logEditServiceTitle => 'تعديل الصيانة';

  @override
  String get logEditExpenseTitle => 'تعديل التكلفة';

  @override
  String get logEditOdometerTitle => 'تعديل القراءة';

  @override
  String get logSavedFillUp => 'تم حفظ التعبئة';

  @override
  String get logSavedService => 'تم حفظ الصيانة';

  @override
  String get logSavedExpense => 'تم حفظ المصروف';

  @override
  String get logSaveFillUp => 'حفظ التعبئة';

  @override
  String get logSaveService => 'حفظ الصيانة';

  @override
  String get logSaveExpense => 'حفظ التكلفة';

  @override
  String get logSaveOdometer => 'حفظ القراءة';

  @override
  String get logDeleteFillUp => 'حذف هذه التعبئة';

  @override
  String get logDeleteService => 'حذف سجل الصيانة هذا';

  @override
  String get logDeleteExpense => 'حذف هذه التكلفة';

  @override
  String get logDeleteOdometer => 'حذف هذه القراءة';

  @override
  String get logDiscardSummary => 'ما كتبته';

  @override
  String get logDateLabel => 'التاريخ';

  @override
  String get logOdometerLabel => 'العدّاد';

  @override
  String get logDateFutureError => 'اختر اليوم أو يومًا مضى.';

  @override
  String get logOdometerRequiredError => 'أدخل قراءة العدّاد.';

  @override
  String logNumberUnclearError(String example) {
    return 'هذا الرقم غير واضح. جرّب $example.';
  }

  @override
  String get logTitleFillUp => 'التعبئة';

  @override
  String get logTitleService => 'الصيانة';

  @override
  String get logTitleExpense => 'التكلفة';

  @override
  String get logTitleOdometer => 'العدّاد';

  @override
  String logOdometerLastEntered(String distance, String date) {
    return 'آخر إدخال $distance في $date';
  }

  @override
  String logOdometerLastEnteredStale(
    int days,
    String distance,
    String date,
    String daysText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'آخر إدخال $distance في $date — قبل $daysText يوم',
      many: 'آخر إدخال $distance في $date — قبل $daysText يومًا',
      few: 'آخر إدخال $distance في $date — قبل $daysText أيام',
      two: 'آخر إدخال $distance في $date — قبل يومين',
      one: 'آخر إدخال $distance في $date — قبل يوم واحد',
      zero: 'آخر إدخال $distance في $date — قبل $daysText يوم',
    );
    return '$_temp0';
  }

  @override
  String logOdometerEstimateChip(String value) {
    return '$value الآن';
  }

  @override
  String logOdometerLastEnteredShort(String distance) {
    return 'آخر إدخال $distance';
  }

  @override
  String logOdometerSinceThen(String distance) {
    return '+$distance منذ ذلك الحين';
  }

  @override
  String logOdometerSince(String date, String distance) {
    return '$date · +$distance';
  }

  @override
  String logOdometerDelta(String distance, String date) {
    return '+$distance منذ $date';
  }

  @override
  String get logOdometerOlderThanAnything =>
      'أقدم من كل ما هو مسجَّل. ستصبح هذه أقدم قراءة لديك.';

  @override
  String get logOdometerBelowLastTitle => 'هذه القراءة أقل من قراءتك الأخيرة';

  @override
  String logOdometerBelowLastBody(String distance, String date) {
    return 'آخر إدخال: $distance في $date.';
  }

  @override
  String get logOdometerBelowLastTypo => 'إنه خطأ مطبعي — سأصحّحه';

  @override
  String get logOdometerBelowLastReplaced =>
      'تم استبدال العدّاد أو أعاد الدوران من الصفر';

  @override
  String get logOdometerBelowLastOlder => 'إنه إدخال أقدم أضيفه الآن';

  @override
  String logOdometerAboveEarliest(String distance, String date, String when) {
    return 'أقدم قراءة لديك هي $distance في $date. وأي قراءة من $when يجب أن تكون أقل من ذلك.';
  }

  @override
  String logOdometerRateWarning(String rate, String date) {
    return 'هذا نحو $rate يوميًا منذ $date. هل هذا صحيح؟';
  }

  @override
  String logOdometerUnitMixUpWarning(String value) {
    return 'هل تقصد $value؟ يبدو هذا بالكيلومترات.';
  }

  @override
  String logOdometerJumpWarning(String distance) {
    return 'هذه قفزة قدرها $distance. هل هذا صحيح؟';
  }

  @override
  String get logOdometerSwitchUnitPrompt =>
      'عرض كل قراءاتك بالكيلومترات من الآن فصاعدًا؟';

  @override
  String get logOdometerUnitChipLabel => 'وحدة هذا الإدخال';

  @override
  String get logOdometerPadClear => 'مسح';

  @override
  String get logOdometerPadBackspace => 'حذف آخر رقم';

  @override
  String get expenseCategoryInsurance => 'التأمين';

  @override
  String get expenseCategoryTaxRegistration => 'رسوم الطريق';

  @override
  String get expenseCategoryParking => 'وقوف السيارات';

  @override
  String get expenseCategoryToll => 'رسوم المرور';

  @override
  String get expenseCategoryFine => 'مخالفة';

  @override
  String get expenseCategoryWash => 'غسيل';

  @override
  String get expenseCategoryTyreStorage => 'تخزين الإطارات';

  @override
  String get expenseCategoryAccessories => 'ملحقات';

  @override
  String get expenseCategoryFinance => 'تمويل';

  @override
  String get expenseCategoryOther => 'أخرى';

  @override
  String get logExpenseCategoryLabel => 'الفئة';

  @override
  String get logExpenseCategoryError => 'اختر الغرض من هذا.';

  @override
  String get logExpenseNameLabel => 'ما هذا؟';

  @override
  String get logExpenseNameError => 'امنح هذه التكلفة اسمًا.';

  @override
  String get logExpenseAmountLabel => 'المبلغ';

  @override
  String get logExpenseAmountError => 'أدخل ما دفعته.';

  @override
  String get logExpenseRefundLabel => 'هذا استرداد';

  @override
  String get logExpenseDatePaidLabel => 'تاريخ الدفع';

  @override
  String get logExpenseCoversLabel => 'يغطي فترة';

  @override
  String get logExpenseCoversFrom => 'من';

  @override
  String get logExpenseCoversTo => 'إلى';

  @override
  String get logExpenseCoversError => 'تاريخ الانتهاء قبل تاريخ البدء.';

  @override
  String get logFillUpQuantityLabel => 'الوقود';

  @override
  String logFillUpPricePerUnitLabel(String unit) {
    return 'السعر/$unit';
  }

  @override
  String get logFillUpTotalLabel => 'المبلغ المدفوع';

  @override
  String get logFillUpFullTank => 'ملأت الخزان';

  @override
  String get logFillUpPartFill => 'تعبئة جزئية';

  @override
  String get logFillUpOverTankWarning =>
      'هذا أكثر مما يتسع له خزانك. سيُحفظ كما أُدخل.';

  @override
  String get logFillUpPartFillHint =>
      'التعبئة الجزئية لا تعطي رقمًا بمفردها. ستُضاف إلى خزانك الممتلئ التالي.';

  @override
  String get logFillUpTrioError =>
      'أدخل كمية الوقود، ثم سعر اللتر أو المبلغ الإجمالي.';

  @override
  String get logFillUpQuantityError => 'يجب أن تكون الكمية أكبر من صفر.';

  @override
  String get logFillUpPriceError => 'لا يمكن أن يكون السعر سالبًا.';

  @override
  String logFillUpTotalError(String zero) {
    return 'لا يمكن أن يكون المبلغ سالبًا. التعبئة المجانية $zero.';
  }

  @override
  String get logFillUpFirstEver =>
      'سيصل أول رقم استهلاك عند التعبئة الكاملة القادمة.';

  @override
  String get logServiceWhatWasDone => 'ما الذي تم عمله';

  @override
  String get logServiceTickResets => 'وضع علامة يعيد ضبط التذكير.';

  @override
  String get logServiceOther => '+ أخرى';

  @override
  String get logServiceCostLabel => 'التكلفة';

  @override
  String get logServiceSplit => 'تقسيم التكلفة حسب البند';

  @override
  String logServiceCostError(String zero) {
    return 'لا يمكن أن تكون التكلفة سالبة. العمل تحت الضمان $zero.';
  }

  @override
  String logServiceCostEmptyError(String zero) {
    return 'أدخل التكلفة، أو $zero.';
  }

  @override
  String get logServiceGenericLine => 'الصيانة';

  @override
  String get logMoreRow => 'المزيد';

  @override
  String get logMoreFillUpSummary => 'المحطة · النوع · الرحلة';

  @override
  String get logMoreServiceSummary => 'الورشة · الفاتورة';

  @override
  String get logMoreExpenseSummary => 'دُفع إلى · ملاحظات';

  @override
  String get logFillUpStation => 'المحطة';

  @override
  String get logFillUpGrade => 'النوع';

  @override
  String get logFillUpChainBroken => 'لم أسجّل تعبئة سابقة';

  @override
  String get logFillUpChainBrokenHint =>
      'تبدأ أرقام استهلاكك من جديد بهذه التعبئة.';

  @override
  String get logServiceWorkshop => 'الورشة';

  @override
  String get logServiceInvoice => 'رقم الفاتورة';

  @override
  String get logNotes => 'ملاحظات';

  @override
  String get logExpensePaidTo => 'دُفع إلى';

  @override
  String logDoneTitle(String item) {
    return 'تم $item';
  }

  @override
  String logDoneNextBoth(String odometer, String date) {
    return 'الاستحقاق التالي عند $odometer أو $date — أيهما أقرب';
  }

  @override
  String logDoneNextDistance(String odometer) {
    return 'الاستحقاق التالي عند $odometer';
  }

  @override
  String logDoneNextDate(String date) {
    return 'الاستحقاق التالي $date';
  }

  @override
  String get logDoneClose => 'إغلاق';

  @override
  String deleteFillUpRecalculated(String segment) {
    return 'حذف عملية التعبئة هذه؟ ستُعاد حساب قيمة الاستهلاك لـ $segment.';
  }

  @override
  String deleteFillUpFiguresRemoved(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حذف عملية التعبئة هذه؟ ستُحذف $nText قيمة استهلاك.',
      many: 'حذف عملية التعبئة هذه؟ ستُحذف $nText قيمةً استهلاك.',
      few: 'حذف عملية التعبئة هذه؟ ستُحذف $nText قيم استهلاك.',
      two: 'حذف عملية التعبئة هذه؟ ستُحذف قيمتا استهلاك.',
      one: 'حذف عملية التعبئة هذه؟ ستُحذف قيمة استهلاك واحدة.',
      zero: 'حذف عملية التعبئة هذه؟ ستُحذف $nText قيمة استهلاك.',
    );
    return '$_temp0';
  }

  @override
  String get deleteFillUpPlain => 'حذف عملية التعبئة هذه؟';

  @override
  String deleteServiceResets(String items) {
    return 'حذف هذه الصيانة؟ ستعود $items إلى الاستحقاق من الصيانة السابقة.';
  }

  @override
  String get deleteServicePlain => 'حذف هذه الصيانة؟';

  @override
  String deleteTripKeepsCosts(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'حذف هذه الرحلة؟ ستبقى $nText نفقة — لكنها لن ترتبط برحلة بعد الآن.',
      many:
          'حذف هذه الرحلة؟ ستبقى $nText نفقةً — لكنها لن ترتبط برحلة بعد الآن.',
      few:
          'حذف هذه الرحلة؟ ستبقى $nText نفقات — لكنها لن ترتبط برحلة بعد الآن.',
      two: 'حذف هذه الرحلة؟ ستبقى نفقتاها — لكنهما لن ترتبطا برحلة بعد الآن.',
      one:
          'حذف هذه الرحلة؟ ستبقى نفقتها الواحدة — لكنها لن ترتبط برحلة بعد الآن.',
      zero:
          'حذف هذه الرحلة؟ ستبقى $nText نفقة — لكنها لن ترتبط برحلة بعد الآن.',
    );
    return '$_temp0';
  }

  @override
  String get deleteTripPlain => 'حذف هذه الرحلة؟';

  @override
  String get deleteReadingPlain => 'حذف هذه القراءة؟';

  @override
  String get deleteExpensePlain => 'حذف هذه النفقة؟';

  @override
  String deleteBlockedOnlyReading(String vehicle) {
    return 'هذه هي قراءة العداد الوحيدة لـ $vehicle. كل سيارة تحتاج إلى واحدة.';
  }

  @override
  String deleteBlockedStartsCorrection(String date) {
    return 'تبدأ هذه القراءة تصحيحًا للعداد من $date. احذف التصحيح أولًا.';
  }

  @override
  String get listSeparator => '، ';

  @override
  String listPairJoin(String head, String last) {
    return '$head و$last';
  }

  @override
  String get reportTitle => 'تقرير الصيانة';

  @override
  String get reportIncludeHeading => 'تضمين في المستند';

  @override
  String get reportToggleCosts => 'التكاليف';

  @override
  String get reportToggleFuel => 'ملخص الوقود';

  @override
  String get reportTogglePlateVin => 'اللوحة ورقم الهيكل';

  @override
  String get reportToggleNotes => 'ملاحظاتي الخاصة';

  @override
  String get reportNotesWarning =>
      'قد تحتوي ملاحظاتك على أشياء لا تريد أن يقرأها المشتري.';

  @override
  String get reportSharePdf => 'مشاركة PDF';

  @override
  String get reportCopyAsText => 'نسخ كنص';

  @override
  String get reportPaperSize => 'حجم الورق';

  @override
  String get reportEmptyTitle => 'لم تُسجَّل أي صيانة بعد';

  @override
  String get reportEmptyBody =>
      'يصبح هذا التقرير ذا قيمة بمجرد أن تبدأ بإضافتها.';

  @override
  String get reportShareDisabledReason => 'لا توجد صيانات لوضعها في تقرير بعد.';

  @override
  String reportOwnedSince(String date) {
    return 'مملوكة منذ $date';
  }

  @override
  String reportGeneratedFooter(String date, String iso) {
    return 'أُنشئ بواسطة Odova في $date ($iso) من سجلات يحتفظ بها المالك. غير مُوثَّق من طرف ثالث.';
  }

  @override
  String get reportEstimatedFootnote =>
      '~ العداد مُقدَّر في حينه، ولم يُقرأ من السيارة.';

  @override
  String get reportNoRecordHeading => 'لا يوجد سجل في هذا التطبيق';

  @override
  String reportServiceCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText صيانة',
      many: '$nText صيانةً',
      few: '$nText صيانات',
      two: 'صيانتان',
      one: 'صيانة واحدة',
      zero: '$nText صيانة',
    );
    return '$_temp0';
  }

  @override
  String reportOwnershipSpan(String years, String months) {
    return '$years سنة $months شهر';
  }

  @override
  String reportInvoiceRef(String ref) {
    return 'فاتورة $ref';
  }

  @override
  String reportOdometerSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String get reportColumnDate => 'التاريخ';

  @override
  String get reportColumnOdometer => 'العداد';

  @override
  String get reportColumnWork => 'العمل المُنجز';

  @override
  String get reportColumnCost => 'التكلفة';

  @override
  String reportPageOf(String n, String total) {
    return 'صفحة $n من $total';
  }

  @override
  String get reportOwnedLabel => 'مملوكة';

  @override
  String get reportServicesLabel => 'صيانات';

  @override
  String get costsTitle => 'التكاليف';

  @override
  String get costsRangeThisYear => 'هذا العام';

  @override
  String get costsRangeAll => 'الكل';

  @override
  String get costsPerMonth => 'شهريًا';

  @override
  String get costsWhereMoneyGoes => 'أين تذهب الأموال';

  @override
  String get costsAccrualNote =>
      'تُوزَّع التكاليف السنوية مثل التأمين على الأشهر التي تغطيها.';

  @override
  String costsThisMonthSoFar(String amount) {
    return 'هذا الشهر حتى الآن: $amount';
  }

  @override
  String get costsEmptyTitle => 'لا توجد تكاليف بعد.';

  @override
  String get costsEmptyAction => 'سجّل شيئًا';

  @override
  String get costsCategoryFuel => 'الوقود';

  @override
  String get costsCategoryService => 'الصيانة والإصلاحات';

  @override
  String get costsCategoryInsuranceTax => 'التأمين والضريبة';

  @override
  String get costsCategoryFinance => 'التمويل';

  @override
  String get costsCategoryParkingTolls => 'مواقف ورسوم';

  @override
  String get costsCategoryOther => 'أخرى';

  @override
  String get costsFuelRow => 'الوقود والاستهلاك';

  @override
  String get costsTripsRow => 'الرحلات';

  @override
  String get costsNoCompletedMonth =>
      'عُد بعد نهاية الشهر — لا يوجد شهر كامل للمتوسط بعد.';

  @override
  String get costsNotEnoughDistance =>
      'لم تُسجَّل مسافة كافية في هذه الفترة لحساب التكلفة لكل كيلومتر.';

  @override
  String costsBoundaryStale(String days) {
    return 'حُسب من قراءات عداد تبعد $days يومًا عن التواريخ المعروضة.';
  }

  @override
  String get costsUpdateOdometer => 'تحديث العداد';

  @override
  String costsRangeMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText شهر',
      many: '$nText شهرًا',
      few: '$nText أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: '$nText شهر',
    );
    return '$_temp0';
  }

  @override
  String costsHeadlineCaption(String vehicle, String range) {
    return '$vehicle · $range';
  }

  @override
  String get costsRangeThisYearSoFar => 'هذا العام حتى الآن';

  @override
  String costsSpanCaption(String from, String to) {
    return '$from – $to';
  }

  @override
  String costsPerKilometre(String amount) {
    return '$amount لكل كيلومتر';
  }

  @override
  String costsPerMile(String amount) {
    return '$amount لكل ميل';
  }

  @override
  String costsInMonths(int n, String nText, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$amount في $nText شهر',
      many: '$amount في $nText شهرًا',
      few: '$amount في $nText أشهر',
      two: '$amount في شهرين',
      one: '$amount في شهر واحد',
      zero: '$amount في $nText شهر',
    );
    return '$_temp0';
  }

  @override
  String get costsAllVehicles => 'كل المركبات';

  @override
  String get costsIncludeInactive => 'تضمين المباعة والمؤرشفة';

  @override
  String costsHiddenVehicles(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مركبة مخفية',
      many: '$nText مركبةً مخفية',
      few: '$nText مركبات مخفية',
      two: 'مركبتان مخفيتان',
      one: 'مركبة واحدة مخفية',
      zero: '$nText مركبة مخفية',
    );
    return '$_temp0';
  }

  @override
  String costsBusinessRow(String share, String amount) {
    return 'عمل $share٪ · $amount';
  }

  @override
  String get costsBusinessCaption =>
      'محسوب من الرحلات التي سجّلتها، وليس من كل قيادتك.';

  @override
  String get costsVehicleSold => 'مباعة';

  @override
  String get costsVehicleArchived => 'مؤرشفة';

  @override
  String get fuelTitle => 'الوقود والاستهلاك';

  @override
  String get fuelConsumptionPerTank => 'الاستهلاك لكل خزان';

  @override
  String get fuelEmptyTitle => 'لا توجد عمليات تعبئة بعد.';

  @override
  String get fuelEmptyAction => 'سجّل تعبئة';

  @override
  String get fuelFirstFigure => 'سيظهر أول رقم لك عند التعبئة الكاملة القادمة.';

  @override
  String get tripsTitle => 'الرحلات';

  @override
  String get tripsEmptyTitle => 'لا توجد رحلات بعد.';

  @override
  String get tripsEmptyBody => 'سجّل واحدة لترى كم تكلف الرحلة.';

  @override
  String get tripsAddAction => 'إضافة رحلة';

  @override
  String get tripsOpenBadge => 'مفتوحة';

  @override
  String get tripsFinishAction => 'إنهاء هذه الرحلة';

  @override
  String get tripsPurposeBusiness => 'عمل';

  @override
  String get tripsPurposeCommute => 'تنقل';

  @override
  String get tripsPurposePersonal => 'شخصي';

  @override
  String get tripsPurposeOther => 'أخرى';

  @override
  String tripsLoggedLabel(String unit) {
    return '$unit مسجلة';
  }

  @override
  String get tripsBusinessLabel => 'عمل';

  @override
  String get tripsCostsLabel => 'تكاليف الرحلات';

  @override
  String get tripsEarlier => 'سابقًا';

  @override
  String tripsCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText رحلة',
      many: '$nText رحلةً',
      few: '$nText رحلات',
      two: 'رحلتان',
      one: 'رحلة واحدة',
      zero: 'لا رحلات',
    );
    return '$_temp0';
  }

  @override
  String tripsStartedFrom(String date, String odometer) {
    return 'بدأت $date · من $odometer';
  }

  @override
  String tripsStartedOn(String date) {
    return 'بدأت $date';
  }

  @override
  String get tripsNoEndReading => 'لا قراءة نهاية بعد';

  @override
  String tripsBusinessValue(String percent) {
    return '$percent%';
  }

  @override
  String get tripEditTitle => 'تعديل الرحلة';

  @override
  String get tripNewTitle => 'رحلة';

  @override
  String get tripSaveAction => 'حفظ الرحلة';

  @override
  String get tripPurposeLabel => 'الغرض';

  @override
  String get tripTitleLabel => 'العنوان';

  @override
  String get tripStartsLabel => 'يبدأ';

  @override
  String get tripEndsLabel => 'ينتهي';

  @override
  String get tripStillGoing => 'ما زالت جارية';

  @override
  String get tripStartOdometerLabel => 'عداد البداية';

  @override
  String get tripEndOdometerLabel => 'عداد النهاية';

  @override
  String get tripDistanceLabel => 'المسافة';

  @override
  String get tripExpensesLabel => 'المصروفات';

  @override
  String get tripAddExpense => 'إضافة مصروف';

  @override
  String get tripNoExpenses => 'لم يُحمّل شيء على هذه الرحلة بعد.';

  @override
  String get tripDeleteAction => 'حذف الرحلة';

  @override
  String get tripStartInFuture => 'اختر اليوم أو يومًا مضى.';

  @override
  String get tripEndBeforeStart => 'تاريخ النهاية قبل تاريخ البداية.';

  @override
  String get tripEndBelowStart => 'قراءة النهاية أقل من قراءة البداية.';

  @override
  String get tripDistanceNotPositive => 'يجب أن تكون المسافة أكبر من صفر.';

  @override
  String get tripSavedToast => 'تم حفظ الرحلة';

  @override
  String get tripSaveFirstToAddExpense =>
      'احفظ الرحلة أولًا، ثم حمّل عليها المصروفات.';

  @override
  String get costsEstimateTitle => 'كيف حُسب هذا';

  @override
  String costsEstimateStaleBoundary(String days) {
    return 'حُسب من قراءات عداد تبعد $days يومًا عن التواريخ المعروضة.';
  }

  @override
  String get costsEstimateNotEnoughDistance =>
      'لم تُسجَّل مسافة كافية في هذه الفترة لحساب التكلفة لكل كيلومتر.';

  @override
  String get costsEstimateNoCompletedMonth =>
      'عد بعد نهاية الشهر — لا يوجد شهر كامل للمتوسط بعد.';

  @override
  String get costsEstimateNoReadings =>
      'لا توجد قراءات عداد في هذه الفترة للقياس بينها.';

  @override
  String get fuelEmptyBody => 'يظهر أول رقم استهلاك عند ثاني خزان ممتلئ.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsBackupRow => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsBackupNever => 'لم تنشئ نسخة احتياطية قط.';

  @override
  String settingsBackupLast(String date, String ago) {
    return 'آخر نسخة احتياطية $date — $ago';
  }

  @override
  String get settingsBackupMigrationFailed =>
      'لم تتمكن أودوفا من إكمال التحديث.';

  @override
  String get settingsVehiclesRow => 'المركبات';

  @override
  String settingsVehicleCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مركبةٍ',
      many: '$nText مركبةً',
      few: '$nText مركبات',
      two: 'مركبتان',
      one: 'مركبة واحدة',
      zero: '$nText مركبةٍ',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnitsRow => 'الوحدات والتنسيقات';

  @override
  String get settingsNotificationsRow => 'الإشعارات';

  @override
  String settingsNotificationsValue(String state, String time) {
    return '$state · $time';
  }

  @override
  String get settingsNotificationsOn => 'مفعّل';

  @override
  String get settingsNotificationsOff => 'معطّل';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsAboutRow => 'حول';

  @override
  String get settingsLanguageRow => 'اللغة';

  @override
  String get settingsLanguageNote =>
      'أودوفا مترجمة إلى هذه اللغات الست. تُضبط الأرقام والتواريخ والوحدات على حدة ضمن «الوحدات والتنسيقات».';

  @override
  String get unitsPreviewLabel => 'معاينة';

  @override
  String get unitsGroupMeasurement => 'القياس';

  @override
  String get unitsGroupDatesNumbers => 'التواريخ والأرقام';

  @override
  String get unitsRowDistance => 'المسافة';

  @override
  String get unitsRowVolume => 'الحجم';

  @override
  String get unitsRowConsumption => 'الاستهلاك';

  @override
  String get unitsRowCurrency => 'العملة';

  @override
  String get unitsRowCalendar => 'التقويم';

  @override
  String get unitsRowNumerals => 'الأرقام';

  @override
  String get unitsRowFirstDay => 'أول أيام الأسبوع';

  @override
  String get unitsDistanceKm => 'كيلومترات (كم)';

  @override
  String get unitsDistanceMi => 'أميال (ميل)';

  @override
  String get unitsVolumeLitre => 'لترات (ل)';

  @override
  String get unitsVolumeGalUs => 'جالونات أمريكية';

  @override
  String get unitsVolumeGalUk => 'جالونات إمبراطورية';

  @override
  String get unitsCalendarGregorian => 'ميلادي';

  @override
  String get unitsCalendarPersian => 'هجري شمسي';

  @override
  String get unitsNumeralsAuto => 'تلقائي';

  @override
  String unitsNumeralsLatin(String digits) {
    return 'لاتينية ($digits)';
  }

  @override
  String unitsNumeralsLocal(String digits) {
    return 'محلية ($digits)';
  }

  @override
  String unitsConsumptionSuggested(String distance, String volume) {
    return 'مقترح لـ $distance و$volume';
  }

  @override
  String get unitsFooter =>
      'تغيّر هذه طريقة عرض سجلاتك فقط. لا يُعدَّل شيء أدخلته من قبل.';

  @override
  String get unitsCurrencyRecent => 'الأخيرة';

  @override
  String get unitsCurrencyAll => 'كل العملات';

  @override
  String get unitsCurrencySearch => 'البحث عن عملة';

  @override
  String get commonSeparator => ' · ';

  @override
  String get notifGroupWhat => 'ما ترسله أودوفا';

  @override
  String get notifGroupWhen => 'متى';

  @override
  String get notifGroupHowFar => 'قبل بكم';

  @override
  String get notifAllowed => 'مسموح';

  @override
  String get notifRowService => 'تذكيرات الصيانة';

  @override
  String get notifRowOdometer => 'تسجيل قراءة العداد';

  @override
  String get notifRowBackup => 'تذكيرات النسخ الاحتياطي';

  @override
  String get notifRowTimeOfDay => 'وقت اليوم';

  @override
  String get notifRowQuietHours => 'ساعات الهدوء';

  @override
  String get notifRowByDistance => 'حسب المسافة';

  @override
  String get notifRowByTime => 'حسب الوقت';

  @override
  String get notifAutomatic => 'تلقائي';

  @override
  String notifAutomaticNote(String percent) {
    return 'التلقائي يعني نحو $percent٪ قبل الاستحقاق.';
  }

  @override
  String get notifCapFooter =>
      'إشعاران في الأسبوع على الأكثر. ولا إشعاران في يوم واحد أبدًا.';

  @override
  String get notifQuietOff => 'معطّلة';

  @override
  String get notifOffTitle => 'التذكيرات معطّلة.';

  @override
  String get notifOffAction => 'تفعيل التذكيرات';

  @override
  String get notifBlockedTitle =>
      'لا تستطيع أودوفا إرسال التذكيرات لأن الإشعارات معطّلة لأودوفا في إعدادات هاتفك.';

  @override
  String get notifBlockedAction => 'فتح إعدادات الهاتف';

  @override
  String get notifBackgroundTitle => 'قد يمنع هاتفك تذكيرات أودوفا.';

  @override
  String get notifSilentFooter =>
      'لن ترسل لك أودوفا شيئًا. ما هو مستحق يظل ظاهرًا على الشاشة الرئيسية.';

  @override
  String get notifRowCalendar => 'إضافة التذكيرات إلى تقويمي';

  @override
  String get aboutPrivacy =>
      'بلا حساب. بلا تسجيل. بلا خادم. لا يُرفع شيء. بلا تتبّع، بلا تحليلات، بلا إعلانات.';

  @override
  String get aboutBackupWarning =>
      'سجلاتك موجودة على هذا الهاتف فقط. إن فقدته دون نسخة احتياطية، فقدتها معه.';

  @override
  String aboutVersion(String version, String build) {
    return 'الإصدار $version ($build)';
  }

  @override
  String aboutBackupFormat(String format) {
    return 'تنسيق النسخ الاحتياطي $format';
  }

  @override
  String get aboutLicencesRow => 'تراخيص المصادر المفتوحة';

  @override
  String get unitConsumptionMpgUs => 'ميل/جالون أمريكي';

  @override
  String get unitConsumptionMpgUk => 'ميل/جالون إمبراطوري';

  @override
  String get commonListSeparator => '، ';

  @override
  String importFailTooLarge(String size) {
    return 'هذا الملف أكبر من أن يكون نسخة احتياطية لـ Odova ($size). حتى عقد كامل من السجلات لا يتجاوز بضعة ميجابايت، فربما يكون ملفًا آخر.';
  }

  @override
  String get importFailCompressed =>
      'هذا الملف مضغوط. فُكَّ ضغطه أولاً، ثم استورد ملف json. الموجود بداخله.';

  @override
  String get importFailNotUtf8 =>
      'لا يستطيع Odova قراءة النص في هذا الملف. ربما غيّره برنامج آخر. جرّب الملف الأصلي الذي صدّرته.';

  @override
  String get importFailTruncated =>
      'هذا الملف غير مكتمل. ربما لم يكتمل تنزيله أو نسخه. احصل على الملف مرة أخرى ثم حاول مجددًا.';

  @override
  String get importFailNotOdova =>
      'هذا الملف ليس نسخة احتياطية من Odova. نسخ Odova هي ملفات json. تُنشَأ من الإعدادات، قسم التصدير. اختر ملفًا آخر.';

  @override
  String get importFailNotMadeByOdova =>
      'لم يُنشئ هذا الملف بواسطة Odova. الملف سليم، لكن Odova لا يستطيع قراءته. لم يتغير شيء على هاتفك.';

  @override
  String get importFailTooNew =>
      'أُنشئت هذه النسخة بإصدار أحدث من Odova. حدّث Odova ثم استوردها من جديد. لم يتغير ملفك.';

  @override
  String get importFailDamagedVersion =>
      'ملف النسخة هذا تالف ولا يستطيع Odova معرفة إصداره. إن كانت لديك نسخة أخرى أو نسخة أقدم، فجرّبها.';

  @override
  String get importFailDamagedFile =>
      'ملف النسخة هذا تالف ولا يستطيع Odova قراءة محتواه. إن كانت لديك نسخة أخرى أو نسخة أقدم، فجرّبها.';

  @override
  String get importFailCannotOpen =>
      'تعذّر على Odova فتح ذلك الملف. انسخه أولاً إلى تطبيق الملفات في هاتفك، ثم استورده من هناك.';

  @override
  String importFailNotEnoughSpace(String size) {
    return 'لا توجد مساحة كافية على هاتفك لاستيراد هذه النسخة. فرّغ نحو $size ثم حاول مجددًا.';
  }

  @override
  String importFailTooDamaged(String readable, String total) {
    return 'جزء كبير من هذه النسخة تالف ولا يمكن استيرادها بأمان. تمكّن Odova من قراءة $readable من أصل $total سجل، واستيراد جزء من سجلك سيترك فجوات. جرّب نسخة أقدم إن كانت لديك. لم يتغير شيء على هاتفك.';
  }

  @override
  String get importWarnContentHash =>
      'عُدِّل هذا الملف بعد أن حفظه Odova. لا بأس إن كنت غيّرته عمدًا. راجع الأرقام أدناه قبل المتابعة.';

  @override
  String importWarnRecordCount(String declared, String found) {
    return 'لا يحتوي هذا الملف على كل ما يذكره — يشير إلى $declared سجل وعُثر على $found. ربما اقتُطع. راجع الأرقام أدناه.';
  }

  @override
  String get importWarnMissingArray =>
      'جزء من هذه النسخة مفقود. سيُستورد كل ما تمكّن Odova من إيجاده.';

  @override
  String importWarnSkipped(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'تعذّرت قراءة $nText سجل ولن تُستورد. سيُستورد كل ما عداها. اضغط لمعرفتها.',
      many:
          'تعذّرت قراءة $nText سجلًا ولن تُستورد. سيُستورد كل ما عداها. اضغط لمعرفتها.',
      few:
          'تعذّرت قراءة $nText سجلات ولن تُستورد. سيُستورد كل ما عداها. اضغط لمعرفتها.',
      two:
          'تعذّرت قراءة سجلَّين ولن يُستورَدا. سيُستورد كل ما عداهما. اضغط لمعرفتهما.',
      one:
          'تعذّرت قراءة سجل واحد ولن يُستورد. سيُستورد كل ما عداه. اضغط لمعرفته.',
      zero:
          'تعذّرت قراءة $nText سجل ولن تُستورد. سيُستورد كل ما عداها. اضغط لمعرفتها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnOrphans(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText سجل لا يذكر المركبة التي يتبعها. ستُستورد تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبها أو حذفها.',
      many:
          '$nText سجلًا لا تذكر المركبة التي تتبعها. ستُستورد تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبها أو حذفها.',
      few:
          '$nText سجلات لا تذكر المركبة التي تتبعها. ستُستورد تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبها أو حذفها.',
      two:
          'سجلان لا يذكران المركبة التي يتبعانها. سيُستورَدان تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبهما أو حذفهما.',
      one:
          'سجل واحد لا يذكر المركبة التي يتبعها. سيُستورد تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبه أو حذفه.',
      zero:
          '$nText سجل لا يذكر المركبة التي يتبعها. ستُستورد تحت مركبة باسم «سجلات مستردة» لتتمكن من ترتيبها أو حذفها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnUnmatchedCorrections(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'تعذّر مطابقة $nText تصحيح للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفتها.',
      many:
          'تعذّر مطابقة $nText تصحيحًا للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفتها.',
      few:
          'تعذّر مطابقة $nText تصحيحات للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفتها.',
      two:
          'تعذّر مطابقة تصحيحَين للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفتهما.',
      one:
          'تعذّر مطابقة تصحيح واحد للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفته.',
      zero:
          'تعذّر مطابقة $nText تصحيح للعدّاد بأي قراءة. قد يبدو سجل مسافاتك خاطئًا حيث استُبدل العدّاد. اضغط لمعرفتها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnDroppedRules(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'استخدم $nText تذكير إعدادًا لم يعد في Odova. صارت تنبّهك عند الأسبق — راجعها في التذكيرات.',
      many:
          'استخدم $nText تذكيرًا إعدادًا لم يعد في Odova. صارت تنبّهك عند الأسبق — راجعها في التذكيرات.',
      few:
          'استخدمت $nText تذكيرات إعدادًا لم يعد في Odova. صارت تنبّهك عند الأسبق — راجعها في التذكيرات.',
      two:
          'استخدم تذكيران إعدادًا لم يعد في Odova. صارا ينبّهانك عند الأسبق — راجعهما في التذكيرات.',
      one:
          'استخدم تذكير واحد إعدادًا لم يعد في Odova. صار ينبّهك عند الأسبق — راجعه في التذكيرات.',
      zero:
          'استخدم $nText تذكير إعدادًا لم يعد في Odova. صارت تنبّهك عند الأسبق — راجعها في التذكيرات.',
    );
    return '$_temp0';
  }

  @override
  String importWarnCoercedEnums(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'استخدم $nText سجل إعدادات لا يعرفها Odova. استُوردت بإعدادات Odova بدلاً منها.',
      many:
          'استخدم $nText سجلًا إعدادات لا يعرفها Odova. استُوردت بإعدادات Odova بدلاً منها.',
      few:
          'استخدمت $nText سجلات إعدادات لا يعرفها Odova. استُوردت بإعدادات Odova بدلاً منها.',
      two:
          'استخدم سجلان إعدادًا لا يعرفه Odova. استُورِدا بإعداد Odova بدلاً منه.',
      one:
          'استخدم سجل واحد إعدادًا لا يعرفه Odova. استُورد بإعداد Odova بدلاً منه.',
      zero:
          'استخدم $nText سجل إعدادات لا يعرفها Odova. استُوردت بإعدادات Odova بدلاً منها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnOutOfRangeDates(int n, String nText, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'لدى $nText سجل تواريخ تبدو خاطئة — قبل $year أو بعد إنشاء هذه النسخة. استُوردت لتتمكن من تصحيحها.',
      many:
          'لدى $nText سجلًا تواريخ تبدو خاطئة — قبل $year أو بعد إنشاء هذه النسخة. استُوردت لتتمكن من تصحيحها.',
      few:
          'لدى $nText سجلات تواريخ تبدو خاطئة — قبل $year أو بعد إنشاء هذه النسخة. استُوردت لتتمكن من تصحيحها.',
      two:
          'لدى سجلَّين تاريخان يبدوان خاطئَين — قبل $year أو بعد إنشاء هذه النسخة. استُورِدا لتتمكن من تصحيحهما.',
      one:
          'لدى سجل واحد تاريخ يبدو خاطئًا — قبل $year أو بعد إنشاء هذه النسخة. استُورد لتتمكن من تصحيحه.',
      zero:
          'لدى $nText سجل تواريخ تبدو خاطئة — قبل $year أو بعد إنشاء هذه النسخة. استُوردت لتتمكن من تصحيحها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnUnresolvedLinks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'أشار $nText سجل إلى رحلة أو تذكير غير موجود في هذا الملف. استُوردت بدونه.',
      many:
          'أشار $nText سجلًا إلى رحلة أو تذكير غير موجود في هذا الملف. استُوردت بدونه.',
      few:
          'أشارت $nText سجلات إلى رحلة أو تذكير غير موجود في هذا الملف. استُوردت بدونه.',
      two:
          'أشار سجلان إلى رحلة أو تذكير غير موجود في هذا الملف. استُورِدا بدونه.',
      one:
          'أشار سجل واحد إلى رحلة أو تذكير غير موجود في هذا الملف. استُورد بدونه.',
      zero:
          'أشار $nText سجل إلى رحلة أو تذكير غير موجود في هذا الملف. استُوردت بدونه.',
    );
    return '$_temp0';
  }

  @override
  String importWarnDuplicateIds(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'يذكر هذا الملف $nText سجل مرتين. سيستورد Odova النسخة الأولى من كل منها.',
      many:
          'يذكر هذا الملف $nText سجلًا مرتين. سيستورد Odova النسخة الأولى من كل منها.',
      few:
          'يذكر هذا الملف $nText سجلات مرتين. سيستورد Odova النسخة الأولى من كل منها.',
      two:
          'يذكر هذا الملف سجلَّين مرتين. سيستورد Odova النسخة الأولى من كل منهما.',
      one: 'يذكر هذا الملف سجلاً واحدًا مرتين. سيستورد Odova النسخة الأولى.',
      zero:
          'يذكر هذا الملف $nText سجل مرتين. سيستورد Odova النسخة الأولى من كل منها.',
    );
    return '$_temp0';
  }

  @override
  String importWarnTruncatedStrings(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'كانت $nText ملاحظة طويلة جدًا فاختُصرت.',
      many: 'كانت $nText ملاحظةً طويلة جدًا فاختُصرت.',
      few: 'كانت $nText ملاحظات طويلة جدًا فاختُصرت.',
      two: 'كانت ملاحظتان طويلتين جدًا فاختُصرتا.',
      one: 'كانت ملاحظة واحدة طويلة جدًا فاختُصرت.',
      zero: 'كانت $nText ملاحظة طويلة جدًا فاختُصرت.',
    );
    return '$_temp0';
  }

  @override
  String importSuccess(String vehicles, String records) {
    return 'تم الاستيراد. استُعيدت $vehicles و$records. أُعيد حساب تذكيراتك.';
  }

  @override
  String importRecordCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText سجل',
      many: '$nText سجلًا',
      few: '$nText سجلات',
      two: 'سجلان',
      one: 'سجل واحد',
      zero: '$nText سجل',
    );
    return '$_temp0';
  }

  @override
  String get importRecoveredVehicleName => 'سجلات مستردة';

  @override
  String get importTypeVehicle => 'مركبة';

  @override
  String get importTypeReminder => 'تذكير';

  @override
  String get importTypeReading => 'قراءة العدّاد';

  @override
  String get importTypeCorrection => 'تصحيح العدّاد';

  @override
  String get importTypeFillup => 'تعبئة وقود';

  @override
  String get importTypeService => 'صيانة';

  @override
  String get importTypeExpense => 'مصروف';

  @override
  String get importTypeTrip => 'رحلة';

  @override
  String get importSkipDate => 'كان التاريخ مفقودًا';

  @override
  String get importSkipFuel => 'كانت كمية الوقود مفقودة';

  @override
  String get importSkipMoney => 'كان المبلغ مفقودًا';

  @override
  String get importSkipCurrency => 'لم تكن العملة معروفة لدى Odova';

  @override
  String get importSkipCorrection =>
      'القراءة التي يصححها غير موجودة في هذا الملف';

  @override
  String get importSkipIncomplete => 'كان جزء منه مفقودًا';

  @override
  String importSkipEntry(String type, String date, String reason) {
    return '$type، $date — $reason';
  }

  @override
  String importSkipEntryNoDate(String type, String reason) {
    return '$type — $reason';
  }

  @override
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupLastLabel => 'آخر نسخة احتياطية';

  @override
  String get backupNever => 'لم تُنشئ نسخة احتياطية من قبل.';

  @override
  String backupEntriesSince(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText إدخال منذ ذلك الحين',
      many: '$nText إدخالًا منذ ذلك الحين',
      few: '$nText إدخالات منذ ذلك الحين',
      two: 'إدخالان منذ ذلك الحين',
      one: 'إدخال واحد منذ ذلك الحين',
      zero: '$nText إدخال منذ ذلك الحين',
    );
    return '$_temp0';
  }

  @override
  String backupEntriesOnlyHere(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText إدخال موجود على هذا الهاتف فقط.',
      many: '$nText إدخالًا موجودة على هذا الهاتف فقط.',
      few: '$nText إدخالات موجودة على هذا الهاتف فقط.',
      two: 'إدخالان موجودان على هذا الهاتف فقط.',
      one: 'إدخال واحد موجود على هذا الهاتف فقط.',
      zero: '$nText إدخال موجود على هذا الهاتف فقط.',
    );
    return '$_temp0';
  }

  @override
  String get backupNow => 'أنشئ نسخة الآن';

  @override
  String get backupNothingToBackUp => 'لا شيء لحفظه بعد.';

  @override
  String get backupPreparing => 'يجري تجهيز نسختك…';

  @override
  String get backupNotEncrypted =>
      'ملف نسختك الاحتياطية غير محمي بكلمة مرور. أي شخص يفتحه يستطيع قراءة كل ما فيه.';

  @override
  String get backupAlsoExport => 'تصدير أيضًا';

  @override
  String get backupFillUpsCsv => 'تعبئات الوقود (CSV)';

  @override
  String get backupAllCostsCsv => 'كل التكاليف (CSV)';

  @override
  String get backupServiceHistoryPdf => 'سجل الصيانة (PDF)';

  @override
  String get backupRestoreHeader => 'استعادة';

  @override
  String get backupRestoreRow => 'الاستعادة من نسخة احتياطية';

  @override
  String get backupUndoImport => 'التراجع عن آخر استيراد';

  @override
  String get backupUndoWipe => 'التراجع عن حذف كل البيانات';

  @override
  String backupUndoUntil(String date) {
    return 'حتى $date';
  }

  @override
  String get backupCopiesGoOnUninstall => 'تُحذف هذه النسخ إذا أزلت Odova.';

  @override
  String backupOnDiskSize(String size) {
    return 'يستخدم Odova $size على هذا الهاتف.';
  }

  @override
  String get backupDeleteAll => 'حذف كل البيانات';

  @override
  String get backupDeleteWord => 'حذف';

  @override
  String get backupMigrationBanner =>
      'لم يتمكن Odova من إكمال التحديث وعاد إلى بياناتك السابقة. لا يمكنك إضافة إدخالات جديدة حتى يُحل هذا — أنشئ نسخة احتياطية الآن.';

  @override
  String backupExportNoSpace(String size) {
    return 'لا توجد مساحة كافية لإنشاء نسخة احتياطية. تلزم نحو $size. فرّغ بعض المساحة ثم حاول مجددًا.';
  }

  @override
  String get backupExportWriteFailed =>
      'لم يتمكن Odova من إكمال النسخة الاحتياطية. لم يتغير شيء على هذا الهاتف. حاول بعد قليل.';

  @override
  String get backupExportNoShare =>
      'لا يسمح هذا الهاتف لـ Odova بتسليم الملف إلى تطبيق آخر. بياناتك بأمان — أعد تشغيل الهاتف ثم حاول مجددًا.';

  @override
  String get backupDeleteAllTitle => 'حذف كل شيء؟';

  @override
  String backupDeleteAllBody(String vehicles, String entries, String since) {
    return 'يؤدي هذا إلى حذف $vehicles و$entries، رجوعًا إلى $since.';
  }

  @override
  String backupDeleteAllNote(String days) {
    return 'تُحفظ نسخة على هذا الهاتف لمدة $days يومًا حتى تتمكن من التراجع. تُحذف إذا أزلت Odova.';
  }

  @override
  String backupVehicleCount(int n, String nText) {
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
  String backupEntryCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText إدخال',
      many: '$nText إدخالًا',
      few: '$nText إدخالات',
      two: 'إدخالان',
      one: 'إدخال واحد',
      zero: '$nText إدخال',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'استعادة';

  @override
  String importFileMade(
    String date,
    String time,
    String vehicles,
    String entries,
  ) {
    return 'أُنشئ في $date الساعة $time · $vehicles · $entries';
  }

  @override
  String get importWhatChanges => 'ما الذي يتغير';

  @override
  String get importNow => 'الآن';

  @override
  String get importAfter => 'بعد ذلك';

  @override
  String get importReplacesEverything =>
      'سيُستبدل كل ما في Odova الآن بهذا الملف.';

  @override
  String importCopySavedFirst(String days) {
    return 'تُحفظ نسخة من بياناتك الحالية أولاً. يمكنك التراجع خلال $days يومًا.';
  }

  @override
  String get importNothingToReplace => 'Odova فارغ، لذا لن يُستبدل شيء.';

  @override
  String get importAlreadyRestored =>
      'هذه هي النسخة التي استعدتها بالفعل. لن يتغير شيء على هذا الهاتف.';

  @override
  String importUndoHeader(String date, String time) {
    return 'بياناتك قبل $date، $time';
  }

  @override
  String importSkippedCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText إدخال لا يمكن قراءته وسيُترك.',
      many: '$nText إدخالًا لا يمكن قراءتها وستُترك.',
      few: '$nText إدخالات لا يمكن قراءتها وستُترك.',
      two: 'إدخالان لا يمكن قراءتهما وسيُتركان.',
      one: 'إدخال واحد لا يمكن قراءته وسيُترك.',
      zero: '$nText إدخال لا يمكن قراءته وسيُترك.',
    );
    return '$_temp0';
  }

  @override
  String get importSeeWhich => 'أيها';

  @override
  String get importReplaceMyData => 'استبدل بياناتي';

  @override
  String get importImport => 'استيراد';

  @override
  String get importReplaceAnyway => 'استبدل على أي حال';

  @override
  String get importRestoring => 'يجري استعادة بياناتك…';

  @override
  String importRestored(String vehicles, String entries) {
    return 'تمت الاستعادة. $vehicles و$entries.';
  }

  @override
  String get importDidNotFinish =>
      'لم تكتمل عملية الاستعادة الأخيرة. لم يتغير شيء.';

  @override
  String get importKindVehicles => 'المركبات';

  @override
  String get importKindFillups => 'تعبئات الوقود';

  @override
  String get importKindServices => 'الصيانات';

  @override
  String get importKindExpenses => 'المصروفات';

  @override
  String get importKindTrips => 'الرحلات';

  @override
  String get importKindReminders => 'التذكيرات';

  @override
  String get importKindReadings => 'قراءات العدّاد';

  @override
  String get commonDone => 'تم';

  @override
  String get backupPickVehicle => 'أي مركبة؟';

  @override
  String get backupAllVehicles => 'كل المركبات';
}
