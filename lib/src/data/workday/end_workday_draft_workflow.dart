import 'odometer_input.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'stored_workday_record.dart';
import 'workday_persistence_session.dart';

class EndWorkdayInputValidation implements Exception {
  const EndWorkdayInputValidation();
  String get message =>
      'Enter an ending odometer at or above the last confirmed reading.';
}

class EndWorkdayInput {
  const EndWorkdayInput({
    required this.workdayId,
    required this.employeeId,
    required this.vehicleId,
    required this.odometer,
    required this.baseRevision,
    required this.baseOdometerRevision,
    this.confirmedAt,
  });
  final String workdayId;
  final String employeeId;
  final String vehicleId;
  final String odometer;
  final int baseRevision;
  final int baseOdometerRevision;
  final DateTime? confirmedAt;
  EndWorkdayInput withChanges({String? odometer, DateTime? confirmedAt}) =>
      EndWorkdayInput(
        workdayId: workdayId,
        employeeId: employeeId,
        vehicleId: vehicleId,
        odometer: odometer ?? this.odometer,
        baseRevision: baseRevision,
        baseOdometerRevision: baseOdometerRevision,
        confirmedAt: confirmedAt ?? this.confirmedAt,
      );
  Map<String, Object?> toPayload() => {
    'workdayId': workdayId,
    'employeeId': employeeId,
    'vehicleId': vehicleId,
    'odometer': odometer,
    'baseRevision': baseRevision,
    'baseOdometerRevision': baseOdometerRevision,
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory EndWorkdayInput.fromPayload(Map<String, Object?> input) =>
      EndWorkdayInput(
        workdayId: input['workdayId'] as String,
        employeeId: input['employeeId'] as String,
        vehicleId: input['vehicleId'] as String,
        odometer: input['odometer'] as String,
        baseRevision: input['baseRevision'] as int,
        baseOdometerRevision: input['baseOdometerRevision'] as int,
        confirmedAt: input['confirmedAt'] == null
            ? null
            : DateTime.parse(input['confirmedAt'] as String),
      );
}

class EndWorkdayDraftController
    extends DraftWorkflowController<EndWorkdayInput> {
  EndWorkdayDraftController._(DraftAutosaveSession session, this._commit)
    : super(session, (input) => input.toPayload(), EndWorkdayInput.fromPayload);
  final Future<WorkdayCommandResult> Function(
    EndWorkdayInput,
    int,
    LocalDraftCheckpoint,
  )
  _commit;
  EndWorkdayInput get input => recoveredInput!;
  void update(String odometer) =>
      updateInput(input.withChanges(odometer: odometer));
  Future<WorkdayCommandResult> confirm() async {
    final reading = tryParseWorkdayOdometerMiles(input.odometer);
    if (reading == null) {
      throw const EndWorkdayInputValidation();
    }
    if (input.confirmedAt == null) {
      updateInput(input.withChanges(confirmedAt: DateTime.now().toUtc()));
    }
    late WorkdayCommandResult result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, reading, checkpoint);
      return result.committed;
    });
    return result;
  }
}

extension EndWorkdayDraftWorkflow on WorkdayPersistenceSession {
  void validateEndWorkdayHandoff(
    EndWorkdayDraftController controller,
    String workdayId,
  ) {
    final current = records.where((s) => s.record.id == workdayId).firstOrNull;
    if (!isReady ||
        !access.canManage ||
        controller.session.organizationId != access.organizationId ||
        controller.session.ownerId != access.actorEmployeeId ||
        controller.session.domain != 'workday/end' ||
        controller.input.workdayId != workdayId ||
        current == null ||
        current.record.status == StoredWorkdayStatus.ended ||
        !access.employeeIds.contains(current.record.employeeId) ||
        !access.vehicleIds.contains(current.record.vehicleId) ||
        current.record.employeeId != controller.input.employeeId ||
        current.record.vehicleId != controller.input.vehicleId) {
      throw StateError('Selected ending input belongs to another workflow.');
    }
  }

  Future<EndWorkdayDraftController> openEndDraft({
    required String workdayId,
    required String initialOdometer,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final snapshot = records.where((s) => s.record.id == workdayId).firstOrNull;
    if (snapshot == null ||
        !isReady ||
        !access.canManage ||
        snapshot.record.organizationId != access.organizationId ||
        !access.employeeIds.contains(snapshot.record.employeeId) ||
        !access.vehicleIds.contains(snapshot.record.vehicleId)) {
      throw StateError('Workday unavailable.');
    }
    final record = snapshot.record;
    final odometer = odometerFor(record.vehicleId)!;
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: access.organizationId,
      ownerId: access.actorEmployeeId,
      domain: 'workday/end',
      draftId:
          recoverySelection?.draftId ??
          'end-${access.actorEmployeeId}-${record.id}',
    );
    void validate(EndWorkdayInput input) {
      if (input.workdayId != record.id ||
          input.employeeId != record.employeeId ||
          input.vehicleId != record.vehicleId ||
          input.baseRevision < 1 ||
          input.baseOdometerRevision < 0 ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Ending input identity is inconsistent.');
      }
    }

    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      final controller = EndWorkdayDraftController._(draft, (
        input,
        reading,
        checkpoint,
      ) {
        validate(input);
        if (reading < record.currentOdometerTenths ||
            reading < odometer.readingTenths) {
          throw const EndWorkdayInputValidation();
        }
        return change(
          id: record.id,
          expectedRevision: input.baseRevision,
          at: input.confirmedAt!,
          status: StoredWorkdayStatus.ended,
          endingOdometerTenths: reading,
          expectedOdometerRevision: input.baseOdometerRevision,
          draft: checkpoint,
        );
      });
      final recovered = controller.recoveredInput;
      if (recovered == null) {
        controller.updateInput(
          EndWorkdayInput(
            workdayId: record.id,
            employeeId: record.employeeId,
            vehicleId: record.vehicleId,
            odometer: initialOdometer,
            baseRevision: snapshot.revision,
            baseOdometerRevision: odometer.revision,
          ),
        );
      } else {
        validate(recovered);
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
