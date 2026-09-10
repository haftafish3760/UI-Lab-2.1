import 'package:flutter/material.dart';
import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/job_material_permissions.dart';
import '../data/work/models/estimate_models.dart';
import '../shared/application_recovery_scope.dart';
import '../shared/operational_scope.dart';
import '../shared/app_view_mode.dart';
import '../screens/expenses/expense_permissions.dart';
import 'application_recovery_routes.dart';
import 'saved_work_recovery_screen.dart';

Future<void> openSavedWorkRecovery(BuildContext context) async {
  final hub = ApplicationRecoveryScope.maybeOf(context);
  if (hub == null) throw StateError('Durable recovery is unavailable.');
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SavedWorkRecoveryScreen(
        hub: hub,
        onResume: (context, workflow) {
          final view = OperationalScope.of(context).view;
          final directory = PrototypeOperationsScope.of(
            context,
          ).directorySession;
          // Same explicit prototype capabilities as existing application recovery
          // composition. These are not production account authentication.
          return openApplicationRecovery(
            context,
            workflow,
            expensePermissions: expensePermissionsForView(view),
            estimatePermissions: view == AppViewMode.admin
                ? const EstimatePermissions.development()
                : const EstimatePermissions.technicianDevelopment(),
            materialPermissions: const JobWorkspacePermissions.development(),
            selectedDay: DateTime.now(),
            employeeLabel: (id) =>
                directory?.employees
                    .where((e) => e.id == id)
                    .firstOrNull
                    ?.name ??
                'Employee',
          );
        },
      ),
    ),
  );
}
