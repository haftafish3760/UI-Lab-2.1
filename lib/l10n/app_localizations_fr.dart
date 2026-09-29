// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get selectVehicleLabel => 'Sélectionner un véhicule';

  @override
  String get appTitle => 'Tame Your Biz';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get dashboardOdometerLabel => 'Compteur kilométrique';

  @override
  String get dashboardStartWorkday => 'Commencer la journée';

  @override
  String get dashboardPaymentsLabel => 'Paiements';

  @override
  String get dashboardMilesLabel => 'Milles';

  @override
  String get dashboardMileageUnavailable =>
      'Le total des distances professionnelles n’est pas encore connecté dans cet aperçu. Aucun total nul n’a été supposé.';

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
  String get nativeReminderTitle => 'Rappel Tame Your Biz';

  @override
  String get nativeReminderBody =>
      'Ouvrez Tame Your Biz pour consulter un rappel programmé.';

  @override
  String get deviceRemindersUnavailableTitle =>
      'Rappels de l’appareil indisponibles';

  @override
  String get deviceRemindersRetry => 'Réessayer les rappels';

  @override
  String get deviceRemindersOffTitle =>
      'Les rappels de l’appareil sont désactivés';

  @override
  String get deviceRemindersOffBody =>
      'Les rappels dans l’application fonctionnent toujours. Activez les notifications de l’appareil pour recevoir des rappels lorsque Tame Your Biz est fermé.';

  @override
  String get deviceRemindersEnable => 'Activer les rappels de l’appareil';

  @override
  String get deviceRemindersEnabling => 'Activation des rappels de l’appareil';

  @override
  String get deviceRemindersDenied =>
      'Les rappels de l’appareil sont toujours désactivés. Vous pouvez autoriser les notifications Tame Your Biz dans les réglages du système.';

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

  @override
  String get catalogBrowse => 'Parcourir le catalogue';

  @override
  String get catalogInventory => 'Mon inventaire';

  @override
  String get catalogGrid => 'Grille';

  @override
  String get catalogList => 'Liste';

  @override
  String get catalogChooseTrade => 'Choisir un métier';

  @override
  String get catalogChooseCategory => 'Choisir une catégorie';

  @override
  String get catalogSearch => 'Rechercher des articles';

  @override
  String get catalogSearchCategory => 'Rechercher dans cette catégorie';

  @override
  String get catalogClear => 'Effacer la recherche';

  @override
  String get catalogPlumbing => 'Plomberie';

  @override
  String get catalogElectrical => 'Électricité';

  @override
  String get catalogHvac => 'CVCA';

  @override
  String get catalogFittings => 'Raccords';

  @override
  String get catalogCopper => 'Cuivre';

  @override
  String get catalogElbows90 => 'Coudes à 90°';

  @override
  String get catalogItemDetails => 'Détails de l’article';

  @override
  String get catalogAdd => 'Ajouter à mon inventaire';

  @override
  String catalogSize(String size) {
    return 'Dimension nominale : $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unité : $unit';
  }

  @override
  String get catalogEach => 'unité';

  @override
  String catalogCopperElbow(String size) {
    return 'Coude en cuivre à 90° de $size';
  }

  @override
  String get catalogEmpty => 'Cette catégorie est en cours de reconstruction.';

  @override
  String get catalogNoMatches =>
      'Aucun article trouvé. Essayez un autre nom ou une autre dimension.';

  @override
  String get workFilterAwaitingCustomer => 'Estimations en attente du client';

  @override
  String get workFilterUnscheduledJobs => 'Travaux à planifier';

  @override
  String get workFilterActiveJobs => 'Travaux en cours';

  @override
  String get workFilterUnpaidInvoices => 'Factures impayées';

  @override
  String get workFilterAllEstimates => 'Toutes les estimations';

  @override
  String get workFilterDraftEstimates => 'Brouillons d’estimations';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimations en attente d’approbation de l’entreprise';

  @override
  String get workFilterReadyEstimates => 'Estimations prêtes à envoyer';

  @override
  String get workFilterChangedEstimates =>
      'Estimations avec modifications demandées';

  @override
  String get workFilterApprovedEstimates => 'Estimations approuvées';

  @override
  String get workFilterDeclinedEstimates => 'Estimations refusées';

  @override
  String get workFilterExpiredEstimates => 'Estimations expirées';

  @override
  String get workFilterAllJobs => 'Tous les travaux';

  @override
  String get workFilterCompletedJobs => 'Travaux terminés';

  @override
  String get workFilterAllInvoices => 'Toutes les factures';

  @override
  String get workFilterDraftInvoices => 'Brouillons de factures';

  @override
  String get workFilterPaidInvoices => 'Factures payées intégralement';

  @override
  String get workFilterOverdueInvoices => 'Factures en retard';

  @override
  String get workStatusDraft => 'Brouillon';

  @override
  String get workStatusReady => 'Prêt';

  @override
  String get workStatusSent => 'Envoyé';

  @override
  String get workStatusAccepted => 'Accepté';

  @override
  String get workStatusScheduled => 'Planifié';

  @override
  String get workStatusEnRoute => 'En route';

  @override
  String get workStatusArrived => 'Sur place';

  @override
  String get workStatusInProgress => 'En cours';

  @override
  String get workStatusPaused => 'En pause';

  @override
  String get workStatusNeedsReturnVisit => 'Visite supplémentaire requise';

  @override
  String get workStatusCompleted => 'Terminé';

  @override
  String get workStatusDue => 'À payer';

  @override
  String get workStatusPaid => 'Payé';

  @override
  String get workStatusReadyToSend => 'Prêt à envoyer';

  @override
  String get workStatusAwaitingCustomer => 'En attente du client';

  @override
  String get workStatusViewed => 'Consulté';

  @override
  String get workStatusChangesRequested => 'Modifications demandées';

  @override
  String get workStatusApproved => 'Approuvé';

  @override
  String get workStatusDeclined => 'Refusé';

  @override
  String get workStatusExpired => 'Expiré';

  @override
  String get workStatusConverted => 'Converti en travail';

  @override
  String get workStatusArchived => 'Archivé';

  @override
  String get workOverviewHeading => 'Aperçu du travail · Toutes les dates';

  @override
  String get workBrowseRecords => 'Consulter les dossiers';

  @override
  String get workRecordsHeading => 'Dossiers de travail';

  @override
  String get workShowRecords => 'Afficher les dossiers';

  @override
  String get workSearchRecords => 'Rechercher un client, un titre ou un numéro';

  @override
  String get workNoMatchingRecords =>
      'Aucun dossier correspondant. Essayez un autre état ou une autre recherche.';

  @override
  String get workRecordUnavailable => 'Ce dossier n’est plus disponible.';

  @override
  String get workNotScheduled => 'Non planifié';

  @override
  String get workCreatedDateMissing => 'Date de création non enregistrée';

  @override
  String workCreatedDate(String date) {
    return 'Créé le $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Terminé le $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Planifié pour le $date';
  }

  @override
  String workDueDate(String date) {
    return 'Échéance : $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers',
      one: '1 dossier',
      zero: '0 dossier',
    );
    return 'Toutes les dates · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Document client';

  @override
  String get workDocumentDetailed => 'Détaillé';

  @override
  String get workDocumentSummary => 'Sommaire';

  @override
  String get workDocumentDetailedHelp =>
      'Afficher chaque article, sa description, sa quantité et son prix.';

  @override
  String get workDocumentSummaryHelp =>
      'Afficher la description des travaux et le prix global. Conserver les articles et les coûts individuels dans vos dossiers.';

  @override
  String get workServicePrice => 'Prix des travaux';

  @override
  String get workEnterServicePrice => 'Saisir un prix';

  @override
  String get workPriceBeforeAdjustments => 'Prix avant rabais et taxes';

  @override
  String get workMoneyPaid => 'Payé intégralement';

  @override
  String get workMoneyUnpaid => 'Impayé';

  @override
  String get workMoneyOverdue => 'En retard';

  @override
  String get workMoneyAllTime => 'Toute la période';

  @override
  String get workInvoicesWithPayments => 'Factures avec paiements';

  @override
  String get workPartiallyPaid => 'Partiellement payé';

  @override
  String get workInvoiceHeading => 'Factures';

  @override
  String get workFilterAllShort => 'Toutes';

  @override
  String get workPaymentsReceivedShort => 'Paiements reçus';

  @override
  String get workDraftsShort => 'Brouillons';

  @override
  String get workInvoiceTotal => 'Total de la facture';

  @override
  String get workInvoiceBalance => 'Solde dû';

  @override
  String get workNewInvoice => 'Nouvelle facture';

  @override
  String get workInvoiceActivityByDate => 'Activité par date';

  @override
  String get workInvoiceActivityHeading => 'Activité des factures';

  @override
  String get workInvoiceAccessDenied =>
      'Vous n’avez pas l’autorisation de consulter les factures.';

  @override
  String get workSearchInvoices => 'Rechercher des factures';

  @override
  String get workSearchInvoicesHint =>
      'Client, travail, numéro de facture ou titre du travail';

  @override
  String get workInvoiceMatches => 'Factures trouvées';

  @override
  String get workInvoiceNoMatches =>
      'Aucune facture autorisée ne correspond à cette recherche.';

  @override
  String get workInvoicesForDate => 'Factures à cette date';

  @override
  String get workInvoiceNoDateActivity =>
      'Aucune activité de facturation n’est enregistrée à cette date.';

  @override
  String get workOpenInvoices => 'Autres factures impayées';

  @override
  String get workInvoiceNoOpenBalance =>
      'Aucune autre facture n’a de solde impayé.';

  @override
  String get workShowOnlyThree => 'Afficher seulement 3';

  @override
  String get workInvoiceUnavailable => 'Cette facture n’est plus disponible.';

  @override
  String get workInvoiceAttention => 'Factures à vérifier';

  @override
  String get workInvoiceDrafts => 'Brouillons de factures';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Facture en retard · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Création';

  @override
  String get workInvoiceActivityIssued => 'Émission';

  @override
  String get workInvoiceActivityDue => 'Échéance';

  @override
  String get workInvoiceActivityPayment => 'Paiement reçu';

  @override
  String get workInvoiceActivityApplied => 'Paiement imputé';

  @override
  String get workSavedClients => 'Clients enregistrés';

  @override
  String get workAddClient => 'Ajouter';

  @override
  String get workUseClient => 'Choisir ce client';

  @override
  String get workSearchClients => 'Rechercher un client enregistré';

  @override
  String get workClientsUnavailable =>
      'Vous ne pouvez pas consulter les clients enregistrés.';

  @override
  String get workNoMatchingClients =>
      'Aucun client correspondant. Modifiez la recherche ou ajoutez un client.';

  @override
  String get invoiceRequestApproval => 'Demander une approbation';

  @override
  String get invoiceApprove => 'Approuver la facture';

  @override
  String get invoiceRequestChanges => 'Demander des modifications';

  @override
  String get invoiceChangesReason => 'Que faut-il modifier ?';

  @override
  String get invoiceChangesReasonRequired =>
      'Précisez les modifications nécessaires.';

  @override
  String get invoiceApprovalSaveFailed =>
      'Impossible d’enregistrer l’approbation. Réessayez.';

  @override
  String get invoiceNeedsApproval => 'Approbation requise';

  @override
  String get workOverallPrice => 'Prix des travaux';

  @override
  String get workOverallPriceHint =>
      'Saisissez un prix ou ajoutez des éléments ci-dessous';

  @override
  String get workOptionalItems => 'Ajouter des éléments (facultatif)';

  @override
  String get clientSaved => 'Clients enregistrés';

  @override
  String get clientAddNew => 'Ajouter un client';

  @override
  String get clientNoSaved => 'Aucun client enregistré';

  @override
  String get clientSearch => 'Rechercher des clients';

  @override
  String get clientNoMatches => 'Aucun client correspondant';

  @override
  String get clientForEstimate => 'Client de cette estimation';

  @override
  String get clientSelectForEstimate =>
      'Sélectionnez un client pour cette estimation.';

  @override
  String get clientViewDenied =>
      'Vous n’avez pas la permission de consulter les clients enregistrés.';

  @override
  String get clientUnfinished => 'Fiches clients inachevées';

  @override
  String get clientContinueHint =>
      'Reprenez les renseignements que vous aviez commencé à saisir.';

  @override
  String get clientRecoveryRetry =>
      'Fiches inachevées indisponibles — Réessayer';

  @override
  String get clientNameMissing => 'Nom du client non saisi';

  @override
  String get clientRecoveryFailed =>
      'Impossible d’ouvrir les renseignements inachevés du client. Vos données ont été conservées. Réessayez.';

  @override
  String get clientDetails => 'Renseignements du client';

  @override
  String get clientName => 'Nom du client';

  @override
  String get clientNameHint => 'Prénom et nom, ou nom de l’entreprise';

  @override
  String get clientBusiness => 'Entreprise du client (facultatif)';

  @override
  String get clientPhone => 'Téléphone (avec indicatif régional)';

  @override
  String get clientEmail => 'Courriel (facultatif)';

  @override
  String get clientPreferredContact => 'Mode de contact préféré';

  @override
  String get clientCall => 'Appel téléphonique';

  @override
  String get clientText => 'Message texte';

  @override
  String get clientEmailMethod => 'Courriel';

  @override
  String get clientLocations => 'Adresse de facturation et lieu du service';

  @override
  String get clientBilling => 'Adresse de facturation';

  @override
  String get clientAddressLabel => 'Libellé de l’adresse (facultatif)';

  @override
  String get clientAddressHint => 'Maison, bureau ou autre nom';

  @override
  String get clientServiceAddress => 'Adresse du service';

  @override
  String get clientAccess => 'Accès à la propriété (facultatif)';

  @override
  String get clientAccessHint =>
      'Code d’accès, stationnement ou instructions d’entrée';

  @override
  String get clientNotes => 'Notes sur le client (facultatif)';

  @override
  String get clientNotesHint =>
      'Notes sur le client, distinctes des instructions d’accès à la propriété.';

  @override
  String get clientSaveUse => 'Enregistrer et sélectionner le client';

  @override
  String get clientSave => 'Enregistrer le client';

  @override
  String get clientSaveChanges => 'Enregistrer les modifications du client';

  @override
  String get clientEdit => 'Modifier le client';
}

