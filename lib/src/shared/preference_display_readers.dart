import '../data/preferences/expense_display_preferences.dart';
import '../data/preferences/report_display_preferences.dart';
import 'package:flutter/widgets.dart';
import '../data/preferences/receipt_intake_display_preferences.dart';
import '../data/preferences/work_record_display_preferences.dart';
import 'app_preferences.dart';

ReceiptIntakeDisplayPreferences readReceiptIntakeDisplayPreferences(
  BuildContext context,
  ReceiptIntakeDisplayPreferences fallback,
) {
  final saved = AppPreferencesScope.maybeOf(context);
  if (saved == null) return fallback;
  return ReceiptIntakeDisplayPreferences(
    showReviewChecklist: saved.receiptShowReviewChecklist,
    showEvidenceReminders: saved.receiptShowEvidenceReminders,
  );
}

WorkRecordDisplayPreferences readWorkRecordDisplayPreferences(
  BuildContext context,
  String workspace,
  WorkRecordDisplayPreferences fallback,
) {
  final saved = AppPreferencesScope.maybeOf(context);
  if (saved == null) return fallback;
  return WorkRecordDisplayPreferences(
    showStatusDetails: saved.workListChoice(workspace, 'showStatusDetails'),
    showAssignments: saved.workListChoice(workspace, 'showAssignments'),
    includeClosedRecords: saved.workListChoice(
      workspace,
      'includeClosedRecords',
    ),
  );
}

ReportDisplayPreferences readReportDisplayPreferences(
  BuildContext context,
  ReportDisplayPreferences fallback,
) {
  final saved = AppPreferencesScope.maybeOf(context);
  if (saved == null) return fallback;
  return ReportDisplayPreferences(
    showInvoicedRevenue: saved.reportDisplayChoice('showInvoicedRevenue'),
    showMoneyCollected: saved.reportDisplayChoice('showMoneyCollected'),
    showRecordedExpenses: saved.reportDisplayChoice('showRecordedExpenses'),
    showEstimatedGrossProfit: saved.reportDisplayChoice(
      'showEstimatedGrossProfit',
    ),
    showVehicleHealth: saved.reportDisplayChoice('showVehicleHealth'),
  );
}

ExpenseDisplayPreferences readExpenseDisplayPreferences(
  BuildContext context,
  ExpenseDisplayPreferences fallback,
) {
  final saved = AppPreferencesScope.maybeOf(context)?.expenseDisplay;
  return saved == null
      ? fallback
      : ExpenseDisplayPreferences.fromPayload(saved);
}
