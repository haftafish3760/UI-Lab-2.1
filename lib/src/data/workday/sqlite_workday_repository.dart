import 'workday_read_models.dart';
export 'workday_read_models.dart';
import 'dart:convert';
import '../storage/local_database.dart';
import '../storage/local_record_store.dart';
import '../storage/local_record_command.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_draft_checkpoint.dart';
import 'stored_workday_record.dart';

/// No mutable record cache: command results are returned after SQLite commits.
/// Exact retries return the original command acknowledgment, potentially older
/// than the current record. Callers reload [read] before publishing live state.
/// Retain the original timestamp, revisions and draft checkpoint when retrying.
class SqliteWorkdayRepository {
  SqliteWorkdayRepository(this.database)
    : _records = LocalRecordStore(database);
  final LocalDatabase database;
  final LocalRecordStore _records;
  static const workdaysDomain = 'workday/records';
  static const odometersDomain = 'workday/odometers';
  static const _activeDomain = 'workday/active';

  Future<List<WorkdaySnapshot>> read(WorkdayAccess access) async {
    final rows = await _records.read(
      organizationId: access.organizationId,
      domain: workdaysDomain,
      ownerIds: access.employeeIds,
    );
    return rows
        .map((row) {
          final record = StoredWorkdayRecord.fromJson(_payload(row));
          if (record.organizationId != access.organizationId ||
              record.employeeId != row.ownerId ||
              record.id != row.recordId) {
            throw StateError('Workday identity mismatch.');
          }
          return WorkdaySnapshot(record, row.revision);
        })
        .where((value) => access.vehicleIds.contains(value.record.vehicleId))
        .toList();
  }

  Future<ConfirmedVehicleOdometer> odometer(
    String vehicleId,
    WorkdayAccess access,
  ) async {
    if (!access.vehicleIds.contains(vehicleId)) {
      throw StateError('Vehicle access denied.');
    }
    final row = await _row(odometersDomain, vehicleId, {vehicleId}, access);
    return ConfirmedVehicleOdometer(
      row == null ? 0 : _payload(row)['readingTenths'] as int,
      row?.revision ?? 0,
    );
  }

  Future<WorkdaySnapshot> start({
    required String id,
    required String employeeId,
    required String vehicleId,
    required int odometerTenths,
    required int expectedOdometerRevision,
    required DateTime at,
    required WorkdayAccess access,
    bool gpsAssistanceRequested = false,
    LocalDraftCheckpoint? draft,
  }) {
    _authorize(employeeId, vehicleId, access);
    final record = StoredWorkdayRecord.start(
      id: id,
      organizationId: access.organizationId,
      employeeId: employeeId,
      vehicleId: vehicleId,
      at: at,
      odometerTenths: odometerTenths,
      gpsAssistanceRequested: gpsAssistanceRequested,
    );
    return database.transaction(() async {
      final commandId = 'workday-start-$id';
      final request = _request(access, draft, {
        'record': record.toJson(),
        'expectedOdometerRevision': expectedOdometerRevision,
      });
      final replay = await _replay(commandId, request, access, draft);
      if (replay != null) return replay;
      final active = await _row(_activeDomain, employeeId, {
        employeeId,
      }, access);
      if (active != null && _payload(active)['workdayId'] != null) {
        throw StateError('This employee already has an active workday.');
      }
      final current = await odometer(vehicleId, access);
      if (current.revision != expectedOdometerRevision ||
          odometerTenths < current.readingTenths) {
        throw const LocalRecordConflict(
          'The confirmed odometer changed or decreased.',
        );
      }
      await _records.commit(
        organizationId: access.organizationId,
        commandId: commandId,
        occurredAt: at,
        writes: [
          _recordWrite(record, 0, access),
          _receiptWrite(commandId, request, record, 1),
          LocalRecordWrite(
            domain: _activeDomain,
            recordId: employeeId,
            ownerId: employeeId,
            expectedRevision: active?.revision ?? 0,
            payload: {'workdayId': id},
          ),
          _odometerWrite(record, current.revision, access),
        ],
      );
      await _consume(draft, access, record, 'workday/start');
      return WorkdaySnapshot(record, 1);
    });
  }

