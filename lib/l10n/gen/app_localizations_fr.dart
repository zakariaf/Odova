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
  String historyMonthEntryCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText entrées',
      many: '$nText entrées',
      one: '$nText entrée',
    );
    return '$_temp0';
  }

  @override
  String get bandFillUpFirstFill =>
      'Premier plein — votre première valeur de consommation arrivera au prochain plein complet.';

  @override
  String get bandFillUpChainBroken =>
      'Pas de valeur : le plein précédent n\'a pas été enregistré.';

  @override
  String get bandFillUpPartial => 'Pas de valeur : plein partiel.';

  @override
  String bandFillUpSegment(String consumption, String distance, String date) {
    return '$consumption sur $distance depuis $date';
  }

  @override
  String bandExpenseSpread(String total, String months, String perMonth) {
    return '$total sur $months = $perMonth par mois';
  }

  @override
  String bandOdometerRate(String distance, String days, String rate) {
    return '$distance en $days — $rate par jour';
  }

  @override
  String get bandDeleteFillUp => 'Supprimer ce plein';

  @override
  String recomputeFiguresRecalculated(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText valeurs de consommation recalculées',
      many: '$nText valeurs de consommation recalculées',
      one: '$nText valeur de consommation recalculée',
    );
    return '$_temp0';
  }

  @override
  String get recomputeSaved => 'Enregistré';

  @override
  String get recomputeFillUpUpdated => 'Plein mis à jour';

  @override
  String get recomputeServiceUpdated => 'Entretien mis à jour';

  @override
  String get recomputeExpenseUpdated => 'Dépense mise à jour';

  @override
  String get recomputeOdometerUpdated => 'Relevé mis à jour';

  @override
  String get historyReport => 'Rapport';

  @override
  String get historySearchHint => 'Rechercher';

  @override
  String get historySearchClear => 'Effacer la recherche';

  @override
  String historySearchNoMatch(String query) {
    return 'Rien ne correspond à « $query ».';
  }

  @override
  String get historySearch => 'Rechercher';

  @override
  String get historyFilterAll => 'Tout';

  @override
  String get historyFilterFuel => 'Carburant';

  @override
  String get historyFilterService => 'Entretien';

  @override
  String get historyFilterExpense => 'Dépenses';

  @override
  String get historyFilterTrip => 'Trajets';

  @override
  String get historyFilterOdometer => 'Compteur';

  @override
  String get historyReadFailureTitle => 'Odova n\'a pas pu ouvrir vos données.';

  @override
  String get historyReadFailureAction => 'Aller à Sauvegarde et restauration';

  @override
  String get historyClearFilters => 'Effacer les filtres';

  @override
  String get historyEmptySubtitle => 'Votre premier plein commence le journal.';

  @override
  String get historyEmptyTitle => 'Rien encore enregistré.';

  @override
  String get historyEmptyAction => 'Enregistrer un plein';

  @override
  String get historyFilteredEmpty =>
      'Aucune entrée ne correspond à ces filtres.';

  @override
  String get historyOdometerReading => 'Relevé';

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
  String get saveRefusedBackwards =>
      'Ce relevé est inférieur au précédent. Vérifiez le nombre.';

  @override
  String get saveRefusedReadOnly =>
      'Odova ne peut pas enregistrer pour l\'instant. Votre saisie est conservée.';

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

  @override
  String homeWasDueAt(String odometer) {
    return 'Échéance à $odometer';
  }

  @override
  String homeWasDueOn(String date) {
    return 'Échéance le $date';
  }

  @override
  String homeWasDueAtOn(String odometer, String date) {
    return 'Échéance à $odometer · $date';
  }

  @override
  String homeDueAt(String odometer) {
    return 'À $odometer';
  }

  @override
  String homeDueAtOn(String odometer, String date) {
    return 'À $odometer · $date';
  }

  @override
  String homeAroundDate(String date) {
    return 'vers le $date';
  }

  @override
  String homeLastEntered(String date) {
    return 'Dernière saisie le $date';
  }

  @override
  String homeStripStale(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Compteur mis à jour il y a $nText jours.',
      many: 'Compteur mis à jour il y a $nText jours.',
      one: 'Compteur mis à jour il y a $nText jour.',
    );
    return '$_temp0';
  }

  @override
  String get homeStripStaleDismiss => 'Masquer pendant une semaine';

  @override
  String homeStripDoneTitle(String item, String date) {
    return 'Vous avez marqué $item comme fait le $date.';
  }

  @override
  String homeStripDoneRecorded(String odometer) {
    return 'J\'ai enregistré $odometer et aucun coût.';
  }

  @override
  String homeStripDoneNext(String odometer, String date) {
    return 'Prochaine échéance à $odometer · $date.';
  }

  @override
  String get actionAddRealNumbers => 'Saisir les vraies valeurs';

  @override
  String get actionThatsRight => 'C\'est exact';

  @override
  String homeDigestOverdue(String item, String date) {
    return '$item est en retard depuis le $date';
  }

  @override
  String homeDigestDue(String item, String date) {
    return '$item est à échéance le $date';
  }

  @override
  String get homeDigestDismiss => 'Fermer ce résumé';

  @override
  String get odometerSavedSnack => 'Compteur enregistré';

  @override
  String get homeNothingDue => 'Rien à faire';

  @override
  String homeNextIs(String item, String date) {
    return 'Ensuite : $item, $date';
  }

  @override
  String homeSinceLast(String item) {
    return 'Depuis le dernier $item :';
  }

  @override
  String homeSinceLastFigure(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String get homeFirstRunSetUp =>
      'Configurez vos rappels — dites-moi quand les choses ont été faites';

  @override
  String get homeFirstRunConsumption =>
      'Enregistrez un plein et votre consommation commence ici.';

  @override
  String homeSoldTitle(String date) {
    return 'Ce véhicule est marqué comme vendu ($date).';
  }

  @override
  String homeSoldOwned(String duration, String distance) {
    return 'Possédé $duration · $distance parcourus';
  }

  @override
  String get homeErrorTitle => 'Odova ne peut pas lire vos données.';

  @override
  String get actionOpenBackup => 'Ouvrir Sauvegarde et restauration';

  @override
  String get homeRowBroken => 'Un problème avec ce rappel';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get remindersGroupPaused => 'En pause';

  @override
  String get remindersGroupNotTracked => 'Non suivi';

  @override
  String get remindersTrack => '+ Suivre';

  @override
  String get remindersPausedStatus => 'En pause';

  @override
  String get remindersEmpty => 'Aucun rappel pour l’instant.';

  @override
  String get remindersNothingTracked => 'Rien n’est suivi sur ce véhicule.';

  @override
  String get remindersWhenLastDone => 'C’était quand la dernière fois';

  @override
  String get actionDoneToday => 'Fait aujourd’hui';

  @override
  String get actionTurnOffShort => 'Désactiver';

  @override
  String get actionSnoozeShort => 'Reporter';

  @override
  String get reminderEditTitle => 'Rappel';

  @override
  String get reminderNewTitle => 'Nouveau rappel';

  @override
  String get reminderName => 'Nom';

  @override
  String get reminderEveryDistance => 'Tous les';

  @override
  String get reminderEveryMonths => 'Tous les … mois';

  @override
  String get reminderOnceAtOdometer => 'Ou une fois, au compteur';

  @override
  String get reminderOnceOnDate => 'Ou une fois, à la date';

  @override
  String get reminderLastDoneDate => 'Dernière fois — date';

  @override
  String get reminderLastDoneOdometer => 'Dernière fois — compteur';

  @override
  String get reminderNotify => 'Me notifier';

  @override
  String get reminderNoticeAhead => 'Prévenez-moi à l’avance de';

  @override
  String reminderNoticeAutomatic(String distance, String days) {
    return 'Vide signifie automatique — $distance / $days.';
  }

  @override
  String get reminderPriority => 'Priorité';

  @override
  String get reminderPrioritySafety => 'Sécurité';

  @override
  String get reminderPriorityNormal => 'Normale';

  @override
  String get reminderPriorityLow => 'Faible';

  @override
  String get reminderRollover => 'À la répétition, compter à partir de';

  @override
  String get reminderRolloverActual => 'Du jour où c’était fait';

  @override
  String get reminderRolloverDue => 'Du jour de l’échéance';

  @override
  String get reminderRepeats => 'Se répète';

  @override
  String get reminderNotes => 'Notes';

  @override
  String get reminderNoScheduleError =>
      'Définissez un intervalle ou une date cible — sinon il n’y a rien à rappeler.';

  @override
  String get reminderBaselineTooLowError =>
      'C’est en dessous du relevé le plus ancien de ce véhicule.';

  @override
  String get reminderBaselineFutureError =>
      'Un entretien ne peut pas avoir été fait dans le futur.';

  @override
  String get reminderNameError => 'Donnez un nom à ce rappel.';

  @override
  String reminderDeletedSnack(String item) {
    return '$item supprimé';
  }

  @override
  String get reminderNotTrackedBanner =>
      'Non suivi — vous ne serez pas rappelé';

  @override
  String get reminderStartTracking => 'Commencer le suivi';

  @override
  String get reminderTurnBackOn => 'Réactiver';

  @override
  String get reminderTurnThisOff => 'Désactiver ce rappel';

  @override
  String reminderCannotDelete(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText entretiens sont enregistrés ici. Le désactiver les conserve.',
      many:
          '$nText entretiens sont enregistrés ici. Le désactiver les conserve.',
      one: '$nText entretien est enregistré ici. Le désactiver le conserve.',
    );
    return '$_temp0';
  }

  @override
  String get reminderLastDoneHeading => 'Dernières fois';

  @override
  String get reminderNoticeAheadDays => 'Prévenez-moi à l’avance de — jours';

  @override
  String get logSegmentFillUp => 'Plein';

  @override
  String get logSegmentService => 'Entretien';

  @override
  String get logSegmentExpense => 'Dépense';

  @override
  String get logSegmentOdometer => 'Compteur';

  @override
  String get logEditFillUpTitle => 'Modifier le plein';

  @override
  String get logEditServiceTitle => 'Modifier l’entretien';

  @override
  String get logEditExpenseTitle => 'Modifier la dépense';

  @override
  String get logEditOdometerTitle => 'Modifier le relevé';

  @override
  String get logSavedFillUp => 'Plein enregistré';

  @override
  String get logSavedService => 'Entretien enregistré';

  @override
  String get logSavedExpense => 'Dépense enregistrée';

  @override
  String get logSaveFillUp => 'Enregistrer le plein';

  @override
  String get logSaveService => 'Enregistrer l’entretien';

  @override
  String get logSaveExpense => 'Enregistrer la dépense';

  @override
  String get logSaveOdometer => 'Enregistrer le relevé';

  @override
  String get logDeleteFillUp => 'Supprimer ce plein';

  @override
  String get logDeleteService => 'Supprimer cet entretien';

  @override
  String get logDeleteExpense => 'Supprimer cette dépense';

  @override
  String get logDeleteOdometer => 'Supprimer ce relevé';

  @override
  String get logDiscardSummary => 'ce que vous avez saisi';

  @override
  String get logDateLabel => 'Date';

  @override
  String get logOdometerLabel => 'Compteur';

  @override
  String get logDateFutureError => 'Choisissez aujourd’hui ou un jour passé.';

  @override
  String get logOdometerRequiredError => 'Saisissez le relevé du compteur.';

  @override
  String logNumberUnclearError(String example) {
    return 'Ce nombre n’est pas clair. Essayez $example.';
  }

  @override
  String get logTitleFillUp => 'Plein';

  @override
  String get logTitleService => 'Entretien';

  @override
  String get logTitleExpense => 'Dépense';

  @override
  String get logTitleOdometer => 'Compteur';

  @override
  String logOdometerLastEntered(String distance, String date) {
    return 'Dernière saisie : $distance le $date';
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
      other: 'Dernière saisie : $distance le $date — il y a $daysText jours',
      many: 'Dernière saisie : $distance le $date — il y a $daysText jours',
      one: 'Dernière saisie : $distance le $date — il y a $daysText jour',
    );
    return '$_temp0';
  }

  @override
  String logOdometerEstimateChip(String value) {
    return '$value maintenant';
  }

  @override
  String logOdometerLastEnteredShort(String distance) {
    return 'Dernier relevé $distance';
  }

  @override
  String logOdometerSinceThen(String distance) {
    return '+$distance depuis';
  }

  @override
  String logOdometerSince(String date, String distance) {
    return '$date · +$distance';
  }

  @override
  String logOdometerDelta(String distance, String date) {
    return '+$distance depuis le $date';
  }

  @override
  String get logOdometerOlderThanAnything =>
      'Antérieur à tout ce qui est enregistré. Ce sera votre relevé le plus ancien.';

  @override
  String get logOdometerBelowLastTitle =>
      'Ce relevé est inférieur à votre dernier';

  @override
  String logOdometerBelowLastBody(String distance, String date) {
    return 'Dernière saisie : $distance le $date.';
  }

  @override
  String get logOdometerBelowLastTypo =>
      'C’est une faute de frappe — je la corrige';

  @override
  String get logOdometerBelowLastReplaced =>
      'Le compteur a été remplacé ou est revenu à zéro';

  @override
  String get logOdometerBelowLastOlder =>
      'C’est une saisie plus ancienne que j’ajoute maintenant';

  @override
  String logOdometerAboveEarliest(String distance, String date, String when) {
    return 'Votre relevé le plus ancien est $distance le $date. Un relevé de $when doit être inférieur à ce chiffre.';
  }

  @override
  String logOdometerRateWarning(String rate, String date) {
    return 'Cela fait environ $rate par jour depuis le $date. Est-ce bien cela ?';
  }

  @override
  String logOdometerUnitMixUpWarning(String value) {
    return 'Vouliez-vous dire $value ? Cela ressemble à des kilomètres.';
  }

  @override
  String logOdometerJumpWarning(String distance) {
    return 'C’est un bond de $distance. Est-ce bien cela ?';
  }

  @override
  String get logOdometerSwitchUnitPrompt =>
      'Afficher désormais tous vos relevés en kilomètres ?';

  @override
  String get logOdometerUnitChipLabel => 'Unité pour cette saisie';

  @override
  String get logOdometerPadClear => 'Effacer';

  @override
  String get logOdometerPadBackspace => 'Supprimer le dernier chiffre';

  @override
  String get expenseCategoryInsurance => 'Assurance';

  @override
  String get expenseCategoryTaxRegistration => 'Taxe de circulation';

  @override
  String get expenseCategoryParking => 'Stationnement';

  @override
  String get expenseCategoryToll => 'Péage';

  @override
  String get expenseCategoryFine => 'Amende';

  @override
  String get expenseCategoryWash => 'Lavage';

  @override
  String get expenseCategoryTyreStorage => 'Stockage des pneus';

  @override
  String get expenseCategoryAccessories => 'Accessoire';

  @override
  String get expenseCategoryFinance => 'Financement';

  @override
  String get expenseCategoryOther => 'Autre';

  @override
  String get logExpenseCategoryLabel => 'Catégorie';

  @override
  String get logExpenseCategoryError => 'Choisissez à quoi cela correspond.';

  @override
  String get logExpenseNameLabel => 'De quoi s’agissait-il ?';

  @override
  String get logExpenseNameError => 'Donnez un nom à cette dépense.';

  @override
  String get logExpenseAmountLabel => 'Montant';

  @override
  String get logExpenseAmountError => 'Saisissez ce que vous avez payé.';

  @override
  String get logExpenseRefundLabel => 'C’est un remboursement';

  @override
  String get logExpenseDatePaidLabel => 'Date de paiement';

  @override
  String get logExpenseCoversLabel => 'Couvre une période';

  @override
  String get logExpenseCoversFrom => 'Du';

  @override
  String get logExpenseCoversTo => 'Au';

  @override
  String get logExpenseCoversError =>
      'La date de fin précède la date de début.';

  @override
  String get logFillUpQuantityLabel => 'Carburant';

  @override
  String logFillUpPricePerUnitLabel(String unit) {
    return 'Prix/$unit';
  }

  @override
  String get logFillUpTotalLabel => 'Total payé';

  @override
  String get logFillUpFullTank => 'Plein complet';

  @override
  String get logFillUpPartFill => 'Plein partiel';

  @override
  String get logFillUpOverTankWarning =>
      'C\'est plus que la contenance de votre réservoir. Enregistré tel quel.';

  @override
  String get logFillUpPartFillHint =>
      'Les pleins partiels ne donnent pas de valeur à eux seuls. Celui-ci sera ajouté à votre prochain plein complet.';

  @override
  String get logFillUpTrioError =>
      'Saisissez la quantité de carburant, puis le prix au litre ou le total.';

  @override
  String get logFillUpQuantityError =>
      'La quantité doit être supérieure à zéro.';

  @override
  String get logFillUpPriceError => 'Le prix ne peut pas être négatif.';

  @override
  String logFillUpTotalError(String zero) {
    return 'Le total ne peut pas être négatif. Un plein gratuit vaut $zero.';
  }

  @override
  String get logFillUpFirstEver =>
      'Votre première valeur de consommation arrivera au prochain plein complet.';

  @override
  String get logServiceWhatWasDone => 'Ce qui a été fait';

  @override
  String get logServiceTickResets => 'Cocher réinitialise le rappel.';

  @override
  String get logServiceOther => '+ Autre';

  @override
  String get logServiceCostLabel => 'Coût';

  @override
  String get logServiceSplit => 'Répartir le coût par élément';

  @override
  String logServiceCostError(String zero) {
    return 'Le coût ne peut pas être négatif. Une intervention sous garantie vaut $zero.';
  }

  @override
  String logServiceCostEmptyError(String zero) {
    return 'Saisissez le coût, ou $zero.';
  }

  @override
  String get logServiceGenericLine => 'Entretien';

  @override
  String get logMoreRow => 'Plus';

  @override
  String get logMoreFillUpSummary => 'Station · Carburant · Trajet';

  @override
  String get logMoreServiceSummary => 'Garage · Facture';

  @override
  String get logMoreExpenseSummary => 'Payé à · Notes';

  @override
  String get logFillUpStation => 'Station';

  @override
  String get logFillUpGrade => 'Carburant';

  @override
  String get logFillUpChainBroken =>
      'J’ai oublié d’enregistrer un plein avant celui-ci';

  @override
  String get logFillUpChainBrokenHint =>
      'Vos valeurs de consommation repartent de ce plein.';

  @override
  String get logServiceWorkshop => 'Garage';

  @override
  String get logServiceInvoice => 'N° de facture';

  @override
  String get logNotes => 'Notes';

  @override
  String get logExpensePaidTo => 'Payé à';

  @override
  String logDoneTitle(String item) {
    return '$item effectué';
  }

  @override
  String logDoneNextBoth(String odometer, String date) {
    return 'Prochaine échéance à $odometer ou $date — au premier des deux';
  }

  @override
  String logDoneNextDistance(String odometer) {
    return 'Prochaine échéance à $odometer';
  }

  @override
  String logDoneNextDate(String date) {
    return 'Prochaine échéance $date';
  }

  @override
  String get logDoneClose => 'Fermer';

  @override
  String deleteFillUpRecalculated(String segment) {
    return 'Supprimer ce plein ? La consommation pour $segment sera recalculée.';
  }

  @override
  String deleteFillUpFiguresRemoved(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Supprimer ce plein ? $nText valeurs de consommation seront supprimées.',
      many:
          'Supprimer ce plein ? $nText de valeurs de consommation seront supprimées.',
      one: 'Supprimer ce plein ? $nText valeur de consommation sera supprimée.',
    );
    return '$_temp0';
  }

  @override
  String get deleteFillUpPlain => 'Supprimer ce plein ?';

  @override
  String deleteServiceResets(String items) {
    return 'Supprimer cet entretien ? $items redeviendront dus à partir de l’intervention précédente.';
  }

  @override
  String get deleteServicePlain => 'Supprimer cet entretien ?';

  @override
  String deleteTripKeepsCosts(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Supprimer ce trajet ? Ses $nText dépenses restent — elles ne seront simplement plus rattachées à un trajet.',
      many:
          'Supprimer ce trajet ? Ses $nText de dépenses restent — elles ne seront simplement plus rattachées à un trajet.',
      one:
          'Supprimer ce trajet ? Sa $nText dépense reste — elle ne sera simplement plus rattachée à un trajet.',
    );
    return '$_temp0';
  }

  @override
  String get deleteTripPlain => 'Supprimer ce trajet ?';

  @override
  String get deleteReadingPlain => 'Supprimer ce relevé ?';

  @override
  String get deleteExpensePlain => 'Supprimer cette dépense ?';

  @override
  String deleteBlockedOnlyReading(String vehicle) {
    return 'C’est le seul relevé de compteur pour $vehicle. Chaque voiture en a besoin d’un.';
  }

  @override
  String deleteBlockedStartsCorrection(String date) {
    return 'Ce relevé démarre une correction de compteur depuis $date. Supprimez d’abord la correction.';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listPairJoin(String head, String last) {
    return '$head et $last';
  }

  @override
  String get reportTitle => 'Rapport d’entretien';

  @override
  String get reportIncludeHeading => 'Inclure dans le document';

  @override
  String get reportToggleCosts => 'Coûts';

  @override
  String get reportToggleFuel => 'Consommation';

  @override
  String get reportTogglePlateVin => 'Plaque et VIN';

  @override
  String get reportToggleNotes => 'Mes notes privées';

  @override
  String get reportNotesWarning =>
      'Vos notes peuvent contenir des choses qu’un acheteur ne devrait pas lire.';

  @override
  String get reportSharePdf => 'Partager le PDF';

  @override
  String get reportCopyAsText => 'Copier en texte';

  @override
  String get reportPaperSize => 'Format de papier';

  @override
  String get reportEmptyTitle => 'Aucun entretien enregistré';

  @override
  String get reportEmptyBody =>
      'Ce rapport prend de la valeur dès que vous en ajoutez.';

  @override
  String get reportShareDisabledReason =>
      'Il n’y a pas encore d’entretiens à mettre dans un rapport.';

  @override
  String reportOwnedSince(String date) {
    return 'Possédée depuis $date';
  }

  @override
  String reportGeneratedFooter(String date, String iso) {
    return 'Généré par Odova le $date ($iso) à partir des relevés du propriétaire. Non vérifié par un tiers.';
  }

  @override
  String get reportEstimatedFootnote =>
      '~ compteur estimé à l’époque, non relevé sur la voiture.';

  @override
  String get reportNoRecordHeading =>
      'Aucun enregistrement dans cette application';

  @override
  String reportServiceCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText entretiens',
      many: '$nText d’entretiens',
      one: '$nText entretien',
    );
    return '$_temp0';
  }

  @override
  String reportOwnershipSpan(String years, String months) {
    return '$years a $months mo';
  }

  @override
  String reportInvoiceRef(String ref) {
    return 'Facture $ref';
  }

  @override
  String reportOdometerSpan(String from, String to) {
    return '$from – $to';
  }

  @override
  String get reportColumnDate => 'Date';

  @override
  String get reportColumnOdometer => 'Compteur';

  @override
  String get reportColumnWork => 'Travaux effectués';

  @override
  String get reportColumnCost => 'Coût';

  @override
  String reportPageOf(String n, String total) {
    return 'Page $n sur $total';
  }

  @override
  String get reportOwnedLabel => 'Possédée';

  @override
  String get reportServicesLabel => 'entretiens';

  @override
  String get costsTitle => 'Coûts';

  @override
  String get costsRangeThisYear => 'Cette année';

  @override
  String get costsRangeAll => 'Tout';

  @override
  String get costsPerMonth => 'par mois';

  @override
  String get costsWhereMoneyGoes => 'Où va l’argent';

  @override
  String get costsAccrualNote =>
      'Les coûts annuels comme l’assurance sont répartis sur les mois couverts.';

  @override
  String costsThisMonthSoFar(String amount) {
    return 'Ce mois-ci jusqu’ici : $amount';
  }

  @override
  String get costsEmptyTitle => 'Aucun coût pour l’instant.';

  @override
  String get costsEmptyAction => 'Enregistrer quelque chose';

  @override
  String get costsCategoryFuel => 'Carburant';

  @override
  String get costsCategoryService => 'Entretien et réparations';

  @override
  String get costsCategoryInsuranceTax => 'Assurance et taxe';

  @override
  String get costsCategoryFinance => 'Financement';

  @override
  String get costsCategoryParkingTolls => 'Stationnement et péages';

  @override
  String get costsCategoryOther => 'Autre';

  @override
  String get costsFuelRow => 'Carburant et consommation';

  @override
  String get costsTripsRow => 'Trajets';

  @override
  String get costsNoCompletedMonth =>
      'Revenez après la fin du mois — il n’y a pas encore de mois complet à moyenner.';

  @override
  String get costsNotEnoughDistance =>
      'Pas assez de distance enregistrée sur cette période pour calculer un coût par kilomètre.';

  @override
  String costsBoundaryStale(String days) {
    return 'Calculé à partir de relevés distants de $days jours des dates affichées.';
  }

  @override
  String get costsUpdateOdometer => 'Mettre à jour le compteur';

  @override
  String costsRangeMonths(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText mois',
      many: '$nText de mois',
      one: '$nText mois',
    );
    return '$_temp0';
  }

  @override
  String costsHeadlineCaption(String vehicle, String range) {
    return '$vehicle · $range';
  }

  @override
  String get costsRangeThisYearSoFar => 'cette année jusqu’ici';

  @override
  String costsSpanCaption(String from, String to) {
    return '$from – $to';
  }

  @override
  String costsPerKilometre(String amount) {
    return '$amount par kilomètre';
  }

  @override
  String costsPerMile(String amount) {
    return '$amount par mile';
  }

  @override
  String costsInMonths(int n, String nText, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$amount en $nText mois',
      many: '$amount en $nText de mois',
      one: '$amount en $nText mois',
    );
    return '$_temp0';
  }

  @override
  String get costsAllVehicles => 'Tous les véhicules';

  @override
  String get costsIncludeInactive => 'Inclure vendus et archivés';

  @override
  String costsHiddenVehicles(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText véhicules masqués',
      many: '$nText de véhicules masqués',
      one: '$nText véhicule masqué',
    );
    return '$_temp0';
  }

  @override
  String costsBusinessRow(String share, String amount) {
    return 'Professionnel $share% · $amount';
  }

  @override
  String get costsBusinessCaption =>
      'Calculé à partir des trajets enregistrés, pas de toute votre conduite.';

  @override
  String get costsVehicleSold => 'Vendu';

  @override
  String get costsVehicleArchived => 'Archivé';

  @override
  String get fuelTitle => 'Carburant et consommation';

  @override
  String get fuelConsumptionPerTank => 'Consommation par plein';

  @override
  String get fuelEmptyTitle => 'Aucun plein pour l’instant.';

  @override
  String get fuelEmptyAction => 'Enregistrer un plein';

  @override
  String get fuelFirstFigure =>
      'Votre premier chiffre arrivera au prochain plein complet.';

  @override
  String get tripsTitle => 'Trajets';

  @override
  String get tripsEmptyTitle => 'Aucun trajet pour l’instant.';

  @override
  String get tripsEmptyBody =>
      'Enregistrez-en un pour voir ce que coûte un trajet.';

  @override
  String get tripsAddAction => 'Ajouter un trajet';

  @override
  String get tripsOpenBadge => 'En cours';

  @override
  String get tripsFinishAction => 'Terminer ce trajet';

  @override
  String get tripsPurposeBusiness => 'Professionnel';

  @override
  String get tripsPurposeCommute => 'Domicile-travail';

  @override
  String get tripsPurposePersonal => 'Personnel';

  @override
  String get tripsPurposeOther => 'Autre';

  @override
  String tripsLoggedLabel(String unit) {
    return '$unit enregistrés';
  }

  @override
  String get tripsBusinessLabel => 'professionnel';

  @override
  String get tripsCostsLabel => 'coûts des trajets';

  @override
  String get tripsEarlier => 'Plus tôt';

  @override
  String tripsCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText trajets',
      many: '$nText trajets',
      one: '$nText trajet',
      zero: 'Aucun trajet',
    );
    return '$_temp0';
  }

  @override
  String tripsStartedFrom(String date, String odometer) {
    return 'Commencé $date · depuis $odometer';
  }

  @override
  String tripsStartedOn(String date) {
    return 'Commencé $date';
  }

  @override
  String get tripsNoEndReading => 'pas encore de relevé de fin';

  @override
  String tripsBusinessValue(String percent) {
    return '$percent %';
  }

  @override
  String get tripEditTitle => 'Modifier le trajet';

  @override
  String get tripNewTitle => 'Trajet';

  @override
  String get tripSaveAction => 'Enregistrer le trajet';

  @override
  String get tripPurposeLabel => 'Motif';

  @override
  String get tripTitleLabel => 'Titre';

  @override
  String get tripStartsLabel => 'Début';

  @override
  String get tripEndsLabel => 'Fin';

  @override
  String get tripStillGoing => 'En cours';

  @override
  String get tripStartOdometerLabel => 'Compteur au début';

  @override
  String get tripEndOdometerLabel => 'Compteur à la fin';

  @override
  String get tripDistanceLabel => 'Distance';

  @override
  String get tripExpensesLabel => 'Dépenses';

  @override
  String get tripAddExpense => 'Ajouter une dépense';

  @override
  String get tripNoExpenses => 'Rien n’est encore imputé à ce trajet.';

  @override
  String get tripDeleteAction => 'Supprimer le trajet';

  @override
  String get tripStartInFuture => 'Choisissez aujourd’hui ou un jour passé.';

  @override
  String get tripEndBeforeStart => 'La date de fin précède la date de début.';

  @override
  String get tripEndBelowStart =>
      'Le relevé de fin est inférieur au relevé de début.';

  @override
  String get tripDistanceNotPositive =>
      'La distance doit être supérieure à zéro.';

  @override
  String get tripSavedToast => 'Trajet enregistré';

  @override
  String get tripSaveFirstToAddExpense =>
      'Enregistrez d’abord le trajet, puis imputez-lui des dépenses.';

  @override
  String get costsEstimateTitle => 'Comment ce chiffre est obtenu';

  @override
  String costsEstimateStaleBoundary(String days) {
    return 'Calculé à partir de relevés distants de $days jours des dates affichées.';
  }

  @override
  String get costsEstimateNotEnoughDistance =>
      'Pas assez de distance enregistrée sur cette période pour calculer un coût au kilomètre.';

  @override
  String get costsEstimateNoCompletedMonth =>
      'Revenez après la fin du mois — il n’y a pas encore de mois complet à moyenner.';

  @override
  String get costsEstimateNoReadings =>
      'Aucun relevé de compteur sur cette période pour mesurer un écart.';

  @override
  String get fuelEmptyBody =>
      'Votre première consommation apparaîtra au deuxième plein.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsBackupRow => 'Sauvegarde et restauration';

  @override
  String get settingsBackupNever => 'Vous n’avez jamais fait de sauvegarde.';

  @override
  String settingsBackupLast(String date, String ago) {
    return 'Dernière sauvegarde $date — $ago';
  }

  @override
  String get settingsBackupMigrationFailed =>
      'Odova n’a pas pu terminer la mise à jour.';

  @override
  String get settingsVehiclesRow => 'Véhicules';

  @override
  String settingsVehicleCount(int n, String nText) {
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
  String get settingsUnitsRow => 'Unités et formats';

  @override
  String get settingsNotificationsRow => 'Notifications';

  @override
  String settingsNotificationsValue(String state, String time) {
    return '$state · $time';
  }

  @override
  String get settingsNotificationsOn => 'Activé';

  @override
  String get settingsNotificationsOff => 'Désactivé';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsAboutRow => 'À propos';

  @override
  String get settingsLanguageRow => 'Langue';

  @override
  String get settingsLanguageNote =>
      'Odova est traduit dans ces six langues. Les nombres, les dates et les unités se règlent séparément sous « Unités et formats ».';

  @override
  String get unitsPreviewLabel => 'Aperçu';

  @override
  String get unitsGroupMeasurement => 'Mesures';

  @override
  String get unitsGroupDatesNumbers => 'Dates et nombres';

  @override
  String get unitsRowDistance => 'Distance';

  @override
  String get unitsRowVolume => 'Volume';

  @override
  String get unitsRowConsumption => 'Consommation';

  @override
  String get unitsRowCurrency => 'Devise';

  @override
  String get unitsRowCalendar => 'Calendrier';

  @override
  String get unitsRowNumerals => 'Chiffres';

  @override
  String get unitsRowFirstDay => 'Premier jour de la semaine';

  @override
  String get unitsDistanceKm => 'Kilomètres (km)';

  @override
  String get unitsDistanceMi => 'Milles (mi)';

  @override
  String get unitsVolumeLitre => 'Litres (L)';

  @override
  String get unitsVolumeGalUs => 'Gallons US';

  @override
  String get unitsVolumeGalUk => 'Gallons impériaux';

  @override
  String get unitsCalendarGregorian => 'Grégorien';

  @override
  String get unitsCalendarPersian => 'Jalali';

  @override
  String get unitsNumeralsAuto => 'Automatique';

  @override
  String unitsNumeralsLatin(String digits) {
    return 'Latins ($digits)';
  }

  @override
  String unitsNumeralsLocal(String digits) {
    return 'Locaux ($digits)';
  }

  @override
  String unitsConsumptionSuggested(String distance, String volume) {
    return 'Suggéré pour $distance et $volume';
  }

  @override
  String get unitsFooter =>
      'Ces réglages changent seulement l’affichage. Rien de ce que vous avez déjà saisi n’est modifié.';

  @override
  String get unitsCurrencyRecent => 'Récentes';

  @override
  String get unitsCurrencyAll => 'Toutes les devises';

  @override
  String get unitsCurrencySearch => 'Rechercher une devise';

  @override
  String get commonSeparator => ' · ';

  @override
  String get notifGroupWhat => 'Ce qu’Odova envoie';

  @override
  String get notifGroupWhen => 'Quand';

  @override
  String get notifGroupHowFar => 'Combien de temps avant';

  @override
  String get notifAllowed => 'Autorisé';

  @override
  String get notifRowService => 'Rappels d’entretien';

  @override
  String get notifRowOdometer => 'Relevés de compteur';

  @override
  String get notifRowBackup => 'Rappels de sauvegarde';

  @override
  String get notifRowTimeOfDay => 'Heure';

  @override
  String get notifRowQuietHours => 'Heures silencieuses';

  @override
  String get notifRowByDistance => 'Par distance';

  @override
  String get notifRowByTime => 'Par durée';

  @override
  String get notifAutomatic => 'Automatique';

  @override
  String notifAutomaticNote(String percent) {
    return 'Automatique, c’est environ $percent% avant l’échéance.';
  }

  @override
  String get notifCapFooter =>
      'Deux notifications par semaine au maximum. Jamais deux le même jour.';

  @override
  String get notifQuietOff => 'Désactivées';

  @override
  String get notifOffTitle => 'Les rappels sont désactivés.';

  @override
  String get notifOffAction => 'Activer les rappels';

  @override
  String get notifBlockedTitle =>
      'Odova ne peut pas envoyer de rappels : les notifications sont désactivées pour Odova dans les réglages du téléphone.';

  @override
  String get notifBlockedAction => 'Ouvrir les réglages du téléphone';

  @override
  String get notifBackgroundTitle =>
      'Votre téléphone empêche peut-être les rappels d’Odova.';

  @override
  String get notifSilentFooter =>
      'Odova ne vous enverra rien. Ce qui est dû reste affiché sur l’écran d’accueil.';

  @override
  String get notifRowCalendar => 'Ajouter les rappels à mon calendrier';

  @override
  String get aboutPrivacy =>
      'Pas de compte. Pas d’inscription. Pas de serveur. Rien n’est envoyé. Pas de suivi, pas d’analyse, pas de publicité.';

  @override
  String get aboutBackupWarning =>
      'Vos données ne sont que sur ce téléphone. Si vous le perdez sans sauvegarde, elles sont perdues.';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String aboutBackupFormat(String format) {
    return 'Format de sauvegarde $format';
  }

  @override
  String get aboutLicencesRow => 'Licences open source';

  @override
  String get unitConsumptionMpgUs => 'mpg (US)';

  @override
  String get unitConsumptionMpgUk => 'mpg (imp.)';

  @override
  String get commonListSeparator => ', ';

  @override
  String importFailTooLarge(String size) {
    return 'Ce fichier est trop volumineux pour une sauvegarde Odova ($size). Même une décennie d’enregistrements ne pèse que quelques mégaoctets : c’est probablement un autre fichier.';
  }

  @override
  String get importFailCompressed =>
      'Ce fichier est compressé. Décompressez-le d’abord, puis importez le fichier .json qu’il contient.';

  @override
  String get importFailNotUtf8 =>
      'Odova ne parvient pas à lire le texte de ce fichier. Un autre programme l’a peut-être modifié. Essayez le fichier que vous avez exporté à l’origine.';

  @override
  String get importFailTruncated =>
      'Ce fichier est incomplet. Son téléchargement ou sa copie ne s’est peut-être pas terminé. Récupérez le fichier et réessayez.';

  @override
  String get importFailNotOdova =>
      'Ce fichier n’est pas une sauvegarde Odova. Les sauvegardes Odova sont des fichiers .json créés depuis Réglages → Exporter. Choisissez un autre fichier.';

  @override
  String get importFailNotMadeByOdova =>
      'Ce fichier n’a pas été créé par Odova. Il est valide, mais Odova ne peut pas le lire. Rien n’a changé sur votre téléphone.';

  @override
  String get importFailTooNew =>
      'Cette sauvegarde a été créée avec une version plus récente d’Odova. Mettez Odova à jour, puis réimportez. Votre fichier n’a pas été modifié.';

  @override
  String get importFailDamagedVersion =>
      'Ce fichier de sauvegarde est endommagé et Odova ne peut pas déterminer sa version. Si vous avez une autre copie ou une sauvegarde plus ancienne, essayez celle-là.';

  @override
  String get importFailDamagedFile =>
      'Ce fichier de sauvegarde est endommagé et Odova ne peut pas en lire le contenu. Si vous avez une autre copie ou une sauvegarde plus ancienne, essayez celle-là.';

  @override
  String get importFailCannotOpen =>
      'Odova n’a pas pu ouvrir ce fichier. Copiez-le d’abord dans l’application Fichiers de votre téléphone, puis importez-le depuis là.';

  @override
  String importFailNotEnoughSpace(String size) {
    return 'Espace insuffisant sur votre téléphone pour importer cette sauvegarde. Libérez environ $size et réessayez.';
  }

  @override
  String importFailTooDamaged(String readable, String total) {
    return 'Cette sauvegarde est trop endommagée pour être importée sans risque. Odova a pu lire $readable enregistrements sur $total, et n’importer qu’une partie laisserait des trous. Essayez une sauvegarde plus ancienne si vous en avez une. Rien n’a changé sur votre téléphone.';
  }

  @override
  String get importWarnContentHash =>
      'Ce fichier a été modifié depuis qu’Odova l’a enregistré. Ce n’est pas un problème si c’était volontaire. Vérifiez les chiffres ci-dessous avant de continuer.';

  @override
  String importWarnRecordCount(String declared, String found) {
    return 'Ce fichier ne contient pas tout ce qu’il annonce : il indique $declared enregistrements et $found ont été trouvés. Il a peut-être été tronqué. Vérifiez les chiffres ci-dessous.';
  }

  @override
  String get importWarnMissingArray =>
      'Une partie de cette sauvegarde est absente. Tout ce qu’Odova a pu trouver sera quand même importé.';

  @override
  String importWarnSkipped(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText enregistrements n’ont pas pu être lus et ne seront pas importés. Tout le reste le sera. Touchez pour voir lesquels.',
      many:
          '$nText enregistrements n’ont pas pu être lus et ne seront pas importés. Tout le reste le sera. Touchez pour voir lesquels.',
      one:
          '$nText enregistrement n’a pas pu être lu et ne sera pas importé. Tout le reste le sera. Touchez pour voir lequel.',
    );
    return '$_temp0';
  }

  @override
  String importWarnOrphans(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText enregistrements n’indiquent pas leur véhicule. Ils seront importés sous un véhicule nommé « Enregistrements récupérés » pour que vous puissiez les reclasser ou les supprimer.',
      many:
          '$nText enregistrements n’indiquent pas leur véhicule. Ils seront importés sous un véhicule nommé « Enregistrements récupérés » pour que vous puissiez les reclasser ou les supprimer.',
      one:
          '$nText enregistrement n’indique pas son véhicule. Il sera importé sous un véhicule nommé « Enregistrements récupérés » pour que vous puissiez le reclasser ou le supprimer.',
    );
    return '$_temp0';
  }

  @override
  String importWarnUnmatchedCorrections(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText corrections de compteur n’ont pas pu être rattachées à un relevé. Votre historique de kilométrage peut sembler faux là où le compteur a été remplacé. Touchez pour voir lesquelles.',
      many:
          '$nText corrections de compteur n’ont pas pu être rattachées à un relevé. Votre historique de kilométrage peut sembler faux là où le compteur a été remplacé. Touchez pour voir lesquelles.',
      one:
          '$nText correction de compteur n’a pas pu être rattachée à un relevé. Votre historique de kilométrage peut sembler faux là où le compteur a été remplacé. Touchez pour voir laquelle.',
    );
    return '$_temp0';
  }

  @override
  String importWarnDroppedRules(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText rappels utilisaient un réglage qu’Odova n’a plus. Ils vous préviennent désormais au premier des deux — vérifiez-les dans Rappels.',
      many:
          '$nText rappels utilisaient un réglage qu’Odova n’a plus. Ils vous préviennent désormais au premier des deux — vérifiez-les dans Rappels.',
      one:
          '$nText rappel utilisait un réglage qu’Odova n’a plus. Il vous prévient désormais au premier des deux — vérifiez-le dans Rappels.',
    );
    return '$_temp0';
  }

  @override
  String importWarnCoercedEnums(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText enregistrements utilisaient des réglages qu’Odova ne connaît pas. Ils ont été importés avec les réglages d’Odova à la place.',
      many:
          '$nText enregistrements utilisaient des réglages qu’Odova ne connaît pas. Ils ont été importés avec les réglages d’Odova à la place.',
      one:
          '$nText enregistrement utilisait un réglage qu’Odova ne connaît pas. Il a été importé avec le réglage d’Odova à la place.',
    );
    return '$_temp0';
  }

  @override
  String importWarnOutOfRangeDates(int n, String nText, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText enregistrements ont des dates qui semblent erronées — avant $year, ou après la création de cette sauvegarde. Ils ont été importés pour que vous puissiez les corriger.',
      many:
          '$nText enregistrements ont des dates qui semblent erronées — avant $year, ou après la création de cette sauvegarde. Ils ont été importés pour que vous puissiez les corriger.',
      one:
          '$nText enregistrement a une date qui semble erronée — avant $year, ou après la création de cette sauvegarde. Il a été importé pour que vous puissiez le corriger.',
    );
    return '$_temp0';
  }

  @override
  String importWarnUnresolvedLinks(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$nText enregistrements renvoyaient à un trajet ou un rappel absent de ce fichier. Ils ont été importés sans ce lien.',
      many:
          '$nText enregistrements renvoyaient à un trajet ou un rappel absent de ce fichier. Ils ont été importés sans ce lien.',
      one:
          '$nText enregistrement renvoyait à un trajet ou un rappel absent de ce fichier. Il a été importé sans ce lien.',
    );
    return '$_temp0';
  }

  @override
  String importWarnDuplicateIds(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Ce fichier liste $nText enregistrements deux fois. Odova importera la première copie de chacun.',
      many:
          'Ce fichier liste $nText enregistrements deux fois. Odova importera la première copie de chacun.',
      one:
          'Ce fichier liste $nText enregistrement deux fois. Odova importera la première copie.',
    );
    return '$_temp0';
  }

  @override
  String importWarnTruncatedStrings(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText notes étaient trop longues et ont été raccourcies.',
      many: '$nText notes étaient trop longues et ont été raccourcies.',
      one: '$nText note était trop longue et a été raccourcie.',
    );
    return '$_temp0';
  }

  @override
  String importSuccess(String vehicles, String records) {
    return 'Importé. $vehicles et $records restaurés. Vos rappels ont été recalculés.';
  }

  @override
  String importRecordCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText enregistrements',
      many: '$nText enregistrements',
      one: '$nText enregistrement',
    );
    return '$_temp0';
  }

  @override
  String get importRecoveredVehicleName => 'Enregistrements récupérés';

  @override
  String get importTypeVehicle => 'Véhicule';

  @override
  String get importTypeReminder => 'Rappel';

  @override
  String get importTypeReading => 'Relevé de compteur';

  @override
  String get importTypeCorrection => 'Correction de compteur';

  @override
  String get importTypeFillup => 'Plein';

  @override
  String get importTypeService => 'Entretien';

  @override
  String get importTypeExpense => 'Dépense';

  @override
  String get importTypeTrip => 'Trajet';

  @override
  String get importSkipDate => 'la date était absente';

  @override
  String get importSkipFuel => 'la quantité de carburant était absente';

  @override
  String get importSkipMoney => 'le montant était absent';

  @override
  String get importSkipCurrency => 'la devise n’était pas reconnue par Odova';

  @override
  String get importSkipCorrection =>
      'le relevé qu’elle corrige est absent de ce fichier';

  @override
  String get importSkipIncomplete => 'une partie était absente';

  @override
  String importSkipEntry(String type, String date, String reason) {
    return '$type, $date — $reason';
  }

  @override
  String importSkipEntryNoDate(String type, String reason) {
    return '$type — $reason';
  }

  @override
  String get backupTitle => 'Sauvegarde et restauration';

  @override
  String get backupLastLabel => 'Dernière sauvegarde';

  @override
  String get backupNever => 'Vous n’avez jamais fait de sauvegarde.';

  @override
  String backupEntriesSince(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText entrées depuis',
      many: '$nText entrées depuis',
      one: '$nText entrée depuis',
    );
    return '$_temp0';
  }

  @override
  String backupEntriesOnlyHere(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText entrées n’existent que sur ce téléphone.',
      many: '$nText entrées n’existent que sur ce téléphone.',
      one: '$nText entrée n’existe que sur ce téléphone.',
    );
    return '$_temp0';
  }

  @override
  String get backupNow => 'Sauvegarder maintenant';

  @override
  String get backupNothingToBackUp => 'Rien à sauvegarder pour l’instant.';

  @override
  String get backupPreparing => 'Préparation de votre sauvegarde…';

  @override
  String get backupNotEncrypted =>
      'Votre fichier de sauvegarde n’est pas protégé par mot de passe. Quiconque l’ouvre peut tout y lire.';

  @override
  String get backupAlsoExport => 'Exporter aussi';

  @override
  String get backupFillUpsCsv => 'Pleins (CSV)';

  @override
  String get backupAllCostsCsv => 'Tous les coûts (CSV)';

  @override
  String get backupServiceHistoryPdf => 'Historique d’entretien (PDF)';

  @override
  String get backupRestoreHeader => 'Restaurer';

  @override
  String get backupRestoreRow => 'Restaurer depuis une sauvegarde';

  @override
  String get backupUndoImport => 'Annuler le dernier import';

  @override
  String get backupUndoWipe => 'Annuler la suppression de toutes les données';

  @override
  String backupUndoUntil(String date) {
    return 'Jusqu’au $date';
  }

  @override
  String get backupCopiesGoOnUninstall =>
      'Ces copies sont supprimées si vous désinstallez Odova.';

  @override
  String backupOnDiskSize(String size) {
    return 'Odova utilise $size sur ce téléphone.';
  }

  @override
  String get backupDeleteAll => 'Supprimer toutes les données';

  @override
  String get backupDeleteWord => 'SUPPRIMER';

  @override
  String get backupMigrationBanner =>
      'Odova n’a pas pu terminer la mise à jour et est revenu à vos données précédentes. Vous ne pouvez rien ajouter tant que ce n’est pas réglé — sauvegardez maintenant.';

  @override
  String backupExportNoSpace(String size) {
    return 'Il n’y a pas assez d’espace libre pour sauvegarder. Il faut environ $size. Libérez de l’espace et réessayez.';
  }

  @override
  String get backupExportWriteFailed =>
      'Odova n’a pas pu terminer la sauvegarde. Rien n’a changé sur ce téléphone. Réessayez dans un instant.';

  @override
  String get backupExportNoShare =>
      'Ce téléphone ne laisse pas Odova transmettre le fichier à une autre application. Vos données sont intactes — réessayez après avoir redémarré le téléphone.';

  @override
  String get backupDeleteAllTitle => 'Tout supprimer ?';

  @override
  String backupDeleteAllBody(String vehicles, String entries, String since) {
    return 'Cela supprime $vehicles et $entries, remontant à $since.';
  }

  @override
  String backupDeleteAllNote(String days) {
    return 'Une copie est conservée $days jours sur ce téléphone, pour que vous puissiez annuler. Elle est supprimée si vous désinstallez Odova.';
  }

  @override
  String backupVehicleCount(int n, String nText) {
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
  String backupEntryCount(int n, String nText) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nText entrées',
      many: '$nText entrées',
      one: '$nText entrée',
    );
    return '$_temp0';
  }
}
