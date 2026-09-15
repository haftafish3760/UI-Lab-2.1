part of 'work_screen.dart';

class _WorkDailySection extends StatelessWidget {
  const _WorkDailySection({
    required this.title,
    required this.plan,
    required this.records,
    required this.onOpen,
    this.onAssign,
  });
  final String title;
  final bool plan;
  final List<WorkRecord> records;
  final ValueChanged<WorkRecord> onOpen;
  final ValueChanged<WorkRecord>? onAssign;

  @override
  Widget build(BuildContext context) {
    final tone = plan
        ? OperationalCardPalette.plan
        : OperationalCardPalette.entries;
    Widget content(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationalSectionHeading(
          background: tone.start,
          foreground: tone.foreground,
          child: Row(
            children: [
              Icon(
                plan ? Icons.event_note_outlined : Icons.fact_check_outlined,
                color: tone.foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tone.foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              plan
                  ? 'No jobs scheduled for this date.'
                  : 'No work entries for this date.',
              style: TextStyle(color: tone.foreground),
            ),
          ),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Material(
              color: tone.row,
              borderRadius: BorderRadius.circular(4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  record.client,
                  style: const TextStyle(
                    color: OperationalCardTone.darkInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${record.title}\n${record.number} · ${record.status.label}\n${_time(context, record)}${plan ? ' · ${record.assignee ?? 'Unassigned'}' : ''}',
                  style: const TextStyle(color: OperationalCardTone.darkInk),
                ),
                onTap: () => onOpen(record),
                trailing: plan && onAssign != null
                    ? IconButton(
                        tooltip: 'Assign employees',
                        icon: const Icon(
                          Icons.group_add_outlined,
                          color: OperationalCardTone.darkInk,
                        ),
                        onPressed: () => onAssign!(record),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: OperationalCardTone.darkInk,
                      ),
              ),
            ),
          ),
        if (records.isNotEmpty) const SizedBox(height: 6),
      ],
    );
    return plan
        ? SectionCard(
            padding: EdgeInsets.zero,
            backgroundColor: tone.start,
            borderColor: tone.start,
            child: content(context),
          )
        : RecordedEntriesSection(builder: content);
  }

  String _time(BuildContext context, WorkRecord record) {
    final date = plan
        ? record.scheduledStart
        : record.kind == WorkRecordKind.job
        ? record.completedOn
        : record.kind == WorkRecordKind.invoice
        ? record.issuedOn
        : record.createdOn;
    return date == null
        ? 'Time not recorded'
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(date.toLocal()));
  }
}
