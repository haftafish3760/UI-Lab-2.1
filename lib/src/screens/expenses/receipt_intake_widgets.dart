part of 'receipt_intake_screen.dart';

class _ReceiptSourceCard extends StatelessWidget {
  const _ReceiptSourceCard({
    required this.evidence,
    required this.openingPicker,
    required this.onCapture,
    required this.onChoosePhotos,
    required this.onText,
    required this.pastedText,
    required this.onReview,
    required this.onRemove,
  });
  final List<ReceiptEvidenceSelection> evidence;
  final bool openingPicker;
  final VoidCallback onCapture, onChoosePhotos, onText;
  final String pastedText;
  final ValueChanged<int> onReview;
  final ValueChanged<ReceiptEvidenceSelection> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReceiptSourceChoices(
        onCamera: openingPicker ? null : onCapture,
        onPhotos: openingPicker ? null : onChoosePhotos,
        onText: openingPicker ? null : onText,
      ),
      if (pastedText.isNotEmpty) ...[
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Receipt text saved with this draft'),
              TextButton(
                onPressed: openingPicker ? null : onText,
                child: const Text('View or edit text'),
              ),
            ],
          ),
        ),
      ],
      if (openingPicker) ...[
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
      ],
      if (evidence.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          '${evidence.length} selected for review',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        for (var index = 0; index < evidence.length; index++)
          ListTile(
            key: ValueKey(
              'selected-receipt-evidence-${evidence[index].identity}',
            ),
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 34,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    evidence[index].kind == ReceiptEvidenceKind.pdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  Text('${index + 1}'),
                ],
              ),
            ),
            title: Text(evidence[index].name),
            subtitle: const Text('Tap to preview'),
            onTap: () => onReview(index),
            trailing: IconButton(
              tooltip: 'Remove ${evidence[index].name}',
              onPressed: () => onRemove(evidence[index]),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        FilledButton.icon(
          key: const ValueKey('review-selected-receipt-evidence'),
          onPressed: () => onReview(0),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Review photos and order'),
        ),
      ],
    ],
  );
}
