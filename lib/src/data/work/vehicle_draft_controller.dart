import '../workday/odometer_input.dart';
import 'vehicle_directory_profile.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';

/// Raw vehicle workflow values, independent of visual field arrangement.
/// Persisted version-one keys are retained for backward-compatible recovery.
class VehicleDraftInput {
  const VehicleDraftInput({
    required this.vehicleId,
    required this.baseRevision,
    required this.odometerRevision,
    required this.active,
    required this.name,
    required this.model,
    required this.odometer,
    required this.assignment,
  });

  final String vehicleId;
  final int baseRevision;
  final int odometerRevision;
  final bool active;
  final String name;
  final String model;
  final String odometer;
  final String assignment;

  VehicleDirectoryProfile confirmedProfile() {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter the vehicle name.');
    }
    if (baseRevision < 0 || odometerRevision < 0) {
      throw const FormatException('Invalid vehicle revision.');
    }
    return VehicleDirectoryProfile.fromJson(
      VehicleDirectoryProfile(
        id: vehicleId,
        name: name.trim(),
        yearMakeModel: model.trim(),
        assignment: assignment.trim(),
        active: active,
      ).toJson(),
    );
  }

  int? confirmedOdometerTenths() {
    final text = odometer.trim();
    if (text.isEmpty) return null;
    return parseExactOdometerMiles(text);
  }

  Map<String, Object?> toPayload() => {
    'vehicleId': vehicleId,
    'baseRevision': baseRevision,
    'odometerRevision': odometerRevision,
    'active': active,
    'name': name,
    'model': model,
    'odometer': odometer,
    'assignment': assignment,
  };

  factory VehicleDraftInput.fromPayload(Map<String, Object?> input) =>
      VehicleDraftInput(
        vehicleId: input['vehicleId'] as String,
        baseRevision: input['baseRevision'] as int,
        odometerRevision: input['odometerRevision'] as int,
        active: input['active'] as bool,
        name: input['name'] as String,
        model: input['model'] as String,
        odometer: input['odometer'] as String,
        assignment: input['assignment'] as String,
      );
}

class VehicleDraftController
    extends DraftWorkflowController<VehicleDraftInput> {
  VehicleDraftController(
    DraftAutosaveSession session, {
    this.expectedRecordId,
    Future<bool> Function(
      VehicleDirectoryProfile,
      VehicleDraftInput,
      LocalDraftCheckpoint,
      int? odometerTenths,
    )?
    confirm,
    // Keep the transaction callback private; presentations use guarded confirm().
    // ignore: prefer_initializing_formals
  }) : _confirm = confirm,
       super(
         session,
         (input) => input.toPayload(),
         VehicleDraftInput.fromPayload,
       );

  final Future<bool> Function(
    VehicleDirectoryProfile,
    VehicleDraftInput,
    LocalDraftCheckpoint,
    int? odometerTenths,
  )?
  _confirm;
  final String? expectedRecordId;

  Future<VehicleDirectoryProfile?> confirm() async {
    final commit = _confirm;
    if (commit == null) {
      throw StateError('This workflow has no confirmation service.');
    }
    VehicleDirectoryProfile? confirmed;
    final saved = await session.confirm((checkpoint) async {
      final input = recoveredInput;
      if (input == null) throw StateError('There is no saved profile input.');
      final profile = input.confirmedProfile();
      final saved = await commit(
        profile,
        input,
        checkpoint,
        input.confirmedOdometerTenths(),
      );
      if (saved) confirmed = profile;
      return saved;
    });
    return saved ? confirmed : null;
  }

  @override
  VehicleDraftInput? get recoveredInput {
    final input = super.recoveredInput;
    if (input == null) return null;
    if (input.vehicleId.isEmpty ||
        input.baseRevision < 0 ||
        (expectedRecordId != null && input.vehicleId != expectedRecordId) ||
        input.odometerRevision < 0) {
      throw const FormatException('Invalid vehicle recovery identity.');
    }
    return input;
  }
}
