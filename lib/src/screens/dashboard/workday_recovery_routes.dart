import 'package:flutter/material.dart';
import '../../data/workday/workday_draft_recovery.dart';
import '../../data/workday/workday_persistence_session.dart';
import '../../data/workday/start_workday_draft_workflow.dart';
import '../../data/workday/end_workday_draft_workflow.dart';
import 'start_workday_screen.dart';
import 'dashboard_end_workday_dialog.dart';

/// Navigation receives typed workday input; no dashboard widget identity is saved.
Future<void> openWorkdayRecovery(
  BuildContext context,
  ResumedWorkdayDraft workflow,
) async {
  final draft = switch (workflow) {
    ResumedWorkdayStart(:final controller) => controller.session,
    ResumedWorkdayEnd(:final controller) => controller.session,
  };
  try {
    if (!context.mounted) return;
    final work = WorkdayPersistenceScope.maybeOf(context);
    if (work == null) throw StateError('Workday recovery is unavailable.');
    switch (workflow) {
      case ResumedWorkdayStart(:final controller):
        work.validateStartWorkdayHandoff(controller);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => StartWorkdayScreen(recoveredWorkflow: controller),
          ),
        );
      case ResumedWorkdayEnd(:final controller):
        work.validateEndWorkdayHandoff(controller, controller.input.workdayId);
        final current = work.records.firstWhere(
          (s) => s.record.id == controller.input.workdayId,
        );
        final minimum = current.record.currentOdometerTenths;
        await showDialog<void>(
          context: context,
          builder: (_) => EndWorkdayDialog(
            initialOdometerTenths: minimum,
            minimumOdometerTenths: minimum,
            session: work,
            workday: current,
            recoveredWorkflow: controller,
          ),
        );
    }
  } finally {
    await draft.close();
  }
}
