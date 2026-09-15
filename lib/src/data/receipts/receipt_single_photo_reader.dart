import 'receipt_ocr_image.dart';
import 'receipt_photo_text.dart';
import 'receipt_read_cancellation.dart';

/// Owns the temporary photo through recognition, including late native replies.
/// The caller owns the recognizer and keeps the workload gate through cleanup.
Future<ReceiptPhotoText> readReceiptSinglePhoto({
  required Future<ReceiptOcrImage> Function() prepare,
  required Future<ReceiptPhotoText> Function(String) recognize,
  required bool Function() expired,
}) async {
  requireReceiptReadActive(expired);
  final image = await prepare();
  try {
    requireReceiptReadActive(expired);
    final result = await recognize(image.path);
    requireReceiptReadActive(expired);
    return ReceiptPhotoText(
      text: result.text,
      warnings: result.warnings,
      lines: [
        for (final line in result.lines)
          ReceiptTextLine(
            line.text,
            line.left * image.scaleX,
            line.top * image.scaleY,
            line.right * image.scaleX,
            line.bottom * image.scaleY,
          ),
      ],
    );
  } finally {
    await image.dispose();
  }
}
