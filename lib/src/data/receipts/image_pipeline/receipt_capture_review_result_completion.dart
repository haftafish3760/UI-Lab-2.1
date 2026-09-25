part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultCompletion on ReceiptPhotoReviewResult {
  Map<String, int> get stitchPairDiagnosticCounts {
    final counts = <String, int>{};
    for (final pair in stitchResult.pairs) {
      final code = pair.diagnosticCode.trim();
      if (code.isEmpty) continue;
      counts[code] = (counts[code] ?? 0) + 1;
    }
    if (stitchResult.usedFallback) {
      final reason = stitchResult.diagnosticReasonLabel.trim();
      if (reason.isNotEmpty) {
        final fallbackCode = 'fallback_$reason';
        counts[fallbackCode] = (counts[fallbackCode] ?? 0) + 1;
      }
    }
    final coverageCode = stitchResult.overlapCoverageCode.trim();
    if (coverageCode.isNotEmpty) {
      counts['overlap_$coverageCode'] =
          (counts['overlap_$coverageCode'] ?? 0) + 1;
    }
    final sourceCode = stitchResult.sourcePreservationCode.trim();
    if (sourceCode.isNotEmpty) {
      counts['source_$sourceCode'] = (counts['source_$sourceCode'] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  List<String> get photoCoverageStatuses {
    final statuses = <String>[];
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final status =
          diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageStatus]
              ?.toString()
              .trim();
      if (status != null && status.isNotEmpty) statuses.add(status);
    }
    return List.unmodifiable(statuses);
  }

  Map<String, int> get photoCoverageStatusCounts {
    final counts = <String, int>{};
    for (final status in photoCoverageStatuses) {
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  bool get hasPossiblePartialReceiptPhotos {
    return captureDiagnosticsByPhotoPath.values.any((diagnostics) {
      return _diagnosticsNeedMoreReceiptSection(diagnostics);
    });
  }

  bool get finalReceiptSectionNeedsBottomTotalsContinuation {
    for (final path in photoPaths.reversed) {
      final diagnostics = captureDiagnosticsByPhotoPath[path];
      if (diagnostics == null) continue;
      if (!_diagnosticsNeedMoreReceiptSection(diagnostics)) return false;
      return _diagnosticsCoverageReason(diagnostics) ==
          'missing_bottom_edge_and_totals';
    }
    return false;
  }

  Map<String, Object> get finalReceiptSectionContinuationEvidence {
    final diagnostics = _finalReceiptSectionDiagnostics;
    final missingBottomAndTotals =
        diagnostics != null &&
        _diagnosticsNeedMoreReceiptSection(diagnostics) &&
        _diagnosticsCoverageReason(diagnostics) ==
            'missing_bottom_edge_and_totals';
    return Map.unmodifiable({
      'schema': 'receipt_final_section_continuation_evidence_v1',
      'needsBottomTotalsContinuation': missingBottomAndTotals,
      if (missingBottomAndTotals) ...{
        'bottomEdgeDetected':
            _diagnosticBool(
              diagnostics[ReceiptCaptureDiagnosticKeys
                  .receiptBottomEdgeDetected],
            ) ??
            false,
        'subtotalDetected':
            _diagnosticBool(
              diagnostics[ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected],
            ) ??
            false,
        'totalDetected':
            _diagnosticBool(
              diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalDetected],
            ) ??
            false,
        'totalAmountDetected':
            _diagnosticBool(
              diagnostics[ReceiptCaptureDiagnosticKeys
                  .receiptTotalAmountDetected],
            ) ??
            false,
        'totalsTextEvidenceStatus': _diagnosticToken(
          diagnostics[ReceiptCaptureDiagnosticKeys
                      .receiptTotalsTextEvidenceStatus]
                  ?.toString() ??
              'missing',
        ),
        'evidenceFamilyCount': _finalSectionMissingEvidenceFamilyCount(
          diagnostics,
        ),
      },
    });
  }

  String get finalReceiptSectionContinuationEvidenceLabel {
    final evidence = finalReceiptSectionContinuationEvidence;
    if (evidence['needsBottomTotalsContinuation'] != true) {
      return 'Final section coverage is complete enough for OCR.';
    }
    final missingFamilies = evidence['evidenceFamilyCount'];
    return 'Final section still needs bottom coverage: bottom edge, subtotal/total words, and total amount were not confirmed ($missingFamilies evidence families).';
  }

  bool get needsAnotherReceiptSectionBeforeDetails =>
      !keptForLater &&
      hasPossiblePartialReceiptPhotos &&
      !userConfirmedPossiblePartialReceiptComplete &&
      (finalReceiptSectionNeedsBottomTotalsContinuation ||
          (!nextReviewUsesOrderedSections &&
              !nextReviewUsesCombinedReceiptImage));

  bool get userConfirmedPossiblePartialReceiptComplete {
    return captureDiagnosticsByPhotoPath.values.any((diagnostics) {
      final confirmed = _diagnosticBool(
        diagnostics[ReceiptCaptureDiagnosticKeys
            .receiptCompletionUserConfirmedComplete],
      );
      if (confirmed == true) return true;
      final decision =
          diagnostics[ReceiptCaptureDiagnosticKeys
                  .receiptCompletionUserDecision]
              ?.toString()
              .trim();
      return decision == 'continue_anyway' ||
          decision == 'confirmed_complete_receipt';
    });
  }

  Map<String, int> get receiptCompletionChoiceCounts {
    final counts = <String, int>{};
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final rawDecision =
          diagnostics[ReceiptCaptureDiagnosticKeys
                  .receiptCompletionUserDecision]
              ?.toString()
              .trim();
      if (rawDecision != null && rawDecision.isNotEmpty) {
        final token = _diagnosticToken(rawDecision);
        counts[token] = (counts[token] ?? 0) + 1;
      }
      final confirmed = _diagnosticBool(
        diagnostics[ReceiptCaptureDiagnosticKeys
            .receiptCompletionUserConfirmedComplete],
      );
      if (confirmed == true) {
        counts['user_confirmed_complete'] =
            (counts['user_confirmed_complete'] ?? 0) + 1;
      }
      final reason =
          diagnostics[ReceiptCaptureDiagnosticKeys
                  .receiptCompletionPromptReasonCode]
              ?.toString()
              .trim();
      if (reason != null && reason.isNotEmpty) {
        final token = _diagnosticToken(reason);
        counts['reason_$token'] = (counts['reason_$token'] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  String get receiptCompletionReviewOutcome {
    if (userConfirmedPossiblePartialReceiptComplete) {
      return 'user_confirmed_complete_after_prompt';
    }
    if (needsAnotherReceiptSectionBeforeDetails) {
      return 'needs_next_section_before_details';
    }
    if (hasPossiblePartialReceiptPhotos && nextReviewUsesOrderedSections) {
      return 'completed_with_ordered_sections';
    }
    if (hasPossiblePartialReceiptPhotos && nextReviewUsesCombinedReceiptImage) {
      return 'completed_with_stitched_receipt';
    }
    return receiptCompletionChoiceCounts.isEmpty
        ? 'completion_not_prompted'
        : 'completion_prompt_reviewed';
  }

  String get firstPossiblePartialReceiptReasonCode {
    if (finalReceiptSectionNeedsBottomTotalsContinuation) {
      return 'missing_bottom_edge_and_totals';
    }
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final stagedReason = _diagnosticsCoverageReason(diagnostics);
      final stagedNeedsMore = _diagnosticsNeedMoreReceiptSection(diagnostics);
      if (stagedNeedsMore && stagedReason != null && stagedReason.isNotEmpty) {
        return stagedReason;
      }
      final decision = ReceiptPhotoCoverageDecision.fromSignals(
        diagnostics: diagnostics,
      );
      if (!decision.shouldPromptForMorePhotos) continue;
      return decision.reasonCode;
    }
    return '';
  }

  static bool _diagnosticsNeedMoreReceiptSection(
    Map<String, Object?> diagnostics,
  ) {
    final needsMore =
        diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos];
    if (needsMore == true || needsMore?.toString() == 'true') return true;
    final status = diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageStatus]
        ?.toString()
        .trim();
    return _coverageStatusNeedsMoreSection(status);
  }

  static bool _coverageStatusNeedsMoreSection(String? status) {
    if (status == null || status.isEmpty) return false;
    if (status == ReceiptPhotoCoverageStatus.likelyCutOff.name ||
        status == ReceiptPhotoCoverageStatus.maybeContinues.name) {
      return true;
    }
    final token = _diagnosticToken(status);
    return const {
      'bottom_soft_or_missing',
      'bottom_missing',
      'soft_or_missing',
      'cut_off',
      'possibly_cut_off',
      'needs_next_section',
      'continues',
      'likely_cut_off',
      'maybe_continues',
    }.contains(token);
  }

  static String? _diagnosticsCoverageReason(Map<String, Object?> diagnostics) {
    final reason = diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageReason]
        ?.toString()
        .trim();
    return reason == null || reason.isEmpty ? null : reason;
  }

  Map<String, Object?>? get _finalReceiptSectionDiagnostics {
    for (final path in photoPaths.reversed) {
      final diagnostics = captureDiagnosticsByPhotoPath[path];
      if (diagnostics != null) return diagnostics;
    }
    return null;
  }

  static int _finalSectionMissingEvidenceFamilyCount(
    Map<String, Object?> diagnostics,
  ) {
    var count = 0;
    final bottomEdgeDetected = _diagnosticBool(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected],
    );
    if (bottomEdgeDetected != true) count++;
    final subtotalDetected = _diagnosticBool(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected],
    );
    final totalDetected = _diagnosticBool(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalDetected],
    );
    if (subtotalDetected != true && totalDetected != true) count++;
    final totalAmountDetected = _diagnosticBool(
      diagnostics[ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected],
    );
    if (totalAmountDetected != true) count++;
    return count;
  }
}
