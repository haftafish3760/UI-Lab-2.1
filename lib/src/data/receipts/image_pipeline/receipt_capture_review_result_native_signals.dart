part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNativeSignals on ReceiptPhotoReviewResult {
  String get nativeReceiptReviewDepth {
    var sawPricesOnly = false;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final value = _normalizedNativeReceiptReviewDepth(
        diagnostics['reviewDepth'],
      );
      if (value == 'detailedLines') return 'detailedLines';
      if (value == 'pricesOnly') sawPricesOnly = true;
    }
    if (sawPricesOnly) return 'pricesOnly';
    return 'pricesOnly';
  }

  Map<String, int> get nativeReceiptReviewDepthCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final raw = diagnostics['reviewDepth']?.toString().trim();
      if (raw == null || raw.isEmpty) continue;
      final normalized = _normalizedNativeReceiptReviewDepth(raw);
      if (normalized != null) {
        counts[normalized] = (counts[normalized] ?? 0) + 1;
        continue;
      }
      counts['invalid_review_depth'] =
          (counts['invalid_review_depth'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoActionCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true) continue;
      final token = _normalizedPhotoEditAction(diagnostics['photoEditAction']);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoSourceSelectionCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true) continue;
      final token = diagnostics['photoEditReplacedOriginal'] == true
          ? 'edited_copy_selected'
          : 'accepted_source_retained';
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get editedPhotoReplacedOriginalCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (diagnostics['userEditedPhoto'] != true ||
          diagnostics['photoEditReplacedOriginal'] != true) {
        continue;
      }
      final token = _normalizedPhotoEditAction(diagnostics['photoEditAction']);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get captureReadinessCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final token = _diagnosticToken(
        diagnostics[ReceiptCaptureDiagnosticKeys.captureReadinessCode]
                ?.toString() ??
            '',
      );
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  int get manualCaptureAllowedCount {
    var count = 0;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(
            diagnostics[ReceiptCaptureDiagnosticKeys.manualCaptureAllowed],
          ) ==
          true) {
        count += 1;
      }
    }
    return count;
  }

  int get autoCaptureAllowedCount {
    var count = 0;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(
            diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureAllowed],
          ) ==
          true) {
        count += 1;
      }
    }
    return count;
  }

  Map<String, int> get nativeCameraUiHealthCounts {
    final counts = <String, int>{};
    final resultProvesReceiptDetailsHandoff =
        acceptedPhotoHandoffMustOpenReceiptDetails &&
        acceptedPhotoHandoffRoute == 'photo_review_accepted_to_receipt_details';
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final controlSet = diagnostics['visibleControlSet']?.toString().trim();
      final previewTarget = diagnostics['previewDominanceTarget']
          ?.toString()
          .trim();
      final hasNativeTransitionContract =
          diagnostics.containsKey('nativeCaptureReviewTransitionPolicy') ||
          diagnostics.containsKey('nativeCaptureReviewTransitionTarget') ||
          diagnostics.containsKey('nativeCaptureReviewDiscardPolicy');
      for (final parityCode in _nativeCapturePreviewParityHealthCodes(
        diagnostics,
      )) {
        counts[parityCode] = (counts[parityCode] ?? 0) + 1;
      }
      for (final closeCode in _nativeCloseHealthCodes(diagnostics)) {
        counts[closeCode] = (counts[closeCode] ?? 0) + 1;
      }
      for (final readinessCode in _nativeControlReadinessHealthCodes(
        diagnostics,
      )) {
        counts[readinessCode] = (counts[readinessCode] ?? 0) + 1;
      }
      for (final latencyCode in _nativeCaptureLatencyHealthCodes(diagnostics)) {
        counts[latencyCode] = (counts[latencyCode] ?? 0) + 1;
      }
      if (hasNativeTransitionContract || !resultProvesReceiptDetailsHandoff) {
        for (final transitionCode in _nativeCaptureReviewTransitionHealthCodes(
          diagnostics,
        )) {
          counts[transitionCode] = (counts[transitionCode] ?? 0) + 1;
        }
      }
      for (final openingCode in _receiptReviewOpeningHealthCodes(diagnostics)) {
        counts[openingCode] = (counts[openingCode] ?? 0) + 1;
      }
      for (final exposureCode in _nativeExposureControlHealthCodes(
        diagnostics,
      )) {
        counts[exposureCode] = (counts[exposureCode] ?? 0) + 1;
      }
      for (final focusCode in _nativeFocusReadabilityHealthCodes(diagnostics)) {
        counts[focusCode] = (counts[focusCode] ?? 0) + 1;
      }
      if ((controlSet == null || controlSet.isEmpty) &&
          (previewTarget == null || previewTarget.isEmpty)) {
        continue;
      }
      final controlCode = _nativeControlSetHealthCode(controlSet);
      final previewCode = previewTarget == 'receipt_preview_75_80_percent'
          ? 'preview_dominance_expected'
          : 'preview_dominance_missing';
      counts[controlCode] = (counts[controlCode] ?? 0) + 1;
      counts[previewCode] = (counts[previewCode] ?? 0) + 1;
      for (final settingsCode in _nativeSettingsControlHealthCodes(
        diagnostics,
        controlSet,
      )) {
        counts[settingsCode] = (counts[settingsCode] ?? 0) + 1;
      }
    }
    if (resultProvesReceiptDetailsHandoff) {
      counts['native_capture_review_transition_ready'] =
          (counts['native_capture_review_transition_ready'] ?? 0) + 1;
      counts['native_capture_review_target_receipt_details'] =
          (counts['native_capture_review_target_receipt_details'] ?? 0) + 1;
      counts['native_capture_review_discard_protected'] =
          (counts['native_capture_review_discard_protected'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get nativeCloseCapturedPhotoOutcomeCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final outcome = diagnostics['closeCapturedPhotoOutcome']
          ?.toString()
          .trim();
      if (outcome == null || outcome.isEmpty) continue;
      final token = _diagnosticToken(outcome);
      if (token == 'unknown') continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }
}

String? _normalizedNativeReceiptReviewDepth(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  final normalized = raw.replaceAll(RegExp(r'[\s_-]+'), '').toLowerCase();
  return switch (normalized) {
    'detailedlines' => 'detailedLines',
    'pricesonly' => 'pricesOnly',
    _ => null,
  };
}

String _normalizedPhotoEditAction(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return 'manual_edit';
  final token = _diagnosticToken(raw);
  return switch (token) {
    'manual_crop' ||
    'manual_rotate' ||
    'manual_edit' ||
    'auto_crop' ||
    'auto_rotate' ||
    'perspective_correction' ||
    'deskew' ||
    'brightness_cleanup' ||
    'contrast_cleanup' ||
    'shadow_cleanup' ||
    'grayscale_cleanup' => token,
    _ => 'invalid_photo_edit_action',
  };
}