/// The translations for French, as used in Canada (`fr_CA`).
class AppLocalizationsFrCa extends AppLocalizationsFr {
  AppLocalizationsFrCa() : super('fr_CA');

  @override
  String get appTitle => 'Tame Your Biz';

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

  @override
  String get catalogBrowse => 'Parcourir le catalogue';

  @override
  String get catalogInventory => 'Mon inventaire';

  @override
  String get catalogGrid => 'Grille';

  @override
  String get catalogList => 'Liste';

  @override
  String get catalogChooseTrade => 'Choisir un métier';

  @override
  String get catalogChooseCategory => 'Choisir une catégorie';

  @override
  String get catalogSearch => 'Rechercher des articles';

  @override
  String get catalogSearchCategory => 'Rechercher dans cette catégorie';

  @override
  String get catalogClear => 'Effacer la recherche';

  @override
  String get catalogPlumbing => 'Plomberie';

  @override
  String get catalogElectrical => 'Électricité';

  @override
  String get catalogHvac => 'CVCA';

  @override
  String get catalogFittings => 'Raccords';

  @override
  String get catalogCopper => 'Cuivre';

  @override
  String get catalogElbows90 => 'Coudes à 90°';

  @override
  String get catalogItemDetails => 'Détails de l’article';

  @override
  String get catalogAdd => 'Ajouter à mon inventaire';

