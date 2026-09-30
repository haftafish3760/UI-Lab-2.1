part of 'estimate_editor_screen.dart';

extension _EstimateInlineApproval on _EstimateEditorScreenState {
  Widget _buildInlineApproval() {
    final access = _work?.permissions;
    if (access == null ||
        (!access.canCollectSignature && !access.canRecordCustomerApproval)) {
      return const SizedBox.shrink();
    }
    return EstimateFormSection(
      title: 'Customer signature and approval',
      child: _approving && _baseRecord != null
          ? EstimateApprovalScreen(
              key: _inlineApproval,
              record: _baseRecord!,
              embedded: true,
              onSaved: (record) async {
                await _inlineApproval.currentState?.flushInput();
                await _reopenSavedEstimate(record);
                if (mounted) {
                  _refresh(() => _approving = false);
                  _message('Customer approval saved.');
                }
              },
              onClose: () async {
                await _inlineApproval.currentState?.flushInput();
                if (mounted) _refresh(() => _approving = false);
              },
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasCurrentApproval)
                  const Text('Customer approval recorded for this estimate.')
                else
                  const Text(
                    'The customer must review the work, price, and terms before approving. They can sign here in person. For approval received by email or text, record their response and supporting evidence.',
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    key: const ValueKey('estimate-customer-approval'),
                    onPressed: !_saving && _draftReady
                        ? () => _confirmEstimate(recordApproval: true)
                        : null,
                    child: Text(
                      _hasCurrentApproval
                          ? 'View approval'
                          : 'Get customer approval',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _reopenSavedEstimate(WorkRecord record) async {
    _refresh(() => _saving = true);
    await _draftSubscription?.cancel();
    await _draft?.close();
    if (!mounted) return;
    _applyCurrentEstimate(record);
    _baseStorageRevision = _work?.storageRevisionFor(record.id) ?? 0;
    if (_work != null) {
      _workflow = await _work!.openEstimateDraft(
        creatorId: _creatorId,
        existingRecordId: record.id,
      );
      if (!mounted) {
        await _draft?.close();
        return;
      }
      _workflow!.updateInput(_estimateInput);
      await _draft!.flush();
      _draftSubscription = _draft!.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
    }
    _entryInput = canonicalJson(_estimateInput.toPayload());
    if (mounted) {
      _refresh(() {
        _saving = false;
        _saveError = null;
      });
    }
  }

  Future<void> _sendEstimate() async {
    final saved = await _confirmEstimate(keepOpen: true);
    if (!saved || !mounted || _baseRecord == null) return;
    final current = _baseRecord!;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EstimateDeliveryScreen(record: current),
      ),
    );
    if (!mounted) return;
    final latest = _work?.records.where((r) => r.id == current.id).firstOrNull;
    if (latest != null) await _reopenSavedEstimate(latest);
  }
}
