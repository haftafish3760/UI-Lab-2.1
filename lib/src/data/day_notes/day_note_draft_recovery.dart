import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'day_note_draft_workflow.dart';
import 'day_note_persistence_session.dart';

/// Immutable day-note creation recovery, independent of the selected calendar
/// date or employee in any current screen. Recovery never publishes a note.
class DayNoteDraftRecovery {
  DayNoteDraftRecovery(this._notes) {
    _catalog = DraftRecoveryCatalog(
      repository: _notes.drafts,
      organizationId: _notes.access.organizationId,
      ownerId: _notes.access.actorEmployeeId,
      handlers: [handler],
    );
  }
  final DayNotePersistenceSession _notes;
  late final DraftRecoveryCatalog _catalog;
  bool get _canList =>
      _notes.access.canCreate && _notes.access.employeeIds.isNotEmpty;
  DraftRecoveryHandler get handler => DraftRecoveryHandler(
    domain: 'activity/day-note-input',
    workflowLabel: 'Day record',
    canList: () => _canList,
    inspect: _inspect,
    canDiscard: (_) async => _canList,
  );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);
  DayNoteDraftInput _decode(Map<String, Object?> raw) {
    final input = DayNoteDraftInput.fromPayload(raw);
    final date = DateTime.tryParse(input.date);
    if (input.noteId.isEmpty ||
        date == null ||
        input.date.length != 10 ||
        date.toIso8601String().substring(0, 10) != input.date ||
        input.timeMinutes < 0 ||
        input.timeMinutes >= 1440 ||
        (input.createdAt != null && !input.createdAt!.isUtc)) {
      throw const FormatException('Invalid day-record identity.');
    }
    return input;
  }

  Future<DraftRecoveryPreview?> _inspect(Map<String, Object?> raw) async {
    late DayNoteDraftInput input;
    try {
      input = _decode(raw);
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved day-record input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    if (!_notes.access.employeeIds.contains(input.employeeId)) return null;
    final recorded = await _notes.repository.read(
      _notes.access,
      recordId: input.noteId,
    );
    return DraftRecoveryPreview(
      title: 'Day record — ${input.date}',
      recordId: input.noteId,
      availability: recorded.isEmpty
          ? DraftRecoveryAvailability.recoverable
          : DraftRecoveryAvailability.conflict,
    );
  }

  Future<DayNoteDraftController> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError(
        'Saved day-record input requires review before resuming.',
      );
    }
    final saved = await _notes.drafts.find(
      organizationId: _notes.access.organizationId,
      ownerId: _notes.access.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null || saved.revision != current.revision) {
      throw const LocalRecordConflict(
        'Selected input changed; refresh recovery.',
      );
    }
    final input = _decode(_notes.drafts.decode(saved));
    return _notes.openDraft(
      date: DateTime.parse(input.date),
      employeeId: input.employeeId,
      recoverySelection: DraftRecoverySelection(
        domain: current.domain,
        draftId: current.draftId,
        revision: current.revision,
      ),
    );
  }
}