  @override
  String catalogSize(String size) {
    return 'Dimension nominale : $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unité : $unit';
  }

  @override
  String get catalogEach => 'unité';

  @override
  String catalogCopperElbow(String size) {
    return 'Coude en cuivre à 90° de $size';
  }

  @override
  String get catalogEmpty => 'Cette catégorie est en cours de reconstruction.';

  @override
  String get catalogNoMatches =>
      'Aucun article trouvé. Essayez un autre nom ou une autre dimension.';

  @override
  String get workFilterAwaitingCustomer => 'Estimations en attente du client';

  @override
  String get workFilterUnscheduledJobs => 'Travaux à planifier';

  @override
  String get workFilterActiveJobs => 'Travaux en cours';

  @override
  String get workFilterUnpaidInvoices => 'Factures impayées';

  @override
  String get workFilterAllEstimates => 'Toutes les estimations';

  @override
  String get workFilterDraftEstimates => 'Brouillons d’estimations';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimations en attente d’approbation de l’entreprise';

  @override
  String get workFilterReadyEstimates => 'Estimations prêtes à envoyer';

  @override
  String get workFilterChangedEstimates =>
      'Estimations avec modifications demandées';

  @override
  String get workFilterApprovedEstimates => 'Estimations approuvées';

  @override
  String get workFilterDeclinedEstimates => 'Estimations refusées';

