import 'models/work_models.dart';
import 'work_activity_reader.dart';
import 'work_persistence_session.dart';

class ProposalApprovalHistoryPage {
  const ProposalApprovalHistoryPage(this.records, this.nextBefore);
  final List<WorkRecord> records;
  final int? nextBefore;
}

extension ProposalApprovalHistory on WorkPersistenceSession {
  /// Uses the same verified snapshots and authority as People and activity.
  /// Never reconstructs old consent from today's document contents.
  Future<ProposalApprovalHistoryPage> approvedProposalHistory(
    String recordId, {
    int? beforeStorageRevision,
  }) async {
    final page = await WorkActivityReader(
      this,
    ).read(recordId, beforeRevision: beforeStorageRevision);
    final verified = <WorkRecord>[];
    for (final entry in page.entries) {
      final record = entry.record;
      if (record == null || !record.isProposal) {
        throw StateError(
          'This history does not belong to an estimate or quote.',
        );
      }
      if (record.hasCurrentCustomerApproval) verified.add(record);
    }
    return ProposalApprovalHistoryPage(
      List.unmodifiable(verified),
      page.nextBeforeRevision,
    );
  }
}
