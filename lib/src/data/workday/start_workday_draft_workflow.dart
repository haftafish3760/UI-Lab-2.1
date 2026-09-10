import 'odometer_input.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'workday_persistence_session.dart';

class StartWorkdayInputValidation implements Exception {
  const StartWorkdayInputValidation(this.message);
  final String message;
}

class StartWorkdayInput {
  StartWorkdayInput({
    required this.workdayId,
    required this.employeeId,
    required this.vehicleId,
    required this.odometer,
    required this.gpsAssistance,
    required Map<String, int> odometerRevisions,
    this.confirmedAt,
  }) : odometerRevisions = Map.unmodifiable(odometerRevisions);
  final String workdayId;
  final String? employeeId;
  final String vehicleId;
  final String odometer;
  final bool gpsAssistance;
  final Map<String, int> odometerRevisions;
  final DateTime? confirmedAt;
  StartWorkdayInput withValues({
    required String? employeeId,
    required String vehicleId,
    required String odometer,
    required bool gpsAssistance,
    DateTime? confirmedAt,
  }) => StartWorkdayInput(
    workdayId: workdayId,
    employeeId: employeeId,
    vehicleId: vehicleId,
    odometer: odometer,
    gpsAssistance: gpsAssistance,
    odometerRevisions: odometerRevisions,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
  Map<String, Object?> toPayload() => {
    'workdayId': workdayId,
    'employeeId': employeeId,
    'vehicleId': vehicleId,
    'odometer': odometer,
    'gpsAssistance': gpsAssistance,
    'odometerRevisions': odometerRevisions,
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory StartWorkdayInput.fromPayload(Map<String, Object?> input) =>
      StartWorkdayInput(
        workdayId: input['workdayId'] as String,
        employeeId: input['employeeId'] as String?,
        vehicleId: input['vehicleId'] as String,
        odometer: input['odometer'] as String,
        gpsAssistance: input['gpsAssistance'] as bool,
        odometerRevisions: (input['odometerRevisions'] as Map)
            .cast<String, int>(),
        confirmedAt: input['confirmedAt'] == null
            ? null
            : DateTime.parse(input['confirmedAt'] as String),
      );
}

class StartWorkdayDraftController
    extends DraftWorkflowController<StartWorkdayInput> {
  StartWorkdayDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        StartWorkdayInput.fromPayload,
      );
  final Future<WorkdayCommandResult> Function(
    StartWorkdayInput,
    int,
    LocalDraftCheckpoint,
  )
  _commit;
  StartWorkdayInput get input => recoveredInput!;
  void update({
    required String? employeeId,
    required String vehicleId,
    required String odometer,
    required bool gpsAssistance,
  }) => updateInput(
    input.withValues(
      employeeId: employeeId,
      vehicleId: vehicleId,
      odometer: odometer,
      gpsAssistance: gpsAssistance,
    ),
  );

  Future<WorkdayCommandResult> confirm() async {
    final current = input;
    if (current.employeeId == null) {
      throw const StartWorkdayInputValidation(
        'Select an employee before starting the workday.',
      );
    }
    final reading = tryParseWorkdayOdometerMiles(current.odometer);
    if (reading == null) {
      throw const StartWorkdayInputValidation(
        'Enter a valid odometer reading.',
      );
    }
    if (current.confirmedAt == null) {
      updateInput(
        current.withValues(
          employeeId: current.employeeId,
          vehicleId: current.vehicleId,
          odometer: current.odometer,
          gpsAssistance: current.gpsAssistance,
          confirmedAt: DateTime.now().toUtc(),
        ),
      );
    }
    late WorkdayCommandResult result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, reading, checkpoint);
      return result.committed;
    });
    return result;
  }
}

extension StartWorkdayDraftWorkflow on WorkdayPersistenceSession {
  void validateStartWorkdayHandoff(StartWorkdayDraftController controller) {
    final input = controller.input;
    if (!isReady ||
        !access.canManage ||
        controller.session.organizationId != access.organizationId ||
        controller.session.ownerId != access.actorEmployeeId ||
        controller.session.domain != 'workday/start' ||
        !access.vehicleIds.contains(input.vehicleId) ||
        (input.employeeId != null &&
            !access.employeeIds.contains(input.employeeId))) {
      throw StateError('Selected starting input belongs to another workflow.');
    }
  }

  Future<StartWorkdayDraftController> openStartDraft({
    required String? employeeId,
    required String vehicleId,
    required String initialOdometer,
    bool gpsAssistance = false,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (!isReady ||
        !access.canManage ||
        !access.vehicleIds.contains(vehicleId) ||
        (employeeId != null && !access.employeeIds.contains(employeeId))) {
      throw StateError('Workday is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: access.organizationId,
      ownerId: access.actorEmployeeId,
      domain: 'workday/start',
      draftId: recoverySelection?.draftId ?? 'start-${access.actorEmployeeId}',
    );
    void validate(StartWorkdayInput input) {
      if (input.workdayId.isEmpty ||
          !access.vehicleIds.contains(input.vehicleId) ||
          (input.employeeId != null &&
              !access.employeeIds.contains(input.employeeId)) ||
          !input.odometerRevisions.containsKey(input.vehicleId) ||
          input.odometerRevisions.values.any((value) => value < 0) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Draft context is unavailable.');
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
      final controller = StartWorkdayDraftController._(draft, (
        input,
        reading,
        checkpoint,
      ) {
        validate(input);
        final odometer = odometerFor(input.vehicleId);
        if (odometer == null || !isReady) {
          throw StateError('Workday is unavailable.');
        }
        if (reading < odometer.readingTenths) {
          throw const StartWorkdayInputValidation(
            'The reading cannot be lower than the last confirmed value.',
          );
        }
        return start(
          id: input.workdayId,
          employeeId: input.employeeId!,
          vehicleId: input.vehicleId,
          odometerTenths: reading,
          expectedOdometerRevision: input.odometerRevisions[input.vehicleId]!,
          gpsAssistanceRequested: input.gpsAssistance,
          at: input.confirmedAt!,
          draft: checkpoint,
        );
      });
      final recovered = controller.recoveredInput;
      if (recovered == null) {
        controller.updateInput(
          StartWorkdayInput(
            workdayId: newLocalRecordIdentity('workday'),
            employeeId: employeeId,
            vehicleId: vehicleId,
            odometer: initialOdometer,
            gpsAssistance: gpsAssistance,
            odometerRevisions: {
              for (final id in access.vehicleIds) id: odometerFor(id)!.revision,
            },
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
