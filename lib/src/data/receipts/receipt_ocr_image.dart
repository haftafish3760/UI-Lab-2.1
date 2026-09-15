import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../device_capabilities/device_workload_service.dart';

/// One bounded, temporary OCR copy. The retained original is never changed.
class ReceiptOcrImage {
  ReceiptOcrImage(this.path, this.scaleX, this.scaleY, this._directory);
  final String path;
  final double scaleX;
  final double scaleY;
  final Directory _directory;

  Future<void> dispose() async {
    if (await _directory.exists()) await _directory.delete(recursive: true);
  }

  static Future<ReceiptOcrImage> prepare(
    String path,
    DeviceWorkloadProfile profile, {
    void Function()? checkActive,
  }) async {
    checkActive?.call();
    if (await File(path).length() > profile.maxEncodedImageBytes) {
      throw const DeviceWorkloadUnavailable(
        'This photo is too large to read safely on this device. Try a smaller photo or enter the details manually.',
      );
    }
    checkActive?.call();
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    Directory? temporary;
    try {
      checkActive?.call();
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      checkActive?.call();
      final pixels = descriptor.width * descriptor.height;
      // Reject extreme dimensions before asking a codec for decoded pixels.
      if (pixels > 100000000 ||
          descriptor.width > 30000 ||
          descriptor.height > 30000) {
        throw const DeviceWorkloadUnavailable(
          'This image is too large to read safely. Use separate photos for each section of a long receipt.',
        );
      }
      final ratio = math.min(1.0, math.sqrt(profile.maxImagePixels / pixels));
      final width = math.max(1, (descriptor.width * ratio).floor());
      final height = math.max(1, (descriptor.height * ratio).floor());
      codec = await descriptor.instantiateCodec(
        targetWidth: width,
        targetHeight: height,
      );
      checkActive?.call();
      image = (await codec.getNextFrame()).image;
      checkActive?.call();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      checkActive?.call();
      if (bytes == null) throw StateError('Image conversion failed.');
      temporary = await Directory.systemTemp.createTemp('receipt-ocr-');
      checkActive?.call();
      final target = File(
        '${temporary.path}${Platform.pathSeparator}photo.png',
      );
      await target.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      checkActive?.call();
      return ReceiptOcrImage(
        target.path,
        descriptor.width / width,
        descriptor.height / height,
        temporary,
      );
    } catch (_) {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete(recursive: true);
      }
      rethrow;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
