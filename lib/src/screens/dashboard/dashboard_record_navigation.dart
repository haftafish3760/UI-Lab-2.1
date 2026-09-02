import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import '../expenses/expense_detail_screen.dart';
import '../work/estimate_detail_screen.dart';
import '../work/estimate_models.dart';
import '../work/invoice_detail_screen.dart';
import '../work/invoice_permissions.dart';
import '../work/job_workspace_screen.dart';
import '../work/work_models.dart';
import 'dashboard_models.dart';
import 'day_entry_details_screen.dart';

/// Routes Dashboard projections back to the record-owning module.
///
/// A missing source never opens a fabricated job. Local notes and telemetry
/// entries without an owning module use the Dashboard detail screen.
class DashboardRecordNavigation {
  const DashboardRecordNavigation._();

  static Future<void> openPlan(
    BuildContext context,
    PlanItem item, {
    required ValueChanged<WorkRecord> onCreateJob,
  }) async {
    final store = PrototypeOperationsScope.of(context);
    final sourceId = item.sourceRecordId ?? item.id;
    final record = store.workRecords
        .where((candidate) => candidate.id == sourceId)
        .firstOrNull;
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This schedule item is not linked to a work record.'),
        ),
      );
      return;
    }
    switch (record.kind) {
      case WorkRecordKind.job:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JobWorkspaceScreen(
              workRecord: record,
              onWorkRecordUpdated: store.updateWorkRecord,
            ),
          ),
        );
      case WorkRecordKind.estimate:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: record,
              onUpdated: store.updateWorkRecord,
              onCreateJob: onCreateJob,
              permissions:
                  OperationalScope.of(context).view == AppViewMode.admin
                  ? const EstimatePermissions.development()
                  : const EstimatePermissions.technicianDevelopment(),
            ),
          ),
        );
      case WorkRecordKind.invoice:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InvoiceDetailScreen(
              record: record,
              permissions: invoicePermissionsForView(
                OperationalScope.of(context).view,
              ),
            ),
          ),
        );
    }
  }

  static Future<void> openEntry(
    BuildContext context,
    DayEntry entry, {
    required DateTime date,
    required bool showOdometer,
    required ValueChanged<WorkRecord> onCreateJob,
  }) async {
    final store = PrototypeOperationsScope.of(context);
    final sourceId = entry.sourceRecordId;
    if (sourceId != null && entry.kind == DayEntryKind.expense) {
      if (store.expenses.any((candidate) => candidate.id == sourceId)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExpenseDetailScreen(expenseId: sourceId),
          ),
        );
        return;
      }
    }
    final record = sourceId == null
        ? null
        : store.workRecords
              .where((candidate) => candidate.id == sourceId)
              .firstOrNull;
    if (record != null) {
      await openPlan(
        context,
        PlanItem(
          entry.time,
          record.title,
          '${record.client} · ${record.number}',
          entry.kind.icon,
          entry.color,
          id: entry.id,
          sourceRecordId: record.id,
          kind: record.kind == WorkRecordKind.job
              ? PlanItemKind.jobStop
              : PlanItemKind.operationalTask,
        ),
        onCreateJob: onCreateJob,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayEntryDetailsScreen(
          entry: entry,
          date: date,
          showOdometer: showOdometer,
        ),
      ),
    );
  }
}
