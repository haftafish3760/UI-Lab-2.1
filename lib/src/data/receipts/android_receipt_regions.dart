import 'dart:io';

import 'package:flutter/services.dart';

import '../device_capabilities/device_workload_service.dart';
import 'receipt_ocr_sections.dart';

/// Native region decoding avoids allocating a full long bitmap before cropping.
class AndroidReceiptRegions {
  static const channel = MethodChannel('maintainiac/receipt_regions');

  static Future<({int width, int height})> describe(
    String path,
    DeviceWorkloadProfile profile,
  ) async {
    final data = await channel.invokeMapMethod<String, dynamic>('describe', {
      'path': path,
      'maxBytes': profile.maxEncodedImageBytes,
    });
    if (data == null || data['width'] is! int || data['height'] is! int) {
      throw StateError('Invalid image dimensions.');
    }
    return (width: data['width'] as int, height: data['height'] as int);
  }

  static Future<AndroidReceiptRegion> prepare(
    String path,
    ReceiptOcrSection section,
    DeviceWorkloadProfile profile,
  ) async {
    final data = await channel.invokeMapMethod<String, dynamic>('decode', {
      'path': path,
      'maxBytes': profile.maxEncodedImageBytes,
      'maxPixels': profile.maxImagePixels,
      'top': section.top,
      'bottom': section.bottom,
      'sampleSize': section.sampleSize,
    });
    if (data == null ||
        data['path'] is! String ||
        data['width'] is! int ||
        data['height'] is! int ||
        (data['width'] as int) <= 0 ||
        (data['height'] as int) <= 0) {
      throw StateError('Invalid image section.');
    }
    return AndroidReceiptRegion(
      data['path'] as String,
      section.width / (data['width'] as int),
      section.height / (data['height'] as int),
      section.top.toDouble(),
    );
  }
}

class AndroidReceiptRegion {
  const AndroidReceiptRegion(this.path, this.scaleX, this.scaleY, this.offsetY);
  final String path;
  final double scaleX, scaleY, offsetY;

  Future<void> dispose() async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
