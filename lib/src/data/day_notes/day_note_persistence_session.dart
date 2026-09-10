import '../storage/draft_repository.dart';
import '../storage/local_draft_store.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/serialized_async_actions.dart';
import 'sqlite_day_note_repository.dart';
import 'stored_day_note.dart';

/// The current UI only creates immutable notes. Publish a new note after its
/// transaction commits; no second read can turn a committed save into failure.
class DayNotePersistenceSession extends ChangeNotifier {
  DayNotePersistenceSession._(this.repository, this.access, this._records);
  final SqliteDayNoteRepository repository;
  final DayNoteAccess access;
  DraftRepository get drafts {
    requireActiveDraftOwner();
    return LocalDraftStore(repository.database);
  }

  void requireActiveDraftOwner() {
    if (_disposed) {
      throw StateError('The activity session is no longer active.');
    }
  }

  final _actions = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _actions.pauseAndDrain();
  List<StoredDayNote> _records;
  int _pending = 0;
  bool _disposed = false;
  String? _error;
  List<StoredDayNote> get records => List.unmodifiable(_records);
  bool get isSaving => _pending > 0;
  String? get error => _error;

  static Future<DayNotePersistenceSession> open(
    SqliteDayNoteRepository repository,
    DayNoteAccess access,
  ) async => DayNotePersistenceSession._(
    repository,
    access,
    await repository.read(access),
  );

  Future<bool> create(StoredDayNote note, {LocalDraftCheckpoint? draft}) {
    if (_disposed) return Future.value(false);
    _pending++;
    notifyListeners();
    return _actions.run(() async {
      try {
        // Admission happened before disposal; drain the accepted command.
        await repository.create(note, access, draft: draft);
        _records = [..._records.where((item) => item.id != note.id), note];
        _error = null;
        return true;
      } on Object {
        _error =
            'The day record could not be saved. Your unfinished input is preserved.';
        return false;
      } finally {
        _pending--;
        if (!_disposed) notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
