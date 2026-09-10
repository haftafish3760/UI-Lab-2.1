import 'employee_directory_profile.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';

/// Raw employee workflow values, independent of visual field arrangement.
/// Persisted version-one keys are retained for backward-compatible recovery.
class EmployeeDraftInput {
  const EmployeeDraftInput({
    required this.employeeId,
    required this.baseRevision,
    required this.role,
    required this.active,
    required this.canSeeEstimates,
    required this.canCreateEstimates,
    required this.canApproveEstimates,
    required this.canRecordExpenses,
    required this.canViewCompanyReports,
    required this.name,
    required this.phone,
    required this.emergency,
    required this.pay,
  });

  final String employeeId;
  final int baseRevision;
  final String role;
  final bool active;
  final bool canSeeEstimates;
  final bool canCreateEstimates;
  final bool canApproveEstimates;
  final bool canRecordExpenses;
  final bool canViewCompanyReports;
  final String name;
  final String phone;
  final String emergency;
  final String pay;

  EmployeeDirectoryProfile confirmedProfile() {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter the employee name.');
    }
    if (baseRevision < 0) {
      throw const FormatException('Invalid employee revision.');
    }
    return EmployeeDirectoryProfile.fromJson(
      EmployeeDirectoryProfile(
        id: employeeId,
        name: name.trim(),
        phone: phone.trim(),
        emergencyContact: emergency.trim(),
        role: role,
        pay: pay.trim(),
        status: active ? 'Available' : 'Former employee',
        active: active,
        canSeeEstimates: canSeeEstimates,
        canCreateEstimates: canCreateEstimates,
        canApproveEstimates: canApproveEstimates,
        canRecordExpenses: canRecordExpenses,
        canViewCompanyReports: canViewCompanyReports,
      ).toJson(),
    );
  }

  Map<String, Object?> toPayload() => {
    'employeeId': employeeId,
    'baseRevision': baseRevision,
    'role': role,
    'active': active,
    'canSeeEstimates': canSeeEstimates,
    'canCreateEstimates': canCreateEstimates,
    'canApproveEstimates': canApproveEstimates,
    'canRecordExpenses': canRecordExpenses,
    'canViewCompanyReports': canViewCompanyReports,
    'name': name,
    'phone': phone,
    'emergency': emergency,
    'pay': pay,
  };

  factory EmployeeDraftInput.fromPayload(Map<String, Object?> input) =>
      EmployeeDraftInput(
        employeeId: input['employeeId'] as String,
        baseRevision: input['baseRevision'] as int,
        role: input['role'] as String,
        active: input['active'] as bool,
        canSeeEstimates: input['canSeeEstimates'] as bool,
        canCreateEstimates: input['canCreateEstimates'] as bool,
        canApproveEstimates: input['canApproveEstimates'] as bool,
        canRecordExpenses: input['canRecordExpenses'] as bool,
        canViewCompanyReports: input['canViewCompanyReports'] as bool,
        name: input['name'] as String,
        phone: input['phone'] as String,
        emergency: input['emergency'] as String,
        pay: input['pay'] as String,
      );
}

class EmployeeDraftController
    extends DraftWorkflowController<EmployeeDraftInput> {
  EmployeeDraftController(
    DraftAutosaveSession session, {
    this.expectedRecordId,
    Future<bool> Function(
      EmployeeDirectoryProfile,
      EmployeeDraftInput,
      LocalDraftCheckpoint,
    )?
    confirm,
    // Keep the transaction callback private; presentations use guarded confirm().
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         EmployeeDraftInput.fromPayload,
       );

  final Future<bool> Function(
    EmployeeDirectoryProfile,
    EmployeeDraftInput,
    LocalDraftCheckpoint,
  )?
  _confirm;
  final String? expectedRecordId;

  Future<EmployeeDirectoryProfile?> confirm() async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('This workflow has no confirmation service.');
    }
    EmployeeDirectoryProfile? confirmed;
    final saved = await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('There is no saved profile input.');
      final profile = input.confirmedProfile();
      final saved = await commit(profile, input, checkpoint);
      if (saved) confirmed = profile;
      return saved;
    });
    return saved ? confirmed : null;
  }

  @override
  EmployeeDraftInput? get recoveredInput {
    final input = super.recoveredInput;
    if (input == null) return null;
    if (input.employeeId.isEmpty ||
        input.baseRevision < 0 ||
        (expectedRecordId != null && input.employeeId != expectedRecordId) ||
        !const [
          'Helper',
          'Technician',
          'Supervisor',
          'Office',
        ].contains(input.role)) {
      throw const FormatException('Invalid employee recovery identity.');
    }
    return input;
  }
}
