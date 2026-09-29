// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectVehicleLabel => 'Select vehicle';

  @override
  String get appTitle => 'Tame Your Biz';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get dashboardOdometerLabel => 'Odometer';

  @override
  String get dashboardStartWorkday => 'Start workday';

  @override
  String get dashboardPaymentsLabel => 'Payments';

  @override
  String get dashboardMilesLabel => 'Miles';

  @override
  String get dashboardMileageUnavailable =>
      'Business mileage totals are not connected yet. No zero total has been assumed.';

  @override
  String get navDashboardCompact => 'Dashboard';

  @override
  String get navWork => 'Work';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navInventory => 'Materials';

  @override
  String get navMaintenance => 'Maintenance';

  @override
  String get fieldRecords => 'Field records';

  @override
  String get offlineRecordsAvailable => 'Records stay available offline.';

  @override
  String get advertisementPlaceholder => 'Advertisement placeholder';

  @override
  String get advertisement => 'ADVERTISEMENT';

  @override
  String get sampleAdSpace => 'Sample ad space';

  @override
  String get demo => 'Demo';

  @override
  String get operationalViewLabel => 'View';

  @override
  String operationalViewValue(String view) {
    return 'View: $view';
  }

  @override
  String get operationalChangeViewTooltip => 'Change view';

  @override
  String get operationalChangeContextTooltip => 'Change work context';

  @override
  String operationalContextSemantics(String context, String value) {
    return '$context: $value';
  }

  @override
  String get operationalViewTechnician => 'Technician';

  @override
  String get operationalViewAdmin => 'Admin';

  @override
  String get operationalContextEmployee => 'Employee';

  @override
  String get operationalContextVehicle => 'Vehicle';

  @override
  String get operationalContextActiveVehicle => 'Active vehicle';

  @override
  String get operationalCompanyOverview => 'Company Overview';

  @override
  String get operationalFleetOverview => 'Fleet Overview';

  @override
  String get operationalPreviousDay => 'Previous day';

  @override
  String get operationalNextDay => 'Next day';

  @override
  String get operationalReturnToToday => 'Return to today';

  @override
  String operationalUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications. $count unread items.',
      one: 'Notifications. 1 unread item.',
      zero: 'Notifications. Nothing new.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHeading => 'Reminders and updates';

  @override
  String get notificationsDescription =>
      'Notifications report reminders and updates. Decisions remain in Needs attention.';

  @override
  String get nativeReminderTitle => 'Tame Your Biz reminder';

  @override
  String get nativeReminderBody =>
      'Open Tame Your Biz to review a scheduled reminder.';

  @override
  String get deviceRemindersUnavailableTitle => 'Device reminders unavailable';

  @override
  String get deviceRemindersRetry => 'Retry device reminders';

  @override
  String get deviceRemindersOffTitle => 'Device reminders are off';

  @override
  String get deviceRemindersOffBody =>
      'In-app reminders still work. Enable device notifications to receive reminders when Tame Your Biz is closed.';

  @override
  String get deviceRemindersEnable => 'Enable device reminders';

  @override
  String get deviceRemindersEnabling => 'Enabling device reminders';

  @override
  String get deviceRemindersDenied =>
      'Device reminders are still off. You can allow Tame Your Biz notifications in system settings.';

  @override
  String get deviceRemindersFailed =>
      'Device reminders could not be updated. Try again.';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmpty =>
      'No reminders or updates are currently available.';

  @override
  String get notificationsLoadFailed => 'Notifications could not be loaded.';

  @override
  String get notificationUnreadState => 'Unread';

  @override
  String get notificationReadState => 'Read';

  @override
  String get notificationDueToday => 'Due today';

  @override
  String get notificationDueTomorrow => 'Due tomorrow';

  @override
  String notificationDueInDays(int count) {
    return 'Due in $count days';
  }

  @override
  String notificationDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String operationalNotificationsAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications. $count items need attention.',
      one: 'Notifications. 1 item needs attention.',
      zero: 'Notifications. Nothing needs attention.',
    );
    return '$_temp0';
  }

  @override
  String get attentionTitle => 'Needs attention';

  @override
  String attentionShowAll(int count) {
    return 'Show all $count';
  }

  @override
  String get attentionDismiss => 'Dismiss Needs attention';

  @override
  String get attentionNothing => 'Nothing needs attention right now.';

  @override
  String get reportToday => 'Today';

  @override
  String get reportThisWeek => 'This week';

  @override
  String get reportThisMonth => 'This month';

  @override
  String get reportThisCalendarQuarter => 'This calendar quarter';

  @override
  String get reportPreviousCalendarQuarter => 'Previous calendar quarter';

  @override
  String get reportPrevious90Days => 'Previous 90 days';

  @override
  String get reportYearToDate => 'Year to date';

  @override
  String get reportPrevious12Months => 'Previous 12 months';

  @override
  String get calendarMonthView => 'Month';

  @override
  String get calendarWeekView => 'Week';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarPreviousWeek => 'Previous week';

  @override
  String get calendarNextWeek => 'Next week';

  @override
  String get calendarChooseWorkDate => 'Choose a work date';

  @override
  String get calendarMondayShort => 'Mon';

  @override
  String get calendarTuesdayShort => 'Tue';

  @override
  String get calendarWednesdayShort => 'Wed';

  @override
  String get calendarThursdayShort => 'Thu';

  @override
  String get calendarFridayShort => 'Fri';

  @override
  String get calendarSaturdayShort => 'Sat';

  @override
  String get calendarSundayShort => 'Sun';

  @override
  String get calendarTodayState => 'Today.';

  @override
  String get calendarOutsideMonthState => 'Outside the selected month.';

  @override
  String get calendarNeedsApprovalState => 'Needs approval.';

  @override
  String get calendarRecordSingular => 'record';

  @override
  String get calendarRecordPlural => 'records';

  @override
  String get calendarDashboardEntrySingular => 'dashboard entry';

  @override
  String get calendarDashboardEntryPlural => 'dashboard entries';

  @override
  String get calendarWorkRecordSingular => 'work record';

  @override
  String get calendarWorkRecordPlural => 'work records';

  @override
  String get calendarJobSingular => 'job';

  @override
  String get calendarJobPlural => 'jobs';

  @override
  String get calendarEstimateSingular => 'estimate';

  @override
  String get calendarEstimatePlural => 'estimates';

  @override
  String get calendarInvoiceSingular => 'invoice';

  @override
  String get calendarInvoicePlural => 'invoices';

  @override
  String get calendarPaymentSingular => 'payment';

  @override
  String get calendarPaymentPlural => 'payments';

  @override
  String get calendarExpenseSingular => 'expense';

  @override
  String get calendarExpensePlural => 'expenses';

  @override
  String get calendarInventoryRecordSingular => 'materials record';

  @override
  String get calendarInventoryRecordPlural => 'materials records';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'No $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }

  @override
  String get catalogBrowse => 'Browse Catalog';

  @override
  String get catalogInventory => 'My Inventory';

  @override
  String get catalogGrid => 'Grid';

  @override
  String get catalogList => 'List';

  @override
  String get catalogChooseTrade => 'Choose a trade';

  @override
  String get catalogChooseCategory => 'Choose a category';

  @override
  String get catalogSearch => 'Search items';

  @override
  String get catalogSearchCategory => 'Search this category';

  @override
  String get catalogClear => 'Clear search';

  @override
  String get catalogPlumbing => 'Plumbing';

  @override
  String get catalogElectrical => 'Electrical';

  @override
  String get catalogHvac => 'HVAC';

  @override
  String get catalogFittings => 'Fittings';

  @override
  String get catalogCopper => 'Copper';

  @override
  String get catalogElbows90 => '90° Elbows';

  @override
  String get catalogItemDetails => 'Item details';

  @override
  String get catalogAdd => 'Add to My Inventory';

  @override
  String catalogSize(String size) {
    return 'Nominal size: $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get catalogEach => 'each';

  @override
  String catalogCopperElbow(String size) {
    return '$size Copper 90° Elbow';
  }

  @override
  String get catalogEmpty => 'This category is being rebuilt.';

  @override
  String get catalogNoMatches => 'No matching items. Try another name or size.';

  @override
  String get workFilterAwaitingCustomer => 'Estimates awaiting customer';

  @override
  String get workFilterUnscheduledJobs => 'Jobs needing scheduling';

  @override
  String get workFilterActiveJobs => 'Active jobs';

  @override
  String get workFilterUnpaidInvoices => 'Outstanding invoices';

  @override
  String get workFilterAllEstimates => 'All estimates';

  @override
  String get workFilterDraftEstimates => 'Draft estimates';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimates awaiting company approval';

  @override
  String get workFilterReadyEstimates => 'Estimates ready to send';

  @override
  String get workFilterChangedEstimates => 'Estimates with changes requested';

  @override
  String get workFilterApprovedEstimates => 'Approved estimates';

  @override
  String get workFilterDeclinedEstimates => 'Declined estimates';

  @override
  String get workFilterExpiredEstimates => 'Expired estimates';

  @override
  String get workFilterAllJobs => 'All jobs';

  @override
  String get workFilterCompletedJobs => 'Completed jobs';

  @override
  String get workFilterAllInvoices => 'All invoices';

  @override
  String get workFilterDraftInvoices => 'Draft invoices';

  @override
  String get workFilterPaidInvoices => 'Invoices paid in full';

  @override
  String get workFilterOverdueInvoices => 'Overdue invoices';

  @override
  String get workStatusDraft => 'Draft';

  @override
  String get workStatusReady => 'Ready';

  @override
  String get workStatusSent => 'Sent';

  @override
  String get workStatusAccepted => 'Accepted';

  @override
  String get workStatusScheduled => 'Scheduled';

  @override
  String get workStatusEnRoute => 'En route';

  @override
  String get workStatusArrived => 'Arrived';

  @override
  String get workStatusInProgress => 'In progress';

  @override
  String get workStatusPaused => 'Paused';

  @override
  String get workStatusNeedsReturnVisit => 'Needs return visit';

  @override
  String get workStatusCompleted => 'Completed';

  @override
  String get workStatusDue => 'Due';

  @override
  String get workStatusPaid => 'Paid';

  @override
  String get workStatusReadyToSend => 'Ready to send';

  @override
  String get workStatusAwaitingCustomer => 'Awaiting customer';

  @override
  String get workStatusViewed => 'Viewed';

  @override
  String get workStatusChangesRequested => 'Changes requested';

  @override
  String get workStatusApproved => 'Approved';

  @override
  String get workStatusDeclined => 'Declined';

  @override
  String get workStatusExpired => 'Expired';

  @override
  String get workStatusConverted => 'Converted to job';

  @override
  String get workStatusArchived => 'Archived';

  @override
  String get workOverviewHeading => 'Work overview · All dates';

  @override
  String get workBrowseRecords => 'Browse records';

  @override
  String get workRecordsHeading => 'Work records';

  @override
  String get workShowRecords => 'Show records';

  @override
  String get workSearchRecords => 'Search customer, title or number';

  @override
  String get workNoMatchingRecords =>
      'No matching records. Try another status or search.';

  @override
  String get workRecordUnavailable => 'This record is no longer available.';

  @override
  String get workNotScheduled => 'Not scheduled';

  @override
  String get workCreatedDateMissing => 'Created date not recorded';

  @override
  String workCreatedDate(String date) {
    return 'Created $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Completed $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Scheduled $date';
  }

  @override
  String workDueDate(String date) {
    return 'Due $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: '0 records',
    );
    return 'All dates · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Customer document';

  @override
  String get workDocumentDetailed => 'Detailed';

  @override
  String get workDocumentSummary => 'Summary';

  @override
  String get workDocumentDetailedHelp =>
      'Show each item, description, quantity and price.';

  @override
  String get workDocumentSummaryHelp =>
      'Show the work description and overall price. Keep individual items and costs in your records.';

  @override
  String get workServicePrice => 'Price for the work';

  @override
  String get workEnterServicePrice => 'Enter one price';

  @override
  String get workPriceBeforeAdjustments => 'Price before discount and tax';

  @override
  String get workMoneyPaid => 'Paid in full';

  @override
  String get workMoneyUnpaid => 'Unpaid';

  @override
  String get workMoneyOverdue => 'Overdue';

  @override
  String get workMoneyAllTime => 'All time';

  @override
  String get workInvoicesWithPayments => 'Invoices with payments';

  @override
  String get workPartiallyPaid => 'Partially paid';

  @override
  String get workInvoiceHeading => 'Invoices';

  @override
  String get workFilterAllShort => 'All';

  @override
  String get workPaymentsReceivedShort => 'Payments received';

  @override
  String get workDraftsShort => 'Drafts';

  @override
  String get workInvoiceTotal => 'Invoice total';

  @override
  String get workInvoiceBalance => 'Balance due';

  @override
  String get workNewInvoice => 'New invoice';

  @override
  String get workInvoiceActivityByDate => 'Date activity';

  @override
  String get workInvoiceActivityHeading => 'Invoice activity';

  @override
  String get workInvoiceAccessDenied =>
      'You do not have permission to view invoices.';

  @override
  String get workSearchInvoices => 'Search invoices';

  @override
  String get workSearchInvoicesHint =>
      'Customer, job, invoice number, or work title';

  @override
  String get workInvoiceMatches => 'Invoice matches';

  @override
  String get workInvoiceNoMatches =>
      'No authorized invoices match that search.';

  @override
  String get workInvoicesForDate => 'Invoices for this date';

  @override
  String get workInvoiceNoDateActivity =>
      'No invoice activity is recorded for this date.';

  @override
  String get workOpenInvoices => 'Other unpaid invoices';

  @override
  String get workInvoiceNoOpenBalance =>
      'No other invoices have an open balance.';

  @override
  String get workShowOnlyThree => 'Show only 3';

  @override
  String get workInvoiceUnavailable => 'This invoice is no longer available.';

  @override
  String get workInvoiceAttention => 'Invoice attention';

  @override
  String get workInvoiceDrafts => 'Invoice drafts';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Invoice is overdue · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Created';

  @override
  String get workInvoiceActivityIssued => 'Issued';

  @override
  String get workInvoiceActivityDue => 'Due';

  @override
  String get workInvoiceActivityPayment => 'Payment received';

  @override
  String get workInvoiceActivityApplied => 'Payment applied';

  @override
  String get workSavedClients => 'Saved clients';

  @override
  String get workAddClient => 'Add new';

  @override
  String get workUseClient => 'Use this client';

  @override
  String get workSearchClients => 'Search saved clients';

  @override
  String get workClientsUnavailable =>
      'You do not have permission to view saved clients.';

  @override
  String get workNoMatchingClients =>
      'No matching clients. Try another search or add a new client.';

  @override
  String get invoiceRequestApproval => 'Request approval';

  @override
  String get invoiceApprove => 'Approve invoice';

  @override
  String get invoiceRequestChanges => 'Request changes';

  @override
  String get invoiceChangesReason => 'What needs to change?';

  @override
  String get invoiceChangesReasonRequired =>
      'Explain which changes are needed.';

  @override
  String get invoiceApprovalSaveFailed =>
      'Approval could not be saved. Try again.';

  @override
  String get invoiceNeedsApproval => 'Needs approval';

  @override
  String get workOverallPrice => 'Price for the work';

  @override
  String get workOverallPriceHint =>
      'Enter one price, or add individual items below';

  @override
  String get workOptionalItems => 'Add items (optional)';

  @override
  String get clientSaved => 'Saved clients';

  @override
  String get clientAddNew => 'Add new client';

  @override
  String get clientNoSaved => 'No saved clients';

  @override
  String get clientSearch => 'Search clients';

  @override
  String get clientNoMatches => 'No matching clients';

  @override
  String get clientForEstimate => 'Client for this estimate';

  @override
  String get clientSelectForEstimate => 'Select a client for this estimate.';

  @override
  String get clientViewDenied =>
      'You do not have permission to view saved clients.';

  @override
  String get clientUnfinished => 'Unfinished client forms';

  @override
  String get clientContinueHint =>
      'Continue information you previously started.';

  @override
  String get clientRecoveryRetry =>
      'Unfinished client forms unavailable — Retry';

  @override
  String get clientNameMissing => 'Client name not entered';

  @override
  String get clientRecoveryFailed =>
      'Could not open unfinished client information. Your input has been kept. Try again.';

  @override
  String get clientDetails => 'Client details';

  @override
  String get clientName => 'Client name';

  @override
  String get clientNameHint => 'First and last name, or business name';

  @override
  String get clientBusiness => 'Client’s business (optional)';

  @override
  String get clientPhone => 'Phone (including area code)';

  @override
  String get clientEmail => 'Email (optional)';

  @override
  String get clientPreferredContact => 'Preferred contact';

  @override
  String get clientCall => 'Phone call';

  @override
  String get clientText => 'Text message';

  @override
  String get clientEmailMethod => 'Email';

  @override
  String get clientLocations => 'Billing and service location';

  @override
  String get clientBilling => 'Billing address';

  @override
  String get clientAddressLabel => 'Address label (optional)';

  @override
  String get clientAddressHint => 'Home, office, or another name';

  @override
  String get clientServiceAddress => 'Service address';

  @override
  String get clientAccess => 'Getting into the property (optional)';

  @override
  String get clientAccessHint => 'Gate code, parking, or entry instructions';

  @override
  String get clientNotes => 'Client notes (optional)';

  @override
  String get clientNotesHint =>
      'Notes about the client, separate from property access instructions.';

  @override
  String get clientSaveUse => 'Save and use client';

  @override
  String get clientSave => 'Save client';

  @override
  String get clientSaveChanges => 'Save client changes';

  @override
  String get clientEdit => 'Edit client';
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get appTitle => 'Tame Your Biz';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navWork => 'Work';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navInventory => 'Materials';

  @override
  String get navMaintenance => 'Maintenance';

  @override
  String get fieldRecords => 'Field records';

  @override
  String get offlineRecordsAvailable => 'Records stay available offline.';

  @override
  String get advertisementPlaceholder => 'Advertisement placeholder';

  @override
  String get advertisement => 'ADVERTISEMENT';

  @override
  String get sampleAdSpace => 'Sample ad space';

  @override
  String get demo => 'Demo';

  @override
  String get calendarMonthView => 'Month';

  @override
  String get calendarWeekView => 'Week';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarPreviousWeek => 'Previous week';

  @override
  String get calendarNextWeek => 'Next week';

  @override
  String get calendarChooseWorkDate => 'Choose a work date';

  @override
  String get calendarTodayState => 'Today.';

  @override
  String get calendarOutsideMonthState => 'Outside the selected month.';

  @override
  String get calendarNeedsApprovalState => 'Needs approval.';

  @override
  String calendarNoRecords(String recordLabel) {
    return 'No $recordLabel.';
  }

  @override
  String calendarRecordCount(int count, String recordLabel) {
    return '$count $recordLabel.';
  }

  @override
  String get catalogBrowse => 'Browse Catalog';

  @override
  String get catalogInventory => 'My Inventory';

  @override
  String get catalogGrid => 'Grid';

  @override
  String get catalogList => 'List';

  @override
  String get catalogChooseTrade => 'Choose a trade';

  @override
  String get catalogChooseCategory => 'Choose a category';

  @override
  String get catalogSearch => 'Search items';

  @override
  String get catalogSearchCategory => 'Search this category';

  @override
  String get catalogClear => 'Clear search';

  @override
  String get catalogPlumbing => 'Plumbing';

  @override
  String get catalogElectrical => 'Electrical';

  @override
  String get catalogHvac => 'HVAC';

  @override
  String get catalogFittings => 'Fittings';

  @override
  String get catalogCopper => 'Copper';

  @override
  String get catalogElbows90 => '90° Elbows';

  @override
  String get catalogItemDetails => 'Item details';

  @override
  String get catalogAdd => 'Add to My Inventory';

  @override
  String catalogSize(String size) {
    return 'Nominal size: $size';
  }

  @override
  String catalogUnit(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get catalogEach => 'each';

  @override
  String catalogCopperElbow(String size) {
    return '$size Copper 90° Elbow';
  }

  @override
  String get catalogEmpty => 'This category is being rebuilt.';

  @override
  String get catalogNoMatches => 'No matching items. Try another name or size.';

  @override
  String get workFilterAwaitingCustomer => 'Estimates awaiting customer';

  @override
  String get workFilterUnscheduledJobs => 'Jobs needing scheduling';

  @override
  String get workFilterActiveJobs => 'Active jobs';

  @override
  String get workFilterUnpaidInvoices => 'Outstanding invoices';

  @override
  String get workFilterAllEstimates => 'All estimates';

  @override
  String get workFilterDraftEstimates => 'Draft estimates';

  @override
  String get workFilterCompanyReviewEstimates =>
      'Estimates awaiting company approval';

  @override
  String get workFilterReadyEstimates => 'Estimates ready to send';

  @override
  String get workFilterChangedEstimates => 'Estimates with changes requested';

  @override
  String get workFilterApprovedEstimates => 'Approved estimates';

  @override
  String get workFilterDeclinedEstimates => 'Declined estimates';

  @override
  String get workFilterExpiredEstimates => 'Expired estimates';

  @override
  String get workFilterAllJobs => 'All jobs';

  @override
  String get workFilterCompletedJobs => 'Completed jobs';

  @override
  String get workFilterAllInvoices => 'All invoices';

  @override
  String get workFilterDraftInvoices => 'Draft invoices';

  @override
  String get workFilterPaidInvoices => 'Invoices paid in full';

  @override
  String get workFilterOverdueInvoices => 'Overdue invoices';

  @override
  String get workStatusDraft => 'Draft';

  @override
  String get workStatusReady => 'Ready';

  @override
  String get workStatusSent => 'Sent';

  @override
  String get workStatusAccepted => 'Accepted';

  @override
  String get workStatusScheduled => 'Scheduled';

  @override
  String get workStatusEnRoute => 'En route';

  @override
  String get workStatusArrived => 'Arrived';

  @override
  String get workStatusInProgress => 'In progress';

  @override
  String get workStatusPaused => 'Paused';

  @override
  String get workStatusNeedsReturnVisit => 'Needs return visit';

  @override
  String get workStatusCompleted => 'Completed';

  @override
  String get workStatusDue => 'Due';

  @override
  String get workStatusPaid => 'Paid';

  @override
  String get workStatusReadyToSend => 'Ready to send';

  @override
  String get workStatusAwaitingCustomer => 'Awaiting customer';

  @override
  String get workStatusViewed => 'Viewed';

  @override
  String get workStatusChangesRequested => 'Changes requested';

  @override
  String get workStatusApproved => 'Approved';

  @override
  String get workStatusDeclined => 'Declined';

  @override
  String get workStatusExpired => 'Expired';

  @override
  String get workStatusConverted => 'Converted to job';

  @override
  String get workStatusArchived => 'Archived';

  @override
  String get workOverviewHeading => 'Work overview · All dates';

  @override
  String get workBrowseRecords => 'Browse records';

  @override
  String get workRecordsHeading => 'Work records';

  @override
  String get workShowRecords => 'Show records';

  @override
  String get workSearchRecords => 'Search customer, title or number';

  @override
  String get workNoMatchingRecords =>
      'No matching records. Try another status or search.';

  @override
  String get workRecordUnavailable => 'This record is no longer available.';

  @override
  String get workNotScheduled => 'Not scheduled';

  @override
  String get workCreatedDateMissing => 'Created date not recorded';

  @override
  String workCreatedDate(String date) {
    return 'Created $date';
  }

  @override
  String workCompletedDate(String date) {
    return 'Completed $date';
  }

  @override
  String workScheduledDate(String date) {
    return 'Scheduled $date';
  }

  @override
  String workDueDate(String date) {
    return 'Due $date';
  }

  @override
  String workRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: '0 records',
    );
    return 'All dates · $_temp0';
  }

  @override
  String get workDocumentStyle => 'Customer document';

  @override
  String get workDocumentDetailed => 'Detailed';

  @override
  String get workDocumentSummary => 'Summary';

  @override
  String get workDocumentDetailedHelp =>
      'Show each item, description, quantity and price.';

  @override
  String get workDocumentSummaryHelp =>
      'Show the work description and overall price. Keep individual items and costs in your records.';

  @override
  String get workServicePrice => 'Price for the work';

  @override
  String get workEnterServicePrice => 'Enter one price';

  @override
  String get workPriceBeforeAdjustments => 'Price before discount and tax';

  @override
  String get workMoneyPaid => 'Paid in full';

  @override
  String get workMoneyUnpaid => 'Unpaid';

  @override
  String get workMoneyOverdue => 'Overdue';

  @override
  String get workMoneyAllTime => 'All time';

  @override
  String get workInvoicesWithPayments => 'Invoices with payments';

  @override
  String get workPartiallyPaid => 'Partially paid';

  @override
  String get workInvoiceHeading => 'Invoices';

  @override
  String get workFilterAllShort => 'All';

  @override
  String get workPaymentsReceivedShort => 'Payments received';

  @override
  String get workDraftsShort => 'Drafts';

  @override
  String get workInvoiceTotal => 'Invoice total';

  @override
  String get workInvoiceBalance => 'Balance due';

  @override
  String get workNewInvoice => 'New invoice';

  @override
  String get workInvoiceActivityByDate => 'Date activity';

  @override
  String get workInvoiceActivityHeading => 'Invoice activity';

  @override
  String get workInvoiceAccessDenied =>
      'You do not have permission to view invoices.';

  @override
  String get workSearchInvoices => 'Search invoices';

  @override
  String get workSearchInvoicesHint =>
      'Customer, job, invoice number, or work title';

  @override
  String get workInvoiceMatches => 'Invoice matches';

  @override
  String get workInvoiceNoMatches =>
      'No authorized invoices match that search.';

  @override
  String get workInvoicesForDate => 'Invoices for this date';

  @override
  String get workInvoiceNoDateActivity =>
      'No invoice activity is recorded for this date.';

  @override
  String get workOpenInvoices => 'Other unpaid invoices';

  @override
  String get workInvoiceNoOpenBalance =>
      'No other invoices have an open balance.';

  @override
  String get workShowOnlyThree => 'Show only 3';

  @override
  String get workInvoiceUnavailable => 'This invoice is no longer available.';

  @override
  String get workInvoiceAttention => 'Invoice attention';

  @override
  String get workInvoiceDrafts => 'Invoice drafts';

  @override
  String workInvoiceOverdueReason(String customer) {
    return 'Invoice is overdue · $customer';
  }

  @override
  String get workInvoiceActivityCreated => 'Created';

  @override
  String get workInvoiceActivityIssued => 'Issued';

  @override
  String get workInvoiceActivityDue => 'Due';

  @override
  String get workInvoiceActivityPayment => 'Payment received';

  @override
  String get workInvoiceActivityApplied => 'Payment applied';

  @override
  String get workSavedClients => 'Saved clients';

  @override
  String get workAddClient => 'Add new';

  @override
  String get workUseClient => 'Use this client';

  @override
  String get workSearchClients => 'Search saved clients';

  @override
  String get workClientsUnavailable =>
      'You do not have permission to view saved clients.';

  @override
  String get workNoMatchingClients =>
      'No matching clients. Try another search or add a new client.';

  @override
  String get invoiceRequestApproval => 'Request approval';

  @override
  String get invoiceApprove => 'Approve invoice';

  @override
  String get invoiceRequestChanges => 'Request changes';

  @override
  String get invoiceChangesReason => 'What needs to change?';

  @override
  String get invoiceChangesReasonRequired =>
      'Explain which changes are needed.';

  @override
  String get invoiceApprovalSaveFailed =>
      'Approval could not be saved. Try again.';

  @override
  String get invoiceNeedsApproval => 'Needs approval';

  @override
  String get workOverallPrice => 'Price for the work';

  @override
  String get workOverallPriceHint =>
      'Enter one price, or add individual items below';

  @override
  String get workOptionalItems => 'Add items (optional)';

  @override
  String get clientSaved => 'Saved clients';

  @override
  String get clientAddNew => 'Add new client';

  @override
  String get clientNoSaved => 'No saved clients';

  @override
  String get clientSearch => 'Search clients';

  @override
  String get clientNoMatches => 'No matching clients';

  @override
  String get clientForEstimate => 'Client for this estimate';

  @override
  String get clientSelectForEstimate => 'Select a client for this estimate.';

  @override
  String get clientViewDenied =>
      'You do not have permission to view saved clients.';

  @override
  String get clientUnfinished => 'Unfinished client forms';

  @override
  String get clientContinueHint =>
      'Continue information you previously started.';

  @override
  String get clientRecoveryRetry =>
      'Unfinished client forms unavailable — Retry';

  @override
  String get clientNameMissing => 'Client name not entered';

  @override
  String get clientRecoveryFailed =>
      'Could not open unfinished client information. Your input has been kept. Try again.';

  @override
  String get clientDetails => 'Client details';

  @override
  String get clientName => 'Client name';

  @override
  String get clientNameHint => 'First and last name, or business name';

  @override
  String get clientBusiness => 'Client’s business (optional)';

  @override
  String get clientPhone => 'Phone (including area code)';

  @override
  String get clientEmail => 'Email (optional)';

  @override
  String get clientPreferredContact => 'Preferred contact';

  @override
  String get clientCall => 'Phone call';

  @override
  String get clientText => 'Text message';

  @override
  String get clientEmailMethod => 'Email';

  @override
  String get clientLocations => 'Billing and service location';

  @override
  String get clientBilling => 'Billing address';

  @override
  String get clientAddressLabel => 'Address label (optional)';

  @override
  String get clientAddressHint => 'Home, office, or another name';

  @override
  String get clientServiceAddress => 'Service address';

  @override
  String get clientAccess => 'Getting into the property (optional)';

  @override
  String get clientAccessHint => 'Gate code, parking, or entry instructions';

  @override
  String get clientNotes => 'Client notes (optional)';

  @override
  String get clientNotesHint =>
      'Notes about the client, separate from property access instructions.';

  @override
  String get clientSaveUse => 'Save and use client';

  @override
  String get clientSave => 'Save client';

  @override
  String get clientSaveChanges => 'Save client changes';

  @override
  String get clientEdit => 'Edit client';
}
