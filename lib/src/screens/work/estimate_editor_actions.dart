part of 'estimate_editor_screen.dart';

extension _EstimateEditorActions on _EstimateEditorScreenState {
  Widget _buildEditorActions() => Padding(
    key: const ValueKey('estimate-editor-actions'),
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_baseRecord != null && !_approving && widget.onCreateJob != null)
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    final success = await _confirmEstimate(keepOpen: true);
                    if (!success || !mounted) return;
                    final saved = _baseRecord!;
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => EstimateDetailScreen(
                          initialRecord: saved,
                          showRecordActions: true,
                          onUpdated: (_) {},
                          onCreateJob: widget.onCreateJob!,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    final latest = _work?.records
                        .where((r) => r.id == saved.id)
                        .firstOrNull;
                    if (latest != null) await _reopenSavedEstimate(latest);
                  },
            child: const Text('More estimate actions'),
          ),

        EstimateFormSection(
          title: 'Customer document',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preview the customer copy before sending. Sending saves the current estimate before opening delivery options.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _draftReady && !_saving && !_approving
                        ? _chooseTemplate
                        : null,
                    child: const Text('Choose PDF template'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('estimate-live-pdf-preview'),
                    onPressed: _draftReady && !_saving && !_approving
                        ? _previewPdf
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Preview PDF'),
                  ),
                  if (_work?.permissions.canShareDocuments == true)
                    FilledButton.icon(
                      key: const ValueKey('estimate-send'),
                      onPressed: _draftReady && !_saving && !_approving
                          ? _sendEstimate
                          : null,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Send estimate'),
                    ),
                ],
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: [
            FilledButton.icon(
              key: ValueKey(
                widget.initialRecord == null
                    ? 'save-estimate-draft'
                    : 'save-estimate-changes',
              ),
              onPressed: _draftReady && !_saving && !_approving ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save estimate'),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('estimate-close'),
              onPressed: !_saving ? () => leaveDraftRoute() : null,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ],
        ),
        if (_draft != null && !_approving)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _saving ? null : _discardEstimateDraft,
              child: Text(
                _baseRecord == null ? 'Delete draft' : 'Delete draft changes',
              ),
            ),
          ),
      ],
    ),
  );
}
