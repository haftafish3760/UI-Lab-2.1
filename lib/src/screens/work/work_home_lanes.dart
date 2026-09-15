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
    if (!showDailySummaries) return const SizedBox.shrink();
    final jobs =
        records
            .where(
              (record) =>
                  record.kind == WorkRecordKind.job &&
                  record.status != WorkRecordStatus.draft &&
                  record.status != WorkRecordStatus.completed &&
                  record.scheduledStart != null &&
                  record.occursOn(selectedDay),
            )
            .toList()
          ..sort((a, b) => a.scheduledStart!.compareTo(b.scheduledStart!));
    final entries = records.where((record) {
      if (record.status == WorkRecordStatus.draft) return false;
      final date = record.kind == WorkRecordKind.job
          ? record.completedOn
          : record.kind == WorkRecordKind.invoice
          ? record.issuedOn
          : record.createdOn;
      return date != null && DateUtils.isSameDay(date, selectedDay);
    }).toList();
    DateTime entryTime(WorkRecord record) => (record.kind == WorkRecordKind.job
        ? record.completedOn
        : record.kind == WorkRecordKind.invoice
        ? record.issuedOn
        : record.createdOn)!;
    entries.sort((a, b) => entryTime(a).compareTo(entryTime(b)));
    void open(WorkRecord record) {
      switch (record.kind) {
        case WorkRecordKind.job:
          onOpenJob(record);
        case WorkRecordKind.estimate:
          onOpenEstimate(record);
        case WorkRecordKind.invoice:
          onOpenInvoice(record);
      }
    }

    return OperationsLaneGrid(
      key: ValueKey('work-${layout.columns}-column-queues'),
      layout: layout,
      children: [
        _WorkDailySection(
          title: 'Plan',
          plan: true,
          records: jobs,
          onOpen: open,
          onAssign:
              (PrototypeOperationsScope.of(
                    context,
                  ).workSession?.permissions.canAssignJobs ??
                  (view == AppViewMode.admin))
              ? onAssignJob
              : null,
        ),
        _WorkDailySection(
          title: 'Entries',
          plan: false,
          records: entries,
          onOpen: open,
        ),
      ],
    );
  }
}
