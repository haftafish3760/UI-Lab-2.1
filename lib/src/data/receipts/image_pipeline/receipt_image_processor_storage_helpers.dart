part of 'receipt_image_processor.dart';

Future<ReceiptPreparedImage> _prepareForOcrAndBackup({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final preparation =
      await ReceiptImageProcessor.prepareReceiptSourceWithReport(
        path: path,
        cleanupSettings: cleanupSettings,
      );
  final ocrSourcePath = preparation.ocrSourcePath;
  final backupPath = await ReceiptImageProcessor.optimizeFile(
    path: ocrSourcePath,
    level: level,
  );
  final quality = await ReceiptImageProcessor.qualityCheckFile(ocrSourcePath);
  return ReceiptPreparedImage(
    ocrSourcePath: ocrSourcePath,
    backupPath: backupPath,
    dataSaverLevel: level,
    quality: quality,
    preparation: preparation,
  );
}

Future<ReceiptImageStoragePreview> _previewPreparedBackupFile({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final ocrSourcePath = await ReceiptImageProcessor.prepareReceiptSourceFile(
    path: path,
    cleanupSettings: cleanupSettings,
  );
  // Working images remain evidence until an explicit confirmed deletion.
  return ReceiptImageProcessor.previewFile(path: ocrSourcePath, level: level);
}

Future<String> _optimizePreparedBackupFile({
  required String path,
  required ReceiptDataSaverLevel level,
  required ReceiptImageCleanupSettings cleanupSettings,
}) async {
  final ocrSourcePath = await ReceiptImageProcessor.prepareReceiptSourceFile(
    path: path,
    cleanupSettings: cleanupSettings,
  );
  final backupPath = await ReceiptImageProcessor.optimizeFile(
    path: ocrSourcePath,
    level: level,
  );
  return backupPath;
}

Future<String> _copyReceiptOcrArtifact({
  required String path,
  required String prefix,
}) async {
  final source = File(path);
  final target = File(
    '${Directory.systemTemp.path}/maintaniac_receipt_${prefix}_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await source.copy(target.path);
  return target.path;
}

Future<String> _optimizeFile({
  required String path,
  required ReceiptDataSaverLevel level,
}) async {
  if (level == ReceiptDataSaverLevel.original) return path;
  final decoded = await _readReceiptImageFile(path);
  if (decoded == null) return path;
  final profile = _profileFor(level);
  final output = _applyDataSaverProfile(decoded, profile);
  return _writeProofJpg(output, level: level, quality: profile.quality);
}

Future<String> _writeProofJpg(
  img.Image source, {
  required ReceiptDataSaverLevel level,
  required int quality,
}) async {
  final encoded = _encodeProofJpgToPolicy(
    source,
    level: level,
    quality: quality,
  );
  final file = File(
    '${Directory.systemTemp.path}/maintaniac_receipt_optimized_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(encoded.bytes, flush: true);
  return file.path;
}

_ReceiptProofJpegEncoding _encodeProofJpgToPolicy(
  img.Image source, {
  required ReceiptDataSaverLevel level,
  required int quality,
}) {
  final maximumBytes = level.proofTargetSizePolicy.maxBytes;
  var output = source;
  var encodedQuality = quality;
  var encoded = img.encodeJpg(output, quality: encodedQuality);
  while (maximumBytes > 0 && encoded.length > maximumBytes) {
    if (encodedQuality > 30) {
      encodedQuality -= 5;
    } else {
      final longestSide = output.width > output.height
          ? output.width
          : output.height;
      final nextLongestSide = (longestSide * .82).round();
      // The policy maximum is a hard ceiling for a saved proof. OCR already
      // read the clear source first, so a tiny proof can be rejected by the
      // readability check rather than silently exceeding its chosen budget.
      if (nextLongestSide < 160) break;
      output = _resizeToMaxSide(output, nextLongestSide);
      encodedQuality = quality > 60 ? 60 : quality;
    }
    encoded = img.encodeJpg(output, quality: encodedQuality);
  }
  return _ReceiptProofJpegEncoding(bytes: encoded, output: output);
}

Future<ReceiptImageStoragePreview> _previewFile({
  required String path,
  required ReceiptDataSaverLevel level,
}) async {
  final file = File(path);
  final originalBytes = await file.exists() ? await file.length() : 0;
  final bytes = await ReceiptImageProcessor._readFileBytes(path);
  if (bytes == null) {
    return ReceiptImageStoragePreview(
      originalBytes: 0,
      estimatedBytes: 0,
      level: level,
      quality: ReceiptImageProcessor._unreadableReceiptQuality,
    );
  }
  final decoded = ReceiptImageProcessor._decodeImage(bytes);
  if (decoded == null) {
    return ReceiptImageStoragePreview(
      originalBytes: originalBytes,
      estimatedBytes: originalBytes,
      level: level,
      quality: ReceiptImageProcessor._unreadableReceiptQuality,
    );
  }
  final profile = _profileFor(level);
  final output = _applyDataSaverProfile(decoded, profile);
  final encoded = level == ReceiptDataSaverLevel.original
      ? null
      : _encodeProofJpgToPolicy(output, level: level, quality: profile.quality);
  final savedCopy = encoded == null
      ? output
      : ReceiptImageProcessor._decodeImage(encoded.bytes) ?? encoded.output;
  return ReceiptImageStoragePreview(
    originalBytes: originalBytes,
    estimatedBytes: encoded?.bytes.length ?? originalBytes,
    level: level,
    quality: _qualityCheck(savedCopy),
  );
}

Future<ReceiptPhotoQualityCheck> _qualityCheckFile(String path) async {
  final decoded = await _readReceiptImageFile(path);
  if (decoded == null) {
    return ReceiptImageProcessor._unreadableReceiptQuality;
  }
  return _qualityCheck(decoded);
}

Future<img.Image?> _readReceiptImageFile(String path) async {
  final bytes = await ReceiptImageProcessor._readFileBytes(path);
  if (bytes == null) return null;
  return ReceiptImageProcessor._decodeImage(bytes);
}

img.Image _applyDataSaverProfile(img.Image source, _DataSaverProfile profile) {
  var output = _resizeToMaxSide(source, profile.maxLongSide);
  if (profile.grayscale) {
    output = img.grayscale(output);
    output = img.contrast(output, contrast: profile.contrast);
  }
  return output;
}

class _ReceiptProofJpegEncoding {
  const _ReceiptProofJpegEncoding({required this.bytes, required this.output});

  final Uint8List bytes;
  final img.Image output;
}
