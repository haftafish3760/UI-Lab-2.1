part of 'work_document_preview_screen.dart';

class _PreviewDeliveryGate extends StatelessWidget {
  const _PreviewDeliveryGate({required this.record});

  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final draft = record.resolvedEstimateStage == EstimateStage.draft;
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('estimate-preview-delivery-gate'),
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft ? 'Draft preview only' : 'Company approval required',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  draft
                      ? 'Mark this revision ready before it can be sent, shared, saved, or printed.'
                      : 'An authorized company reviewer must approve this revision before it can leave the app.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerApprovalStatus extends StatelessWidget {
  const _CustomerApprovalStatus({required this.record});

  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final signature = record.customerSignature;
    final current = record.hasCurrentCustomerSignature;
    final colors = Theme.of(context).colorScheme;
    final title = current
        ? 'Customer approval is current'
        : signature == null
        ? 'Customer approval has not been recorded'
        : 'Customer approval required again';
    final detail = current
        ? 'Signed by ${signature!.signedBy} on ${MaterialLocalizations.of(context).formatMediumDate(signature.signedOn)} for revision ${signature.signedRevision}.'
        : signature == null
        ? 'Send this estimate for approval when its scope and price are ready.'
        : 'The previous signature no longer applies because the estimate items or price changed.';
    return SectionCard(
      backgroundColor: current
          ? colors.secondaryContainer
          : colors.errorContainer.withValues(alpha: .55),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            current ? Icons.verified_outlined : Icons.edit_note_outlined,
            color: current
                ? colors.onSecondaryContainer
                : colors.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentActions extends StatelessWidget {
  const _DocumentActions({required this.record, this.onEditItems});

  final WorkRecord record;
  final VoidCallback? onEditItems;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back to records'),
      ),
      if (record.kind == WorkRecordKind.estimate && onEditItems != null)
        OutlinedButton.icon(
          key: const ValueKey('edit-estimate-items'),
          onPressed: onEditItems,
          icon: const Icon(Icons.playlist_add_outlined),
          label: const Text('Edit estimate items'),
        ),
      if (record.kind == WorkRecordKind.estimate &&
          record.status == WorkRecordStatus.accepted &&
          record.hasCurrentCustomerSignature)
        FilledButton.icon(
          key: const ValueKey('preview-create-job'),
          onPressed: () =>
              Navigator.of(context).pop(WorkDocumentPreviewAction.createJob),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Create and plan job'),
        ),
    ],
  );
}

Future<void> _showPdfDeliveryOptions(
  BuildContext context,
  WorkRecord record,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PDF delivery options',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose how the final customer copy should leave the app. Nothing is sent from this review screen.',
              style: TextStyle(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in const [
              (Icons.email_outlined, 'Email PDF to customer'),
              (Icons.ios_share_outlined, 'Share from this device'),
              (Icons.save_alt_outlined, 'Save PDF copy'),
              (Icons.print_outlined, 'Print customer copy'),
            ])
              ListTile(
                leading: Icon(option.$1),
                title: Text(option.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheetContext).pop(option.$2),
              ),
          ],
        ),
      ),
    ),
  );
  if (selected == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$selected selected for ${record.number}. Nothing was sent.',
      ),
    ),
  );
}