  @override
  String get workFilterExpiredEstimates => 'Estimations expirées';

  @override
  String get workFilterAllJobs => 'Tous les travaux';

  @override
  String get workFilterCompletedJobs => 'Travaux terminés';

  @override
  String get workFilterAllInvoices => 'Toutes les factures';

  @override
  String get workFilterDraftInvoices => 'Brouillons de factures';

  @override
  String get workFilterPaidInvoices => 'Factures payées intégralement';

  @override
  String get workFilterOverdueInvoices => 'Factures en retard';

  @override
  String get workStatusDraft => 'Brouillon';

  @override
  String get workStatusReady => 'Prêt';

  @override
  String get workStatusSent => 'Envoyé';

  @override
  String get workStatusAccepted => 'Accepté';

  @override
  String get workStatusScheduled => 'Planifié';

  @override
  String get workStatusEnRoute => 'En route';

  @override
  String get workStatusArrived => 'Sur place';

  @override
  String get workStatusInProgress => 'En cours';

  @override
  String get workStatusPaused => 'En pause';

  @override
  String get workStatusNeedsReturnVisit => 'Visite supplémentaire requise';

  @override
  String get workStatusCompleted => 'Terminé';

  @override
  String get workStatusDue => 'À payer';

  @override
  String get workStatusPaid => 'Payé';

