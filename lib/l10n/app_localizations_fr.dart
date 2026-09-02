// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navDashboardCompact => 'Accueil';

  @override
  String get navWork => 'Travail';

  @override
  String get navExpenses => 'Dépenses';

  @override
  String get navInventory => 'Matériaux';

  @override
  String get navMaintenance => 'Entretien';

  @override
  String get fieldRecords => 'Dossiers de terrain';

  @override
  String get offlineRecordsAvailable =>
      'Les dossiers restent accessibles hors ligne.';

  @override
  String get advertisementPlaceholder => 'Espace publicitaire de démonstration';

  @override
  String get advertisement => 'PUBLICITÉ';

  @override
  String get sampleAdSpace => 'Espace publicitaire';

  @override
  String get demo => 'Démo';

  @override
  String get operationalViewLabel => 'Vue';

  @override
  String operationalViewValue(String view) {
    return 'Vue : $view';
  }

  @override
  String get operationalChangeViewTooltip => 'Changer de vue';

  @override
  String get operationalChangeContextTooltip =>
      'Changer le contexte de travail';

  @override
  String operationalContextSemantics(String context, String value) {
    return '$context : $value';
  }

  @override
  String get operationalViewTechnician => 'Technicien';

  @override
  String get operationalViewAdmin => 'Administrateur';

  @override
  String get operationalContextEmployee => 'Employé';

  @override
  String get operationalContextVehicle => 'Véhicule';

  @override
  String get operationalContextActiveVehicle => 'Véhicule actif';

  @override
  String get operationalCompanyOverview => 'Aperçu de l’entreprise';

  @override
  String get operationalFleetOverview => 'Aperçu de la flotte';

  @override
  String get operationalPreviousDay => 'Jour précédent';

  @override
  String get operationalNextDay => 'Jour suivant';

  @override
  String get operationalReturnToToday => 'Revenir à aujourd’hui';

  @override
  String operationalUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications. $count éléments non lus.',
      one: 'Notifications. 1 élément non lu.',
      zero: 'Notifications. Rien de nouveau.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHeading => 'Rappels et mises à jour';

  @override
  String get notificationsDescription =>
      'Les notifications présentent les rappels et les mises à jour. Les décisions restent dans À vérifier.';

  @override
  String get nativeReminderTitle => 'Rappel Maintainiac';

  @override
  String get nativeReminderBody =>
      'Ouvrez Maintainiac pour consulter un rappel programmé.';

  @override
  String get deviceRemindersOffTitle =>
      'Les rappels de l’appareil sont désactivés';

  @override
  String get deviceRemindersOffBody =>
      'Les rappels dans l’application fonctionnent toujours. Activez les notifications de l’appareil pour recevoir des rappels lorsque Maintainiac est fermé.';

  @override
  String get deviceRemindersEnable => 'Activer les rappels de l’appareil';

  @override
  String get deviceRemindersEnabling => 'Activation des rappels de l’appareil';

  @override
  String get deviceRemindersDenied =>
      'Les rappels de l’appareil sont toujours désactivés. Vous pouvez autoriser les notifications Maintainiac dans les réglages du système.';

  @override
  String get deviceRemindersFailed =>
      'Impossible de mettre à jour les rappels de l’appareil. Réessayez.';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsEmpty =>
      'Aucun rappel ni mise à jour n’est disponible.';

  @override
  String get notificationsLoadFailed =>
      'Impossible de charger les notifications.';

  @override
  String get notificationUnreadState => 'Non lue';

  @override
  String get notificationReadState => 'Lue';

  @override
  String get notificationDueToday => 'Échéance aujourd’hui';

  @override
  String get notificationDueTomorrow => 'Échéance demain';

  @override
  String notificationDueInDays(int count) {
    return 'Échéance dans $count jours';
  }

  @override
  String notificationDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de retard',
      one: '1 jour de retard',
    );
    return '$_temp0';
  }

  @override
  String operationalNotificationsAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications. $count éléments nécessitent votre attention.',
      one: 'Notifications. 1 élément nécessite votre attention.',
      zero: 'Notifications. Rien ne nécessite votre attention.',
    );
    return '$_temp0';
  }

  @override
  String get attentionTitle => 'À vérifier';

  @override
  String attentionShowAll(int count) {
    return 'Tout afficher ($count)';
  }

  @override
  String get attentionDismiss => 'Masquer À vérifier';

  @override
  String get attentionNothing =>
      'Rien ne nécessite votre attention pour le moment.';

  @override
  String get reportToday => 'Aujourd’hui';

  @override
  String get reportThisWeek => 'Cette semaine';

  @override
  String get reportThisMonth => 'Ce mois-ci';

  @override
  String get reportThisCalendarQuarter => 'Ce trimestre civil';

  @override
  String get reportPreviousCalendarQuarter => 'Trimestre civil précédent';

  @override
  String get reportPrevious90Days => '90 derniers jours';

  @override
  String get reportYearToDate => 'Depuis le début de l’année';

  @override
  String get reportPrevious12Months => '12 derniers mois';

  @override
  String get calendarMonthView => 'Mois';

  @override
  String get calendarWeekView => 'Semaine';

  @override
  String get calendarPreviousMonth => 'Mois précédent';

  @override
  String get calendarNextMonth => 'Mois suivant';

  @override
  String get calendarPreviousWeek => 'Semaine précédente';

  @override
  String get calendarNextWeek => 'Semaine suivante';

  @override
  String get calendarChooseWorkDate => 'Choisir une date de travail';

  @override
  String get calendarMondayShort => 'lun.';

  @override
  String get calendarTuesdayShort => 'mar.';

  @override
  String get calendarWednesdayShort => 'mer.';

  @override
  String get calendarThursdayShort => 'jeu.';

  @override
  String get calendarFridayShort => 'ven.';

  @override
  String get calendarSaturdayShort => 'sam.';

  @override
  String get calendarSundayShort => 'dim.';

  @override
  String get calendarTodayState => 'Aujourd’hui.';

  @override
  String get calendarOutsideMonthState => 'Hors du mois sélectionné.';

  @override
  String get calendarNeedsApprovalState => 'Approbation requise.';

  @override
  String get calendarRecordSingular => 'dossier';

  @override
  String get calendarRecordPlural => 'dossiers';

  @override
  String get calendarDashboardEntrySingular => 'entrée du tableau de bord';

  @override
  String get calendarDashboardEntryPlural => 'entrées du tableau de bord';

  @override
  String get calendarWorkRecordSingular => 'dossier de travail';

  @override
  String get calendarWorkRecordPlural => 'dossiers de travail';

  @override
  String get calendarJobSingular => 'travail';

  @override
  String get calendarJobPlural => 'travaux';

  @override
  String get calendarEstimateSingular => 'devis';

  @override
  String get calendarEstimatePlural => 'devis';

  @override
  String get calendarInvoiceSingular => 'facture';

  @override
  String get calendarInvoicePlural => 'factures';

  @override
  String get calendarPaymentSingular => 'paiement';

  @override
  String get calendarPaymentPlural => 'paiements';

  @override
  String get calendarExpenseSingular => 'dépense';

  @override
  String get calendarExpensePlural => 'dépenses';

  @override
  String get calendarInventoryRecordSingular => 'dossier de matériaux';

  @override
  String get calendarInventoryRecordPlural => 'dossiers de matériaux';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'Aucun élément : $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }
}

