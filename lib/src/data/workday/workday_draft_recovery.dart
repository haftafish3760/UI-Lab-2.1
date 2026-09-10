import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'start_workday_draft_workflow.dart';
import 'end_workday_draft_workflow.dart';
import 'stored_workday_record.dart';
import 'workday_persistence_session.dart';

sealed class ResumedWorkdayDraft {
  const ResumedWorkdayDraft();
}

class ResumedWorkdayStart extends ResumedWorkdayDraft {
  const ResumedWorkdayStart(this.controller);
  final StartWorkdayDraftController controller;
}

class ResumedWorkdayEnd extends ResumedWorkdayDraft {
  const ResumedWorkdayEnd(this.controller);
  final EndWorkdayDraftController controller;
}

typedef _Context = ({
  String id,
  String? employee,
  String vehicle,
  int? revision,
  int odometerRevision,
});

/// Recover workflow input without starting/ending work or enabling GPS.
class WorkdayDraftRecovery {
  WorkdayDraftRecovery(this._work) {
    _catalog = DraftRecoveryCatalog(
      repository: _work.drafts,
      organizationId: _work.access.organizationId,
      ownerId: _work.access.actorEmployeeId,
      handlers: handlers,
    );
  }
  final WorkdayPersistenceSession _work;
  late final DraftRecoveryCatalog _catalog;
  bool get _canList =>
      _work.access.canManage && _work.access.vehicleIds.isNotEmpty;
  Iterable<DraftRecoveryHandler> get handlers =>
      ['workday/start', 'workday/end'].map(
        (domain) => DraftRecoveryHandler(
          domain: domain,
          workflowLabel: domain == 'workday/start'
              ? 'Start workday'
              : 'End workday',
          canList: () => _canList,
          inspect: (raw) => _inspect(domain, raw),
          canDiscard: (_) async => _canList,
        ),
      );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);
  _Context _context(String domain, Map<String, Object?> raw) {
    if (domain == 'workday/start') {
      final input = StartWorkdayInput.fromPayload(raw);
      if (input.workdayId.isEmpty ||
          !input.odometerRevisions.containsKey(input.vehicleId) ||
          input.odometerRevisions.values.any((r) => r < 0) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw const FormatException('Invalid start identity.');
      }
      return (
        id: input.workdayId,
        employee: input.employeeId,
        vehicle: input.vehicleId,
        revision: null,
        odometerRevision: input.odometerRevisions[input.vehicleId]!,
      );
    }
    final input = EndWorkdayInput.fromPayload(raw);
    if (input.workdayId.isEmpty ||
        input.baseRevision < 1 ||
        input.baseOdometerRevision < 0 ||
        (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
      throw const FormatException('Invalid ending identity.');
    }
    return (
      id: input.workdayId,
      employee: input.employeeId,
      vehicle: input.vehicleId,
      revision: input.baseRevision,
      odometerRevision: input.baseOdometerRevision,
    );
  }

  Future<DraftRecoveryPreview?> _inspect(
    String domain,
    Map<String, Object?> raw,
  ) async {
    late _Context input;
    try {
      input = _context(domain, raw);
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved workday input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final access = _work.access;
    if (!access.vehicleIds.contains(input.vehicle) ||
        (input.employee != null &&
            !access.employeeIds.contains(input.employee))) {
      return null;
    }
    if (!_work.isReady) {
      return const DraftRecoveryPreview(
        title: 'Workday unavailable — input preserved',
        availability: DraftRecoveryAvailability.unavailable,
      );
    }
    final repository = _work.repository;
    final current = await repository.database.transaction(
      () async => (
        await repository.read(access),
        await repository.odometer(input.vehicle, access),
      ),
    );
    final parent = current.$1.where((s) => s.record.id == input.id).firstOrNull;
    var availability = DraftRecoveryAvailability.recoverable;
    if (input.revision == null) {
      if (parent != null ||
          current.$1.any(
            (s) =>
                s.record.employeeId == input.employee &&
                s.record.status != StoredWorkdayStatus.ended,
          )) {
        availability = DraftRecoveryAvailability.conflict;
      }
    } else if (parent == null ||
        parent.record.status == StoredWorkdayStatus.ended) {
      availability = DraftRecoveryAvailability.parentUnavailable;
    } else if (parent.revision != input.revision ||
        parent.record.employeeId != input.employee ||
        parent.record.vehicleId != input.vehicle) {
      availability = DraftRecoveryAvailability.conflict;
    }
    if (availability == DraftRecoveryAvailability.recoverable &&
        current.$2.revision != input.odometerRevision) {
      availability = DraftRecoveryAvailability.conflict;
    }
    return DraftRecoveryPreview(
      title: domain == 'workday/start'
          ? 'Unfinished workday start'
          : 'Unfinished workday ending',
      availability: availability,
      recordId: input.id,
    );
  }

  Future<ResumedWorkdayDraft> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Saved workday input requires review before resuming.');
    }
    final saved = await _work.drafts.find(
      organizationId: _work.access.organizationId,
      ownerId: _work.access.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null || saved.revision != current.revision) {
      throw const LocalRecordConflict(
        'Selected input changed; refresh recovery.',
      );
    }
    final raw = _work.drafts.decode(saved);
    final selection = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    if (current.domain == 'workday/start') {
      final input = StartWorkdayInput.fromPayload(raw);
      return ResumedWorkdayStart(
        await _work.openStartDraft(
          employeeId: input.employeeId,
          vehicleId: input.vehicleId,
          initialOdometer: input.odometer,
          gpsAssistance: input.gpsAssistance,
          recoverySelection: selection,
        ),
      );
    }
    final input = EndWorkdayInput.fromPayload(raw);
    return ResumedWorkdayEnd(
      await _work.openEndDraft(
        workdayId: input.workdayId,
        initialOdometer: input.odometer,
        recoverySelection: selection,
      ),
    );
  }
}
