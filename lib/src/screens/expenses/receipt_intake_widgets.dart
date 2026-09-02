part of 'receipt_intake_screen.dart';

class _ReceiptSourceCard extends StatelessWidget {
  const _ReceiptSourceCard({
    required this.evidence,
    required this.openingPicker,
    required this.showEvidenceReminders,
    required this.onCapture,
    required this.onChoosePhotos,
    required this.onChooseFiles,
    required this.onManualEntry,
    required this.onReview,
    required this.onRemove,
  });

  final List<ReceiptEvidenceSelection> evidence;
  final bool openingPicker;
  final bool showEvidenceReminders;
  final VoidCallback onCapture;
  final VoidCallback onChoosePhotos;
  final VoidCallback onChooseFiles;
  final VoidCallback onManualEntry;
  final ValueChanged<int> onReview;
  final ValueChanged<ReceiptEvidenceSelection> onRemove;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose receipt source',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        if (showEvidenceReminders)
          const Text('Add the receipt images or file you want to review.'),
        const SizedBox(height: 12),
        _SourceButton(
          key: const ValueKey('manual-receipt-entry'),
          icon: Icons.edit_note_rounded,
          label: 'Enter receipt manually',
          detail: 'Type the store, totals, and every item you need to keep.',
          onPressed: openingPicker ? null : onManualEntry,
        ),
        const SizedBox(height: 8),
        _SourceButton(
          icon: Icons.photo_camera_outlined,
          label: 'Capture receipt photos',
          detail: 'Use the camera with overlap guides for long receipts.',
          onPressed: openingPicker ? null : onCapture,
        ),
        const SizedBox(height: 8),
        _SourceButton(
          icon: Icons.photo_library_outlined,
          label: 'Choose existing photos',
          detail: 'Select and order one or more receipt images.',
          onPressed: openingPicker ? null : onChoosePhotos,
        ),
        const SizedBox(height: 8),
        _SourceButton(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Choose a receipt file',
          detail:
              'Import a supported image or PDF without changing the original.',
          onPressed: openingPicker ? null : onChooseFiles,
        ),
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
              subtitle: showEvidenceReminders
                  ? const Text('Original evidence retained for review')
                  : null,
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
    ),
  );
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.all(12),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReceiptReviewSteps extends StatelessWidget {
  const _ReceiptReviewSteps();

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before anything is saved',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const _ReviewStep(
          number: '1',
          text: 'Review photo order and the original receipt image.',
        ),
        const _ReviewStep(
          number: '2',
          text: 'Check vendor, date, tax, total, and every extracted line.',
        ),
        const _ReviewStep(
          number: '3',
          text:
              'Assign lines to one job, several jobs, inventory, or business expense.',
        ),
        const _ReviewStep(
          number: '4',
          text:
              'Confirm the reviewed records. Receipt Assistant suggestions do not change anything before then.',
        ),
      ],
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 13, child: Text(number)),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
