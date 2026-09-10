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
  /// **'Maintainiac UI Lab 2.1'**
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
  /// **'Business mileage totals are not connected in this UI Lab preview yet. No zero total has been assumed.'**
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
  /// **'Maintainiac reminder'**
  String get nativeReminderTitle;

  /// No description provided for @nativeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Open Maintainiac to review a scheduled reminder.'**
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
  /// **'In-app reminders still work. Enable device notifications to receive reminders when Maintainiac is closed.'**
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
  /// **'Device reminders are still off. You can allow Maintainiac notifications in system settings.'**
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
