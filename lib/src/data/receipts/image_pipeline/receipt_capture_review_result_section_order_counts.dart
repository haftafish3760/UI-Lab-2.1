part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultSectionOrderCounts
    on ReceiptPhotoReviewResult {
  Map<String, int> get receiptSectionOrderCounts {
    final counts = <String, int>{};
    final removalFinalSections = <int>{};
    final removalFinalSectionCounts = <int>{};
    final removalRemainingOriginalSections = <int>{};
    var hasRemovalMetadata = false;
    var hasDuplicateRemovalFinalSection = false;
    var hasDuplicateRemovalRemainingOriginalSection = false;
    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      final sectionCount = _diagnosticPositiveInt(
        diagnostics['receiptSectionCount'],
      );
      final nextSection = _diagnosticPositiveInt(
        diagnostics['nextReceiptSectionNumber'],
      );
      final orderPolicy = _diagnosticToken(
        diagnostics['receiptSectionOrderPolicy']?.toString() ?? '',
      );
      final ghostPolicy = _diagnosticToken(
        diagnostics['previousSectionGhostGuidePolicy']?.toString() ?? '',
      );
      final ghostVisible = _diagnosticBool(
        diagnostics['previousSectionGhostGuideVisible'],
      );
      final previousSectionReason = _diagnosticToken(
        diagnostics['previousSectionReasonCode']?.toString() ?? '',
      );
      final retakeOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptRetakeOriginalSectionNumber'],
      );
      final retakeFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptRetakeFinalSectionNumber'],
      );
      final retakeReplacementCount = _diagnosticPositiveInt(
        diagnostics['receiptRetakeReplacementCount'],
      );
      final retakeFinalSectionCount = _diagnosticPositiveInt(
        diagnostics['receiptRetakeFinalSectionCount'],
      );
      final retakeGuidance = _diagnosticToken(
        diagnostics['receiptRetakeGuidanceCode']?.toString() ?? '',
      );
      final retakePolicy = _diagnosticToken(
        diagnostics['receiptRetakeOrderPolicy']?.toString() ?? '',
      );
      final hasRetakeMetadata =
          retakeOriginalSection != null ||
          retakeFinalSection != null ||
          retakeGuidance != 'unknown' ||
          retakePolicy != 'unknown' ||
          diagnostics.containsKey('receiptRetakeReplacementOffset') ||
          diagnostics.containsKey('receiptRetakePreservedOriginalSlot') ||
          diagnostics.containsKey('receiptRetakeInsertedExtraSection');
      final insertAnchorSection = _diagnosticPositiveInt(
        diagnostics['receiptInsertAfterAnchorSectionNumber'],
      );
      final insertFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptInsertFinalSectionNumber'],
      );
      final insertCount = _diagnosticPositiveInt(
        diagnostics['receiptInsertCount'],
      );
      final insertFinalSectionCount = _diagnosticPositiveInt(
        diagnostics['receiptInsertFinalSectionCount'],
      );
      final insertPolicy = _diagnosticToken(
        diagnostics['receiptInsertOrderPolicy']?.toString() ?? '',
      );
      final manualReorderOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptManualReorderOriginalSectionNumber'],
      );
      final manualReorderFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptManualReorderFinalSectionNumber'],
      );
      final manualReorderDirection = _diagnosticToken(
        diagnostics['receiptManualReorderDirection']?.toString() ?? '',
      );
      final manualReorderSectionCount = _diagnosticPositiveInt(
        diagnostics['receiptManualReorderSectionCount'],
      );
      final manualReorderPolicy = _diagnosticToken(
        diagnostics['receiptManualReorderPolicy']?.toString() ?? '',
      );
      final removalOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptRemoveOriginalSectionNumber'],
      );
      final removalFinalSection = _diagnosticPositiveInt(
        diagnostics['receiptRemoveFinalSectionNumber'],
      );
      final removalRemainingOriginalSection = _diagnosticPositiveInt(
        diagnostics['receiptRemoveRemainingSectionOriginalNumber'],
      );
      final removalFinalCount = _diagnosticPositiveInt(
        diagnostics['receiptRemoveFinalSectionCount'],
      );
      final currentHasRemovalMetadata =
          removalOriginalSection != null ||
          removalFinalSection != null ||
          removalRemainingOriginalSection != null ||
          removalFinalCount != null ||
          diagnostics.containsKey('receiptRemoveSectionShifted');
      if (currentHasRemovalMetadata) {
        hasRemovalMetadata = true;
        if (removalFinalSection != null &&
            !removalFinalSections.add(removalFinalSection)) {
          hasDuplicateRemovalFinalSection = true;
        }
        if (removalFinalCount != null) {
          removalFinalSectionCounts.add(removalFinalCount);
        }
        if (removalRemainingOriginalSection != null &&
            !removalRemainingOriginalSections.add(
              removalRemainingOriginalSection,
            )) {
          hasDuplicateRemovalRemainingOriginalSection = true;
        }
      }
      if (sectionCount != null) {
        final bucket = sectionCount <= 1
            ? 'single_section'
            : 'multi_section_${sectionCount}_sections';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (nextSection != null && nextSection > 1) {
        final bucket = nextSection > 9
            ? 'next_section_10_plus'
            : 'next_section_$nextSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeOriginalSection != null) {
        final bucket = retakeOriginalSection > 9
            ? 'retake_original_section_10_plus'
            : 'retake_original_section_$retakeOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeFinalSection != null) {
        final bucket = retakeFinalSection > 9
            ? 'retake_final_section_10_plus'
            : 'retake_final_section_$retakeFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeReplacementCount != null) {
        final bucket = retakeReplacementCount > 9
            ? 'retake_replacement_count_10_plus'
            : 'retake_replacement_count_$retakeReplacementCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (retakeFinalSectionCount != null) {
        final bucket = retakeFinalSectionCount > 9
            ? 'retake_final_section_count_10_plus'
            : 'retake_final_section_count_$retakeFinalSectionCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertAnchorSection != null) {
        final bucket = insertAnchorSection > 9
            ? 'insert_anchor_section_10_plus'
            : 'insert_anchor_section_$insertAnchorSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertFinalSection != null) {
        final bucket = insertFinalSection > 9
            ? 'insert_final_section_10_plus'
            : 'insert_final_section_$insertFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertCount != null) {
        final bucket = insertCount > 9
            ? 'insert_count_10_plus'
            : 'insert_count_$insertCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (insertFinalSectionCount != null) {
        final bucket = insertFinalSectionCount > 9
            ? 'insert_final_section_count_10_plus'
            : 'insert_final_section_count_$insertFinalSectionCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (manualReorderOriginalSection != null) {
        final bucket = manualReorderOriginalSection > 9
            ? 'manual_reorder_original_section_10_plus'
            : 'manual_reorder_original_section_$manualReorderOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (manualReorderSectionCount != null) {
        final bucket = manualReorderSectionCount > 9
            ? 'manual_reorder_section_count_10_plus'
            : 'manual_reorder_section_count_$manualReorderSectionCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (manualReorderFinalSection != null) {
        final bucket = manualReorderFinalSection > 9
            ? 'manual_reorder_final_section_10_plus'
            : 'manual_reorder_final_section_$manualReorderFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (removalOriginalSection != null) {
        final bucket = removalOriginalSection > 9
            ? 'remove_original_section_10_plus'
            : 'remove_original_section_$removalOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (removalFinalSection != null) {
        final bucket = removalFinalSection > 9
            ? 'remove_final_section_10_plus'
            : 'remove_final_section_$removalFinalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (removalRemainingOriginalSection != null) {
        final bucket = removalRemainingOriginalSection > 9
            ? 'remove_remaining_original_section_10_plus'
            : 'remove_remaining_original_section_$removalRemainingOriginalSection';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      if (removalFinalCount != null) {
        final bucket = removalFinalCount > 9
            ? 'remove_final_section_count_10_plus'
            : 'remove_final_section_count_$removalFinalCount';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      for (final invalidCode in _receiptRetakeInvalidOrderCodes(
        diagnostics: diagnostics,
        originalSection: retakeOriginalSection,
        finalSection: retakeFinalSection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptNativeGhostRetakeInvalidOrderCodes(
        hasRetakeMetadata: hasRetakeMetadata,
        diagnostics: diagnostics,
        originalSection: retakeOriginalSection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptRetakeInvalidGuidanceCodes(
        hasRetakeMetadata: hasRetakeMetadata,
        originalSection: retakeOriginalSection,
        guidance: retakeGuidance,
        diagnostics: diagnostics,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptRetakeInvalidPreviousGuideReasonCodes(
        hasRetakeMetadata: hasRetakeMetadata,
        originalSection: retakeOriginalSection,
        previousSectionReason: previousSectionReason,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptInsertInvalidOrderCodes(
        diagnostics: diagnostics,
        anchorSection: insertAnchorSection,
        finalSection: insertFinalSection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      for (final invalidCode in _receiptManualReorderInvalidOrderCodes(
        diagnostics: diagnostics,
        originalSection: manualReorderOriginalSection,
        finalSection: manualReorderFinalSection,
        direction: manualReorderDirection,
      )) {
        counts[invalidCode] = (counts[invalidCode] ?? 0) + 1;
      }
      if (orderPolicy != 'unknown') {
        counts['policy_$orderPolicy'] =
            (counts['policy_$orderPolicy'] ?? 0) + 1;
      }
      if (retakePolicy != 'unknown') {
        counts['retake_policy_$retakePolicy'] =
            (counts['retake_policy_$retakePolicy'] ?? 0) + 1;
      }
      if (insertPolicy != 'unknown') {
        counts['insert_policy_$insertPolicy'] =
            (counts['insert_policy_$insertPolicy'] ?? 0) + 1;
      }
      if (manualReorderPolicy != 'unknown') {
        counts['manual_reorder_policy_$manualReorderPolicy'] =
            (counts['manual_reorder_policy_$manualReorderPolicy'] ?? 0) + 1;
      }
      if (manualReorderDirection != 'unknown') {
        counts['manual_reorder_direction_$manualReorderDirection'] =
            (counts['manual_reorder_direction_$manualReorderDirection'] ?? 0) +
            1;
      }
      if (retakeGuidance != 'unknown') {
        counts['retake_guidance_$retakeGuidance'] =
            (counts['retake_guidance_$retakeGuidance'] ?? 0) + 1;
      }
      if (previousSectionReason != 'unknown') {
        counts['previous_section_reason_$previousSectionReason'] =
            (counts['previous_section_reason_$previousSectionReason'] ?? 0) + 1;
      }
      if (ghostPolicy != 'unknown') {
        counts['ghost_policy_$ghostPolicy'] =
            (counts['ghost_policy_$ghostPolicy'] ?? 0) + 1;
      }
      if (ghostVisible != null) {
        final bucket = ghostVisible
            ? 'ghost_guide_visible'
            : 'ghost_guide_hidden';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
      for (final code in _receiptRetakeContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptInsertContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptManualReorderContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptRemovalContextCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
      for (final code in _receiptRemovalInvalidOrderCodes(diagnostics)) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    if (hasRemovalMetadata) {
      if (hasDuplicateRemovalFinalSection) {
        counts['remove_invalid_duplicate_final_section'] =
            (counts['remove_invalid_duplicate_final_section'] ?? 0) + 1;
      }
      if (hasDuplicateRemovalRemainingOriginalSection) {
        counts['remove_invalid_duplicate_remaining_original_section'] =
            (counts['remove_invalid_duplicate_remaining_original_section'] ??
                0) +
            1;
      }
      if (removalFinalSectionCounts.length > 1) {
        counts['remove_invalid_inconsistent_final_section_count'] =
            (counts['remove_invalid_inconsistent_final_section_count'] ?? 0) +
            1;
      }
      if (removalFinalSectionCounts.length == 1) {
        final expectedCount = removalFinalSectionCounts.single;
        if (removalFinalSections.length == expectedCount) {
          final hasEveryFinalSection = Iterable<int>.generate(
            expectedCount,
            (index) => index + 1,
          ).every(removalFinalSections.contains);
          if (!hasEveryFinalSection) {
            counts['remove_invalid_non_contiguous_final_sections'] =
                (counts['remove_invalid_non_contiguous_final_sections'] ?? 0) +
                1;
          }
        }
      }
    }
    final hasTrackedMultiSection = counts.keys.any(
      (key) => key.startsWith('multi_section_'),
    );
    final inferredSectionCount = [
      savedBackupPhotoCount,
      ocrSourcePhotoCount,
      stitchResult.inputPaths.length,
      stitchResult.ocrSourcePaths.length,
    ].fold<int>(0, (max, count) => count > max ? count : max);
    if (!hasTrackedMultiSection && inferredSectionCount > 1) {
      final bucket = inferredSectionCount > 9
          ? 'inferred_multi_section_10_plus_sections'
          : 'inferred_multi_section_${inferredSectionCount}_sections';
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }
}

List<String> _receiptRemovalInvalidOrderCodes(
  Map<String, Object?> diagnostics,
) {
  final originalSection = _diagnosticPositiveInt(
    diagnostics['receiptRemoveRemainingSectionOriginalNumber'],
  );
  final finalSection = _diagnosticPositiveInt(
    diagnostics['receiptRemoveFinalSectionNumber'],
  );
  final finalSectionCount = _diagnosticPositiveInt(
    diagnostics['receiptRemoveFinalSectionCount'],
  );
  final shifted = _diagnosticBool(diagnostics['receiptRemoveSectionShifted']);
  final hasRemovalMetadata =
      originalSection != null ||
      finalSection != null ||
      finalSectionCount != null ||
      shifted != null ||
      _diagnosticPositiveInt(
            diagnostics['receiptRemoveOriginalSectionNumber'],
          ) !=
          null;
  if (!hasRemovalMetadata) return const [];
  final codes = <String>[];
  if (originalSection == null) {
    codes.add('remove_invalid_missing_remaining_original_section');
  }
  if (finalSection == null) {
    codes.add('remove_invalid_missing_final_section');
  }
  if (finalSectionCount == null) {
    codes.add('remove_invalid_missing_final_section_count');
  }
  if (shifted == null) {
    codes.add('remove_invalid_missing_shift_flag');
  }
  if (finalSection != null &&
      finalSectionCount != null &&
      finalSection > finalSectionCount) {
    codes.add('remove_invalid_final_section_out_of_range');
  }
  if (originalSection != null && finalSection != null && shifted != null) {
    final expectedShifted = originalSection != finalSection;
    if (shifted != expectedShifted) {
      codes.add('remove_invalid_shift_flag_mismatch');
    }
  }
  return List.unmodifiable(codes);
}