  @override
  String get workStatusReadyToSend => 'Prêt à envoyer';

  @override
  String get workStatusAwaitingCustomer => 'En attente du client';

  @override
  String get workStatusViewed => 'Consulté';

  @override
  String get workStatusChangesRequested => 'Modifications demandées';

  @override
  String get workStatusApproved => 'Approuvé';

  @override
  String get workStatusDeclined => 'Refusé';

  @override
  String get workStatusExpired => 'Expiré';

  @override
  String get workStatusConverted => 'Converti en travail';

  @override
  String get workStatusArchived => 'Archivé';

  @override
  String get workOverviewHeading => 'Aperçu du travail · Toutes les dates';

  @override
  String get workBrowseRecords => 'Consulter les dossiers';

  @override
  String get workRecordsHeading => 'Dossiers de travail';

  @override
  String get workShowRecords => 'Afficher les dossiers';

  @override
  String get workSearchRecords => 'Rechercher un client, un titre ou un numéro';

  @override
  String get workNoMatchingRecords =>
      'Aucun dossier correspondant. Essayez un autre état ou une autre recherche.';

  @override
  String get workRecordUnavailable => 'Ce dossier n’est plus disponible.';

  @override
  String get workNotScheduled => 'Non planifié';

  @override
  String get workCreatedDateMissing => 'Date de création non enregistrée';

