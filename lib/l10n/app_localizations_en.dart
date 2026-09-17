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
}
