part of 'invoice_actions_screen.dart';

extension _InvoicePrimaryActions on InvoiceActionsScreen {
  Widget _primaryCard(BuildContext context, WorkRecord current) {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    final tone = OperationalCardPalette.plan;
    return SectionCard(
      backgroundColor: tone.start,
      borderColor: tone.start,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manage this invoice',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: tone.foreground),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (current.status == WorkRecordStatus.draft &&
                  permissions.canEditDraft)
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-edit'),
                  onPressed: () => _editDraft(context, current),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit invoice'),
                ),
              if (permissions.canPreviewCustomerCopy)
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-preview'),
                  onPressed: () => _preview(context, current),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Preview PDF'),
                ),
              if (current.status == WorkRecordStatus.draft &&
                  permissions.canIssue)
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-finalize'),
                  onPressed: () => _issue(context, current),
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Finalize invoice'),
                ),
              if (permissions.canIssue &&
                  (work?.permissions.canShareDocuments ?? false))
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-send'),
                  onPressed: () => _sendInvoice(context, current),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send invoice'),
                ),
              if (permissions.canIssue &&
                  (work?.permissions.canShareDocuments ?? false))
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-save-pdf'),
                  onPressed: () => _sendInvoice(
                    context,
                    current,
                    action: WorkPdfAction.save,
                  ),
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Save PDF copy'),
                ),
              if (current.status != WorkRecordStatus.draft &&
                  balanceCents > 0 &&
                  permissions.canRecordPayment)
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-payment'),
                  onPressed: () => _recordPayment(context, current),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record payment'),
                ),
              if (work != null && work.canDeleteDraft(current))
                FilledButton.icon(
                  key: const ValueKey('invoice-primary-delete'),
                  onPressed: () => _deleteInvoice(context, current),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete draft'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvoice(
    BuildContext context,
    WorkRecord current, {
    WorkPdfAction action = WorkPdfAction.share,
  }) async {
    try {
      if (current.status == WorkRecordStatus.draft) {
        await _issue(context, current);
      }
      if (!context.mounted) return;
      final latest = PrototypeOperationsScope.of(
        context,
      ).workRecords.where((r) => r.id == current.id).firstOrNull;
      if (latest == null || latest.status == WorkRecordStatus.draft) return;
      await deliverWorkPdf(context, latest, action);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pdfExportErrorMessage(error))));
      }
    }
  }

  Future<void> _deleteInvoice(BuildContext context, WorkRecord current) async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null || !work.canDeleteDraft(current)) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete ${current.number} for ${current.client}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final deleted = await work.deleteDraft(current);
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The draft could not be deleted. Please retry.'),
        ),
      );
    }
  }
}