  @override
  String workCreatedDate(String date) {
    return 'Créé le $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Terminé le $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Planifié pour le $date';
  }

  @override
  String workDueDate(String date) {
    return 'Échéance : $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers',
      one: '1 dossier',
      zero: '0 dossier',
    );
    return 'Toutes les dates · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Document client';

  @override
  String get workDocumentDetailed => 'Détaillé';

  @override
  String get workDocumentSummary => 'Sommaire';

  @override
  String get workDocumentDetailedHelp =>
      'Afficher chaque article, sa description, sa quantité et son prix.';

  @override
  String get workDocumentSummaryHelp =>
      'Afficher la description des travaux et le prix global. Conserver les articles et les coûts individuels dans vos dossiers.';

  @override
  String get workServicePrice => 'Prix des travaux';

  @override
  String get workEnterServicePrice => 'Saisir un prix';

  @override
  String get workPriceBeforeAdjustments => 'Prix avant rabais et taxes';

  @override
  String get workMoneyPaid => 'Payé intégralement';

  @override
  String get workMoneyUnpaid => 'Impayé';

  @override
  String get workMoneyOverdue => 'En retard';

  @override
  String get workMoneyAllTime => 'Toute la période';

  @override
  String get workInvoicesWithPayments => 'Factures avec paiements';

  @override
  String get workPartiallyPaid => 'Partiellement payé';

  @override
  String get workInvoiceHeading => 'Factures';

  @override
  String get workFilterAllShort => 'Toutes';

  @override
  String get workPaymentsReceivedShort => 'Paiements reçus';

  @override
  String get workDraftsShort => 'Brouillons';

  @override
  String get workInvoiceTotal => 'Total de la facture';

  @override
  String get workInvoiceBalance => 'Solde dû';

  @override
  String get workNewInvoice => 'Nouvelle facture';

  @override
  String get workInvoiceActivityByDate => 'Activité par date';

  @override
  String get workInvoiceActivityHeading => 'Activité des factures';

  @override
  String get workInvoiceAccessDenied =>
      'Vous n’avez pas l’autorisation de consulter les factures.';

  @override
  String get workSearchInvoices => 'Rechercher des factures';

  @override
  String get workSearchInvoicesHint =>
      'Client, travail, numéro de facture ou titre du travail';

  @override
  String get workInvoiceMatches => 'Factures trouvées';

  @override
  String get workInvoiceNoMatches =>
      'Aucune facture autorisée ne correspond à cette recherche.';

  @override
  String get workInvoicesForDate => 'Factures à cette date';

  @override
  String get workInvoiceNoDateActivity =>
      'Aucune activité de facturation n’est enregistrée à cette date.';

  @override
  String get workOpenInvoices => 'Autres factures impayées';

  @override
  String get workInvoiceNoOpenBalance =>
      'Aucune autre facture n’a de solde impayé.';

  @override
  String get workShowOnlyThree => 'Afficher seulement 3';

  @override
  String get workInvoiceUnavailable => 'Cette facture n’est plus disponible.';

  @override
  String get workInvoiceAttention => 'Factures à vérifier';

  @override
  String get workInvoiceDrafts => 'Brouillons de factures';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Facture en retard · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Création';

  @override
  String get workInvoiceActivityIssued => 'Émission';

  @override
  String get workInvoiceActivityDue => 'Échéance';

  @override
  String get workInvoiceActivityPayment => 'Paiement reçu';

  @override
  String get workInvoiceActivityApplied => 'Paiement imputé';

  @override
  String get workSavedClients => 'Clients enregistrés';

  @override
  String get workAddClient => 'Ajouter';

  @override
  String get workUseClient => 'Choisir ce client';

  @override
  String get workSearchClients => 'Rechercher un client enregistré';

