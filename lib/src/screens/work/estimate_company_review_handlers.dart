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
    await _update(
      _record.recordCompanyReview(
        decision: EstimateCompanyReviewDecision.approved,
        reviewedBy: 'Company reviewer',
        note: 'Revision ${_record.revision} approved for customer delivery.',
        reviewedOn: DateTime.now(),
      ),
    );
  }

  Future<void> _returnCompanyReview() =>
      _recordReviewReason(EstimateCompanyReviewDecision.changesRequested);

  Future<void> _rejectCompanyReview() =>
      _recordReviewReason(EstimateCompanyReviewDecision.rejected);

  Future<void> _recordReviewReason(
    EstimateCompanyReviewDecision decision,
  ) async {
    if (_saving || !widget.permissions.canApproveCompanyReview) return;
    final record = await showDialog<WorkRecord>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EstimateReviewReasonDialog(
        record: _record,
        decision: decision,
        permissions: widget.permissions,
      ),
    );
    if (!mounted || record == null) return;
    await _update(record);
  }

  Future<void> _submitCompanyReview() async {
    if (_record.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add labor, materials, or a flat-rate item first.'),
        ),
      );
      return;
    }
    await _update(
      _record.submitForCompanyReview(
        submittedBy: 'Estimate creator',
        submittedOn: DateTime.now(),
      ),
    );
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
