import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import 'company_draft_controller.dart';
import 'directory_persistence_session.dart';
import 'employee_draft_controller.dart';
import 'vehicle_draft_controller.dart';

/// Stable workflow identities and recovery validation belong to the directory,
/// not a route, widget key, layout or navigation stack.
extension DirectoryDraftWorkflows on DirectoryPersistenceSession {
  Future<CompanyDraftController> openCompanyDraft({
    DraftRecoverySelection? recoverySelection,
  }) {
    if (!permissions.canViewCompany || !permissions.canManageCompany) {
      throw StateError('Company editing is unavailable.');
    }
    return _openProfileDraft(
      recoverySelection: recoverySelection,
      domain: 'directory/company-editor',
      draftId: 'company-${permissions.actorEmployeeId}',
      create: (session) => CompanyDraftController(
        session,
        confirm: (profile, input, checkpoint) => saveCompany(
          profile,
          expectedRevision: input.baseRevision,
          draftCheckpoint: checkpoint,
        ),
      ),
    );
  }

  Future<EmployeeDraftController> openEmployeeDraft({
    String? employeeId,
    DraftRecoverySelection? recoverySelection,
  }) {
    if (!permissions.canViewEmployees || !permissions.canManageEmployees) {
      throw StateError('Employee editing is unavailable.');
    }
    if (employeeId != null && !employees.any((e) => e.id == employeeId)) {
      throw StateError('Employee record is unavailable.');
    }
    return _openProfileDraft(
      recoverySelection: recoverySelection,
      domain: 'directory/employee-editor',
      draftId: _profileDraftId(employeeId),
      create: (session) => EmployeeDraftController(
        session,
        expectedRecordId: employeeId,
        confirm: (profile, input, checkpoint) => saveEmployee(
          profile,
          expectedRevision: input.baseRevision,
          draftCheckpoint: checkpoint,
        ),
      ),
    );
  }

  Future<VehicleDraftController> openVehicleDraft({
    String? vehicleId,
    DraftRecoverySelection? recoverySelection,
  }) {
    if (!permissions.canViewVehicles || !permissions.canManageVehicles) {
      throw StateError('Vehicle editing is unavailable.');
    }
    if (vehicleId != null && !vehicles.any((v) => v.id == vehicleId)) {
      throw StateError('Vehicle record is unavailable.');
    }
    return _openProfileDraft(
      recoverySelection: recoverySelection,
      domain: 'directory/vehicle-editor',
      draftId: _profileDraftId(vehicleId),
      create: (session) => VehicleDraftController(
        session,
        expectedRecordId: vehicleId,
        confirm: (profile, input, checkpoint, reading) => saveVehicle(
          profile,
          expectedRevision: input.baseRevision,
          odometerTenths: reading,
          expectedOdometerRevision: reading == null
              ? null
              : input.odometerRevision,
          draftCheckpoint: checkpoint,
        ),
      ),
    );
  }

  String _profileDraftId(String? recordId) => recordId == null
      ? 'new-${permissions.actorEmployeeId}'
      : 'edit-${permissions.actorEmployeeId}-$recordId';

  Future<C> _openProfileDraft<T, C extends DraftWorkflowController<T>>({
    required String domain,
    required String draftId,
    DraftRecoverySelection? recoverySelection,
    required C Function(DraftAutosaveSession) create,
  }) async {
    final session = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: domain,
      draftId: recoverySelection?.draftId ?? draftId,
      ownerId: permissions.actorEmployeeId,
    );
    try {
      await session.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: session.domain,
        openedDraftId: session.draftId,
        openedRevision: session.savedRevision,
        hasInput: session.input.isNotEmpty,
      );
      final controller = create(session);
      // Validate before exposing the session to any presentation. Failure keeps
      // the original row intact and releases the unopened workflow resources.
      controller.recoveredInput;
      return controller;
    } on Object {
      await session.close().catchError((Object _) {});
      rethrow;
    }
  }
}
