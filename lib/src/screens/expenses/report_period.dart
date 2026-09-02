import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../shared/localized_date.dart';

enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  thisCalendarQuarter,
  previousCalendarQuarter,
  previous90Days,
  yearToDate,
  previous12Months;

  String localizedLabel(AppLocalizations localizations) => switch (this) {
    ReportPeriod.today => localizations.reportToday,
    ReportPeriod.thisWeek => localizations.reportThisWeek,
    ReportPeriod.thisMonth => localizations.reportThisMonth,
    ReportPeriod.thisCalendarQuarter => localizations.reportThisCalendarQuarter,
    ReportPeriod.previousCalendarQuarter =>
      localizations.reportPreviousCalendarQuarter,
    ReportPeriod.previous90Days => localizations.reportPrevious90Days,
    ReportPeriod.yearToDate => localizations.reportYearToDate,
    ReportPeriod.previous12Months => localizations.reportPrevious12Months,
  };

  ({DateTime fromInclusive, DateTime toExclusive}) rangeFor(DateTime value) {
    final today = DateTime(value.year, value.month, value.day);
    final tomorrow = today.add(const Duration(days: 1));
    final quarterMonth = ((today.month - 1) ~/ 3) * 3 + 1;
    final quarterStart = DateTime(today.year, quarterMonth);
    return switch (this) {
      ReportPeriod.today => (fromInclusive: today, toExclusive: tomorrow),
      ReportPeriod.thisWeek => (
        fromInclusive: today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        ),
        toExclusive: today
            .subtract(Duration(days: today.weekday - DateTime.monday))
            .add(const Duration(days: 7)),
      ),
      ReportPeriod.thisMonth => (
        fromInclusive: DateTime(today.year, today.month),
        toExclusive: DateTime(today.year, today.month + 1),
      ),
      ReportPeriod.thisCalendarQuarter => (
        fromInclusive: quarterStart,
        toExclusive: DateTime(today.year, quarterMonth + 3),
      ),
      ReportPeriod.previousCalendarQuarter => (
        fromInclusive: DateTime(today.year, quarterMonth - 3),
        toExclusive: quarterStart,
      ),
      ReportPeriod.previous90Days => (
        fromInclusive: today.subtract(const Duration(days: 89)),
        toExclusive: tomorrow,
      ),
      ReportPeriod.yearToDate => (
        fromInclusive: DateTime(today.year),
        toExclusive: tomorrow,
      ),
      ReportPeriod.previous12Months => (
        fromInclusive: _sameDayPreviousYear(today),
        toExclusive: tomorrow,
      ),
    };
  }

  String dateRangeLabel(BuildContext context, DateTime value) {
    final range = rangeFor(value);
    final inclusiveEnd = range.toExclusive.subtract(const Duration(days: 1));
    return operationalDateRangeLabel(
      context,
      range.fromInclusive,
      inclusiveEnd,
    );
  }
}

class ReportDisplayPreferences {
  const ReportDisplayPreferences({
    required this.showInvoicedRevenue,
    required this.showMoneyCollected,
    required this.showRecordedExpenses,
    required this.showEstimatedGrossProfit,
    required this.showVehicleHealth,
  });

  const ReportDisplayPreferences.defaults()
    : showInvoicedRevenue = true,
      showMoneyCollected = true,
      showRecordedExpenses = true,
      showEstimatedGrossProfit = true,
      showVehicleHealth = true;

  final bool showInvoicedRevenue;
  final bool showMoneyCollected;
  final bool showRecordedExpenses;
  final bool showEstimatedGrossProfit;
  final bool showVehicleHealth;

  ReportDisplayPreferences copyWith({
    bool? showInvoicedRevenue,
    bool? showMoneyCollected,
    bool? showRecordedExpenses,
    bool? showEstimatedGrossProfit,
    bool? showVehicleHealth,
  }) => ReportDisplayPreferences(
    showInvoicedRevenue: showInvoicedRevenue ?? this.showInvoicedRevenue,
    showMoneyCollected: showMoneyCollected ?? this.showMoneyCollected,
    showRecordedExpenses: showRecordedExpenses ?? this.showRecordedExpenses,
    showEstimatedGrossProfit:
        showEstimatedGrossProfit ?? this.showEstimatedGrossProfit,
    showVehicleHealth: showVehicleHealth ?? this.showVehicleHealth,
  );
}

DateTime _sameDayPreviousYear(DateTime day) {
  final lastDay = DateTime(day.year - 1, day.month + 1, 0).day;
  return DateTime(day.year - 1, day.month, math.min(day.day, lastDay));
}
