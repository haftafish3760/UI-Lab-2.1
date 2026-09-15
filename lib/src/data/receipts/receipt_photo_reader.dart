import 'dart:io';
import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../device_capabilities/device_workload_service.dart';
import 'receipt_ocr_image.dart';
import 'android_receipt_regions.dart';
import 'receipt_ocr_sections.dart';

import 'receipt_photo_text.dart';
import 'receipt_section_reader.dart';
import 'receipt_single_photo_reader.dart';
import 'receipt_read_cancellation.dart';

export 'receipt_photo_text.dart';

abstract interface class ReceiptPhotoReader {
  bool get supported;
  Future<ReceiptPhotoText> read(String path);
}

/// Native, bundled Latin recognition. No cloud, stitching, or PDF operations.
class NativeReceiptPhotoReader implements ReceiptPhotoReader {
  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<ReceiptPhotoText> read(String path) async {
    if (!supported) {
      throw UnsupportedError('Photo reading requires Android or iOS.');
    }
    if (!await File(path).exists()) {
      throw const FileSystemException('The receipt photo is unavailable.');
    }
    // Timeout releases the UI, not the shared gate. The underlying operation
    // retains its slot until native recognition and resource cleanup finish.
    var expired = false;
    return DeviceWorkloadService.instance
        .run((profile) => _readBounded(path, profile, () => expired))
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            expired = true;
            throw const DeviceWorkloadUnavailable(
              'Reading is taking longer than expected. You can continue manually. Try again after the current read finishes.',
            );
          },
        );
  }

  Future<ReceiptPhotoText> _readBounded(
    String path,
    DeviceWorkloadProfile profile,
    bool Function() expired,
  ) async {
    requireReceiptReadActive(expired);
    if (Platform.isAndroid) {
      final size = await AndroidReceiptRegions.describe(path, profile);
      requireReceiptReadActive(expired);
      if (size.height >= size.width * 3) {
        return _readSections(path, profile, size.width, size.height, expired);
      }
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await readReceiptSinglePhoto(
        prepare: () => ReceiptOcrImage.prepare(
          path,
          profile,
          checkActive: () => requireReceiptReadActive(expired),
        ),
        recognize: (path) => _recognizePhoto(recognizer, path),
        expired: expired,
      );
    } finally {
      await recognizer.close();
    }
  }

  Future<ReceiptPhotoText> _readSections(
    String path,
    DeviceWorkloadProfile profile,
    int width,
    int height,
    bool Function() expired,
  ) async {
    final sections = planReceiptOcrSections(
      width,
      height,
      profile.maxImagePixels,
    );
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await readReceiptSectionSequence(
        sections: sections,
        expired: expired,
        prepare: (section) async {
          final current = await DeviceWorkloadService.instance.checkpoint();
          requireReceiptReadActive(expired);
          if (current.maxImagePixels <
                  section.decodedWidth * section.decodedHeight ||
              current.maxEncodedImageBytes < profile.maxEncodedImageBytes) {
            throw const DeviceWorkloadUnavailable(
              'Your device needs a lighter read. Try again after it has recovered.',
            );
          }
          return AndroidReceiptRegions.prepare(path, section, current);
        },
        recognize: (path) => _recognizePhoto(recognizer, path),
      );
    } finally {
      await recognizer.close();
    }
  }

  Future<ReceiptPhotoText> _recognizePhoto(
    TextRecognizer recognizer,
    String path,
  ) async {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return ReceiptPhotoText(
      text: result.text,
      lines: [
        for (final block in result.blocks)
          for (final line in block.lines)
            ReceiptTextLine(
              line.text,
              line.boundingBox.left,
              line.boundingBox.top,
              line.boundingBox.right,
              line.boundingBox.bottom,
            ),
      ],
    );
  }
}
