import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'receipt_capture_models.dart';
import 'receipt_photo_path_identity.dart';
import 'receipt_pipeline_trace.dart';
import '../receipt_stitch_acceptance.dart';
import 'receipt_native_stitch_registration.dart';
import '../receipt_stitch_text_evidence.dart';
part 'receipt_image_processor_models.dart';
part 'receipt_image_processor_source_prep.dart';
part 'receipt_image_processor_resize_helpers.dart';
part 'receipt_image_processor_stitch_search_budget.dart';
part 'receipt_image_processor_stitch_sequence_guidance.dart';
part 'receipt_image_processor_stitch_helpers.dart';
part 'receipt_image_processor_stitch_overlap_search.dart';
part 'receipt_image_processor_stitch_ambiguity.dart';
part 'receipt_image_processor_stitch_offsets.dart';
part 'receipt_image_processor_stitch_coordinate_refinement.dart';
part 'receipt_image_processor_stitch_fast_path.dart';
part 'receipt_image_processor_stitch_frame_transform.dart';
part 'receipt_image_processor_stitch_text_guidance.dart';
part 'receipt_image_processor_stitch_native_guidance.dart';
part 'receipt_image_processor_stitch_duplicate_helpers.dart';
part 'receipt_image_processor_stitch_transform_helpers.dart';
part 'receipt_image_processor_stitch_scoring_helpers.dart';
part 'receipt_image_processor_stitch_geometry_helpers.dart';
part 'receipt_image_processor_stitch_support.dart';
part 'receipt_image_processor_stitch_isolate.dart';
part 'receipt_image_processor_stitch_sources.dart';
part 'receipt_image_processor_stitch_manual_pair.dart';
part 'receipt_image_processor_stitch_api.dart';
part 'receipt_image_processor_stitch_composition.dart';
part 'receipt_image_processor_scan_helpers.dart';
part 'receipt_image_processor_perspective_helpers.dart';
part 'receipt_image_processor_enhancement_helpers.dart';
part 'receipt_image_processor_exposure_helpers.dart';
part 'receipt_image_processor_quality_helpers.dart';
part 'receipt_image_processor_storage_helpers.dart';

