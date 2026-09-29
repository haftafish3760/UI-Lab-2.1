part of 'estimate_editor_screen.dart';

extension _EstimateEditorConfirmation on _EstimateEditorScreenState {
  Future<void> _reviewEstimate() async {
    if (!_draftReady || _saving) return;
    FocusScope.of(context).unfocus();
    _captureEstimateInput();
    _refresh(() => _saving = true);
    try {
      await _draft?.flush();
      if (!mounted) return;
      final record = buildConfirmedEstimate(
        _estimateInput,
        now: DateTime.now(),
      );
      final save = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EstimateDetailScreen(
            initialRecord: record,
            reviewBeforeSave: true,
            onEditSection: _editFromReview,
            onCustomerApproval:
                (_work?.permissions.canCollectSignature == true ||
                    _work?.permissions.canRecordCustomerApproval == true)
                ? _approvalFromReview
                : null,
            onUpdated: (_) {},
            onCreateJob: (_) {},
          ),
        ),
      );
      if (mounted) _refresh(() => _saving = false);
      if (mounted && save == true) await _confirmEstimate();
    } on EstimateInputValidation catch (error) {
      if (mounted) _message(error.message);
    } on Object {
      if (mounted) {
        _message('Review could not open. Your form is still here; try again.');
      }
    } finally {
      if (mounted && _saving) _refresh(() => _saving = false);
    }
  }

  Future<WorkRecord?> _approvalFromReview() async {
    _refresh(() => _saving = false);
    try {
      await _confirmEstimate(recordApproval: true);
      if (!mounted || _saveError != null) return null;
      return buildConfirmedEstimate(_estimateInput, now: DateTime.now());
    } finally {
      if (mounted) _refresh(() => _saving = true);
    }
  }

  Future<bool> _openReviewSection(EstimateReviewSection section) async {
    if (section == EstimateReviewSection.photos) {
      return _editSitePhotos();
    }
    if (section == EstimateReviewSection.items) {
      return _editItemCategory(
        EstimateItemCategory.all,
        _items,
        fromReview: true,
      );
    }
    final Widget Function() content = switch (section) {
      EstimateReviewSection.customer => () => _identity(customerOnly: true),
      EstimateReviewSection.work => () => _identity(customerOnly: false),
      EstimateReviewSection.dates => _timingEditor,
      EstimateReviewSection.terms => _termsEditor,
      EstimateReviewSection.pricing => () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Labor and materials: ${_currency(_subtotal)}'),
          const SizedBox(height: 16),
          DocumentAmountField(label: 'Discount', controller: _discount),
          const SizedBox(height: 16),
          DocumentAmountField(label: 'Tax', controller: _tax),
          const SizedBox(height: 16),
          Text('Estimate total: ${_currency(_total)}'),
        ],
      ),
      EstimateReviewSection.items ||
      EstimateReviewSection.photos => throw StateError('Handled above'),
    };
    return _openSectionEditor(section.label, content, fromReview: true);
  }

  Future<WorkRecord?> _editFromReview(EstimateReviewSection section) async {
    // The review route guards its own input while this nested editor is open.
    // Permit the existing draft listeners to capture section edits.
    _refresh(() => _saving = false);
    try {
      await _openReviewSection(section);
      if (!mounted) return null;
      _captureEstimateInput();
      await _draft?.flush();
      return buildConfirmedEstimate(_estimateInput, now: DateTime.now());
    } finally {
      if (mounted) _refresh(() => _saving = true);
    }
  }

  Future<void> _openInitialSection() async {
    if (!mounted || !_draftReady || widget.initialSection == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final saved = await _openReviewSection(widget.initialSection!);
    if (!mounted) return;
    if (saved) {
      await _confirmEstimate();
    } else {
      // Keep unfinished input recoverable, without updating the saved record.
      await finishDraftRoute();
    }
  }

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
