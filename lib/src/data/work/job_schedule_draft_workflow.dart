import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

/// Raw civil-time input, including partial numbers, independent of a date picker.
class JobScheduleInput {
  const JobScheduleInput({
    required this.base,
    required this.baseRevision,
    required this.day,
    required this.hour,
    required this.minute,
    required this.period,
    this.bufferMinutes = 0,
  });
  final WorkRecord base;
  final int baseRevision;
  final DateTime day;
  final String hour;
  final String minute;
  final String period;
  final int bufferMinutes;

  factory JobScheduleInput.initial(
    WorkRecord record, {
    required int baseRevision,
  }) {
    final start = record.scheduledStart ?? DateTime.now();
    return JobScheduleInput(
      base: record,
      baseRevision: baseRevision,
      day: DateTime(start.year, start.month, start.day),
      hour: (start.hour % 12 == 0 ? 12 : start.hour % 12).toString(),
      minute: start.minute.toString().padLeft(2, '0'),
      period: start.hour < 12 ? 'AM' : 'PM',
      bufferMinutes: record.scheduleBufferMinutes,
    );
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'day': day.toIso8601String(),
    'hour': hour,
    'minute': minute,
    'period': period,
    'bufferMinutes': bufferMinutes,
  };
  factory JobScheduleInput.fromPayload(Map<String, Object?> payload) =>
      JobScheduleInput(
        base: decodeWorkRecord(
          (payload['base'] as Map).cast<String, Object?>(),
        ),
        baseRevision: payload['baseRevision'] as int,
        day: DateTime.parse(payload['day'] as String),
        hour: payload['hour'] as String,
        minute: payload['minute'] as String,
        period: payload['period'] as String,
        bufferMinutes:
            payload['bufferMinutes'] as int? ??
            ((payload['base'] as Map)['scheduleBufferMinutes'] as int? ?? 0),
      );

  WorkRecord confirmedRecord() {
    final parsedHour = int.tryParse(hour.trim());
    final parsedMinute = int.tryParse(minute.trim());
    if (parsedHour == null ||
        parsedHour < 1 ||
        parsedHour > 12 ||
        parsedMinute == null ||
        parsedMinute < 0 ||
        parsedMinute > 59 ||
        !const {'AM', 'PM'}.contains(period)) {
      throw StateError('Enter an hour from 1 to 12 and minutes from 00 to 59.');
    }
    final start = base.scheduledStart;
    final end = base.scheduledEnd;
    if (start == null || end == null || !end.isAfter(start)) {
      throw StateError(
        'This job needs a recorded start and end before it can be rescheduled.',
      );
    }
    final localHour = parsedHour % 12 + (period == 'PM' ? 12 : 0);
    final scheduledStart = DateTime(
      day.year,
      day.month,
      day.day,
      localHour,
      parsedMinute,
    );
    if (scheduledStart.hour != localHour ||
        scheduledStart.minute != parsedMinute ||
        scheduledStart.day != day.day) {
      throw StateError(
        'That local time is unavailable because the clock changes. Choose another time.',
      );
    }
    return base.copyWith(
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledStart.add(end.difference(start)),
      scheduleBufferMinutes: bufferMinutes,
      status: base.status == WorkRecordStatus.needsReturnVisit
          ? WorkRecordStatus.scheduled
          : base.status,
    );
  }
}

class JobScheduleDraftController
    extends DraftWorkflowController<JobScheduleInput> {
  JobScheduleDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        JobScheduleInput.fromPayload,
      );
  final Future<WorkRecord?> Function(JobScheduleInput, LocalDraftCheckpoint)
  _commit;
  JobScheduleInput get input => recoveredInput!;
  void update({
    required DateTime day,
    required String hour,
    required String minute,
    required String period,
    int? bufferMinutes,
  }) => updateInput(
    JobScheduleInput(
      base: input.base,
      baseRevision: input.baseRevision,
      day: day,
      hour: hour,
      minute: minute,
      period: period,
      bufferMinutes: bufferMinutes ?? input.bufferMinutes,
    ),
  );
  Future<WorkRecord?> confirm() async {
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension JobScheduleDraftWorkflow on WorkPersistenceSession {
  void validateJobScheduleHandoff(
    JobScheduleDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/job-schedule' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current) ||
        !permissions.canScheduleJobs) {
      throw StateError('Selected job schedule belong to another workflow.');
    }
  }

  Future<JobScheduleDraftController> openJobScheduleDraft(
    String recordId, {
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current) ||
        !permissions.canScheduleJobs) {
      throw StateError('Job unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/job-schedule',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(JobScheduleInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.job ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !const {'AM', 'PM'}.contains(input.period) ||
          !permissions.canEdit(input.base) ||
          !permissions.canScheduleJobs) {
        throw StateError('Saved schedule does not match this job.');
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
      final controller = JobScheduleDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.confirmedRecord();
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          JobScheduleInput.initial(
            current,
            baseRevision: storageRevisionFor(recordId),
          ),
        );
      } else {
        validate(controller.input);
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
