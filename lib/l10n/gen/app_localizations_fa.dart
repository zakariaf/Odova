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
}
