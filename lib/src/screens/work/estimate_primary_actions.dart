part of 'estimate_detail_screen.dart';

extension _EstimatePrimaryActions on _EstimateDetailScreenState {
  Widget _actionSection(String title, List<Widget> actions) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    ),
  );

  Widget _approvalActions() {
    final work = PrototypeOperationsScope.of(context).workSession;
    final allowed =
        _record.companyReviewAllowsCustomerApproval &&
        _record.resolvedEstimateStage != EstimateStage.converted;
    return _actionSection('Customer signature and approval', [
      if (allowed &&
          widget.permissions.canCollectSignature &&
          (work == null || work.permissions.canCollectSignature))
        OutlinedButton.icon(
          onPressed: _collectSignature,
          icon: const Icon(Icons.draw_outlined),
          label: const Text('Sign in person'),
        ),
      if (allowed &&
          widget.permissions.canRecordCustomerApproval &&
          (work == null || work.permissions.canRecordCustomerApproval))
        TextButton(
          onPressed: _recordCustomerApproval,
          child: const Text('Record customer approval'),
        ),
      if (widget.permissions.canEditItems)
        TextButton(
          onPressed: () => _collectSignature(forBusiness: true),
          child: const Text('Business signature'),
        ),
    ]);
  }

  Widget _depositActions() {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (!(work?.permissions.canRecordPayments ?? false)) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: OutlinedButton.icon(
        key: const ValueKey('estimate-record-deposit'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => DirectPaymentEntryScreen(
              initialDay: DateTime.now(),
              related: _record,
            ),
          ),
        ),
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Record deposit received'),
      ),
    );
  }

  Widget _jobActions() => widget.permissions.canConvertToJob
      ? _actionSection('Next: plan the work', [
          OutlinedButton.icon(
            key: const ValueKey('estimate-primary-job'),
            onPressed: _record.resolvedEstimateStage == EstimateStage.converted
                ? null
                : _createApprovedJob,
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('Create job'),
          ),
          if (!_record.hasCurrentCustomerApproval)
            const Text(
              'Customer approval is required before creating a job. A proposed date is not a booking.',
            ),
        ])
      : const SizedBox.shrink();

  Widget _documentActions() {
    final work = PrototypeOperationsScope.of(context).workSession;
    final canSend =
        widget.permissions.canSend &&
        (work == null || work.permissions.canShareDocuments);
    return KeyedSubtree(
      key: const ValueKey('estimate-action-controls'),
      child: _actionSection('Customer copy', [
        OutlinedButton.icon(
          key: const ValueKey('estimate-primary-preview'),
          onPressed: _preview,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Preview PDF'),
        ),
        if (canSend ||
            (_record.requiresCompanyReview &&
                !_record.companyReviewAllowsCustomerApproval &&
                widget.permissions.canEditItems))
          FilledButton.icon(
            key: const ValueKey('estimate-primary-send'),
            onPressed: _reviewAndSend,
            icon: const Icon(Icons.send_outlined),
            label: Text(
              _record.requiresCompanyReview &&
                      !_record.companyReviewAllowsCustomerApproval
                  ? 'Submit for approval'
                  : _record.hasCurrentCustomerSignature
                  ? 'Send signed copy'
                  : 'Send estimate',
            ),
          ),
        if (work != null && work.canDeleteDraft(_record))
          TextButton.icon(
            key: const ValueKey('estimate-primary-delete'),
            onPressed: _deleteEstimateDraft,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete draft'),
          ),
      ]),
    );
  }

  Future<void> _reviewAndSend() async {
    if (_record.requiresCompanyReview &&
        !_record.companyReviewAllowsCustomerApproval) {
      await _submitCompanyReview();
      return;
    }
    if (!mounted) return;
    await _prepareDelivery();
  }

  Future<void> _deleteEstimateDraft() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null || !work.canDeleteDraft(_record)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete ${_record.number} for ${_record.client}?'),
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
    if (confirmed != true || !mounted) return;
    _refreshActions(() => _saving = true);
    final deleted = await work.deleteDraft(_record);
    if (!mounted) return;
    _refreshActions(() => _saving = false);
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            work.failureMessage ?? 'The draft could not be deleted.',
          ),
        ),
      );
    }
  }
}
