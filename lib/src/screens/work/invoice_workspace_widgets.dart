part of 'invoice_workspace_screen.dart';

class _InvoiceListSection extends StatelessWidget {
  const _InvoiceListSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.emptyMessage,
    required this.headerColor,
    required this.borderColor,
    required this.preferences,
    required this.showFinancials,
    required this.onOpen,
    this.totalCount,
    this.dateLabelFor,
    this.rowAccent,
    this.footer,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<WorkRecord> records;
  final int? totalCount;
  final String Function(WorkRecord)? dateLabelFor;
  final String emptyMessage;
  final Color headerColor;
  final Color borderColor;
  final Color? rowAccent;
  final WorkRecordDisplayPreferences preferences;
  final bool showFinancials;
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
                          _InvoiceRecordRow(
                            record: records[index],
                            dateLabel: dateLabelFor?.call(records[index]),
                            accent: rowAccent,
                            showStatus:
                                preferences.showStatusDetails && showFinancials,
                            showFinancials: showFinancials,
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

class _InvoiceRecordRow extends StatelessWidget {
  const _InvoiceRecordRow({
    required this.record,
    required this.showStatus,
    required this.showFinancials,
    required this.onOpen,
    this.accent,
    this.dateLabel,
  });

  final WorkRecord record;
  final bool showStatus;
  final bool showFinancials;
  final VoidCallback onOpen;
  final Color? accent;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final collectionStatus = showFinancials
        ? invoiceCollectionStatus(
            record,
            PrototypeOperationsScope.of(context).financialEntries,
            now: DateTime.now(),
          )
        : null;
    final statusLabel = collectionStatus?.localizedLabel(context.l10n) ?? '';
    final rowAccent = showFinancials
        ? accent ?? _invoiceStatusColor(context, collectionStatus!)
        : colors.outline;
    final accessible = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.35;
    return Semantics(
      button: true,
      label:
          '${record.client}, ${record.title}${showFinancials ? ', $statusLabel, ${_money(record.total)}' : ''}',
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
            key: ValueKey('invoice-row-${record.id}'),
            constraints: const BoxConstraints(minHeight: 60),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 5, child: ColoredBox(color: rowAccent)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 0, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (accessible)
                            _accessibleBody(context, rowAccent, statusLabel)
                          else
                            _compactBody(context, rowAccent, statusLabel),
                          if (dateLabel case final label?) ...[
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
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

  Widget _compactBody(
    BuildContext context,
    Color rowAccent,
    String statusLabel,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              record.number,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              record.client,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.05,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showFinancials)
            Text(
              _money(record.total),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          SizedBox(
            width: 82,
            child: showStatus
                ? Text(
                    statusLabel,
                    style: TextStyle(
                      color: rowAccent,
                      fontSize: 10.5,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              record.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _accessibleBody(
    BuildContext context,
    Color rowAccent,
    String statusLabel,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          Text(
            record.number,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (showStatus)
            Text(
              statusLabel,
              style: TextStyle(color: rowAccent, fontWeight: FontWeight.w700),
            ),
          if (showFinancials)
            Text(
              _money(record.total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
      const SizedBox(height: 3),
      Text(record.client, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(
        record.title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

Color _invoiceStatusColor(
  BuildContext context,
  InvoiceCollectionStatus status,
) {
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  return switch (status) {
    InvoiceCollectionStatus.paid => semantic.success,
    InvoiceCollectionStatus.unpaid ||
    InvoiceCollectionStatus.partiallyPaid => semantic.current,
    InvoiceCollectionStatus.draft => semantic.draft,
    _ => semantic.attention,
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
