part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultWarnings on ReceiptPhotoReviewResult {
  List<String> get savedPhotoWarningCodes {
    final codes = <String>[];
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      if (warning != null) codes.add(warning.code);
    }
    return List.unmodifiable(codes);
  }

  List<String> get savedPhotoWarningSeverities {
    final severities = <String>[];
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      if (warning != null) severities.add(warning.severity.name);
    }
    return List.unmodifiable(severities);
  }

  Map<String, int> get savedPhotoWarningCounts {
    final counts = <String, int>{};
    for (final code in savedPhotoWarningCodes) {
      counts[code] = (counts[code] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get savedPhotoWarningSeverityCounts {
    final counts = <String, int>{};
    for (final severity in savedPhotoWarningSeverities) {
      counts[severity] = (counts[severity] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get savedPhotoWarningActionCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      final action = warning?.actionCode.trim();
      if (action == null || action.isEmpty) continue;
      counts[action] = (counts[action] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get savedPhotoWarningCauseCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      final cause = warning?.causeCode.trim();
      if (cause == null || cause.isEmpty) continue;
      counts[cause] = (counts[cause] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get savedPhotoParserRiskCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      final risk = warning?.parserRiskCode.trim();
      if (risk == null || risk.isEmpty) continue;
      counts[risk] = (counts[risk] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get nativeReceiptCameraSurfaceActualCounts {
    return _diagnosticValueCounts(this, 'nativeReceiptCameraSurfaceActual');
  }

  Map<String, int> get nativeReceiptCameraSurfaceVerificationCounts {
    return _diagnosticValueCounts(
      this,
      'nativeReceiptCameraSurfaceVerification',
    );
  }

  Map<String, int> get nativeCameraIdentityCounts {
    return _diagnosticValueCounts(this, 'nativeCameraIdentity');
  }

  String get nativeReceiptCameraSurfaceOutcome {
    return _firstPreferredCountKey(nativeReceiptCameraSurfaceActualCounts, [
      'maintainiac_native_android',
      'maintainiac_native_ios',
    ]);
  }

  String get nativeReceiptCameraSurfaceVerificationOutcome {
    return _firstPreferredCountKey(
      nativeReceiptCameraSurfaceVerificationCounts,
      ['maintainiac_custom_surface_verified'],
    );
  }

  String get nativeCameraIdentityOutcome {
    return _firstPreferredCountKey(nativeCameraIdentityCounts, [
      'maintainiac_in_app_receipt_camera',
    ]);
  }

  List<ReceiptNativeSavedPhotoReviewWarning> get savedPhotoReviewWarnings {
    final warnings = <ReceiptNativeSavedPhotoReviewWarning>[];
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
        diagnostics,
      );
      if (warning == null || !warning.shouldSurface) continue;
      warnings.add(warning);
    }
    return List.unmodifiable(warnings);
  }

  List<String> get savedPhotoWarningReviewActionLabels {
    final labels = <String>[];
    for (final warning in savedPhotoReviewWarnings) {
      final label = warning.primaryActionLabel.trim();
      if (label.isEmpty || labels.contains(label)) continue;
      labels.add(label);
    }
    return List.unmodifiable(labels);
  }

  String get acceptedPhotoWarningReviewActionLabel {
    final labels = savedPhotoWarningReviewActionLabels;
    if (labels.isNotEmpty) return labels.first;
    return 'Review readability before using this photo';
  }

  bool get hasSavedPhotoQualityWarning => savedPhotoWarningCodes.isNotEmpty;

  Map<String, int> get acceptedPhotoQualityOutcomeCounts {
    final counts = <String, int>{};
    void addQualityActionCounts(ReceiptPhotoQualityCheck? quality) {
      if (quality == null) return;
      final action = 'quality_action_${quality.reviewActionCode}';
      final family = 'quality_family_${quality.reviewActionFamily}';
      counts[action] = (counts[action] ?? 0) + 1;
      counts[family] = (counts[family] ?? 0) + 1;
    }

    for (final entry in captureDiagnosticsByPhotoPath.entries) {
      addQualityActionCounts(photoQualityChecksByPath[entry.key]);
      final outcome = _acceptedPhotoQualityOutcomeFor(
        quality: photoQualityChecksByPath[entry.key],
        diagnostics: entry.value,
      );
      counts[outcome] = (counts[outcome] ?? 0) + 1;
    }
    for (final entry in photoQualityChecksByPath.entries) {
      if (captureDiagnosticsByPhotoPath.containsKey(entry.key)) continue;
      addQualityActionCounts(entry.value);
      final outcome = _acceptedPhotoQualityOutcomeFor(quality: entry.value);
      counts[outcome] = (counts[outcome] ?? 0) + 1;
    }
    if (counts.isEmpty && photoPaths.isNotEmpty) {
      counts['accepted_no_quality_signal'] = photoPaths.length;
    }
    if (stitchResult.usedFallback) {
      counts['stitch_fallback_sections'] =
          (counts['stitch_fallback_sections'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  String get acceptedPhotoHandoffOutcome {
    if (keptForLater) return 'not_accepted_for_receipt_details_yet';
    if (receiptSectionOrderNeedsReview) return 'needs_review_before_ocr';
    if (ocrSourceReviewRequirement ==
        'manual_review_required_before_saving_receipt') {
      return 'needs_review_before_ocr';
    }
    final counts = acceptedPhotoQualityOutcomeCounts;
    for (final outcome in const [
      'critical_quality_retake_recommended',
      'possible_partial_receipt',
      'stitch_fallback_sections',
      'needs_review_before_ocr',
      'accepted_no_quality_signal',
      'ready_for_receipt_review',
    ]) {
      if ((counts[outcome] ?? 0) > 0) return outcome;
    }
    return 'ready_for_receipt_review';
  }

  String get acceptedPhotoWarningProfile {
    final counts = savedPhotoWarningCounts;
    for (final code in const [
      'saved_photo_brightness_assist_failed_dark',
      'saved_photo_darker_than_preview',
      'saved_photo_soft_blur_risk',
      'saved_photo_brighter_than_preview',
      'saved_photo_glare_risk',
      'saved_photo_bottom_too_dark',
      'saved_photo_bottom_soft',
      'saved_photo_dirty_lens_or_haze',
      'saved_photo_shadow_risk',
      'saved_photo_brightness_assist_still_dim',
      'saved_photo_dimmer_than_preview',
    ]) {
      if ((counts[code] ?? 0) > 0) return code;
    }
    return 'saved_photo_ok';
  }
}
