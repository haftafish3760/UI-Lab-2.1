part of 'receipt_evidence_review_screen.dart';

class _EvidencePreviewPane extends StatelessWidget {
  const _EvidencePreviewPane({
    required this.evidence,
    required this.selectedIndex,
    required this.evidenceCount,
    required this.height,
  });

  final ReceiptEvidenceSelection? evidence;
  final int selectedIndex;
  final int evidenceCount;
  final double height;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          evidence == null
              ? 'No receipt evidence selected'
              : 'Item ${selectedIndex + 1} of $evidenceCount',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (evidence case final item?) ...[
          const SizedBox(height: 2),
          Text(item.name),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: item.kind == ReceiptEvidenceKind.photo
                ? ReceiptPhotoPreview(
                    path: item.path,
                    name: item.name,
                    key: ValueKey('receipt-evidence-preview-${item.identity}'),
                  )
                : LocalDocumentPreview(
                    key: ValueKey('receipt-evidence-preview-${item.identity}'),
                    path: item.path,
                    kind: item.kind == ReceiptEvidenceKind.pdf
                        ? LocalDocumentKind.pdf
                        : LocalDocumentKind.image,
                    semanticsLabel: 'Preview of ${item.name}',
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pinch, scroll, or drag to inspect the original.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.kind == ReceiptEvidenceKind.photo)
            ReceiptPhotoTextPanel(
              key: ValueKey(item.identity),
              path: item.path,
            ),
        ],
      ],
    ),
  );
}

class _EvidenceOrderPanel extends StatelessWidget {
  const _EvidenceOrderPanel({
    required this.evidence,
    required this.selectedIndex,
    required this.onSelect,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onRemove,
  });

  final List<ReceiptEvidenceSelection> evidence;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onMoveEarlier;
  final ValueChanged<int> onMoveLater;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Receipt order', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(
          evidence.isEmpty
              ? 'Return to receipt sources to add an image or PDF.'
              : 'Select an item to preview it. Use the labeled controls to change photo order.',
        ),
        if (evidence.isNotEmpty) const SizedBox(height: 10),
        for (var index = 0; index < evidence.length; index++) ...[
          _EvidenceOrderRow(
            key: ValueKey('receipt-evidence-order-${evidence[index].identity}'),
            evidence: evidence[index],
            position: index + 1,
            isSelected: index == selectedIndex,
            canMoveEarlier: index > 0,
            canMoveLater: index < evidence.length - 1,
            onSelect: () => onSelect(index),
            onMoveEarlier: () => onMoveEarlier(index),
            onMoveLater: () => onMoveLater(index),
            onRemove: () => onRemove(index),
          ),
          if (index < evidence.length - 1) const SizedBox(height: 8),
        ],
      ],
    ),
  );
}

class _EvidenceOrderRow extends StatelessWidget {
  const _EvidenceOrderRow({
    required this.evidence,
    required this.position,
    required this.isSelected,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onSelect,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onRemove,
    super.key,
  });

  final ReceiptEvidenceSelection evidence;
  final int position;
  final bool isSelected;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onSelect;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: isSelected,
    button: true,
    label: 'Receipt item $position, ${evidence.name}',
    child: Material(
      color: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    evidence.kind == ReceiptEvidenceKind.pdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$position. ${evidence.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          evidence.kind == ReceiptEvidenceKind.pdf
                              ? 'PDF document'
                              : 'Receipt photo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: canMoveEarlier ? onMoveEarlier : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Earlier'),
                  ),
                  TextButton.icon(
                    onPressed: canMoveLater ? onMoveLater : null,
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Later'),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.hasEvidence,
    required this.onSave,
    required this.onContinue,
  });

  final bool hasEvidence;
  final VoidCallback onSave;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 10,
    runSpacing: 8,
    children: [
      OutlinedButton(onPressed: onSave, child: const Text('Save order')),
      FilledButton.icon(
        onPressed: hasEvidence ? onContinue : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue to receipt details'),
      ),
    ],
  );
}
