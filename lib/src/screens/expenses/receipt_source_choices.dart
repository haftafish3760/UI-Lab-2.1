import 'package:flutter/material.dart';
import 'receipt_choice_card.dart';

class ReceiptSourceChoices extends StatelessWidget {
  const ReceiptSourceChoices({
    required this.onCamera,
    required this.onPhotos,
    required this.onText,
    super.key,
  });
  final VoidCallback? onCamera, onPhotos, onText;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Choose how you want to add this receipt.'),
      const SizedBox(height: 14),
      ReceiptChoicePair(
        first: ReceiptChoiceCard(
          key: const ValueKey('receipt-source-camera'),
          title: 'Capture Photo',
          description: 'Take receipt photos, then check that they are clear.',
          icon: Icons.photo_camera_outlined,
          onTap: onCamera,
        ),
        second: ReceiptChoiceCard(
          key: const ValueKey('receipt-source-photos'),
          title: 'Upload Photos',
          description: 'Choose one or more receipt images from this device.',
          icon: Icons.photo_library_outlined,
          onTap: onPhotos,
        ),
      ),
      const SizedBox(height: 12),
      ReceiptChoicePair(
        first: const ReceiptChoiceCard(
          key: ValueKey('receipt-source-pdf'),
          title: 'Upload PDF/File',
          description: 'Not available yet.',
          icon: Icons.folder_outlined,
          onTap: null,
        ),
        second: ReceiptChoiceCard(
          key: const ValueKey('receipt-source-text'),
          title: 'Paste/Text',
          description: 'Use copied receipt text when there is no photo.',
          icon: Icons.content_paste_outlined,
          onTap: onText,
        ),
      ),
    ],
  );
}
