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
      final store = PrototypeOperationsScope.of(context);
      final confirmed = chooseTemplate
          ? null
          : buildConfirmedEstimate(_estimateInput, now: DateTime.now());
      final document = chooseTemplate
          ? estimateTemplateDocument(_estimateInput, store.companyProfile)
          : workCustomerDocument(
              confirmed!,
              store.companyProfile,
              resolveWorkDocumentCustomer(confirmed!, store.customers),
            );
      final selected = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => chooseTemplate
              ? DocumentTemplateScreen(
                  selectedId: _template,
                  document: document,
                )
              : CustomerPdfScreen(document: document),
        ),
      );
      if (mounted && chooseTemplate && selected != null) {
        _changeEstimateInput(() => _template = selected);
      }
    } on EstimateInputValidation catch (error) {
      if (mounted) _message(error.message);
    } on Object {
      if (mounted)
        _message(
          'The PDF preview could not open. Your form is still here; try again.',
        );
    }
  }
}
