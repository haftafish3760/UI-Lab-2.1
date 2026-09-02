part of 'estimate_detail_screen.dart';

extension _EstimateCompanyReviewHandlers on _EstimateDetailScreenState {
  Future<void> _approveCompanyReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve for sending?'),
        content: Text(
          'This approves revision ${_record.revision} for customer delivery. '
          'It does not record customer acceptance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-company-approval'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve for sending'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _update(
      _record.recordCompanyReview(
        decision: EstimateCompanyReviewDecision.approved,
        reviewedBy: 'Company reviewer',
        note: 'Revision ${_record.revision} approved for customer delivery.',
        reviewedOn: DateTime.now(),
      ),
    );
  }

  Future<void> _returnCompanyReview() async {
    final reason = await _requestCompanyReviewReason(
      title: 'Return for changes',
      prompt: 'Tell the estimate creator exactly what needs to change.',
      actionLabel: 'Return estimate',
    );
    if (!mounted || reason == null) return;
    _update(
      _record.recordCompanyReview(
        decision: EstimateCompanyReviewDecision.changesRequested,
        reviewedBy: 'Company reviewer',
        note: reason,
        reviewedOn: DateTime.now(),
      ),
    );
  }

  Future<void> _rejectCompanyReview() async {
    final reason = await _requestCompanyReviewReason(
      title: 'Reject estimate',
      prompt:
          'Explain why this estimate must not be sent. The record will be retained.',
      actionLabel: 'Reject estimate',
    );
    if (!mounted || reason == null) return;
    _update(
      _record.recordCompanyReview(
        decision: EstimateCompanyReviewDecision.rejected,
        reviewedBy: 'Company reviewer',
        note: reason,
        reviewedOn: DateTime.now(),
      ),
    );
  }

  void _submitCompanyReview() {
    if (_record.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add labor, materials, or a flat-rate item first.'),
        ),
      );
      return;
    }
    _update(
      _record.submitForCompanyReview(
        submittedBy: 'Estimate creator',
        submittedOn: DateTime.now(),
      ),
    );
  }

  Future<String?> _requestCompanyReviewReason({
    required String title,
    required String prompt,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const ValueKey('company-review-reason'),
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Reason',
              helperText: prompt,
              alignLabelWithHint: true,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a clear reason.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-company-review-decision'),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(controller.text.trim());
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }

  void _showCompanyReviewRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'An authorized company reviewer must approve this revision first.',
        ),
      ),
    );
  }
}
