import '../device_capabilities/device_workload_service.dart';
import 'android_receipt_regions.dart';
import 'receipt_ocr_sections.dart';
import 'receipt_photo_text.dart';

/// Sequential ownership: one derived file and native recognition at a time.
/// An exception rejects the whole read, including already-completed sections.
Future<ReceiptPhotoText> readReceiptSectionSequence({
  required List<ReceiptOcrSection> sections,
  required Future<AndroidReceiptRegion> Function(ReceiptOcrSection) prepare,
  required Future<ReceiptPhotoText> Function(String) recognize,
  required bool Function() expired,
}) async {
  void requireActive() {
    if (expired()) {
      throw const DeviceWorkloadUnavailable(
        'Reading stopped. Try shorter receipt sections or enter the details yourself.',
      );
    }
  }

  final results = <ReceiptPhotoText>[];
  for (final section in sections) {
    requireActive();
    final image = await prepare(section);
    try {
      requireActive();
      final result = await recognize(image.path);
      requireActive();
      results.add(
        ReceiptPhotoText(
          text: result.text,
          warnings: result.warnings,
          lines: [
            for (final line in result.lines)
              ReceiptTextLine(
                line.text,
                line.left * image.scaleX,
                line.top * image.scaleY + image.offsetY,
                line.right * image.scaleX,
                line.bottom * image.scaleY + image.offsetY,
              ),
          ],
        ),
      );
    } finally {
      await image.dispose();
    }
  }
  requireActive();
  return mergeReceiptSectionText(results);
}
