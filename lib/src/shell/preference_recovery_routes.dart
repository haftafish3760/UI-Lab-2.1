import 'package:flutter/material.dart';
import '../shared/app_preferences.dart';
import '../shared/preference_draft_recovery.dart';
import '../shared/work_display_draft_workflow.dart';
import '../shared/secondary_display_draft_workflows.dart';
import '../shared/report_display_draft_workflow.dart';
import '../shared/expense_display_draft_workflow.dart';
import '../screens/work/work_settings_screen.dart';
import '../screens/work/work_record_settings_screen.dart';
import '../screens/expenses/receipt_intake_settings_screen.dart';
import '../screens/expenses/reports_settings_screen.dart';
import '../screens/expenses/expenses_settings_screen.dart';

/// Presentation dispatch accepts typed choices; identifiers and codecs remain
/// owned by the preference workflows, independently of navigation or layout.
Future<void> openPreferenceRecovery(
  BuildContext context,
  ResumedPreferenceDraft recovered,
) async {
  try {
    if (!context.mounted) return;
    final owner = AppPreferencesScope.maybeOf(context);
    if (owner == null) throw StateError('Preferences recovery unavailable.');
    final Widget editor;
    switch (recovered) {
      case ResumedWorkPreferences(:final workflow):
        owner.validateWorkDisplayHandoff(workflow);
        editor = WorkSettingsScreen(
          initial: workflow.input,
          recoveredWorkflow: workflow,
        );
      case ResumedWorkListPreferences(:final workspaceId, :final workflow):
        owner.validateWorkListDisplayHandoff(
          workflow,
          workspaceId: workspaceId,
        );
        final label = switch (workspaceId) {
          'jobs' => 'Jobs',
          'estimates' => 'Estimates',
          'invoices' => 'Invoices',
          _ => throw StateError('Unsupported Work preferences.'),
        };
        editor = WorkRecordSettingsScreen(
          workspaceId: workspaceId,
          workspaceLabel: label,
          initial: workflow.input,
          recoveredWorkflow: workflow,
        );
      case ResumedReceiptPreferences(:final workflow):
        owner.validateReceiptDisplayHandoff(workflow);
        editor = ReceiptIntakeSettingsScreen(
          initial: workflow.input,
          recoveredWorkflow: workflow,
        );
      case ResumedReportPreferences(:final workflow):
        owner.validateReportDisplayHandoff(workflow);
        editor = ReportsSettingsScreen(
          initial: workflow.input,
          recoveredWorkflow: workflow,
        );
      case ResumedExpensePreferences(:final workflow):
        owner.validateExpenseDisplayHandoff(workflow);
        editor = ExpensesSettingsScreen(
          initial: workflow.input.preferences,
          recoveredWorkflow: workflow,
        );
    }
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => editor));
  } finally {
    await recovered.close();
  }
}
