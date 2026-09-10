import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/job_action_draft_recovery.dart';
import '../../data/work/job_notes_draft_workflow.dart';
import '../../data/work/job_schedule_draft_workflow.dart';
import '../../data/work/job_assignment_draft_workflow.dart';
import 'job_notes_editor_dialog.dart';
import 'job_schedule_editor_sheet.dart';
import 'job_assignment_editor_sheet.dart';

/// Material editing has its own item-workspace route and is not handled here.
bool supportsJobDetailsRecovery(ResumedJobAction workflow) =>
    workflow is ResumedJobNotes ||
    workflow is ResumedJobSchedule ||
    workflow is ResumedJobAssignment;

/// Presentation composition only; selected input remains owned by its workflow.
Future<void> openJobDetailsRecovery(
  BuildContext context,
  ResumedJobAction workflow,
) async {
  final session = switch (workflow) {
    ResumedJobNotes(:final controller) => controller.session,
    ResumedJobSchedule(:final controller) => controller.session,
    ResumedJobAssignment(:final controller) => controller.session,
    ResumedJobMaterials(:final controller) => controller.session,
  };
  try {
    if (!context.mounted) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('Job recovery is unavailable.');
    switch (workflow) {
      case ResumedJobNotes(:final controller):
        work.validateJobNotesHandoff(controller, controller.input.base.id);
        await showDialog<void>(
          context: context,
          builder: (_) => JobNotesEditorDialog(
            record: controller.input.base,
            work: work,
            recoveredWorkflow: controller,
          ),
        );
      case ResumedJobSchedule(:final controller):
        work.validateJobScheduleHandoff(controller, controller.input.base.id);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => JobScheduleEditorSheet(
            record: controller.input.base,
            work: work,
            recoveredWorkflow: controller,
          ),
        );
      case ResumedJobAssignment(:final controller):
        work.validateJobAssignmentHandoff(controller, controller.input.base.id);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => JobAssignmentEditorSheet(
            record: controller.input.base,
            work: work,
            recoveredWorkflow: controller,
          ),
        );
      case ResumedJobMaterials():
        throw ArgumentError('Materials recovery requires its item workspace.');
    }
  } finally {
    await session.close();
  }
}
