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
  String unitConsumptionPerDistance(String n) {
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

  @override
  String get tabHome => 'خانه';

  @override
  String historyMonthEntryCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText مورد',
      one: '$nText مورد',
    );
    return '$_temp0';
  }

  @override
  String get bandFillUpFirstFill =>
      'اولین سوخت‌گیری — اولین عدد مصرف شما در باک پر بعدی می‌آید.';

  @override
  String get bandFillUpChainBroken => 'بدون عدد: باک قبلی ثبت نشده بود.';

  @override
  String get bandFillUpPartial => 'بدون عدد: پر کردن جزئی.';

  @override
  String bandFillUpSegment(String consumption, String distance, String date) {
    return '$consumption در $distance از $date';
  }

  @override
  String bandExpenseSpread(String total, String months, String perMonth) {
    return '$total در $months = $perMonth در ماه';
  }

  @override
  String bandOdometerRate(String distance, String days, String rate) {
    return '$distance در $days — $rate در روز';
  }

  @override
  String get bandDeleteFillUp => 'حذف این سوخت‌گیری';

  @override
  String recomputeFiguresRecalculated(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText عدد مصرف بعدی دوباره محاسبه شد',
      one: '$nText عدد مصرف بعدی دوباره محاسبه شد',
    );
    return '$_temp0';
  }

  @override
  String get recomputeSaved => 'ذخیره شد';

  @override
  String get recomputeFillUpUpdated => 'سوخت‌گیری به‌روزرسانی شد';

  @override
  String get recomputeServiceUpdated => 'سرویس به‌روزرسانی شد';

  @override
  String get recomputeExpenseUpdated => 'هزینه به‌روزرسانی شد';

  @override
  String get recomputeOdometerUpdated => 'ثبت کیلومتر به‌روزرسانی شد';

  @override
  String get historyReport => 'گزارش';

  @override
  String get historySearchHint => 'جستجو';

  @override
  String get historySearchClear => 'پاک کردن جستجو';

  @override
  String historySearchNoMatch(String query) {
    return 'چیزی با «$query» مطابقت ندارد.';
  }

  @override
  String get historySearch => 'جستجو در تاریخچه';

  @override
  String get historyFilterAll => 'همه';

  @override
  String get historyFilterFuel => 'سوخت';

  @override
  String get historyFilterService => 'سرویس';

  @override
  String get historyFilterExpense => 'هزینه';

  @override
  String get historyFilterTrip => 'سفرها';

  @override
  String get historyFilterOdometer => 'کیلومترشمار';

  @override
  String get historyReadFailureTitle => 'اودووا نتوانست سوابق شما را باز کند.';

  @override
  String get historyReadFailureAction => 'رفتن به پشتیبان‌گیری و بازیابی';

  @override
  String get historyClearFilters => 'پاک کردن فیلترها';

  @override
  String get historyEmptySubtitle => 'اولین سوخت‌گیری شما شروع سابقه است.';

  @override
  String get historyEmptyTitle => 'هنوز چیزی ثبت نشده است.';

  @override
  String get historyEmptyAction => 'ثبت سوخت‌گیری';

  @override
  String get historyFilteredEmpty => 'هیچ موردی با این فیلترها مطابقت ندارد.';

  @override
  String get historyOdometerReading => 'ثبت کیلومتر';

  @override
  String get tabHistory => 'تاریخچه';

  @override
  String get tabCosts => 'هزینه‌ها';

  @override
  String get tabSettings => 'تنظیمات';

  @override
  String get tabLogA11y => 'ثبت';

  @override
  String get discardTitle => 'تغییرات دور ریخته شود؟';

  @override
  String discardBody(String subject, String summary) {
    return 'ویرایش‌های شما روی $subject — $summary — ذخیره نشده است.';
  }

  @override
  String get discardKeepEditing => 'ادامه ویرایش';

  @override
  String get discardDiscard => 'دور بریز';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText رکوردش',
      one: 'یک رکوردش',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$subject و $_temp0 حذف شود؟',
      zero: '$subject حذف شود؟',
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
      other: '$fillUpsText سوخت‌گیری',
      one: 'یک سوخت‌گیری',
      zero: 'هیچ سوخت‌گیری',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText سرویس',
      one: 'یک سرویس',
      zero: 'هیچ سرویس',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText هزینه',
      one: 'یک هزینه',
      zero: 'هیچ هزینه',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText سفر',
      one: 'یک سفر',
      zero: 'هیچ سفر',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText یادآور',
      one: 'یک یادآور',
      zero: 'هیچ یادآور',
    );
    return '$_temp0، $_temp1، $_temp2، $_temp3 و $_temp4 برای همیشه حذف می‌شوند.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'برای تأیید، $subject را بنویسید';
  }

  @override
  String confirmDeleteMismatch(String subject) {
    return 'با $subject یکی نیست.';
  }

  @override
  String get confirmDeleteDelete => 'حذف';

  @override
  String snoozeTitle(String item) {
    return 'به تعویق انداختن $item';
  }

  @override
  String get snoozeBody =>
      'این فقط یادآور را ساکت می‌کند و زمان سررسید کار را تغییر نمی‌دهد.';

  @override
  String snoozeThreeDays(String count) {
    return '$count روز';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count هفته';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count ماه';
  }

  @override
  String snoozeDistance(String distance) {
    return 'پس از $distance دیگر';
  }

  @override
  String snoozeUntil(String date) {
    return 'تا $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'در $odometer';
  }

  @override
  String get commonCancel => 'انصراف';

  @override
  String get commonContinue => 'ادامه';

  @override
  String get commonRestoreBackup => 'بازیابی از پشتیبان';

  @override
  String settingsLanguageSystem(String language) {
    return 'سیستم ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'اودووا هنوز به زبان دستگاه شما ترجمه نشده است. اعداد، تاریخ‌ها، یکاها و مبالغ همچنان از منطقهٔ شما پیروی می‌کنند.';

  @override
  String get firstRunLanguageTagline =>
      'زبانی را انتخاب کنید که بهتر می‌خوانید.';

  @override
  String get firstRunRestorePrompt => 'از گوشی دیگری آمده‌اید؟';

  @override
  String get firstRunVehicleTitle => 'خودروی شما';

  @override
  String get firstRunVehicleSubtitle => 'یک خودرو و یک عدد. کل کار همین است.';

  @override
  String get vehicleTypeCar => 'سواری';

  @override
  String get vehicleTypeMotorcycle => 'موتور';

  @override
  String get vehicleTypeVan => 'ون';

  @override
  String get vehicleNameLabel => 'نام';

  @override
  String get vehicleNameDefaultCar => 'خودروی من';

  @override
  String get vehicleNameDefaultMotorcycle => 'موتور من';

  @override
  String get vehicleNameDefaultVan => 'ون من';

  @override
  String get vehicleFuelLabel => 'سوخت';

  @override
  String get fuelPetrol => 'بنزین';

  @override
  String get fuelDiesel => 'دیزل';

  @override
  String get fuelElectric => 'برقی';

  @override
  String get fuelLpg => 'ال‌پی‌جی';

  @override
  String get fuelCng => 'سی‌ان‌جی';

  @override
  String get fuelHybrid => 'هیبریدی';

  @override
  String get fuelOther => 'سایر';

  @override
  String get commonMore => 'بیشتر…';

  @override
  String get odometerNowLabel => 'کیلومتر فعلی';

  @override
  String get odometerFirstRunHint => 'از روی داشبورد بخوانید.';

  @override
  String get odometerEmptyError => 'عدد روی داشبورد را وارد کنید.';

  @override
  String get odometerNotANumberError => 'این شبیه عدد نیست. فقط رقم وارد کنید.';

  @override
  String get odometerImplausibleWarning =>
      'این از کارکرد هر خودرویی بیشتر است. عدد را بررسی کنید.';

  @override
  String get commonUseItAnyway => 'به هر حال استفاده کن';

  @override
  String get annualBandLabelKm => 'سالانه چند هزار کیلومتر؟';

  @override
  String get annualBandLabelMi => 'سالانه چند هزار مایل؟';

  @override
  String annualBandUnder(String max) {
    return 'زیر $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'بالای $min';
  }

  @override
  String get commonStart => 'شروع';

  @override
  String get firstRunHaveBackup => 'از قبل پشتیبان اودووا دارم';

  @override
  String get saveRefusedBackwards =>
      'این عدد از عدد قبلی کمتر است. لطفاً بررسی کنید.';

  @override
  String get saveRefusedReadOnly =>
      'اکنون امکان ذخیره نیست. ورودی شما باقی می‌ماند.';

  @override
  String get saveDiskFullError => 'ذخیره نشد. شاید حافظهٔ گوشی پر باشد.';

  @override
  String get commonRetry => 'تلاش دوباره';

  @override
  String get vehicleEditTitle => 'خودرو';

  @override
  String get commonClose => 'بستن';

  @override
  String get commonSave => 'ذخیره';

  @override
  String get vehicleTypeOther => 'سایر';

  @override
  String get vehicleMakeLabel => 'سازنده';

  @override
  String get vehicleModelLabel => 'مدل';

  @override
  String get vehicleYearLabel => 'سال';

  @override
  String get vehiclePlateLabel => 'پلاک';

  @override
  String get vehicleVinLabel => 'VIN';

  @override
  String get vehicleColourLabel => 'رنگ';

  @override
  String get vehicleNotesLabel => 'یادداشت';

  @override
  String get vehicleBusinessLabel => 'از این خودرو برای کار استفاده می‌کنید؟';

  @override
  String get vehicleMuteLabel => 'ساکت کردن یادآورهای این خودرو';

  @override
  String get vehicleOdometerRow => 'کیلومترشمار';

  @override
  String vehicleOdometerRowHint(String age) {
    return '$age ثبت شده';
  }

  @override
  String get vehicleMarkAsSold => 'ثبت به‌عنوان فروخته‌شده';

  @override
  String get vehicleKeepItMarkSold => 'نگهش دار — به‌عنوان فروخته‌شده ثبتش کن';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return 'حذف $name و $countText رکوردش';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return 'حذف $name';
  }

  @override
  String get vehiclePurchaseGroup => 'خرید و فروش';

  @override
  String get vehicleUnitsGroup => 'یکاها و واحد پول این خودرو';

  @override
  String get commonAutomatic => 'خودکار';

  @override
  String get vehiclePurchaseDate => 'تاریخ خرید';

  @override
  String get vehiclePurchasePrice => 'قیمت خرید';

  @override
  String get vehiclePurchaseOdometer => 'کیلومترشمار هنگام خرید';

  @override
  String get vehicleSoldOn => 'تاریخ فروش';

  @override
  String get vehicleSoldPrice => 'قیمت فروش';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'سالی بین $min و $max وارد کنید.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'شمارهٔ VIN معمولاً $countText کاراکتر دارد.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'از قبل خودرویی به نام $name دارید';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'فقط رکوردهای جدید از این پیروی می‌کنند. چیزی که ذخیره شده تغییر نمی‌کند.';

  @override
  String get vehicleFuelChangeNote =>
      'یادآورها بازه‌های فعلی خود را نگه می‌دارند.';

  @override
  String get colourWhite => 'سفید';

  @override
  String get colourSilver => 'نقره‌ای';

  @override
  String get colourGrey => 'خاکستری';

  @override
  String get colourBlack => 'مشکی';

  @override
  String get colourRed => 'قرمز';

  @override
  String get colourBlue => 'آبی';

  @override
  String get colourGreen => 'سبز';

  @override
  String get colourYellow => 'زرد';

  @override
  String get colourOther => 'سایر';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText روز پیش',
      one: '$nText روز پیش',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $nText هفته پیش',
      one: 'حدود $nText هفته پیش',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'حدود $nText ماه پیش',
      one: 'حدود $nText ماه پیش',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'خودروها';

  @override
  String get vehiclesIntro =>
      'گاراژ را اینجا مدیریت کنید. تعویض خودرو از عنوان صفحه خانه انجام می‌شود.';

  @override
  String get vehiclesReorderHint =>
      'برای جابه‌جایی، ردیف را نگه دارید. برای فروش و حذف، بکشید.';

  @override
  String get vehiclesSoldArchived => 'فروخته‌شده و بایگانی';

  @override
  String get vehicleStatusAllGood => 'همه‌چیز مرتب';

  @override
  String get vehicleStatusNoReminders => 'هنوز یادآوری ندارد';

  @override
  String get vehicleStatusNeedsOdometer =>
      'کیلومترشمار نیاز به به‌روزرسانی دارد';

  @override
  String get vehicleStatusUnknown => 'مشخص نشد چه چیزی موعد دارد';

  @override
  String vehicleOdometerStale(String age) {
    return 'کیلومترشمار $age به‌روزرسانی شده';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'آخرین ثبت $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return '$item عقب‌افتاده';
  }

  @override
  String vehicleStatusDue(String item) {
    return '$item موعدش رسیده';
  }

  @override
  String get vehicleStatusItemGeneric => 'سرویس';

  @override
  String get vehiclesOnlyOneWarning =>
      'این تنها خودروی شماست. با حذف آن، اودووا از نو شروع می‌شود.';

  @override
  String get vehicleSwitchToIt => 'همین را نشان بده';

  @override
  String get vehicleAddTitle => 'افزودن خودرو';

  @override
  String vehicleAddedSnack(String name) {
    return '$name افزوده شد';
  }

  @override
  String get switcherTitle => 'تعویض خودرو';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText خودرو',
      one: '$nText خودرو',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'افزودن خودرو';

  @override
  String get switcherManageVehicles => 'مدیریت خودروها';

  @override
  String get vehicleBusinessBadge => 'کاری';

  @override
  String get commonBack => 'بازگشت';

  @override
  String get commonAdd => 'افزودن';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonUndo => 'واگرد';

  @override
  String vehicleDeletedSnack(String name) {
    return '$name حذف شد';
  }

  @override
  String vehicleSoldSnack(String name) {
    return '$name به‌عنوان فروخته‌شده علامت خورد';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'فروخته‌شده در $date · $countText رکورد',
      one: 'فروخته‌شده در $date · $countText رکورد',
      zero: 'فروخته‌شده $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$item تا $countText روز دیگر موعد دارد',
      one: '$item تا $countText روز دیگر موعد دارد',
    );
    return '$_temp0';
  }

  @override
  String homeOverdueByDistance(String distance) {
    return '$distance گذشته';
  }

  @override
  String homeOverdueByTime(String duration) {
    return '$duration گذشته';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return '$distance و $duration گذشته';
  }

  @override
  String get homeDueNow => 'همین حالا موعدش است';

  @override
  String homeDueSoonDistance(String distance) {
    return 'حدود $distance دیگر';
  }

  @override
  String get homeNeedsOdometer => 'به کیلومتر نیاز دارد';

  @override
  String get homeUnknownTitle => 'اینها آخرین بار کی انجام شدند؟';

  @override
  String get homeUnknownHint => 'بگو تا به یادآور تبدیل شوند.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText مورد دیگر',
      one: '+ $nText مورد دیگر',
      zero: 'دیدن همه',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'دیدن همه — $nText مورد دیگر رسیده یا گذشته',
      one: 'دیدن همه — $nText مورد دیگر رسیده یا گذشته',
      zero: 'همهٔ یادآورها',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'تا $date به تعویق افتاد';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'همهٔ یادآورها ($nText)',
      one: 'همهٔ یادآورها ($nText)',
      zero: 'همهٔ یادآورها',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'اودووا با کارهای معمول شروع می‌کند. دفترچهٔ خودت مرجع است — هر چیزی را اینجا تغییر بده.';

  @override
  String get actionLogIt => 'ثبت کن';

  @override
  String get actionUpdateOdometer => 'به‌روزرسانی کیلومتر';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText روز',
      one: '$nText روز',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText هفته',
      one: '$nText هفته',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ماه',
      one: '$nText ماه',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'ثبت‌شده $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'برآورد از حدود $rate در روز از $date.';
  }

  @override
  String get homeEstimateExpired =>
      'آخرین عدد تو خیلی قدیمی است، پس اودووا دیگر حدس نمی‌زند. آنچه روی داشبورد است را وارد کن.';

  @override
  String get homeConsumptionPending =>
      'اولین عدد مصرف تو در باک‌پرکردن کامل بعدی می‌آید.';

  @override
  String get homeLastFillUp => 'آخرین سوخت‌گیری';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText عقب‌افتاده',
      one: '$name · $nText عقب‌افتاده',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText سررسید',
      one: '$name · $nText سررسید',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'در هر $unit';
  }

  @override
  String get homeTilePerMonth => 'در ماه';

  @override
  String get homeMoreActions => 'اقدام‌های بیشتر';

  @override
  String get actionSnooze => 'یادآوری بعداً';

  @override
  String get actionEditReminder => 'ویرایش یادآور';

  @override
  String get actionTurnOff => 'خاموش کردن این یادآور';

  @override
  String homeTurnedOff(String item) {
    return '$item خاموش شد';
  }

  @override
  String get unitConsumptionKmPerLitre => 'کم/ل';

  @override
  String unitConsumptionKwhPerDistance(String n) {
    return 'کیلووات‌ساعت/$n کم';
  }

  @override
  String get unitConsumptionMiPerKwh => 'مایل/کیلووات‌ساعت';

  @override
  String get unitEnergyKwh => 'کیلووات‌ساعت';

  @override
  String get unitMassKg => 'کیلوگرم';

  @override
  String commonEstimatedValue(String value) {
    return '~$value';
  }

  @override
  String homeWasDueAt(String odometer) {
    return 'موعدش $odometer بود';
  }

  @override
  String homeWasDueOn(String date) {
    return 'موعدش $date بود';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'موعدش $odometer · $date بود';
  }

  @override
  String homeDueAt(String odometer) {
    return 'در $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'در $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'حدود $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'آخرین ثبت $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'کیلومترشمار $nText روز پیش به‌روز شد.',
      one: 'کیلومترشمار $nText روز پیش به‌روز شد.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'یک هفته پنهان کن';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'شما $item را در $date انجام‌شده علامت زدید.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'من $odometer و بدون هزینه ثبت کردم.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'موعد بعدی $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'عددهای واقعی را وارد کن';

  @override
  String get actionThatsRight => 'درست است';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item در $date عقب‌افتاده شد';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item در $date سررسید می‌شود';
  }

  @override
  String get homeDigestDismiss => 'بستن این خلاصه';

  @override
  String get odometerSavedSnack => 'کیلومترشمار ذخیره شد';

  @override
  String get homeNothingDue => 'چیزی سررسید نشده';

  @override
  String homeNextIs(String item, String date) {
    return 'بعدی: $item، $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'از آخرین $item:';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'یادآورهایتان را تنظیم کنید — بگویید هر کار آخرین‌بار کی انجام شده';

  @override
  String get homeFirstRunConsumption =>
      'یک سوخت‌گیری ثبت کنید تا مصرف‌تان از اینجا شروع شود.';

  @override
  String homeSoldTitle(String date) {
    return 'این خودرو فروخته‌شده علامت خورده است ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return '$duration در اختیار · $distance رانده‌شده';
  }

  @override
  String get homeErrorTitle => 'اودووا نمی‌تواند داده‌های شما را بخواند.';

  @override
  String get actionOpenBackup => 'باز کردن پشتیبان‌گیری و بازیابی';

  @override
  String get homeRowBroken => 'این یادآور مشکلی دارد';

  @override
  String get remindersTitle => 'یادآورها';

  @override
  String get remindersGroupPaused => 'متوقف‌شده';

  @override
  String get remindersGroupNotTracked => 'پیگیری نمی‌شود';

  @override
  String get remindersTrack => '+ پیگیری';

  @override
  String get remindersPausedStatus => 'متوقف';

  @override
  String get remindersEmpty => 'هنوز یادآوری نیست.';

  @override
  String get remindersNothingTracked => 'برای این خودرو چیزی پیگیری نمی‌شود.';

  @override
  String get remindersWhenLastDone => 'آخرین‌بار کی انجام شد';

  @override
  String get actionDoneToday => 'امروز انجام شد';

  @override
  String get actionTurnOffShort => 'خاموش';

  @override
  String get actionSnoozeShort => 'تعویق';

  @override
  String get reminderEditTitle => 'یادآور';

  @override
  String get reminderNewTitle => 'یادآور تازه';

  @override
  String get reminderName => 'نام';

  @override
  String get reminderEveryDistance => 'هر';

  @override
  String get reminderEveryMonths => 'هر … ماه';

  @override
  String get reminderOnceAtOdometer => 'یا یک‌بار، در کیلومترشمار';

  @override
  String get reminderOnceOnDate => 'یا یک‌بار، در تاریخ';

  @override
  String get reminderLastDoneDate => 'آخرین‌بار — تاریخ';

  @override
  String get reminderLastDoneOdometer => 'آخرین‌بار — کیلومترشمار';

  @override
  String get reminderNotify => 'به من اطلاع بده';

  @override
  String get reminderNoticeAhead => 'چقدر زودتر بگویم';

  @override
  String reminderNoticeAutomatic(String distance, String days) {
    return 'خالی یعنی خودکار — $distance / $days.';
  }

  @override
  String get reminderPriority => 'اولویت';

  @override
  String get reminderPrioritySafety => 'ایمنی';

  @override
  String get reminderPriorityNormal => 'عادی';

  @override
  String get reminderPriorityLow => 'کم';

  @override
  String get reminderRollover => 'هنگام تکرار، بشمار از';

  @override
  String get reminderRolloverActual => 'روزی که انجام شد';

  @override
  String get reminderRolloverDue => 'روز سررسید';

  @override
  String get reminderRepeats => 'تکرار می‌شود';

  @override
  String get reminderNotes => 'یادداشت';

  @override
  String get reminderNoScheduleError =>
      'یک بازه یا تاریخ هدف تعیین کنید — وگرنه چیزی برای یادآوری نیست.';

  @override
  String get reminderBaselineTooLowError =>
      'این کمتر از قدیمی‌ترین عدد ثبت‌شدهٔ این خودرو است.';

  @override
  String get reminderBaselineFutureError =>
      'کاری نمی‌تواند در آینده انجام شده باشد.';

  @override
  String get reminderNameError => 'برای این یادآور نامی بگذارید.';

  @override
  String reminderDeletedSnack(String item) {
    return '$item حذف شد';
  }

  @override
  String get reminderNotTrackedBanner => 'پیگیری نمی‌شود — یادآوری نخواهید شد';

  @override
  String get reminderStartTracking => 'شروع پیگیری';

  @override
  String get reminderTurnBackOn => 'دوباره روشن کن';

  @override
  String get reminderTurnThisOff => 'این یادآور را خاموش کن';

  @override
  String reminderCannotDelete(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText سرویس برای این ثبت شده است. خاموش کردن آن‌ها را نگه می‌دارد.',
      one: '$nText سرویس برای این ثبت شده است. خاموش کردن آن را نگه می‌دارد.',
    );
    return '$_temp0';
  }

  @override
  String get reminderLastDoneHeading => 'آخرین‌بارها';

  @override
  String get reminderNoticeAheadDays => 'چقدر زودتر بگویم — روز';

  @override
  String get logSegmentFillUp => 'سوخت';

  @override
  String get logSegmentService => 'سرویس';

  @override
  String get logSegmentExpense => 'هزینه';

  @override
  String get logSegmentOdometer => 'کیلومتر';

  @override
  String get logEditFillUpTitle => 'ویرایش سوخت‌گیری';

  @override
  String get logEditServiceTitle => 'ویرایش سرویس';

  @override
  String get logEditExpenseTitle => 'ویرایش هزینه';

  @override
  String get logEditOdometerTitle => 'ویرایش عدد کیلومتر';

  @override
  String get logSavedFillUp => 'سوخت‌گیری ذخیره شد';

  @override
  String get logSavedService => 'سرویس ذخیره شد';

  @override
  String get logSavedExpense => 'هزینه ذخیره شد';

  @override
  String get logSaveFillUp => 'ذخیرهٔ سوخت‌گیری';

  @override
  String get logSaveService => 'ذخیرهٔ سرویس';

  @override
  String get logSaveExpense => 'ذخیرهٔ هزینه';

  @override
  String get logSaveOdometer => 'ذخیرهٔ کیلومتر';

  @override
  String get logDeleteFillUp => 'حذف این سوخت‌گیری';

  @override
  String get logDeleteService => 'حذف این رکورد سرویس';

  @override
  String get logDeleteExpense => 'حذف این هزینه';

  @override
  String get logDeleteOdometer => 'حذف این عدد کیلومتر';

  @override
  String get logDiscardSummary => 'آنچه نوشته‌اید';

  @override
  String get logDateLabel => 'تاریخ';

  @override
  String get logOdometerLabel => 'کیلومترشمار';

  @override
  String get logDateFutureError => 'امروز یا روزی در گذشته را انتخاب کنید.';

  @override
  String get logOdometerRequiredError => 'عدد کیلومترشمار را وارد کنید.';

  @override
  String logNumberUnclearError(String example) {
    return 'این عدد روشن نیست. مثلاً $example بنویسید.';
  }

  @override
  String get logTitleFillUp => 'سوخت‌گیری';

  @override
  String get logTitleService => 'سرویس';

  @override
  String get logTitleExpense => 'هزینه';

  @override
  String get logTitleOdometer => 'کیلومترشمار';

  @override
  String logOdometerLastEntered(String distance, String date) {
    return 'آخرین ثبت $distance در $date';
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
      other: 'آخرین ثبت $distance در $date — $daysText روز پیش',
      one: 'آخرین ثبت $distance در $date — $daysText روز پیش',
    );
    return '$_temp0';
  }

  @override
  String logOdometerEstimateChip(String value) {
    return 'اکنون $value';
  }

  @override
  String logOdometerLastEnteredShort(String distance) {
    return 'آخرین ثبت $distance';
  }

  @override
  String logOdometerSinceThen(String distance) {
    return '+$distance از آن زمان';
  }

  @override
  String logOdometerSince(String date, String distance) {
    return '$date · +$distance';
  }

  @override
  String logOdometerDelta(String distance, String date) {
    return '+$distance از $date';
  }

  @override
  String get logOdometerOlderThanAnything =>
      'قدیمی‌تر از هر چیزی است که ثبت شده. این قدیمی‌ترین عدد شما می‌شود.';

  @override
  String get logOdometerBelowLastTitle => 'این عدد از آخرین عدد شما کمتر است';

  @override
  String logOdometerBelowLastBody(String distance, String date) {
    return 'آخرین ثبت: $distance در $date.';
  }

  @override
  String get logOdometerBelowLastTypo => 'اشتباه تایپی است — اصلاحش می‌کنم';

  @override
  String get logOdometerBelowLastReplaced =>
      'کیلومترشمار تعویض شده یا دور کامل زده است';

  @override
  String get logOdometerBelowLastOlder =>
      'ثبتی قدیمی‌تر است که الان اضافه می‌کنم';

  @override
  String logOdometerAboveEarliest(String distance, String date, String when) {
    return 'قدیمی‌ترین عدد شما $distance در $date است. عددی از $when باید کمتر از آن باشد.';
  }

  @override
  String logOdometerRateWarning(String rate, String date) {
    return 'این حدود $rate در روز از $date تاکنون است. درست است؟';
  }

  @override
  String logOdometerUnitMixUpWarning(String value) {
    return 'منظورتان $value بود؟ این شبیه کیلومتر است.';
  }

  @override
  String logOdometerJumpWarning(String distance) {
    return 'این جهشی به اندازهٔ $distance است. درست است؟';
  }

  @override
  String get logOdometerSwitchUnitPrompt =>
      'از این پس همهٔ عددهای شما به کیلومتر نمایش داده شود؟';

  @override
  String get logOdometerUnitChipLabel => 'یکای این ثبت';

  @override
  String get logOdometerPadClear => 'پاک کردن';

  @override
  String get logOdometerPadBackspace => 'حذف آخرین رقم';

  @override
  String get expenseCategoryInsurance => 'بیمه';

  @override
  String get expenseCategoryTaxRegistration => 'عوارض و مالیات';

  @override
  String get expenseCategoryParking => 'پارکینگ';

  @override
  String get expenseCategoryToll => 'عوارض راه';

  @override
  String get expenseCategoryFine => 'جریمه';

  @override
  String get expenseCategoryWash => 'کارواش';

  @override
  String get expenseCategoryTyreStorage => 'نگهداری لاستیک';

  @override
  String get expenseCategoryAccessories => 'لوازم جانبی';

  @override
  String get expenseCategoryFinance => 'اقساط';

  @override
  String get expenseCategoryOther => 'سایر';

  @override
  String get logExpenseCategoryLabel => 'دسته';

  @override
  String get logExpenseCategoryError => 'انتخاب کنید این بابت چه بود.';

  @override
  String get logExpenseNameLabel => 'این چه بود؟';

  @override
  String get logExpenseNameError => 'برای این هزینه نامی بگذارید.';

  @override
  String get logExpenseAmountLabel => 'مبلغ';

  @override
  String get logExpenseAmountError => 'مبلغ پرداختی را وارد کنید.';

  @override
  String get logExpenseRefundLabel => 'این بازپرداخت است';

  @override
  String get logExpenseDatePaidLabel => 'تاریخ پرداخت';

  @override
  String get logExpenseCoversLabel => 'یک بازه را پوشش می‌دهد';

  @override
  String get logExpenseCoversFrom => 'از';

  @override
  String get logExpenseCoversTo => 'تا';

  @override
  String get logExpenseCoversError => 'تاریخ پایان پیش از تاریخ شروع است.';

  @override
  String get logFillUpQuantityLabel => 'سوخت';

  @override
  String logFillUpPricePerUnitLabel(String unit) {
    return 'قیمت/$unit';
  }

  @override
  String get logFillUpTotalLabel => 'مبلغ کل';

  @override
  String get logFillUpFullTank => 'باک را پر کردم';

  @override
  String get logFillUpPartFill => 'پر کردن جزئی';

  @override
  String get logFillUpOverTankWarning =>
      'این بیشتر از گنجایش باک شماست. همان‌طور که وارد شده ذخیره می‌شود.';

  @override
  String get logFillUpPartFillHint =>
      'پر کردن جزئی به‌تنهایی عددی نمی‌دهد. این یکی به باک پر بعدی اضافه می‌شود.';

  @override
  String get logFillUpTrioError =>
      'بنویسید چقدر سوخت زدید، و قیمت هر لیتر یا مبلغ کل را.';

  @override
  String get logFillUpQuantityError => 'مقدار سوخت باید بیشتر از صفر باشد.';

  @override
  String get logFillUpPriceError => 'قیمت نمی‌تواند منفی باشد.';

  @override
  String logFillUpTotalError(String zero) {
    return 'مبلغ کل نمی‌تواند منفی باشد. سوخت‌گیری رایگان $zero است.';
  }

  @override
  String get logFillUpFirstEver =>
      'اولین عدد مصرف شما در سوخت‌گیری کامل بعدی می‌آید.';

  @override
  String get logServiceWhatWasDone => 'چه کاری انجام شد';

  @override
  String get logServiceTickResets => 'تیک زدن یادآور را از نو تنظیم می‌کند.';

  @override
  String get logServiceOther => '+ موارد دیگر';

  @override
  String get logServiceCostLabel => 'هزینه';

  @override
  String get logServiceSplit => 'تقسیم هزینه بر اساس مورد';

  @override
  String logServiceCostError(String zero) {
    return 'هزینه نمی‌تواند منفی باشد. کار گارانتی $zero است.';
  }

  @override
  String logServiceCostEmptyError(String zero) {
    return 'هزینه را بنویسید، یا $zero.';
  }

  @override
  String get logServiceGenericLine => 'سرویس';

  @override
  String get logMoreRow => 'بیشتر';

  @override
  String get logMoreFillUpSummary => 'پمپ بنزین · نوع · سفر';

  @override
  String get logMoreServiceSummary => 'تعمیرگاه · فاکتور';

  @override
  String get logMoreExpenseSummary => 'پرداخت به · یادداشت';

  @override
  String get logFillUpStation => 'پمپ بنزین';

  @override
  String get logFillUpGrade => 'نوع سوخت';

  @override
  String get logFillUpChainBroken => 'سوخت‌گیری قبلی را ثبت نکردم';

  @override
  String get logFillUpChainBrokenHint =>
      'عددهای مصرف شما از این سوخت‌گیری از نو شروع می‌شود.';

  @override
  String get logServiceWorkshop => 'تعمیرگاه';

  @override
  String get logServiceInvoice => 'شمارهٔ فاکتور';

  @override
  String get logNotes => 'یادداشت';

  @override
  String get logExpensePaidTo => 'پرداخت به';

  @override
  String logDoneTitle(String item) {
    return '$item انجام شد';
  }

  @override
  String logDoneNextBoth(String odometer, String date) {
    return 'سررسید بعدی در $odometer یا $date — هرکدام زودتر رسید';
  }

  @override
  String logDoneNextDistance(String odometer) {
    return 'سررسید بعدی در $odometer';
  }

  @override
  String logDoneNextDate(String date) {
    return 'سررسید بعدی $date';
  }

  @override
  String get logDoneClose => 'بستن';

  @override
  String deleteFillUpRecalculated(String segment) {
    return 'این سوخت‌گیری حذف شود؟ مقدار مصرف برای $segment دوباره محاسبه می‌شود.';
  }

  @override
  String deleteFillUpFiguresRemoved(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'این سوخت‌گیری حذف شود؟ $nText مقدار مصرف حذف می‌شود.',
      one: 'این سوخت‌گیری حذف شود؟ $nText مقدار مصرف حذف می‌شود.',
    );
    return '$_temp0';
  }

  @override
  String get deleteFillUpPlain => 'این سوخت‌گیری حذف شود؟';

  @override
  String deleteServiceResets(String items) {
    return 'این سرویس حذف شود؟ $items دوباره از سرویس قبلی سررسید می‌شوند.';
  }

  @override
  String get deleteServicePlain => 'این سرویس حذف شود؟';

  @override
  String deleteTripKeepsCosts(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'این سفر حذف شود؟ $nText هزینهٔ آن می‌مانند — فقط دیگر به سفری وصل نیستند.',
      one:
          'این سفر حذف شود؟ $nText هزینهٔ آن می‌ماند — فقط دیگر به سفری وصل نیست.',
    );
    return '$_temp0';
  }

  @override
  String get deleteTripPlain => 'این سفر حذف شود؟';

  @override
  String get deleteReadingPlain => 'این کیلومترشمار حذف شود؟';

  @override
  String get deleteExpensePlain => 'این هزینه حذف شود؟';

  @override
  String deleteBlockedOnlyReading(String vehicle) {
    return 'این تنها کیلومترشمار ثبت‌شده برای $vehicle است. هر خودرو به یکی نیاز دارد.';
  }

  @override
  String deleteBlockedStartsCorrection(String date) {
    return 'این کیلومترشمار آغاز یک تصحیح از $date است. اول تصحیح را حذف کنید.';
  }

  @override
  String get listSeparator => '، ';

  @override
  String listPairJoin(String head, String last) {
    return '$head و $last';
  }

  @override
  String get reportTitle => 'گزارش سرویس';

  @override
  String get reportIncludeHeading => 'در سند گنجانده شود';

  @override
  String get reportToggleCosts => 'هزینه‌ها';

  @override
  String get reportToggleFuel => 'خلاصهٔ سوخت';

  @override
  String get reportTogglePlateVin => 'پلاک و شمارهٔ شاسی';

  @override
  String get reportToggleNotes => 'یادداشت‌های خصوصی من';

  @override
  String get reportNotesWarning =>
      'یادداشت‌های شما ممکن است چیزهایی داشته باشد که نمی‌خواهید خریدار بخواند.';

  @override
  String get reportSharePdf => 'هم‌رسانی PDF';

  @override
  String get reportCopyAsText => 'کپی به‌صورت متن';

  @override
  String get reportPaperSize => 'اندازهٔ کاغذ';

  @override
  String get reportEmptyTitle => 'هنوز سرویسی ثبت نشده';

  @override
  String get reportEmptyBody =>
      'این گزارش از همان لحظه‌ای که شروع به افزودن کنید ارزشمند می‌شود.';

  @override
  String get reportShareDisabledReason =>
      'هنوز سرویسی برای قرار دادن در گزارش نیست.';

  @override
  String reportOwnedSince(String date) {
    return 'در مالکیت از $date';
  }

  @override
  String reportGeneratedFooter(String date, String iso) {
    return 'ساخته‌شده توسط اودووا در $date ($iso) از سوابق نگهداری‌شده توسط مالک. تأیید نشده توسط شخص ثالث.';
  }

  @override
  String get reportEstimatedFootnote =>
      '~ کیلومترشمار در آن زمان تخمینی بوده، از خودرو خوانده نشده.';

  @override
  String get reportNoRecordHeading => 'بدون سابقه در این برنامه';

  @override
  String reportServiceCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText سرویس',
      one: '$nText سرویس',
    );
    return '$_temp0';
  }

  @override
  String reportOwnershipSpan(String years, String months) {
    return '$years سال $months ماه';
  }

  @override
  String reportInvoiceRef(String ref) {
    return 'فاکتور $ref';
  }

  @override
  String reportOdometerSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String get reportColumnDate => 'تاریخ';

  @override
  String get reportColumnOdometer => 'کیلومترشمار';

  @override
  String get reportColumnWork => 'کار انجام‌شده';

  @override
  String get reportColumnCost => 'هزینه';

  @override
  String reportPageOf(String n, String total) {
    return 'صفحهٔ $n از $total';
  }

  @override
  String get reportOwnedLabel => 'در مالکیت';

  @override
  String get reportServicesLabel => 'سرویس';

  @override
  String get costsTitle => 'هزینه‌ها';

  @override
  String get costsRangeThisYear => 'امسال';

  @override
  String get costsRangeAll => 'همه';

  @override
  String get costsPerMonth => 'در ماه';

  @override
  String get costsWhereMoneyGoes => 'پول کجا می‌رود';

  @override
  String get costsAccrualNote =>
      'هزینه‌های سالانه مانند بیمه روی ماه‌هایی که پوشش می‌دهند پخش می‌شود.';

  @override
  String costsThisMonthSoFar(String amount) {
    return 'این ماه تا کنون: $amount';
  }

  @override
  String get costsEmptyTitle => 'هنوز هزینه‌ای نیست.';

  @override
  String get costsEmptyAction => 'چیزی ثبت کنید';

  @override
  String get costsCategoryFuel => 'سوخت';

  @override
  String get costsCategoryService => 'سرویس و تعمیرات';

  @override
  String get costsCategoryInsuranceTax => 'بیمه و مالیات';

  @override
  String get costsCategoryFinance => 'تأمین مالی';

  @override
  String get costsCategoryParkingTolls => 'پارکینگ و عوارض';

  @override
  String get costsCategoryOther => 'سایر';

  @override
  String get costsFuelRow => 'سوخت و مصرف';

  @override
  String get costsTripsRow => 'سفرها';

  @override
  String get costsNoCompletedMonth =>
      'بعد از پایان ماه برگردید — هنوز یک ماه کامل برای میانگین‌گیری نیست.';

  @override
  String get costsNotEnoughDistance =>
      'در این دوره مسافت کافی ثبت نشده تا هزینه به ازای هر کیلومتر محاسبه شود.';

  @override
  String costsBoundaryStale(String days) {
    return 'از کیلومترشمارهایی محاسبه شده که $days روز با تاریخ‌های نشان‌داده‌شده فاصله دارند.';
  }

  @override
  String get costsUpdateOdometer => 'به‌روزرسانی کیلومترشمار';

  @override
  String costsRangeMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText ماه',
      one: '$nText ماه',
    );
    return '$_temp0';
  }

  @override
  String costsHeadlineCaption(String vehicle, String range) {
    return '$vehicle · $range';
  }

  @override
  String get costsRangeThisYearSoFar => 'امسال تا کنون';

  @override
  String costsSpanCaption(String from, String to) {
    return '$from – $to';
  }

  @override
  String costsPerKilometre(String amount) {
    return '$amount در هر کیلومتر';
  }

  @override
  String costsPerMile(String amount) {
    return '$amount در هر مایل';
  }

  @override
  String costsInMonths(int n, String nText, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$amount در $nText ماه',
      one: '$amount در $nText ماه',
    );
    return '$_temp0';
  }

  @override
  String get costsAllVehicles => 'همهٔ خودروها';

  @override
  String get costsIncludeInactive => 'شامل فروخته‌شده و بایگانی';

  @override
  String costsHiddenVehicles(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText خودرو پنهان است',
      one: '$nText خودرو پنهان است',
    );
    return '$_temp0';
  }

  @override
  String costsBusinessRow(String share, String amount) {
    return 'کاری $share٪ · $amount';
  }

  @override
  String get costsBusinessCaption =>
      'از سفرهایی که ثبت کرده‌اید محاسبه شده، نه از همهٔ رانندگی شما.';

  @override
  String get costsVehicleSold => 'فروخته‌شده';

  @override
  String get costsVehicleArchived => 'بایگانی‌شده';

  @override
  String get fuelTitle => 'سوخت و مصرف';

  @override
  String get fuelConsumptionPerTank => 'مصرف در هر باک';

  @override
  String get fuelEmptyTitle => 'هنوز سوخت‌گیری‌ای نیست.';

  @override
  String get fuelEmptyAction => 'ثبت سوخت‌گیری';

  @override
  String get fuelFirstFigure => 'اولین عدد شما در سوخت‌گیری کامل بعدی می‌آید.';

  @override
  String get tripsTitle => 'سفرها';

  @override
  String get tripsEmptyTitle => 'هنوز سفری نیست.';

  @override
  String get tripsEmptyBody => 'یکی ثبت کنید تا ببینید یک سفر چقدر هزینه دارد.';

  @override
  String get tripsAddAction => 'افزودن سفر';

  @override
  String get tripsOpenBadge => 'باز';

  @override
  String get tripsFinishAction => 'پایان این سفر';

  @override
  String get tripsPurposeBusiness => 'کاری';

  @override
  String get tripsPurposeCommute => 'رفت‌وآمد';

  @override
  String get tripsPurposePersonal => 'شخصی';

  @override
  String get tripsPurposeOther => 'سایر';

  @override
  String tripsLoggedLabel(String unit) {
    return '$unit ثبت‌شده';
  }

  @override
  String get tripsBusinessLabel => 'کاری';

  @override
  String get tripsCostsLabel => 'هزینهٔ سفرها';

  @override
  String get tripsEarlier => 'پیش‌تر';

  @override
  String tripsCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText سفر',
      one: '$nText سفر',
      zero: 'بدون سفر',
    );
    return '$_temp0';
  }

  @override
  String tripsStartedFrom(String date, String odometer) {
    return 'آغاز $date · از $odometer';
  }

  @override
  String tripsStartedOn(String date) {
    return 'آغاز $date';
  }

  @override
  String get tripsNoEndReading => 'کیلومتر پایان ثبت نشده';

  @override
  String tripsBusinessValue(String percent) {
    return '$percent%';
  }

  @override
  String get tripEditTitle => 'ویرایش سفر';

  @override
  String get tripNewTitle => 'سفر';

  @override
  String get tripSaveAction => 'ذخیرهٔ سفر';

  @override
  String get tripPurposeLabel => 'هدف';

  @override
  String get tripTitleLabel => 'عنوان';

  @override
  String get tripStartsLabel => 'آغاز';

  @override
  String get tripEndsLabel => 'پایان';

  @override
  String get tripStillGoing => 'هنوز ادامه دارد';

  @override
  String get tripStartOdometerLabel => 'کیلومترشمار آغاز';

  @override
  String get tripEndOdometerLabel => 'کیلومترشمار پایان';

  @override
  String get tripDistanceLabel => 'مسافت';

  @override
  String get tripExpensesLabel => 'هزینه‌ها';

  @override
  String get tripAddExpense => 'افزودن هزینه';

  @override
  String get tripNoExpenses => 'هنوز چیزی به این سفر اختصاص نیافته است.';

  @override
  String get tripDeleteAction => 'حذف سفر';

  @override
  String get tripStartInFuture => 'امروز یا روزی در گذشته را انتخاب کنید.';

  @override
  String get tripEndBeforeStart => 'تاریخ پایان پیش از تاریخ آغاز است.';

  @override
  String get tripEndBelowStart => 'عدد پایان کمتر از عدد آغاز است.';

  @override
  String get tripDistanceNotPositive => 'مسافت باید بیشتر از صفر باشد.';

  @override
  String get tripSavedToast => 'سفر ذخیره شد';

  @override
  String get tripSaveFirstToAddExpense =>
      'ابتدا سفر را ذخیره کنید، سپس هزینه‌ها را به آن اختصاص دهید.';

  @override
  String get costsEstimateTitle => 'این عدد چگونه به دست آمده';

  @override
  String costsEstimateStaleBoundary(String days) {
    return 'از کیلومترشمارهایی محاسبه شده که $days روز با تاریخ‌های نشان‌داده‌شده فاصله دارند.';
  }

  @override
  String get costsEstimateNotEnoughDistance =>
      'در این بازه مسافت کافی ثبت نشده تا هزینهٔ هر کیلومتر محاسبه شود.';

  @override
  String get costsEstimateNoCompletedMonth =>
      'پس از پایان ماه سر بزنید — هنوز یک ماه کامل برای میانگین‌گیری نیست.';

  @override
  String get costsEstimateNoReadings =>
      'در این بازه هیچ کیلومترشماری برای اندازه‌گیری وجود ندارد.';

  @override
  String get fuelEmptyBody =>
      'نخستین عدد مصرف شما در دومین باک پر به دست می‌آید.';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingsBackupRow => 'پشتیبان‌گیری و بازیابی';

  @override
  String get settingsBackupNever => 'هرگز پشتیبانی نگرفته‌اید.';

  @override
  String settingsBackupLast(String date, String ago) {
    return 'آخرین پشتیبان $date — $ago';
  }

  @override
  String get settingsBackupMigrationFailed =>
      'اودووا نتوانست به‌روزرسانی را کامل کند.';

  @override
  String get settingsVehiclesRow => 'خودروها';

  @override
  String settingsVehicleCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText خودرو',
      one: '$nText خودرو',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnitsRow => 'یکاها و قالب‌ها';

  @override
  String get settingsNotificationsRow => 'اعلان‌ها';

  @override
  String settingsNotificationsValue(String state, String time) {
    return '$state · $time';
  }

  @override
  String get settingsNotificationsOn => 'روشن';

  @override
  String get settingsNotificationsOff => 'خاموش';

  @override
  String get settingsAppearance => 'ظاهر';

  @override
  String get settingsThemeSystem => 'سیستم';

  @override
  String get settingsThemeLight => 'روشن';

  @override
  String get settingsThemeDark => 'تیره';

  @override
  String get settingsAboutRow => 'درباره';

  @override
  String get settingsLanguageRow => 'زبان';

  @override
  String get settingsLanguageNote =>
      'اودووا به این شش زبان ترجمه شده است. اعداد، تاریخ‌ها و یکاها جداگانه در «یکاها و قالب‌ها» تنظیم می‌شوند.';
}
