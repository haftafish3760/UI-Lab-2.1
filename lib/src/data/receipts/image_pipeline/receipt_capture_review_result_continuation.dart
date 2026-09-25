part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultContinuation on ReceiptPhotoReviewResult {
  int get savedBackupPhotoCount => photoPaths.length;

  int get ocrSourcePhotoCount => ocrSourcePhotoPaths.length;

  bool get hasSavedBackupPhotos => savedBackupPhotoCount > 0;

  bool get hasOcrSourcePhotos => ocrSourcePhotoCount > 0;

  bool get hasReceiptReaderHandoff =>
      hasSavedBackupPhotos && hasOcrSourcePhotos;

  bool get hasReceiptDetailsHandoff => hasReceiptReaderHandoff;

  bool get keptForLater =>
      outcome == ReceiptPhotoReviewOutcome.saveDraftAndExit;

  bool get hasPreviousSectionContinuationRequest =>
      receiptContinuationSignalCounts.isNotEmpty;

  bool get hasOcrRequestedBottomSectionContinuation =>
      (receiptContinuationSignalCounts['ocr_requested_bottom_section'] ?? 0) >
          0 ||
      (receiptContinuationSignalCounts['missing_bottom_edge_and_totals_continuation'] ??
              0) >
          0;

  String get receiptContinuationHandoffStatus {
    if (hasOcrRequestedBottomSectionContinuation) {
      return 'ocr_requested_bottom_section_continuation';
    }
    if (hasPreviousSectionContinuationRequest) {
      return 'review_requested_continuation';
    }
    return 'no_continuation_request';
  }

  Map<String, int> get receiptContinuationSignalCounts {
    final counts = <String, int>{};
    void add(String key) {
      counts[key] = (counts[key] ?? 0) + 1;
    }

    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(diagnostics['previousSectionGuideRequested']) ==
              true ||
          _diagnosticBool(
                diagnostics['phoneCameraBackupHadPreviousSectionGuide'],
              ) ==
              true) {
        add('previous_section_guide_requested');
      }
      if (_diagnosticBool(diagnostics['previousSectionGuidePhotoAvailable']) ==
          true) {
        add('previous_section_ghost_guide_available');
      }
      if (_diagnosticBool(diagnostics['previousSectionGuidanceAvailable']) ==
          true) {
        add('previous_section_guidance_available');
      }
      final reason = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionReasonCode'],
        diagnostics['phoneCameraBackupPreviousSectionReasonCode'],
      );
      if (reason != null && reason.isNotEmpty && reason != 'none') {
        add('reason_${_diagnosticToken(reason)}');
      }
      final source = diagnostics['receiptContinuationSource']
          ?.toString()
          .trim();
      if (source != null && source.isNotEmpty && source != 'none') {
        add('source_${_diagnosticToken(source)}');
      }
      final ghostStatus = diagnostics['receiptContinuationGhostGuideStatus']
          ?.toString()
          .trim();
      if (ghostStatus != null &&
          ghostStatus.isNotEmpty &&
          ghostStatus != 'not_requested') {
        add('ghost_${_diagnosticToken(ghostStatus)}');
      }
      final missingBottomAndTotals =
          _diagnosticBool(
                diagnostics['previousSectionMissingBottomAndTotals'],
              ) ==
              true ||
          _diagnosticBool(
                diagnostics['phoneCameraBackupPreviousSectionMissingBottomAndTotals'],
              ) ==
              true;
      if (missingBottomAndTotals) {
        add('missing_bottom_edge_and_totals_continuation');
      }
      final ghostPolicy = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuidePolicy'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuidePolicy'],
      );
      if (ghostPolicy != null &&
          ghostPolicy.isNotEmpty &&
          ghostPolicy != 'not_requested') {
        add('ghost_policy_${_diagnosticToken(ghostPolicy)}');
      } else if (missingBottomAndTotals) {
        add('ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines');
      }
      final repeatLineTarget = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuideRepeatLineTarget'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget'],
      );
      if (repeatLineTarget != null &&
          repeatLineTarget.isNotEmpty &&
          repeatLineTarget != 'none') {
        add('ghost_repeat_target_${_diagnosticToken(repeatLineTarget)}');
      }
      final ghostPlacement = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuidePlacement'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuidePlacement'],
      );
      if (ghostPlacement != null &&
          ghostPlacement.isNotEmpty &&
          ghostPlacement != 'none') {
        add('ghost_placement_${_diagnosticToken(ghostPlacement)}');
      }
      final ghostMatchTarget = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuideMatchTarget'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuideMatchTarget'],
      );
      if (ghostMatchTarget != null &&
          ghostMatchTarget.isNotEmpty &&
          ghostMatchTarget != 'none') {
        add('ghost_match_target_${_diagnosticToken(ghostMatchTarget)}');
      }
      final ghostSlicePercent = _diagnosticInt(
        diagnostics['previousSectionGhostSlicePercent'],
      );
      if (_usableGhostSlicePercent(ghostSlicePercent)) {
        add('ghost_slice_percent_$ghostSlicePercent');
      } else {
        final ghostSourceHeightFraction = _diagnosticDouble(
          diagnostics['previousSectionGhostSourceHeightFraction'],
        );
        if (ghostSourceHeightFraction != null) {
          final derivedPercent = (ghostSourceHeightFraction * 100).round();
          if (_usableGhostSlicePercent(derivedPercent)) {
            add('ghost_slice_percent_$derivedPercent');
          }
        }
      }
      if (source == 'ocr_missing_bottom_totals' || missingBottomAndTotals) {
        add('ocr_requested_bottom_section');
      }
    }
    return Map.unmodifiable(counts);
  }

  Map<String, Object?> get privacySafeReceiptContinuationSummary {
    final counts = receiptContinuationSignalCounts;
    return Map.unmodifiable({
      'schema': 'receipt_continuation_handoff_v1',
      'status': receiptContinuationHandoffStatus,
      'hasContinuationRequest': hasPreviousSectionContinuationRequest,
      'hasOcrRequestedBottomSectionContinuation':
          hasOcrRequestedBottomSectionContinuation,
      if (counts.isNotEmpty) 'continuationSignalCounts': counts,
    });
  }

  String get ocrSourceFirstOutcome {
    if (!hasOcrSourcePhotos) return 'ocr_source_not_ready';
    if (usedSavedProofAsOcrSourceFallback) {
      return 'fallback_saved_proof_review_required';
    }
    if (stitchResult.didStitch) return 'combined_source_ready';
    if (usesImportedReceiptPhotoSource) return 'imported_source_ready';
    if (scannerUsedEnhancedOcrSource) return 'prepared_source_ready';
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      return 'temporary_full_quality_ready';
    }
    if (usesSeparateOcrSourceCopies) return 'separate_source_ready';
    return 'saved_source_matched_original';
  }

  String get ocrSourceFirstActionLabel {
    return switch (ocrSourceFirstOutcome) {
      'prepared_source_ready' =>
        'Receipt details use the prepared photo before the saved copy',
      'temporary_full_quality_ready' =>
        'Receipt details use the full-quality photo before the saved copy',
      'combined_source_ready' =>
        'Receipt details use the combined receipt image before the saved copy',
      'imported_source_ready' =>
        'Receipt details use the imported photo before the saved copy',
      'separate_source_ready' =>
        'Receipt details use the clear photos before the saved copy',
      'saved_source_matched_original' =>
        'The clear photo matches the accepted receipt copy',
      'fallback_saved_proof_review_required' =>
        'Receipt details used the saved copy; review the filled receipt carefully',
      _ => 'The clear receipt photo was not ready before the saved copy',
    };
  }
}

String? _firstContinuationDiagnosticValue(Object? primary, Object? fallback) {
  final primaryText = primary?.toString().trim();
  if (primaryText != null && primaryText.isNotEmpty) return primaryText;
  final fallbackText = fallback?.toString().trim();
  if (fallbackText != null && fallbackText.isNotEmpty) return fallbackText;
  return null;
}

int? _diagnosticInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value % 1 == 0) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _diagnosticDouble(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed.isFinite) return parsed;
  }
  return null;
}

bool _usableGhostSlicePercent(int? value) {
  return value != null && value >= 12 && value <= 35;
}
