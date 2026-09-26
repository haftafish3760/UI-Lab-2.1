part of 'invoice_editor_screen.dart';

extension _InvoiceEditorConfirmation on _InvoiceEditorScreenState {
  Future<void> _save() async {
    if (!_draftReady || _submitting) return;
    await _confirmDraft();
  }

  Future<void> _createInvoice() async {
    if (!_draftReady || _submitting) return;
    try {
      final invoice = buildConfirmedInvoice(
        _draftInput(),
        existing: widget.initialRecord,
      );
      if (invoice.total <= 0) {
        throw const InvoiceInputValidation(
          'Add a positive invoice amount before creating the invoice.',
        );
      }
    } on InvoiceInputValidation catch (error) {
      _refresh(() => _formError = error.message);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create this invoice?'),
        content: const Text(
          'This adds the invoice amount to your books. It does not send the invoice to the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const ValueKey('confirm-create-invoice'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create invoice'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _confirmDraft(issue: true);
  }
}
