// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'geschätzt, etwa $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'Odova braucht einen Kilometerstand, um das zu sagen';

  @override
  String get unitDistanceKm => 'km';

  @override
  String get unitDistanceMi => 'mi';

  @override
  String get unitVolumeLitre => 'l';

  @override
  String get unitVolumeGallon => 'gal';

  @override
  String unitConsumptionPerDistance(String n) {
    return 'l/$n km';
  }

  @override
  String get unitConsumptionMpg => 'mpg';

  @override
  String unitPerDistance(String unit) {
    return '/$unit';
  }

  @override
  String get dateToday => 'Heute';

  @override
  String get dateTomorrow => 'Morgen';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $nText Tagen',
      one: 'in $nText Tag',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in etwa $nText Wochen',
      one: 'in etwa $nText Woche',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in etwa $nText Monaten',
      one: 'in etwa $nText Monat',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Tage überfällig',
      one: '$nText Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Erinnerungen fällig',
      one: '$nText Erinnerung fällig',
      zero: 'Nichts fällig',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'Nicht gefunden';

  @override
  String get routeNotFoundBody => 'Dieser Link führt nirgendwohin.';

  @override
  String get routeNotFoundGoHome => 'Zur Startseite';

  @override
  String get tabHome => 'Start';

  @override
  String get tabHistory => 'Verlauf';

  @override
  String get tabCosts => 'Kosten';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get tabLogA11y => 'Erfassen';

  @override
  String get discardTitle => 'Änderungen verwerfen?';

  @override
  String discardBody(String subject, String summary) {
    return 'Ihre Änderungen an $subject — $summary — wurden nicht gespeichert.';
  }

  @override
  String get discardKeepEditing => 'Weiter bearbeiten';

  @override
  String get discardDiscard => 'Verwerfen';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seine $countText Einträge',
      one: 'seinen einen Eintrag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$subject und $_temp0 löschen?',
      zero: '$subject löschen?',
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
      other: '$fillUpsText Tankfüllungen',
      one: '$fillUpsText Tankfüllung',
      zero: 'Keine Tankfüllungen',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText Services',
      one: '$servicesText Service',
      zero: 'keine Services',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText Kostenposten',
      one: '$costsText Kostenposten',
      zero: 'keine Kostenposten',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText Fahrten',
      one: '$tripsText Fahrt',
      zero: 'keine Fahrten',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText Erinnerungen',
      one: '$remindersText Erinnerung',
      zero: 'keine Erinnerungen',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3 und $_temp4 sind endgültig weg.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'Zum Bestätigen $subject eingeben';
  }

  @override
  String confirmDeleteMismatch(String subject) {
    return 'Das stimmt nicht mit $subject überein.';
  }

  @override
  String get confirmDeleteDelete => 'Löschen';

  @override
  String snoozeTitle(String item) {
    return '$item zurückstellen';
  }

  @override
  String get snoozeBody =>
      'Das macht nur die Erinnerung still. Der Fälligkeitstermin ändert sich nicht.';

  @override
  String snoozeThreeDays(String count) {
    return '$count Tage';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count Woche';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count Monat';
  }

  @override
  String snoozeDistance(String distance) {
    return 'Nach weiteren $distance';
  }

  @override
  String snoozeUntil(String date) {
    return 'bis $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'bei $odometer';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonRestoreBackup => 'Backup wiederherstellen';

  @override
  String settingsLanguageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'Odova ist noch nicht in die Sprache Ihres Geräts übersetzt. Zahlen, Datumsangaben, Einheiten und Beträge richten sich weiterhin nach Ihrer Region.';

  @override
  String get firstRunLanguageTagline =>
      'Wählen Sie die, die Sie am besten lesen.';

  @override
  String get firstRunRestorePrompt => 'Wechseln Sie von einem anderen Telefon?';

  @override
  String get firstRunVehicleTitle => 'Ihr Fahrzeug';

  @override
  String get firstRunVehicleSubtitle =>
      'Ein Fahrzeug und eine Zahl. Das ist schon die ganze Einrichtung.';

  @override
  String get vehicleTypeCar => 'Auto';

  @override
  String get vehicleTypeMotorcycle => 'Motorrad';

  @override
  String get vehicleTypeVan => 'Transporter';

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameDefaultCar => 'Mein Auto';

  @override
  String get vehicleNameDefaultMotorcycle => 'Mein Motorrad';

  @override
  String get vehicleNameDefaultVan => 'Mein Transporter';

  @override
  String get vehicleFuelLabel => 'Kraftstoff';

  @override
  String get fuelPetrol => 'Benzin';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelElectric => 'Elektro';

  @override
  String get fuelLpg => 'Autogas';

  @override
  String get fuelCng => 'Erdgas';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get fuelOther => 'Sonstiges';

  @override
  String get commonMore => 'Mehr…';

  @override
  String get odometerNowLabel => 'Aktueller Kilometerstand';

  @override
  String get odometerFirstRunHint => 'Lesen Sie ihn vom Tacho ab.';

  @override
  String get odometerEmptyError => 'Geben Sie die Zahl vom Tacho ein.';

  @override
  String get odometerNotANumberError =>
      'Das sieht nicht nach einer Zahl aus. Nur Ziffern.';

  @override
  String get odometerImplausibleWarning =>
      'So weit ist noch kein Auto gefahren. Prüfen Sie die Zahl.';

  @override
  String get commonUseItAnyway => 'Trotzdem verwenden';

  @override
  String get annualBandLabelKm =>
      'Wie weit fahren Sie etwa im Jahr? (in Tausend km)';

  @override
  String get annualBandLabelMi =>
      'Wie weit fahren Sie etwa im Jahr? (in Tausend Meilen)';

  @override
  String annualBandUnder(String max) {
    return 'unter $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'über $min';
  }

  @override
  String get commonStart => 'Starten';

  @override
  String get firstRunHaveBackup => 'Ich habe schon ein Odova-Backup';

  @override
  String get saveDiskFullError =>
      'Speichern fehlgeschlagen. Vielleicht ist der Speicher Ihres Telefons voll.';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get vehicleEditTitle => 'Fahrzeug';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get vehicleTypeOther => 'Sonstiges';

  @override
  String get vehicleMakeLabel => 'Marke';

  @override
  String get vehicleModelLabel => 'Modell';

  @override
  String get vehicleYearLabel => 'Baujahr';

  @override
  String get vehiclePlateLabel => 'Kennzeichen';

  @override
  String get vehicleVinLabel => 'FIN';

  @override
  String get vehicleColourLabel => 'Farbe';

  @override
  String get vehicleNotesLabel => 'Notizen';

  @override
  String get vehicleBusinessLabel => 'Fahren Sie damit beruflich?';

  @override
  String get vehicleMuteLabel =>
      'Erinnerungen für dieses Fahrzeug stummschalten';

  @override
  String get vehicleOdometerRow => 'Kilometerstand';

  @override
  String vehicleOdometerRowHint(String age) {
    return '$age erfasst';
  }

  @override
  String get vehicleMarkAsSold => 'Als verkauft markieren';

  @override
  String get vehicleKeepItMarkSold => 'Behalten — als verkauft markieren';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return '$name und seine $countText Einträge löschen';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return '$name löschen';
  }

  @override
  String get vehiclePurchaseGroup => 'Kauf und Verkauf';

  @override
  String get vehicleUnitsGroup => 'Einheiten & Währung dieses Fahrzeugs';

  @override
  String get commonAutomatic => 'Automatisch';

  @override
  String get vehiclePurchaseDate => 'Kaufdatum';

  @override
  String get vehiclePurchasePrice => 'Kaufpreis';

  @override
  String get vehiclePurchaseOdometer => 'Kilometerstand beim Kauf';

  @override
  String get vehicleSoldOn => 'Verkauft am';

  @override
  String get vehicleSoldPrice => 'Verkaufspreis';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'Geben Sie ein Jahr zwischen $min und $max ein.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'Eine FIN hat üblicherweise $countText Zeichen.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'Sie haben bereits ein Fahrzeug namens $name';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'Gilt nur für neue Einträge. Bereits Gespeichertes bleibt unverändert.';

  @override
  String get vehicleFuelChangeNote =>
      'Erinnerungen behalten ihre bisherigen Intervalle.';

  @override
  String get colourWhite => 'Weiß';

  @override
  String get colourSilver => 'Silber';

  @override
  String get colourGrey => 'Grau';

  @override
  String get colourBlack => 'Schwarz';

  @override
  String get colourRed => 'Rot';

  @override
  String get colourBlue => 'Blau';

  @override
  String get colourGreen => 'Grün';

  @override
  String get colourYellow => 'Gelb';

  @override
  String get colourOther => 'Sonstige';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vor $nText Tagen',
      one: 'Vor $nText Tag',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vor etwa $nText Wochen',
      one: 'Vor etwa $nText Woche',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vor etwa $nText Monaten',
      one: 'Vor etwa $nText Monat',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'Fahrzeuge';

  @override
  String get vehiclesIntro =>
      'Hier verwalten Sie Ihre Fahrzeuge. Das Fahrzeug wechseln Sie über den Titel auf der Startseite.';

  @override
  String get vehiclesReorderHint =>
      'Halten Sie ein Fahrzeug gedrückt, um die Reihenfolge zu ändern. Wischen Sie zum Verkaufen und Löschen.';

  @override
  String get vehiclesSoldArchived => 'Verkauft und archiviert';

  @override
  String get vehicleStatusAllGood => 'Alles in Ordnung';

  @override
  String get vehicleStatusNoReminders => 'Noch keine Erinnerungen';

  @override
  String get vehicleStatusNeedsOdometer => 'Kilometerstand aktualisieren';

  @override
  String get vehicleStatusUnknown => 'Konnte nicht ermitteln, was fällig ist';

  @override
  String vehicleOdometerStale(String age) {
    return 'Kilometerstand zuletzt aktualisiert: $age';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'zuletzt erfasst am $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return '$item überfällig';
  }

  @override
  String vehicleStatusDue(String item) {
    return '$item fällig';
  }

  @override
  String get vehicleStatusItemGeneric => 'Wartung';

  @override
  String get vehiclesOnlyOneWarning =>
      'Das ist Ihr einziges Fahrzeug. Wenn Sie es löschen, beginnt Odova von vorn.';

  @override
  String get vehicleSwitchToIt => 'Wechseln';

  @override
  String get vehicleAddTitle => 'Fahrzeug hinzufügen';

  @override
  String vehicleAddedSnack(String name) {
    return '$name hinzugefügt';
  }

  @override
  String get switcherTitle => 'Fahrzeug wechseln';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Fahrzeuge',
      one: '$nText Fahrzeug',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'Fahrzeug hinzufügen';

  @override
  String get switcherManageVehicles => 'Fahrzeuge verwalten';

  @override
  String get vehicleBusinessBadge => 'Beruflich';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String vehicleDeletedSnack(String name) {
    return '$name gelöscht';
  }

  @override
  String vehicleSoldSnack(String name) {
    return '$name als verkauft markiert';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Verkauft am $date · $countText Einträge',
      one: 'Verkauft am $date · $countText Eintrag',
      zero: 'Verkauft am $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$item in $countText Tagen fällig',
      one: '$item in $countText Tag fällig',
    );
    return '$_temp0';
  }

  @override
  String homeOverdueByDistance(String distance) {
    return '$distance überfällig';
  }

  @override
  String homeOverdueByTime(String duration) {
    return '$duration überfällig';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return '$distance und $duration überfällig';
  }

  @override
  String get homeDueNow => 'Jetzt fällig';

  @override
  String homeDueSoonDistance(String distance) {
    return 'in etwa $distance';
  }

  @override
  String get homeNeedsOdometer => 'Braucht einen Kilometerstand';

  @override
  String get homeUnknownTitle => 'Wann wurde das zuletzt gemacht?';

  @override
  String get homeUnknownHint =>
      'Sagen Sie es mir, und daraus werden Erinnerungen.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText weitere',
      one: '+ $nText weiteres',
      zero: 'Alle anzeigen',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Alle anzeigen — $nText weitere fällig oder überfällig',
      one: 'Alle anzeigen — $nText weiteres fällig oder überfällig',
      zero: 'Alle Erinnerungen',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'Zurückgestellt bis $date';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Alle Erinnerungen ($nText)',
      one: 'Alle Erinnerungen ($nText)',
      zero: 'Alle Erinnerungen',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'Odova beginnt mit den üblichen Arbeiten. Ihr Handbuch zählt — ändern Sie hier alles.';

  @override
  String get actionLogIt => 'Eintragen';

  @override
  String get actionUpdateOdometer => 'Kilometerstand aktualisieren';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Tage',
      one: '$nText Tag',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Wochen',
      one: '$nText Woche',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText Monate',
      one: '$nText Monat',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'erfasst $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'Geschätzt aus etwa $rate pro Tag seit $date.';
  }

  @override
  String get homeEstimateExpired =>
      'Ihr letzter Stand ist zu alt, daher schätzt Odova nicht mehr. Geben Sie ein, was das Display jetzt zeigt.';

  @override
  String get homeConsumptionPending =>
      'Ihr erster Verbrauchswert kommt beim nächsten Volltanken.';

  @override
  String get homeLastFillUp => 'Letztes Tanken';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText überfällig',
      one: '$name · $nText überfällig',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText fällig',
      one: '$name · $nText fällig',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'pro $unit';
  }

  @override
  String get homeTilePerMonth => 'pro Monat';

  @override
  String get homeMoreActions => 'Weitere Aktionen';

  @override
  String get actionSnooze => 'Später erinnern';

  @override
  String get actionEditReminder => 'Erinnerung bearbeiten';

  @override
  String get actionTurnOff => 'Diese Erinnerung ausschalten';

  @override
  String homeTurnedOff(String item) {
    return '$item ausgeschaltet';
  }

  @override
  String get unitConsumptionKmPerLitre => 'km/l';

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
    return 'War fällig bei $odometer';
  }

  @override
  String homeWasDueOn(String date) {
    return 'War fällig am $date';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'War fällig bei $odometer · $date';
  }

  @override
  String homeDueAt(String odometer) {
    return 'Bei $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'Bei $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'etwa $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'Zuletzt eingetragen am $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Kilometerstand zuletzt vor $nText Tagen aktualisiert.',
      one: 'Kilometerstand zuletzt vor $nText Tag aktualisiert.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'Eine Woche ausblenden';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'Sie haben $item am $date als erledigt markiert.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'Ich habe $odometer und keine Kosten erfasst.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'Nächste Fälligkeit bei $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'Echte Werte eintragen';

  @override
  String get actionThatsRight => 'Stimmt so';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item ist am $date überfällig geworden';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item ist am $date fällig';
  }

  @override
  String get homeDigestDismiss => 'Diese Übersicht schließen';

  @override
  String get odometerSavedSnack => 'Kilometerstand gespeichert';

  @override
  String get homeNothingDue => 'Nichts fällig';

  @override
  String homeNextIs(String item, String date) {
    return 'Als Nächstes: $item, $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'Seit dem letzten $item:';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'Richten Sie Ihre Erinnerungen ein — sagen Sie mir, wann was zuletzt gemacht wurde';

  @override
  String get homeFirstRunConsumption =>
      'Tragen Sie eine Tankfüllung ein, dann beginnt hier Ihr Verbrauch.';

  @override
  String homeSoldTitle(String date) {
    return 'Dieses Fahrzeug ist als verkauft markiert ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return '$duration besessen · $distance gefahren';
  }

  @override
  String get homeErrorTitle => 'Odova kann Ihre Daten nicht lesen.';

  @override
  String get actionOpenBackup => 'Sicherung & Wiederherstellung öffnen';

  @override
  String get homeRowBroken => 'Mit dieser Erinnerung stimmt etwas nicht';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get remindersGroupPaused => 'Pausiert';

  @override
  String get remindersGroupNotTracked => 'Nicht verfolgt';

  @override
  String get remindersTrack => '+ Verfolgen';

  @override
  String get remindersPausedStatus => 'Pausiert';

  @override
  String get remindersEmpty => 'Noch keine Erinnerungen.';

  @override
  String get remindersNothingTracked =>
      'Für dieses Fahrzeug wird nichts verfolgt.';

  @override
  String get remindersWhenLastDone => 'Wann war das zuletzt';

  @override
  String get actionDoneToday => 'Heute erledigt';

  @override
  String get actionTurnOffShort => 'Ausschalten';
}
