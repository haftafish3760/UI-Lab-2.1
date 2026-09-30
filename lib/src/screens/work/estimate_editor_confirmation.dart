part of 'estimate_editor_screen.dart';

extension _EstimateEditorConfirmation on _EstimateEditorScreenState {
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
      EstimateReviewSection.work => () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identity(customerOnly: false),
          EstimateFormField(
            inputKey: const ValueKey('estimate-work-description'),
            label: 'Work to be completed',
            controller: _scope,
            multiline: true,
          ),
        ],
      ),
      EstimateReviewSection.dates => _timingEditor,
      EstimateReviewSection.terms => _termsEditor,
      EstimateReviewSection.pricing => () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canUseEstimateServicePrice(_estimateId, _items))
            EstimateFormField(
              inputKey: const ValueKey('estimate-service-price'),
              label: context.l10n.workPriceBeforeAdjustments,
              controller: _servicePrice,
              money: true,
            )
          else
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

  Future<void> _openInitialSection() async {
    if (!mounted || !_draftReady) return;
    if (widget.openApprovalOnEntry) {
      await _confirmEstimate(recordApproval: true);
      return;
    }
    if (widget.initialSection == null) return;
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
