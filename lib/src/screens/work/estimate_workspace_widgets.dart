part of 'estimate_workspace_screen.dart';

class _EstimateHomeSections extends StatelessWidget {
  const _EstimateHomeSections({
    required this.layout,
    required this.dateRecords,
    required this.drafts,
    required this.searchResults,
    required this.showAllDrafts,
    required this.showStatusDetails,
    required this.showTotals,
    required this.canCreate,
    required this.onOpen,
    required this.onToggleDrafts,
  });

  final OperationsWorkspaceLayout layout;
  final List<WorkRecord> dateRecords;
  final List<WorkRecord> drafts;
  final List<WorkRecord>? searchResults;
  final bool showAllDrafts;
  final bool showStatusDetails;
  final bool showTotals;
  final bool canCreate;
  final ValueChanged<WorkRecord> onOpen;
  final VoidCallback onToggleDrafts;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    if (searchResults case final results?) {
      final draftResults = results
          .where(
            (record) => record.resolvedEstimateStage == EstimateStage.draft,
          )
          .toList();
      final estimateResults = results
          .where(
            (record) => record.resolvedEstimateStage != EstimateStage.draft,
          )
          .toList();
      return OperationsLaneGrid(
        layout: layout,
        children: [
          _EstimateListSection(
            key: const ValueKey('estimate-search-drafts'),
            title: 'Draft matches',
            icon: Icons.edit_note_rounded,
            records: draftResults,
            emptyMessage: 'No draft estimates match that search.',
            headerColor: semantic.draftSurface,
            borderColor: semantic.draft,
            rowAccent: semantic.draft,
            showStatusDetails: showStatusDetails,
            showTotals: showTotals,
            onOpen: onOpen,
          ),
          _EstimateListSection(
            key: const ValueKey('estimate-search-results'),
            title: 'Estimate matches',
            icon: Icons.request_quote_outlined,
            records: estimateResults,
            emptyMessage: 'No completed or shared estimates match that search.',
            headerColor: semantic.plannedSurface,
            borderColor: semantic.planned,
            showStatusDetails: showStatusDetails,
            showTotals: showTotals,
            onOpen: onOpen,
          ),
        ],
      );
    }

    final dateSection = _EstimateListSection(
      key: const ValueKey('estimate-date-records'),
      title: 'Estimates for this date',
      icon: Icons.request_quote_outlined,
      records: dateRecords,
      emptyMessage: canCreate
          ? 'No estimates are recorded for this date. Tap New estimate to create one.'
          : 'No estimates are recorded for this date.',
      headerColor: semantic.plannedSurface,
      borderColor: semantic.planned,
      showStatusDetails: showStatusDetails,
      showTotals: showTotals,
      onOpen: onOpen,
    );
    return OperationsLaneGrid(layout: layout, children: [dateSection]);
  }
}

class _EstimateListSection extends StatelessWidget {
  const _EstimateListSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.emptyMessage,
    required this.headerColor,
    required this.borderColor,
    required this.showStatusDetails,
    required this.showTotals,
    required this.onOpen,
    this.rowAccent,

    super.key,
  });

  final String title;
  final IconData icon;
  final List<WorkRecord> records;

  final String emptyMessage;
  final Color headerColor;
  final Color borderColor;
  final bool showStatusDetails;
  final bool showTotals;
  final ValueChanged<WorkRecord> onOpen;
  final Color? rowAccent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerColor,
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
                      '${records.length}',
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
                          _EstimateRecordRow(
                            record: records[index],
                            accent: rowAccent,
                            showStatusDetails: showStatusDetails,
                            showTotals: showTotals,
                            onOpen: () => onOpen(records[index]),
                          ),
                          if (index < records.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateRecordRow extends StatelessWidget {
  const _EstimateRecordRow({
    required this.record,
    required this.showStatusDetails,
    required this.showTotals,
    required this.onOpen,
    this.accent,
  });

  final WorkRecord record;
  final bool showStatusDetails;
  final bool showTotals;
  final VoidCallback onOpen;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    final colors = Theme.of(context).colorScheme;
    final rowAccent = accent ?? _stageColor(context, stage);
    return Semantics(
      button: true,
      label: '${record.client}, ${record.title}, ${stage.label}',
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
            key: ValueKey('estimate-row-${record.id}'),
            constraints: const BoxConstraints(minHeight: 60),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 5, child: ColoredBox(color: rowAccent)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.client,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            record.title,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showTotals)
                          Text(
                            '\$${record.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        if (showStatusDetails)
                          Text(
                            stage.label,
                            style: TextStyle(
                              color: rowAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
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
}

Color _stageColor(BuildContext context, EstimateStage stage) {
  final colors = Theme.of(context).colorScheme;
  return switch (stage) {
    EstimateStage.draft ||
    EstimateStage.readyToSend ||
    EstimateStage.changesRequested ||
    EstimateStage.expired => colors.tertiary,
    EstimateStage.awaitingCustomer || EstimateStage.viewed => colors.primary,
    EstimateStage.approved || EstimateStage.converted => colors.secondary,
    EstimateStage.declined || EstimateStage.archived => colors.onSurfaceVariant,
  };
}
