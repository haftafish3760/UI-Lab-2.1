part of 'invoice_editor_screen.dart';

extension _InvoiceEditorConfirmation on _InvoiceEditorScreenState {
  Future<void> _save() async {
    if (!_draftReady || _submitting) return;
    await _confirmDraft();
  }
}
