part of 'estimate_editor_screen.dart';

extension _EstimateEditorActions on _EstimateEditorScreenState {
  Widget _buildEditorActions() => Padding(
    key: const ValueKey('estimate-editor-actions'),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.tonalIcon(
          key: const ValueKey('estimate-live-pdf-preview'),
          onPressed: _draftReady && !_saving ? _previewPdf : null,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Preview PDF'),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('estimate-review'),
          onPressed: _draftReady && !_saving ? _reviewEstimate : null,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Review estimate'),
        ),
        FilledButton.icon(
          key: ValueKey(
            widget.initialRecord == null
                ? 'save-estimate-draft'
                : 'save-estimate-changes',
          ),
          onPressed: _draftReady && !_saving ? _save : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save estimate'),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey('estimate-close'),
          onPressed: !_saving ? () => leaveDraftRoute() : null,
          icon: const Icon(Icons.close),
          label: const Text('Close'),
        ),
      ],
    ),
  );
}