class ReceiptImageProcessor {
  ReceiptImageProcessor._();
  static Future<String> prepareReceiptSourceFile({
    required String path,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return (await prepareReceiptSourceWithReport(
      path: path,
      cleanupSettings: cleanupSettings,
    )).ocrSourcePath;
  }

  static Future<ReceiptImagePreparationReport> prepareReceiptSourceWithReport({
    required String path,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _prepareReceiptSourceWithReport(
      path: path,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<ReceiptPreparedImage> prepareForOcrAndBackup({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _prepareForOcrAndBackup(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<ReceiptImageStoragePreview> previewPreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _previewPreparedBackupFile(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<String> optimizePreparedBackupFile({
    required String path,
    required ReceiptDataSaverLevel level,
    ReceiptImageCleanupSettings cleanupSettings =
        const ReceiptImageCleanupSettings(),
  }) async {
    return _optimizePreparedBackupFile(
      path: path,
      level: level,
      cleanupSettings: cleanupSettings,
    );
  }

  static Future<String> cropFile({
    required Uint8List bytes,
    required Rect displayImageRect,
    required Rect cropRect,
  }) async {
    final decoded = _decodeImage(bytes);
    if (decoded == null) throw StateError('Image could not be decoded.');
    if (!_isUsableCropRect(displayImageRect) || !_isUsableCropRect(cropRect)) {
      throw StateError('Crop bounds are not usable.');
    }
    final relativeCrop = Rect.fromLTRB(
      cropRect.left - displayImageRect.left,
      cropRect.top - displayImageRect.top,
      cropRect.right - displayImageRect.left,
      cropRect.bottom - displayImageRect.top,
    );
    final scaleX = decoded.width / displayImageRect.width;
    final scaleY = decoded.height / displayImageRect.height;
    final x = (relativeCrop.left * scaleX).round().clamp(0, decoded.width - 1);
    final y = (relativeCrop.top * scaleY).round().clamp(0, decoded.height - 1);
    final right = (relativeCrop.right * scaleX).round().clamp(
      x + 1,
      decoded.width,
    );
    final bottom = (relativeCrop.bottom * scaleY).round().clamp(
      y + 1,
      decoded.height,
    );
    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
    return _writeJpg(cropped, prefix: 'crop', quality: 92);
  }

  static bool _isUsableCropRect(Rect rect) {
    return rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite &&
        rect.width > 0 &&
        rect.height > 0;
  }

  static Future<String> rotateFile({
    required String path,
    required num degrees,
  }) async {
    if (!degrees.isFinite) {
      throw StateError('Rotation angle is not usable.');
    }
    final bytes = await _readFileBytes(path);
    final decoded = bytes == null ? null : _decodeImage(bytes);
    if (decoded == null) throw StateError('Image could not be decoded.');
    final rotated = img.copyRotate(
      decoded,
      angle: degrees,
      interpolation: img.Interpolation.linear,
    );
    return _writeJpg(rotated, prefix: 'straightened', quality: 92);
  }

  static Future<String> copyReceiptOcrArtifact({
    required String path,
    String prefix = 'stitched_final',
  }) async {
    return _copyReceiptOcrArtifact(path: path, prefix: prefix);
  }

  static const _unreadableReceiptQuality = ReceiptPhotoQualityCheck(
    width: 0,
    height: 0,
    focusScore: 0,
    isLikelyReadable: false,
  );
  static Future<Uint8List?> _readFileBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  static img.Image? _decodeImage(Uint8List bytes) {
    try {
      return bytes.isEmpty ? null : img.decodeImage(bytes);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  static ReceiptImagePreparationReport _unreadableReceiptSourceReport({
    required String path,
    required String action,
    required String code,
  }) {
    return ReceiptImagePreparationReport(
      sourcePath: path,
      ocrSourcePath: path,
      originalQuality: _unreadableReceiptQuality,
      ocrQuality: _unreadableReceiptQuality,
      cleanupActions: [action],
      usedEnhancedOcrSource: false,
      scannerDecisionCodes: [code],
    );
  }

  static Future<String> optimizeFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    return _optimizeFile(path: path, level: level);
  }

  static Future<ReceiptImageStoragePreview> previewFile({
    required String path,
    required ReceiptDataSaverLevel level,
  }) async {
    return _previewFile(path: path, level: level);
  }

  static Future<ReceiptPhotoQualityCheck> qualityCheckFile(String path) async {
    return _qualityCheckFile(path);
  }

  static img.Image? decodeReceiptImageBytes(Uint8List bytes) {
    return _decodeImage(bytes);
  }

  /// Returns a conservative, non-destructive crop suggestion in source-image
  /// coordinates (0Ã¢â‚¬â€œ1). The review screen presents it for confirmation rather
  /// than changing the captured evidence on its own.
  static Rect? suggestReceiptCropNormalized(Uint8List bytes) {
    final source = _decodeImage(bytes);
    if (source == null) return null;
    return suggestReceiptCropNormalizedForDecodedImage(source);
  }

  /// Same conservative suggestion for callers that already decoded the image
  /// for display, avoiding a second decode on lower-memory devices.
  static Rect? suggestReceiptCropNormalizedForDecodedImage(img.Image source) {
    return _suggestReceiptCropNormalized(source);
  }

  static Future<ReceiptStitchResult> stitchReceiptPhotosForOcr({
    required List<String> paths,
    String? traceId,
    List<ReceiptStitchTextEvidence>? textEvidence,
    List<bool>? manualZeroOverlapPairs,
    List<int>? manualOverlapPixels,
    List<double>? manualOverlapFractions,
    List<double>? manualScaleCorrections,
    List<double>? manualRotationCorrectionsDegrees,
    List<double>? manualHorizontalOffsetFractions,
    int maxOutputPixels = 16000000,
    int maxOutputHeight = 20000,
    int maxTargetWidth = 1400,
    int comparisonWidth = 400,
    int retryComparisonWidth = 320,
    Duration? processingTimeout,
    bool Function()? shouldCancel,
    List<ReceiptNativeRegistrationProposal>? nativeRegistrationProposals,
    String timeoutReasonCode = 'stitch_timeout',
    String timeoutWarning =
        'Putting these photos together took too long. Receipt details will use them from top to bottom.',
  }) async {
    final stitchStopwatch = Stopwatch()..start();
    final evidenceByPath = <String, ReceiptStitchTextEvidence>{};
    for (final evidence
        in textEvidence ?? const <ReceiptStitchTextEvidence>[]) {
      final normalizedPath = normalizedReceiptPhotoPath(evidence.path);
      if (normalizedPath == null) continue;
      evidenceByPath[normalizedPath] = evidence;
    }
    final outputPath =
        '${Directory.systemTemp.path}/maintaniac_receipt_stitched_'
        '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final hasManualRegistration =
        manualOverlapPixels != null ||
        manualOverlapFractions != null ||
        (manualZeroOverlapPairs?.any((value) => value) ?? false);
    final resolvedNativeProposals =
        nativeRegistrationProposals ??
        (hasManualRegistration
            ? const <ReceiptNativeRegistrationProposal>[]
            : await const ReceiptNativeStitchRegistration().propose(
                paths: paths,
                comparisonWidth: comparisonWidth,
              ));
    if (traceId != null) {
      traceReceiptPipelineStage(
        'stitch_registration_ready',
        traceId: traceId,
        elapsedMs: stitchStopwatch.elapsedMilliseconds,
        sourceCount: paths.length,
        layoutLineCount: evidenceByPath.values.fold<int>(
          0,
          (total, item) => total + item.positionedLines.length,
        ),
        candidateLineCount: resolvedNativeProposals.length,
      );
    }
    final request = _ReceiptStitchRequest(
      paths: List<String>.of(paths),
      textEvidenceByPath: evidenceByPath.isEmpty
          ? null
          : [
              for (final inputPath in paths)
                ReceiptStitchTextEvidence(
                  path: inputPath,
                  lines: List<String>.of(
                    evidenceByPath[normalizedReceiptPhotoPath(inputPath)]
                            ?.lines ??
                        const <String>[],
                  ),
                  positionedLines: List<ReceiptStitchTextLineEvidence>.of(
                    evidenceByPath[normalizedReceiptPhotoPath(inputPath)]
                            ?.positionedLines ??
                        const <ReceiptStitchTextLineEvidence>[],
                  ),
                ),
            ],
      manualZeroOverlapPairs: manualZeroOverlapPairs == null
          ? null
          : List<bool>.of(manualZeroOverlapPairs),
      manualOverlapPixels: manualOverlapPixels == null
          ? null
          : List<int>.of(manualOverlapPixels),
      manualOverlapFractions: manualOverlapFractions == null
          ? null
          : List<double>.of(manualOverlapFractions),
      manualScaleCorrections: manualScaleCorrections == null
          ? null
          : List<double>.of(manualScaleCorrections),
      manualRotationCorrectionsDegrees: manualRotationCorrectionsDegrees == null
          ? null
          : List<double>.of(manualRotationCorrectionsDegrees),
      manualHorizontalOffsetFractions: manualHorizontalOffsetFractions == null
          ? null
          : List<double>.of(manualHorizontalOffsetFractions),
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      maxTargetWidth: maxTargetWidth,
      comparisonWidth: comparisonWidth,
      retryComparisonWidth: retryComparisonWidth,
      nativeRegistrationProposals: resolvedNativeProposals,
      outputPath: outputPath,
    );
    final remainingWorkerTimeout = processingTimeout == null
        ? null
        : receiptRemainingStitchWorkerTimeout(
            totalBudget: processingTimeout,
            elapsedBeforeWorker: stitchStopwatch.elapsed,
          );
    final result = await _runReceiptStitchInManagedIsolate(
      request: request,
      processingTimeout: remainingWorkerTimeout,
      timeoutReasonCode: timeoutReasonCode,
      timeoutWarning: timeoutWarning,
      shouldCancel: shouldCancel,
    );
    stitchStopwatch.stop();
    if (traceId != null) {
      traceReceiptPipelineStage(
        'stitch_finished',
        traceId: traceId,
        elapsedMs: stitchStopwatch.elapsedMilliseconds,
        sourceCount: paths.length,
        layoutLineCount: result.pairs.fold<int>(
          0,
          (total, pair) => total + pair.matchedTextLineCount,
        ),
        candidateLineCount: resolvedNativeProposals.length,
        destination: result.didStitch
            ? result.status.name
            : '${result.status.name}.${result.fallbackReasonCode}',
      );
    }
    return result;
  }
}
