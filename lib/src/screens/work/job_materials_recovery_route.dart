import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/job_materials_draft_workflow.dart';
import '../../data/work/job_material_permissions.dart';
import 'job_workspace_screen.dart';

/// Reuses the owning job's material confirmation and stock checks. Merely
/// reopening a draft does not apply either confirmed materials or stock changes.
Future<void> openJobMaterialsRecovery(
  BuildContext context,
  JobMaterialsDraftController workflow, {
  required JobWorkspacePermissions permissions,
}) async {
  try {
    if (!context.mounted) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) throw StateError('Job recovery unavailable.');
    final id = workflow.input.base.id;
    work.validateJobMaterialsHandoff(
      workflow,
      id,
      materialPermissions: permissions,
    );
    final current = work.records.firstWhere((record) => record.id == id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JobWorkspaceScreen(
          workRecord: current,
          permissions: permissions,
          recoveredMaterialsWorkflow: workflow,
        ),
      ),
    );
  } finally {
    await workflow.session.close();
  }
}