  @override
  String get workClientsUnavailable =>
      'Vous ne pouvez pas consulter les clients enregistrés.';

  @override
  String get workNoMatchingClients =>
      'Aucun client correspondant. Modifiez la recherche ou ajoutez un client.';

  @override
  String get invoiceRequestApproval => 'Demander une approbation';

  @override
  String get invoiceApprove => 'Approuver la facture';

  @override
  String get invoiceRequestChanges => 'Demander des modifications';

  @override
  String get invoiceChangesReason => 'Que faut-il modifier ?';

  @override
  String get invoiceChangesReasonRequired =>
      'Précisez les modifications nécessaires.';

  @override
  String get invoiceApprovalSaveFailed =>
      'Impossible d’enregistrer l’approbation. Réessayez.';

  @override
  String get invoiceNeedsApproval => 'Approbation requise';

  @override
  String get workOverallPrice => 'Prix des travaux';

  @override
  String get workOverallPriceHint =>
      'Saisissez un prix ou ajoutez des éléments ci-dessous';

  @override
  String get workOptionalItems => 'Ajouter des éléments (facultatif)';

  @override
  String get clientSaved => 'Clients enregistrés';

  @override
  String get clientAddNew => 'Ajouter un client';

  @override
  String get clientNoSaved => 'Aucun client enregistré';

  @override
  String get clientSearch => 'Rechercher des clients';

  @override
  String get clientNoMatches => 'Aucun client correspondant';

  @override
  String get clientForEstimate => 'Client de cette estimation';

  @override
  String get clientSelectForEstimate =>
      'Sélectionnez un client pour cette estimation.';

  @override
  String get clientViewDenied =>
      'Vous n’avez pas la permission de consulter les clients enregistrés.';

  @override
  String get clientUnfinished => 'Fiches clients inachevées';

  @override
  String get clientContinueHint =>
      'Reprenez les renseignements que vous aviez commencé à saisir.';

  @override
  String get clientRecoveryRetry =>
      'Fiches inachevées indisponibles — Réessayer';

  @override
  String get clientNameMissing => 'Nom du client non saisi';

  @override
  String get clientRecoveryFailed =>
      'Impossible d’ouvrir les renseignements inachevés du client. Vos données ont été conservées. Réessayez.';

  @override
  String get clientDetails => 'Renseignements du client';

  @override
  String get clientName => 'Nom du client';

  @override
  String get clientNameHint => 'Prénom et nom, ou nom de l’entreprise';

  @override
  String get clientBusiness => 'Entreprise du client (facultatif)';

  @override
  String get clientPhone => 'Téléphone (avec indicatif régional)';

  @override
  String get clientEmail => 'Courriel (facultatif)';

  @override
  String get clientPreferredContact => 'Mode de contact préféré';

  @override
  String get clientCall => 'Appel téléphonique';

  @override
  String get clientText => 'Message texte';

  @override
  String get clientEmailMethod => 'Courriel';

  @override
  String get clientLocations => 'Adresse de facturation et lieu du service';

  @override
  String get clientBilling => 'Adresse de facturation';

  @override
  String get clientAddressLabel => 'Libellé de l’adresse (facultatif)';

  @override
  String get clientAddressHint => 'Maison, bureau ou autre nom';

  @override
  String get clientServiceAddress => 'Adresse du service';

  @override
  String get clientAccess => 'Accès à la propriété (facultatif)';

  @override
  String get clientAccessHint =>
      'Code d’accès, stationnement ou instructions d’entrée';

  @override
  String get clientNotes => 'Notes sur le client (facultatif)';

  @override
  String get clientNotesHint =>
      'Notes sur le client, distinctes des instructions d’accès à la propriété.';

  @override
  String get clientSaveUse => 'Enregistrer et sélectionner le client';

  @override
  String get clientSave => 'Enregistrer le client';

  @override
  String get clientSaveChanges => 'Enregistrer les modifications du client';

  @override
  String get clientEdit => 'Modifier le client';
}
