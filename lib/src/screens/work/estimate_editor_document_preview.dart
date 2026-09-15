part of 'estimate_editor_screen.dart';

extension _EstimateDocumentPreview on _EstimateEditorScreenState {
  Future<void> _previewPdf() => _openDocumentPreview(chooseTemplate: false);
  Future<void> _chooseTemplate() => _openDocumentPreview(chooseTemplate: true);

  Future<void> _openDocumentPreview({required bool chooseTemplate}) async {
    if (!_draftReady || _saving) return;
    try {
      _captureEstimateInput();
      await _draft?.flush();
      if (!mounted) return;
      // This is the same construction used when the form is confirmed, without
      // confirming or issuing a record as a side effect of viewing it.
      final record = buildConfirmedEstimate(_estimateInput, now: DateTime.now());
      final store = PrototypeOperationsScope.of(context);
      final document = workCustomerDocument(record, store.companyProfile,
        store.customers.where((c) => c.name == record.client).firstOrNull);
      final selected = await Navigator.of(context).push<String>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => chooseTemplate
          ? DocumentTemplateScreen(selectedId: _template, document: document)
          : CustomerPdfScreen(document: document)));
      if (mounted && chooseTemplate && selected != null) {
        _changeEstimateInput(() => _template = selected);
      }
    } on EstimateInputValidation catch (error) {
      if (mounted) _message(error.message);
    } on Object {
      if (mounted) _message('The PDF preview could not open. Your form is still here; try again.');
    }
  }
}
