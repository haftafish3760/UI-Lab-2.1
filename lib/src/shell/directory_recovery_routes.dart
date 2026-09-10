import 'package:flutter/material.dart';
import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/directory_draft_recovery.dart';
import '../data/work/directory_draft_handoff.dart';
import '../screens/work/company_profile_editor.dart';
import '../screens/work/customer_edit_screen.dart';
import 'employee_editor_screen.dart';
import 'vehicle_editor_screen.dart';

/// Presents selected domain input without rebuilding its serialized state.
Future<void> openDirectoryRecovery(
  BuildContext context,
  ResumedDirectoryDraft workflow, {
  required DateTime selectedDay,
}) async {
  final draft = switch (workflow) {
    ResumedCompanyDraft(:final controller) => controller.session,
    ResumedCustomerDraft(:final controller) => controller.session,
    ResumedEmployeeDraft(:final controller) => controller.session,
    ResumedVehicleDraft(:final controller) => controller.session,
  };
  try {
    if (!context.mounted) return;
    final directory = PrototypeOperationsScope.of(context).directorySession;
    if (directory == null) {
      throw StateError('Directory recovery is unavailable.');
    }
    final Widget editor;
    switch (workflow) {
      case ResumedCompanyDraft(:final controller):
        directory.validateCompanyHandoff(controller);
        editor = CompanyProfileEditScreen(
          initialProfile: directory.company,
          selectedDay: selectedDay,
          recoveredWorkflow: controller,
        );
      case ResumedCustomerDraft(:final controller):
        final id = controller.recoveredInput!.existingCustomer?.id;
        directory.validateCustomerHandoff(controller, id);
        editor = CustomerEditScreen(
          initialCustomer: id == null
              ? null
              : directory.customers.firstWhere((r) => r.id == id),
          selectedDay: selectedDay,
          recoveredWorkflow: controller,
        );
      case ResumedEmployeeDraft(:final controller):
        final id = controller.expectedRecordId;
        directory.validateEmployeeHandoff(controller, id);
        editor = EmployeeEditorScreen(
          initial: id == null
              ? null
              : directory.employees.firstWhere((r) => r.id == id),
          recoveredWorkflow: controller,
        );
      case ResumedVehicleDraft(:final controller):
        final id = controller.expectedRecordId;
        directory.validateVehicleHandoff(controller, id);
        editor = VehicleEditorScreen(
          initial: id == null
              ? null
              : directory.vehicles.firstWhere((r) => r.id == id),
          recoveredWorkflow: controller,
        );
    }
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => editor));
  } finally {
    await draft.close();
  }
}
