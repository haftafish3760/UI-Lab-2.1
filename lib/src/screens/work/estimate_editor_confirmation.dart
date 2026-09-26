part of 'estimate_editor_screen.dart';

extension _EstimateEditorConfirmation on _EstimateEditorScreenState {
  bool get _hasCurrentApproval {
    try {
      return buildConfirmedEstimate(
        _estimateInput,
        now: DateTime.now(),
      ).hasCurrentCustomerApproval;
    } on EstimateInputValidation {
      return false;
    }
  }

  Future<void> _save() async {
    if (!_draftReady || _saving) return;
    await _confirmEstimate();
  }
}
