import '../storage/draft_repository.dart';
import '../storage/local_draft_store.dart';
import 'package:flutter/widgets.dart';

import '../storage/local_draft_checkpoint.dart';
import '../storage/serialized_async_actions.dart';
import 'sqlite_workday_repository.dart';
import 'stored_workday_record.dart';

class WorkdayCommandResult {
  const WorkdayCommandResult({required this.committed, this.message});
  final bool committed;
  final String? message;
}

/// Shared committed state above routes. UI selection does not change authority.
/// Retry callers retain the original request, including its timestamp/revisions.
class WorkdayPersistenceSession extends ChangeNotifier {
  WorkdayPersistenceSession._(this.repository, this.access);
  final SqliteWorkdayRepository repository;
  final WorkdayAccess access;
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
  List<WorkdaySnapshot> _records = const [];
  Map<String, ConfirmedVehicleOdometer> _odometers = const {};
  bool _disposed = false;
  bool _ready = false;
  int _pending = 0;
  String? _error;

  bool get isReady => _ready;
  bool get isSaving => _pending > 0;
  String? get error => _error;
  List<WorkdaySnapshot> get records => _ready ? _records : const [];
  ConfirmedVehicleOdometer? odometerFor(String vehicleId) =>
      _ready ? _odometers[vehicleId] : null;
  WorkdaySnapshot? activeFor(String employeeId) => records
      .where(
        (item) =>
            item.record.employeeId == employeeId &&
            item.record.status != StoredWorkdayStatus.ended,
      )
      .singleOrNull;

  static Future<WorkdayPersistenceSession> open(
    SqliteWorkdayRepository repository,
    WorkdayAccess access,
  ) async {
    final session = WorkdayPersistenceSession._(repository, access);
    await session._reload();
    return session;
  }

  Future<void> _reload() async {
    final snapshot = await repository.database.transaction(() async {
      final records = await repository.read(access);
      final odometers = <String, ConfirmedVehicleOdometer>{};
      for (final vehicleId in access.vehicleIds) {
        odometers[vehicleId] = await repository.odometer(vehicleId, access);
      }
      return (records, odometers);
    });
    if (_disposed) return;
    _records = List.unmodifiable(snapshot.$1);
    _odometers = Map.unmodifiable(snapshot.$2);
    _ready = true;
    _error = null;
  }

  Future<bool> reload() => _actions.run(() async {
    if (_disposed) return false;
    try {
      await _reload();
      return true;
    } on Object {
      _ready = false;
      _error = 'Workday information could not be loaded. Try again.';
      return false;
    } finally {
      _notify();
    }
  });

  Future<WorkdayCommandResult> start({
    required String id,
    required String employeeId,
    required String vehicleId,
    required int odometerTenths,
    required int expectedOdometerRevision,
    required DateTime at,
    bool gpsAssistanceRequested = false,
    LocalDraftCheckpoint? draft,
  }) => _run(
    () => repository.start(
      id: id,
      employeeId: employeeId,
      vehicleId: vehicleId,
      odometerTenths: odometerTenths,
      gpsAssistanceRequested: gpsAssistanceRequested,
      expectedOdometerRevision: expectedOdometerRevision,
      at: at,
      access: access,
      draft: draft,
    ),
  );

  Future<WorkdayCommandResult> change({
    required String id,
    required int expectedRevision,
    required DateTime at,
    required StoredWorkdayStatus status,
    int? endingOdometerTenths,
    int? expectedOdometerRevision,
    LocalDraftCheckpoint? draft,
  }) => _run(
    () => repository.change(
      id: id,
      expectedRevision: expectedRevision,
      at: at,
      access: access,
      status: status,
      endingOdometerTenths: endingOdometerTenths,
      expectedOdometerRevision: expectedOdometerRevision,
      draft: draft,
    ),
  );

  Future<WorkdayCommandResult> _run(
    Future<WorkdaySnapshot> Function() command,
  ) {
    if (_disposed) {
      return Future.value(
        const WorkdayCommandResult(
          committed: false,
          message: 'This workday session is unavailable.',
        ),
      );
    }
    _pending++;
    _notify();
    return _actions.run(() async {
      try {
        // Disposal stops new admission, not an already accepted command.
        await command();
        try {
          // Replayed acknowledgments can be older than current state.
          await _reload();
          return const WorkdayCommandResult(committed: true);
        } on Object {
          _ready = false;
          _error =
              'Your workday was saved. Reload to view the latest information.';
          return WorkdayCommandResult(committed: true, message: _error);
        }
      } on Object {
        _error =
            'The workday could not be saved. Your unfinished input is preserved.';
        return WorkdayCommandResult(committed: false, message: _error);
      } finally {
        _pending--;
        _notify();
      }
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class WorkdayPersistenceScope
    extends InheritedNotifier<WorkdayPersistenceSession> {
  const WorkdayPersistenceScope({
    required WorkdayPersistenceSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);
  static WorkdayPersistenceSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WorkdayPersistenceScope>()
      ?.notifier;
}