/// The translations for French, as used in Canada (`fr_CA`).
class AppLocalizationsFrCa extends AppLocalizationsFr {
  AppLocalizationsFrCa() : super('fr_CA');

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navWork => 'Travail';

  @override
  String get navExpenses => 'Dépenses';

  @override
  String get navInventory => 'Matériaux';

  @override
  String get navMaintenance => 'Entretien';

  @override
  String get fieldRecords => 'Dossiers de terrain';

  @override
  String get offlineRecordsAvailable =>
      'Les dossiers restent accessibles hors ligne.';

  @override
  String get advertisementPlaceholder => 'Espace publicitaire de démonstration';

  @override
  String get advertisement => 'PUBLICITÉ';

  @override
  String get sampleAdSpace => 'Espace publicitaire';

  @override
  String get demo => 'Démo';

  @override
  String get calendarMonthView => 'Mois';

  @override
  String get calendarWeekView => 'Semaine';

  @override
  String get calendarPreviousMonth => 'Mois précédent';

  @override
  String get calendarNextMonth => 'Mois suivant';

  @override
  String get calendarPreviousWeek => 'Semaine précédente';

  @override
  String get calendarNextWeek => 'Semaine suivante';

  @override
  String get calendarChooseWorkDate => 'Choisir une date de travail';

  @override
  String get calendarTodayState => 'Aujourd’hui.';

  @override
  String get calendarOutsideMonthState => 'Hors du mois sélectionné.';

  @override
  String get calendarNeedsApprovalState => 'Approbation requise.';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'Aucun élément : $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }
}
