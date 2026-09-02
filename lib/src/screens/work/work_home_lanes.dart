part of 'work_screen.dart';

class _WorkLanes extends StatelessWidget {
  const _WorkLanes({
    required this.layout,
    required this.view,
    required this.selectedDay,
    required this.records,
    required this.attentionRecordIds,
    required this.showDailySummaries,
    required this.onOpenJob,
    required this.onAssignJob,
    required this.onOpenJobs,
    required this.onOpenEstimate,
    required this.onOpenInvoice,
    required this.onOpenEstimates,
    required this.onOpenInvoices,
    required this.onCreateJob,
    required this.onCreateEstimate,
    required this.onCreateInvoice,
  });

  final OperationsWorkspaceLayout layout;
  final AppViewMode view;
  final DateTime selectedDay;
  final List<WorkRecord> records;
  final Set<String> attentionRecordIds;
  final bool showDailySummaries;
  final ValueChanged<WorkRecord> onOpenJob;
  final ValueChanged<WorkRecord> onAssignJob;
  final VoidCallback onOpenJobs;
  final ValueChanged<WorkRecord> onOpenEstimate;
  final ValueChanged<WorkRecord> onOpenInvoice;
  final VoidCallback onOpenEstimates;
  final VoidCallback onOpenInvoices;
  final VoidCallback onCreateJob;
  final VoidCallback onCreateEstimate;
  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final scopedRecords = records
        .where((record) => record.occursOn(selectedDay))
        .toList();
    final jobs = scopedRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.job &&
              !attentionRecordIds.contains(record.id),
        )
        .toList();
    final estimateRecords = scopedRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.estimate &&
              !attentionRecordIds.contains(record.id),
        )
        .toList();
    final estimateDrafts = estimateRecords
        .where((record) => record.resolvedEstimateStage == EstimateStage.draft)
        .toList();
    final estimates = estimateRecords
        .where((record) => record.resolvedEstimateStage != EstimateStage.draft)
        .toList();
    final invoices = scopedRecords
        .where(
          (record) =>
              record.kind == WorkRecordKind.invoice &&
              !attentionRecordIds.contains(record.id),
        )
        .toList();
    if (!showDailySummaries) return const SizedBox.shrink();
    return OperationsLaneGrid(
      key: ValueKey('work-${layout.columns}-column-queues'),
      layout: layout,
      children: [
        _JobQueuePanel(
          view: view,
          records: jobs,
          onOpen: onOpenJob,
          onAssign: onAssignJob,
          onOpenAll: onOpenJobs,
          onCreate: onCreateJob,
        ),
        _DocumentQueuePanel(
          kind: WorkRecordKind.estimate,
          records: estimates,
          drafts: estimateDrafts,
          onOpenRecord: onOpenEstimate,
          onOpenAll: onOpenEstimates,
          onCreate: onCreateEstimate,
        ),
        _DocumentQueuePanel(
          kind: WorkRecordKind.invoice,
          records: invoices,
          onOpenRecord: onOpenInvoice,
          onOpenAll: onOpenInvoices,
          onCreate: onCreateInvoice,
        ),
      ],
    );
  }
}
