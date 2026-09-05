// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Odova';

  @override
  String commonEstimatedA11y(String value) {
    return 'estimé, environ $value';
  }

  @override
  String get homeDueSoonNoConfidence =>
      'Odova a besoin d’un relevé pour le dire';

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
  String get dateToday => 'Aujourd’hui';

  @override
  String get dateTomorrow => 'Demain';

  @override
  String get dateYesterday => 'Hier';

  @override
  String dateInDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans $nText jours',
      many: 'dans $nText jours',
      one: 'dans $nText jour',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans environ $nText semaines',
      many: 'dans environ $nText semaines',
      one: 'dans environ $nText semaine',
    );
    return '$_temp0';
  }

  @override
  String dateInAboutMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans environ $nText mois',
      many: 'dans environ $nText mois',
      one: 'dans environ $nText mois',
    );
    return '$_temp0';
  }

  @override
  String dateDaysOverdue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'en retard de $nText jours',
      many: 'en retard de $nText jours',
      one: 'en retard de $nText jour',
    );
    return '$_temp0';
  }

  @override
  String remindersDueCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText rappels à échéance',
      many: '$nText rappels à échéance',
      one: '$nText rappel à échéance',
      zero: 'Rien à faire',
    );
    return '$_temp0';
  }

  @override
  String get routeNotFoundTitle => 'Introuvable';

  @override
  String get routeNotFoundBody => 'Ce lien ne mène nulle part.';

  @override
  String get routeNotFoundGoHome => 'Aller à l\'accueil';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabHistory => 'Historique';

  @override
  String get tabCosts => 'Coûts';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get tabLogA11y => 'Enregistrer';

  @override
  String get discardTitle => 'Abandonner les modifications ?';

  @override
  String discardBody(String subject, String summary) {
    return 'Vos modifications de $subject — $summary — n’ont pas été enregistrées.';
  }

  @override
  String get discardKeepEditing => 'Continuer à modifier';

  @override
  String get discardDiscard => 'Abandonner';

  @override
  String confirmDeleteTitle(String subject, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ses $countText entrées',
      many: 'ses $countText entrées',
      one: 'son entrée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $subject et $_temp0 ?',
      zero: 'Supprimer $subject ?',
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
      other: '$fillUpsText pleins',
      many: '$fillUpsText pleins',
      one: '$fillUpsText plein',
      zero: 'Aucun plein',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$servicesText entretiens',
      many: '$servicesText entretiens',
      one: '$servicesText entretien',
      zero: 'aucun entretien',
    );
    String _temp2 = intl.Intl.pluralLogic(
      costs,
      locale: localeName,
      other: '$costsText frais',
      many: '$costsText frais',
      one: '$costsText frais',
      zero: 'aucun frais',
    );
    String _temp3 = intl.Intl.pluralLogic(
      trips,
      locale: localeName,
      other: '$tripsText trajets',
      many: '$tripsText trajets',
      one: '$tripsText trajet',
      zero: 'aucun trajet',
    );
    String _temp4 = intl.Intl.pluralLogic(
      reminders,
      locale: localeName,
      other: '$remindersText rappels',
      many: '$remindersText rappels',
      one: '$remindersText rappel',
      zero: 'aucun rappel',
    );
    return '$_temp0, $_temp1, $_temp2, $_temp3 et $_temp4 disparaissent définitivement.';
  }

  @override
  String confirmDeleteTypeToConfirm(String subject) {
    return 'Saisissez $subject pour confirmer';
  }

  @override
  String confirmDeleteMismatch(String subject) {
    return 'Cela ne correspond pas à $subject.';
  }

  @override
  String get confirmDeleteDelete => 'Supprimer';

  @override
  String snoozeTitle(String item) {
    return 'Reporter $item';
  }

  @override
  String get snoozeBody =>
      'Cela met le rappel en sourdine. L\'échéance ne change pas.';

  @override
  String snoozeThreeDays(String count) {
    return '$count jours';
  }

  @override
  String snoozeOneWeek(String count) {
    return '$count semaine';
  }

  @override
  String snoozeOneMonth(String count) {
    return '$count mois';
  }

  @override
  String snoozeDistance(String distance) {
    return 'Après $distance de plus';
  }

  @override
  String snoozeUntil(String date) {
    return 'jusqu\'au $date';
  }

  @override
  String snoozeAtOdometer(String odometer) {
    return 'à $odometer';
  }

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonRestoreBackup => 'Restaurer une sauvegarde';

  @override
  String settingsLanguageSystem(String language) {
    return 'Système ($language)';
  }

  @override
  String get settingsLanguageNotTranslated =>
      'Odova n’est pas encore traduit dans la langue de votre appareil. Les nombres, les dates, les unités et les montants suivront toujours votre région.';

  @override
  String get firstRunLanguageTagline =>
      'Choisissez celle que vous lisez le mieux.';

  @override
  String get firstRunRestorePrompt => 'Vous changez de téléphone ?';

  @override
  String get firstRunVehicleTitle => 'Votre véhicule';

  @override
  String get firstRunVehicleSubtitle =>
      'Un véhicule et un nombre. C’est tout ce qu’il faut.';

  @override
  String get vehicleTypeCar => 'Voiture';

  @override
  String get vehicleTypeMotorcycle => 'Moto';

  @override
  String get vehicleTypeVan => 'Utilitaire';

  @override
  String get vehicleNameLabel => 'Nom';

  @override
  String get vehicleNameDefaultCar => 'Ma voiture';

  @override
  String get vehicleNameDefaultMotorcycle => 'Ma moto';

  @override
  String get vehicleNameDefaultVan => 'Mon utilitaire';

  @override
  String get vehicleFuelLabel => 'Carburant';

  @override
  String get fuelPetrol => 'Essence';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelElectric => 'Électrique';

  @override
  String get fuelLpg => 'GPL';

  @override
  String get fuelCng => 'GNV';

  @override
  String get fuelHybrid => 'Hybride';

  @override
  String get fuelOther => 'Autre';

  @override
  String get commonMore => 'Plus…';

  @override
  String get odometerNowLabel => 'Compteur actuel';

  @override
  String get odometerFirstRunHint => 'Lisez-le sur votre tableau de bord.';

  @override
  String get odometerEmptyError =>
      'Saisissez le nombre affiché sur votre tableau de bord.';

  @override
  String get odometerNotANumberError =>
      'Cela ne ressemble pas à un nombre. Chiffres uniquement.';

  @override
  String get odometerImplausibleWarning =>
      'Aucune voiture n’a jamais roulé autant. Vérifiez le nombre.';

  @override
  String get commonUseItAnyway => 'Utiliser quand même';

  @override
  String get annualBandLabelKm =>
      'Quelle distance environ par an ? (en milliers de km)';

  @override
  String get annualBandLabelMi =>
      'Quelle distance environ par an ? (en milliers de miles)';

  @override
  String annualBandUnder(String max) {
    return 'moins de $max';
  }

  @override
  String annualBandRange(String min, String max) {
    return '$min–$max';
  }

  @override
  String annualBandOver(String min) {
    return 'plus de $min';
  }

  @override
  String get commonStart => 'Commencer';

  @override
  String get firstRunHaveBackup => 'J’ai déjà une sauvegarde Odova';

  @override
  String get saveDiskFullError =>
      'Impossible d’enregistrer. Votre téléphone manque peut-être d’espace.';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get vehicleEditTitle => 'Véhicule';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get vehicleTypeOther => 'Autre';

  @override
  String get vehicleMakeLabel => 'Marque';

  @override
  String get vehicleModelLabel => 'Modèle';

  @override
  String get vehicleYearLabel => 'Année';

  @override
  String get vehiclePlateLabel => 'Immatriculation';

  @override
  String get vehicleVinLabel => 'VIN';

  @override
  String get vehicleColourLabel => 'Couleur';

  @override
  String get vehicleNotesLabel => 'Notes';

  @override
  String get vehicleBusinessLabel =>
      'Conduisez-vous ce véhicule pour le travail ?';

  @override
  String get vehicleMuteLabel =>
      'Mettre en sourdine les rappels de ce véhicule';

  @override
  String get vehicleOdometerRow => 'Compteur';

  @override
  String vehicleOdometerRowHint(String age) {
    return 'saisi $age';
  }

  @override
  String get vehicleMarkAsSold => 'Marquer comme vendu';

  @override
  String get vehicleKeepItMarkSold => 'Le garder — le marquer comme vendu';

  @override
  String vehicleDeleteRow(String name, String countText) {
    return 'Supprimer $name et ses $countText entrées';
  }

  @override
  String vehicleDeleteRowEmpty(String name) {
    return 'Supprimer $name';
  }

  @override
  String get vehiclePurchaseGroup => 'Achat et vente';

  @override
  String get vehicleUnitsGroup => 'Unités et devise de ce véhicule';

  @override
  String get commonAutomatic => 'Automatique';

  @override
  String get vehiclePurchaseDate => 'Date d’achat';

  @override
  String get vehiclePurchasePrice => 'Prix d’achat';

  @override
  String get vehiclePurchaseOdometer => 'Compteur à l’achat';

  @override
  String get vehicleSoldOn => 'Vendu le';

  @override
  String get vehicleSoldPrice => 'Prix de vente';

  @override
  String vehicleYearRangeError(String min, String max) {
    return 'Saisissez une année comprise entre $min et $max.';
  }

  @override
  String vehicleVinLengthNote(String countText) {
    return 'Un VIN compte généralement $countText caractères.';
  }

  @override
  String vehicleDuplicateNameNote(String name) {
    return 'Vous avez déjà un véhicule nommé $name';
  }

  @override
  String get vehicleCurrencyChangeNote =>
      'Seules les nouvelles entrées l’utilisent. Ce qui est déjà enregistré ne change pas.';

  @override
  String get vehicleFuelChangeNote =>
      'Les rappels conservent les intervalles qu’ils ont déjà.';

  @override
  String get colourWhite => 'Blanc';

  @override
  String get colourSilver => 'Argent';

  @override
  String get colourGrey => 'Gris';

  @override
  String get colourBlack => 'Noir';

  @override
  String get colourRed => 'Rouge';

  @override
  String get colourBlue => 'Bleu';

  @override
  String get colourGreen => 'Vert';

  @override
  String get colourYellow => 'Jaune';

  @override
  String get colourOther => 'Autre';

  @override
  String dateDaysAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a $nText jours',
      many: 'il y a $nText jours',
      one: 'il y a $nText jour',
    );
    return '$_temp0';
  }

  @override
  String dateAboutWeeksAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a environ $nText semaines',
      many: 'il y a environ $nText semaines',
      one: 'il y a environ $nText semaine',
    );
    return '$_temp0';
  }

  @override
  String dateAboutMonthsAgo(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'il y a environ $nText mois',
      many: 'il y a environ $nText mois',
      one: 'il y a environ $nText mois',
    );
    return '$_temp0';
  }

  @override
  String get vehiclesTitle => 'Véhicules';

  @override
  String get vehiclesIntro =>
      'Gérez le garage ici. Le changement de véhicule se fait depuis le titre de l’accueil.';

  @override
  String get vehiclesReorderHint =>
      'Appuyez longuement sur une ligne pour la déplacer. Balayez pour vendre ou supprimer.';

  @override
  String get vehiclesSoldArchived => 'Vendus et archivés';

  @override
  String get vehicleStatusAllGood => 'Tout est en ordre';

  @override
  String get vehicleStatusNoReminders => 'Aucun rappel pour l’instant';

  @override
  String get vehicleStatusNeedsOdometer => 'Compteur à mettre à jour';

  @override
  String get vehicleStatusUnknown => 'Impossible de déterminer les échéances';

  @override
  String vehicleOdometerStale(String age) {
    return 'Compteur mis à jour $age';
  }

  @override
  String vehicleOdometerLastEntered(String date) {
    return 'saisi le $date';
  }

  @override
  String vehicleStatusOverdue(String item) {
    return '$item en retard';
  }

  @override
  String vehicleStatusDue(String item) {
    return '$item à faire';
  }

  @override
  String get vehicleStatusItemGeneric => 'Entretien';

  @override
  String get vehiclesOnlyOneWarning =>
      'C’est votre seul véhicule. Le supprimer remet Odova à zéro.';

  @override
  String get vehicleSwitchToIt => 'Passer à ce véhicule';

  @override
  String get vehicleAddTitle => 'Ajouter un véhicule';

  @override
  String vehicleAddedSnack(String name) {
    return '$name ajouté';
  }

  @override
  String get switcherTitle => 'Changer de véhicule';

  @override
  String switcherCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText véhicules',
      many: '$nText véhicules',
      one: '$nText véhicule',
    );
    return '$_temp0';
  }

  @override
  String get switcherAddVehicle => 'Ajouter un véhicule';

  @override
  String get switcherManageVehicles => 'Gérer les véhicules';

  @override
  String get vehicleBusinessBadge => 'Professionnel';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonUndo => 'Annuler';

  @override
  String vehicleDeletedSnack(String name) {
    return '$name supprimé';
  }

  @override
  String vehicleSoldSnack(String name) {
    return '$name marqué comme vendu';
  }

  @override
  String vehicleSoldSummary(int n, String date, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Vendu le $date · $countText entrées',
      many: 'Vendu le $date · $countText entrées',
      one: 'Vendu le $date · $countText entrée',
      zero: 'Vendu le $date',
    );
    return '$_temp0';
  }

  @override
  String vehicleStatusDueInDays(int n, String item, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$item à échéance dans $countText jours',
      many: '$item à échéance dans $countText jours',
      one: '$item à échéance dans $countText jour',
    );
    return '$_temp0';
  }

  @override
  String homeOverdueByDistance(String distance) {
    return 'En retard de $distance';
  }

  @override
  String homeOverdueByTime(String duration) {
    return 'En retard de $duration';
  }

  @override
  String homeOverdueByBoth(String distance, String duration) {
    return 'En retard de $distance et $duration';
  }

  @override
  String get homeDueNow => 'À faire maintenant';

  @override
  String homeDueSoonDistance(String distance) {
    return 'dans environ $distance';
  }

  @override
  String get homeNeedsOdometer => 'Besoin d’un relevé du compteur';

  @override
  String get homeUnknownTitle => 'Quand cela a-t-il été fait ?';

  @override
  String get homeUnknownHint => 'Dites-le-moi et cela devient des rappels.';

  @override
  String homeUnknownMore(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $nText autres',
      many: '+ $nText autres',
      one: '+ $nText autre',
      zero: 'Tout voir',
    );
    return '$_temp0';
  }

  @override
  String homeMoreDue(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tout voir — $nText autres à faire ou en retard',
      many: 'Tout voir — $nText autres à faire ou en retard',
      one: 'Tout voir — $nText autre à faire ou en retard',
      zero: 'Tous les rappels',
    );
    return '$_temp0';
  }

  @override
  String homeSnoozedUntil(String date) {
    return 'Reporté jusqu’au $date';
  }

  @override
  String remindersSeeAll(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les rappels ($nText)',
      many: 'Tous les rappels ($nText)',
      one: 'Tous les rappels ($nText)',
      zero: 'Tous les rappels',
    );
    return '$_temp0';
  }

  @override
  String get remindersDisclaimer =>
      'Odova commence par les travaux habituels. Votre manuel prime — modifiez tout ici.';

  @override
  String get actionLogIt => 'Enregistrer';

  @override
  String get actionUpdateOdometer => 'Mettre à jour le compteur';

  @override
  String homeDurationDays(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText jours',
      many: '$nText jours',
      one: '$nText jour',
    );
    return '$_temp0';
  }

  @override
  String homeDurationWeeks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText semaines',
      many: '$nText semaines',
      one: '$nText semaine',
    );
    return '$_temp0';
  }

  @override
  String homeDurationMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText mois',
      many: '$nText mois',
      one: '$nText mois',
    );
    return '$_temp0';
  }

  @override
  String homeEnteredOn(String date) {
    return 'saisi $date';
  }

  @override
  String homeEstimatedFrom(String rate, String date) {
    return 'Estimé à partir d’environ $rate par jour depuis le $date.';
  }

  @override
  String get homeEstimateExpired =>
      'Votre dernier relevé est trop ancien, Odova a cessé d’estimer. Saisissez ce qu’affiche le compteur.';

  @override
  String get homeConsumptionPending =>
      'Votre première consommation arrivera au prochain plein.';

  @override
  String get homeLastFillUp => 'Dernier plein';

  @override
  String homeLastFillUpDetail(String date, String volume) {
    return '$date · $volume';
  }

  @override
  String homeOtherVehicleOverdue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText en retard',
      many: '$name · $nText en retard',
      one: '$name · $nText en retard',
    );
    return '$_temp0';
  }

  @override
  String homeOtherVehicleDue(int n, String nText, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name · $nText à échéance',
      many: '$name · $nText à échéance',
      one: '$name · $nText à échéance',
    );
    return '$_temp0';
  }

  @override
  String homeTilePerDistance(String unit) {
    return 'par $unit';
  }

  @override
  String get homeTilePerMonth => 'par mois';

  @override
  String get homeMoreActions => 'Plus d’actions';

  @override
  String get actionSnooze => 'Reporter';

  @override
  String get actionEditReminder => 'Modifier le rappel';

  @override
  String get actionTurnOff => 'Désactiver ce rappel';

  @override
  String homeTurnedOff(String item) {
    return '$item désactivé';
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
}
