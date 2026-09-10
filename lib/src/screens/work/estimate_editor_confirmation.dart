part of 'estimate_editor_screen.dart';

extension _EstimateEditorConfirmation on _EstimateEditorScreenState {
  Future<void> _save() async {
    if (!_draftReady || _saving) return;
    await _confirmEstimate();
  }
}
