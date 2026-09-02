part of 'job_list_workspace_screen.dart';

class _JobListSection extends StatelessWidget {
  const _JobListSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.emptyMessage,
    required this.headerColor,
    required this.borderColor,
    required this.selectedDay,
    required this.preferences,
    required this.onOpen,
    this.totalCount,
    this.rowAccent,
    this.footer,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<WorkRecord> records;
  final int? totalCount;
  final String emptyMessage;
  final Color headerColor;
  final Color borderColor;
  final Color? rowAccent;
  final DateTime selectedDay;
  final WorkRecordDisplayPreferences preferences;
  final ValueChanged<WorkRecord> onOpen;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: headerColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${totalCount ?? records.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: records.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(emptyMessage),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < records.length;
                          index++
                        ) ...[
                          _JobRecordRow(
                            record: records[index],
                            selectedDay: selectedDay,
                            accent: rowAccent,
                            preferences: preferences,
                            onOpen: () => onOpen(records[index]),
                          ),
                          if (index < records.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            if (footer case final footer?)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Align(alignment: Alignment.centerLeft, child: footer),
              ),
          ],
        ),
      ),
    );
  }
}

class _JobRecordRow extends StatelessWidget {
  const _JobRecordRow({
    required this.record,
    required this.selectedDay,
    required this.preferences,
    required this.onOpen,
    this.accent,
  });

  final WorkRecord record;
  final DateTime selectedDay;
  final WorkRecordDisplayPreferences preferences;
  final VoidCallback onOpen;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rowAccent = accent ?? _jobStatusColor(context, record.status);
    return Semantics(
      button: true,
      label:
          '${record.client}, ${record.title}, ${record.status.label}, ${_timeLabel(context)}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: rowAccent.withValues(alpha: .65)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: ConstrainedBox(
            key: ValueKey('job-row-${record.id}'),
            constraints: const BoxConstraints(minHeight: 60),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 5, child: ColoredBox(color: rowAccent)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 0, 7),
                      child: _rowBody(context, colors, rowAccent),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.chevron_right_rounded, size: 22),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowBody(BuildContext context, ColorScheme colors, Color rowAccent) {
    final assignment = preferences.showAssignments
        ? record.assignee ?? 'Unassigned'
        : null;
    final secondary = assignment == null
        ? record.client
        : '${record.client} · $assignment';
    final accessible = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.35;
    if (accessible) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              Text(
                _timeLabel(context),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (preferences.showStatusDetails)
                Text(
                  record.status.label,
                  style: TextStyle(
                    color: rowAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            record.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(secondary, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                _timeLabel(context),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                record.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (preferences.showStatusDetails)
              SizedBox(
                width: 72,
                child: Text(
                  record.status.label,
                  style: TextStyle(
                    color: rowAccent,
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const SizedBox(width: 72),
            Expanded(
              child: Text(
                secondary,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _timeLabel(BuildContext context) {
    final start = record.scheduledStart;
    if (start == null) return 'Not set';
    if (!DateUtils.isSameDay(start, selectedDay)) return 'Continues';
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(start));
  }
}

Color _jobStatusColor(BuildContext context, WorkRecordStatus status) {
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  return switch (status) {
    WorkRecordStatus.scheduled || WorkRecordStatus.ready => semantic.planned,
    WorkRecordStatus.enRoute ||
    WorkRecordStatus.arrived ||
    WorkRecordStatus.inProgress ||
    WorkRecordStatus.paused => semantic.current,
    WorkRecordStatus.completed || WorkRecordStatus.paid => semantic.success,
    WorkRecordStatus.needsReturnVisit => semantic.attention,
    _ => semantic.draft,
  };
}
