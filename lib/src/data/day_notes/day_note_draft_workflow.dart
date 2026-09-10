import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_identity.dart';
import 'day_note_persistence_session.dart';
import 'stored_day_note.dart';

class DayNoteInputValidation implements Exception {
  const DayNoteInputValidation(this.message);
  final String message;
}

class DayNoteDraftInput {
  const DayNoteDraftInput({
    required this.noteId,
    required this.employeeId,
    required this.date,
    required this.timeMinutes,
    required this.text,
    this.createdAt,
  });
  final String noteId;
  final String employeeId;
  final String date;
  final int timeMinutes;
  final String text;
  final DateTime? createdAt;

  DayNoteDraftInput withChanges({
    String? text,
    int? timeMinutes,
    DateTime? createdAt,
  }) => DayNoteDraftInput(
    noteId: noteId,
    employeeId: employeeId,
    date: date,
    timeMinutes: timeMinutes ?? this.timeMinutes,
    text: text ?? this.text,
    createdAt: createdAt ?? this.createdAt,
  );
  Map<String, Object?> toPayload() => {
    'noteId': noteId,
    'employeeId': employeeId,
    'date': date,
    'timeMinutes': timeMinutes,
    'text': text,
    'createdAt': createdAt?.toIso8601String(),
  };
  factory DayNoteDraftInput.fromPayload(Map<String, Object?> input) =>
      DayNoteDraftInput(
        noteId: input['noteId'] as String,
        employeeId: input['employeeId'] as String,
        date: input['date'] as String,
        timeMinutes: input['timeMinutes'] as int,
        text: input['text'] as String,
        createdAt: input['createdAt'] == null
            ? null
            : DateTime.parse(input['createdAt'] as String),
      );
}

class DayNoteDraftController
    extends DraftWorkflowController<DayNoteDraftInput> {
  DayNoteDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        DayNoteDraftInput.fromPayload,
      );
  final Future<bool> Function(DayNoteDraftInput, LocalDraftCheckpoint) _commit;
  DayNoteDraftInput get input => recoveredInput!;

  void update({required String text, required int timeMinutes}) =>
      updateInput(input.withChanges(text: text, timeMinutes: timeMinutes));

  Future<bool> confirm() async {
    final current = input;
    if (current.text.trim().isEmpty) {
      throw const DayNoteInputValidation('Enter a record description.');
    }
    // Persist the first confirmation timestamp before the command; failure and
    // later recovery must retry the same note identity and timestamp.
    if (current.createdAt == null) {
      updateInput(current.withChanges(createdAt: DateTime.now().toUtc()));
    }
    return session.confirm((checkpoint) => _commit(input, checkpoint));
  }
}

extension DayNoteDraftWorkflow on DayNotePersistenceSession {
  void validateDayNoteHandoff(
    DayNoteDraftController controller, {
    required DateTime date,
    required String employeeId,
  }) {
    final day = _dayNoteDate(date);
    if (controller.session.organizationId != access.organizationId ||
        controller.session.ownerId != access.actorEmployeeId ||
        controller.session.domain != 'activity/day-note-input' ||
        controller.input.employeeId != employeeId ||
        controller.input.date != day ||
        !access.canCreate ||
        !access.employeeIds.contains(employeeId)) {
      throw StateError('Selected day record belongs to another workflow.');
    }
  }

  Future<DayNoteDraftController> openDraft({
    required DateTime date,
    required String employeeId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (!access.canCreate || !access.employeeIds.contains(employeeId)) {
      throw StateError('Day record is unavailable.');
    }
    final day = _dayNoteDate(date);
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: access.organizationId,
      ownerId: access.actorEmployeeId,
      domain: 'activity/day-note-input',
      draftId:
          recoverySelection?.draftId ??
          'new-${access.actorEmployeeId}-$employeeId-$day',
    );
    void validate(DayNoteDraftInput input) {
      if (input.employeeId != employeeId ||
          input.date != day ||
          input.noteId.isEmpty ||
          input.timeMinutes < 0 ||
          input.timeMinutes >= 1440 ||
          (input.createdAt != null && !input.createdAt!.isUtc)) {
        throw StateError(
          'Retained note belongs to another context or is invalid.',
        );
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
      final controller = DayNoteDraftController._(draft, (input, checkpoint) {
        validate(input);
        return create(
          StoredDayNote(
            id: input.noteId,
            organizationId: access.organizationId,
            employeeId: employeeId,
            date: day,
            timeMinutes: input.timeMinutes,
            text: input.text,
            createdAt: input.createdAt!,
          ),
          draft: checkpoint,
        );
      });
      final recovered = controller.recoveredInput;
      if (recovered == null) {
        final now = DateTime.now();
        controller.updateInput(
          DayNoteDraftInput(
            noteId: newLocalRecordIdentity('day-note'),
            employeeId: employeeId,
            date: day,
            timeMinutes: now.hour * 60 + now.minute,
            text: '',
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

String _dayNoteDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
