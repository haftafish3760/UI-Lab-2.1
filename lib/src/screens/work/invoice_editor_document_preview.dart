part of 'invoice_editor_screen.dart';

extension _InvoiceDocumentPreview on _InvoiceEditorScreenState {
  Future<void> _previewPdf() => _openDocumentPreview(chooseTemplate: false);
  Future<void> _chooseTemplate() => _openDocumentPreview(chooseTemplate: true);

  Future<void> _openDocumentPreview({required bool chooseTemplate}) async {
    if (!_draftReady || _submitting) return;
    try {
      _captureDraft();
      await _draft?.flush();
      if (!mounted) return;
      final record = buildConfirmedInvoice(_draftInput(),
        existing: widget.initialRecord, previewIncomplete: true);
      final document = workCustomerDocument(record, _store.companyProfile,
        _store.customers.where((c) => c.name == record.client).firstOrNull);
      final selected = await Navigator.of(context).push<String>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => chooseTemplate
          ? DocumentTemplateScreen(selectedId: _template, document: document)
          : CustomerPdfScreen(document: document)));
      if (mounted && chooseTemplate && selected != null) {
        _updateInput(() => _template = selected);
      }
    } on InvoiceInputValidation catch (error) {
      if (mounted) _refresh(() => _formError = error.message);
    } on Object {
      if (mounted) _refresh(() => _formError = 'The PDF preview could not open. Your form is still here; try again.');
    }
  }
}
