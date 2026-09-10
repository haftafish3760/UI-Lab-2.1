import 'day_note_access.dart';
export 'day_note_access.dart';
import '../storage/local_database.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_store.dart';
import '../storage/local_record_command.dart';
import 'stored_day_note.dart';

/// Standalone activity notes do not require a workday, vehicle or GPS session.
class SqliteDayNoteRepository {
  SqliteDayNoteRepository(this.database)
    : _records = LocalRecordStore(database);
  final LocalDatabase database;
  final LocalRecordStore _records;
  static const domain = 'activity/day-notes';
  static const draftDomain = 'activity/day-note-input';

  Future<List<StoredDayNote>> read(
    DayNoteAccess access, {
    String? recordId,
  }) async {
    final rows = await _records.read(
      organizationId: access.organizationId,
      domain: domain,
      ownerIds: access.employeeIds,
      recordIds: recordId == null ? null : {recordId},
    );
    return rows.map((row) {
      final note = StoredDayNote.fromJson(_records.decode(row));
      if (note.id != row.recordId ||
          note.organizationId != access.organizationId ||
          note.employeeId != row.ownerId) {
        throw StateError('Day note identity mismatch.');
      }
      return note;
    }).toList();
  }

  Future<void> create(
    StoredDayNote note,
    DayNoteAccess access, {
    LocalDraftCheckpoint? draft,
  }) async {
    if (!access.canCreate ||
        access.organizationId != note.organizationId ||
        access.actorEmployeeId.trim().isEmpty ||
        access.permissionRevision.trim().isEmpty ||
        !access.employeeIds.contains(note.employeeId)) {
      throw StateError('Day note action denied.');
    }
    await database.transaction(() async {
      final existing = (await _records.read(
        organizationId: access.organizationId,
        domain: domain,
        ownerIds: access.employeeIds,
      )).where((row) => row.recordId == note.id).firstOrNull;
      final drafts = LocalDraftStore(database);
      final retained = draft == null
          ? null
          : await drafts.find(
              organizationId: access.organizationId,
              domain: draft.domain,
              draftId: draft.draftId,
              ownerId: access.actorEmployeeId,
            );
      if (draft != null) {
        if (draft.domain != draftDomain) {
          throw const LocalRecordConflict('Wrong day note draft.');
        }
        if (existing != null) {
          if (retained != null) {
            throw const LocalRecordConflict(
              'New unfinished input is preserved.',
            );
          }
        } else {
          final input = retained == null ? null : drafts.decode(retained);
          if (input?['noteId'] != note.id ||
              input?['employeeId'] != note.employeeId ||
              input?['date'] != note.date ||
              input?['text'] != note.text ||
              input?['timeMinutes'] != note.timeMinutes ||
              retained?.revision != draft.revision) {
            throw const LocalRecordConflict(
              'Day note input changed or is unavailable.',
            );
          }
        }
      }
      // The command fingerprint rejects the same ID with changed values and
      // allows exact acknowledged or lost-acknowledgment retries after reopen.
      await _records.commit(
        organizationId: access.organizationId,
        commandId: 'day-note-create-${note.id}',
        occurredAt: note.createdAt,
        writes: [
          LocalRecordWrite(
            domain: domain,
            recordId: note.id,
            ownerId: note.employeeId,
            expectedRevision: 0,
            payload: {
              ...note.toJson(),
              'actorEmployeeId': access.actorEmployeeId,
              'permissionRevision': access.permissionRevision,
            },
          ),
        ],
      );
      if (draft != null &&
          existing == null &&
          !await drafts.consumeIfUnchanged(
            organizationId: access.organizationId,
            domain: draft.domain,
            draftId: draft.draftId,
            ownerId: access.actorEmployeeId,
            expectedRevision: draft.revision,
          )) {
        throw const LocalRecordConflict('Day note input changed.');
      }
    });
  }
}
