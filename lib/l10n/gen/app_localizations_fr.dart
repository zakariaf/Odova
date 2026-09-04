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
      zero: 'ses entrées',
    );
    return 'Supprimer $subject et $_temp0 ?';
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
  String get confirmDeleteCancel => 'Annuler';

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
  String get snoozeCancel => 'Annuler';
}
