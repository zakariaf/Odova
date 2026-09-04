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

  @override
  String get tabHome => 'خانه';

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
    return '$age ثبت شده · برای به‌روزرسانی ضربه بزنید';
  }

  @override
  String get vehicleMarkAsSold => 'ثبت به‌عنوان فروخته‌شده';

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
  String get vehicleStatusItemGeneric => 'سرویس';

  @override
  String get vehiclesOnlyOneWarning =>
      'این تنها خودروی شماست. با حذف آن، اودووا از نو شروع می‌شود.';

  @override
  String get vehicleSwitchToIt => 'همین را نشان بده';

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
}
