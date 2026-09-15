part of 'work_screen.dart';

class _JobQueuePanel extends StatelessWidget {
  const _JobQueuePanel({
    required this.view,
    required this.records,
    required this.onOpen,
    required this.onAssign,
  });

  final AppViewMode view;
  final List<WorkRecord> records;
  final ValueChanged<WorkRecord> onOpen;
  final ValueChanged<WorkRecord> onAssign;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final visible = records.take(3).toList();
    return _WorkRecordSection(
      key: const ValueKey('work-jobs-section'),
      icon: Icons.home_repair_service_outlined,
      title: view == AppViewMode.admin ? 'Company Jobs' : 'My Jobs',
      accent: semantic.current,
      headerSurface: semantic.currentSurface,
      records: visible,
      totalCount: records.length,
      emptyMessage: 'No jobs are available in this view.',
      rowBuilder: (record) => _WorkRecordRow(
        rowKey: ValueKey('work-job-row-${record.id}'),
        record: record,
        icon: Icons.handyman_outlined,
        subtitle: _jobSubtitle(context, record),
        accent: semantic.current,
        onOpen: () => onOpen(record),
        trailing: view == AppViewMode.admin
            ? PopupMenuButton<String>(
                key: ValueKey('assign-${record.id}'),
                tooltip: 'Job actions',
                onSelected: (_) => onAssign(record),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'assign',
                    child: Text(
                      record.assignee == null ? 'Assign job' : 'Reassign job',
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _DocumentQueuePanel extends StatelessWidget {
  const _DocumentQueuePanel({
    required this.kind,
    required this.records,
    required this.onOpenRecord,
    required this.onOpenAll,
  });

  final WorkRecordKind kind;
  final List<WorkRecord> records;
  final ValueChanged<WorkRecord> onOpenRecord;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final estimate = kind == WorkRecordKind.estimate;
    final accent = estimate ? semantic.planned : semantic.success;
    final headerSurface = estimate
        ? semantic.plannedSurface
        : semantic.successSurface;
    return _WorkRecordSection(
      key: ValueKey('work-${kind.name}s-section'),
      icon: _recordIcon(kind),
      title: estimate ? 'Estimates' : 'Invoices',
      accent: accent,
      headerSurface: headerSurface,
      records: records.take(3).toList(),
      totalCount: records.length,
      emptyMessage: estimate
          ? 'No estimates are available in this scope.'
          : 'No invoices are available in this scope.',
      onOpenAll: onOpenAll,
      rowBuilder: (record) => _WorkRecordRow(
        rowKey: ValueKey('work-${kind.name}-row-${record.id}'),
        record: record,
        icon: _recordIcon(record.kind),
        subtitle: _documentSubtitle(record),
        accent: accent,
        onOpen: () => onOpenRecord(record),
      ),
    );
  }
}

class _WorkRecordSection extends StatelessWidget {
  const _WorkRecordSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.headerSurface,
    required this.records,
    required this.totalCount,
    required this.rowBuilder,
    this.onOpenAll,
    this.emptyMessage,
    super.key,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Color headerSurface;
  final List<WorkRecord> records;
  final int totalCount;
  final String? emptyMessage;
  final VoidCallback? onOpenAll;
  final Widget Function(WorkRecord record) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      backgroundColor: headerSurface,
      borderColor: accent.withValues(alpha: .72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkSectionHeading(
            icon: icon,
            title: title,
            count: totalCount,
            accent: accent,
            background: headerSurface,
            onOpenAll: onOpenAll,
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                emptyMessage ?? 'No records are available in this view.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else ...[
            if (records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Column(
                  children: [
                    for (var index = 0; index < records.length; index++) ...[
                      rowBuilder(records[index]),
                      if (index != records.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WorkRecordRow extends StatelessWidget {
  const _WorkRecordRow({
    required this.record,
    required this.icon,
    required this.subtitle,
    required this.accent,
    required this.onOpen,
    required this.rowKey,
    this.trailing,
  });

  final WorkRecord record;
  final IconData icon;
  final String subtitle;
  final Color accent;
  final VoidCallback onOpen;
  final Key rowKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
        return SectionCard(
          key: rowKey,
          padding: EdgeInsets.zero,
          backgroundColor: colors.surface,
          borderColor: accent.withValues(alpha: .58),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: type.operationRowHeight),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.surface),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: TextStyle(
                              fontSize: type.rowTitle,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _jobSubtitle(BuildContext context, WorkRecord record) {
  final start = record.scheduledStart;
  final time = start == null
      ? 'Time not set'
      : MaterialLocalizations.of(
          context,
        ).formatTimeOfDay(TimeOfDay.fromDateTime(start));
  return '${record.client} · $time';
}

String _documentSubtitle(WorkRecord record) {
  if (record.kind == WorkRecordKind.estimate) {
    return '${record.client} · ${record.resolvedEstimateStage.label} · ${record.number}';
  }
  return '${record.client} · ${record.number}';
}

class _WorkCalendarPanel extends StatelessWidget {
  const _WorkCalendarPanel({
    required this.maximumWidth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.entryCountForDay,
  });

  final double maximumWidth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final int Function(DateTime day) entryCountForDay;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Work Calendar', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 3),
      const Text('Review planned work and recorded activity by date.'),
      const SizedBox(height: 10),
      WorkMonthCalendar(
        maximumWidth: maximumWidth,
        selectedDay: selectedDay,
        onDaySelected: onDaySelected,
        entryCountForDay: entryCountForDay,
        recordKind: CalendarRecordKind.workRecord,
      ),
    ],
  );
}
