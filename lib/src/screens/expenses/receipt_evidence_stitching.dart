part of 'receipt_evidence_review_screen.dart';

extension _ReceiptEvidenceStitching on _ReceiptEvidenceReviewScreenState {
  Widget _stitchControls() {
    final canCombine =
        _workflow != null &&
        _evidence.length >= 2 &&
        _evidence.length <= 8 &&
        _evidence.every((e) => e.kind == ReceiptEvidenceKind.photo);
    if (!canCombine) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For sections of one long receipt, arrange photos from top to bottom, then combine.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonal(
                key: const ValueKey('combine-receipt-sections'),
                onPressed:
                    _saving || _stitching || _readingEvidenceIds.isNotEmpty
                    ? null
                    : _combineSections,
                child: Text(
                  _stitching
                      ? 'Combining…'
                      : _stitchState?.needsRetry == true
                      ? 'Retry combining'
                      : 'Combine receipt sections',
                ),
              ),
              if (_stitchState?.attachmentId != null)
                TextButton(
                  onPressed: () =>
                      _refresh(() => _showCombined = !_showCombined),
                  child: Text(
                    _showCombined
                        ? 'Show original photos'
                        : 'Show combined receipt',
                  ),
                ),
            ],
          ),
          if (_stitchState?.stage == ReceiptStitchDraftStage.review)
            const Text(
              'The overlap is unclear. Your original photos are preserved. Review their order and shared area before retrying.',
            ),
          if (_stitchState?.needsRetry == true && !_stitching)
            Text(_stitchState!.retryGuidance),
        ],
      ),
    );
  }

  Future<void> _combineSections() async {
    final workflow = _workflow;
    if (workflow == null || _stitching || _saving) return;
    _capture();
    _refresh(() {
      _stitching = true;
      _failure = null;
    });
    try {
      await ReceiptStitchDraftWorkflow(
        workflow,
        authorize: () async {
          final session = _submission;
          if (!mounted ||
              session == null ||
              !widget.permissions.canAttachReceipt ||
              !widget.permissions.canView ||
              !widget.permissions.canViewAmounts) {
            throw StateError('Receipt access is unavailable.');
          }
          final current = (await session.receipts.findById(
            draftId: workflow.source.draftId,
          )).record;
          final permission = session.receiptPermissions;
          if (current == null ||
              current.lifecycle.revision != workflow.input.sourceRevision ||
              !permission.canTarget(current) ||
              !(permission.owns(current)
                  ? permission.canEditOwn
                  : permission.canEditTeam)) {
            throw StateError('Receipt access or evidence changed.');
          }
        },
      ).process();
      if (!mounted) return;
      _refresh(() {
        _stitchState = workflow.input.stitchState;
        _showCombined = _stitchState?.attachmentId != null;
        _combinedFile = _loadCombinedPreview();
      });
    } catch (_) {
      if (!mounted) return;
      _refresh(() {
        _stitchState = workflow.input.stitchState;
        _failure =
            'The receipt could not be combined. Your saved photos remain available.';
      });
    } finally {
      if (mounted) _refresh(() => _stitching = false);
    }
  }

  Future<String?> _loadCombinedPreview() async {
    final workflow = _workflow;
    final id = _stitchState?.attachmentId;
    final store = workflow?.session.store;
    if (workflow == null || id == null || store is! LocalDraftStore)
      return null;
    final files = await LocalAttachmentStore(store.database).verifiedFiles(
      organizationId: workflow.session.organizationId,
      ownerIds: {workflow.session.ownerId},
      attachmentIds: {id},
    );
    return files.single.path;
  }

  Widget _combinedPreview(double height) => FutureBuilder<String?>(
    future: _combinedFile,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return const Text(
          'The saved preview is unavailable. Your original photos can still be reviewed.',
        );
      final path = snapshot.data;
      if (path == null) return const Center(child: CircularProgressIndicator());
      return SizedBox(
        height: height,
        child: ReceiptPhotoPreview(
          key: ValueKey('combined-receipt-${_stitchState?.attachmentId}'),
          path: path,
          name: 'Combined receipt',
        ),
      );
    },
  );
}
