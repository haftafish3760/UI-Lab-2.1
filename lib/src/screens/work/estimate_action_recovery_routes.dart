import '../../data/work/estimate_approval_draft_workflow.dart';
import 'estimate_approval_screen.dart';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/estimate_action_draft_recovery.dart';
import '../../data/work/estimate_signature_draft_workflow.dart';
import '../../data/work/estimate_delivery_draft_workflow.dart';
import '../../data/work/estimate_review_draft_workflow.dart';
import '../../data/work/estimate_items_draft_workflow.dart';
import '../../data/work/models/estimate_models.dart';
import 'estimate_signature_screen.dart';
import 'estimate_delivery_screen.dart';
import 'estimate_review_reason_dialog.dart';
import 'stored_estimate_items_editor.dart';

/// Routes selected domain input; current review authority is supplied explicitly.
Future<void> openEstimateActionRecovery(
  BuildContext context,
  ResumedEstimateAction workflow, {
  required EstimatePermissions reviewPermissions,
}) async {
  final draft = switch (workflow) {
    ResumedEstimateApproval(:final controller) => controller.session,
    ResumedEstimateSignature(:final controller) => controller.session,
    ResumedEstimateDelivery(:final controller) => controller.session,
    ResumedEstimateReview(:final controller) => controller.session,
    ResumedEstimateItems(:final controller) => controller.session,
  };
  try {
    if (!context.mounted) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('Estimate recovery is unavailable.');
    final Widget editor;
    switch (workflow) {
      case ResumedEstimateApproval(:final controller):
        work.validateEstimateApprovalHandoff(
          controller,
          controller.input.base.id,
        );
        editor = EstimateApprovalScreen(
          record: controller.input.base,
          recoveredWorkflow: controller,
        );
      case ResumedEstimateSignature(:final controller):
        work.validateEstimateSignatureHandoff(
          controller,
          controller.input.base.id,
        );
        editor = EstimateSignatureScreen(
          record: controller.input.base,
          recoveredWorkflow: controller,
        );
      case ResumedEstimateDelivery(:final controller):
        work.validateEstimateDeliveryHandoff(
          controller,
          controller.input.base.id,
        );
        editor = EstimateDeliveryScreen(
          record: controller.input.base,
          recoveredWorkflow: controller,
        );
      case ResumedEstimateItems(:final controller):
        work.validateEstimateItemsHandoff(controller, controller.input.base.id);
        editor = StoredEstimateItemsEditor(
          record: controller.input.base,
          work: work,
          recoveredWorkflow: controller,
        );
      case ResumedEstimateReview(:final controller):
        work.validateEstimateReviewHandoff(
          controller,
          recordId: controller.input.base.id,
          decision: controller.input.decision,
          reviewPermissions: reviewPermissions,
        );
        await showDialog<void>(
          context: context,
          builder: (_) => EstimateReviewReasonDialog(
            record: controller.input.base,
            decision: controller.input.decision,
            permissions: reviewPermissions,
            recoveredWorkflow: controller,
          ),
        );
        return;
    }
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => editor));
  } finally {
    await draft.close();
  }
}