  Future<WorkdaySnapshot> change({
    required String id,
    required int expectedRevision,
    required DateTime at,
    required WorkdayAccess access,
    required StoredWorkdayStatus status,
    int? endingOdometerTenths,
    int? expectedOdometerRevision,
    LocalDraftCheckpoint? draft,
  }) => database.transaction(() async {
    final commandId = 'workday-$id-${expectedRevision + 1}';
    final request = _request(access, draft, {
      'id': id,
      'expectedRevision': expectedRevision,
      'at': at.toUtc().toIso8601String(),
      'status': status.name,
      'endingOdometerTenths': endingOdometerTenths,
      'expectedOdometerRevision': expectedOdometerRevision,
    });
    final replay = await _replay(commandId, request, access, draft);
    if (replay != null) return replay;
    final row = await _row(workdaysDomain, id, access.employeeIds, access);
    if (row == null || row.revision != expectedRevision) {
      throw const LocalRecordConflict('Workday changed or is unavailable.');
    }
    final current = StoredWorkdayRecord.fromJson(_payload(row));
    if (current.organizationId != access.organizationId ||
        current.id != id ||
        current.employeeId != row.ownerId) {
      throw StateError('Workday identity mismatch.');
    }
    _authorize(current.employeeId, current.vehicleId, access);
    final next = switch (status) {
      StoredWorkdayStatus.active => current.resume(at),
      StoredWorkdayStatus.paused => current.pause(at),
      StoredWorkdayStatus.ended => current.end(
        at: at,
        odometerTenths:
            endingOdometerTenths ??
            (throw ArgumentError('Ending odometer is required.')),
      ),
    };
    final writes = [
      _recordWrite(next, row.revision, access),
      _receiptWrite(commandId, request, next, row.revision + 1),
    ];
    if (status == StoredWorkdayStatus.ended) {
      final odometerState = await odometer(current.vehicleId, access);
      if (expectedOdometerRevision != odometerState.revision ||
          next.currentOdometerTenths < odometerState.readingTenths) {
        throw const LocalRecordConflict(
          'The confirmed odometer changed or decreased.',
        );
      }
      final active = await _row(_activeDomain, current.employeeId, {
        current.employeeId,
      }, access);
      if (active == null || _payload(active)['workdayId'] != id) {
        throw const LocalRecordConflict('Active workday changed.');
      }
      writes.add(_odometerWrite(next, odometerState.revision, access));
      writes.add(
        LocalRecordWrite(
          domain: _activeDomain,
          recordId: current.employeeId,
          ownerId: current.employeeId,
          expectedRevision: active.revision,
          payload: {'workdayId': null},
        ),
      );
    }
    await _records.commit(
      organizationId: access.organizationId,
      commandId: commandId,
      writes: writes,
      occurredAt: at,
    );
    if (draft != null && status != StoredWorkdayStatus.ended) {
      throw const LocalRecordConflict(
        'Only ending a workday can consume end input.',
      );
    }
    await _consume(draft, access, next, 'workday/end');
    return WorkdaySnapshot(next, row.revision + 1);
  });
  String _request(
    WorkdayAccess access,
    LocalDraftCheckpoint? draft,
    Map<String, Object?> values,
  ) => payloadDigest(
    canonicalJson({
      ...values,
      'actorEmployeeId': access.actorEmployeeId,
      'permissionRevision': access.permissionRevision,
      'draft': draft == null
          ? null
          : {
              'domain': draft.domain,
              'draftId': draft.draftId,
              'revision': draft.revision,
            },
    }),
  );

  LocalRecordWrite _receiptWrite(
    String commandId,
    String request,
    StoredWorkdayRecord record,
    int revision,
  ) => LocalRecordWrite(
    domain: 'workday/command-results',
    recordId: commandId,
    ownerId: record.employeeId,
    expectedRevision: 0,
    payload: {
      'request': request,
      'record': record.toJson(),
      'revision': revision,
    },
  );

