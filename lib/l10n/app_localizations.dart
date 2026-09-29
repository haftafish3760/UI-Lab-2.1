import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('es', 'US'),
    Locale('fr'),
    Locale('fr', 'CA'),
  ];

  /// No description provided for @selectVehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get selectVehicleLabel;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tame Your Biz'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @dashboardOdometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get dashboardOdometerLabel;

  /// No description provided for @dashboardStartWorkday.
  ///
  /// In en, this message translates to:
  /// **'Start workday'**
  String get dashboardStartWorkday;

  /// No description provided for @dashboardPaymentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get dashboardPaymentsLabel;

  /// No description provided for @dashboardMilesLabel.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get dashboardMilesLabel;

  /// No description provided for @dashboardMileageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Business mileage totals are not connected yet. No zero total has been assumed.'**
  String get dashboardMileageUnavailable;

  /// No description provided for @navDashboardCompact.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboardCompact;

  /// No description provided for @navWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get navWork;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get navInventory;

  /// No description provided for @navMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get navMaintenance;

  /// No description provided for @fieldRecords.
  ///
  /// In en, this message translates to:
  /// **'Field records'**
  String get fieldRecords;

  /// No description provided for @offlineRecordsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Records stay available offline.'**
  String get offlineRecordsAvailable;

  /// No description provided for @advertisementPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Advertisement placeholder'**
  String get advertisementPlaceholder;

  /// No description provided for @advertisement.
  ///
  /// In en, this message translates to:
  /// **'ADVERTISEMENT'**
  String get advertisement;

  /// No description provided for @sampleAdSpace.
  ///
  /// In en, this message translates to:
  /// **'Sample ad space'**
  String get sampleAdSpace;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @operationalViewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get operationalViewLabel;

  /// No description provided for @operationalViewValue.
  ///
  /// In en, this message translates to:
  /// **'View: {view}'**
  String operationalViewValue(String view);

  /// No description provided for @operationalChangeViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get operationalChangeViewTooltip;

  /// No description provided for @operationalChangeContextTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change work context'**
  String get operationalChangeContextTooltip;

  /// No description provided for @operationalContextSemantics.
  ///
  /// In en, this message translates to:
  /// **'{context}: {value}'**
  String operationalContextSemantics(String context, String value);

  /// No description provided for @operationalViewTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get operationalViewTechnician;

  /// No description provided for @operationalViewAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get operationalViewAdmin;

  /// No description provided for @operationalContextEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get operationalContextEmployee;

  /// No description provided for @operationalContextVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get operationalContextVehicle;

  /// No description provided for @operationalContextActiveVehicle.
  ///
  /// In en, this message translates to:
  /// **'Active vehicle'**
  String get operationalContextActiveVehicle;

  /// No description provided for @operationalCompanyOverview.
  ///
  /// In en, this message translates to:
  /// **'Company Overview'**
  String get operationalCompanyOverview;

  /// No description provided for @operationalFleetOverview.
  ///
  /// In en, this message translates to:
  /// **'Fleet Overview'**
  String get operationalFleetOverview;

  /// No description provided for @operationalPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get operationalPreviousDay;

  /// No description provided for @operationalNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get operationalNextDay;

  /// No description provided for @operationalReturnToToday.
  ///
  /// In en, this message translates to:
  /// **'Return to today'**
  String get operationalReturnToToday;

  /// No description provided for @operationalUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Notifications. Nothing new.} =1 {Notifications. 1 unread item.} other {Notifications. {count} unread items.}}'**
  String operationalUnreadNotifications(int count);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Reminders and updates'**
  String get notificationsHeading;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications report reminders and updates. Decisions remain in Needs attention.'**
  String get notificationsDescription;

  /// No description provided for @nativeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Tame Your Biz reminder'**
  String get nativeReminderTitle;

  /// No description provided for @nativeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Open Tame Your Biz to review a scheduled reminder.'**
  String get nativeReminderBody;

  /// No description provided for @deviceRemindersUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Device reminders unavailable'**
  String get deviceRemindersUnavailableTitle;

  /// No description provided for @deviceRemindersRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry device reminders'**
  String get deviceRemindersRetry;

  /// No description provided for @deviceRemindersOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Device reminders are off'**
  String get deviceRemindersOffTitle;

  /// No description provided for @deviceRemindersOffBody.
  ///
  /// In en, this message translates to:
  /// **'In-app reminders still work. Enable device notifications to receive reminders when Tame Your Biz is closed.'**
  String get deviceRemindersOffBody;

  /// No description provided for @deviceRemindersEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable device reminders'**
  String get deviceRemindersEnable;

  /// No description provided for @deviceRemindersEnabling.
  ///
  /// In en, this message translates to:
  /// **'Enabling device reminders'**
  String get deviceRemindersEnabling;

  /// No description provided for @deviceRemindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Device reminders are still off. You can allow Tame Your Biz notifications in system settings.'**
  String get deviceRemindersDenied;

  /// No description provided for @deviceRemindersFailed.
  ///
  /// In en, this message translates to:
  /// **'Device reminders could not be updated. Try again.'**
  String get deviceRemindersFailed;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders or updates are currently available.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded.'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationUnreadState.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnreadState;

  /// No description provided for @notificationReadState.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationReadState;

  /// No description provided for @notificationDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get notificationDueToday;

  /// No description provided for @notificationDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get notificationDueTomorrow;

  /// No description provided for @notificationDueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {count} days'**
  String notificationDueInDays(int count);

  /// No description provided for @notificationDaysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 day overdue} other {{count} days overdue}}'**
  String notificationDaysOverdue(int count);

  /// No description provided for @operationalNotificationsAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Notifications. Nothing needs attention.} =1 {Notifications. 1 item needs attention.} other {Notifications. {count} items need attention.}}'**
  String operationalNotificationsAttention(int count);

  /// No description provided for @attentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get attentionTitle;

  /// No description provided for @attentionShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String attentionShowAll(int count);

  /// No description provided for @attentionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Needs attention'**
  String get attentionDismiss;

  /// No description provided for @attentionNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention right now.'**
  String get attentionNothing;

  /// No description provided for @reportToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get reportToday;

  /// No description provided for @reportThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reportThisWeek;

  /// No description provided for @reportThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportThisMonth;

  /// No description provided for @reportThisCalendarQuarter.
  ///
  /// In en, this message translates to:
  /// **'This calendar quarter'**
  String get reportThisCalendarQuarter;

  /// No description provided for @reportPreviousCalendarQuarter.
  ///
  /// In en, this message translates to:
  /// **'Previous calendar quarter'**
  String get reportPreviousCalendarQuarter;

  /// No description provided for @reportPrevious90Days.
  ///
  /// In en, this message translates to:
  /// **'Previous 90 days'**
  String get reportPrevious90Days;

  /// No description provided for @reportYearToDate.
  ///
  /// In en, this message translates to:
  /// **'Year to date'**
  String get reportYearToDate;

  /// No description provided for @reportPrevious12Months.
  ///
  /// In en, this message translates to:
  /// **'Previous 12 months'**
  String get reportPrevious12Months;

  /// No description provided for @calendarMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonthView;

  /// No description provided for @calendarWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeekView;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get calendarPreviousWeek;

  /// No description provided for @calendarNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get calendarNextWeek;

  /// No description provided for @calendarChooseWorkDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a work date'**
  String get calendarChooseWorkDate;

  /// No description provided for @calendarMondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get calendarMondayShort;

  /// No description provided for @calendarTuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get calendarTuesdayShort;

  /// No description provided for @calendarWednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get calendarWednesdayShort;

  /// No description provided for @calendarThursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get calendarThursdayShort;

  /// No description provided for @calendarFridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get calendarFridayShort;

  /// No description provided for @calendarSaturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get calendarSaturdayShort;

  /// No description provided for @calendarSundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get calendarSundayShort;

  /// No description provided for @calendarTodayState.
  ///
  /// In en, this message translates to:
  /// **'Today.'**
  String get calendarTodayState;

  /// No description provided for @calendarOutsideMonthState.
  ///
  /// In en, this message translates to:
  /// **'Outside the selected month.'**
  String get calendarOutsideMonthState;

  /// No description provided for @calendarNeedsApprovalState.
  ///
  /// In en, this message translates to:
  /// **'Needs approval.'**
  String get calendarNeedsApprovalState;

  /// No description provided for @calendarRecordSingular.
  ///
  /// In en, this message translates to:
  /// **'record'**
  String get calendarRecordSingular;

  /// No description provided for @calendarRecordPlural.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get calendarRecordPlural;

  /// No description provided for @calendarDashboardEntrySingular.
  ///
  /// In en, this message translates to:
  /// **'dashboard entry'**
  String get calendarDashboardEntrySingular;

  /// No description provided for @calendarDashboardEntryPlural.
  ///
  /// In en, this message translates to:
  /// **'dashboard entries'**
  String get calendarDashboardEntryPlural;

  /// No description provided for @calendarWorkRecordSingular.
  ///
  /// In en, this message translates to:
  /// **'work record'**
  String get calendarWorkRecordSingular;

  /// No description provided for @calendarWorkRecordPlural.
  ///
  /// In en, this message translates to:
  /// **'work records'**
  String get calendarWorkRecordPlural;

  /// No description provided for @calendarJobSingular.
  ///
  /// In en, this message translates to:
  /// **'job'**
  String get calendarJobSingular;

  /// No description provided for @calendarJobPlural.
  ///
  /// In en, this message translates to:
  /// **'jobs'**
  String get calendarJobPlural;

  /// No description provided for @calendarEstimateSingular.
  ///
  /// In en, this message translates to:
  /// **'estimate'**
  String get calendarEstimateSingular;

  /// No description provided for @calendarEstimatePlural.
  ///
  /// In en, this message translates to:
  /// **'estimates'**
  String get calendarEstimatePlural;

  /// No description provided for @calendarInvoiceSingular.
  ///
  /// In en, this message translates to:
  /// **'invoice'**
  String get calendarInvoiceSingular;

  /// No description provided for @calendarInvoicePlural.
  ///
  /// In en, this message translates to:
  /// **'invoices'**
  String get calendarInvoicePlural;

  /// No description provided for @calendarPaymentSingular.
  ///
  /// In en, this message translates to:
  /// **'payment'**
  String get calendarPaymentSingular;

  /// No description provided for @calendarPaymentPlural.
  ///
  /// In en, this message translates to:
  /// **'payments'**
  String get calendarPaymentPlural;

  /// No description provided for @calendarExpenseSingular.
  ///
  /// In en, this message translates to:
  /// **'expense'**
  String get calendarExpenseSingular;

  /// No description provided for @calendarExpensePlural.
  ///
  /// In en, this message translates to:
  /// **'expenses'**
  String get calendarExpensePlural;

  /// No description provided for @calendarInventoryRecordSingular.
  ///
  /// In en, this message translates to:
  /// **'materials record'**
  String get calendarInventoryRecordSingular;

  /// No description provided for @calendarInventoryRecordPlural.
  ///
  /// In en, this message translates to:
  /// **'materials records'**
  String get calendarInventoryRecordPlural;

  /// No description provided for @calendarNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No {recordLabel}.'**
  String calendarNoRecords(String recordLabel);

  /// No description provided for @calendarRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {recordLabel}.'**
  String calendarRecordCount(int count, String recordLabel);

  /// No description provided for @catalogBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse Catalog'**
  String get catalogBrowse;

  /// No description provided for @catalogInventory.
  ///
  /// In en, this message translates to:
  /// **'My Inventory'**
  String get catalogInventory;

  /// No description provided for @catalogGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get catalogGrid;

  /// No description provided for @catalogList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get catalogList;

  /// No description provided for @catalogChooseTrade.
  ///
  /// In en, this message translates to:
  /// **'Choose a trade'**
  String get catalogChooseTrade;

  /// No description provided for @catalogChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get catalogChooseCategory;

  /// No description provided for @catalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get catalogSearch;

  /// No description provided for @catalogSearchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search this category'**
  String get catalogSearchCategory;

  /// No description provided for @catalogClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get catalogClear;

  /// No description provided for @catalogPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get catalogPlumbing;

  /// No description provided for @catalogElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get catalogElectrical;

  /// No description provided for @catalogHvac.
  ///
  /// In en, this message translates to:
  /// **'HVAC'**
  String get catalogHvac;

  /// No description provided for @catalogFittings.
  ///
  /// In en, this message translates to:
  /// **'Fittings'**
  String get catalogFittings;

  /// No description provided for @catalogCopper.
  ///
  /// In en, this message translates to:
  /// **'Copper'**
  String get catalogCopper;

  /// No description provided for @catalogElbows90.
  ///
  /// In en, this message translates to:
  /// **'90° Elbows'**
  String get catalogElbows90;

  /// No description provided for @catalogItemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get catalogItemDetails;

  /// No description provided for @catalogAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to My Inventory'**
  String get catalogAdd;

  /// No description provided for @catalogSize.
  ///
  /// In en, this message translates to:
  /// **'Nominal size: {size}'**
  String catalogSize(String size);

  /// No description provided for @catalogUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String catalogUnit(String unit);

  /// No description provided for @catalogEach.
  ///
  /// In en, this message translates to:
  /// **'each'**
  String get catalogEach;

  /// No description provided for @catalogCopperElbow.
  ///
  /// In en, this message translates to:
  /// **'{size} Copper 90° Elbow'**
  String catalogCopperElbow(String size);

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'This category is being rebuilt.'**
  String get catalogEmpty;

  /// No description provided for @catalogNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching items. Try another name or size.'**
  String get catalogNoMatches;

  /// No description provided for @workFilterAwaitingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Estimates awaiting customer'**
  String get workFilterAwaitingCustomer;

  /// No description provided for @workFilterUnscheduledJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs needing scheduling'**
  String get workFilterUnscheduledJobs;

  /// No description provided for @workFilterActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get workFilterActiveJobs;

  /// No description provided for @workFilterUnpaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Outstanding invoices'**
  String get workFilterUnpaidInvoices;

  /// No description provided for @workFilterAllEstimates.
  ///
  /// In en, this message translates to:
  /// **'All estimates'**
  String get workFilterAllEstimates;

  /// No description provided for @workFilterDraftEstimates.
  ///
  /// In en, this message translates to:
  /// **'Draft estimates'**
  String get workFilterDraftEstimates;

  /// No description provided for @workFilterCompanyReviewEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates awaiting company approval'**
  String get workFilterCompanyReviewEstimates;

  /// No description provided for @workFilterReadyEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates ready to send'**
  String get workFilterReadyEstimates;

  /// No description provided for @workFilterChangedEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates with changes requested'**
  String get workFilterChangedEstimates;

  /// No description provided for @workFilterApprovedEstimates.
  ///
  /// In en, this message translates to:
  /// **'Approved estimates'**
  String get workFilterApprovedEstimates;

  /// No description provided for @workFilterDeclinedEstimates.
  ///
  /// In en, this message translates to:
  /// **'Declined estimates'**
  String get workFilterDeclinedEstimates;

  /// No description provided for @workFilterExpiredEstimates.
  ///
  /// In en, this message translates to:
  /// **'Expired estimates'**
  String get workFilterExpiredEstimates;

  /// No description provided for @workFilterAllJobs.
  ///
  /// In en, this message translates to:
  /// **'All jobs'**
  String get workFilterAllJobs;

  /// No description provided for @workFilterCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs'**
  String get workFilterCompletedJobs;

  /// No description provided for @workFilterAllInvoices.
  ///
  /// In en, this message translates to:
  /// **'All invoices'**
  String get workFilterAllInvoices;

  /// No description provided for @workFilterDraftInvoices.
  ///
  /// In en, this message translates to:
  /// **'Draft invoices'**
  String get workFilterDraftInvoices;

  /// No description provided for @workFilterPaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices paid in full'**
  String get workFilterPaidInvoices;

  /// No description provided for @workFilterOverdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'Overdue invoices'**
  String get workFilterOverdueInvoices;

  /// No description provided for @workStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get workStatusDraft;

  /// No description provided for @workStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get workStatusReady;

  /// No description provided for @workStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get workStatusSent;

  /// No description provided for @workStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get workStatusAccepted;

  /// No description provided for @workStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get workStatusScheduled;

  /// No description provided for @workStatusEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get workStatusEnRoute;

  /// No description provided for @workStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get workStatusArrived;

  /// No description provided for @workStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get workStatusInProgress;

  /// No description provided for @workStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get workStatusPaused;

  /// No description provided for @workStatusNeedsReturnVisit.
  ///
  /// In en, this message translates to:
  /// **'Needs return visit'**
  String get workStatusNeedsReturnVisit;

  /// No description provided for @workStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get workStatusCompleted;

  /// No description provided for @workStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get workStatusDue;

  /// No description provided for @workStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get workStatusPaid;

  /// No description provided for @workStatusReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get workStatusReadyToSend;

  /// No description provided for @workStatusAwaitingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Awaiting customer'**
  String get workStatusAwaitingCustomer;

  /// No description provided for @workStatusViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get workStatusViewed;

  /// No description provided for @workStatusChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get workStatusChangesRequested;

  /// No description provided for @workStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get workStatusApproved;

  /// No description provided for @workStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get workStatusDeclined;

  /// No description provided for @workStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get workStatusExpired;

  /// No description provided for @workStatusConverted.
  ///
  /// In en, this message translates to:
  /// **'Converted to job'**
  String get workStatusConverted;

  /// No description provided for @workStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get workStatusArchived;

  /// No description provided for @workOverviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Work overview · All dates'**
  String get workOverviewHeading;

  /// No description provided for @workBrowseRecords.
  ///
  /// In en, this message translates to:
  /// **'Browse records'**
  String get workBrowseRecords;

  /// No description provided for @workRecordsHeading.
  ///
  /// In en, this message translates to:
  /// **'Work records'**
  String get workRecordsHeading;

  /// No description provided for @workShowRecords.
  ///
  /// In en, this message translates to:
  /// **'Show records'**
  String get workShowRecords;

  /// No description provided for @workSearchRecords.
  ///
  /// In en, this message translates to:
  /// **'Search customer, title or number'**
  String get workSearchRecords;

  /// No description provided for @workNoMatchingRecords.
  ///
  /// In en, this message translates to:
  /// **'No matching records. Try another status or search.'**
  String get workNoMatchingRecords;

  /// No description provided for @workRecordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This record is no longer available.'**
  String get workRecordUnavailable;

  /// No description provided for @workNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get workNotScheduled;

  /// No description provided for @workCreatedDateMissing.
  ///
  /// In en, this message translates to:
  /// **'Created date not recorded'**
  String get workCreatedDateMissing;

  /// No description provided for @workCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String workCreatedDate(String date);

  /// No description provided for @workCompletedDate.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String workCompletedDate(String date);

  /// No description provided for @workScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {date}'**
  String workScheduledDate(String date);

  /// No description provided for @workDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String workDueDate(String date);

  /// No description provided for @workRecordCount.
  ///
  /// In en, this message translates to:
  /// **'All dates · {count, plural, =0{0 records} =1{1 record} other{{count} records}}'**
  String workRecordCount(int count);

  /// No description provided for @workDocumentStyle.
  ///
  /// In en, this message translates to:
  /// **'Customer document'**
  String get workDocumentStyle;

  /// No description provided for @workDocumentDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get workDocumentDetailed;

  /// No description provided for @workDocumentSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get workDocumentSummary;

  /// No description provided for @workDocumentDetailedHelp.
  ///
  /// In en, this message translates to:
  /// **'Show each item, description, quantity and price.'**
  String get workDocumentDetailedHelp;

  /// No description provided for @workDocumentSummaryHelp.
  ///
  /// In en, this message translates to:
  /// **'Show the work description and overall price. Keep individual items and costs in your records.'**
  String get workDocumentSummaryHelp;

  /// No description provided for @workServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Price for the work'**
  String get workServicePrice;

  /// No description provided for @workEnterServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter one price'**
  String get workEnterServicePrice;

  /// No description provided for @workPriceBeforeAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Price before discount and tax'**
  String get workPriceBeforeAdjustments;

  /// No description provided for @workMoneyPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid in full'**
  String get workMoneyPaid;

  /// No description provided for @workMoneyUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get workMoneyUnpaid;

  /// No description provided for @workMoneyOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get workMoneyOverdue;

  /// No description provided for @workMoneyAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get workMoneyAllTime;

  /// No description provided for @workInvoicesWithPayments.
  ///
  /// In en, this message translates to:
  /// **'Invoices with payments'**
  String get workInvoicesWithPayments;

  /// No description provided for @workPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get workPartiallyPaid;

  /// No description provided for @workInvoiceHeading.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get workInvoiceHeading;

  /// No description provided for @workFilterAllShort.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get workFilterAllShort;

  /// No description provided for @workPaymentsReceivedShort.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get workPaymentsReceivedShort;

  /// No description provided for @workDraftsShort.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get workDraftsShort;

  /// No description provided for @workInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice total'**
  String get workInvoiceTotal;

  /// No description provided for @workInvoiceBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get workInvoiceBalance;

  /// No description provided for @workNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get workNewInvoice;

  /// No description provided for @workInvoiceActivityByDate.
  ///
  /// In en, this message translates to:
  /// **'Date activity'**
  String get workInvoiceActivityByDate;

  /// No description provided for @workInvoiceActivityHeading.
  ///
  /// In en, this message translates to:
  /// **'Invoice activity'**
  String get workInvoiceActivityHeading;

  /// No description provided for @workInvoiceAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view invoices.'**
  String get workInvoiceAccessDenied;

  /// No description provided for @workSearchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Search invoices'**
  String get workSearchInvoices;

  /// No description provided for @workSearchInvoicesHint.
  ///
  /// In en, this message translates to:
  /// **'Customer, job, invoice number, or work title'**
  String get workSearchInvoicesHint;

  /// No description provided for @workInvoiceMatches.
  ///
  /// In en, this message translates to:
  /// **'Invoice matches'**
  String get workInvoiceMatches;

  /// No description provided for @workInvoiceNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No authorized invoices match that search.'**
  String get workInvoiceNoMatches;

  /// No description provided for @workInvoicesForDate.
  ///
  /// In en, this message translates to:
  /// **'Invoices for this date'**
  String get workInvoicesForDate;

  /// No description provided for @workInvoiceNoDateActivity.
  ///
  /// In en, this message translates to:
  /// **'No invoice activity is recorded for this date.'**
  String get workInvoiceNoDateActivity;

  /// No description provided for @workOpenInvoices.
  ///
  /// In en, this message translates to:
  /// **'Other unpaid invoices'**
  String get workOpenInvoices;

  /// No description provided for @workInvoiceNoOpenBalance.
  ///
  /// In en, this message translates to:
  /// **'No other invoices have an open balance.'**
  String get workInvoiceNoOpenBalance;

  /// No description provided for @workShowOnlyThree.
  ///
  /// In en, this message translates to:
  /// **'Show only 3'**
  String get workShowOnlyThree;

  /// No description provided for @workInvoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This invoice is no longer available.'**
  String get workInvoiceUnavailable;

  /// No description provided for @workInvoiceAttention.
  ///
  /// In en, this message translates to:
  /// **'Invoice attention'**
  String get workInvoiceAttention;

  /// No description provided for @workInvoiceDrafts.
  ///
  /// In en, this message translates to:
  /// **'Invoice drafts'**
  String get workInvoiceDrafts;

  /// No description provided for @workInvoiceOverdueReason.
  ///
  /// In en, this message translates to:
  /// **'Invoice is overdue · {customer}'**
  String workInvoiceOverdueReason(String customer);

  /// No description provided for @workInvoiceActivityCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get workInvoiceActivityCreated;

  /// No description provided for @workInvoiceActivityIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get workInvoiceActivityIssued;

  /// No description provided for @workInvoiceActivityDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get workInvoiceActivityDue;

  /// No description provided for @workInvoiceActivityPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get workInvoiceActivityPayment;

  /// No description provided for @workInvoiceActivityApplied.
  ///
  /// In en, this message translates to:
  /// **'Payment applied'**
  String get workInvoiceActivityApplied;

  /// No description provided for @workSavedClients.
  ///
  /// In en, this message translates to:
  /// **'Saved clients'**
  String get workSavedClients;

  /// No description provided for @workAddClient.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get workAddClient;

  /// No description provided for @workUseClient.
  ///
  /// In en, this message translates to:
  /// **'Use this client'**
  String get workUseClient;

  /// No description provided for @workSearchClients.
  ///
  /// In en, this message translates to:
  /// **'Search saved clients'**
  String get workSearchClients;

  /// No description provided for @workClientsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view saved clients.'**
  String get workClientsUnavailable;

  /// No description provided for @workNoMatchingClients.
  ///
  /// In en, this message translates to:
  /// **'No matching clients. Try another search or add a new client.'**
  String get workNoMatchingClients;

  /// No description provided for @invoiceRequestApproval.
  ///
  /// In en, this message translates to:
  /// **'Request approval'**
  String get invoiceRequestApproval;

  /// No description provided for @invoiceApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve invoice'**
  String get invoiceApprove;

  /// No description provided for @invoiceRequestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request changes'**
  String get invoiceRequestChanges;

  /// No description provided for @invoiceChangesReason.
  ///
  /// In en, this message translates to:
  /// **'What needs to change?'**
  String get invoiceChangesReason;

  /// No description provided for @invoiceChangesReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Explain which changes are needed.'**
  String get invoiceChangesReasonRequired;

  /// No description provided for @invoiceApprovalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Approval could not be saved. Try again.'**
  String get invoiceApprovalSaveFailed;

  /// No description provided for @invoiceNeedsApproval.
  ///
  /// In en, this message translates to:
  /// **'Needs approval'**
  String get invoiceNeedsApproval;

  /// No description provided for @workOverallPrice.
  ///
  /// In en, this message translates to:
  /// **'Price for the work'**
  String get workOverallPrice;

  /// No description provided for @workOverallPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter one price, or add individual items below'**
  String get workOverallPriceHint;

  /// No description provided for @workOptionalItems.
  ///
  /// In en, this message translates to:
  /// **'Add items (optional)'**
  String get workOptionalItems;

  /// No description provided for @clientSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved clients'**
  String get clientSaved;

  /// No description provided for @clientAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add new client'**
  String get clientAddNew;

  /// No description provided for @clientNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved clients'**
  String get clientNoSaved;

  /// No description provided for @clientSearch.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get clientSearch;

  /// No description provided for @clientNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching clients'**
  String get clientNoMatches;

  /// No description provided for @clientForEstimate.
  ///
  /// In en, this message translates to:
  /// **'Client for this estimate'**
  String get clientForEstimate;

  /// No description provided for @clientSelectForEstimate.
  ///
  /// In en, this message translates to:
  /// **'Select a client for this estimate.'**
  String get clientSelectForEstimate;

  /// No description provided for @clientViewDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view saved clients.'**
  String get clientViewDenied;

  /// No description provided for @clientUnfinished.
  ///
  /// In en, this message translates to:
  /// **'Unfinished client forms'**
  String get clientUnfinished;

  /// No description provided for @clientContinueHint.
  ///
  /// In en, this message translates to:
  /// **'Continue information you previously started.'**
  String get clientContinueHint;

  /// No description provided for @clientRecoveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Unfinished client forms unavailable — Retry'**
  String get clientRecoveryRetry;

  /// No description provided for @clientNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Client name not entered'**
  String get clientNameMissing;

  /// No description provided for @clientRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open unfinished client information. Your input has been kept. Try again.'**
  String get clientRecoveryFailed;

  /// No description provided for @clientDetails.
  ///
  /// In en, this message translates to:
  /// **'Client details'**
  String get clientDetails;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get clientName;

  /// No description provided for @clientNameHint.
  ///
  /// In en, this message translates to:
  /// **'First and last name, or business name'**
  String get clientNameHint;

  /// No description provided for @clientBusiness.
  ///
  /// In en, this message translates to:
  /// **'Client’s business (optional)'**
  String get clientBusiness;

  /// No description provided for @clientPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (including area code)'**
  String get clientPhone;

  /// No description provided for @clientEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get clientEmail;

  /// No description provided for @clientPreferredContact.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact'**
  String get clientPreferredContact;

  /// No description provided for @clientCall.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get clientCall;

  /// No description provided for @clientText.
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get clientText;

  /// No description provided for @clientEmailMethod.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientEmailMethod;

  /// No description provided for @clientLocations.
  ///
  /// In en, this message translates to:
  /// **'Billing and service location'**
  String get clientLocations;

  /// No description provided for @clientBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing address'**
  String get clientBilling;

  /// No description provided for @clientAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address label (optional)'**
  String get clientAddressLabel;

  /// No description provided for @clientAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Home, office, or another name'**
  String get clientAddressHint;

  /// No description provided for @clientServiceAddress.
  ///
  /// In en, this message translates to:
  /// **'Service address'**
  String get clientServiceAddress;

  /// No description provided for @clientAccess.
  ///
  /// In en, this message translates to:
  /// **'Getting into the property (optional)'**
  String get clientAccess;

  /// No description provided for @clientAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Gate code, parking, or entry instructions'**
  String get clientAccessHint;

  /// No description provided for @clientNotes.
  ///
  /// In en, this message translates to:
  /// **'Client notes (optional)'**
  String get clientNotes;

  /// No description provided for @clientNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes about the client, separate from property access instructions.'**
  String get clientNotesHint;

  /// No description provided for @clientSaveUse.
  ///
  /// In en, this message translates to:
  /// **'Save and use client'**
  String get clientSaveUse;

  /// No description provided for @clientSave.
  ///
  /// In en, this message translates to:
  /// **'Save client'**
  String get clientSave;

  /// No description provided for @clientSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save client changes'**
  String get clientSaveChanges;

  /// No description provided for @clientEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit client'**
  String get clientEdit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case 'US':
            return AppLocalizationsEsUs();
        }
        break;
      }
    case 'fr':
      {
        switch (locale.countryCode) {
          case 'CA':
            return AppLocalizationsFrCa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
