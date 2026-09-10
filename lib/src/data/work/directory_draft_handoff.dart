import '../storage/draft_autosave_session.dart';
import 'directory_persistence_session.dart';
import 'company_draft_controller.dart';
import 'customer_draft_controller.dart';
import 'employee_draft_controller.dart';
import 'vehicle_draft_controller.dart';

/// Rechecks selected editor input against the current directory session.
/// Visual layout and navigation identities are deliberately absent.
extension DirectoryDraftHandoff on DirectoryPersistenceSession {
  void _checkHandoff(DraftAutosaveSession draft, String domain, bool allowed) {
    if (!allowed ||
        draft.organizationId != permissions.organizationId ||
        draft.ownerId != permissions.actorEmployeeId ||
        draft.domain != domain ||
        draft.input.isEmpty) {
      throw StateError('Selected directory input is unavailable.');
    }
  }

  void validateCompanyHandoff(CompanyDraftController workflow) {
    _checkHandoff(
      workflow.session,
      'directory/company-editor',
      permissions.canViewCompany && permissions.canManageCompany,
    );
  }

  void validateCustomerHandoff(CustomerDraftController workflow, String? id) {
    _checkHandoff(
      workflow.session,
      'directory/customer-editor',
      permissions.canViewCustomers && permissions.canManageCustomers,
    );
    if (workflow.recoveredInput!.existingCustomer?.id != id ||
        (id != null && !customers.any((record) => record.id == id))) {
      throw StateError('Selected client input belongs to another record.');
    }
  }

  void validateEmployeeHandoff(EmployeeDraftController workflow, String? id) {
    _checkHandoff(
      workflow.session,
      'directory/employee-editor',
      permissions.canViewEmployees && permissions.canManageEmployees,
    );
    if (workflow.expectedRecordId != id ||
        (id != null && !employees.any((record) => record.id == id))) {
      throw StateError('Selected employee input belongs to another record.');
    }
  }

  void validateVehicleHandoff(VehicleDraftController workflow, String? id) {
    _checkHandoff(
      workflow.session,
      'directory/vehicle-editor',
      permissions.canViewVehicles && permissions.canManageVehicles,
    );
    if (workflow.expectedRecordId != id ||
        (id != null && !vehicles.any((record) => record.id == id))) {
      throw StateError('Selected vehicle input belongs to another record.');
    }
  }
}
