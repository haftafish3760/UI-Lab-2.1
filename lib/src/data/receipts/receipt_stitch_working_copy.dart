import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../device_capabilities/device_workload_service.dart';

class ReceiptStitchWorkingCopy {
  const ReceiptStitchWorkingCopy(this.path, this.pixels, this.encodedBytes);
  final String path;
  final int pixels, encodedBytes;

  static Future<ReceiptStitchWorkingCopy> prepare({
    required String path,
    required int maxPixels,
    required DeviceWorkloadProfile profile,
    required void Function() checkActive,
    required Future<void> Function() beforeWrite,
  }) async {
    checkActive();
    final length = await File(path).length();
    if (length > profile.maxEncodedImageBytes || length <= 0) {
      throw const DeviceWorkloadUnavailable(
        'This receipt photo exceeds the safe input size.',
      );
    }
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      checkActive();
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final originalPixels = descriptor.width * descriptor.height;
      if (originalPixels > 100000000 ||
          descriptor.width > 30000 ||
          descriptor.height > 30000) {
        throw const DeviceWorkloadUnavailable(
          'Use separate photos for this very large receipt image.',
        );
      }
      // Re-encoding also normalizes orientation before the isolated matcher.
      final ratio = math.min(1.0, math.sqrt(maxPixels / originalPixels));
      final width = math.max(1, (descriptor.width * ratio).floor());
      final height = math.max(1, (descriptor.height * ratio).floor());
      codec = await descriptor.instantiateCodec(
        targetWidth: width,
        targetHeight: height,
      );
      checkActive();
      image = (await codec.getNextFrame()).image;
      checkActive();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      checkActive();
      if (data == null || data.lengthInBytes > 4 * 1024 * 1024) {
        throw const DeviceWorkloadUnavailable(
          'The receipt working copy exceeds its storage budget.',
        );
      }
      await beforeWrite();
      checkActive();
      final directory = await Directory.systemTemp.createTemp(
        'receipt-stitch-copy-',
      );
      final output = File(
        '${directory.path}${Platform.pathSeparator}working.png',
      );
      await output.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return ReceiptStitchWorkingCopy(
        output.path,
        image.width * image.height,
        data.lengthInBytes,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
