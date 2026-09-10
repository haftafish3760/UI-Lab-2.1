part of 'work_persistence_session.dart';

extension WorkJobConversion on WorkPersistenceSession {
  Future<bool> createJobFromApprovedEstimate({
    required WorkRecord job,
    required int expectedSourceStorageRevision,
    required int expectedSourceDocumentRevision,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    final source = _records[job.sourceId];
    if (source == null ||
        source.kind != WorkRecordKind.estimate ||
        source.revision != expectedSourceDocumentRevision ||
        source.resolvedEstimateStage != EstimateStage.approved ||
        !source.hasCurrentCustomerSignature ||
        _records.containsKey(job.id)) {
      return _reject(
        'The approved estimate changed. Review it before creating a job.',
      );
    }
    return save(
      records: [
        job,
        source.withEstimateStage(EstimateStage.converted, DateTime.now()),
      ],
      expectedStorageRevisions: {
        job.id: 0,
        source.id: expectedSourceStorageRevision,
      },
      draftCheckpoint: draftCheckpoint,
    );
  }

  void _validateJobConversions(List<WorkRecord> proposed) {
    final newLinkedJobs = proposed
        .where(
          (record) =>
              record.kind == WorkRecordKind.job &&
              record.sourceId != null &&
              !_records.containsKey(record.id),
        )
        .toList();
    for (final job in newLinkedJobs) {
      final source = _records[job.sourceId];
      final converted = proposed
          .where((record) => record.id == job.sourceId)
          .firstOrNull;
      if (source == null ||
          source.kind != WorkRecordKind.estimate ||
          source.resolvedEstimateStage != EstimateStage.approved ||
          !source.hasCurrentCustomerSignature ||
          converted == null ||
          converted.resolvedEstimateStage != EstimateStage.converted ||
          converted.revision != source.revision ||
          job.total != source.total ||
          job.pricing != source.pricing ||
          job.client != source.client ||
          canonicalJson(job.items.map(encodeWorkLineItem).toList()) !=
              canonicalJson(source.items.map(encodeWorkLineItem).toList())) {
        throw StateError(
          'A linked job requires the current approved estimate and an atomic conversion.',
        );
      }
    }
    for (final estimate in proposed.where(
      (record) => record.kind == WorkRecordKind.estimate,
    )) {
      if (estimate.resolvedEstimateStage == EstimateStage.converted &&
          _records[estimate.id]?.resolvedEstimateStage !=
              EstimateStage.converted &&
          newLinkedJobs.where((job) => job.sourceId == estimate.id).length !=
              1) {
        throw StateError(
          'Estimate conversion must create exactly one linked job.',
        );
      }
    }
  }
}
