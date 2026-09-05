// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'estimated, about $value';
  }

  @override
  String get homeDueSoonNoConfidence => 'Odova needs a reading to say when';

  @override
  String get unitDistanceKm => 'km';

  @override
  String get unitDistanceMi => 'mi';

  @override
  String get unitVolumeLitre => 'L';

  @override
  String get unitVolumeGallon => 'gal';

  @override
  String unitConsumptionPerDistance(String n) {
    return 'L/$n km';
  }

  @override
  String get unitConsumptionMpg => 'mpg';

  @override
  String unitPerDistance(String unit) {
    return '/$unit';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $nText days',
      one: 'in $nText day',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $nText weeks',
      one: 'in about $nText week',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in about $nText months',
      one: 'in about $nText month',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText days overdue',
      one: '$nText day overdue',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText reminders due',
      one: '$nText reminder due',
      zero: 'Nothing due',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'Not found';

  @override
  String get routeNotFoundBody => 'That link doesn\'t lead anywhere.';

  @override
  String get routeNotFoundGoHome => 'Go to Home';

  @override
  String get tabHome => 'Home';

  @override
  String get tabHistory => 'History';

  @override
  String get tabCosts => 'Costs';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabLogA11y => 'Log';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String discardBody(String subject, String summary) {
    return 'Your edits to $subject — $summary — have not been saved.';
  }

  @override
  String get discardKeepEditing => 'Keep editing';

  @override
  String get discardDiscard => 'Discard';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'its $countText entries',
      one: 'its $countText entry',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $subject and $_temp0?',
      zero: 'Delete $subject?',
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
      other: '$fillUpsText fill-ups',
      one: '$fillUpsText fill-up',
      zero: 'No fill-ups',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText services',
      one: '$servicesText service',
      zero: 'no services',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText costs',
      one: '$costsText cost',
      zero: 'no costs',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText trips',
      one: '$tripsText trip',
      zero: 'no trips',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText reminders',
      one: '$remindersText reminder',
      zero: 'no reminders',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3 and $_temp4 go permanently.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'Type $subject to confirm';
  }

  @override
  String confirmDeleteMismatch(String subject) {
    return 'That doesn\'t match $subject.';
  }

  @override
  String get confirmDeleteDelete => 'Delete';

  @override
  String snoozeTitle(String item) {
    return 'Snooze $item';
  }

  @override
  String get snoozeBody =>
      'This quiets the reminder. It does not change when the job is due.';

  @override
  String snoozeThreeDays(String count) {
    return '$count days';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count week';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count month';
  }

  @override
  String snoozeDistance(String distance) {
    return 'After another $distance';
  }

  @override
  String snoozeUntil(String date) {
    return 'until $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'at $odometer';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRestoreBackup => 'Restore a backup';

  @override
  String settingsLanguageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'Odova isn’t translated into your device’s language yet. Numbers, dates, units and money will still follow your region.';

  @override
  String get firstRunLanguageTagline => 'Pick the one you read best.';

  @override
  String get firstRunRestorePrompt => 'Moving from another phone?';

  @override
  String get firstRunVehicleTitle => 'Your vehicle';

  @override
  String get firstRunVehicleSubtitle =>
      'One vehicle and one number. That is the whole setup.';

  @override
  String get vehicleTypeCar => 'Car';

  @override
  String get vehicleTypeMotorcycle => 'Motorbike';

  @override
  String get vehicleTypeVan => 'Van';

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameDefaultCar => 'My car';

  @override
  String get vehicleNameDefaultMotorcycle => 'My motorbike';

  @override
  String get vehicleNameDefaultVan => 'My van';

  @override
  String get vehicleFuelLabel => 'Fuel';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get fuelOther => 'Other';

  @override
  String get commonMore => 'More…';

  @override
  String get odometerNowLabel => 'Odometer now';

  @override
  String get odometerFirstRunHint => 'Read it off the dash.';

  @override
  String get odometerEmptyError => 'Enter the number on your dash.';

  @override
  String get odometerNotANumberError =>
      'That doesn\'t look like a number. Digits only.';

  @override
  String get odometerImplausibleWarning =>
      'That\'s higher than any car has driven. Check the number.';

  @override
  String get commonUseItAnyway => 'Use it anyway';

  @override
  String get annualBandLabelKm => 'About how far a year? (thousand km)';

  @override
  String get annualBandLabelMi => 'About how far a year? (thousand miles)';

  @override
  String annualBandUnder(String max) {
    return 'under $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'over $min';
  }

  @override
  String get commonStart => 'Start';

  @override
  String get firstRunHaveBackup => 'I already have an Odova backup';

  @override
  String get saveDiskFullError =>
      'Couldn\'t save. Your phone may be out of space.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get vehicleEditTitle => 'Vehicle';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get vehicleTypeOther => 'Other';

  @override
  String get vehicleMakeLabel => 'Make';

  @override
  String get vehicleModelLabel => 'Model';

  @override
  String get vehicleYearLabel => 'Year';

  @override
  String get vehiclePlateLabel => 'Plate';

  @override
  String get vehicleVinLabel => 'VIN';

  @override
  String get vehicleColourLabel => 'Colour';

  @override
  String get vehicleNotesLabel => 'Notes';

  @override
  String get vehicleBusinessLabel => 'Do you drive this for work?';

  @override
  String get vehicleMuteLabel => 'Mute reminders for this vehicle';

  @override
  String get vehicleOdometerRow => 'Odometer';

  @override
  String vehicleOdometerRowHint(String age) {
    return 'entered $age';
  }

  @override
  String get vehicleMarkAsSold => 'Mark as sold';

  @override
  String get vehicleKeepItMarkSold => 'Keep it — mark it sold';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return 'Delete $name and its $countText entries';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return 'Delete $name';
  }

  @override
  String get vehiclePurchaseGroup => 'Purchase and sale';

  @override
  String get vehicleUnitsGroup => 'This vehicle\'s units & currency';

  @override
  String get commonAutomatic => 'Automatic';

  @override
  String get vehiclePurchaseDate => 'Purchase date';

  @override
  String get vehiclePurchasePrice => 'Purchase price';

  @override
  String get vehiclePurchaseOdometer => 'Odometer at purchase';

  @override
  String get vehicleSoldOn => 'Sold on';

  @override
  String get vehicleSoldPrice => 'Sold price';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'Enter a year between $min and $max.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'A VIN is usually $countText characters.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'You already have a vehicle called $name';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'Only new entries use this. Nothing already saved changes.';

  @override
  String get vehicleFuelChangeNote =>
      'Reminders keep the intervals they already have.';

  @override
  String get colourWhite => 'White';

  @override
  String get colourSilver => 'Silver';

  @override
  String get colourGrey => 'Grey';

  @override
  String get colourBlack => 'Black';

  @override
  String get colourRed => 'Red';

  @override
  String get colourBlue => 'Blue';

  @override
  String get colourGreen => 'Green';

  @override
  String get colourYellow => 'Yellow';

  @override
  String get colourOther => 'Other';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText days ago',
      one: '$nText day ago',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'about $nText weeks ago',
      one: 'about $nText week ago',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'about $nText months ago',
      one: 'about $nText month ago',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'Vehicles';

  @override
  String get vehiclesIntro =>
      'Manage the garage here. Switching cars happens from the Home title.';

  @override
  String get vehiclesReorderHint =>
      'Press and hold a row to reorder. Swipe for sell and delete.';

  @override
  String get vehiclesSoldArchived => 'Sold and archived';

  @override
  String get vehicleStatusAllGood => 'All good';

  @override
  String get vehicleStatusNoReminders => 'No reminders yet';

  @override
  String get vehicleStatusNeedsOdometer => 'Odometer needs updating';

  @override
  String get vehicleStatusUnknown => 'Couldn\'t work out what\'s due';

  @override
  String vehicleOdometerStale(String age) {
    return 'Odometer last updated $age';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'last entered $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return '$item overdue';
  }

  @override
  String vehicleStatusDue(String item) {
    return '$item due';
  }

  @override
  String get vehicleStatusItemGeneric => 'Service';

  @override
  String get vehiclesOnlyOneWarning =>
      'This is your only vehicle. Deleting it starts Odova over.';

  @override
  String get vehicleSwitchToIt => 'Switch to it';

  @override
  String get vehicleAddTitle => 'Add vehicle';

  @override
  String vehicleAddedSnack(String name) {
    return '$name added';
  }

  @override
  String get switcherTitle => 'Switch vehicle';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText vehicles',
      one: '$nText vehicle',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'Add vehicle';

  @override
  String get switcherManageVehicles => 'Manage vehicles';

  @override
  String get vehicleBusinessBadge => 'Business';

  @override
  String get commonBack => 'Back';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String vehicleDeletedSnack(String name) {
    return 'Deleted $name';
  }

  @override
  String vehicleSoldSnack(String name) {
    return '$name marked as sold';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sold $date · $countText entries',
      one: 'Sold $date · $countText entry',
      zero: 'Sold $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$item due in $countText days',
      one: '$item due in $countText day',
    );
    return '$_temp0';
  }

  @override
  String homeOverdueByDistance(String distance) {
    return 'Overdue by $distance';
  }

  @override
  String homeOverdueByTime(String duration) {
    return 'Overdue by $duration';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return 'Overdue by $distance and $duration';
  }

  @override
  String get homeDueNow => 'Due now';

  @override
  String homeDueSoonDistance(String distance) {
    return 'in about $distance';
  }

  @override
  String get homeNeedsOdometer => 'Needs an odometer reading';

  @override
  String get homeUnknownTitle => 'When were these last done?';

  @override
  String get homeUnknownHint => 'Telling me turns them into reminders.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText more',
      one: '+ $nText more',
      zero: 'See all',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'See all — $nText more due or overdue',
      one: 'See all — $nText more due or overdue',
      zero: 'See all reminders',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'Snoozed until $date';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'See all reminders ($nText)',
      one: 'See all reminders ($nText)',
      zero: 'See all reminders',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'Odova starts you off with the usual jobs. Your handbook wins — edit anything here.';

  @override
  String get actionLogIt => 'Log it';

  @override
  String get actionUpdateOdometer => 'Update odometer';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText days',
      one: '$nText day',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText weeks',
      one: '$nText week',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText months',
      one: '$nText month',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'entered $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'Estimated from about $rate a day since $date.';
  }

  @override
  String get homeEstimateExpired =>
      'Your last reading is too old, so Odova has stopped guessing. Enter what the dash says now.';

  @override
  String get homeConsumptionPending =>
      'Your first consumption figure arrives at your next full fill-up.';

  @override
  String get homeLastFillUp => 'Last fill-up';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText overdue',
      one: '$name · $nText overdue',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText due',
      one: '$name · $nText due',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'per $unit';
  }

  @override
  String get homeTilePerMonth => 'per month';

  @override
  String get homeMoreActions => 'More actions';

  @override
  String get actionSnooze => 'Snooze';

  @override
  String get actionEditReminder => 'Edit reminder';

  @override
  String get actionTurnOff => 'Turn this off';

  @override
  String homeTurnedOff(String item) {
    return '$item turned off';
  }

  @override
  String get unitConsumptionKmPerLitre => 'km/L';

  @override
  String unitConsumptionKwhPerDistance(String n) {
    return 'kWh/$n km';
  }

  @override
  String get unitConsumptionMiPerKwh => 'mi/kWh';

  @override
  String get unitEnergyKwh => 'kWh';

  @override
  String get unitMassKg => 'kg';

  @override
  String commonEstimatedValue(String value) {
    return '~$value';
  }

  @override
  String homeWasDueAt(String odometer) {
    return 'Was due at $odometer';
  }

  @override
  String homeWasDueOn(String date) {
    return 'Was due $date';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'Was due at $odometer · $date';
  }

  @override
  String homeDueAt(String odometer) {
    return 'At $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'At $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'around $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'Last entered $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Odometer last updated $nText days ago.',
      one: 'Odometer last updated $nText day ago.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'Hide this for a week';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'You marked $item done on $date.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'I recorded $odometer and no cost.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'Next due at $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'Add the real numbers';

  @override
  String get actionThatsRight => 'That\'s right';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item went overdue on $date';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item is due $date';
  }

  @override
  String get homeDigestDismiss => 'Dismiss this summary';

  @override
  String get odometerSavedSnack => 'Odometer saved';

  @override
  String get homeNothingDue => 'Nothing due';

  @override
  String homeNextIs(String item, String date) {
    return 'Next: $item, $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'Since the last $item:';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'Set up your reminders — tell me when things were last done';

  @override
  String get homeFirstRunConsumption =>
      'Log a fill-up and your consumption starts here.';

  @override
  String homeSoldTitle(String date) {
    return 'This vehicle is marked sold ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return 'Owned $duration · $distance driven';
  }

  @override
  String get homeErrorTitle => 'Odova can\'t read your data.';

  @override
  String get actionOpenBackup => 'Open Backup & restore';

  @override
  String get homeRowBroken => 'Something\'s wrong with this reminder';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersGroupPaused => 'Paused';

  @override
  String get remindersGroupNotTracked => 'Not tracked';

  @override
  String get remindersTrack => '+ Track';

  @override
  String get remindersPausedStatus => 'Paused';

  @override
  String get remindersEmpty => 'No reminders yet.';

  @override
  String get remindersNothingTracked =>
      'Nothing is being tracked on this vehicle.';

  @override
  String get remindersWhenLastDone => 'When was this last done';

  @override
  String get actionDoneToday => 'Done today';

  @override
  String get actionTurnOffShort => 'Turn off';

  @override
  String get actionSnoozeShort => 'Snooze';

  @override
  String get reminderEditTitle => 'Reminder';

  @override
  String get reminderNewTitle => 'New reminder';

  @override
  String get reminderName => 'Name';

  @override
  String get reminderEveryDistance => 'Every';

  @override
  String get reminderEveryMonths => 'Every … months';

  @override
  String get reminderOnceAtOdometer => 'Or once, at odometer';

  @override
  String get reminderOnceOnDate => 'Or once, on date';

  @override
  String get reminderLastDoneDate => 'Last done — date';

  @override
  String get reminderLastDoneOdometer => 'Last done — odometer';

  @override
  String get reminderNotify => 'Notify me';

  @override
  String get reminderNoticeAhead => 'Tell me this far ahead';

  @override
  String reminderNoticeAutomatic(String distance, String days) {
    return 'Blank means automatic — $distance / $days.';
  }

  @override
  String get reminderPriority => 'Priority';

  @override
  String get reminderPrioritySafety => 'Safety';

  @override
  String get reminderPriorityNormal => 'Normal';

  @override
  String get reminderPriorityLow => 'Low';

  @override
  String get reminderRollover => 'When it repeats, count from';

  @override
  String get reminderRolloverActual => 'The day it was done';

  @override
  String get reminderRolloverDue => 'The day it was due';

  @override
  String get reminderRepeats => 'Repeats';

  @override
  String get reminderNotes => 'Notes';

  @override
  String get reminderNoScheduleError =>
      'Set an interval or a target date — otherwise there\'s nothing to remind you about.';

  @override
  String get reminderBaselineTooLowError =>
      'This is below the earliest reading for this vehicle.';

  @override
  String get reminderBaselineFutureError =>
      'A job cannot have been done in the future.';

  @override
  String get reminderNotTrackedBanner => 'Not tracked — you won\'t be reminded';

  @override
  String get reminderStartTracking => 'Start tracking';

  @override
  String get reminderTurnBackOn => 'Turn back on';

  @override
  String get reminderTurnThisOff => 'Turn this reminder off';

  @override
  String reminderCannotDelete(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText services are recorded against this. Turning it off keeps them.',
      one: '$nText service is recorded against this. Turning it off keeps it.',
    );
    return '$_temp0';
  }

  @override
  String get reminderLastDoneHeading => 'Last done';

  @override
  String get reminderNoticeAheadDays => 'Tell me this far ahead — days';
}
