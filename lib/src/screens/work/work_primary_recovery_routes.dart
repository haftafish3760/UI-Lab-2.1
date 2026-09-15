import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/work_primary_draft_recovery.dart';
import 'estimate_editor_screen.dart';
import 'invoice_editor_screen.dart';
import 'work_job_editor.dart';
import 'work_models.dart';
import 'work_saved_document_route.dart';

/// Presents an already-authorized workflow without rebuilding its saved input.
/// Taking ownership includes closing it when navigation fails or finishes.
Future<void> openPrimaryWorkRecovery(
  BuildContext context,
  ResumedWorkDraft workflow,
) async {
  final session = switch (workflow) {
    ResumedEstimateDraft(:final controller) => controller.session,
    ResumedInvoiceDraft(:final controller) => controller.session,
    ResumedJobDraft(:final controller) => controller.session,
  };
  try {
    if (!context.mounted) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('Work recovery is unavailable.');
    final Widget editor;
    switch (workflow) {
      case ResumedEstimateDraft(:final controller):
        final input = controller.recoveredInput;
        if (input == null) throw StateError('Estimate input is unavailable.');
        editor = EstimateEditorScreen(
          initialDay: input.createdOn,
          initialRecord: input.baseRecord,
          createdByEmployeeId: input.creatorId,
          recoveredWorkflow: controller,
        );
      case ResumedInvoiceDraft(:final controller):
        final input = controller.recoveredInput;
        if (input == null) throw StateError('Invoice input is unavailable.');
        final existing = input.existingRecordId == null
            ? null
            : work.records
                  .where((record) => record.id == input.existingRecordId)
                  .firstOrNull;
        if (input.existingRecordId != null && existing == null) {
          throw StateError('Invoice record is unavailable.');
        }
        editor = InvoiceEditorScreen(
          initialDay: input.createdOn,
          initialRecord: existing,
          createdByEmployeeId: input.creatorId,
          recoveredWorkflow: controller,
        );
      case ResumedJobDraft(:final controller):
        final input = controller.recoveredInput;
        if (input == null) throw StateError('Job input is unavailable.');
        editor = WorkJobEditor(
          initialDay: input.scheduledStart,
          sourceEstimate: input.sourceEstimate,
          recoveredWorkflow: controller,
        );
    }
    final saved = await Navigator.of(
      context,
    ).push<WorkRecord>(MaterialPageRoute(builder: (_) => editor));
    if (saved != null && context.mounted) {
      await openSavedWorkDocument(context, saved);
    }
  } finally {
    await session.close();
  }
}
