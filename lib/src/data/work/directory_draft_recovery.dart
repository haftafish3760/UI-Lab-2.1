import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'company_draft_controller.dart';
import 'customer_draft_controller.dart';
import 'customer_draft_workflow.dart';
import 'directory_draft_workflows.dart';
import 'directory_persistence_session.dart';
import 'directory_recovery_revision.dart';
import 'employee_draft_controller.dart';
import 'vehicle_draft_controller.dart';

sealed class ResumedDirectoryDraft {
  const ResumedDirectoryDraft();
}

class ResumedCompanyDraft extends ResumedDirectoryDraft {
  const ResumedCompanyDraft(this.controller);
  final CompanyDraftController controller;
}

class ResumedCustomerDraft extends ResumedDirectoryDraft {
  const ResumedCustomerDraft(this.controller);
  final CustomerDraftController controller;
}

class ResumedEmployeeDraft extends ResumedDirectoryDraft {
  const ResumedEmployeeDraft(this.controller);
  final EmployeeDraftController controller;
}

class ResumedVehicleDraft extends ResumedDirectoryDraft {
  const ResumedVehicleDraft(this.controller);
  final VehicleDraftController controller;
}

/// Directory recovery exposes domain controllers, never routes or database rows.
/// Current record/mileage revisions come from a fresh read, not the editor cache.
class DirectoryDraftRecovery {
  DirectoryDraftRecovery(this._directory) {
    _catalog = DraftRecoveryCatalog(
      repository: _directory.drafts,
      organizationId: _directory.permissions.organizationId,
      ownerId: _directory.permissions.actorEmployeeId,
      handlers: handlers,
    );
  }
  final DirectoryPersistenceSession _directory;
  late final DraftRecoveryCatalog _catalog;
  static const _labels = {
    'directory/company-editor': 'Company information',
    'directory/customer-editor': 'Client information',
    'directory/employee-editor': 'Employee information',
    'directory/vehicle-editor': 'Vehicle information',
  };
  bool _canList(String domain) {
    final p = _directory.permissions;
    return switch (domain) {
      'directory/company-editor' => p.canViewCompany && p.canManageCompany,
      'directory/customer-editor' => p.canViewCustomers && p.canManageCustomers,
      'directory/employee-editor' => p.canViewEmployees && p.canManageEmployees,
      'directory/vehicle-editor' => p.canViewVehicles && p.canManageVehicles,
      _ => false,
    };
  }

  Iterable<DraftRecoveryHandler> get handlers => _labels.entries.map(
    (entry) => DraftRecoveryHandler(
      domain: entry.key,
      workflowLabel: entry.value,
      canList: () => _canList(entry.key),
      inspect: (raw) => _inspect(entry.key, raw),
      canDiscard: (_) async => _canList(entry.key),
    ),
  );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  ({String id, int revision, String title, int? odometerRevision}) _identity(
    String domain,
    Map<String, Object?> raw,
  ) {
    switch (domain) {
      case 'directory/company-editor':
        final input = CompanyDraftInput.fromPayload(raw);
        return (
          id: 'company',
          revision: input.baseRevision,
          title: input.name,
          odometerRevision: null,
        );
      case 'directory/customer-editor':
        final input = CustomerDraftInput.fromPayload(raw);
        if ((input.existingCustomer == null) != (input.baseRevision == 0) ||
            (input.existingCustomer != null &&
                input.existingCustomer!.id != input.customerId)) {
          throw const FormatException('Invalid client recovery identity.');
        }
        return (
          id: input.customerId,
          revision: input.baseRevision,
          title: input.name,
          odometerRevision: null,
        );
      case 'directory/employee-editor':
        final input = EmployeeDraftInput.fromPayload(raw);
        if (!const {
          'Helper',
          'Technician',
          'Supervisor',
          'Office',
        }.contains(input.role)) {
          throw const FormatException('Invalid employee role.');
        }
        return (
          id: input.employeeId,
          revision: input.baseRevision,
          title: input.name,
          odometerRevision: null,
        );
      case 'directory/vehicle-editor':
        final input = VehicleDraftInput.fromPayload(raw);
        if (input.odometerRevision < 0) {
          throw const FormatException('Invalid mileage revision.');
        }
        return (
          id: input.vehicleId,
          revision: input.baseRevision,
          title: input.name,
          odometerRevision: input.odometer.trim().isEmpty
              ? null
              : input.odometerRevision,
        );
      default:
        throw StateError('Unknown directory workflow.');
    }
  }

  Future<DraftRecoveryPreview?> _inspect(
    String domain,
    Map<String, Object?> raw,
  ) async {
    late ({String id, int revision, String title, int? odometerRevision})
    identity;
    try {
      identity = _identity(domain, raw);
      if (identity.id.trim().isEmpty || identity.revision < 0) {
        throw const FormatException('Invalid profile identity.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved directory input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final kind = switch (domain) {
      'directory/company-editor' => DirectoryProfileKind.company,
      'directory/customer-editor' => DirectoryProfileKind.customer,
      'directory/employee-editor' => DirectoryProfileKind.employee,
      'directory/vehicle-editor' => DirectoryProfileKind.vehicle,
      _ => throw StateError('Unknown directory workflow.'),
    };
    final current = await _directory.recoveryRevisionFor(kind, identity.id);
    final revision = current.profileRevision;
    final availability = revision == 0 && identity.revision > 0
        ? DraftRecoveryAvailability.parentUnavailable
        : revision != identity.revision ||
              (identity.odometerRevision != null &&
                  (current.odometerRevision ?? 0) != identity.odometerRevision)
        ? DraftRecoveryAvailability.conflict
        : DraftRecoveryAvailability.recoverable;
    return DraftRecoveryPreview(
      title: availability == DraftRecoveryAvailability.parentUnavailable
          ? 'Saved input — original profile unavailable'
          : identity.title.trim().isEmpty
          ? 'Unnamed profile'
          : identity.title,
      availability: availability,
      recordId: identity.id,
    );
  }

  Future<ResumedDirectoryDraft> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError(
        'Saved directory input requires review before resuming.',
      );
    }
    final saved = await _directory.drafts.find(
      organizationId: _directory.permissions.organizationId,
      ownerId: _directory.permissions.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null || saved.revision != current.revision) {
      throw const LocalRecordConflict(
        'Selected input changed; refresh recovery.',
      );
    }
    final identity = _identity(current.domain, _directory.drafts.decode(saved));
    final selected = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    final existingId = identity.revision == 0 ? null : identity.id;
    switch (current.domain) {
      case 'directory/company-editor':
        return ResumedCompanyDraft(
          await _directory.openCompanyDraft(recoverySelection: selected),
        );
      case 'directory/customer-editor':
        return ResumedCustomerDraft(
          await _directory.openCustomerDraft(
            existingCustomerId: existingId,
            recoverySelection: selected,
          ),
        );
      case 'directory/employee-editor':
        return ResumedEmployeeDraft(
          await _directory.openEmployeeDraft(
            employeeId: existingId,
            recoverySelection: selected,
          ),
        );
      case 'directory/vehicle-editor':
        return ResumedVehicleDraft(
          await _directory.openVehicleDraft(
            vehicleId: existingId,
            recoverySelection: selected,
          ),
        );
      default:
        throw StateError('Unknown directory workflow.');
    }
  }
}
