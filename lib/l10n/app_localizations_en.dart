// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

  @override
  String get navDashboard => 'Dashboard';

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
  String get nativeReminderTitle => 'Maintainiac reminder';

  @override
  String get nativeReminderBody =>
      'Open Maintainiac to review a scheduled reminder.';

  @override
  String get deviceRemindersOffTitle => 'Device reminders are off';

  @override
  String get deviceRemindersOffBody =>
      'In-app reminders still work. Enable device notifications to receive reminders when Maintainiac is closed.';

  @override
  String get deviceRemindersEnable => 'Enable device reminders';

  @override
  String get deviceRemindersEnabling => 'Enabling device reminders';

  @override
  String get deviceRemindersDenied =>
      'Device reminders are still off. You can allow Maintainiac notifications in system settings.';

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
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get appTitle => 'Maintainiac UI Lab 2.1';

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
}
