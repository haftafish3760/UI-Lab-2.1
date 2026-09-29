import 'quote_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import 'estimate_detail_screen.dart';
import 'estimate_models.dart';
import 'invoice_detail_screen.dart';
import 'job_workspace_screen.dart';
import 'work_job_editor.dart';
import 'work_models.dart';

/// An explicit Save leads to review. Ordinary Work navigation never calls this.
Future<void> openSavedWorkDocument(
  BuildContext context,
  WorkRecord record, {
  bool recordApproval = false,
}) async {
  final store = PrototypeOperationsScope.of(context);
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) {
        return switch (record.kind) {
          WorkRecordKind.quote => QuoteDetailScreen(recordId: record.id),
          WorkRecordKind.invoice => InvoiceDetailScreen(record: record),
          WorkRecordKind.job => JobWorkspaceScreen(
            workRecord: record,
            onWorkRecordUpdated: store.updateWorkRecord,
          ),
          WorkRecordKind.estimate => EstimateDetailScreen(
            initialRecord: record,
            openApprovalOnEntry: recordApproval,
            onUpdated: store.updateWorkRecord,
            onCreateJob: (estimate) async {
              if (!estimate.hasCurrentCustomerApproval ||
                  estimate.resolvedEstimateStage != EstimateStage.approved) {
                return;
              }
              final job = await Navigator.of(routeContext).push<WorkRecord>(
                MaterialPageRoute(
                  builder: (_) => WorkJobEditor(
                    sourceEstimate: estimate,
                    initialDay: estimate.estimateDates?.proposedServiceOn,
                  ),
                ),
              );
              // Persistent controllers commit the conversion atomically. In-memory
              // fixtures use the same editor but have no repository transaction.
              if (job != null && store.workSession == null) {
                await store.addWorkRecord(job);
                await store.updateWorkRecord(
                  estimate.withEstimateStage(
                    EstimateStage.converted,
                    DateTime.now(),
                  ),
                );
              }
            },
          ),
        };
      },
    ),
  );
}