  Future<WorkdaySnapshot?> _replay(
    String commandId,
    String request,
    WorkdayAccess access,
    LocalDraftCheckpoint? draft,
  ) async {
    final row = await _row(
      'workday/command-results',
      commandId,
      access.employeeIds,
      access,
    );
    if (row == null) return null;
    final payload = _payload(row);
    final record = StoredWorkdayRecord.fromJson(
      (payload['record'] as Map).cast<String, Object?>(),
    );
    _authorize(record.employeeId, record.vehicleId, access);
    if (record.organizationId != access.organizationId ||
        record.employeeId != row.ownerId ||
        payload['request'] != request) {
      throw const LocalRecordConflict(
        'This workday action was already used for different input.',
      );
    }
    if (draft != null &&
        await LocalDraftStore(database).find(
              organizationId: access.organizationId,
              domain: draft.domain,
              draftId: draft.draftId,
              ownerId: access.actorEmployeeId,
            ) !=
            null) {
      throw const LocalRecordConflict('New unfinished input is preserved.');
    }
    return WorkdaySnapshot(record, payload['revision'] as int);
  }

  void _authorize(String employeeId, String vehicleId, WorkdayAccess access) {
    if (!access.canManage ||
        access.organizationId.trim().isEmpty ||
        access.actorEmployeeId.trim().isEmpty ||
        access.permissionRevision.trim().isEmpty ||
        !access.employeeIds.contains(employeeId) ||
        !access.vehicleIds.contains(vehicleId)) {
      throw StateError('Workday action denied.');
    }
  }

  Future<LocalRecord?> _row(
    String domain,
    String id,
    Set<String> ownerIds,
    WorkdayAccess access,
  ) async => (await _records.read(
    organizationId: access.organizationId,
    domain: domain,
    ownerIds: ownerIds,
  )).where((row) => row.recordId == id).firstOrNull;
  Map<String, Object?> _payload(LocalRecord row) {
    if (row.payloadVersion != 1) {
      throw StateError('Unsupported workday storage version.');
    }
    return (jsonDecode(row.payload) as Map).cast<String, Object?>();
  }

  LocalRecordWrite _recordWrite(
    StoredWorkdayRecord record,
    int revision,
    WorkdayAccess access,
  ) => LocalRecordWrite(
    domain: workdaysDomain,
    recordId: record.id,
    ownerId: record.employeeId,
    expectedRevision: revision,
    payload: {
      ...record.toJson(),
      'lastChangedByEmployeeId': access.actorEmployeeId,
      'permissionRevision': access.permissionRevision,
    },
  );
  LocalRecordWrite _odometerWrite(
    StoredWorkdayRecord record,
    int revision,
    WorkdayAccess access,
  ) => LocalRecordWrite(
    domain: odometersDomain,
    recordId: record.vehicleId,
    ownerId: record.vehicleId,
    expectedRevision: revision,
    payload: {
      'readingTenths': record.currentOdometerTenths,
      'workdayId': record.id,
      'lastChangedByEmployeeId': access.actorEmployeeId,
      'permissionRevision': access.permissionRevision,
    },
  );
  Future<void> _consume(
    LocalDraftCheckpoint? draft,
    WorkdayAccess access,
    StoredWorkdayRecord record,
    String domain,
  ) async {
    if (draft == null) return;
    final store = LocalDraftStore(database);
    final retained = await store.find(
      organizationId: access.organizationId,
      domain: draft.domain,
      draftId: draft.draftId,
      ownerId: access.actorEmployeeId,
    );
    final input = retained == null ? null : store.decode(retained);
    if (draft.domain != domain ||
        input?['workdayId'] != record.id ||
        input?['employeeId'] != record.employeeId ||
        input?['vehicleId'] != record.vehicleId) {
      throw const LocalRecordConflict(
        'Unfinished input does not belong to this workday.',
      );
    }
    if (!await LocalDraftStore(database).consumeIfUnchanged(
      organizationId: access.organizationId,
      domain: draft.domain,
      draftId: draft.draftId,
      ownerId: access.actorEmployeeId,
      expectedRevision: draft.revision,
    )) {
      throw const LocalRecordConflict('The unfinished workday input changed.');
    }
  }
}
