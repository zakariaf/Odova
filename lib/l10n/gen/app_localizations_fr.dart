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
  String unitConsumptionPerDistance(int n) {
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
    return 'saisi $age · appuyez pour mettre à jour';
  }

  @override
  String get vehicleMarkAsSold => 'Marquer comme vendu';

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
}
