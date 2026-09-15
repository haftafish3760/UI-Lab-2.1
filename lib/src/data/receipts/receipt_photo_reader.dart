import 'dart:io';
import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../device_capabilities/device_workload_service.dart';
import 'receipt_ocr_image.dart';

/// Observations from one source image. Never a confirmed expense or stock item.
class ReceiptPhotoText {
  ReceiptPhotoText({required this.text, required List<ReceiptTextLine> lines})
    : lines = List.unmodifiable(lines);

  final String text;
  final List<ReceiptTextLine> lines;
}

class ReceiptTextLine {
  const ReceiptTextLine(
    this.text,
    this.left,
    this.top,
    this.right,
    this.bottom,
  );
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

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
    return DeviceWorkloadService.instance
        .run((profile) => _readBounded(path, profile))
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw const DeviceWorkloadUnavailable(
            'Reading is taking longer than expected. You can continue manually. Try again after the current read finishes.',
          ),
        );
  }

  Future<ReceiptPhotoText> _readBounded(
    String path,
    DeviceWorkloadProfile profile,
  ) async {
    final image = await ReceiptOcrImage.prepare(path, profile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return ReceiptPhotoText(
        text: result.text,
        lines: [
          for (final block in result.blocks)
            for (final line in block.lines)
              ReceiptTextLine(
                line.text,
                line.boundingBox.left * image.scaleX,
                line.boundingBox.top * image.scaleY,
                line.boundingBox.right * image.scaleX,
                line.boundingBox.bottom * image.scaleY,
              ),
        ],
      );
    } finally {
      try {
        await recognizer.close();
      } finally {
        await image.dispose();
      }
    }
  }
}
